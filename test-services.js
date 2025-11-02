/**
 * Fast SocialFi 服务测试脚本
 * 测试所有数据库和中间件服务的连接性和性能
 */

const { Client: PgClient } = require('pg');
const redis = require('redis');
const { Client: ElasticsearchClient } = require('@elastic/elasticsearch');
const { Kafka } = require('kafkajs');
const mysql = require('mysql2/promise');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function section(title) {
  console.log('\n' + '='.repeat(80));
  log(title, 'bright');
  console.log('='.repeat(80));
}

// 测试结果收集
const testResults = {
  timestamp: new Date().toISOString(),
  services: {}
};

// 1. 测试 PostgreSQL
async function testPostgreSQL() {
  section('📊 PostgreSQL 测试');
  const result = {
    name: 'PostgreSQL',
    version: '16-alpine',
    port: 5432,
    available: false,
    connectionTime: 0,
    performance: {}
  };

  const client = new PgClient({
    host: 'localhost',
    port: 5432,
    user: 'socialfi',
    password: 'socialfi_pg_pass_2024',
    database: 'socialfi_db'
  });

  try {
    // 连接测试
    const startConnect = Date.now();
    await client.connect();
    result.connectionTime = Date.now() - startConnect;
    result.available = true;
    log(`✅ 连接成功 (${result.connectionTime}ms)`, 'green');

    // 版本信息
    const versionRes = await client.query('SELECT version()');
    log(`📌 版本: ${versionRes.rows[0].version.split(',')[0]}`, 'cyan');

    // 数据库信息 (修复数据库名称)
    const dbSizeRes = await client.query(`
      SELECT pg_size_pretty(pg_database_size('socialfi_db')) as size
    `);
    log(`💾 数据库大小: ${dbSizeRes.rows[0].size}`, 'cyan');

    // 设置搜索路径
    await client.query('SET search_path TO socialfi, public');

    // 性能测试 - 写入
    const writeStart = Date.now();
    await client.query(`
      CREATE TABLE IF NOT EXISTS test_performance (
        id SERIAL PRIMARY KEY,
        data TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    await client.query('DELETE FROM test_performance');

    const insertPromises = [];
    for (let i = 0; i < 1000; i++) {
      insertPromises.push(
        client.query('INSERT INTO test_performance (data) VALUES ($1)', [`test_data_${i}`])
      );
    }
    await Promise.all(insertPromises);
    const writeTime = Date.now() - writeStart;
    result.performance.write = {
      records: 1000,
      time: writeTime,
      rps: Math.round(1000 / (writeTime / 1000))
    };
    log(`✍️  写入性能: 1000条记录, ${writeTime}ms, ${result.performance.write.rps} records/s`, 'yellow');

    // 性能测试 - 读取
    const readStart = Date.now();
    for (let i = 0; i < 100; i++) {
      await client.query('SELECT * FROM test_performance LIMIT 100');
    }
    const readTime = Date.now() - readStart;
    result.performance.read = {
      queries: 100,
      time: readTime,
      qps: Math.round(100 / (readTime / 1000))
    };
    log(`📖 读取性能: 100次查询, ${readTime}ms, ${result.performance.read.qps} queries/s`, 'yellow');

    // 连接池信息
    const poolRes = await client.query(`
      SELECT count(*) as connections
      FROM pg_stat_activity
      WHERE datname = 'socialfi_db'
    `);
    log(`🔗 当前连接数: ${poolRes.rows[0].connections}`, 'cyan');

    // 清理
    await client.query('DROP TABLE IF EXISTS test_performance');

  } catch (error) {
    log(`❌ PostgreSQL 测试失败: ${error.message}`, 'red');
    result.error = error.message;
  } finally {
    await client.end();
  }

  testResults.services.postgresql = result;
  return result;
}

// 2. 测试 Redis
async function testRedis() {
  section('🔴 Redis 测试');
  const result = {
    name: 'Redis',
    version: '7-alpine',
    port: 6379,
    available: false,
    connectionTime: 0,
    performance: {}
  };

  const client = redis.createClient({
    socket: {
      host: 'localhost',
      port: 6379
    }
  });

  try {
    // 连接测试
    const startConnect = Date.now();
    await client.connect();
    result.connectionTime = Date.now() - startConnect;
    result.available = true;
    log(`✅ 连接成功 (${result.connectionTime}ms)`, 'green');

    // 服务器信息
    const info = await client.info('server');
    const version = info.match(/redis_version:([^\r\n]+)/)?.[1];
    log(`📌 版本: ${version}`, 'cyan');

    // 内存信息
    const memInfo = await client.info('memory');
    const usedMemory = memInfo.match(/used_memory_human:([^\r\n]+)/)?.[1];
    log(`💾 内存使用: ${usedMemory}`, 'cyan');

    // 性能测试 - 写入
    const writeStart = Date.now();
    const writePromises = [];
    for (let i = 0; i < 10000; i++) {
      writePromises.push(client.set(`test:key:${i}`, `value_${i}`));
    }
    await Promise.all(writePromises);
    const writeTime = Date.now() - writeStart;
    result.performance.write = {
      operations: 10000,
      time: writeTime,
      ops: Math.round(10000 / (writeTime / 1000))
    };
    log(`✍️  写入性能: 10000次SET, ${writeTime}ms, ${result.performance.write.ops} ops/s`, 'yellow');

    // 性能测试 - 读取
    const readStart = Date.now();
    const readPromises = [];
    for (let i = 0; i < 10000; i++) {
      readPromises.push(client.get(`test:key:${i}`));
    }
    await Promise.all(readPromises);
    const readTime = Date.now() - readStart;
    result.performance.read = {
      operations: 10000,
      time: readTime,
      ops: Math.round(10000 / (readTime / 1000))
    };
    log(`📖 读取性能: 10000次GET, ${readTime}ms, ${result.performance.read.ops} ops/s`, 'yellow');

    // 统计信息
    const stats = await client.info('stats');
    const totalCommands = stats.match(/total_commands_processed:([^\r\n]+)/)?.[1];
    log(`📊 总命令数: ${totalCommands}`, 'cyan');

    // 清理
    for (let i = 0; i < 10000; i++) {
      await client.del(`test:key:${i}`);
    }

  } catch (error) {
    log(`❌ Redis 测试失败: ${error.message}`, 'red');
    result.error = error.message;
  } finally {
    await client.quit();
  }

  testResults.services.redis = result;
  return result;
}

// 3. 测试 Elasticsearch
async function testElasticsearch() {
  section('🔍 Elasticsearch 测试');
  const result = {
    name: 'Elasticsearch',
    version: '8.11.3',
    port: 9200,
    available: false,
    connectionTime: 0,
    performance: {}
  };

  const client = new ElasticsearchClient({
    node: 'http://localhost:9200'
  });

  try {
    // 连接测试
    const startConnect = Date.now();
    const pingResult = await client.ping();
    result.connectionTime = Date.now() - startConnect;
    result.available = pingResult;
    log(`✅ 连接成功 (${result.connectionTime}ms)`, 'green');

    // 集群信息
    const clusterHealth = await client.cluster.health();
    log(`📌 集群状态: ${clusterHealth.status}`, 'cyan');
    log(`📊 节点数: ${clusterHealth.number_of_nodes}`, 'cyan');
    log(`📦 索引数: ${clusterHealth.number_of_data_nodes}`, 'cyan');

    // 版本信息
    const info = await client.info();
    log(`📌 版本: ${info.version.number}`, 'cyan');

    // 创建测试索引
    const indexName = 'test_performance';
    try {
      await client.indices.delete({ index: indexName });
    } catch (e) {
      // 索引可能不存在
    }

    await client.indices.create({
      index: indexName,
      body: {
        mappings: {
          properties: {
            title: { type: 'text' },
            content: { type: 'text' },
            timestamp: { type: 'date' }
          }
        }
      }
    });

    // 性能测试 - 索引文档
    const indexStart = Date.now();
    const indexPromises = [];
    for (let i = 0; i < 1000; i++) {
      indexPromises.push(
        client.index({
          index: indexName,
          body: {
            title: `Test Document ${i}`,
            content: `This is test content for document number ${i}`,
            timestamp: new Date()
          }
        })
      );
    }
    await Promise.all(indexPromises);
    await client.indices.refresh({ index: indexName });
    const indexTime = Date.now() - indexStart;
    result.performance.index = {
      documents: 1000,
      time: indexTime,
      dps: Math.round(1000 / (indexTime / 1000))
    };
    log(`✍️  索引性能: 1000个文档, ${indexTime}ms, ${result.performance.index.dps} docs/s`, 'yellow');

    // 性能测试 - 搜索
    const searchStart = Date.now();
    for (let i = 0; i < 100; i++) {
      await client.search({
        index: indexName,
        body: {
          query: {
            match: {
              content: 'test'
            }
          }
        }
      });
    }
    const searchTime = Date.now() - searchStart;
    result.performance.search = {
      queries: 100,
      time: searchTime,
      qps: Math.round(100 / (searchTime / 1000))
    };
    log(`🔍 搜索性能: 100次查询, ${searchTime}ms, ${result.performance.search.qps} queries/s`, 'yellow');

    // 清理
    await client.indices.delete({ index: indexName });

  } catch (error) {
    log(`❌ Elasticsearch 测试失败: ${error.message}`, 'red');
    result.error = error.message;
  } finally {
    await client.close();
  }

  testResults.services.elasticsearch = result;
  return result;
}

// 4. 测试 Kafka
async function testKafka() {
  section('📨 Kafka 测试');
  const result = {
    name: 'Kafka',
    version: '3.7.0',
    port: 9092,
    available: false,
    connectionTime: 0,
    performance: {}
  };

  const kafka = new Kafka({
    clientId: 'test-client',
    brokers: ['localhost:9092']
  });

  const admin = kafka.admin();
  const producer = kafka.producer();
  const consumer = kafka.consumer({ groupId: 'test-group' });

  try {
    // 连接测试
    const startConnect = Date.now();
    await admin.connect();
    result.connectionTime = Date.now() - startConnect;
    result.available = true;
    log(`✅ 连接成功 (${result.connectionTime}ms)`, 'green');

    // 集群信息
    const cluster = await admin.listTopics();
    log(`📊 主题数量: ${cluster.length}`, 'cyan');

    // 创建测试主题
    const testTopic = 'test-performance';
    try {
      await admin.deleteTopics({ topics: [testTopic] });
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (e) {
      // 主题可能不存在
    }

    await admin.createTopics({
      topics: [{
        topic: testTopic,
        numPartitions: 3,
        replicationFactor: 1
      }]
    });
    log(`📌 创建测试主题: ${testTopic}`, 'cyan');

    // 连接生产者和消费者
    await producer.connect();
    await consumer.connect();
    await consumer.subscribe({ topic: testTopic, fromBeginning: true });

    // 性能测试 - 生产消息
    const produceStart = Date.now();
    const messages = [];
    for (let i = 0; i < 1000; i++) {
      messages.push({
        value: JSON.stringify({ id: i, message: `Test message ${i}`, timestamp: Date.now() })
      });
    }
    await producer.send({
      topic: testTopic,
      messages: messages
    });
    const produceTime = Date.now() - produceStart;
    result.performance.produce = {
      messages: 1000,
      time: produceTime,
      mps: Math.round(1000 / (produceTime / 1000))
    };
    log(`✍️  生产性能: 1000条消息, ${produceTime}ms, ${result.performance.produce.mps} msgs/s`, 'yellow');

    // 性能测试 - 消费消息
    let consumedCount = 0;
    const consumeStart = Date.now();

    await consumer.run({
      eachMessage: async ({ message }) => {
        consumedCount++;
      }
    });

    // 等待消费完成
    await new Promise(resolve => {
      const checkInterval = setInterval(() => {
        if (consumedCount >= 1000) {
          clearInterval(checkInterval);
          resolve();
        }
      }, 100);
    });

    const consumeTime = Date.now() - consumeStart;
    result.performance.consume = {
      messages: consumedCount,
      time: consumeTime,
      mps: Math.round(consumedCount / (consumeTime / 1000))
    };
    log(`📖 消费性能: ${consumedCount}条消息, ${consumeTime}ms, ${result.performance.consume.mps} msgs/s`, 'yellow');

    // 清理
    await admin.deleteTopics({ topics: [testTopic] });

  } catch (error) {
    log(`❌ Kafka 测试失败: ${error.message}`, 'red');
    result.error = error.message;
  } finally {
    try {
      await producer.disconnect();
      await consumer.disconnect();
      await admin.disconnect();
    } catch (e) {
      // 忽略断开连接错误
    }
  }

  testResults.services.kafka = result;
  return result;
}

// 5. 测试本机 MySQL
async function testMySQL() {
  section('🐬 MySQL 测试 (本机)');
  const result = {
    name: 'MySQL',
    version: 'Unknown',
    port: 3306,
    available: false,
    connectionTime: 0,
    performance: {}
  };

  let connection;

  try {
    // 连接测试
    const startConnect = Date.now();
    connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'mysql'
    });
    result.connectionTime = Date.now() - startConnect;
    result.available = true;
    log(`✅ 连接成功 (${result.connectionTime}ms)`, 'green');

    // 版本信息
    const [versionRows] = await connection.query('SELECT VERSION() as version');
    result.version = versionRows[0].version;
    log(`📌 版本: ${result.version}`, 'cyan');

    // 数据库列表
    const [databases] = await connection.query('SHOW DATABASES');
    log(`💾 数据库数量: ${databases.length}`, 'cyan');

    // 创建测试数据库和表
    await connection.query('CREATE DATABASE IF NOT EXISTS test_performance');
    await connection.query('USE test_performance');
    await connection.query(`
      CREATE TABLE IF NOT EXISTS test_table (
        id INT AUTO_INCREMENT PRIMARY KEY,
        data VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    await connection.query('TRUNCATE TABLE test_table');

    // 性能测试 - 写入
    const writeStart = Date.now();
    for (let i = 0; i < 1000; i++) {
      await connection.query('INSERT INTO test_table (data) VALUES (?)', [`test_data_${i}`]);
    }
    const writeTime = Date.now() - writeStart;
    result.performance.write = {
      records: 1000,
      time: writeTime,
      rps: Math.round(1000 / (writeTime / 1000))
    };
    log(`✍️  写入性能: 1000条记录, ${writeTime}ms, ${result.performance.write.rps} records/s`, 'yellow');

    // 性能测试 - 读取
    const readStart = Date.now();
    for (let i = 0; i < 100; i++) {
      await connection.query('SELECT * FROM test_table LIMIT 100');
    }
    const readTime = Date.now() - readStart;
    result.performance.read = {
      queries: 100,
      time: readTime,
      qps: Math.round(100 / (readTime / 1000))
    };
    log(`📖 读取性能: 100次查询, ${readTime}ms, ${result.performance.read.qps} queries/s`, 'yellow');

    // 连接信息
    const [processlist] = await connection.query('SHOW PROCESSLIST');
    log(`🔗 当前连接数: ${processlist.length}`, 'cyan');

    // 清理
    await connection.query('DROP DATABASE IF EXISTS test_performance');

  } catch (error) {
    log(`❌ MySQL 测试失败: ${error.message}`, 'red');
    result.error = error.message;
  } finally {
    if (connection) {
      await connection.end();
    }
  }

  testResults.services.mysql = result;
  return result;
}

// 生成测试报告
function generateReport() {
  section('📋 测试报告汇总');

  console.log('\n服务可用性:');
  console.log('─'.repeat(80));
  Object.entries(testResults.services).forEach(([name, result]) => {
    const status = result.available ? '✅ 可用' : '❌ 不可用';
    const statusColor = result.available ? 'green' : 'red';
    log(`${result.name.padEnd(20)} ${status.padEnd(15)} 连接时间: ${result.connectionTime}ms`, statusColor);
  });

  console.log('\n性能测试结果:');
  console.log('─'.repeat(80));

  Object.entries(testResults.services).forEach(([name, result]) => {
    if (result.available && result.performance) {
      console.log(`\n${result.name}:`);
      Object.entries(result.performance).forEach(([operation, metrics]) => {
        const metricsStr = Object.entries(metrics)
          .map(([key, value]) => `${key}: ${value}`)
          .join(', ');
        log(`  ${operation}: ${metricsStr}`, 'yellow');
      });
    }
  });

  // 保存报告到文件
  const reportPath = 'SERVICE_TEST_REPORT.json';
  const fs = require('fs');
  fs.writeFileSync(reportPath, JSON.stringify(testResults, null, 2));

  console.log('\n' + '─'.repeat(80));
  log(`\n✅ 详细报告已保存到: ${reportPath}`, 'green');
  log(`📅 测试时间: ${testResults.timestamp}\n`, 'cyan');
}

// 主函数
async function main() {
  log('\n🚀 Fast SocialFi 服务测试开始\n', 'bright');

  try {
    await testPostgreSQL();
    await testRedis();
    await testElasticsearch();
    await testKafka();
    await testMySQL();

    generateReport();

    log('\n✅ 所有测试完成!\n', 'green');
  } catch (error) {
    log(`\n❌ 测试过程出错: ${error.message}\n`, 'red');
    console.error(error);
    process.exit(1);
  }
}

// 运行测试
main();
