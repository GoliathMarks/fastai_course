variable "aws_region" {
  description = "AWS region to launch the instance in. g4dn is available in most regions."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "ryan"
}

variable "public_key_path" {
  description = "Path to the SSH public key to load onto the instance."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH (22) and Jupyter (8888). Restrict to your IP for security."
  type        = list(string)
  default     = ["71.117.128.174/32"] 
}
