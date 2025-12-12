resource "aws_s3_bucket" "polystudent_s3_back" {
  bucket = "${var.s3_bucket_name}-back"
}

resource "aws_s3_bucket_versioning" "polystudent_s3_back_versioning" {
  bucket = aws_s3_bucket.polystudent_s3_back.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "polystudent_s3_back_encryption" {
  bucket = aws_s3_bucket.polystudent_s3_back.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.polystudent_kms.arn
    }
  }
}

data "aws_iam_policy_document" "s3_replication" {
  # Allows the replication bucket to read the source bucket
  statement {
    sid    = "AllowReadFromSourceBucket"
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.polystudent_s3.arn
    ]
  }

  # Allows the replication bucket to read objects version.
  statement {
    sid    = "AllowReadVersionedObjects"
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      "${aws_s3_bucket.polystudent_s3.arn}/*"
    ]
  }

  # Allows object replication
  statement {
    sid    = "AllowWriteToDestinationBucket"
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = [
      "${aws_s3_bucket.polystudent_s3_back.arn}/*"
    ]
  }

  # Allows decrpytion from kms key
  statement {
    sid    = "AllowKMSDecryptFromSource"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.polystudent_kms.arn
    ]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.*.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${aws_s3_bucket.polystudent_s3.arn}/*"]
    }
  }

  # Allows encryption
  statement {
    sid    = "AllowKMSEncryptToDestination"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.polystudent_kms.arn
    ]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.*.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${aws_s3_bucket.polystudent_s3_back.arn}/*"]
    }
  }
}

resource "aws_iam_role" "s3_replication_role" {
  name = "polystudent-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_replication_policy" {
  name   = "polystudent-s3-replication-policy"
  role   = aws_iam_role.s3_replication_role.id
  policy = data.aws_iam_policy_document.s3_replication.json
}

resource "aws_s3_bucket_replication_configuration" "polystudent_s3_replication" {
  bucket = aws_s3_bucket.polystudent_s3.id
  role   = aws_iam_role.s3_replication_role.arn
  
  depends_on = [
    aws_iam_role_policy.s3_replication_policy,
    aws_s3_bucket_versioning.polystudent_s3_back_versioning
    ]

  # All objects from the source bucket will be replicated
  rule {
    id     = "replicate-all-objects"
    status = "Enabled"
    filter {}

    # Allows replication of encrpyted objects
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
        }
    }

    destination {
      bucket        = aws_s3_bucket.polystudent_s3_back.arn
      storage_class = "STANDARD"

      encryption_configuration {replica_kms_key_id = aws_kms_key.polystudent_kms.arn}
    }

    delete_marker_replication { status = "Enabled" }
  }
}