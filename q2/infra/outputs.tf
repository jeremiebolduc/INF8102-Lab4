output "s3_bucket_name" {
  value       = aws_s3_bucket.polystudent-s3.bucket
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.polystudent-s3.arn
}

output "kms_key_arn" {
  value       = data.aws_kms_key.polystudent-kms.arn
}
