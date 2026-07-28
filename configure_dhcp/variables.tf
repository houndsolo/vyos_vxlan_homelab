variable "node_name" { type = string }
variable "node" {
  type = object({
    id                  = number
    hypervisor_node     = string
    vm_id               = number
    ha_role             = string
    service_host_offset = number
    configure           = optional(bool, true)
  })
}
variable "nodes" { type = map(any) }
variable "dhcp" { type = any }
variable "dns" {
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })
}
variable "attachments" {
  type = map(object({
    vni            = number
    interface      = string
    bridge         = string
    subnet         = string
    default_router = string
    scope          = any
  }))
}

locals {
  scopes    = { for vni, attachment in var.attachments : vni => attachment if attachment.scope != null }
  peer_name = one([for name in keys(var.nodes) : name if name != var.node_name])
  ha        = var.attachments[tostring(var.dhcp.ha.l2vni)]
  source    = cidrhost(local.ha.subnet, var.node.service_host_offset)
  remote    = cidrhost(local.ha.subnet, var.nodes[local.peer_name].service_host_offset)
}
