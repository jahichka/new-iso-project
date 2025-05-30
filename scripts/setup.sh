#!/bin/bash

echo "🚀 Postavljanje Web Aplikacije (bez Docker Compose)..."
echo "====================================================="

# Provjeri da li je Docker instaliran
if ! command -v docker &> /dev/null; then
    echo "❌ Docker nije instaliran. Molimo instaliraj Docker prvo."
    exit 1
fi

echo "✅ Docker je instaliran"

# Kreiraj Docker network
echo "🌐 Kreiram Docker network..."
docker network create webapp-network 2>/dev/null || true

# Zaustavi i obriši postojeće kontejnere
echo "🧹 Čistim stare kontejnere..."
docker stop webapp-postgres webapp-backend webapp-frontend webapp-redis webapp-pgadmin 2>/dev/null || true
docker rm webapp-postgres webapp-backend webapp-frontend webapp-redis webapp-pgadmin 2>/dev/null || true

# Kreiraj volume za PostgreSQL
echo "💾 Kreiram Docker volume za bazu..."
docker volume create postgres_data 2>/dev/null || true
docker volume create redis_data 2>/dev/null || true

# Build backend image
echo "🔨 Gradim backend..."
docker build -f Dockerfile.backend -t webapp-backend .

# Build frontend image  
echo "🔨 Gradim frontend..."
docker build -f Dockerfile.frontend -t webapp-frontend .

echo ""
echo "🎉 Setup je završen uspješno!"
echo ""
echo "Da pokreneš aplikaciju, pokreni:"
echo "  ./start.sh"