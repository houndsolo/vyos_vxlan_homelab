locals {
  vxlan_mgmt_cidr    = var.fabric_defaults.vyos_mgmt_cidr
  management_address = coalesce(var.host_node.management_address, cidrhost(var.fabric_defaults.vyos_mgmt_prefix, var.host_node.id))
  vxlan_mgmt_ip_sub  = "${local.management_address}/${local.vxlan_mgmt_cidr}"
  vm_id              = coalesce(var.host_node.vm_id, var.host_node.id + 700)
  started            = coalesce(var.host_node.started, false)
  tags               = coalesce(var.host_node.tags, ["opentofu", "debian", "vyos", "vxlan"])
  network_bridges    = coalesce(var.host_node.network_bridges, var.host_node.underlay_bridges, var.vm_config.default_underlay_bridges)
}

variable "host_node" {
  description = "Role-independent VyOS VM identity and ordered network layout."
  type = object({
    hostname           = string
    hypervisor_node    = string
    id                 = number
    vm_id              = optional(number)
    management_address = optional(string)
    started            = optional(bool)
    tags               = optional(list(string))
    network_bridges    = optional(list(string))
    underlay_bridges   = optional(list(string))
  })
}

variable "fabric_defaults" {
  description = "Shared fabric-wide defaults used to derive VM management addressing."
  type = object({
    vyos_mgmt_prefix = string
    vyos_mgmt_cidr   = number
  })
}

variable "vm_config" {
  description = "Proxmox VM settings for this VyOS VTEP instance."
  type = object({
    datastore_id             = string
    import_image             = string
    cloud_init_datastore_id  = string
    user_data_file_id        = string
    management_bridge        = string
    default_underlay_bridges = list(string)
    cpu_cores                = number
    cpu_type                 = string
    memory_mb                = number
    disk_size_gb             = number
  })
}
