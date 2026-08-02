locals {
  # Add the small set of values that are mechanically derived from each node ID.
  # All topology and service intent remains in the root variable files.
  fabric_leaves = {
    for node_name, node in var.fabric.fabric_ext_leaves :
    node_name => merge(node, {
      hostname               = "BORDER-LEAF-${node.id}"
      l2_svd                 = var.fabric.defaults.l2_service_bridge_id
      underlay_local_as      = var.fabric.defaults.underlay_local_as_base + node.id
      vxlan_loopback_net     = cidrhost(var.fabric.defaults.ipv4_loopback_prefix, node.id)
      vxlan_loopback         = "${cidrhost(var.fabric.defaults.ipv4_loopback_prefix, node.id)}/32"
      vxlan_loopback_v6_net  = cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node.id), 16))
      vxlan_loopback_v6      = "${cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node.id), 16))}/128"
      bgp_system_as          = var.fabric.defaults.bgp_system_as
      vxlan_source_interface = var.fabric.defaults.vxlan_source_interface
    })
  }
  border_leaves = {
    for node_name, node in var.fabric.border_leaves :
    node_name => merge(node, {
      hostname               = "BORDER-LEAF-${node.id}"
      l2_svd                 = var.fabric.defaults.l2_service_bridge_id
      underlay_local_as      = var.fabric.defaults.underlay_local_as_base + node.id
      vxlan_loopback_net     = cidrhost(var.fabric.defaults.ipv4_loopback_prefix, node.id)
      vxlan_loopback         = "${cidrhost(var.fabric.defaults.ipv4_loopback_prefix, node.id)}/32"
      vxlan_loopback_v6_net  = cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node.id), 16))
      vxlan_loopback_v6      = "${cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node.id), 16))}/128"
      bgp_system_as          = var.fabric.defaults.bgp_system_as
      vxlan_source_interface = var.fabric.defaults.vxlan_source_interface
      border_leaf_id_1_2     = node.id - 17
    })
  }

  spines = {
    for node_name, node in var.fabric.spines :
    node_name => merge(node, {
      vxlan_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node.id), 16))
    })
  }

  l2_vnis = merge([
    for l3_key, l3 in var.vnis.l3 : {
      for l2_key, l2 in try(l3.l2, {}) :
      tostring(l2.vni) => merge(l2, {
        l3_key = l3_key
        l2_key = l2_key

        l3_vni = l3.vni

        vrf       = l3.vrf
        vrf_table = l3.vrf_table

        bridge     = "br${var.fabric.defaults.l2_service_bridge_id}"
        bridge_vif = l2.vlan_id
      })
    }
  ]...)

  ipv4_vpn_export_policy = {
    for l3_key, l3 in var.vnis.l3 :
    l3_key => {
      prefix_list_name = "PL-${upper(replace(l3.vrf, "_", "-"))}-IPV4-NATIVE"
      route_map_name   = "RM-${upper(replace(l3.vrf, "_", "-"))}-IPV4-VPN-EXPORT"
    }
    if anytrue([
      for l2_key, l2 in l3.l2 : try(l2.export_ipv4_unicast, false)
    ])
  }

  # The existing per-VRF RT import list selects which VPN routes are eligible.
  # This policy is attached only to that VPN import path, where it strips the
  # communities from every route that passed the RT import selection.
  ipv4_vpn_import_policy = {
    for destination_key, destination in var.vnis.l3 :
    destination_key => {
      prefix_list_name = "PL-${upper(replace(destination.vrf, "_", "-"))}-IPV4-VPN-IMPORT"
      route_map_name   = "RM-${upper(replace(destination.vrf, "_", "-"))}-IPV4-VPN-IMPORT"
    }
    if try(destination.border_leaf_ipv4_vpn_import_bool, false) &&
    destination.border_leaf_ipv4_rt_imports != null
  }

  evpn_ipv4_advertisement_policy = {
    for l3_key, l3 in var.vnis.l3 :
    l3_key => {
      prefix_list_name = local.ipv4_vpn_export_policy[l3_key].prefix_list_name
      route_map_name   = "RM-${upper(replace(l3.vrf, "_", "-"))}-EVPN-ADVERTISE"
    }
    if try(l3.export_vpn_ipv4, false) &&
    try(l3.border_leaf_ipv4_vpn_import_bool, false) &&
    contains(keys(local.ipv4_vpn_export_policy), l3_key)
  }
}


variable "dns" {
  description = "DNS configuration"
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })
}


variable "vyos_key" {
  type      = string
  sensitive = true
}

variable "external_l3" {
  description = "Border-leaf external L3 connectivity settings."
  type = object({
    interface       = string
    peer_group_name = string
    remote_asn      = number
  })
}
variable "external_l2" {}
variable "vnis" {}
variable "fabric" {}
