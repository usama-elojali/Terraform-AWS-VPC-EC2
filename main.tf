# main.tf

terraform {
  required_version = ">= 1.5.0" # ensure a modern Terraform version
  required_providers {
    aws  = { source = "hashicorp/aws", version = ">= 5.0" }  # AWS provider
    http = { source = "hashicorp/http", version = ">= 3.0" } # to fetch your public IP
  }
}

# Use the region from variables.tf
provider "aws" {
  region = var.region
}

# List available AZs so we can place subnets across zones for resilience
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetch your current public IP to lock down SSH/HTTP to just you
data "http" "myip" {
  url = "https://checkip.amazonaws.com"
}

# Turn the IP into CIDR form (x.x.x.x/32)
locals {
  my_ip_cidr = "${chomp(data.http.myip.response_body)}/32"
}

# --------------------------
# Networking: VPC + internet
# --------------------------

# Create the VPC (your private network in AWS)
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr # 10.0.0.0/16 by default
  enable_dns_hostnames = true         # needed for public DNS names
  enable_dns_support   = true
  tags                 = { Name = "${var.project}-vpc" }
}

# Internet Gateway: provides a path to/from the public internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-igw" }
}

# Two public subnets across the first 2 AZs
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs) # create as many as CIDRs
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true                                                     # auto-assign public IP to instances
  availability_zone       = data.aws_availability_zones.available.names[count.index] # spread across AZs
  tags = {
    Name = "${var.project}-public-${count.index + 1}"
  }
}

# Public route table: default route (0.0.0.0/0) points to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"                 # all IPv4 traffic
    gateway_id = aws_internet_gateway.igw.id # go via IGW
  }
  tags = { Name = "${var.project}-public-rt" }
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------
# Security: lock it down
# ------------------------

# Security Group: allow only YOUR IP for SSH(22) and HTTP(80)
resource "aws_security_group" "web_sg" {
  name        = "${var.project}-web-sg"
  description = "Allow SSH/HTTP from my IP only"
  vpc_id      = aws_vpc.this.id

  # SSH inbound for remote login (from your IP only)
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr] # e.g., 81.2.69.142/32
  }

  # HTTP inbound to view Nginx test page (from your IP only)
  ingress {
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # All outbound allowed (updates, package installs, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-web-sg" }
}

# ------------------------
# Compute: EC2 + key pair
# ------------------------

# Upload your local SSH public key, so you can log into the instance
resource "aws_key_pair" "this" {
  key_name   = "${var.project}-key"      # shows up in EC2 console
  public_key = file("/Users/usamaelojali/.ssh/id_rsa.pub") # reads your public key
}

# Find the latest Amazon Linux 2 AMI (official publisher ID)
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["137112412989"] # Amazon Linux 2 owner AWS account ID
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"] # AL2 x86_64
  }
}

# One EC2 instance in the first public subnet, with Nginx installed via user data
resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type       # t2.micro (free-tier)
  subnet_id                   = aws_subnet.public[0].id # first public subnet
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true                                # ensure it has a public IP
  user_data                   = file("${path.module}/user_data.sh") # run our setup script

  tags = { Name = "${var.project}-web" }
}
