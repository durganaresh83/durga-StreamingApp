# ============================================================================
# LOCAL TESTING SETUP - Docker Compose Start Guide
# ============================================================================
# This script helps you start all services locally using docker-compose

Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║                  🚀 STARTING LOCAL DOCKER SERVICES                        ║
╚════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check if docker is installed
Write-Host "📦 Checking Docker installation..." -ForegroundColor Yellow
$dockerVersion = docker --version 2>$null
if ($null -eq $dockerVersion) {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Docker version: $dockerVersion" -ForegroundColor Green

# Check if docker-compose is installed
Write-Host "📦 Checking Docker Compose installation..." -ForegroundColor Yellow
$composeVersion = docker-compose --version 2>$null
if ($null -eq $composeVersion) {
    Write-Host "❌ Docker Compose is not installed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker Compose version: $composeVersion" -ForegroundColor Green

# Check if .env file exists
Write-Host "📄 Checking .env file..." -ForegroundColor Yellow
if (-not (Test-Path ".env")) {
    Write-Host "❌ .env file not found in current directory" -ForegroundColor Red
    exit 1
}
Write-Host "✓ .env file found" -ForegroundColor Green

Write-Host @"

════════════════════════════════════════════════════════════════════════════════

📝 CONFIGURATION:
  Services will start with the following ports:
  - Frontend:     http://localhost:3000
  - Auth API:     http://localhost:3001
  - Streaming:    http://localhost:3002
  - Admin API:    http://localhost:3003
  - Chat API:     http://localhost:3004
  - MongoDB:      localhost:27017

════════════════════════════════════════════════════════════════════════════════

🔄 Starting services... (this may take 2-3 minutes)

"@ -ForegroundColor Cyan

# Start docker-compose
Write-Host "Step 1/3: Building Docker images and starting containers..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start services" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Services started" -ForegroundColor Green

# Wait for services to be ready
Write-Host "`nStep 2/3: Waiting for services to be ready (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check service status
Write-Host "Step 3/3: Checking service status..." -ForegroundColor Yellow
$services = docker-compose ps --services

Write-Host @"

════════════════════════════════════════════════════════════════════════════════

✅ SERVICES STARTED SUCCESSFULLY!

📊 Running Containers:
"@ -ForegroundColor Green

docker-compose ps

Write-Host @"

════════════════════════════════════════════════════════════════════════════════

🌐 ACCESS YOUR APPLICATION:

1. Frontend:        http://localhost:3000
2. Auth API:        http://localhost:3001/api
3. Streaming API:   http://localhost:3002/api
4. Admin API:       http://localhost:3003/api/admin
5. Chat API:        http://localhost:3004/api/chat

════════════════════════════════════════════════════════════════════════════════

📋 USEFUL COMMANDS:

View logs:
  docker-compose logs -f <service-name>
  
  Examples:
  docker-compose logs -f frontend
  docker-compose logs -f auth
  docker-compose logs -f streaming

Stop services:
  docker-compose down

Rebuild services:
  docker-compose up -d --build

Check container status:
  docker ps
  docker-compose ps

════════════════════════════════════════════════════════════════════════════════

🧪 TESTING THE APPLICATION:

1. Open http://localhost:3000 in your browser
2. Test user registration and login (uses auth service)
3. Browse videos (uses streaming service)
4. Test admin functionality (uses admin service)
5. Test chat feature (uses chat service)

════════════════════════════════════════════════════════════════════════════════

"@ -ForegroundColor Green

Write-Host "✨ Setup complete! Your streaming application is now running locally." -ForegroundColor Green
