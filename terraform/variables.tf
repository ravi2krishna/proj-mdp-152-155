variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for KOPS state"
  type        = string
  default     = "petra-kops-state-bucket-12345" # Must be globally unique!
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Name of Kubernetes cluster"
  type        = string
  default     = "petra-cluster.k8s.local"
}
