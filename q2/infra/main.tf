provider "aws" {
  region = "ca-central-1"
}

data "aws_kms_key" "polystudent-kms" {
  key_id = var.kms_key_alias
}

resource "aws_s3_bucket" "polystudent-s3" {
  bucket = var.s3_bucket_name
  acl    = "private"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.polystudent-s3.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.polystudent-s3.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.polystudent-kms.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.polystudent-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}
