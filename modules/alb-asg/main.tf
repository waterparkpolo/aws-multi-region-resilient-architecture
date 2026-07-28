############################################
# IAM Role for EC2 Instances
############################################

resource "aws_iam_role" "ec2" {
  name = "${var.name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

############################################
# IAM Policy - Read Database Secret
############################################

resource "aws_iam_role_policy" "secrets_manager" {
  count = var.db_secret_arn != null ? 1 : 0

  name = "${var.name}-${var.environment}-secrets-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDatabaseSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      }
    ]
  })
}

############################################
# EC2 Instance Profile
############################################

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-${var.environment}-instance-profile"

  role = aws_iam_role.ec2.name

  tags = var.tags
}
############################################
# Data Sources
############################################

data "aws_region" "current" {}

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

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
  db_secret_arn = var.db_secret_arn != null ? var.db_secret_arn : ""
  aws_region    = data.aws_region.current.name
}))

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