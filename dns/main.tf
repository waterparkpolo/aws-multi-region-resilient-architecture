data "terraform_remote_state" "us_east_1" {
  backend = "s3"
  config = {
    bucket = "mikah-terraform-state-2026"
    key    = "project5/us-east-1/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "us_west_2" {
  backend = "s3"
  config = {
    bucket = "mikah-terraform-state-2026"
    key    = "project5/us-west-2/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_route53_zone" "private" {
  name = var.zone_name

  vpc {
    vpc_id = data.terraform_remote_state.us_east_1.outputs.vpc_id
  }
}

resource "aws_route53_zone_association" "secondary" {
  zone_id    = aws_route53_zone.private.zone_id
  vpc_id     = data.terraform_remote_state.us_west_2.outputs.vpc_id
  vpc_region = "us-west-2"
}

resource "aws_route53_health_check" "primary" {
  fqdn              = data.terraform_remote_state.us_east_1.outputs.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
}

resource "aws_route53_record" "primary" {
  zone_id        = aws_route53_zone.private.zone_id
  name           = var.record_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = data.terraform_remote_state.us_east_1.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.us_east_1.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id        = aws_route53_zone.private.zone_id
  name           = var.record_name
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = data.terraform_remote_state.us_west_2.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.us_west_2.outputs.alb_zone_id
    evaluate_target_health = true
  }
}