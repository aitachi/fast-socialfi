/**
 * 智能服务启动器
 * 根据应用需求自动检测并启动所需的服务
 */

const { execSync } = require('child_process');
const path = require('path');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// 执行命令
function exec(command) {
  try {
    return execSync(command, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  } catch (error) {
    return null;
  }
}

// 检查服务是否运行
function isServiceRunning(serviceName) {
  const output = exec(`docker ps --filter "name=${serviceName}" --format "{{.Names}}"`);
  return output && output.includes(serviceName);
}

// 启动服务
function startService(serviceName, displayName) {
  log(`\n启动 ${displayName}...`, 'cyan');

  const isWin = process.platform === 'win32';
  const scriptExt = isWin ? '.bat' : '.sh';
  const scriptPath = path.join(__dirname, `start-${serviceName}${scriptExt}`);

  try {
    execSync(`"${scriptPath}" auto`, { stdio: 'inherit' });
    log(`✓ ${displayName} 启动成功`, 'green');
    return true;
  } catch (error) {
    log(`✗ ${displayName} 启动失败: ${error.message}`, 'yellow');
    return false;
  }
}

// 服务定义
const SERVICES = {
  postgres: {
    containerName: 'socialfi-postgres',
    displayName: 'PostgreSQL',
    required: true,
    memoryMB: 37
  },
  redis: {
    containerName: 'socialfi-redis',
    displayName: 'Redis',
    required: true,
    memoryMB: 5
  },
  elasticsearch: {
    containerName: 'socialfi-elasticsearch',
    displayName: 'Elasticsearch',
    required: false,
    memoryMB: 1064,
    startScript: 'elasticsearch'
  },
  kafka: {
    containerName: 'socialfi-kafka',
    displayName: 'Kafka',
    required: false,
    memoryMB: 400,
    startScript: 'kafka'
  }
};

// 检测应用需求
function detectRequiredServices(appPath) {
  const requiredServices = new Set(['postgres', 'redis']); // 核心服务始终需要

  if (!appPath) {
    return requiredServices;
  }

  try {
    const fs = require('fs');

    // 检测是否使用 Elasticsearch
    const esPatterns = [
      '@elastic/elasticsearch',
      'elasticsearch',
      'esClient',
      'searchIndex'
    ];

    // 检测是否使用 Kafka
    const kafkaPatterns = [
      'kafkajs',
      'kafka',
      'producer.send',
      'consumer.run'
    ];

    // 读取常见的应用文件
    const filesToCheck = [
      'package.json',
      'src/index.js',
      'src/app.js',
      'src/server.js',
      'backend/index.js'
    ];

    for (const file of filesToCheck) {
      const filePath = path.join(appPath, file);
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');

        // 检测 Elasticsearch
        if (esPatterns.some(pattern => content.includes(pattern))) {
          requiredServices.add('elasticsearch');
        }

        // 检测 Kafka
        if (kafkaPatterns.some(pattern => content.includes(pattern))) {
          requiredServices.add('kafka');
        }
      }
    }
  } catch (error) {
    // 如果检测失败,只启动核心服务
  }

  return requiredServices;
}

// 主函数
async function main() {
  log('\n╔════════════════════════════════════════╗', 'bright');
  log('║   Fast SocialFi 智能服务启动器        ║', 'bright');
  log('╚════════════════════════════════════════╝\n', 'bright');

  // 检查 Docker 是否运行
  const dockerInfo = exec('docker info');
  if (!dockerInfo) {
    log('❌ Docker 未运行，请先启动 Docker Desktop', 'yellow');
    process.exit(1);
  }

  // 检测需要的服务
  const appPath = process.argv[2] || process.cwd();
  log(`检测应用目录: ${appPath}`, 'cyan');

  const requiredServices = detectRequiredServices(appPath);

  log('\n检测到需要以下服务:', 'cyan');
  const serviceList = Array.from(requiredServices).map(s => SERVICES[s].displayName);
  log(`  ${serviceList.join(', ')}`, 'yellow');

  // 计算预计内存占用
  const totalMemory = Array.from(requiredServices)
    .reduce((sum, s) => sum + SERVICES[s].memoryMB, 0);
  log(`\n预计内存占用: ${totalMemory} MB`, 'cyan');

  log('\n开始启动服务...', 'bright');
  log('─'.repeat(50));

  // 检查并启动服务
  const results = [];

  for (const serviceKey of requiredServices) {
    const service = SERVICES[serviceKey];
    const isRunning = isServiceRunning(service.containerName);

    if (isRunning) {
      log(`\n✓ ${service.displayName} - 已在运行`, 'green');
      results.push({ service: service.displayName, status: 'already_running' });
    } else {
      log(`\n⏳ ${service.displayName} - 需要启动`, 'yellow');

      if (service.startScript) {
        const success = startService(service.startScript, service.displayName);
        results.push({
          service: service.displayName,
          status: success ? 'started' : 'failed'
        });
      } else {
        // 核心服务通过 docker-compose 启动
        try {
          execSync(`docker-compose -f docker-compose.full.yml up -d ${serviceKey}`,
            { stdio: 'inherit' });
          log(`✓ ${service.displayName} 启动成功`, 'green');
          results.push({ service: service.displayName, status: 'started' });
        } catch (error) {
          log(`✗ ${service.displayName} 启动失败`, 'yellow');
          results.push({ service: service.displayName, status: 'failed' });
        }
      }
    }
  }

  // 显示总结
  log('\n' + '═'.repeat(50), 'bright');
  log('启动总结', 'bright');
  log('═'.repeat(50), 'bright');

  const started = results.filter(r => r.status === 'started');
  const alreadyRunning = results.filter(r => r.status === 'already_running');
  const failed = results.filter(r => r.status === 'failed');

  if (started.length > 0) {
    log(`\n✅ 新启动: ${started.length} 个服务`, 'green');
    started.forEach(r => log(`   - ${r.service}`, 'green'));
  }

  if (alreadyRunning.length > 0) {
    log(`\n✓ 已运行: ${alreadyRunning.length} 个服务`, 'cyan');
    alreadyRunning.forEach(r => log(`   - ${r.service}`, 'cyan'));
  }

  if (failed.length > 0) {
    log(`\n❌ 启动失败: ${failed.length} 个服务`, 'yellow');
    failed.forEach(r => log(`   - ${r.service}`, 'yellow'));
  }

  // 显示服务状态
  log('\n当前运行的服务:', 'bright');
  const output = exec('docker ps --filter "name=socialfi-" --format "table {{.Names}}\\t{{.Status}}"');
  if (output) {
    console.log(output);
  }

  log('\n提示:', 'cyan');
  log('  - 停止所有服务: docker-compose -f docker-compose.full.yml down', 'yellow');
  log('  - 切换最小模式: set-minimal-mode.bat (仅 PostgreSQL + Redis)', 'yellow');
  log('  - 查看资源占用: node monitor-resources.js', 'yellow');

  log('\n✅ 所有服务已就绪!\n', 'green');
}

// 运行
main().catch(error => {
  console.error('启动失败:', error);
  process.exit(1);
});
