output "alb_dns_name" {
  value = module.aws_lb.app_load_balancer.dns_name
  description = "The domain name of the load balancer"
}