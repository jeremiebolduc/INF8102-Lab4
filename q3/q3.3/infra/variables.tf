variable "s3_bucket_name" {
  type        = string
  default     = "polystudent-s3-2148028"
}

variable "replication_role_name" {
  type        = string
  default     = "bucket_replication_role"
}

variable "cloudtrail_bucket_name" {
  type        = string
  default     = "cloudtrail-bucket-2148028"
}

variable "kms_key_alias" {
  type        = string
  default     = "polystudent-kms-tp4"
}