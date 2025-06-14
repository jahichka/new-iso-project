#!/bin/bash

echo "🚀 Pokretanje Web Aplikacije..."
echo "==============================="

if ! docker info &> /dev/null; then
    echo "❌ Docker nije pokrenut. Molimo pokreni Docker prvo."
    exit 1
fi

echo "▶️  Pokretam kontejnere..."

echo "🗄️  Pokretam PostgreSQL..."
docker run -d \
    --name webapp-postgres \
    --network webapp-network \
    -e POSTGRES_DB=webapp_db \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres123 \
    -v postgres_data:/var/lib/postgresql/data \
    -v "$(pwd)/init.sql:/docker-entrypoint-initdb.d/init.sql" \
    -p 54321:5432 \
    postgres:15-alpine

echo "🔴 Pokretam Redis..."
docker run -d \
    --name webapp-redis \
    --network webapp-network \
    -v redis_data:/data \
    -p 6379:6379 \
    redis:7-alpine redis-server --appendonly yes

echo "⏳ Čekam da PostgreSQL bude spreman..."
for i in {1..30}; do
    if docker exec webapp-postgres pg_isready -U postgres -d webapp_db &> /dev/null; then
        echo "✅ PostgreSQL je spreman"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ PostgreSQL se nije pokrenuo na vrijeme"
        docker logs webapp-postgres
        exit 1
    fi
    sleep 2
done

echo "⚙️  Pokretam Backend..."
docker run -d \
    --name webapp-backend \
    --network webapp-network \
    -e NODE_ENV=production \
    -e PORT=3000 \
    -e DB_HOST=webapp-postgres \
    -e DB_PORT=5432 \
    -e DB_NAME=webapp_db \
    -e DB_USER=postgres \
    -e DB_PASSWORD=postgres123 \
    -p 3000:3000 \
    webapp-backend

echo "⏳ Čekam da Backend bude spreman..."
sleep 5
for i in {1..20}; do
    if curl -f http://localhost:3000/health &> /dev/null; then
        echo "✅ Backend je spreman"
        break
    fi
    if [ $i -eq 20 ]; then
        echo "❌ Backend se nije pokrenuo na vrijeme"
        docker logs webapp-backend
        exit 1
    fi
    sleep 2
done

echo "🌐 Pokretam Frontend..."
docker run -d \
    --name webapp-frontend \
    --network webapp-network \
    --link webapp-backend:backend \
    -p 80:80 \
    webapp-frontend

echo "⏳ Čekam da Frontend bude spreman..."
sleep 10
for i in {1..15}; do
    if curl -f http://localhost/ &> /dev/null; then
        echo "✅ Frontend je spreman"
        break
    fi
    if [ $i -eq 15 ]; then
        echo "❌ Frontend se nije pokrenuo na vrijeme"
        echo "🔍 Logovi frontend kontejnera:"
        docker logs webapp-frontend
        exit 1
    fi
    sleep 3
done

echo "🔧 Pokretam pgAdmin..."
docker run -d \
    --name webapp-pgadmin \
    --network webapp-network \
    -e PGADMIN_DEFAULT_EMAIL=admin@webapp.com \
    -e PGADMIN_DEFAULT_PASSWORD=admin123 \
    -p 8080:80 \
    dpage/pgadmin4:latest

echo ""
echo "🎉 Aplikacija je uspješno pokrenuta!"
echo "===================================="
echo ""
echo "📱 Web Aplikacija:     http://localhost"
echo "🔧 Backend API:        http://localhost:3000/api"
echo "🗄️  pgAdmin:           http://localhost:8080"
echo "   📧 Email: admin@webapp.com"
echo "   🔑 Password: admin123"
echo ""
echo "📊 Status kontejnera:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=webapp-"
echo ""
echo "📊 Za praćenje logova:"
echo "   docker logs -f webapp-backend"
echo "   docker logs -f webapp-frontend"
echo ""
echo "🛑 Za zaustavljanje:"
echo "   ./stop.sh"