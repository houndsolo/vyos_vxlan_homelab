locals {
  dhcp_listen_interfaces = [
    for vlan_id, scope in var.dhcp_scopes : "eth1.${vlan_id}"
  ]
}

variable "node" {
}

variable "dns" {
}

variable "dhcp_scopes" {
}
