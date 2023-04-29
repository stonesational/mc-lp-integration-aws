
data "aws_route53_zone" "jasonstone_us_zone" {
  name         = "jasonstone.us"
  private_zone = false
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "navomi.jasonstone.us"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dns_records" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.jasonstone_us_zone.zone_id
}


resource "aws_acm_certificate_validation" "navomi_jasonstone_us" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_records : record.fqdn]
}

resource "aws_route53_record" "navomi_jasonstone_us" {
  zone_id = data.aws_route53_zone.jasonstone_us_zone.zone_id
  name    = "navomi.jasonstone.us"
  type    = "A"

  alias {
    name                   = aws_lb.inbound_elb.dns_name
    zone_id                = aws_lb.inbound_elb.zone_id
    evaluate_target_health = true
  }
}


resource "aws_lb" "inbound_elb" {
  name               = "inbound-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.inbound_elb.id]
  subnets            = module.vpc.public_subnets

}


resource "aws_security_group" "inbound_elb" {
  name        = "Inbound ELB Security Group"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Inbound TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Inbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "inbound_elb_https_listener" {
  load_balancer_arn = aws_lb.inbound_elb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.navomi_jasonstone_us.certificate_arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.api_target_group.arn
      }
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# APPLICATION LOAD BALANCER CONFIGURATION
# Inbound ELB on port 80 to ECS service on port 8080
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "api_target_group" {
  name        = "${var.application_name}-target-group"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}


resource "aws_lb_listener_rule" "api_lb_listener_rule" {
  listener_arn = aws_lb_listener.inbound_elb_https_listener.arn
  priority     = 99
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}