# Terraform code to create mongodb ec2 instance
resource "aws_instance" "mongodb" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.mongodb_sg_id]
    subnet_id = local.database_subnet_id
    
    tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-mongodb" # roboshop-dev-mongodb
        }
    )
}

resource "terraform_data" "mongodb" {
  triggers_replace = [ #If ec2 instance id is changed then terraform_data block starts its execution
    aws_instance.mongodb.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.mongodb.private_ip
  }

# terraform copies the file to mongodb server
    provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstarp.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstarp.sh",
      "sudo sh /tmp/bootstarp.sh mongodb"
    ]
  }
}


# Terraform code to create redis ec2 instance
resource "aws_instance" "redis" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.redis_sg_id]
    subnet_id = local.database_subnet_id
    
    tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-redis" # roboshop-dev-redis
        }
    )
}

resource "terraform_data" "redis" {
  triggers_replace = [ #If ec2 instance id is changed then terraform_data block starts its execution
    aws_instance.redis.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.redis.private_ip
  }

# terraform copies the file to mongodb server
    provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstarp.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstarp.sh",
      "sudo sh /tmp/bootstarp.sh redis"
    ]
  }
}


# Terraform code to create rabbitmq ec2 instance
resource "aws_instance" "rabbitmq" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.rabbitmq_sg_id]
    subnet_id = local.database_subnet_id
    
    tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-rabbitmq" # roboshop-dev-redis
        }
    )
}

resource "terraform_data" "rabbitmq" {
  triggers_replace = [ #If ec2 instance id is changed then terraform_data block starts its execution
    aws_instance.rabbitmq.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.rabbitmq.private_ip
  }

# Terraform copies the file to rabbitmq server
    provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstarp.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstarp.sh",
      "sudo sh /tmp/bootstarp.sh rabbitmq"
    ]
  }
}



# Terraform code to create mysql ec2 instance
resource "aws_instance" "mysql" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.mysql_sg_id]
    subnet_id = local.database_subnet_id
    iam_instance_profile = aws_iam_instance_profile.mysql.name
    
    tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-mysql" # roboshop-dev-mysql
        }
    )
}

# code to read SSM parameter store parameters using  IAM role 
resource "aws_iam_instance_profile" "mysql" {
  name = "mysql"
  role = "EC2SSMParameterRead"
}

resource "terraform_data" "mysql" {
  triggers_replace = [ #If ec2 instance id is changed then terraform_data block starts its execution
    aws_instance.mysql.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.mysql.private_ip
  }

# Terraform copies the file to mysql server
    provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstarp.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstarp.sh",
      "sudo sh /tmp/bootstarp.sh mysql dev"
    ]
  }
}

# Route53 record creation for mongodb
resource "aws_route53_record" "mongodb" {
  zone_id = var.zone_id
  name    = "mongodb.${var.environment}.${var.domain_name}" #mongodb.dev.sindhuworld.icu
  type    = "A"
  ttl     = 1
  records = [aws_instance.mongodb.private_ip]
}

# Route53 record creation for redis
resource "aws_route53_record" "redis" {
  zone_id = var.zone_id
  name    = "redis.${var.environment}.${var.domain_name}"
  type    = "A"
  ttl     = 1
  records = [aws_instance.redis.private_ip]
}

# Route53 record creation for rabbitmq
resource "aws_route53_record" "rabbitmq" {
  zone_id = var.zone_id
  name    = "rabbitmq.${var.environment}.${var.domain_name}"
  type    = "A"
  ttl     = 1
  records = [aws_instance.rabbitmq.private_ip]
}

# Route53 record creation for mysql
resource "aws_route53_record" "mysql" {
  zone_id = var.zone_id
  name    = "mysql.${var.environment}.${var.domain_name}"
  type    = "A"
  ttl     = 1
  records = [aws_instance.mysql.private_ip]
}