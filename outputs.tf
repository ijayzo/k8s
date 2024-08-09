output "instance_ip" {
  description = "the pub ip for ssh access"
  value       = aws_instance.terraform_project[var.index].public_ip
}
