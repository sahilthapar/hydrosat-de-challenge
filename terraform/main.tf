# Configure the Kubernetes provider
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "aws" {
  region = var.aws_region
  # Use AWS credentials from environment variables or AWS CLI configuration
}

# Create a namespace for our applications
resource "kubernetes_namespace" "hydrosat" {
  metadata {
    name = "hydrosat"
  }
}

# Create S3 buckets for input and output data
resource "aws_s3_bucket" "input_bucket" {
  bucket = var.input_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "input_bucket_ownership" {
  bucket = aws_s3_bucket.input_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "input_bucket_access" {
  bucket                  = aws_s3_bucket.input_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "input_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.input_bucket_ownership,
    aws_s3_bucket_public_access_block.input_bucket_access,
  ]

  bucket = aws_s3_bucket.input_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "input_bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.input_bucket_access]

  bucket = aws_s3_bucket.input_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.input_bucket_name}/*"
      },
    ]
  })
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = var.output_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "output_bucket_ownership" {
  bucket = aws_s3_bucket.output_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "output_bucket_access" {
  bucket                  = aws_s3_bucket.output_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "output_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.output_bucket_ownership,
    aws_s3_bucket_public_access_block.output_bucket_access,
  ]

  bucket = aws_s3_bucket.output_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "output_bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.output_bucket_access]

  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.output_bucket_name}/*"
      },
    ]
  })
}

# Upload sample data to the input bucket
resource "aws_s3_object" "bounding_box" {
  bucket = aws_s3_bucket.input_bucket.id
  key    = "bounding_box.geojson"
  source = "../data/bounding_box.geojson"
  content_type = "application/json"
}

resource "aws_s3_object" "fields" {
  bucket = aws_s3_bucket.input_bucket.id
  key    = "fields.geojson"
  source = "../data/fields.geojson"
  content_type = "application/json"
}

# Deploy Dagster
resource "helm_release" "dagster" {
  name       = "dagster"
  repository = "https://dagster-io.github.io/helm"
  chart      = "dagster"
  namespace  = kubernetes_namespace.hydrosat.metadata[0].name

  # Customize Dagster deployment
  values = [
    file("${path.module}/../k8s/dagster-values.yaml")
  ]

  # Set AWS credentials as environment variables for Dagster
  set {
    name  = "dagster-user-deployments.deployments[0].env[0].name"
    value = "AWS_REGION"
  }

  set {
    name  = "dagster-user-deployments.deployments[0].env[0].value"
    value = var.aws_region
  }

  set {
    name  = "dagster-user-deployments.deployments[0].env[1].name"
    value = "INPUT_BUCKET"
  }

  set {
    name  = "dagster-user-deployments.deployments[0].env[1].value"
    value = var.input_bucket_name
  }

  set {
    name  = "dagster-user-deployments.deployments[0].env[2].name"
    value = "OUTPUT_BUCKET"
  }

  set {
    name  = "dagster-user-deployments.deployments[0].env[2].value"
    value = var.output_bucket_name
  }
}