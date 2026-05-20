#!/bin/bash

echo "🛑 Deteniendo entorno K8s..."

# Detener port-forwards
echo "🔌 Cerrando port-forwards..."
kill $(lsof -ti:9090) 2>/dev/null
kill $(lsof -ti:8000) 2>/dev/null
kill $(lsof -ti:8080) 2>/dev/null

# Detener cluster
echo "⏳ Deteniendo minikube..."
minikube stop

echo ""
echo "✅ Entorno detenido correctamente."