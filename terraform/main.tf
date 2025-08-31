# Create S3 Bucket for KOPS State Storage
resource "aws_s3_bucket" "kops_state" {
  bucket = var.bucket_name
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Project = "kubernetes-cluster"
  }
}

# Create VPC for Kubernetes Cluster
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "k8s-vpc"
  }
}

# Fetch Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Public Subnets in 2 AZs
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "k8s-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Associate Subnets with Route Table
resource "aws_route_table_association" "public_rta" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# IAM Role for KOPS
resource "aws_iam_role" "kops_role" {
  name = "kops-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach Administrative Policy to KOPS Role (for demo purposes)
resource "aws_iam_role_policy_attachment" "kops_admin" {
  role       = aws_iam_role.kops_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM Role for Kubernetes Nodes
resource "aws_iam_role" "node_role" {
  name = "k8s-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach Policies to Node Role
resource "aws_iam_role_policy_attachment" "node_ec2" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "node_s3" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Security Group for SSH Access
resource "aws_security_group" "ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "allow-ssh"
  }
}
