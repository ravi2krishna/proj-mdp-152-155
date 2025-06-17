output "workstation_public_ip" {
  description = "Public IP of the Kubernetes workstation"
  value       = aws_instance.k8ws_workstation.public_ip
}

output "ansible_master_public_ip" {
  description = "Public IP of the Ansible master"
  value       = aws_instance.ansible_master.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Kubernetes state"
  value       = aws_s3_bucket.k8ws_bucket.id
}