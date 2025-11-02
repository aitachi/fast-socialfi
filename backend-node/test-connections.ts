import db from './src/config/database';
import redisClient from './src/config/redis';
import esClient from './src/config/elasticsearch';
import kafkaClient from './src/config/kafka';
import blockchainClient from './src/config/blockchain';

/**
 * Test all database and service connections
 */
async function testConnections() {
  console.log('\n========================================');
  console.log('  Testing Database Connections');
  console.log('========================================\n');

  let allSuccess = true;

  // Test PostgreSQL
  try {
    console.log('1. Testing PostgreSQL...');
    const dbOk = await db.testConnection();
    const poolStatus = db.getPoolStatus();
    console.log(`   Status: ${dbOk ? '✓ Connected' : '✗ Failed'}`);
    console.log(`   Pool: ${poolStatus.totalCount} total, ${poolStatus.idleCount} idle\n`);
    allSuccess = allSuccess && dbOk;
  } catch (error) {
    console.error('   Status: ✗ Failed');
    console.error('   Error:', error);
    allSuccess = false;
  }

  // Test Redis
  try {
    console.log('2. Testing Redis...');
    const redisOk = await redisClient.testConnection();
    console.log(`   Status: ${redisOk ? '✓ Connected' : '✗ Failed'}`);
    console.log(`   Connected: ${redisClient.connected}\n`);
    allSuccess = allSuccess && redisOk;
  } catch (error) {
    console.error('   Status: ✗ Failed');
    console.error('   Error:', error);
    allSuccess = false;
  }

  // Test Elasticsearch
  try {
    console.log('3. Testing Elasticsearch...');
    await esClient.initialize();
    const esOk = await esClient.testConnection();
    console.log(`   Status: ${esOk ? '✓ Connected' : '✗ Failed'}\n`);
    allSuccess = allSuccess && esOk;
  } catch (error) {
    console.error('   Status: ✗ Failed');
    console.error('   Error:', error);
    allSuccess = false;
  }

  // Test Kafka
  try {
    console.log('4. Testing Kafka...');
    await kafkaClient.initialize();
    const kafkaOk = await kafkaClient.testConnection();
    console.log(`   Status: ${kafkaOk ? '✓ Connected' : '✗ Failed'}\n`);
    allSuccess = allSuccess && kafkaOk;
  } catch (error) {
    console.error('   Status: ✗ Failed');
    console.error('   Error:', error);
    allSuccess = false;
  }

  // Test Blockchain
  try {
    console.log('5. Testing Blockchain RPC...');
    const blockchainOk = await blockchainClient.testConnection();
    console.log(`   Status: ${blockchainOk ? '✓ Connected' : '✗ Failed'}\n`);
    allSuccess = allSuccess && blockchainOk;
  } catch (error) {
    console.error('   Status: ✗ Failed');
    console.error('   Error:', error);
    allSuccess = false;
  }

  // Summary
  console.log('========================================');
  if (allSuccess) {
    console.log('  ✓ All connections successful!');
  } else {
    console.log('  ✗ Some connections failed');
    console.log('  Please check the errors above');
  }
  console.log('========================================\n');

  // Cleanup
  await cleanup();

  process.exit(allSuccess ? 0 : 1);
}

/**
 * Cleanup connections
 */
async function cleanup() {
  try {
    await db.close();
    await redisClient.close();
    await esClient.close();
    await kafkaClient.disconnect();
  } catch (error) {
    console.error('Error during cleanup:', error);
  }
}

// Run tests
testConnections();
