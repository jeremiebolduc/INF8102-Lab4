output "s3_bucket_name" {
  value       = aws_s3_bucket.polystudent_s3.bucket
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.polystudent_s3.arn
}

output "kms_key_arn" {
  value       = aws_kms_key.polystudent_kms.arn
}

output "replication_bucket_name" {
  value       = aws_s3_bucket.polystudent_s3_back.bucket
}

output "replication_bucket_arn" {
  value       = aws_s3_bucket.polystudent_s3_back.arn
}

output "cloudtrail_bucket_name" {
  value       = aws_s3_bucket.cloudtrail_bucket.bucket
}

output "cloudtrail_bucket_arn" {
  value       = aws_s3_bucket.cloudtrail_bucket.arn
}