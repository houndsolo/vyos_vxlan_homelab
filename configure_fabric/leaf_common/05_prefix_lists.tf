# This creates a route map/ AS Path filter to only export originated routes into the BGP Underlay
# aka path length of 0, nothing that was imported
resource "vyos_policy_as_path_list" "create_as_path_list" {
  identifier = {
    as_path_list = "local_as_export"
  }
}

resource "vyos_policy_as_path_list_rule" "as_path_local_rule" {
  depends_on = [resource.vyos_policy_as_path_list.create_as_path_list]

  identifier = {
    as_path_list = "local_as_export"
    rule         = 10
  }

  action = "permit"
  regex  = "^$"
}

resource "vyos_policy_route_map" "create_route_map_local_as" {
  depends_on = [
    resource.vyos_policy_as_path_list_rule.as_path_local_rule,
  ]
  identifier = {
    route_map = "local_as_rm"
  }
}

resource "vyos_policy_route_map_rule" "local_as_rm_rule" {
  depends_on = [vyos_policy_route_map.create_route_map_local_as]

  identifier = {
    route_map = "local_as_rm"
    rule      = 10
  }

  action = "permit"

  match = {
    as_path = "local_as_export"
  }
}

resource "vyos_policy_route_map_rule" "local_as_rm_rule_deny" {
  depends_on = [vyos_policy_route_map.create_route_map_local_as]

  identifier = {
    route_map = "local_as_rm"
    rule      = 100
  }

  action = "deny"

}


# These per-VRF lists are also consumed by connected redistribution and local
# VPN export. Reusing the caller's policy map avoids maintaining an aggregate
# copy solely for the EVPN neighbor policy.
resource "vyos_policy_prefix_list" "l2vni_subnets" {
  for_each   = var.l2vni_subnet_policies
  identifier = { prefix_list = each.value.prefix_list }
}

resource "vyos_policy_prefix_list_rule" "l2vni_subnet_rules" {
  for_each   = { for key, l2 in var.l2_vnis : key => l2 if try(l2.export_ipv4_unicast, false) }
  depends_on = [vyos_policy_prefix_list.l2vni_subnets]
  identifier = {
    prefix_list = var.l2vni_subnet_policies[each.value.l3_key].prefix_list
    rule        = tonumber(each.value.vlan_id) * 10
  }
  action = "permit"
  prefix = cidrsubnet("${each.value.anycast_gw_ip}/${each.value.anycast_gw_cidr}", 0, 0)
}

resource "vyos_policy_route_map" "evpn_spine_export" {
  count      = length(var.l2vni_subnet_policies) > 0 ? 1 : 0
  depends_on = [vyos_policy_prefix_list_rule.l2vni_subnet_rules]
  identifier = { route_map = "RM-EVPN-SPINE-EXPORT" }
}

resource "vyos_policy_route_map_rule" "evpn_spine_export_deny_l2vni_subnets" {
  for_each   = var.l2vni_subnet_policies
  depends_on = [vyos_policy_route_map.evpn_spine_export]
  identifier = {
    route_map = "RM-EVPN-SPINE-EXPORT"
    rule      = (index(sort(keys(var.l2vni_subnet_policies)), each.key) + 1) * 10
  }
  action = "deny"
  match = {
    evpn = { route_type = "prefix" }
    ip   = { address = { prefix_list = each.value.prefix_list } }
  }
}

resource "vyos_policy_route_map_rule" "evpn_spine_export_permit_other" {
  count      = length(var.l2vni_subnet_policies) > 0 ? 1 : 0
  depends_on = [vyos_policy_route_map.evpn_spine_export]
  identifier = { route_map = "RM-EVPN-SPINE-EXPORT", rule = 100 }
  action     = "permit"
}

resource "vyos_policy_as_path_list" "block_local_AS_evpn" {
  identifier = {
    as_path_list = "block_local_AS_evpn_PL"
  }
}

resource "vyos_policy_as_path_list_rule" "block_local_AS_evpn_rule" {
  depends_on = [resource.vyos_policy_as_path_list.block_local_AS_evpn]

  identifier = {
    as_path_list = "block_local_AS_evpn_PL"
    rule         = 10
  }

  action = "permit"
  regex  = "^$"
}

resource "vyos_policy_route_map" "route_map_block_local_evpn" {
  depends_on = [resource.vyos_policy_as_path_list_rule.block_local_AS_evpn_rule]
  identifier = {
    route_map = "block_local_as_rm"
  }
}

resource "vyos_policy_route_map_rule" "route_map_block_local_evpn_rule" {
  depends_on = [vyos_policy_route_map.route_map_block_local_evpn]

  identifier = {
    route_map = "block_local_as_rm"
    rule      = 10
  }

  action = "deny"

  match = {
    as_path = "block_local_AS_evpn_PL"
  }
}

resource "vyos_policy_route_map_rule" "route_map_block_local_evpn_rule_2" {
  depends_on = [vyos_policy_route_map.route_map_block_local_evpn]

  identifier = {
    route_map = "block_local_as_rm"
    rule      = 100
  }

  action = "permit"
}
