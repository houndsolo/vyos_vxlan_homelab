locals {
  derived_node_defaults = {
    for node_id in distinct(concat(
      [for node in values(var.fabric.spines) : node.id],
      [for node in values(var.fabric.leaves) : node.id],
      [for node in values(var.fabric.leaves_greatfox) : node.id],
      [for node in values(var.fabric.border_leaves) : node.id],
      [for node in values(var.fabric.fabric_ext_leaves) : node.id],
    )) :
    tostring(node_id) => {
      l2_svd                 = var.fabric.defaults.l2_service_bridge_id
      underlay_local_as      = var.fabric.defaults.underlay_local_as_base + node_id
      vxlan_loopback_net     = cidrhost(var.fabric.defaults.ipv4_loopback_prefix, node_id)
      vxlan_loopback         = "${cidrhost(var.fabric.defaults.ipv4_loopback_prefix, node_id)}/32"
      vxlan_loopback_v6_net  = cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node_id), 16))
      vxlan_loopback_v6      = "${cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(node_id), 16))}/128"
      bgp_system_as          = var.fabric.defaults.bgp_system_as
      vxlan_source_interface = var.fabric.defaults.vxlan_source_interface
    }
  }

  derived_fabric = {
    spines = {
      for node_name, node in var.fabric.spines :
      node_name => merge(node, local.derived_node_defaults[tostring(node.id)])
    }

    leaves = {
      for node_name, node in var.fabric.leaves :
      node_name => merge(node, local.derived_node_defaults[tostring(node.id)], {
        hostname = "LEAF-${node.id}"
      })
    }

    leaves_greatfox = {
      for node_name, node in var.fabric.leaves_greatfox :
      node_name => merge(node, local.derived_node_defaults[tostring(node.id)], {
        hostname = "LEAF-${node.id}"
      })
    }

    border_leaves = {
      for node_name, node in var.fabric.border_leaves :
      node_name => merge(node, local.derived_node_defaults[tostring(node.id)], {
        hostname           = "BORDER-LEAF-${node.id}"
        border_leaf_id_1_2 = node.id - 17
      })
    }

    fabric_leaves = {
      for node_name, node in var.fabric.fabric_ext_leaves :
      node_name => merge(node, local.derived_node_defaults[tostring(node.id)], {
        hostname = "FABRIC-LEAF-${node.id}"
      })
    }
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

variable "fabric" {
}

variable "dns" {
  description = "DNS configuration"
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })
}

variable "vnis" {
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
