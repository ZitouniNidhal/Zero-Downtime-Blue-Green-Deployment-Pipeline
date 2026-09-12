# 1. The Application Load Balancer (ALB)
resource "aws_lb" "app_alb" {
  name               = "blue-green-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.deploy_sg.id]
  subnets            = module.vpc.public_subnets # Using your VPC module
}

# 2. Target Group (Where the LB sends traffic)
resource "aws_lb_target_group" "app_tg" {
  name     = "blue-green-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# 3. Listener (Listens on port 80 and forwards to Target Group)
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. Auto Scaling Group (The Cluster)
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2  # Keep 2 servers running at all times
  max_size           = 4  # Scale up to 4 if traffic spikes
  min_size           = 2  # Never go below 2 servers
  
  target_group_arns  = [aws_lb_target_group.app_tg.arn]
  vpc_zone_identifiers = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}