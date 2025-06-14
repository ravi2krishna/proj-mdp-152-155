provider "aws" {
  region = "us-east-2"
}

# 1. VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "k8s-vpc"
  }
}

# 2. Public Subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id                          = aws_vpc.k8s_vpc.id
  cidr_block                      = "10.0.1.0/24"
  availability_zone               = "us-east-2a"
  map_public_ip_on_launch        = true
  assign_ipv6_address_on_creation = false
  tags = {
    Name = "k8s-subnet"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "k8s-igw"
  }
}

# 4. Route Table
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "k8s-rt"
  }
}

# 5. Route to Internet
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.k8s_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.k8s_igw.id
}

# 6. Route Table Association
resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

# 7. Security Group (SSH + K8s API + All Egress)
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow SSH and Kubernetes API"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

# 8. Master Node
resource "aws_instance" "k8s_master" {
  ami                         = "ami-0d512b4a2ccda15f1" # Amazon Linux 2 - us-east-2
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = "devops-key"
  associate_public_ip_address = true

  tags = {
    Name = "k8s-master"
  }
}

# 9. Worker Nodes (x2)
resource "aws_instance" "k8s_worker" {
  count                       = 2
  ami                         = "ami-0d512b4a2ccda15f1"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = "devops-key"
  associate_public_ip_address = true

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}
