provider "aws" {
  region = "ca-central-1"
}

data "terraform_remote_state" "q1" {
  backend = "local"
  config = {
    path = "../../q1/terraform.tfstate"
  }
}

data "terraform_remote_state" "q2" {
  backend = "local"
  config = {
    path = "../../q2/terraform.tfstate"
  }
}

# IAM role
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.project}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM policy to grant access to S3 bucket
resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "${var.project}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          data.terraform_remote_state.q2.outputs.polystudens3_arn,
          "${data.terraform_remote_state.q2.outputs.polystudens3_arn}/*"
        ]
      }
    ]
  })
}

# VPC Flow Logs (rejected packets => S3)
resource "aws_flow_log" "vpc_rejected" {
  log_destination_type = "s3"
  log_destination      = data.terraform_remote_state.q2.outputs.polystudens3_arn

  traffic_type = "REJECT"

  vpc_id       = data.terraform_remote_state.q1.outputs.vpc_id
  iam_role_arn = aws_iam_role.vpc_flow_logs_role.arn

  tags = {
    Name = "${var.project}-vpc-flow-logs"
  }
}
