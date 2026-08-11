locals {
  # VRFs with at least one native subnet that should enter BGP.
  l2vni_subnet_policies = {
    for l3_key, l3 in var.vnis.l3 : l3_key => {
      prefix_list          = "PL-${upper(replace(l3.vrf, "_", "-"))}-L2VNI-SUBNETS"
      connected_route_map  = "RM-${upper(replace(l3.vrf, "_", "-"))}-CONNECTED-TO-BGP"
      vpn_export_route_map = "RM-${upper(replace(l3.vrf, "_", "-"))}-BGP-TO-LOCAL-VPN"
    }
    if anytrue([
      for l2 in values(try(l3.l2, {})) : try(l2.export_ipv4_unicast, false)
    ])
  }

  # Native subnets used to build the per-VRF prefix lists above.
  exported_l2vni_subnets = {
    for vni, l2 in local.l2_vnis : vni => l2
    if try(l2.export_ipv4_unicast, false)
  }

  # VRFs allowed to advertise imported IPv4 VPN routes into EVPN.
  evpn_ipv4_advertisement_policies = {
    for l3_key, l3 in var.vnis.l3 : l3_key => {
      route_map = "RM-${upper(replace(l3.vrf, "_", "-"))}-BGP-TO-EVPN"
    }
    if try(l3.export_vpn_ipv4, false)
    && try(l3.border_leaf_ipv4_vpn_import_bool, false)
    && contains(keys(local.l2vni_subnet_policies), l3_key)
  }
}
