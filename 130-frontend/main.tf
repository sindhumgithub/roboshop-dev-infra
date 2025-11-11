#1. User Instance creation..
resource "aws_instance" "frontend" {
  ami = local.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [local.frontend_sg_id]
  subnet_id = local.public_subnet_id
  

  tags = merge (
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-frontend"
    }
  )
  }

#2. Connect to user instance using remote-exec provisioner through terraform_data
  resource "terraform_data" "frontend" {
  triggers_replace = [ #If ec2 instance id is changed then terraform_data block starts its execution
    aws_instance.frontend.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.frontend.private_ip
  }

# terraform copies the file to redis server
    provisioner "file" {
    source = "frontend.sh"
    destination = "/tmp/frontend.sh" 
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo sh /tmp/frontend.sh frontend ${var.environment}"
    ]
  }
}

# 3. Terraform code to stop instance to take AMI image
resource "aws_ec2_instance_state" "frontend" {
  instance_id = aws_instance.frontend.id
  state       = "stopped"
  depends_on = [terraform_data.frontend]
}

# 4. Terraform code to take AMI from stopped Instance.
resource "aws_ami_from_instance" "frontend" {
  name               = "${local.common_name_suffix}-frontend-ami"
  source_instance_id = aws_instance.frontend.id
  depends_on = [aws_ec2_instance_state.frontend]
    tags = merge (
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-frontend"
    }
  )
}


# 5. User target group code.
resource "aws_lb_target_group" "frontend" {
  name     = "${local.common_name_suffix}-frontend"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60  #waiting period before deleting the instance.
  health_check {
    healthy_threshold = 2
    interval = 10
    matcher = "200-299"
    path = "/"
    port = 80
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

#6. terraform code to create launch template.
resource "aws_launch_template" "frontend" {
  name = "${local.common_name_suffix}-frontend"
  image_id = aws_ami_from_instance.frontend.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  vpc_security_group_ids = [local.frontend_sg_id]
  update_default_version = true

# tags attached to the Instance
  tag_specifications {
    resource_type = "instance"

    tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-frontend"
    }
  )
}

# tags attached to the Volume created by Instance.
  tag_specifications {
    resource_type = "volume"

    tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-frontend"
    }
  )
}

# tags attached to the Launch Template
tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-frontend"
    }
  )
}

# 7. Autoscaling code 
resource "aws_autoscaling_group" "frontend" {
  name                      = "${local.common_name_suffix}-frontend"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
  }
  vpc_zone_identifier       = local.public_subnet_ids
  target_group_arns = [aws_lb_target_group.frontend.arn]

# instance_refresh is used so that application will not be down and application is up and running.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 # atleast 50% of the instances should be up and running
    }
    triggers = ["launch_template"]
  }
  dynamic "tag" {  # We will get the iterator with name as tag
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-frontend"
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
resource "aws_autoscaling_policy" "frontend" {
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  name                   = "${local.common_name_suffix}-frontend"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

#9. Load Balancer Rule
resource "aws_lb_listener_rule" "frontend" {
  listener_arn = local.frontend_alb_listener_arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["frontend.backend-alb-${var.environment}.${var.domain_name}"]
    }
  }
}