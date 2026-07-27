############################################
# Load Balancer Outputs
############################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}


############################################
# Target Group Outputs
############################################

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.this.arn
}


############################################
# Security Group Outputs
############################################

output "alb_security_group_id" {
  description = "Security group ID attached to the ALB"
  value       = aws_security_group.alb.id
}

output "instance_security_group_id" {
  description = "Security group ID attached to EC2 instances"
  value       = aws_security_group.ec2.id
}


############################################
# Auto Scaling Outputs
############################################

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}


############################################
# Launch Template Outputs
############################################

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = aws_launch_template.this.id
}