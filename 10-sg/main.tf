module "sg" {
    count = length(var.sg_names)
    source = "D:\\DevOpsShiva\\terraform-roboshop-project\\terraform-aws-sg"
    project_name = var.project_name
    environment = var.environment
    sg_name = var.sg_names[count.index] #mongodb, redis, mysql, rabbitmq
    sg_description = "created for ${var.sg_names[count.index]}"
    vpc_id = local.vpc_id
}

# # Frontend VM's accepting traffic from frontend load balancer.
# resource "aws_security_group_rule" "frontend_frontend_alb" {
#   type = "ingress"
#   security_group_id = module.sg[9].sg_id  #frontend SG ID
#   source_security_group_id =  module.sg[11].sg_id #frontend load balancer ID
#   from_port         = 80
#   protocol          = "tcp"
#   to_port           = 80
# }