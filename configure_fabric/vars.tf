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
  greatfox_leaves = {
    for node_name, node in var.fabric.leaves_greatfox :
    node_name => merge(node, {
      hostname               = "LEAF-${node.id}"
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
  pve_leaves = {
    for node_name, node in var.fabric.leaves :
    node_name => merge(node, {
      hostname               = "LEAF-${node.id}"
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
