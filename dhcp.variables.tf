variable "dhcp" {
  description = "DHCP cluster defaults, HA attachment, and node inventory."
  type = object({
    defaults = object({
      client_name_servers = list(string)
      lease_seconds       = number
      authoritative       = bool
    })
    ha = object({
      mode  = string
      l2vni = number
    })
    nodes = map(object({
      id              = number
      hypervisor_node = string
      vm_id           = number
      ha_role         = string
      configure       = optional(bool, true)
      started         = optional(bool, false)
    }))
  })

  validation {
    condition     = length(var.dhcp.nodes) == 2
    error_message = "DHCP HA requires exactly two nodes."
  }
  validation {
    condition = (
      length([for node in values(var.dhcp.nodes) : node if node.ha_role == "primary"]) == 1 &&
      length([for node in values(var.dhcp.nodes) : node if node.ha_role == "secondary"]) == 1
    )
    error_message = "DHCP HA requires exactly one primary and one secondary node."
  }
  validation {
    condition     = length(distinct([for node in values(var.dhcp.nodes) : node.id])) == length(var.dhcp.nodes)
    error_message = "DHCP node IDs must be unique."
  }
  validation {
    condition     = length(distinct([for node in values(var.dhcp.nodes) : node.vm_id])) == length(var.dhcp.nodes)
    error_message = "DHCP VM IDs must be unique."
  }
  validation {
    condition = alltrue([
      for name, node in var.dhcp.nodes :
      trimspace(name) != "" && trimspace(node.hypervisor_node) != "" &&
      !contains(["fichina", "fortuna", "eldarad"], node.hypervisor_node) &&
      node.id > 0 && node.id < 255 && node.id == floor(node.id) && node.vm_id > 0
    ])
    error_message = "DHCP node names/hosts must be valid, retired hosts are forbidden, and IDs must be usable final-octet host numbers."
  }
  validation {
    condition = (
      trimspace(var.dhcp.ha.mode) != "" &&
      var.dhcp.ha.l2vni >= 1 && var.dhcp.ha.l2vni <= 16777215 &&
      var.dhcp.defaults.lease_seconds > 0 &&
      length(var.dhcp.defaults.client_name_servers) > 0
    )
    error_message = "DHCP mode, HA VNI, lease, and client DNS defaults must be valid."
  }
}
