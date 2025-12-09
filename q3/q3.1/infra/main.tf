provider "aws" {
  region = "ca-central-1"
}

data "terraform_remote_state" "q1" {
  backend = "local"
  config = {
    path = "../../../q1/infra/terraform.tfstate"
  }
}

data "terraform_remote_state" "q2" {
  backend = "local"
  config = {
    path = "../../../q2/infra/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

# IAM policy to grant access to S3 bucket
data "aws_iam_policy_document" "vpc_flow_logs" {
  statement {
    sid = "AllowVPCFlowLogsWrite"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${data.terraform_remote_state.q2.outputs.s3_bucket_arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = data.terraform_remote_state.q2.outputs.s3_bucket_name
  policy = data.aws_iam_policy_document.vpc_flow_logs.json
}

# VPC Flow Logs (rejected packets => S3)
resource "aws_flow_log" "vpc_rejected" {
  log_destination_type = "s3"
  log_destination      = data.terraform_remote_state.q2.outputs.s3_bucket_arn

  traffic_type = "REJECT"
  vpc_id       = data.terraform_remote_state.q1.outputs.vpc_id

  tags = {
    Name = "${var.project}-vpc-flow-logs"
  }
}
