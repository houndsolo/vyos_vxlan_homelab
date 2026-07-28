variable "dhcp_nodes" {
  description = "All VyOS nodes"

  type = map(object({
    name              = string
    mgmt_addr         = string
    mgmt_subnet       = string
    node_id           = number
    hypervisor_node   = string
    hypervisor_vm_id  = number
    dhcp_ha_role   = string
    dhcp_ha_source = string
    dhcp_ha_remote = string
    dhcp_ha_peer_name = string
  }))

}

variable "dns" {
  description = "DNS configuration"
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })
}

variable "dhcp_scopes" {
  type = map(object({
    subnet         = string
    default_router = string
    name_server    = list(string)
    domain_name = string

    range = map(object({
      start = string
      stop  = string
    }))
  }))
}
