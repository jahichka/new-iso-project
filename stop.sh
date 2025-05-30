#!/bin/bash

echo "🛑 Zaustavljanje Web Aplikacije..."
echo "=================================="

# Zaustavi sve kontejnere
echo "⏹️  Zaustavljam kontejnere..."
docker stop webapp-postgres webapp-backend webapp-frontend webapp-redis webapp-pgadmin 2>/dev/null || true

# Obriši kontejnere
echo "🗑️  Brišem kontejnere..."
docker rm webapp-postgres webapp-backend webapp-frontend webapp-redis webapp-pgadmin 2>/dev/null || true

echo ""
echo "✅ Aplikacija je zaustavljena!"
echo ""
echo "🔧 Opcije za čišćenje:"
echo "   docker volume rm postgres_data redis_data    # Obriši podatke"
echo "   docker network rm webapp-network             # Obriši network"
echo "   docker rmi webapp-backend webapp-frontend    # Obriši images"
echo "   docker system prune                          # Očisti sve nekorišteno"