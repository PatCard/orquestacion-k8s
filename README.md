# orquestacion-k8s

Repositorio de aprendizaje de Kubernetes desde cero, usando minikube en Linux.

## Herramientas utilizadas

- `kubectl` v1.36.1
- `minikube` v1.38.1
- `docker compose` v2.39.2 (driver de minikube)

## Estructura

```
orquestacion-k8s/
└── manifests/
    ├── 01-pods/
    ├── 02-deployments/
    ├── 03-services/
    ├── 04-configmaps/
    └── 05-namespaces/
```

## Fases de aprendizaje

- [x] **Fase 1** - Instalación y fundamentos
- [ ] **Fase 2** - Conceptos core (Pod, Deployment, Service, ConfigMap)
- [ ] **Fase 3** - Práctica real
- [ ] **Fase 4** - Certificación (CKAD)

## Comandos clave

```bash
minikube start --driver=docker                              # Iniciar cluster
minikube stop                                               # Detener cluster
kubectl get pods                                            # Listar pods
kubectl get pods --all-namespaces                           # Ver pods internos
kubectl describe pod <nombre>                               # Inspeccionar pod
kubectl logs <nombre>                                       # Ver logs
kubectl exec -it <nombre> -- bash                           # Entrar al contenedor
kubectl port-forward pod/<nombre> 8080:80 --address=0.0.0.0 # Exponer pod
kubectl delete pod <nombre>                                 # Eliminar pod
kubectl apply -f <archivo.yaml>                             # Aplicar manifiesto
kubectl delete -f <archivo.yaml>                            # Eliminar por manifiesto
```