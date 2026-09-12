# Launch Template for the App Servers
resource "aws_launch_template" "app_lt" {
  name          = "blue-green-app-template"
  image_id      = "ami-0c55b159cbfafe1f0" # Replace with your region's Ubuntu AMI
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.deploy_sg.id]
  }

  # The User Data script installs Docker and clones the repo automatically
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    mkdir -p /home/ubuntu/app
    git clone https://github.com/ZitouniNidhal/Zero-Downtime-Blue-Green-Deployment-Pipeline.git /home/ubuntu/app
    cd /home/ubuntu/app
    docker compose up -d
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}