from fastapi import FastAPI
from kubernetes import client, config
import psycopg2
import os
import math

app = FastAPI()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASS = os.getenv("DB_PASS", "apppass")

def get_db():
    return psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS)

def get_k8s():
    try:
        config.load_incluster_config()
    except:
        config.load_kube_config()

@app.get("/")
def root():
    return {"mensaje": "API funcionando", "version": os.getenv("VERSION", "1.0")}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/db")
def db_check():
    try:
        conn = get_db()
        conn.close()
        return {"db": "conectada"}
    except Exception as e:
        return {"db": "error", "detalle": str(e)}

@app.get("/stress")
def stress(segundos: int = 5):
    resultado = 0
    for i in range(segundos * 1000000):
        resultado += math.sqrt(i)
    return {"resultado": resultado, "iteraciones": segundos * 1000000}

@app.get("/pods")
def get_pods():
    try:
        get_k8s()
        v1 = client.CoreV1Api()
        pods = v1.list_namespaced_pod(namespace="default", label_selector="app=backend")
        return {"pods": [{"name": p.metadata.name, "status": p.status.phase} for p in pods.items]}
    except Exception as e:
        return {"pods": [], "error": str(e)}

@app.get("/hpa")
def get_hpa():
    try:
        get_k8s()
        autoscaling = client.AutoscalingV2Api()
        hpa = autoscaling.read_namespaced_horizontal_pod_autoscaler(name="backend-hpa", namespace="default")
        cpu_actual = "N/A"
        if hpa.status.current_metrics:
            for m in hpa.status.current_metrics:
                if m.resource and m.resource.name == "cpu":
                    cpu_actual = f"{m.resource.current.average_utilization}%"
        return {
            "cpu_actual": cpu_actual,
            "cpu_umbral": f"{hpa.spec.metrics[0].resource.target.average_utilization}%",
            "replicas": hpa.status.current_replicas,
            "min": hpa.spec.min_replicas,
            "max": hpa.spec.max_replicas
        }
    except Exception as e:
        return {"error": str(e)}
