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
- [x] **Fase 2** - Conceptos core (Pod, Deployment, Service, ConfigMap, Namespace)
- [ ] **Fase 3** - Práctica real
- [ ] **Fase 4** - Certificación (CKAD)

---

## Fase 1 - Instalación y fundamentos

### Instalación

```bash
# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Instalar minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Iniciar cluster
minikube start --driver=docker
```

### Arquitectura interna del cluster

| Componente | Rol |
|---|---|
| `kube-apiserver` | Recibe todos los comandos kubectl |
| `etcd` | Base de datos del cluster |
| `kube-scheduler` | Decide en qué nodo corre cada pod |
| `kube-controller-manager` | Vigila que todo esté como se definió |
| `kube-proxy` | Maneja el networking entre pods |
| `coredns` | DNS interno del cluster |
| `storage-provisioner` | Gestiona volúmenes de almacenamiento |

### Docker vs Kubernetes

| Docker | Kubernetes |
|---|---|
| `docker run` | Pod |
| `docker-compose.yml` | Deployment + Service (YAML) |
| `docker compose up` | `kubectl apply -f` |
| Puerto expuesto | Service |
| Volumen | PersistentVolume |
| Red interna | Namespace |

---

## Fase 2 - Conceptos core

### 01 - Pod

La unidad mínima de Kubernetes. Contiene uno o más contenedores.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-primer-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
```

> **Limitación:** un Pod solo no se recupera si muere. Para eso existe el Deployment.

### 02 - Deployment

Gestiona pods automáticamente. Provee:
- **Self-healing**: si un pod muere, crea uno nuevo automáticamente
- **Escalado**: sube o baja réplicas con un comando
- **Estado deseado**: tú declaras cuántos pods quieres y K8s los mantiene

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: nginx-config
```

**Escalar manualmente:**
```bash
kubectl scale deployment nginx-deployment --replicas=5
```

> **Próximamente (Fase 3):** HPA (Horizontal Pod Autoscaler) para escalar automáticamente según uso de CPU/memoria.

### 03 - Service

IP fija que apunta siempre a los pods correctos, sin importar si cambian o cuántos haya.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

**Tipos de Service:**

| Tipo | Para qué |
|---|---|
| `ClusterIP` | Solo accesible dentro del cluster |
| `NodePort` | Accesible desde fuera, por un puerto fijo |
| `LoadBalancer` | Para nubes (AWS, Azure, GCP) |

### 04 - ConfigMap

Almacena configuración separada de la imagen. Reutilizable en múltiples pods.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  AMBIENTE: "desarrollo"
  VERSION: "1.0"
  MENSAJE: "Hola desde ConfigMap"
```

> Las variables se inyectan en el pod con `envFrom.configMapRef`.

### 05 - Namespace

Agrupa y aísla recursos dentro del mismo cluster. Permite separar entornos sin necesitar clusters distintos.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: desarrollo
---
apiVersion: v1
kind: Namespace
metadata:
  name: produccion
```

**Namespaces internos de K8s:**

| Namespace | Para qué |
|---|---|
| `default` | Donde corren los recursos por defecto |
| `kube-system` | Componentes internos de K8s |
| `kube-public` | Recursos públicos del cluster |
| `kube-node-lease` | Control de salud de los nodos |

---

## Comandos clave

```bash
# Cluster
minikube start --driver=docker                              # Iniciar cluster
minikube stop                                               # Detener cluster
minikube ip                                                 # IP del nodo

# Pods
kubectl get pods                                            # Listar pods
kubectl get pods --all-namespaces                           # Ver todos los namespaces
kubectl get pods --namespace=desarrollo                     # Ver pods de un namespace
kubectl describe pod <nombre>                               # Inspeccionar pod
kubectl logs <nombre>                                       # Ver logs
kubectl exec -it <nombre> -- bash                           # Entrar al contenedor
kubectl delete pod <nombre>                                 # Eliminar pod

# Deployments
kubectl get deployments                                     # Listar deployments
kubectl scale deployment <nombre> --replicas=5              # Escalar

# Services
kubectl get services                                        # Listar services
kubectl port-forward service/<nombre> 8080:80 --address=0.0.0.0

# ConfigMaps
kubectl get configmaps                                      # Listar configmaps
kubectl describe configmap <nombre>                         # Ver contenido

# Namespaces
kubectl get namespaces                                      # Listar namespaces

# Manifiestos
kubectl apply -f <archivo.yaml>                             # Aplicar manifiesto
kubectl delete -f <archivo.yaml>                            # Eliminar por manifiesto
```