output "adress" {
  value = aws_db_instance.mysql.adress
  description = "Connect to the DB instances"
}

output "port" {
  value = aws_db_instance.mysql.port
  description = "The port the database is listening on"
}

output "arn" {
  value = aws_db_instance.mysql.arn
  description = "The ARn of the db"
}