
resource "vyos_policy_prefix_list" "create_prefix_list" {
  for_each = var.ipv4_vpn_export_policy

  identifier = {
    prefix_list = each.value.prefix_list_name
  }
}

resource "vyos_policy_prefix_list_rule" "ipv4_vpn_export_prefix_rules" {
  depends_on = [resource.vyos_policy_prefix_list.create_prefix_list]

  for_each = merge([
    for l3_key, l3 in var.vnis.l3 : {
      for l2_key, l2 in l3.l2 :
      "${l3_key}-${l2_key}" => {
        l3_key = l3_key
        prefix = cidrsubnet("${l2.anycast_gw_ip}/${l2.anycast_gw_cidr}", 0, 0)
        rule   = tonumber(l2.vlan_id) * 10
      }
      if try(l2.export_ipv4_unicast, false)
    }
  ]...)

  identifier = {
    prefix_list = var.ipv4_vpn_export_policy[each.value.l3_key].prefix_list_name
  rule = each.value.rule }

  action = "permit"
  prefix = each.value.prefix
}

resource "vyos_policy_route_map" "evpn_advertise" {
  for_each = var.evpn_ipv4_advertisement_policy

  identifier = {
    route_map = each.value.route_map_name
  }
}

resource "vyos_policy_route_map_rule" "evpn_advertise_deny_native" {
  depends_on = [
    vyos_policy_prefix_list_rule.ipv4_vpn_export_prefix_rules,
    vyos_policy_route_map.evpn_advertise,
  ]
  for_each = var.evpn_ipv4_advertisement_policy

  identifier = {
    route_map = each.value.route_map_name
    rule      = 10
  }

  action = "deny"
  match = {
    ip = {
      address = {
        prefix_list = each.value.prefix_list_name
      }
    }
  }
}

resource "vyos_policy_route_map_rule" "evpn_advertise_permit_other" {
  depends_on = [vyos_policy_route_map.evpn_advertise]
  for_each   = var.evpn_ipv4_advertisement_policy

  identifier = {
    route_map = each.value.route_map_name
    rule      = 100
  }

  action = "permit"
}

resource "vyos_policy_as_path_list" "advertise_ext_l3" {
  identifier = {
    as_path_list = "advertise_ext_l3_AS"
  }
}

resource "vyos_policy_as_path_list_rule" "advertise_ext_l3_rule_10" {
  depends_on = [resource.vyos_policy_as_path_list.advertise_ext_l3]

  identifier = {
    as_path_list = "advertise_ext_l3_AS"
    rule         = 10
  }

  action = "permit"
  regex  = "^420$"
}
resource "vyos_policy_route_map" "create_route_map" {
  for_each = var.ipv4_vpn_export_policy

  identifier = {
    route_map = each.value.route_map_name
  }
}

resource "vyos_policy_route_map_rule" "ipv4_vpn_export_permit" {
  depends_on = [resource.vyos_policy_route_map.create_route_map]
  for_each   = var.ipv4_vpn_export_policy

  identifier = {
    route_map = each.value.route_map_name
    rule      = 10
  }

  action = "permit"

  match = {
    ip = {
      address = {
        prefix_list = each.value.prefix_list_name
      }
    }
  }
}

#resource "vyos_policy_route_map_rule" "ipv4_vpn_export_permit_service_export" {
#  depends_on = [resource.vyos_policy_route_map.create_route_map]
#
#  identifier = {
#    route_map = "RM-LYLAT-SERVICE-IPV4-VPN-EXPORT"
#    rule      = 11
#  }
#
#  action = "permit"
#  match = {
#    as_path = "advertise_ext_l3_AS"
#  }
#}

resource "vyos_policy_route_map_rule" "ipv4_vpn_export_deny" {
  for_each = var.ipv4_vpn_export_policy

  identifier = {
    route_map = each.value.route_map_name
    rule      = 100
  }

  action = "deny"
}

resource "vyos_policy_prefix_list" "ipv4_vpn_import" {
  for_each = var.ipv4_vpn_import_policy

  identifier = {
    prefix_list = each.value.prefix_list_name
  }
}

resource "vyos_policy_prefix_list_rule" "ipv4_vpn_import_permit" {
  depends_on = [vyos_policy_prefix_list.ipv4_vpn_import]
  for_each   = var.ipv4_vpn_import_policy

  identifier = {
    prefix_list = each.value.prefix_list_name
    rule        = 10
  }

  action = "permit"
  prefix = "0.0.0.0/0"
  le     = 32
}

resource "vyos_policy_route_map" "ipv4_vpn_import" {
  for_each = var.ipv4_vpn_import_policy

  identifier = {
    route_map = each.value.route_map_name
  }
}

resource "vyos_policy_route_map_rule" "ipv4_vpn_import_permit" {
  depends_on = [
    vyos_policy_prefix_list_rule.ipv4_vpn_import_permit,
    vyos_policy_route_map.ipv4_vpn_import,
  ]
  for_each = var.ipv4_vpn_import_policy

  identifier = {
    route_map = each.value.route_map_name
    rule      = 10
  }

  action = "permit"
  match = {
    ip = {
      address = {
        prefix_list = each.value.prefix_list_name
      }
    }
  }
  set = {
    extcommunity = {
      none = true
    }
  }
}

resource "vyos_policy_route_map_rule" "ipv4_vpn_import_deny" {
  depends_on = [vyos_policy_route_map.ipv4_vpn_import]
  for_each   = var.ipv4_vpn_import_policy

  identifier = {
    route_map = each.value.route_map_name
    rule      = 100
  }

  action = "deny"
}

resource "vyos_vrf_name" "create_vrfs" {
  depends_on = [
    module.leaf_common,
    vyos_policy_route_map_rule.evpn_advertise_deny_native,
    vyos_policy_route_map_rule.evpn_advertise_permit_other,
    vyos_policy_route_map_rule.ipv4_vpn_import_permit,
    vyos_policy_route_map_rule.ipv4_vpn_import_deny,
    #vyos_interfaces_ethernet_vif.set_eth3_vif_mtu
  ]
  for_each = var.vnis.l3

  identifier = { name = each.value.vrf }

  table = each.value.vrf_table
  vni   = each.value.vni

  protocols = {
    bgp = {
      system_as = var.node.bgp_system_as

      parameters = {
        router_id = var.node.vxlan_loopback_net

        bestpath = {
          as_path = { multipath_relax = true }
        }
      }

      address_family = {
        ipv4_unicast = merge(
          {
            export = {
              vpn = each.value.border_leaf_ipv4_vpn_import_bool
            }
            import = {
              vpn = each.value.border_leaf_ipv4_vpn_import_bool
              vrf = each.value.border_leaf_ipv4_vrf_imports
            }
            #label  = { vpn = { export = "auto" } }

            rd = each.value.border_leaf_ipv4_vpn_import_bool ? {
              vpn = {
                export = "${var.node.vxlan_loopback_net}:${each.value.vni}"
              }
            } : null

            route_target = {
              vpn = {
                import = each.value.border_leaf_ipv4_rt_imports
                export = each.value.border_leaf_ipv4_rt_exports
              }
            }

            soft_reconfiguration = { inbound = true }
          },
          each.value.redistribute_ipv4 != null ? {
            redistribute = each.value.redistribute_ipv4
          } : {},
          contains(keys(var.ipv4_vpn_export_policy), each.key) || contains(keys(var.ipv4_vpn_import_policy), each.key) ? {
            route_map = {
              vpn = merge(
                contains(keys(var.ipv4_vpn_export_policy), each.key) ? {
                  export = var.ipv4_vpn_export_policy[each.key].route_map_name
                } : {},
                contains(keys(var.ipv4_vpn_import_policy), each.key) ? {
                  import = var.ipv4_vpn_import_policy[each.key].route_map_name
                } : {}
              )
            }
          } : {}
        )

        l2vpn_evpn = merge(
          {
            rd = "${var.node.vxlan_loopback_net}:${each.value.vni}"

            route_target = {
              import = each.value.evpn_rt_imports
              export = each.value.evpn_rt_exports
            }
          },
          each.value.export_vpn_ipv4 ? {
            advertise = {
              ipv4 = {
                unicast = {
                  route_map = contains(keys(var.evpn_ipv4_advertisement_policy), each.key) ? (
                    var.evpn_ipv4_advertisement_policy[each.key].route_map_name
                  ) : "block_local_as_rm"
                }
              }
            }
          } : {}
        )
      }
    }
  }
}
