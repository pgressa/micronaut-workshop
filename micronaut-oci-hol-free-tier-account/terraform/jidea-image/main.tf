terraform {
  required_version = ">= 0.13.0"
}

resource "oci_identity_compartment" "this" {
  compartment_id = var.tenancy_ocid
  description = "Micronaut HOL Compartment"
  name = var.compartment_name
}

resource "oci_core_vcn" "this" {
  dns_label      = var.vcn_dns_label
  cidr_block     = var.vcn_cidr
  compartment_id = oci_identity_compartment.this.id
  display_name   = "${var.vnic_name}-${random_string.suffix.result}"
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

resource "oci_core_security_list" "java_ports" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.vnic_name}-java-ports"
  ingress_security_rules {
    protocol = "6"
    source = "0.0.0.0/0"
    description = "Allow port 8080 - 8887"
    stateless = "false"
    tcp_options {
      max = "8887"
      min = "8080"
    }
  }
}

resource "oci_core_security_list" "https_access" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id = oci_core_vcn.this.id
  display_name = "${var.vnic_name}-https"
  ingress_security_rules {
    protocol = "6"
    source = "0.0.0.0/0"
    description = "Allow Https"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
}

resource "oci_core_subnet" "subnet" {
  availability_domain = local.availability_domain
  cidr_block          = cidrsubnet(var.vcn_cidr, ceil(log(length(data.oci_identity_availability_domains.this.availability_domains) * 2, 2)), 0)
  display_name        = "MN-OCI Demo Public Subnet"
  dns_label           = "${var.subnet_dns_label}1"
  compartment_id      = oci_identity_compartment.this.id
  vcn_id              = oci_core_vcn.this.id
  security_list_ids   = [
      oci_core_vcn.this.default_security_list_id,
      oci_core_security_list.java_ports.id,
      oci_core_security_list.https_access.id
  ]
}

data "oci_core_subnet" "this" {
  subnet_id = oci_core_subnet.subnet.id // the last AD should have the "always free" shapes...
}

resource "oci_core_image" "projector_image" {
  #Required
  compartment_id = var.tenancy_ocid

  #Optional
  display_name = "Micronaut Intelli JIdea Projector - ${random_string.suffix.result}"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri = var.projector_image_source_uri

    #Optional
    operating_system = "Oracle Linux"
    operating_system_version = "7.9"
  }

  timeouts {
    create = "20m"
    delete = "10m"
  }
}


data "oci_limits_services" "services" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = ["compute"]
  }
}

data "oci_limits_limit_values" "ad_limits" {
  count          = length(data.oci_identity_availability_domains.this.availability_domains)
  compartment_id = var.tenancy_ocid
  service_name   = data.oci_limits_services.services.services.0.name
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[count.index].name
  name                = var.shape_limit
  scope_type          = "AD"
}

data "oci_limits_resource_availability" "ad_limits_availability" {
  #Required
  compartment_id = var.tenancy_ocid
  limit_name = var.shape_limit
  service_name   = data.oci_limits_services.services.services.0.name
  count          = length(data.oci_identity_availability_domains.this.availability_domains)

  #Optional
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[count.index].name
}

locals {
  availability_domains = [for limit in data.oci_limits_resource_availability.ad_limits_availability : limit.availability_domain if limit.available >= 2]
  availability_domain = local.availability_domains != null ? local.availability_domains[0] : data.oci_identity_availability_domains.this.availability_domains[0].name
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
    user_data           = base64encode(templatefile("user_data.tpl", {
      db_id = oci_database_autonomous_database.autonomous_database.id
      db_name = "${oci_database_autonomous_database.autonomous_database.db_name}_high"
      user_password = random_string.autonomous_database_schema_password.result
      admin_password = random_string.autonomous_database_admin_password.result
      wallet_password = random_string.autonomous_database_wallet_password.result
    }))
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_type = "image"
    source_id   = oci_core_image.projector_image.id
  }
}

resource "oci_identity_dynamic_group" "instance_resource_principals_dynamic_group" {
  compartment_id = var.tenancy_ocid
  matching_rule = "ANY {instance.compartment.id = '${oci_identity_compartment.this.id}'}"
  name = "${var.dynamic_group_display_name}-${random_string.suffix.result}-group"
  description = "${var.dynamic_group_display_name}-group"
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
  name = "${var.dynamic_group_display_name}-${random_string.suffix.result}-policy"
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
  display_name                                   = "${var.autonomous_database_display_name}${random_string.suffix.result}"
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

resource "oci_database_autonomous_database_wallet" "autonomous_database_wallet" {
  autonomous_database_id = oci_database_autonomous_database.autonomous_database.id
  password               = random_string.autonomous_database_wallet_password.result
  base64_encode_content  = "true"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
}