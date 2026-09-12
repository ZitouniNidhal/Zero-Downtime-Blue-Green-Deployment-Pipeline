@echo off
echo ================================
echo Blue-Green Deployment Setup (Windows)
echo ================================
echo.

echo Checking prerequisites...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo X Docker is not installed. Please install Docker Desktop.
    exit /b 1
)
echo ✓ Docker found.

git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo X Git is not installed. Please install Git for Windows.
    exit /b 1
)
echo ✓ Git found.

echo.
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo ✓ .env created.
) else (
    echo ✓ .env already exists.
)

echo.
echo Building Docker images...
docker compose build

echo.
echo Starting services...
docker compose up -d

echo.
echo Waiting for services to be ready...
:loop
curl -s http://localhost/health >nul 2>&1
if %errorlevel% neq 0 (
    echo   Waiting...
    timeout /t 2 >nul
    goto loop
)

echo ✓ Services are ready!
echo.
echo ================================
echo Setup Complete!
echo ================================
echo.
echo Next steps:
echo 1. Verify: curl http://localhost/
echo 2. Deploy: bash deploy.sh v2
echo.
pause