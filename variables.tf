# variables.tf

# A short name used in tags and resource names so you can tell stacks apart.
variable "project" {
  description = "Short project tag used in names/tags"
  type        = string
  default     = "demo-vpc"
}

# Default AWS region to deploy into (London here).
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

# The VPC CIDR block (your private network range inside AWS).
variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

# Two public subnet CIDRs (one /24 each). We’ll spread them across 2 AZs.
variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Instance type – t2.micro is free-tier eligible.
variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.micro"
}
