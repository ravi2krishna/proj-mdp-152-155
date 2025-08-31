output "s3_bucket_name" {
  value = aws_s3_bucket.kops_state.bucket
}

output "vpc_id" {
  value = aws_vpc.k8s_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "kops_role_arn" {
  value = aws_iam_role.kops_role.arn
}

output "node_role_arn" {
  value = aws_iam_role.node_role.arn
}
