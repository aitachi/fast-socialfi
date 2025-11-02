@echo off
REM Fast SocialFi Backend Initialization Script for Windows
REM This script initializes the database and installs dependencies

echo =========================================
echo   Fast SocialFi Backend Setup
echo =========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Node.js is not installed
    echo Please install Node.js >= 18.0.0
    exit /b 1
)

echo [OK] Node.js version:
node --version

REM Check if npm is installed
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: npm is not installed
    exit /b 1
)

echo [OK] npm version:
npm --version

REM Check if PostgreSQL is installed
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Warning: psql command not found
    echo PostgreSQL might not be installed or not in PATH
) else (
    echo [OK] PostgreSQL is installed
)

echo.
echo =========================================
echo   Step 1: Installing Dependencies
echo =========================================
echo.

cd backend-node

if not exist package.json (
    echo Error: package.json not found
    exit /b 1
)

call npm install

if %ERRORLEVEL% NEQ 0 (
    echo Failed to install dependencies
    exit /b 1
)

echo.
echo [OK] Dependencies installed successfully

echo.
echo =========================================
echo   Step 2: Setting up Environment
echo =========================================
echo.

if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo [WARNING] Please edit .env file with your actual configuration
    echo [WARNING] Especially change the JWT_SECRET for production!
) else (
    echo [OK] .env file already exists
)

echo.
echo =========================================
echo   Step 3: Database Initialization
echo =========================================
echo.

set /p INIT_DB="Do you want to initialize the PostgreSQL database? (y/n): "
if /i "%INIT_DB%"=="y" (
    echo.
    echo Initializing database...

    REM Get database credentials from .env or use defaults
    set DB_HOST=localhost
    set DB_PORT=5432
    set DB_NAME=socialfi_db
    set DB_USER=socialfi
    set DB_PASSWORD=socialfi_pg_pass_2024

    echo Database Configuration:
    echo   Host: %DB_HOST%
    echo   Port: %DB_PORT%
    echo   Database: %DB_NAME%
    echo   User: %DB_USER%
    echo.

    REM Create database schema
    echo Creating database schema...
    set PGPASSWORD=%DB_PASSWORD%
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f ..\database\schema.sql

    if %ERRORLEVEL% EQU 0 (
        echo [OK] Database schema created successfully
    ) else (
        echo [FAIL] Failed to create database schema
        echo Please check your database configuration in .env
    )

    REM Load seed data
    set /p LOAD_SEED="Do you want to load test data? (y/n): "
    if /i "%LOAD_SEED%"=="y" (
        echo Loading test data...
        psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f ..\database\seed.sql

        if %ERRORLEVEL% EQU 0 (
            echo [OK] Test data loaded successfully
        ) else (
            echo [FAIL] Failed to load test data
        )
    )
)

echo.
echo =========================================
echo   Step 4: Testing Connections
echo =========================================
echo.

set /p TEST_CONN="Do you want to test database connections? (y/n): "
if /i "%TEST_CONN%"=="y" (
    echo.
    echo Testing connections...
    call npx ts-node test-connections.ts
)

echo.
echo =========================================
echo   Setup Complete!
echo =========================================
echo.
echo Next steps:
echo.
echo   1. Edit .env file with your configuration
echo   2. Start development server:
echo      cd backend-node
echo      npm run dev
echo.
echo   3. Access API at: http://localhost:3000/api
echo   4. View API documentation: backend-node\README.md
echo   5. Test API endpoints: backend-node\API_TESTS.md
echo.
echo =========================================

pause
