variable "server_port" {
  description = "The port the server will use for requests"
  type = number
  default = 8080
}

variable "cluster_name" {
  description = "The name to use for all clusterresources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type = string
}

variable "instance_type" {
  description = "The type of the EC2 to run (e.g. t2.micro)"
  type = string
}

variable "min_size" {
  description = "The minimum number of EC2 in the ASG"
  type = number
}

variable "max_size" {
  description = "The maximum number of EC2 in the ASG"
  type = number
}

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

# utilizzato in production module
variable "custom_tags" {
  description = "Custom tags to seton the Instance in the ASG"
  type = map(string)
  default = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enable autoscaling"
  type = bool
}

variable "ami" {
  description = "The AMI to run in the cluster"
  type = string
  default = "ami-jd8ewd98ew9d8e9w"
}

variable "server_text" {
  description = "The text the web-cluster should run"
  type = string
  default = "Hello world"
}