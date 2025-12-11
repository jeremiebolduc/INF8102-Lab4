provider "aws" {
  region = "ca-central-1"
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.cloudtrail_bucket_name
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl","s3:GetBucketLocation"]
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

resource "aws_cloudtrail" "s3_log_activities" {
  name           = "s3-log-activities"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id
  
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
  
  event_selector {
    read_write_type = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${data.terraform_remote_state.q2.outputs.s3_bucket_arn}/"]
    }
  }
}
