# terraform_remote_state data sourse

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
}

resource "aws_db_instance" "mysql" {
  identifier_prefix = "db-mysql-identifier"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  skip_final_snapshot = true
  db_name = "prod-mysql-t-remote-state"

  username = var.db_username
  password = var.db_password
}