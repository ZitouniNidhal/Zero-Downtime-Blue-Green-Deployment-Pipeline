# Lookup latest Ubuntu 22.04 LTS AMI if ami_id is not specified
data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
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

resource "aws_key_pair" "deployer" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.app_name}-${var.environment}-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "deployment_host_sg" {
  name        = "${var.app_name}-${var.environment}-sg"
  description = "Security Group for Blue-Green Deployment Host"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP Web Application Access
  ingress {
    description = "HTTP Web App (Nginx)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS Web Access
  ingress {
    description = "HTTPS Web App"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Prometheus Access
  ingress {
    description = "Prometheus Monitoring"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Grafana Dashboard Access
  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # cAdvisor Container Metrics Access
  ingress {
    description = "cAdvisor Metrics"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Outbound All Traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-sg"
    Environment = var.environment
  }
}

resource "aws_instance" "deployment_host" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.deployment_host_sg.id]
  key_name               = var.ssh_public_key != "" ? aws_key_pair.deployer[0].key_name : var.key_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -ex

              # Update system packages
              apt-get update && apt-get upgrade -y
              apt-get install -y ca-certificates curl gnupg lsb-release git make

              # Install Docker
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

              # Enable Docker service and add ubuntu user to docker group
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              # Prepare deployment directory
              mkdir -p /opt/bluegreen-deploy
              chown -R ubuntu:ubuntu /opt/bluegreen-deploy

              # Clone repository if configured
              if [ -n "${var.git_repo_url}" ]; then
                sudo -u ubuntu git clone ${var.git_repo_url} /opt/bluegreen-deploy || true
                cd /opt/bluegreen-deploy
                sudo -u ubuntu cp .env.example .env || true
                sudo -u ubuntu chmod +x deploy.sh rollback.sh || true
              fi

              echo "Deployment host bootstrap complete."
              EOF

  tags = {
    Name        = "${var.app_name}-${var.environment}-server"
    Environment = var.environment
  }
}
