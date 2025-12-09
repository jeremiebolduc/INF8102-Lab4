output "s3_bucket_name" {
  value       = aws_s3_bucket.polystudent_s3.bucket
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.polystudent_s3.arn
}

output "kms_key_arn" {
  value       = aws_kms_key.polystudent_kms.arn
}
