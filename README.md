# orquestacion-k8s

Repositorio de aprendizaje de Kubernetes desde cero, usando minikube en Linux.

## Herramientas utilizadas

- `kubectl` v1.36.1
- `minikube` v1.38.1
- `docker compose` v2.39.2 (driver de minikube)

## Estructura

```
orquestacion-k8s/
├── app/
│   ├── backend/          # FastAPI + Python
│   │   ├── main.py
│   │   └── Dockerfile
│   └── frontend/         # Nginx + HTML
│       ├── index.html
│       ├── nginx.conf
│       └── Dockerfile
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
- [x] **Fase 3** - Práctica real con HPA
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

### 04 - ConfigMap y Secret

**ConfigMap** — configuración general:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_HOST: "postgres-service"
  DB_NAME: "appdb"
  VERSION: "1.0"
```

**Secret** — datos sensibles (contraseñas, tokens):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:
  DB_USER: "appuser"
  DB_PASS: "apppass"
```

| | ConfigMap | Secret |
|---|---|---|
| Tipo de dato | Configuración general | Datos sensibles |
| Almacenamiento | Texto plano | Base64 encriptado |

### 05 - Namespace

Agrupa y aísla recursos dentro del mismo cluster.

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

---

## Fase 3 - Práctica real con HPA

### Arquitectura de la app demo

```
Navegador → frontend (nginx:80) → backend (fastapi:8000) → postgresql:5432
```

### Stack desplegado

| Componente | Imagen | Tipo |
|---|---|---|
| frontend | k8s-demo-frontend:2.0 | NodePort 30090 |
| backend | k8s-demo-backend:2.0 | ClusterIP 8000 |
| postgres | postgres:15 | ClusterIP 5432 |

### PersistentVolumeClaim

Almacenamiento que sobrevive si el pod muere:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### HPA - Horizontal Pod Autoscaler

Escala automáticamente según uso de CPU:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 20
```

**Comportamiento observado:**
```
Sin carga  → 1 pod  (mínimo)
Con stress → escala hasta 5 pods automáticamente
Sin carga  → baja de vuelta a 1 pod (tras ~5 min de enfriamiento)
```

### RBAC - Permisos para el backend

El backend necesita permisos para leer pods y HPA del cluster:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-role
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["get", "list"]
```

### Endpoints del backend

| Endpoint | Descripción |
|---|---|
| `GET /` | Estado de la API |
| `GET /health` | Health check |
| `GET /db` | Verificar conexión a PostgreSQL |
| `GET /stress?segundos=15` | Generar carga de CPU |
| `GET /pods` | Listar pods del backend |
| `GET /hpa` | Estado del HPA |

### Construir y desplegar

```bash
# Apuntar Docker al registry de minikube
eval $(minikube docker-env)

# Construir imágenes
docker build -t k8s-demo-backend:2.0 app/backend/
docker build -t k8s-demo-frontend:2.0 app/frontend/

# Aplicar manifiestos
kubectl apply -f manifests/02-deployments/
kubectl apply -f manifests/03-services/
kubectl apply -f manifests/04-configmaps/

# Exponer servicios
kubectl port-forward service/frontend-service 9090:80 --address=0.0.0.0 &
kubectl port-forward service/backend-service 8000:8000 --address=0.0.0.0 &
```

### Habilitar metrics-server (requerido para HPA)

```bash
minikube addons enable metrics-server

# Fix para certificados autofirmados
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

---

## Inicio rápido (cada sesión)

```bash
minikube start --driver=docker
eval $(minikube docker-env)
kubectl port-forward service/frontend-service 9090:80 --address=0.0.0.0 &
kubectl port-forward service/backend-service 8000:8000 --address=0.0.0.0 &
```

Abrir: `http://192.168.1.10:9090`

## Detener todo

```bash
kill %1 %2
minikube stop
```

---

## Comandos clave

```bash
# Cluster
minikube start --driver=docker                              # Iniciar cluster
minikube stop                                               # Detener cluster
minikube ip                                                 # IP del nodo
minikube addons enable metrics-server                       # Habilitar metrics

# Pods
kubectl get pods                                            # Listar pods
kubectl get pods -w                                         # Watch en tiempo real
kubectl get pods --all-namespaces                           # Ver todos los namespaces
kubectl describe pod <nombre>                               # Inspeccionar pod
kubectl logs <nombre>                                       # Ver logs
kubectl exec -it <nombre> -- bash                           # Entrar al contenedor
kubectl delete pod <nombre>                                 # Eliminar pod
kubectl top pods                                            # Ver uso de CPU/memoria

# Deployments
kubectl get deployments                                     # Listar deployments
kubectl scale deployment <nombre> --replicas=5              # Escalar manualmente
kubectl set image deployment/<nombre> <container>=<imagen>  # Actualizar imagen

# HPA
kubectl get hpa                                             # Ver estado del HPA
kubectl describe hpa <nombre>                               # Detalle del HPA

# Services
kubectl get services                                        # Listar services
kubectl port-forward service/<nombre> 8080:80 --address=0.0.0.0

# Manifiestos
kubectl apply -f <archivo.yaml>                             # Aplicar manifiesto
kubectl apply -f <directorio/>                              # Aplicar directorio
kubectl delete -f <archivo.yaml>                            # Eliminar por manifiesto
```