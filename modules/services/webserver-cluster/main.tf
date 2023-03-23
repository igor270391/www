terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  alias = "region_1"
}

provider "aws" {
  region = "us-west-1"
  aalias  = "region_2"
}

data "aws_region" "name" {
  provider = aws.region_1
}

data "aws_region" "name" {
  provider = aws.region_2
}

resource "aws_launch_configuration" "ec2_cluster" {
  image_id      = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.sg_ec2.id]

  #tell to terraform to use instance profile defined in "../global/iam/main"
  iam_instance_profile = aws_iam_instance_profile.instance.name

  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_adress = data.terraform_remote_state.db.outputs.adress
    db_port = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sg_ec2" {
  name        = "${var.cluster_name}-sg-ec2"
  description = "Allow incomming request on port 8080 from any IP"

  ingress = {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_autoscaling_group" "asg_ec2" {
  
  launch_configuration = aws_launch_configuration.ec2_cluster.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  
  #To know which ec2 result unhealthy
  target_group_arns = [aws_lb_target_group.asg.target_group_arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  # Use instance refresh to roll out changes to ASG for 0 down time
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  
  tag {
    key = "Name"
    value = var.cluster_name
    propagate_at_launch = true
  }

  dynamic {
    for_each = {
      for key, value in var.custom_tags:
      key => upper(value)
      if key != "Name"
    }

    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
    }
}

# Autoscalling schedule
resource "aws_autoscaling_schedule" "scale_out_during_bisness_hours" {
  /* 1 -> means 1 resourse will be copy one resourse;
  0 -> set to false */
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "${var.cluster_name}-scale-out-during-bisness-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"

  autoscaling_group_name = module.webserver-cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"

  autoscaling_group_name = module.webserver-cluster.asg_name
}

# get the list of subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



# --------DEPLoy ALB-------------------
# Create <aws_lb>
# create listeners
# create SG for ALB
# create target group
# create listeners rule

resource "aws_lb" "app_load_balancer" {
  name = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port = local.http_port
  protocol = "HTTP"

  #By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    } 
  }
}

# Manage SG 
# - "Allow incoming request on port 80 to access LB over HTTP"
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-sg-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
  
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb_target_group" "asg" {
  name = "${var.cluster_name}alb-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_patern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# to read all outputs from the database's state
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "ue-east-2"
   }
}