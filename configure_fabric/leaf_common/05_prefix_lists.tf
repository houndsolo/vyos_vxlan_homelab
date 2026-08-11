# This creates a route map/ AS Path filter to only export originated routes into the BGP Underlay
# aka path length of 0
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

resource "vyos_policy_as_path_list_rule" "as_path_local_rule_extl3" {
  depends_on = [resource.vyos_policy_as_path_list.create_as_path_list]

  identifier = {
    as_path_list = "local_as_export"
    rule         = 20
  }

  action = "permit"
  regex  = "^420$"
}

resource "vyos_policy_route_map" "create_route_map_local_as" {
  depends_on = [
    resource.vyos_policy_as_path_list_rule.as_path_local_rule,
    resource.vyos_policy_as_path_list_rule.as_path_local_rule_extl3
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


locals {
  evpn_local_svi_prefix_list_name = "PL-EVPN-LOCAL-SVI"

  evpn_local_svi_prefixes = sort(distinct(flatten([
    for l3_key, l3 in var.vnis.l3 : [
      for l2_key, l2 in try(l3.l2, {}) : [
        cidrsubnet("${split("/", l2.anycast_gw_ip)[0]}/${l2.anycast_gw_cidr}", 0, 0),
        "${split("/", l2.anycast_gw_ip)[0]}/32"
      ]
    ]
  ])))

  evpn_local_svi_prefix_rules = {
    for index, prefix in local.evpn_local_svi_prefixes :
    prefix => {
      prefix = prefix
      rule   = (index + 1) * 10
    }
  }
}

# Exact L2VNI subnet matches are safe in the EVPN neighbor policy: IPv4 prefix
# matching in the EVPN AF applies to Type-5 NLRI, while Type-2/3 NLRI have no
# IPv4-unicast prefix on which this list can match.
resource "vyos_policy_prefix_list" "evpn_local_l2vni_subnets" {
  count      = length(var.l2_vnis) > 0 ? 1 : 0
  identifier = { prefix_list = "PL-EVPN-LOCAL-L2VNI-SUBNETS" }
}

resource "vyos_policy_prefix_list_rule" "evpn_local_l2vni_subnet_rules" {
  for_each   = { for key, l2 in var.l2_vnis : key => l2 if try(l2.export_ipv4_unicast, false) }
  depends_on = [vyos_policy_prefix_list.evpn_local_l2vni_subnets]
  identifier = {
    prefix_list = "PL-EVPN-LOCAL-L2VNI-SUBNETS"
    rule        = tonumber(each.value.vlan_id) * 10
  }
  action = "permit"
  prefix = cidrsubnet("${each.value.anycast_gw_ip}/${each.value.anycast_gw_cidr}", 0, 0)
}

resource "vyos_policy_route_map" "evpn_spine_export" {
  count      = length(var.l2_vnis) > 0 ? 1 : 0
  depends_on = [vyos_policy_prefix_list_rule.evpn_local_l2vni_subnet_rules]
  identifier = { route_map = "RM-EVPN-SPINE-EXPORT" }
}

resource "vyos_policy_route_map_rule" "evpn_spine_export_deny_l2vni_subnets" {
  count      = length(var.l2_vnis) > 0 ? 1 : 0
  depends_on = [vyos_policy_route_map.evpn_spine_export]
  identifier = { route_map = "RM-EVPN-SPINE-EXPORT", rule = 10 }
  action     = "deny"
  match = {
    evpn = { route_type = "prefix" }
    ip   = { address = { prefix_list = "PL-EVPN-LOCAL-L2VNI-SUBNETS" } }
  }
}

resource "vyos_policy_route_map_rule" "evpn_spine_export_permit_other" {
  count      = length(var.l2_vnis) > 0 ? 1 : 0
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

resource "vyos_policy_prefix_list" "evpn_local_svi" {
  identifier = {
    prefix_list = local.evpn_local_svi_prefix_list_name
  }
}

resource "vyos_policy_prefix_list_rule" "evpn_local_svi_rules" {
  depends_on = [resource.vyos_policy_prefix_list.evpn_local_svi]
  for_each   = local.evpn_local_svi_prefix_rules

  identifier = {
    prefix_list = local.evpn_local_svi_prefix_list_name
    rule        = each.value.rule
  }

  action = "permit"
  prefix = each.value.prefix
}

resource "vyos_policy_route_map" "route_map_block_local_evpn" {
  depends_on = [
    resource.vyos_policy_as_path_list_rule.block_local_AS_evpn_rule,
    resource.vyos_policy_prefix_list_rule.evpn_local_svi_rules
  ]
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

    #ip = {
    #  address = {
    #    prefix_list = local.evpn_local_svi_prefix_list_name
    #  }
    #}
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
