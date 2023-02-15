output "alb_dns_name" {
  value = aws_lb.app_load_balancer.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value = aws_autoscaling_group.asg_ec2.name
  description = "The name of auto scaling group"
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}