# 🚀 FastAPI Hello World – Logz.io CSE Assignment

**Candidate:** Sudhir Chepeni  
**Goal:** Build, containerize, and deploy a simple web app to Kubernetes, integrate observability with **Logz.io**, and demonstrate alerting and dashboard capabilities.

---

## 🧱 Overview

| Component | Description |
|------------|--------------|
| **App** | FastAPI service (`/` → Hello World, `/?name=SC` → Hello "SC") |
| **Containerization** | Dockerized Python app pushed to Docker Hub |
| **Deployment** | Minikube-based Kubernetes cluster (Deployment + Service) |
| **Telemetry** | Logs shipped to Logz.io using Helm-installed **Telemetry Collector (OpenTelemetry)** |
| **Validation** | Logs confirmed in Logz.io; query: `message:"SC"` |

---

## ⚙️ Alert & API Update

**Alert:**  
- Name: `FastAPI Log Alert - SC`  
- Query: `message:"SC"`  
- Condition: count > 5 in 5 minutes → email notification  

**API Update:**  
- Updated threshold to **>50** using Logz.io REST API (PowerShell script with `PUT /v1/alerts/{id}`).

---

## 📊 Dashboard Panels

| Panel | Description |
|--------|--------------|
| **A: Log Count Over Time** | Line graph of app log frequency |
| **B: Pod Status (All Namespaces)** | Table of pod phases/readiness from cluster logs |

---

## 🧩 Troubleshooting & Key Fixes

| Issue | Resolution |
|--------|-------------|
| No logs in Logz.io | Fixed incorrect listener endpoint |
| Helm install errors | Added namespace and proper values file |
| 401 on API call | Corrected header to use `X-API-TOKEN` |

---

## ⚖️ Design Choices

- **FastAPI** → lightweight, async, ideal for demo.  
- **Minikube** → reproducible local K8s.  
- **Helm** → simplest for installing telemetry collector.  
- **Cost-awareness:** would add log filters to drop INFO logs only from this service.

---

## 📁 Deliverables

✅ Dockerfile    
✅ Alert creation + API update script  
✅ Dashboard screenshots (`/docs/`)  
✅ Detailed README with troubleshooting + rationale  

---

**Next Steps:**  
Automate via GitHub Actions, add Prometheus metrics, and complete bonus “Noise Down” exercise.

---

**Repo:** [GitHub Link Placeholder]  
**Docs Folder:** `/docs` → logs, alert, and dashboard screenshots  

---

# fastapi-hello-world

A simple FastAPI-based “Hello World” service deployed on Kubernetes with full telemetry (logs, metrics) sent to **Logz.io** via the **Telemetry Collector (OpenTelemetry)**.  
This project demonstrates containerization, observability setup, alerting, and dashboarding in a reproducible way.

---

## 🧱 1. Application Overview

**Framework:** FastAPI (Python 3.10+)  
**Behavior:**
- `GET /` → returns `Hello World`
- `GET /?name=<your_name>` → returns `Hello "<your_name>"`
- Logs every request (method, path, status code, name if provided)
- Optional `/healthz` endpoint for readiness checks

---

## 🐳 2. Containerization

**Dockerfile:**
```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Build & Push:**
```bash
docker build -t <your_dockerhub_user>/fastapi-hello-world:latest .
docker push <your_dockerhub_user>/fastapi-hello-world:latest
```

---

## ☸️ 3. Kubernetes Deployment

**Deployment (deployment.yaml):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi-hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fastapi-hello-world
  template:
    metadata:
      labels:
        app: fastapi-hello-world
    spec:
      containers:
      - name: fastapi-hello-world
        image: <your_dockerhub_user>/fastapi-hello-world:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: fastapi-service
spec:
  selector:
    app: fastapi-hello-world
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: NodePort
```

**Apply:**
```bash
kubectl apply -f deployment.yaml
kubectl get pods
minikube service fastapi-service
```

---

## 📈 4. Logz.io Telemetry Collector

Installed via Helm:

```bash
helm repo add logzio-telemetry https://logzio.github.io/public-helm-charts
helm repo update
helm install logzio-telemetry logzio-telemetry/logzio-telemetry   --set logzioShippingToken=<your_token>   --set logsListener=https://listener.logz.io:8071   --set clusterName=local-minikube   --set otelCollector.enabled=true
```

**Validation:**
- Confirm telemetry pods are running:
  ```bash
  kubectl get pods -n logzio-telemetry
  ```
- Access your Logz.io dashboard → Logs → verify logs from your service.

---

## 🧪 5. Generate Logs

Run:
```bash
curl "http://<minikube_ip>:<nodeport>/?name=SC"
```

Repeat multiple times to trigger your alert condition (>5 logs with `"SC"` in 5 minutes).

---

## 🚨 6. Alert Configuration

**Alert Name:** `FastAPI Log Alert - SC`  
**Query:** `message:"SC"`  
**Condition:** count > 5 in the last 5 minutes  
**Notification:** email to `my.email@example.com`  

### 🔄 Update via Logz.io API

PowerShell script:
```powershell
$token = "<TOKEN>"
$alertId = "<ALERTID>"
$baseUrl = "https://api.logz.io/v1"

$headers = @{
  "X-API-TOKEN" = $token
  "Content-Type" = "application/json"
}

$alert = Invoke-RestMethod -Uri "$baseUrl/alerts/$alertId" -Method Get -Headers $headers
$alert.threshold = 50.0
if ($alert.severityThresholdTiers -and $alert.severityThresholdTiers.Count -gt 0) {
    $alert.severityThresholdTiers[0].threshold = 50.0
}
$body = $alert | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "$baseUrl/alerts/$alertId" -Method Put -Headers $headers -Body $body
Write-Host "✅ Alert updated successfully!"
```

---

## 📊 7. Dashboard Panels

### **Panel A: Log Count Over Time**
- Visualization: Line chart
- Query: `kubernetes.container_name:fastapi-hello-world`
- Metric: Count of logs over time

### **Panel B: Pod Status**
- Source: Kubernetes logs
- Query: `kubernetes.namespace_name:*`
- Visualization: Table showing pod name, namespace, phase, and readiness

---

## 🧩 8. Troubleshooting Journey

| Issue | Root Cause | Fix |
|-------|-------------|-----|
| No logs in Logz.io | Mismatch in listener endpoint | Corrected region-specific endpoint to `listener.logz.io:8071` |
| Helm install failed | Namespace missing | Added `--create-namespace` |
| Logz.io API 401 | Token not in header | Fixed header to use `X-API-TOKEN` |

---

## ⚖️ 9. Key Choices & Trade-offs

- **Minikube vs. GKE:** Used Minikube for simplicity and reproducibility.  
- **FastAPI:** Lightweight, async-ready, and integrates easily with OpenTelemetry.  
- **Helm:** Simplifies collector deployment and teardown.  
- **Logging strategy:** Chose JSON logs for better parsing in Logz.io.  
- **Cost awareness:** Would use filters and log-level drop rules (INFO only) to reduce ingestion cost in production.

---

## 🚀 10. Next Improvements

- Add Prometheus/Grafana integration for richer pod metrics.  
- Automate traffic generation with a small Python loop or k6.  
- Deploy with Ingress and TLS for a more realistic setup.  
- Add CI/CD pipeline (GitHub Actions) for image build and Helm release.  
- Implement the bonus “Noise Down” exercise (drop INFO logs only for this app).

---

## 📁 11. Repository Structure

```
/fastapi-hello-world
├── main.py
├── requirements.txt
├── Dockerfile
├── deployment.yaml
├── alert-update.ps1
├── /docs
│   ├── logs-validation.png
│   ├── alert-definition.png
│   ├── alert-triggered.png
│   ├── dashboard.png
│  
└── README.md
```

---

## 📚 12. References

- [Logz.io Docs](https://docs.logz.io/)
- [OpenTelemetry Collector Helm Chart](https://github.com/logzio/public-helm-charts](https://docs.logz.io/docs/k8s-360/unified-helm-chart/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

✅ **All required deliverables covered:**
- App code + Dockerfile  
- K8s manifests  
- Helm values (collector)  
- Logz.io alert (threshold >5) + API update (>50)  
- Dashboard panels (logs + pod status)  
- Screenshots (in `/docs`)  
- Full README with troubleshooting, decisions, and next steps  
