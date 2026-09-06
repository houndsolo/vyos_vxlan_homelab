locals {
  # Normalize address and ASN derivation once, then retain small role-specific views.
  leaves = {
    for node_name, node in var.fabric.nodes.leaves : node_name => merge(node, {
      hostname               = node.role == "pve" ? "LEAF-${node.id}" : "BORDER-LEAF-${node.id}"
      l2_svd                 = var.fabric.defaults.l2_service_bridge_id
      underlay_local_as      = var.fabric.defaults.underlay_local_as_base + node.id
      fabric_loopback_v4_net = cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)
      fabric_loopback_v4     = "${cidrhost(var.fabric.defaults.ipv4_fabric_loopback_prefix, node.id)}/32"
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
      fabric_loopback_v6     = "${cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))}/128"
      bgp_system_as          = var.fabric.defaults.bgp_system_as
      vxlan_source_interface = var.fabric.defaults.vxlan_source_interface
      border_leaf_id_1_2     = node.role == "external_l3" ? node.id - 17 : null
    })
  }
  leaves_by_role = {
    for role in ["pve", "external_l2", "external_l3"] : role => {
      for name, node in local.leaves : name => node if node.role == role
    }
  }
  vnis_by_role = {
    for role in ["pve", "external_l2", "external_l3"] : role => {
      l3 = { for key, l3 in var.vnis.l3 : key => l3 if contains(l3.roles, role) }
    }
  }
  l2_vnis_by_role = {
    for role, selected in local.vnis_by_role : role => merge([
      for l3_key, l3 in selected.l3 : {
        for l2_key, l2 in l3.l2 : tostring(l2.vni) => merge(l2, {
          l3_key = l3_key, l2_key = l2_key, l3_vni = l3.vni
          vrf    = l3.vrf, vrf_table = l3.vrf_table
          bridge = "br${var.fabric.defaults.l2_service_bridge_id}", bridge_vif = l2.vlan_id
        })
      }
    ]...)
  }
  spines = {
    for name, node in var.fabric.nodes.spines : name => merge(node, {
      fabric_loopback_v6_net = cidrhost(var.fabric.defaults.ipv6_fabric_loopback_prefix, parseint(tostring(node.id), 16))
    })
  }
}

variable "external_l3" {}
variable "external_l2" {}
variable "vnis" {}
variable "fabric" {}
variable "dns" {}
variable "vyos_key" {}
