variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "my_home_ip" {
  description = "Your specific home IP address for SSH access"
  type        = string
  default     = "108.27.77.58/32"
}