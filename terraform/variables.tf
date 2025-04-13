variable "aws_region" {
  description = "AWS region for S3 buckets"
  type        = string
  default     = "us-east-1"
}

variable "input_bucket_name" {
  description = "Name of the S3 bucket for input data"
  type        = string
  default     = "hydrosat-input-data"
}

variable "output_bucket_name" {
  description = "Name of the S3 bucket for output data"
  type        = string
  default     = "hydrosat-output-data"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for Dagster deployment"
  type        = string
  default     = "hydrosat"
}