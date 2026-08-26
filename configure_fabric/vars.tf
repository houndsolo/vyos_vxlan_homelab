locals {
  # Add the small set of values that are mechanically derived from each node ID.
  # All topology and service intent remains in the root variable files.
  fabric_leaves = {
    for node_name, node in var.fabric.fabric_ext_leaves :
    node_name => merge(node, {
      hostname               = "BORDER-LEAF-${node.id}"
      l2_svd                 = var.fabric.defaults.l2_service_bridge_id
      underlay_local_as      = var.fabric.defaults.underlay_local_as_base + node.id
      fabric_loopback_v4_net = cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)
      fabric_loopback_v4     = "${cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)}/32"
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
      fabric_loopback_v6     = "${cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))}/128"
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
      fabric_loopback_v4_net = cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)
      fabric_loopback_v4     = "${cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)}/32"
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
      fabric_loopback_v6     = "${cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))}/128"
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
      fabric_loopback_v4_net = cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)
      fabric_loopback_v4     = "${cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)}/32"
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
      fabric_loopback_v6     = "${cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))}/128"
      bgp_system_as          = var.fabric.defaults.bgp_system_as
      vxlan_source_interface = var.fabric.defaults.vxlan_source_interface
      fabric_macs            = node.fabric_macs
    })
  }
  pve_leaves = {
    for node_name, node in var.fabric.leaves :
    node_name => merge(node, {
      hostname               = "LEAF-${node.id}"
      l2_svd                 = var.fabric.defaults.l2_service_bridge_id
      underlay_local_as      = var.fabric.defaults.underlay_local_as_base + node.id
      fabric_loopback_v4_net = cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)
      fabric_loopback_v4     = "${cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)}/32"
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
      fabric_loopback_v6     = "${cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))}/128"
      bgp_system_as          = var.fabric.defaults.bgp_system_as
      vxlan_source_interface = var.fabric.defaults.vxlan_source_interface
      fabric_macs            = node.fabric_macs
    })
  }

  spines = {
    for node_name, node in var.fabric.spines :
    node_name => merge(node, {
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
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


variable "external_l3" {}
variable "external_l2" {}
variable "vnis" {}
variable "fabric" {}

variable "dns" {}
variable "vyos_key" {}
