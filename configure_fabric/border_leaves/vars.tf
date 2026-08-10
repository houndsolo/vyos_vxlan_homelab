variable "dns" {
  description = "DNS configuration for the node."
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })
}

variable "node" {
  description = "Leaf node inventory plus fabric-derived settings from configure_fabric."
  type = object({
    id                     = number
    hypervisor_node        = optional(string, null)
    is_vm                  = optional(bool, true)
    underlay_bridges       = optional(list(string), null)
    underlay_peer_vlan     = optional(number, null)
    hostname               = string
    l2_svd                 = number
    underlay_local_as      = number
    vxlan_loopback         = string
    vxlan_loopback_net     = string
    vxlan_loopback_v6      = string
    vxlan_loopback_v6_net  = string
    bgp_system_as          = number
    vxlan_source_interface = string
    border_leaf_id_1_2     = optional(number, null)
  })
}

variable "spines" {
  description = "Spine inventory with overlay peering addresses derived by configure_fabric."
  type = map(object({
    id                    = number
    uplink_if             = string
    vxlan_loopback_v6_net = string
    hypervisor_node       = optional(string, null)
  }))
}

variable "vxlan" {
  type = object({
    mtu                       = number
    outer_mtu                 = number
    disable_forwarding        = bool
    disable_arp_filter        = bool
    enable_arp_accept         = bool
    enable_arp_announce       = bool
    enable_directed_broadcast = bool
    enable_proxy_arp          = bool
    proxy_arp_pvlan           = bool
    external                  = bool
    neighbor_suppress         = bool
    nolearning                = bool
    vni_filter                = bool
  })
}

variable "bgp_l2vpn" {
  type = object({
    flooding_disable = bool
    her              = bool
    advertise_svi    = bool
    advertise_vni    = bool
    rt_auto_derive   = bool
  })
}

variable "vnis" {
}

variable "external_l3" {
  description = "Border-leaf external L3 connectivity settings."
  type = object({
    interface       = string
    peer_group_name = string
    remote_asn      = number
  })
}
