# MLOps Retail Forecast Pipeline

A fully automated end-to-end pipeline for retail sales forecasting, from data generation all the way to model serving on AWS ECS.

---

## 1. Project Summary

This project implements a complete MLOps workflow:

- **Data Generation**  
  Synthetic daily sales data (100–500 units) generated via Python.  
- **Feature Engineering**  
  Basic lag and rolling‐window features computed in a reusable module.  
- **Model Training**  
  LSTM model trained on ECS tasks, triggered by S3 uploads via EventBridge.  
- **Model Serving**  
  FastAPI server containerized and deployed on Fargate, with automatic CI/CD.  
- **Infrastructure as Code**  
  Terraform modules for VPC, ECS, ECR, S3, EventBridge, IAM, etc.  
- **CI/CD with GitHub Actions**  
  Tests, static analysis, container scanning, infra deploy, app build/deploy, data generation.

---

## 2. Directory Layout

```
mlops-retail-forecast/
├── .github/
│   └── workflows/mlops.yml           # CI/CD pipeline definition
├── Dockerfile                        # Multi-stage Dockerfile
├── scripts/
│   ├── generate_data.py              # Dummy data generator
│   └── generate_training_trigger.py  # Creates EventBridge payload
├── src/
│   ├── data/ingest.py                # Config & S3 download utilities
│   ├── features/engineer.py          # Feature engineering logic
│   ├── models/train.py               # Training script (with scalers)
│   └── serve/app.py                  # FastAPI serve application
├── tests/                            # Pytest unit tests
├── data/raw/                         # Generated CSV files
├── terraform/
│   ├── dev/                          # Dev env Terraform configs
│   └── modules/                      # Reusable Terraform modules
│       ├── alb/        ├── ecs-cluster/
│       ├── ecr/        ├── ecs-service-fargate/
│       ├── ecs-task-fargate/  ├── events/
│       ├── iam/       ├── networking/
│       ├── s3-bucket/ └── security-group/
└── requirements.txt                  # Python dependencies
```

---

## 3. Infrastructure as Code

**Terraform modules** define all cloud resources:

- **VPC & Networking**: subnets, route tables, IGW, NAT Gateway  
- **ECR**: private repositories for train & serve images  
- **ECS**: Fargate cluster, services & task definitions  
- **S3**: buckets for raw data, processed features & models  
- **EventBridge**: rule to trigger training on S3 object creation  
- **IAM**: roles & policies for ECS tasks and CI/CD role assumption  

```hcl
resource "aws_s3_bucket_notification" "data_trigger" {
  bucket = aws_s3_bucket.data_bucket.id
  eventbridge { enabled = true }
}
```

<!-- Screenshot: Terraform plan/apply output -->

---

## 4. CI/CD Pipeline

Defined in **`.github/workflows/mlops.yml`**, the pipeline runs on every push to `main`:

```yaml
name: 🚀 MLOps • App & Train

on:
  push:
    branches: [main]

jobs:
  check-changes: …    # Detects which layer changed (app/train/infra)
  terraform: …        # Plan & apply Terraform if infra changed
  app-deploy: …       # Build & deploy serve image if serve code changed
  train-deploy: …     # Build/train image & register new task def
  generate-data: …    # Always generate & upload dummy CSV
```

### Job Breakdown

1. **check-changes**  
   Uses `git diff` to set outputs: `app_changed`, `train_changed`, `terraform_changed`.  
   <!-- Screenshot: “Determine What Changed” step -->

2. **terraform**  
   ```bash
   terraform init && terraform plan -out=tfplan && terraform apply -auto-approve tfplan
   ```
   Exports outputs (ECR URLs, ECS names, bucket names) for downstream jobs.  
   <!-- Screenshot: Terraform Outputs action -->

3. **app-deploy**  
   - Runs `pytest` 
   - Builds & scans serve image (`trivy-action`)  
   - Pushes to ECR & updates ECS service  
   <!-- Screenshot: Serve image build & push -->

4. **train-deploy**  
   - Runs `pytest`  
   - Builds & pushes train image  
   - Describes existing task def, swaps in new image, registers new revision  
   <!-- Screenshot: Train task registration -->

5. **generate-data**  
   - Always runs: `generate_data.py` → `data/raw/sales.csv`  
   - Uploads to S3 → triggers EventBridge → fires ECS train task  
   <!-- Screenshot: Upload to S3 step -->

---

## 5. Docker Multi-Stage Build

```dockerfile
FROM python:3.10-slim AS base
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS train
COPY scripts/ src/models/ src/data/ src/features/ ./
CMD ["bash", "run_pipeline.sh"]

FROM base AS serve
COPY src/serve/ ./src/serve/
EXPOSE 8000
ENV PYTHONPATH=/app
CMD ["uvicorn", "src.serve.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

- **base**: installs dependencies  
- **train**: includes data generator, feature engineer, training code  
- **serve**: FastAPI application  

<!-- Screenshot: Docker build output -->

---

## 6. Data Generation & Feature Engineering

- **generate_data.py** creates 180 days of dummy sales in `data/raw/sales.csv`.  
- **engineer.py** reads CSV, computes:
  - `lag_1`: previous day’s sales  
  - `rolling_mean_7`: 7-day moving average  

```bash
python scripts/generate_data.py
```

<!-- Screenshot: sample rows from sales.csv -->

---

## 7. Model Training Pipeline

The ECS train task runs `run_pipeline.sh`, which:

1. Downloads raw CSV from S3  
2. Executes training code (`src/models/train.py`):
   - loads config  
   - scales features & target with `MinMaxScaler`  
   - trains `LSTM(32) + Dense(1)`  
   - saves model + scalers to S3  
3. Optionally forces ECS serve service to reload new model  

```bash
bash run_pipeline.sh
```

<!-- Screenshot: CloudWatch Logs for training steps -->

---

## 8. Model Serving

`src/serve/app.py`:

- Loads model & scalers (or falls back to dummy/identity in tests)  
- Provides endpoints:
  - `GET /health`  
  - `GET /metrics`  
  - `GET /model` → metadata  
  - `POST /predict` → returns `prediction`, `request_id`, `processing_time`  

```bash
curl https://<serve-url>/model
curl -X POST /predict -d '{"lag_1": 300, "rolling_mean_7": 300}'
```

<!-- Screenshot: OpenAPI docs (/docs) -->

---

## 9. Testing & Validation

- **Unit tests** in `tests/` cover:
  - input validation (negative values → 422)  
  - prediction consistency on known inputs  
  - health & model metadata endpoints  

```bash
pytest --maxfail=1 --disable-warnings -q
```

<!-- Screenshot: pytest summary -->

---

## 10. EventBridge Trigger

- Terraform sets up S3 bucket notifications with `eventbridge { enabled = true }`.  
- Uploading `sales.csv` to `s3://raw-bucket/data/raw/sales.csv` fires the rule → ECS train task.  

```hcl
resource "aws_s3_bucket_notification" "data_trigger" {
  bucket = aws_s3_bucket.data_bucket.id
  eventbridge { enabled = true }
}
```

<!-- Screenshot: EventBridge rule in AWS Console -->

---

## 11. Observability & Logging

- **CloudWatch Logs** for train & serve containers  
- **X-Process-Time** and **X-Request-ID** headers for latency tracing  
- **GitHub Actions** insights: test coverage, static analysis, container scan results  

<!-- Screenshot: CloudWatch dashboard & GitHub Actions insights -->


---

## 12. Benefits & Takeaways

- **Full automation** from data → model → serving  
- **Reproducibility** via Terraform & containerization  
- **Scalability** with ECS Fargate  
- **Robustness**: input validation, fallback mechanisms, CI/CD gates  


