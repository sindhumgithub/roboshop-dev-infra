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

  provisioner "remote_exec" {
    inline = [
      "chmod +x /tmp/bootstarp.sh",
      "sudo sh /tmp/bootstarp.sh"
    ]
  }
}