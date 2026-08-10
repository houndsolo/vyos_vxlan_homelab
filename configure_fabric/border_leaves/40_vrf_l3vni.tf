resource "vyos_vrf_name" "create_vrfs" {
  depends_on = [module.leaf_common]
  for_each   = var.vnis.external_l3

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
            soft_reconfiguration = { inbound = true }
          },
          try(each.value.redistribute_ipv4, null) != null ? {
            redistribute = each.value.redistribute_ipv4
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
                  route_map = "block_local_as_rm"
                }
              }
            }
          } : {}
        )
      }
    }
  }
}
