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

resource "aws_vpc" "capstone_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "TKH-Capstone-VPC"
  }
}

#tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "capstone_subnet" {
  vpc_id                  = aws_vpc.capstone_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "TKH-Capstone-Public-Subnet"
  }
}

resource "aws_internet_gateway" "capstone_igw" {
  vpc_id = aws_vpc.capstone_vpc.id

  tags = {
    Name = "TKH-Capstone-IGW"
  }
}

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

resource "aws_route_table_association" "capstone_rta" {
  subnet_id      = aws_subnet.capstone_subnet.id
  route_table_id = aws_route_table.capstone_public_rt.id
}

# ----------------------------------------------------------------------
# 2. FIREWALL & SECURITY GROUP
# ----------------------------------------------------------------------

#tfsec:ignore:aws-ec2-add-description-to-security-group-rule
resource "aws_security_group" "web_sg" {
  name        = "capstone-web-sg"
  description = "Allow HTTP inbound from anywhere and SSH inbound ONLY from home IP"
  vpc_id      = aws_vpc.capstone_vpc.id

  ingress {
    description = "Allow HTTP access from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH access strictly from home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_home_ip]
  }

  egress {
    description = "Allow all outbound traffic"
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
# 3. SERVER INSTANCE
# ----------------------------------------------------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.capstone_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  metadata_options {
    http_tokens = "required"
  }

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