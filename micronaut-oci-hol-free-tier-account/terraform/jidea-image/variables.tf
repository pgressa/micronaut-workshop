variable "ssh_public_key" {}
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

variable "use_free_tier" {
  default = false
}

variable "compartment_name" {
  default = "mn-oci-hol"
}

variable "projector_image_source_uri" {
  default = "https://objectstorage.us-phoenix-1.oraclecloud.com/p/GM2geYGPG5O7J39b4Oei5H7l1t0CEeM46QOIjrHLJEdDiy-t6G65y25rxHtXFw6G/n/cloudnative-devrel/b/workshop-images/o/jidea-workshop-image-v8"
}

variable "instance_display_name" {
  default = "mn-oci-demo"
}
variable "dynamic_group_display_name" {
  default = "mn-oci-demo-dynamic"
}

variable "boot_volume_size_in_gbs" {
  default = 50
}

variable "shape_limit" {
  default = "standard-e2-core-count"
}

variable "shape" {
  default = "VM.Standard.E2.2"
}
variable "assign_public_ip" {
  default = "true"
}
variable "vnic_name" {
  default = "micronaut-hol"
}

variable "attachment_type" {
  default = "iscsi"
}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "vcn_dns_label" {
  default     = "vcn"
}

variable "subnet_dns_label" {
  default = "subnet"
}

variable "autonomous_database_db_workload" {
  default = "OLTP"
}

variable "autonomous_database_license_model" {
  default = "LICENSE_INCLUDED"
}

variable "autonomous_database_db_name" {
  default = "mnociatp"
}

variable "autonomous_database_display_name" {
  default = "mnociatp"
}

variable "autonomous_database_is_dedicated" {
  default = "false"
}

provider "oci" {
  retry_duration_seconds = 120
  tenancy_ocid = var.tenancy_ocid
  region = var.region
}
