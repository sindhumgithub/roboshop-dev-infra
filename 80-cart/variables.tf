variable "project_name" {
  type        = string
  default = "roboshop"
}

variable "environment" {
  type        = string
  default =  "env"
}

variable "instance_type" {
  type        = string
  default = "t3.micro"
}

variable "service_name" {
  type = string
  default = "cart"
}

variable "health_check_interval" {
  type        = number
  default = 30
}

variable "domain_name" {
  type = string
  default = "sindhuworld.icu"
}

