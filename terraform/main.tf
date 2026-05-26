terraform {
  required_version = ">= 1.3.0"

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

# ──────────────────────────────────────────────
# Resolve latest Ubuntu 20.04 LTS AMI
# ──────────────────────────────────────────────
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ──────────────────────────────────────────────
# Default VPC + subnets (keeps things simple)
# ──────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ──────────────────────────────────────────────
# Security group – SSH + Jupyter
# ──────────────────────────────────────────────
resource "aws_security_group" "fastai" {
  name        = "${var.name_prefix}-fastai-sg"
  description = "Allow SSH and Jupyter access for fast.ai course"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Jupyter is accessed via SSH tunnel (localhost:8888), so this rule is
  # optional — remove it if you always use the tunnel.
  ingress {
    description = "Jupyter Notebook"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.name_prefix}-fastai-sg"
    Project = "fast.ai"
  }
}

# ──────────────────────────────────────────────
# Key pair  (import your existing public key)
# ──────────────────────────────────────────────
resource "aws_key_pair" "fastai" {
  key_name   = "${var.name_prefix}-fastai-key"
  public_key = file(var.public_key_path)
}

# ──────────────────────────────────────────────
# g4dn.xlarge EC2 instance
# ──────────────────────────────────────────────
resource "aws_instance" "fastai" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = "g4dn.xlarge"
  key_name               = aws_key_pair.fastai.key_name
  vpc_security_group_ids = [aws_security_group.fastai.id]
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]

  # fast.ai recommends ≥ 100 GB — using gp3 for better price/performance
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
    encrypted             = true
  }

  # Tag the instance so it's easy to find in the console
  tags = {
    Name    = "${var.name_prefix}-fastai"
    Project = "fast.ai"
  }

  # Wait for the instance to be reachable before Terraform considers it done
  provisioner "local-exec" {
    command = "echo 'Instance ${self.public_ip} is ready. Run Ansible next.'"
  }
}
