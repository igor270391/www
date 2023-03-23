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
  alias = "primary"
}

provider "aws" {
  region = "us-west-1"
  alias = "replica"
}

module "mysql_primary" {
  source = "../../../../modules/data-stores/mysql"

  providers = {
    aws = aws.primary
   }

  db_name = "prod_db"
  db_username = var.db_username
  db_password = var.db_password

  # must be enable to support replication
  backup_retention_period = 1
}


# to create a replica add the second module
module "mysql_replica" {
  source = "../../../../modules/data-stores/mysql"

  providers = {
    aws = aws.replica
   }

  # Make this replica of primary
  replicate_source_db = module.mysql_primary.arn
}