# Terraform Infrastructure for Blue-Green Deployment Host

This Terraform module provisions a production-ready AWS infrastructure for hosting the Zero-Downtime Blue-Green deployment pipeline.

## Architecture

- **VPC**: Isolated cloud network (`10.0.0.0/16`) with an Internet Gateway and public subnet.
- **Security Group**: Permits ports:
  - `80` / `443`: Public web application traffic (Nginx proxy)
  - `22`: SSH deployment access
  - `9090`: Prometheus metrics server
  - `3000`: Grafana monitoring dashboard
  - `8080`: cAdvisor container statistics
- **EC2 Instance**: Ubuntu 22.04 LTS instance pre-configured via `user_data` with Docker Engine, Docker Compose v2, Git, and automated project repository initialization.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads) v1.5+ installed.
2. AWS CLI configured with credentials (`aws configure` or environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
3. An SSH public key pair on your machine (`~/.ssh/id_rsa.pub`).

## Quick Start

1. Navigate to the `terraform/` directory:
   ```bash
   cd terraform
   ```

2. Copy the example variable file and adjust parameters:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Fill in `ssh_public_key` in `terraform.tfvars` with the contents of your `~/.ssh/id_rsa.pub`.

4. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

5. Copy the output details (`deployment_host_public_ip`) to configure GitHub Actions secrets:
   - `DEPLOY_HOST`: Output IP address from `deployment_host_public_ip`
   - `DEPLOY_USER`: `ubuntu`
   - `DEPLOY_SSH_KEY`: Content of your private SSH key matching `ssh_public_key`

## Modules Overview

- `modules/vpc/`: Manages VPC, Subnet, Internet Gateway, Route Tables.
- `modules/ec2_deployment_host/`: Configures Security Group, Key Pair, and EC2 Instance bootstrap user_data script.

## Destroying Infrastructure

To clean up resources provisioned by Terraform:
```bash
terraform destroy -auto-approve
```
