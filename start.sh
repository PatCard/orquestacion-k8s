#!/bin/bash

echo "🚀 Iniciando entorno K8s..."

# Iniciar cluster
minikube start --driver=docker

# Esperar que el cluster esté listo
echo "⏳ Esperando que el cluster esté listo..."
kubectl wait --for=condition=Ready node/minikube --timeout=60s

# Apuntar Docker al registry de minikube y reconstruir imágenes
echo "🔨 Reconstruyendo imágenes..."
eval $(minikube docker-env)
docker build -t k8s-demo-backend:2.0 app/backend/ -q
docker build -t k8s-demo-frontend:2.0 app/frontend/ -q

# Reiniciar deployments para usar las nuevas imágenes
echo "🔄 Reiniciando deployments..."
kubectl rollout restart deployment/frontend-deployment
kubectl rollout restart deployment/backend-deployment

# Esperar que los pods estén Running
echo "⏳ Esperando que los pods estén listos..."
kubectl wait --for=condition=Ready pod -l app=frontend --timeout=120s
kubectl wait --for=condition=Ready pod -l app=backend --timeout=120s

# Matar port-forwards anteriores si existen
kill $(lsof -ti:9090) 2>/dev/null
kill $(lsof -ti:8000) 2>/dev/null

# Esperar un momento antes de reconectar
sleep 3

# Exponer servicios en segundo plano
echo "🔗 Exponiendo servicios..."
kubectl port-forward service/frontend-service 9090:80 --address=0.0.0.0 &
kubectl port-forward service/backend-service 8000:8000 --address=0.0.0.0 &

sleep 3

# Mostrar estado
echo ""
echo "✅ Entorno listo!"
echo ""
kubectl get pods
echo ""
kubectl get hpa
echo ""
echo "🌐 Frontend: http://192.168.1.10:9090"
echo "🔧 Backend:  http://192.168.1.10:8000"
echo ""
echo "Para detener todo ejecuta: ./stop.sh"