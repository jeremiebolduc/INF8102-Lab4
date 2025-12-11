provider "aws" {
  region = "ca-central-1"
}

data "terraform_remote_state" "q1" {
  backend = "local"
  config = {
    path = "../../../q1/infra/terraform.tfstate"
  }
}

# Allows EC2 instances to assume a role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# LabRole IAM role
resource "aws_iam_role" "labrole" {
  name               = "LabRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Allows LabRole to push data to CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.labrole.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# LabRole instance profile
resource "aws_iam_instance_profile" "lab_instance_profile" {
  name = "${var.project}-labrole-instance-profile"
  role = aws_iam_role.labrole.name
}

# AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # publisher ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] # ubuntu 22.04 jammy
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Public instance AZ1
resource "aws_instance" "public_az1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.terraform_remote_state.q1.outputs.public_subnets[0]
  vpc_security_group_ids      = [data.terraform_remote_state.q1.outputs.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.lab_instance_profile.name

  tags = {
    Name = "${var.project}-public-az1"
  }
}

# Public instance AZ2
resource "aws_instance" "public_az2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.terraform_remote_state.q1.outputs.public_subnets[1]
  vpc_security_group_ids      = [data.terraform_remote_state.q1.outputs.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.lab_instance_profile.name

  tags = {
    Name = "${var.project}-public-az2"
  }
}

# Private instance AZ1
resource "aws_instance" "private_az1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.q1.outputs.private_subnets[0]
  vpc_security_group_ids = [data.terraform_remote_state.q1.outputs.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.lab_instance_profile.name

  tags = {
    Name = "${var.project}-private-az1"
  }
}

# Private instance AZ2
resource "aws_instance" "private_az2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.q1.outputs.private_subnets[1]
  vpc_security_group_ids = [data.terraform_remote_state.q1.outputs.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.lab_instance_profile.name

  tags = {
    Name = "${var.project}-private-az2"
  }
}

# Cloudwatch alarm for NetworkPacketsIn >= 1000
locals {
  instances = {
    public_az1  = aws_instance.public_az1.id
    public_az2  = aws_instance.public_az2.id
    private_az1 = aws_instance.private_az1.id
    private_az2 = aws_instance.private_az2.id
  }
}

resource "aws_cloudwatch_metric_alarm" "network_packets_in" {
  for_each = local.instances

  alarm_name          = "${var.project}-${each.key}-pkt-in"
  alarm_description   = "Triggers if NetworkPacketsIn >= 1000 pkts/sec"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkPacketsIn"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 1000
  alarm_actions       = []
  ok_actions          = []
  dimensions = {
    InstanceId = each.value
  }
}
