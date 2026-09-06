locals {
  l2vni_subnet_policies_by_role = {
    for role, selected in local.vnis_by_role : role => {
      for l3_key, l3 in selected.l3 : l3_key => {
        prefix_list          = "PL-${upper(replace(l3.vrf, "_", "-"))}-L2VNI-SUBNETS"
        connected_route_map  = "RM-${upper(replace(l3.vrf, "_", "-"))}-CONNECTED-TO-BGP"
        vpn_export_route_map = "RM-${upper(replace(l3.vrf, "_", "-"))}-BGP-TO-LOCAL-VPN"
      } if anytrue([for l2 in values(l3.l2) : l2.export_ipv4_unicast])
    }
  }
  evpn_ipv4_advertisement_policies_by_role = {
    for role, selected in local.vnis_by_role : role => {
      for l3_key, l3 in selected.l3 : l3_key => {
        route_map = "RM-${upper(replace(l3.vrf, "_", "-"))}-BGP-TO-EVPN"
      } if l3.export_vpn_ipv4 && l3.border_leaf_ipv4_vpn_import_bool && contains(keys(local.l2vni_subnet_policies_by_role[role]), l3_key)
    }
  }
}
