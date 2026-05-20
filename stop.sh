#!/bin/bash

echo "🛑 Deteniendo entorno K8s..."

# Detener port-forwards
echo "🔌 Cerrando puertos..."
kill $(lsof -ti:80) 2>/dev/null
kill $(lsof -ti:8000) 2>/dev/null
kill $(lsof -ti:9090) 2>/dev/null

# Detener cluster
echo "⏳ Deteniendo minikube..."
minikube stop

echo ""
echo "✅ Entorno detenido correctamente."
