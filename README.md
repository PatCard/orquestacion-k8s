# orquestacion-k8s

Repositorio de aprendizaje de Kubernetes desde cero, usando minikube en Linux.

## Herramientas utilizadas

- `kubectl` v1.36.1
- `minikube` v1.38.1
- `docker compose` v2.39.2 (driver de minikube)

## Fases

- [x] **Fase 1** - Fundamentos e instalación
- [ ] **Fase 2** - Conceptos core (Pod, Deployment, Service, ConfigMap)
- [ ] **Fase 3** - Práctica real
- [ ] **Fase 4** - Certificación (CKAD)

## Fase 1 - Lo aprendido

- Instalación de kubectl y minikube
- Arquitectura interna del cluster (control-plane, etcd, scheduler, etc.)
- Crear, inspeccionar y eliminar pods
- Comandos básicos de kubectl vs docker

## Comandos clave

```bash
minikube start --driver=docker   # Iniciar cluster
minikube stop                    # Detener cluster
kubectl get pods                 # Listar pods
kubectl get pods --all-namespaces # Ver pods internos
kubectl describe pod <nombre>    # Inspeccionar pod
kubectl logs <nombre>            # Ver logs
kubectl exec -it <nombre> -- bash # Entrar al contenedor
kubectl port-forward pod/<nombre> 8080:80 --address=0.0.0.0
kubectl delete pod <nombre>      # Eliminar pod
```
