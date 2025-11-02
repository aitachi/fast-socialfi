#!/bin/bash

# Fast SocialFi - Stop Services
# Author: Aitachi <44158892@qq.com>

set -e

echo ""
echo "========================================"
echo "Fast SocialFi - Stopping Services"
echo "========================================"
echo ""

if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] Docker is not running!"
    exit 1
fi

echo "Stopping all containers..."
docker-compose down

echo ""
echo "[OK] All services stopped"
echo ""
