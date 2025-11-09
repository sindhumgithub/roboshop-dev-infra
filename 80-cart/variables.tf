variable "project_name" {
  type        = string
  default = "roboshop"
}

variable "environment" {
  type        = string
  default =  "dev"
}

variable "instance_type" {
  type        = string
  default = "t3.micro"
}

variable "service_name" {
  type = string
  default = "cart"
}



variable "domain_name" {
  type = string
  default = "sindhuworld.icu"
}

