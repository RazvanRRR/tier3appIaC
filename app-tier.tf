########################################
# ALB Security Group
########################################
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.environment}"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.main.id

  # Inbound: allow HTTP from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: allow all 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg-${var.environment}"
  }
}

########################################
# App Security Group
########################################
resource "aws_security_group" "app_sg" {
  name        = "app-sg-${var.environment}"
  description = "App Tier Security Group"
  vpc_id      = aws_vpc.main.id

  # Inbound: allow HTTP from ALB only
  ingress {
    description             = "HTTP from ALB"
    from_port               = 80
    to_port                 = 80
    protocol                = "tcp"
    security_groups         = [aws_security_group.alb_sg.id]
  }

  # Egress: allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg-${var.environment}"
  }
}

########################################
# ALB + Target Group + Listener
########################################
resource "aws_lb" "public_alb" {
  name               = "3tier-alb-${var.environment}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

  tags = {
    Name = "3tier-alb-${var.environment}"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path = "/"
    port = "80"
  }

  tags = {
    Name = "app-tg-${var.environment}"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

########################################
# Launch Template 
########################################
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = var.app_instance_type
  key_name      = var.aws_key_name

  # Attach the App SG here (launch template level)
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data =  base64encode(templatefile("${path.module}/user_data.tpl",{}))


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app-instance-${var.environment}"
    }
  }
}

########################################
# App Auto Scaling Group
########################################
resource "aws_autoscaling_group" "app_asg" {
  name                = "asg-app-${var.environment}"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [for subnet in aws_subnet.private_subnets : subnet.id]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  # Attach to our Target Group
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  # Ensure instances are registered/deregistered smoothly
  health_check_type = "EC2"
  health_check_grace_period = 30

  tag {
    key                 = "Name"
    value               = "app-asg-${var.environment}"
    propagate_at_launch = true
  }
}
