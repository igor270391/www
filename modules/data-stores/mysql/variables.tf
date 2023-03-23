variable "db_name" {
  description = "Name for the DB."
  type        = string
  default     = null
}

variable "db_username" {
  description = "The username for the DB"
  type = string
  sensitive = true
  default = null
}

variable "db_password" {
  description = "The pass for the DB"
  type = string
  sensitive = true
  default = null
}

# to use DB read replicas
variable "backup_retention_period" {
  description = "Days to retain backups. Must be > 0 to enable replication"
  type = number
  default = null
}

variable "replicate_source_db" {
  description = "If specified, replicate the RDS db at the given ARN"
  type = string
  default = null
}