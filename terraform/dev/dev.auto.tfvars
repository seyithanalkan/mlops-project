aws_region  = "eu-west-1"
environment = "dev"

vpc_cidr           = "10.0.0.0/16"

subnet_bits        = 8


train_repo_name = "mlops-train"
serve_repo_name = "mlops-serve"


cluster_name = "mlops-cluster"

raw_bucket_name       = "mlops-dev-raw-data-seyithan"
processed_bucket_name = "mlops-dev-processed-data-seyithan"
model_bucket_name     = "mlops-dev-model-artifacts-seyithan"


serve_service_name   = "serve-mlops-service"
serve_container_port = 8000
serve_cpu            = 256
serve_memory         = 512

train_task_name = "train-mlops-task"
train_cpu       = 256
train_memory    = 512

alb_listener_port   = 443
alb_target_port     = 8000
alb_certificate_arn = "arn:aws:acm:eu-west-1:544167776152:certificate/ed924481-247e-445a-bb45-65bf6449d33a"