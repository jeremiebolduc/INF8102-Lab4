provider "aws" {
  region = "ca-central-1"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  statement {
    sid = "EnableRootPermissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "AllowS3UseOfKey"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "polystudent_kms" {
  description             = "KMS key for polystudent S3 bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "polystudent" {
  name          = "alias/polystudent-kms"
  target_key_id = aws_kms_key.polystudent_kms.key_id
}

resource "aws_s3_bucket" "polystudent_s3" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.polystudent_s3.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.polystudent_s3.id

  depends_on = [
    aws_kms_key.polystudent_kms,
    aws_s3_bucket_public_access_block.this
  ]

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.polystudent_kms.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.polystudent_s3.id

  depends_on = [
    aws_s3_bucket_server_side_encryption_configuration.this
  ]

  versioning_configuration {
    status = "Enabled"
  }
}
