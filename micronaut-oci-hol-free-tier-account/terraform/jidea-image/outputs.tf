output "projector_link" {
  description = "Intelli JIdea projector link"
  value       = "https://${oci_core_instance.this.public_ip}"
}

output "atp_admin_password" {
  description = "Database admin password."
  value = random_string.autonomous_database_admin_password.result
}

output "atp_schema_user" {
  description = "Database user."
  value = "mnocidemo"
}

output "atp_schema_password" {
  description = "Database user password."
  value = random_string.autonomous_database_schema_password.result
}

output "atp_wallet_password" {
  description = "Database wallet password."
  value = random_string.autonomous_database_wallet_password.result
}

output "atp_db_service_alias" {
  description = "Database service alias."
  value = "${oci_database_autonomous_database.autonomous_database.db_name}_high"
}

output "atp_db_ocid" {
  description = "Database id."
  value = oci_database_autonomous_database.autonomous_database.id
}

output "compartment_ocid" {
  description = "Instance compartment"
  value = oci_core_instance.this.compartment_id
}

output "region" {
  value = var.region
}