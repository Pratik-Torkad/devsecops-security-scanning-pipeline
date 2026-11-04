output "artifact_bucket_name" {
  description = "S3 bucket name declared by this example."
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifact_bucket_arn" {
  description = "S3 bucket ARN declared by this example."
  value       = aws_s3_bucket.artifacts.arn
}
