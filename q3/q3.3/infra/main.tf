# This code replaces Q2. 
# If you dont want to copy-paste it in the q2 folder, make sure to delete the infrastructure from Q2 and Q3.1 before running Q3.3
# The bucket from Q2 will have to be deleted manually
# Make sure that 3.1 points the right "q2" remote state before re-running it. (see q3.1/main.tf)
# 
data "aws_iam_policy_document" "kms" {

  # Allow Root permissions, for encryption and replication
  statement {
    sid = "EnableRootPermissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow S3 to use the key for KMS bucket encryption
  statement {
    sid = "AllowS3UseOfKey"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = ["*"]
  }

  # Allows AWS Logs Delivery
  statement {
    sid = "AllowLogsDeliveryToUseKey"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allows the replicaction role to use the kms key
  statement {
    sid = "AllowReplicationRoleUseOfKey"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_replication_role.arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

# KMS key to use for both the S3 bucket and the encryption bucket
resource "aws_kms_key" "polystudent_kms" {
  description             = "KMS key for polystudent S3 bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "polystudent" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.polystudent_kms.key_id
}

resource "aws_s3_bucket" "polystudent_s3" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# This for VPC Flow Logs to avoid ACL issues
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.polystudent_s3.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Ensures no public access is allowed to the bucket
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

# Enables bucket versioning for accidental overwrites or deletes
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.polystudent_s3.id

  depends_on = [
    aws_s3_bucket_server_side_encryption_configuration.this
  ]

  versioning_configuration {
    status = "Enabled"
  }
}