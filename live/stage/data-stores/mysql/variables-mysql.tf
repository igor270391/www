variable "db_username" {
  description = "The username for the DB"
  type = string
  sensitive = true
}

variable "db_password" {
  description = "The pass for the DB"
  type = string
  sensitive = true
}