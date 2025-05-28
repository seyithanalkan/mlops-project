module "s3" {
  source      = "../modules/s3-bucket"
  bucket_name = var.raw_bucket_name
  environment = var.environment
  versioning  = true
}

module "processed_s3" {
  source      = "../modules/s3-bucket"
  bucket_name = var.processed_bucket_name
  environment = var.environment
  versioning  = true
}

module "model_s3" {
  source      = "../modules/s3-bucket"
  bucket_name = var.model_bucket_name
  environment = var.environment
  versioning  = true
}
