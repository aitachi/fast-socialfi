#!/bin/bash

# Fast SocialFi Backend Initialization Script
# This script initializes the database and installs dependencies

set -e

echo "========================================="
echo "  Fast SocialFi Backend Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js >= 18.0.0"
    exit 1
fi

echo -e "${GREEN}✓ Node.js version:${NC} $(node --version)"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ npm version:${NC} $(npm --version)"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}Warning: psql command not found${NC}"
    echo "PostgreSQL might not be installed or not in PATH"
else
    echo -e "${GREEN}✓ PostgreSQL is installed${NC}"
fi

echo ""
echo "========================================="
echo "  Step 1: Installing Dependencies"
echo "========================================="
echo ""

cd backend-node

if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found${NC}"
    exit 1
fi

npm install

echo ""
echo -e "${GREEN}✓ Dependencies installed successfully${NC}"

echo ""
echo "========================================="
echo "  Step 2: Setting up Environment"
echo "========================================="
echo ""

if [ ! -f ".env" ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo -e "${YELLOW}⚠ Please edit .env file with your actual configuration${NC}"
    echo -e "${YELLOW}⚠ Especially change the JWT_SECRET for production!${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

echo ""
echo "========================================="
echo "  Step 3: Database Initialization"
echo "========================================="
echo ""

read -p "Do you want to initialize the PostgreSQL database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Initializing database..."

    # Get database credentials
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    DB_NAME="${DB_NAME:-socialfi_db}"
    DB_USER="${DB_USER:-socialfi}"
    DB_PASSWORD="${DB_PASSWORD:-socialfi_pg_pass_2024}"

    echo "Database Configuration:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo ""

    # Create database schema
    echo "Creating database schema..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f ../database/schema.sql

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database schema created successfully${NC}"
    else
        echo -e "${RED}✗ Failed to create database schema${NC}"
        echo "Please check your database configuration in .env"
    fi

    # Load seed data
    read -p "Do you want to load test data? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Loading test data..."
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f ../database/seed.sql

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Test data loaded successfully${NC}"
        else
            echo -e "${RED}✗ Failed to load test data${NC}"
        fi
    fi
fi

echo ""
echo "========================================="
echo "  Step 4: Testing Connections"
echo "========================================="
echo ""

read -p "Do you want to test database connections? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Testing connections..."
    npx ts-node test-connections.ts
fi

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit .env file with your configuration"
echo "  2. Start development server:"
echo "     cd backend-node"
echo "     npm run dev"
echo ""
echo "  3. Access API at: http://localhost:3000/api"
echo "  4. View API documentation: backend-node/README.md"
echo "  5. Test API endpoints: backend-node/API_TESTS.md"
echo ""
echo "========================================="
