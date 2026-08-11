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

variable "l2_vnis" {
  description = "Flattened L2VNI map derived once by configure_fabric."
  type = map(object({
    vni                  = number
    vlan_id              = number
    anycast_gw_ip        = string
    anycast_gw_cidr      = number
    anycast_mac          = string
    advertise_default_gw = optional(bool, false)
    advertise_svi_ip     = optional(bool, false)
    export_ipv4_unicast  = optional(bool, false)
    l3_key               = string
    l2_key               = string
    l3_vni               = number
    vrf                  = string
    vrf_table            = number
    bridge               = string
    bridge_vif           = number
  }))
}

variable "l2vni_subnet_policy" {
  description = "Per-VRF native L2VNI subnet policy names derived once by configure_fabric."
  type = map(object({
    prefix_list_name          = string
    route_map_name            = string
    vpn_export_route_map_name = string
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
