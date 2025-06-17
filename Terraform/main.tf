provider "aws" {
  region = "us-east-2"
}
resource "aws_vpc" "k8ws_vpc" {
  cidr_block = "10.50.0.0/16"
  tags = {
    Name = "k8ws_vpc"
  }
}
# create subnet 2A
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.k8ws_vpc.id
  cidr_block = "10.50.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "k8ws-subnet-a"
  }
}
# create subnet 2B
resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.k8ws_vpc.id
  cidr_block = "10.50.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "k8ws-subnet-b"
  }
}
# create igw
resource "aws_internet_gateway" "k8ws_igw" {
  vpc_id = aws_vpc.k8ws_vpc.id
  tags = {
    Name = "k8ws_igw"
  }
}
# create route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8ws_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8ws_igw.id
  }
  tags = {
    Name = "k8ws_public_rt"
  }
}
# associate route table with subnet 2A
resource "aws_route_table_association" "public_rt_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}
# associate route table with subnet 2B
resource "aws_route_table_association" "public_rt_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}
# create security group
resource "aws_security_group" "k8ws_sg" {
  vpc_id = aws_vpc.k8ws_vpc.id
  name   = "k8ws_sg"
  description = "Allow ssh and k8"
  ingress { # allow ssh
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { # allow k8
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "k8ws master"
  }
  ingress {# allow k8ws node port
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "k8ws pods"
  }
  ingress {# allow k8ws node port
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "k8ws pods"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "k8ws_sg"
  }
}
  # create EC2 workstation
  resource "aws_instance" "k8ws_workstation" {
    ami           = "ami-0fe972392d04329e1" # Amazon Linux 2 AMI
    instance_type = "t2.medium"
    subnet_id     = aws_subnet.public_subnet_a.id
    key_name      = var.key_name
    associate_public_ip_address = true
    security_groups = [aws_security_group.k8ws_sg.id]
    tags = {
      Name = "k8ws_workstation"
    }
  }
  # create ansible EC2 master
  resource "aws_instance" "ansible_master" {
    ami           = "ami-0fe972392d04329e1" # Amazon Linux 2 AMI
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.public_subnet_a.id
    key_name      = var.key_name
    associate_public_ip_address = true
    security_groups = [aws_security_group.k8ws_sg.id]
      user_data = <<-EOF
  #!/bin/bash
  sudo yum -y update
  # Enable EPEL repository
  sudo amazon-linux-extras install epel
  # Install Ansible
  sudo yum install -y ansible
  sudo yum install -y git
  cd /home/ec2-user
  # Clone the project repository and checkout the specific branch
  sudo git clone https://github.com/richardthe1stt/proj-mdp-152-155.git
  cd /home/ec2-user/proj-mdp-152-155
  # Verify installation (optional, logs to /var/log/user-data.log)
  ansible --version >> /var/log/user-data.log 2>&1
  EOF
      tags = {
        Name = "ansible_master"
      }
    }
    # S3 Bucket for Kubernetes state
resource "aws_s3_bucket" "k8ws_bucket" {
  bucket = "k8ws-kops-everything-state-chsufg1"
  tags = {
    Name = "k8ws_bucket"
  }
}
resource "aws_s3_bucket_versioning" "k8ws_bucket_versioning" {
  bucket = aws_s3_bucket.k8ws_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "k8ws_bucket_ownership" {
  bucket = aws_s3_bucket.k8ws_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "k8ws_bucket_public_block" {
  bucket = aws_s3_bucket.k8ws_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

