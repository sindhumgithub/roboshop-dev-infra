variable "project_name" {
    default = "roboshop"
}

variable "environment"{
    default = "dev"
}

variable "sg_names" {
    default = [
    # database
    "mongodb","redis","mysql","rabbitmq",
    # backend
    "catalogue","user","cart","shipping","payment",
    # frontend
    "frontend",
    # bastion
    "bastion",
    # frontend load balancer
    "frontend_lb",
    # backend application load balancer
    "backend_alb"
    ]
}