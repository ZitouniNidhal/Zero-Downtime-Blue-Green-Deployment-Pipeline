output "ecr_repository_url" {
  description = "URL of the Amazon ECR Container Registry"
  value       = module.ecr.repository_url
}

output "deployment_host_public_ip" {
  description = "Public IP address of the deployment host"
  value       = module.ec2_deployment_host.public_ip
}


output "deployment_host_public_dns" {
  description = "Public DNS of the deployment host"
  value       = module.ec2_deployment_host.public_dns
}

output "ssh_connection_command" {
  description = "Command to SSH into the deployment host"
  value       = "ssh ubuntu@${module.ec2_deployment_host.public_ip}"
}

output "app_url" {
  description = "URL of the live Web Application"
  value       = "http://${module.ec2_deployment_host.public_ip}/"
}

output "grafana_url" {
  description = "URL for Grafana Monitoring Dashboard"
  value       = "http://${module.ec2_deployment_host.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL for Prometheus Metrics Server"
  value       = "http://${module.ec2_deployment_host.public_ip}:9090"
}
