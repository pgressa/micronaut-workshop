terraform {
  required_version = ">= 0.13.0"
}

resource "oci_identity_compartment" "this" {
  compartment_id = var.compartment_ocid
  description = "Micronaut HOL Compartment"
  name = var.compartment_name
}

resource "oci_core_vcn" "this" {
  dns_label      = var.vcn_dns_label
  cidr_block     = var.vcn_cidr
  compartment_id = oci_identity_compartment.this.id
  display_name   = var.vcn_display_name
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id
}

resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_security_list" "this" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id = oci_core_vcn.this.id
  ingress_security_rules {
    protocol = "6"
    source = "0.0.0.0/0"
    description = "Allow port 8080"
    stateless = "false"
    tcp_options {
      max = "8080"
      min = "8080"
    }
  }
}

resource "oci_core_subnet" "subnet" {
  availability_domain = local.availability_domain
  cidr_block          = cidrsubnet(var.vcn_cidr, ceil(log(length(data.oci_identity_availability_domains.this.availability_domains) * 2, 2)), 0)
  display_name        = "MN-OCI Demo Subnet"
  dns_label           = "${var.subnet_dns_label}1"
  compartment_id      = oci_identity_compartment.this.id
  vcn_id              = oci_core_vcn.this.id
  security_list_ids   = [
      oci_core_vcn.this.default_security_list_id,
      oci_core_security_list.this.id
  ]
}

data "oci_core_subnet" "this" {
  subnet_id = oci_core_subnet.subnet.id // the last AD should have the "always free" shapes...
}

data "oci_core_images" "this" {
  #Required
  compartment_id = oci_identity_compartment.this.id
  #Optional
  shape = length(local.availability_domains) > 0 ? "VM.Standard.E2.1.Micro" : "VM.Standard.E2.1"
  state = "AVAILABLE"
}

data "oci_limits_services" "services" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = ["compute"]
  }
}


data "oci_limits_resource_availability" "ad_limits_availability" {
  #Required
  compartment_id = var.tenancy_ocid
  limit_name = var.shape_limit_name
  service_name   = data.oci_limits_services.services.services.0.name
  count          = length(data.oci_identity_availability_domains.this.availability_domains)

  #Optional
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[count.index].name
}

locals {
  availability_domains = [for limit in data.oci_limits_resource_availability.ad_limits_availability : limit.availability_domain if limit.available >= 2]
  availability_domain = length(local.availability_domains) > 0 ? local.availability_domains[0] : data.oci_identity_availability_domains.this.availability_domains[0].name
}

resource "oci_core_instance" "this" {
  availability_domain  = local.availability_domain
  compartment_id       = oci_identity_compartment.this.id
  display_name         = var.instance_display_name
  shape                = var.shape

  create_vnic_details {
    assign_public_ip       = var.assign_public_ip
    display_name           = var.vnic_name
    subnet_id              = data.oci_core_subnet.this.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = var.user_data
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.this.images[0].id
  }
}

resource "oci_identity_dynamic_group" "instance_resource_principals_dynamic_group" {
  compartment_id = var.tenancy_ocid
  matching_rule = "ANY {instance.compartment.id = '${oci_identity_compartment.this.id}'}"
  description = "${var.dynamic_group_display_name}${random_string.suffix.result}-group"
  name = "${var.dynamic_group_display_name}${random_string.suffix.result}-group"
}

data "oci_identity_dynamic_groups" "instance_resource_principals_dynamic_group" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "id"
    values = [oci_identity_dynamic_group.instance_resource_principals_dynamic_group.id]
  }
}

resource "oci_identity_policy" "instance_resource_principals_policy" {
  compartment_id = var.tenancy_ocid
  description = "${var.dynamic_group_display_name}-policy"
  name = "${var.dynamic_group_display_name}-policy"
  statements = local.allow_dynamicgroup_manage_databases
}

locals {
  allow_dynamicgroup_manage_databases = [
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_resource_principals_dynamic_group.name} to manage autonomous-database-family in compartment ${oci_identity_compartment.this.name}"
  ]
}

resource "random_string" "autonomous_database_admin_password" {
  length      = 16
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  min_special = 1
  override_special = "_"
}

resource "random_string" "autonomous_database_schema_password" {
  length      = 16
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  min_special = 1
  override_special = "_"
}

data "oci_database_autonomous_db_versions" "test_autonomous_db_versions" {
  #Required
  compartment_id = oci_identity_compartment.this.id

  #Optional
  db_workload = var.autonomous_database_db_workload
}

resource "oci_database_autonomous_database" "autonomous_database" {
  #Required
  admin_password           = random_string.autonomous_database_admin_password.result
  compartment_id           = oci_identity_compartment.this.id
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  is_free_tier             = var.use_free_tier
  db_name                  = "${var.autonomous_database_db_name}${random_string.suffix.result}"

  #Optional
  //db_version                                     = data.oci_database_autonomous_db_versions.test_autonomous_db_versions.autonomous_db_versions.0.version
  db_workload                                    = var.autonomous_database_db_workload
  display_name                                   = var.autonomous_database_display_name
  license_model                                  = var.autonomous_database_license_model
  is_preview_version_with_service_terms_accepted = "false"
}

data "oci_database_autonomous_databases" "autonomous_databases" {
  #Required
  compartment_id = oci_identity_compartment.this.id

  #Optional
  display_name = oci_database_autonomous_database.autonomous_database.display_name
  db_workload  = var.autonomous_database_db_workload
}

resource "random_string" "autonomous_database_wallet_password" {
  length  = 16
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  min_special = 1
  override_special = "_"
}


resource "random_string" "suffix" {
  length  = 6
  special = false
}

resource "oci_database_autonomous_database_wallet" "autonomous_database_wallet" {
  autonomous_database_id = oci_database_autonomous_database.autonomous_database.id
  password               = random_string.autonomous_database_wallet_password.result
  base64_encode_content  = "true"
}