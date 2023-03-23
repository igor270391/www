provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "github.com/www/modules/services/webserver-cluster?ref=v0.0.1"

  cluster_name = "webservers-prod"
  db_remote_state_bucket = "prod-mysql-t-remote-state"
  db_remote_state_key = "prod/data-stores/mysql/terraformstate.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 10
  enable_autoscaling = true

  custom_tags = {
    Owner = "team-foo"
    ManagedBy = "terraform"
  }
 }