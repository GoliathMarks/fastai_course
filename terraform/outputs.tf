output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.fastai.id
}

output "public_ip" {
  description = "Public IPv4 address — use this in your Ansible inventory"
  value       = aws_instance.fastai.public_ip
}

output "ssh_command" {
  description = "SSH command with Jupyter port forwarding"
  value       = "ssh -L localhost:8888:localhost:8888 ubuntu@${aws_instance.fastai.public_ip}"
}

output "ansible_inventory_hint" {
  description = "Quick inventory line for Ansible"
  value       = "fastai_host ansible_host=${aws_instance.fastai.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"
}
