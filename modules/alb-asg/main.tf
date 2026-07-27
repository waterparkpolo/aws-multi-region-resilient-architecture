############################################
# ALB Security Group
############################################

resource "aws_security_group" "alb" {
  name        = "${var.name}-${var.environment}-alb-sg"
  description = "Security group for internet-facing ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.environment}-alb-sg"
    }
  )
}


############################################
# EC2 Security Group
############################################

resource "aws_security_group" "ec2" {
  name        = "${var.name}-${var.environment}-ec2-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP only from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.environment}-ec2-sg"
    }
  )
}


############################################
# Application Load Balancer
############################################

resource "aws_lb" "this" {
  name = "${var.name}-${var.environment}-alb"

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = var.public_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.environment}-alb"
    }
  )
}


############################################
# Target Group
############################################

resource "aws_lb_target_group" "this" {
  name = "${var.name}-${var.environment}-tg"

  port     = var.app_port
  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {
    enabled  = true
    path     = var.health_check_path
    protocol = "HTTP"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.environment}-tg"
    }
  )
}


############################################
# ALB Listener
############################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.this.arn
  }
}


############################################
# Launch Template
############################################

resource "aws_launch_template" "this" {
  name = "${var.name}-${var.environment}-lt"

  image_id = var.ami_id

  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = base64encode(<<-EOF
#!/bin/bash

dnf update -y

dnf install nginx -y

systemctl start nginx
systemctl enable nginx

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

cat <<HTML > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Project 5 Resilient Architecture</title>
</head>

<body>

<h1>Project 5 Multi-Region Failover Test</h1>

<p>Region: $REGION</p>

<p>Instance ID: $INSTANCE_ID</p>

</body>
</html>
HTML

EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.name}-${var.environment}-instance"
      }
    )
  }
}


############################################
# Auto Scaling Group
############################################

resource "aws_autoscaling_group" "this" {

  name = "${var.name}-${var.environment}-asg"

  desired_capacity = var.desired_capacity

  min_size = var.min_size

  max_size = var.max_size

  vpc_zone_identifier = var.private_subnet_ids


  launch_template {
    id = aws_launch_template.this.id

    version = "$Latest"
  }


  target_group_arns = [
    aws_lb_target_group.this.arn
  ]


  health_check_type = "ELB"


  tag {
    key                 = "Name"
    value               = "${var.name}-${var.environment}-instance"
    propagate_at_launch = true
  }
}