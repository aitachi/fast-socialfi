/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

/**
 * Docker 服务资源占用监控脚本
 * 监控 CPU、内存、网络、磁盘等资源使用情况
 */

const { execSync } = require('child_process');
const os = require('os');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function section(title) {
  console.log('\n' + '='.repeat(80));
  log(title, 'bright');
  console.log('='.repeat(80));
}

// 执行 shell 命令
function exec(command) {
  try {
    return execSync(command, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  } catch (error) {
    return error.stdout || '';
  }
}

// 格式化字节大小
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// 格式化百分比
function formatPercent(value) {
  return parseFloat(value).toFixed(2) + '%';
}

// 获取系统信息
function getSystemInfo() {
  section('💻 系统信息');

  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  const usedMem = totalMem - freeMem;

  log(`操作系统: ${os.platform()} ${os.release()}`, 'cyan');
  log(`架构: ${os.arch()}`, 'cyan');
  log(`CPU 核心数: ${os.cpus().length}`, 'cyan');
  log(`总内存: ${formatBytes(totalMem)}`, 'cyan');
  log(`已用内存: ${formatBytes(usedMem)} (${formatPercent((usedMem / totalMem) * 100)})`, 'cyan');
  log(`可用内存: ${formatBytes(freeMem)} (${formatPercent((freeMem / totalMem) * 100)})`, 'cyan');

  return {
    totalMem,
    freeMem,
    usedMem,
    cpuCount: os.cpus().length
  };
}

// 解析 Docker stats 输出
function parseDockerStats() {
  const output = exec('docker stats --no-stream --format "{{.Container}}|{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}"');

  const containers = [];
  const lines = output.trim().split('\n');

  for (const line of lines) {
    if (!line || !line.includes('socialfi-')) continue;

    const [id, name, cpu, memUsage, memPerc, netIO, blockIO] = line.split('|');

    // 解析内存使用
    const memParts = memUsage.split('/');
    const memUsed = memParts[0].trim();
    const memLimit = memParts[1] ? memParts[1].trim() : 'N/A';

    // 解析网络 I/O
    const netParts = netIO.split('/');
    const netInput = netParts[0] ? netParts[0].trim() : '0B';
    const netOutput = netParts[1] ? netParts[1].trim() : '0B';

    // 解析磁盘 I/O
    const blockParts = blockIO.split('/');
    const blockRead = blockParts[0] ? blockParts[0].trim() : '0B';
    const blockWrite = blockParts[1] ? blockParts[1].trim() : '0B';

    containers.push({
      id,
      name,
      cpu: cpu.replace('%', ''),
      memUsed,
      memLimit,
      memPerc: memPerc.replace('%', ''),
      netInput,
      netOutput,
      blockRead,
      blockWrite
    });
  }

  return containers;
}

// 获取容器详细信息
function getContainerDetails(containerName) {
  try {
    const inspect = exec(`docker inspect ${containerName}`);
    const info = JSON.parse(inspect)[0];

    return {
      state: info.State.Status,
      running: info.State.Running,
      startedAt: new Date(info.State.StartedAt),
      image: info.Config.Image,
      restartCount: info.RestartCount
    };
  } catch (error) {
    return null;
  }
}

// 计算运行时间
function getUptime(startedAt) {
  const now = new Date();
  const diff = now - startedAt;

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

  if (days > 0) return `${days}天 ${hours}小时`;
  if (hours > 0) return `${hours}小时 ${minutes}分钟`;
  return `${minutes}分钟`;
}

// 获取数据卷大小
function getVolumeSize() {
  section('💾 数据卷占用');

  const volumes = [
    'fast-socialfi_postgres_data',
    'fast-socialfi_redis_data',
    'fast-socialfi_es_data',
    'fast-socialfi_kafka_data'
  ];

  const volumeInfo = [];
  let totalSize = 0;

  for (const volume of volumes) {
    try {
      // Windows 使用 PowerShell 获取卷大小
      const cmd = `powershell -Command "(docker volume inspect ${volume} | ConvertFrom-Json).Mountpoint | ForEach-Object { (Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum }"`;
      const size = parseInt(exec(cmd).trim()) || 0;

      const serviceName = volume.replace('fast-socialfi_', '').replace('_data', '');
      volumeInfo.push({
        name: serviceName,
        volume,
        size
      });
      totalSize += size;

      log(`${serviceName.padEnd(15)} ${volume.padEnd(35)} ${formatBytes(size)}`, 'yellow');
    } catch (error) {
      // 如果获取失败，尝试其他方法
      volumeInfo.push({
        name: volume.replace('fast-socialfi_', '').replace('_data', ''),
        volume,
        size: 0
      });
    }
  }

  log(`\n总计: ${formatBytes(totalSize)}`, 'bright');

  return { volumeInfo, totalSize };
}

// 监控资源使用
async function monitorResources(duration = 30, interval = 5) {
  section(`📊 资源监控 (${duration}秒, 每${interval}秒采样)`);

  const samples = [];
  const iterations = Math.floor(duration / interval);

  log('开始监控...', 'cyan');
  log('提示: 服务处于空闲状态,无外部请求\n', 'yellow');

  for (let i = 0; i < iterations; i++) {
    const stats = parseDockerStats();
    const timestamp = new Date().toISOString();

    samples.push({
      timestamp,
      stats
    });

    log(`[${i + 1}/${iterations}] 采样时间: ${new Date().toLocaleTimeString()}`, 'cyan');

    if (i < iterations - 1) {
      await new Promise(resolve => setTimeout(resolve, interval * 1000));
    }
  }

  return samples;
}

// 计算平均值
function calculateAverages(samples) {
  const services = {};

  // 收集所有服务的数据
  for (const sample of samples) {
    for (const stat of sample.stats) {
      if (!services[stat.name]) {
        services[stat.name] = {
          name: stat.name,
          cpuSamples: [],
          memSamples: []
        };
      }

      services[stat.name].cpuSamples.push(parseFloat(stat.cpu));
      services[stat.name].memSamples.push(parseFloat(stat.memPerc));
    }
  }

  // 计算平均值
  const averages = [];
  for (const [name, data] of Object.entries(services)) {
    const avgCpu = data.cpuSamples.reduce((a, b) => a + b, 0) / data.cpuSamples.length;
    const avgMem = data.memSamples.reduce((a, b) => a + b, 0) / data.memSamples.length;
    const maxCpu = Math.max(...data.cpuSamples);
    const maxMem = Math.max(...data.memSamples);

    averages.push({
      name,
      avgCpu,
      avgMem,
      maxCpu,
      maxMem
    });
  }

  return averages;
}

// 生成报告
function generateReport(systemInfo, containers, volumeData, samples) {
  section('📋 资源占用报告');

  // 计算平均值
  const averages = calculateAverages(samples);

  console.log('\n服务资源占用汇总:');
  console.log('─'.repeat(100));
  console.log('服务名称'.padEnd(25) +
              'CPU (平均)'.padEnd(15) +
              'CPU (峰值)'.padEnd(15) +
              '内存 (平均)'.padEnd(15) +
              '内存 (峰值)'.padEnd(15) +
              '内存实际用量');
  console.log('─'.repeat(100));

  let totalAvgCpu = 0;
  let totalAvgMem = 0;

  for (const avg of averages) {
    // 从最新的 stats 中获取实际内存用量
    const latestStat = samples[samples.length - 1].stats.find(s => s.name === avg.name);
    const memUsed = latestStat ? latestStat.memUsed : 'N/A';

    log(
      avg.name.padEnd(25) +
      formatPercent(avg.avgCpu).padEnd(15) +
      formatPercent(avg.maxCpu).padEnd(15) +
      formatPercent(avg.avgMem).padEnd(15) +
      formatPercent(avg.maxMem).padEnd(15) +
      memUsed,
      'yellow'
    );

    totalAvgCpu += avg.avgCpu;
    totalAvgMem += avg.avgMem;
  }

  console.log('─'.repeat(100));
  log(`总计 (平均)`.padEnd(25) +
      formatPercent(totalAvgCpu).padEnd(15) +
      '-'.padEnd(15) +
      formatPercent(totalAvgMem).padEnd(15),
      'bright');

  // 容器运行时间
  console.log('\n\n容器运行时间:');
  console.log('─'.repeat(80));

  for (const container of containers) {
    const details = getContainerDetails(container.name);
    if (details) {
      const uptime = getUptime(details.startedAt);
      log(`${container.name.padEnd(30)} 运行时长: ${uptime}`, 'cyan');
    }
  }

  // 网络和磁盘 I/O
  console.log('\n\n网络 & 磁盘 I/O (累计):');
  console.log('─'.repeat(100));
  console.log('服务名称'.padEnd(25) +
              '网络接收'.padEnd(15) +
              '网络发送'.padEnd(15) +
              '磁盘读取'.padEnd(15) +
              '磁盘写入');
  console.log('─'.repeat(100));

  const latestStats = samples[samples.length - 1].stats;
  for (const stat of latestStats) {
    log(
      stat.name.padEnd(25) +
      stat.netInput.padEnd(15) +
      stat.netOutput.padEnd(15) +
      stat.blockRead.padEnd(15) +
      stat.blockWrite,
      'yellow'
    );
  }

  // 数据卷占用
  console.log('\n\n数据卷磁盘占用:');
  console.log('─'.repeat(80));
  for (const vol of volumeData.volumeInfo) {
    log(`${vol.name.padEnd(20)} ${formatBytes(vol.size)}`, 'magenta');
  }
  log(`\n总计: ${formatBytes(volumeData.totalSize)}`, 'bright');

  // 资源占用总结
  section('💡 资源占用总结');

  const systemMemUsage = (totalAvgMem / 100) * systemInfo.totalMem;

  log(`✅ 所有服务正常运行`, 'green');
  log(`\n📊 资源占用 (空闲状态):`, 'cyan');
  log(`   CPU 使用率: ${formatPercent(totalAvgCpu)} (系统总CPU的平均占用)`, 'yellow');
  log(`   内存占用: ${formatPercent(totalAvgMem)} (约 ${formatBytes(systemMemUsage)})`, 'yellow');
  log(`   磁盘占用: ${formatBytes(volumeData.totalSize)} (数据卷)`, 'yellow');

  log(`\n📈 资源影响评估:`, 'cyan');
  if (totalAvgCpu < 5) {
    log(`   CPU: ✅ 极低 (几乎无影响)`, 'green');
  } else if (totalAvgCpu < 10) {
    log(`   CPU: ✅ 低 (轻微影响)`, 'green');
  } else {
    log(`   CPU: ⚠️  中等 (有一定影响)`, 'yellow');
  }

  if (totalAvgMem < 10) {
    log(`   内存: ✅ 极低 (几乎无影响)`, 'green');
  } else if (totalAvgMem < 20) {
    log(`   内存: ✅ 低 (轻微影响)`, 'green');
  } else if (totalAvgMem < 30) {
    log(`   内存: ⚠️  中等 (有一定影响)`, 'yellow');
  } else {
    log(`   内存: ⚠️  较高 (建议关闭不用的服务)`, 'red');
  }

  log(`\n💰 成本估算:`, 'cyan');
  log(`   如果服务器按 8GB 内存计算,这些服务占用约 ${formatPercent((systemMemUsage / (8 * 1024 * 1024 * 1024)) * 100)}`, 'yellow');
  log(`   建议: ${totalAvgMem > 20 ? '考虑按需启动服务' : '可以长期保持运行'}`, totalAvgMem > 20 ? 'yellow' : 'green');

  // 保存报告
  const report = {
    timestamp: new Date().toISOString(),
    systemInfo: {
      totalMemory: formatBytes(systemInfo.totalMem),
      availableMemory: formatBytes(systemInfo.freeMem),
      cpuCores: systemInfo.cpuCount
    },
    summary: {
      avgCpuUsage: totalAvgCpu,
      avgMemUsage: totalAvgMem,
      totalDiskUsage: volumeData.totalSize
    },
    services: averages.map(avg => {
      const latest = latestStats.find(s => s.name === avg.name);
      return {
        name: avg.name,
        cpu: {
          average: avg.avgCpu,
          max: avg.maxCpu
        },
        memory: {
          average: avg.avgMem,
          max: avg.maxMem,
          actual: latest ? latest.memUsed : 'N/A'
        },
        network: latest ? {
          input: latest.netInput,
          output: latest.netOutput
        } : null,
        disk: latest ? {
          read: latest.blockRead,
          write: latest.blockWrite
        } : null
      };
    }),
    volumes: volumeData.volumeInfo.map(v => ({
      name: v.name,
      size: v.size,
      sizeFormatted: formatBytes(v.size)
    })),
    samples
  };

  const fs = require('fs');
  fs.writeFileSync('RESOURCE_USAGE_REPORT.json', JSON.stringify(report, null, 2));

  console.log('\n' + '─'.repeat(80));
  log(`\n✅ 详细报告已保存到: RESOURCE_USAGE_REPORT.json`, 'green');
  log(`📅 监控时间: ${new Date().toLocaleString()}\n`, 'cyan');
}

// 主函数
async function main() {
  log('\n🔍 Docker 服务资源监控开始\n', 'bright');

  try {
    // 1. 获取系统信息
    const systemInfo = getSystemInfo();

    // 2. 获取容器列表
    section('🐳 Docker 容器状态');
    const containers = parseDockerStats();

    if (containers.length === 0) {
      log('❌ 未找到运行中的 socialfi 服务', 'red');
      log('请先启动服务: docker-compose -f docker-compose.full.yml up -d', 'yellow');
      return;
    }

    log(`找到 ${containers.length} 个运行中的容器:\n`, 'cyan');
    for (const container of containers) {
      log(`  ✅ ${container.name}`, 'green');
    }

    // 3. 获取数据卷大小
    const volumeData = getVolumeSize();

    // 4. 监控资源使用 (30秒,每5秒采样)
    const samples = await monitorResources(30, 5);

    // 5. 生成报告
    generateReport(systemInfo, containers, volumeData, samples);

    log('\n✅ 监控完成!\n', 'green');

  } catch (error) {
    log(`\n❌ 监控过程出错: ${error.message}\n`, 'red');
    console.error(error);
    process.exit(1);
  }
}

// 运行监控
main();
