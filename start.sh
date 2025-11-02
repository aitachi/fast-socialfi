#!/bin/bash

# Fast SocialFi - Quick Start

set -e

echo ""
echo "========================================"
echo "Fast SocialFi Platform"
echo "========================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] Docker is not running!"
    echo "Please start Docker and try again."
    exit 1
fi

echo "[1/3] Docker is running..."

# Stop existing containers
echo "[2/3] Cleaning up..."
docker-compose down 2>/dev/null || true

# Start services
echo "[3/3] Starting services..."
docker-compose up -d

echo ""
echo "========================================"
echo "Service Status:"
echo "========================================"
docker-compose ps

echo ""
echo "========================================"
echo "Quick Links:"
echo "========================================"
echo "Backend API:  http://localhost:8080"
echo "PostgreSQL:   localhost:5432"
echo "Redis:        localhost:6379"
echo ""
echo "Useful commands:"
echo "  View logs:  docker-compose logs -f"
echo "  Stop:       ./stop.sh"
echo "========================================"
echo ""
