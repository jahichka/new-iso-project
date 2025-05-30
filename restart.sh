#!/bin/bash

echo "🔄 Restartovanje Web Aplikacije..."
echo "=================================="

# Zaustavi aplikaciju
echo "🛑 Zaustavljam aplikaciju..."
./stop.sh

# Čekaj malo
sleep 3

# Pokreni ponovo
echo "🚀 Pokretam aplikaciju ponovo..."
./start.sh