resource "aws_ssm_parameter" "frontend_alb_listener" {
  name  = "/${var.project_name}/${var.environment}/frontend_alb_listener"
  type  = "String"
  value = aws_acm_certificate.roboshop.arn
}