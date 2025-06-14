output "master_public_ip" {
  description = "Public IP of the Kubernetes Master node"
  value       = aws_instance.k8s_master.public_ip
}

output "worker_public_ip" {
  description = "Public IP of the Kubernetes Worker node"
  value       = aws_instance.k8s_worker.public_ip
}
