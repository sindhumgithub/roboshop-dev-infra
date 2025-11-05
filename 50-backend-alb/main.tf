resource "aws_lb" "backend_alb" {
  name               = "${local.common_name_suffix}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [local.backend_alb_sg_id]
  subnets            = local.private_subnet_ids

  enable_deletion_protection = true #We can't delete backend application using terraform and we need to delete manually from UI if we need to delete backend application.

  tags = merge (
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-backend-alb"  #roboshop-dev-backend-alb
    }
  )
}

# Backend Application load balancer listening on port no 80
resource "aws_lb_listener" "backend_alb" {
  load_balancer_arn = aws_lb.backend_alb.arn #Amazon Resource Name
  port              = "80"
  protocol          = "HTTP"

 default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hi, I am from backend ALB HTTP"
      status_code  = "200"
    }
  }
}


resource "aws_route53_record" "backend_alb" {
  zone_id = var.zone_id
  name    = "*.backend-alb-dev.${var.environment}.${var.domain_name}"
  type    = "A"
# These are Backend application load balancer details, not domain details.
  alias {
    name                   = aws_elb.backend_alb.dns_name
    zone_id                = aws_elb.backend_alb.zone_id
    evaluate_target_health = true
  }
}