output "dagster_webserver_endpoint" {
  description = "Endpoint for Dagster webserver (after port-forwarding)"
  value       = "http://localhost:3000"
}

output "input_bucket_name" {
  description = "Name of the S3 bucket for input data"
  value       = aws_s3_bucket.input_bucket.bucket
}

output "output_bucket_name" {
  description = "Name of the S3 bucket for output data"
  value       = aws_s3_bucket.output_bucket.bucket
}

output "kubernetes_namespace" {
  description = "Kubernetes namespace for Dagster deployment"
  value       = kubernetes_namespace.hydrosat.metadata[0].name
}

output "port_forward_command" {
  description = "Command to set up port forwarding to the Dagster webserver"
  value       = "kubectl port-forward svc/dagster-dagster-webserver -n ${kubernetes_namespace.hydrosat.metadata[0].name} 3000:80"
}