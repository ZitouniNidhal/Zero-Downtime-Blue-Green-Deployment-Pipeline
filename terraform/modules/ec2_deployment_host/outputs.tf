output "public_ip" {
  description = "Public IP address of the EC2 deployment host"
  value       = aws_instance.deployment_host.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 deployment host"
  value       = aws_instance.deployment_host.public_dns
}

output "security_group_id" {
  description = "Security group ID attached to the deployment host"
  value       = aws_security_group.deployment_host_sg.id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.deployment_host.id
}
