# Create Bucket
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags = {
    Environment = var.environment
    Name        = var.bucket_name
  }
}

# Disable Public Access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = var.versioning ? "Enabled" : "Suspended" }
}


#Send Notification to EventBridge
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.this.id
  eventbridge = true
}