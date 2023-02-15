provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webservers-stage"
  db_remote_state_bucket = "stage-mysql-t-remote-state"
  db_remote_state_key = "stage/data-stores/mysql/terraformstate.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2

}

# Expose an extra PORT in just the staging env for testing
resource "aws_security_group_rule" "allow_testing_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port = 12345
  to_port = 122345
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}