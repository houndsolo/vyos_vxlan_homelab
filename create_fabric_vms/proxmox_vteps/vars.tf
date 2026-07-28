variable "host_node" {
  description = "Role-independent VyOS VM identity and ordered network layout."
  type = object({
    hostname           = string
    hypervisor_node    = string
    id                 = number
    vm_id              = optional(number)
    management_address = optional(string)
    started            = optional(bool, false)
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
