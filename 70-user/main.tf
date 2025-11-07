# User Instance creation..
resource "aws_instance" "user" {
  ami = local.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [local.user_sg_id]
  subnet_id = local.private_subnet_id
  

  tags = merge (
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-user"
    }
  )
  }

#Connect to user instance using remote-exec provisioner through terraform_data
  resource "terraform_data" "user" {
  triggers_replace = [ #If ec2 instance id is changed then terraform_data block starts its execution
    aws_instance.user.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.user.private_ip
  }

# terraform copies the file to redis server
    provisioner "file" {
    source = "user.sh"
    destination = "/tmp/user.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/user.sh",
      "sudo sh /tmp/user.sh user ${var.environment}"
    ]
  }
}