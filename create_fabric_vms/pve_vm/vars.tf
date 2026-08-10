variable "host_node" {
  description = "VyOS VM identity and ordered Proxmox network layout."
  type = object({
    hostname           = string
    hypervisor_node    = string
    id                 = number
    vm_id              = optional(number)
    management_address = optional(string)
    started            = optional(bool, false)
    tags               = optional(list(string))
    network_devices = list(object({
      bridge  = string
      vlan_id = optional(number)
    }))
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
  description = "Shared Proxmox settings for this VyOS VM."
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
