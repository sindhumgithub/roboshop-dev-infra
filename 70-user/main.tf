#1. User Instance creation..
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

#2. Connect to user instance using remote-exec provisioner through terraform_data
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

# 3. Terraform code to stop instance to take AMI image
resource "aws_ec2_instance_state" "user" {
  instance_id = aws_instance.user.id
  state       = "stopped"
  depends_on = [terraform_data.user]
}

# 4. Terraform code to take AMI from stopped Instance.
resource "aws_ami_from_instance" "user" {
  name               = "${local.common_name_suffix}-user-ami"
  source_instance_id = aws_instance.user.id
  depends_on = [aws_ec2_instance_state.user]
    tags = merge (
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-user"
    }
  )
}


# 5. User target group code.
resource "aws_lb_target_group" "user" {
  name     = "${local.common_name_suffix}-user"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60  #waiting period before deleting the instance.
  health_check {
    healthy_threshold = 2
    interval = 20
    matcher = "200-299"
    path = "/health"
    port = 8080
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

#6. terraform code to create launch template.
resource "aws_launch_template" "user" {
  name = "${local.common_name_suffix}-user"
  image_id = aws_ami_from_instance.user.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  vpc_security_group_ids = [local.user_sg_id]

# tags attached to the Instance
  tag_specifications {
    resource_type = "instance"

    tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-user"
    }
  )
}

# tags attached to the Volume created by Instance.
  tag_specifications {
    resource_type = "volume"

    tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-user"
    }
  )
}

# tags attached to the Launch Template
tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-user"
    }
  )
}

# 7. Autoscaling code 
resource "aws_autoscaling_group" "user" {
  name                      = "${local.common_name_suffix}-user"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  launch_template {
    id      = aws_launch_template.user.id
    version = aws_launch_template.user.latest_version
  }
  vpc_zone_identifier       = local.private_subnet_ids
  target_group_arns = [aws_lb_target_group.user.arn]
  dynamic "tag" {  # We will get the iterator with name as tag
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-user"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  timeouts {
    delete = "15m"
  }
}

#8. Autoscaling policy code.
resource "aws_autoscaling_policy" "user" {
  autoscaling_group_name = aws_autoscaling_group.user.name
  name                   = "${local.common_name_suffix}-user"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

#9. Load Balancer Rule
resource "aws_lb_listener_rule" "user" {
  listener_arn = local.backend_alb_listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user.arn
  }

  condition {
    host_header {
      values = ["user.backend-alb-${var.environment}.${var.domain_name}"]
    }
  }
}