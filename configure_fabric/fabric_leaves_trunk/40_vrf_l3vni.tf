resource "vyos_vrf_name" "create_vrfs" {
  depends_on = [
    module.leaf_common,
    vyos_policy_route_map_rule.bgp_to_local_vpn_permit,
  ]
  for_each = var.vnis.l3

  identifier = { name = each.value.vrf }

  table = each.value.vrf_table
  vni   = each.value.vni

  protocols = {
    bgp = {
      system_as = var.node.bgp_system_as

      parameters = {
        router_id = var.node.fabric_loopback_v4_net

        bestpath = {
          as_path = { multipath_relax = true }
        }
      }

      address_family = {
        ipv4_unicast = merge(
          {
            soft_reconfiguration = { inbound = true }
          },
          {
            export = { vpn = true }
            import = { vpn = true }
            rd = {
              vpn = {
                export = "${var.node.fabric_loopback_v4_net}:${each.value.vni}"
              }
            }
            route_target = {
              vpn = {
                import = each.value.ipv4_rt_imports
                export = each.value.ipv4_rt_exports
              }
            }
            route_map = {
              vpn = {
                export = var.l2vni_subnet_policies[each.key].vpn_export_route_map
              }
            }
          },
          contains(keys(var.l2vni_subnet_policies), each.key) ? {
            redistribute = merge(
              each.value.redistribute_ipv4 != null ? each.value.redistribute_ipv4 : {},
              { connected = { route_map = var.l2vni_subnet_policies[each.key].connected_route_map } }
            )
            } : (each.value.redistribute_ipv4 != null ? {
              redistribute = each.value.redistribute_ipv4
          } : {}),
        )

        l2vpn_evpn = merge(
          {
            rd = "${var.node.fabric_loopback_v4_net}:${each.value.vni}"

            route_target = {
              import = each.value.evpn_rt_imports
              export = each.value.evpn_rt_exports
            }
          },
          each.value.export_vpn_ipv4 ? {
            advertise = {
              ipv4 = {
                unicast = {
                  route_map = contains(keys(var.evpn_ipv4_advertisement_policies), each.key) ? var.evpn_ipv4_advertisement_policies[each.key].route_map : "block_local_as_rm"
                }
              }
            }
          } : {}
        )
      }
    }
  }
}

resource "vyos_policy_route_map" "evpn_advertise" {
  for_each = var.evpn_ipv4_advertisement_policies

  identifier = {
    route_map = each.value.route_map
  }
}

resource "vyos_policy_route_map_rule" "evpn_advertise_deny_native" {
  depends_on = [
    vyos_policy_route_map.evpn_advertise,
  ]
  for_each = var.evpn_ipv4_advertisement_policies

  identifier = {
    route_map = each.value.route_map
    rule      = 10
  }

  # This stage intentionally admits native subnets into the local EVPN RIB.
  action = "permit"
}

resource "vyos_policy_route_map" "create_route_map" {
  for_each = var.l2vni_subnet_policies

  identifier = {
    route_map = each.value.connected_route_map
  }
}

resource "vyos_policy_route_map_rule" "connected_to_bgp_permit" {
  depends_on = [module.leaf_common, resource.vyos_policy_route_map.create_route_map]
  for_each   = var.l2vni_subnet_policies

  identifier = {
    route_map = each.value.connected_route_map
    rule      = 10
  }

  action = "permit"

  match = {
    ip = {
      address = {
        prefix_list = each.value.prefix_list
      }
    }
  }
}

resource "vyos_policy_route_map_rule" "connected_to_bgp_deny_other" {
  for_each = var.l2vni_subnet_policies

  identifier = {
    route_map = each.value.connected_route_map
    rule      = 100
  }

  action = "deny"
}

resource "vyos_policy_route_map" "bgp_to_local_vpn" {
  for_each = var.l2vni_subnet_policies

  identifier = {
    route_map = each.value.vpn_export_route_map
  }
}

resource "vyos_policy_route_map_rule" "bgp_to_local_vpn_permit" {
  depends_on = [module.leaf_common, vyos_policy_route_map.bgp_to_local_vpn]
  for_each   = var.l2vni_subnet_policies

  identifier = {
    route_map = each.value.vpn_export_route_map
    rule      = 10
  }

  action = "permit"
  match = {
    ip = {
      address = {
        prefix_list = each.value.prefix_list
      }
    }
  }
}
