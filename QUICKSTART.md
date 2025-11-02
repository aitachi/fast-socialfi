# Fast SocialFi - Quick Start Guide

**Author:** Aitachi <44158892@qq.com>
**Last Updated:** 2025-11-02

---

## Prerequisites

- Docker Desktop
- Node.js >= 18.0.0
- PostgreSQL (optional, can use Docker)
- Git

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/fast-socialfi.git
cd fast-socialfi
```

### 2. Start Services

#### Option A: All Services (Recommended)
```bash
# Windows
start-all-services.bat

# Linux/Mac
chmod +x start-all-services.sh
./start-all-services.sh
```

#### Option B: Database Services Only
```bash
# Windows
start-databases.bat

# Linux/Mac
./start-databases.sh
```

#### Option C: Smart Start (Auto-detect)
```bash
# Windows
smart-start.bat

# Linux/Mac
./smart-start.sh
```

### 3. Setup Backend

```bash
# Windows
setup-backend.bat

# Linux/Mac
chmod +x setup-backend.sh
./setup-backend.sh
```

### 4. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Backend API | http://localhost:8080 | - |
| PostgreSQL | localhost:5432 | socialfi / socialfi_pg_pass_2024 |
| Redis | localhost:6379 | Password: socialfi_redis_2024 |
| Elasticsearch | http://localhost:9200 | - |
| Kafka | localhost:9092 | - |
| Kafka UI | http://localhost:8090 | - |

---

## Available Scripts

### Windows Scripts (.bat)

| Script | Purpose |
|--------|---------|
| `docker-start.bat` | Start Docker services (docker-compose.yml) |
| `docker-stop.bat` | Stop all Docker services |
| `check-services.bat` | Check service status and resource usage |
| `start-databases.bat` | Start database services (PostgreSQL, Redis, ES, Kafka) |
| `start-all-services.bat` | Start all services (full stack) |
| `smart-start.bat` | Smart startup (auto-detect required services) |
| `setup-backend.bat` | Setup backend (install deps, init DB) |
| `setup-autostart-all.bat` | Configure Windows auto-start |

### Linux/Mac Scripts (.sh)

| Script | Purpose |
|--------|---------|
| `setup-backend.sh` | Setup backend (install deps, init DB) |

---

## Docker Compose Files

| File | Services Included |
|------|-------------------|
| `docker-compose.yml` | Basic setup (Backend + MySQL + Redis) |
| `docker-compose.db.yml` | Database only (PostgreSQL + Redis) |
| `docker-compose.full.yml` | Full stack (PostgreSQL + Redis + ES + Kafka) |

---

## Service Configuration

### PostgreSQL
- **Host:** localhost:5432
- **Database:** socialfi_db
- **User:** socialfi
- **Password:** socialfi_pg_pass_2024
- **Container:** socialfi-postgres

### Redis
- **Host:** localhost:6379
- **Password:** socialfi_redis_2024
- **Container:** socialfi-redis

### Elasticsearch
- **HTTP:** http://localhost:9200
- **Transport:** localhost:9300
- **Container:** socialfi-elasticsearch

### Kafka (KRaft Mode)
- **Bootstrap:** localhost:9092
- **Controller:** localhost:9093
- **Container:** socialfi-kafka

### Kafka UI
- **Web UI:** http://localhost:8090
- **Container:** socialfi-kafka-ui

---

## Useful Commands

### Docker Management

```bash
# View logs
docker-compose logs -f

# View specific service logs
docker logs -f socialfi-postgres

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Remove all data (CAUTION!)
docker-compose down -v
```

### Database Access

```bash
# PostgreSQL
docker exec -it socialfi-postgres psql -U socialfi -d socialfi_db

# Redis
docker exec -it socialfi-redis redis-cli -a socialfi_redis_2024

# Elasticsearch
curl http://localhost:9200/_cat/indices?v

# Kafka - List topics
docker exec socialfi-kafka kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Service Health Checks

```bash
# Check PostgreSQL
docker exec socialfi-postgres pg_isready -U socialfi

# Check Redis
docker exec socialfi-redis redis-cli ping

# Check Elasticsearch
curl http://localhost:9200/_cluster/health

# Check Kafka
docker exec socialfi-kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

---

## Auto-start Configuration

### Windows

Run `setup-autostart-all.bat` to configure Windows auto-start.

**Requirements:**
1. Docker Desktop must be set to start on login
2. Script will be placed in Startup folder
3. Services start 45 seconds after boot

### Linux (systemd)

```bash
# Copy service file
sudo cp docker-socialfi.service /etc/systemd/system/

# Enable service
sudo systemctl enable docker-socialfi.service

# Start service
sudo systemctl start docker-socialfi.service

# Check status
sudo systemctl status docker-socialfi.service
```

---

## Troubleshooting

### Docker not running
```bash
# Check Docker status
docker info

# Start Docker Desktop (Windows/Mac)
# Or: sudo systemctl start docker (Linux)
```

### Port conflicts
```bash
# Check ports in use
netstat -ano | findstr "5432 6379 9200 9092"  # Windows
lsof -i :5432,:6379,:9200,:9092  # Linux/Mac
```

### Reset all services
```bash
# Stop and remove all containers and volumes
docker-compose -f docker-compose.full.yml down -v

# Restart
docker-compose -f docker-compose.full.yml up -d
```

### View resource usage
```bash
# Check container stats
docker stats

# Or use check-services.bat (Windows)
check-services.bat
```

---

## Development Workflow

### 1. Start Database Services
```bash
start-databases.bat  # or start-all-services.bat
```

### 2. Setup Backend
```bash
setup-backend.bat
cd backend-node
npm run dev
```

### 3. Deploy Smart Contracts
```bash
npx hardhat compile
npx hardhat run scripts/socialfi/deploy.ts --network sepolia
```

### 4. Run Tests
```bash
# Backend tests
cd backend-node
npm test

# Smart contract tests
npx hardhat test
```

---

## Project Structure

```
fast-socialfi/
├── backend-node/          # Node.js backend
├── contracts/             # Solidity smart contracts
├── database/              # Database schemas and migrations
├── scripts/               # Deployment scripts
├── tests/                 # Test suites
├── docs/                  # Documentation
├── docker-compose*.yml    # Docker configurations
├── *.bat                  # Windows scripts
├── *.sh                   # Linux/Mac scripts
└── README.md             # Project overview
```

---

## Support

- **GitHub Issues:** https://github.com/yourusername/fast-socialfi/issues
- **Email:** 44158892@qq.com

---

## License

MIT License - see LICENSE file for details
