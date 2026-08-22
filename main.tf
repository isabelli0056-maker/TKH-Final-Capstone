terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ----------------------------------------------------------------------
# 1. NETWORK ARCHITECTURE
# ----------------------------------------------------------------------

# AWS VPC (10.0.0.0/16)
resource "aws_vpc" "capstone_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "TKH-Capstone-VPC"
  }
}

# AWS Subnet (10.0.1.0/24)
resource "aws_subnet" "capstone_subnet" {
  vpc_id                  = aws_vpc.capstone_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "TKH-Capstone-Public-Subnet"
  }
}

# AWS Internet Gateway
resource "aws_internet_gateway" "capstone_igw" {
  vpc_id = aws_vpc.capstone_vpc.id

  tags = {
    Name = "TKH-Capstone-IGW"
  }
}

# AWS Route Table mapping 0.0.0.0/0 to IGW
resource "aws_route_table" "capstone_public_rt" {
  vpc_id = aws_vpc.capstone_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone_igw.id
  }

  tags = {
    Name = "TKH-Capstone-Public-RouteTable"
  }
}

# Route Table Association
resource "aws_route_table_association" "capstone_rta" {
  subnet_id      = aws_subnet.capstone_subnet.id
  route_table_id = aws_route_table.capstone_public_rt.id
}

# ----------------------------------------------------------------------
# 2. FIREWALL & SECURITY GROUP
# ----------------------------------------------------------------------

resource "aws_security_group" "web_sg" {
  name        = "capstone-web-sg"
  description = "Allow HTTP inbound from anywhere and SSH inbound ONLY from home IP"
  vpc_id      = aws_vpc.capstone_vpc.id

  # Ingress Port 80 (HTTP) from Anywhere
  ingress {
    description = "HTTP Ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress Port 22 (SSH) strictly from Home IP (/32)
  ingress {
    description = "SSH Ingress from Home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_home_ip]
  }

  # Egress (Outbound traffic allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TKH-Capstone-Web-SG"
  }
}

# ----------------------------------------------------------------------
# 3. SERVER INSTANCE (Amazon Linux 2023 with Apache user_data)
# ----------------------------------------------------------------------

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# EC2 Web Server Instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.capstone_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to TKH Capstone Web Server</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "TKH-Capstone-Web-Server"
  }
}