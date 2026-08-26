resource "vyos_protocols_bgp" "enable_bgp" {
  depends_on = [
    vyos_interfaces_dummy.dummy_interface
  ]
  system_as = var.node.bgp_system_as
}

resource "vyos_protocols_bgp_parameters" "set_router_id" {
  depends_on       = [vyos_protocols_bgp.enable_bgp]
  router_id        = var.node.fabric_loopback_v4_net
  fast_convergence = true
}

resource "vyos_protocols_bgp_parameters_bestpath_as_path" "bgp_multipath_relax" {
  depends_on      = [vyos_protocols_bgp.enable_bgp]
  multipath_relax = true
}

resource "vyos_protocols_bgp_peer_group" "peer_group_spine_underlay" {
  depends_on = [
    vyos_protocols_bgp.enable_bgp,
    vyos_policy_route_map.create_route_map_local_as
  ]
  identifier = { peer_group = "spine_underlay" }
  capability = {
    #dynamic = true
    extended_nexthop = true
  }
  remote_as = "external"
  bfd       = {}
  address_family = {
    ipv6_unicast = {
      soft_reconfiguration = { inbound = true }
      route_map = {
        export = "local_as_rm"
      }
    }
  }
}

resource "vyos_protocols_bgp_peer_group_local_as" "peer_group_underlay_local_as" {
  depends_on = [vyos_protocols_bgp_peer_group.peer_group_spine_underlay]
  identifier = {
    local_as   = var.node.underlay_local_as
    peer_group = "spine_underlay"
  }
  no_prepend = { replace_as = true }
}

resource "vyos_protocols_bgp_neighbor" "bgp_underlay_neighbors" {
  for_each   = var.spines
  depends_on = [vyos_protocols_bgp_peer_group.peer_group_spine_underlay]
  identifier = { neighbor = local.underlay_peer_interfaces[each.key] }
  interface = {
    v6only = {
      peer_group = "spine_underlay"
    }
  }
}


resource "vyos_protocols_bgp_address_family_ipv6_unicast_network" "redistribute_loopback" {
  depends_on = [vyos_protocols_bgp.enable_bgp]
  identifier = { network = var.node.fabric_loopback_v6 }
}
