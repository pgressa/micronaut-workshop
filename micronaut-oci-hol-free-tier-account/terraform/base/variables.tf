variable "ssh_public_key" {}
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

variable "use_free_tier" {
  default = true
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
variable "shape" {
  default = "VM.Standard.E2.1.Micro"
}
variable "assign_public_ip" {
  default = "true"
}
variable "vnic_name" {
  default = "vnic"
}

variable "user_data" {
  default = "IyEvYmluL3NoCiMgdGhpcyBzY3JpcHQgaXMgdXNlZCB0byBnZW5lcmF0ZSB0aGUgInVzZXJfZGF0YSIgaW4gYHNldHVwLnNoYAojIGJhc2U2NCBlbmNvZGUgdGhpcyBmaWxlIGFuZCBzZXQgaXQgaW4gdGVycmFmb3JtL3ZhcmlhYmxlcy50ZiwgYW5kIHdoYXRldmVyIGlzIGluIHRoaXMgc2NyaXB0IHdpbGwgYmUgcnVuIGF0IHN0YXJ0dXAgb2YgdGhlIFZNCmVjaG8gIioqKm1ha2luZyAvamF2YSBkaXJlY3RvcnkqKioiCm1rZGlyIC1wIC9qYXZhCmVjaG8gIioqKmRvd25sb2FkaW5nIGdyYWFsdm0qKioiCndnZXQgLXEgLU8gL2phdmEvZ3JhYWx2bS1jZS1qYXZhMTEtbGludXgtYW1kNjQtMjAuMS4wLnRhci5neiBodHRwczovL2dpdGh1Yi5jb20vZ3JhYWx2bS9ncmFhbHZtLWNlLWJ1aWxkcy9yZWxlYXNlcy9kb3dubG9hZC92bS0yMC4xLjAvZ3JhYWx2bS1jZS1qYXZhMTEtbGludXgtYW1kNjQtMjAuMS4wLnRhci5negplY2hvICIqKip1bnppcHBpbmcgZ3JhYWx2bSoqKiIKdGFyIC14ZiAvamF2YS9ncmFhbHZtLWNlLWphdmExMS1saW51eC1hbWQ2NC0yMC4xLjAudGFyLmd6IC1DIC9qYXZhLwplY2hvICIqKipyZW1vdmluZyB6aXAqKioiCnJtIC9qYXZhL2dyYWFsdm0tY2UtamF2YTExLWxpbnV4LWFtZDY0LTIwLjEuMC50YXIuZ3oKZWNobyAiKioqc2V0dGluZyBKQVZBX0hPTUUqKioiCmVjaG8gImV4cG9ydCBKQVZBX0hPTUU9L2phdmEvZ3JhYWx2bS1jZS1qYXZhMTEtMjAuMS4wIiA+PiAvZXRjL3Byb2ZpbGUuZC9qYXZhLnNoCmVjaG8gIioqKnNldHRpbmcgUEFUSCoqKiIKZWNobyAiZXhwb3J0IFBBVEg9XCRKQVZBX0hPTUUvYmluOlwkUEFUSCIgPj4gL2V0Yy9wcm9maWxlLmQvamF2YS5zaAplY2hvICIqKipzZXR0aW5nIGZpcmV3YWxsIHJ1bGVzKioqIgpzdWRvIGZpcmV3YWxsLW9mZmxpbmUtY21kIC0tem9uZT1wdWJsaWMgLS1hZGQtcG9ydD04MDgwL3RjcApzdWRvIHN5c3RlbWN0bCByZXN0YXJ0IGZpcmV3YWxsZAplY2hvICIqKipzZXR0aW5nIG1vdGQqKioiCnN1ZG8gc2ggLWMgJ2VjaG8gIldlbGNvbWUgTWljcm9uYXV0IEhhbmRzIE9uIExhYiBBdHRlbmRlZSEiID4gL2V0Yy9tb3RkJwplY2hvICJzZXR1cCBkb25lISI="
}

variable "vcn_display_name" {
  default = "testVCN"
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
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}
