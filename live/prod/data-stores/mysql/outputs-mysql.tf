output "primary_address" {
  value = module.mysql_primary.adress
  description = "Connect to the primary database at this point"
}

output "primary_port" {
  value = module.mysql_primary.port
  description = "The port  the primary database is listenning on"
}

output "primary_arn" {
  value = module.mysql_primary.arn
  description = "The ARN of the primary database"
}

output "replica_address" {
  value = module.mysql_replica.replica_address
  description = "Connect to the replica database at this point"
}

output "replica_port" {
  value = module.mysql_replica.port
  description = "The port  the replica database is listenning on"
}

output "preplica_arn" {
  value = module.mysql_replica.arn
  description = "The ARN of the replica database"
}