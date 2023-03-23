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

module "mysql" {
  source = "../../../../modules/data-stores/mysql"
 
  db_name = "prod_db"
  db_username = var.db_username
  db_password = var.db_password

}