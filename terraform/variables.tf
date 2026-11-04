variable "aws_region" {
  description = "AWS region for the static infrastructure example."
  type        = string
  default     = "ap-south-1"
}

variable "artifact_bucket_name" {
  description = "Globally unique name, only if you later deploy this example."
  type        = string
  default     = "replace-with-globally-unique-artifact-bucket"
}
