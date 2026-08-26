resource "vyos_protocols_bgp_address_family_l2vpn_evpn" "l2vpn_evpn_config" {
  depends_on        = [vyos_protocols_bgp.enable_bgp]
  advertise_all_vni = var.bgp_l2vpn.advertise_vni
  advertise_svi_ip  = var.bgp_l2vpn.advertise_svi
  rt_auto_derive    = var.bgp_l2vpn.rt_auto_derive
}

resource "vyos_protocols_bgp_address_family_l2vpn_evpn_vni" "l2vni_bgp_global_config" {
  for_each             = var.l2_vnis
  depends_on           = [vyos_protocols_bgp_address_family_l2vpn_evpn.l2vpn_evpn_config]
  identifier           = { vni = each.value.vni }
  rd                   = "${var.node.fabric_loopback_v4_net}:${tostring(each.value.vni)}"
  advertise_default_gw = each.value.advertise_default_gw
  advertise_svi_ip     = each.value.advertise_svi_ip
}

resource "vyos_protocols_bgp_address_family_l2vpn_evpn_flooding" "l2vpn_evpn_flooding" {
  depends_on           = [vyos_protocols_bgp_address_family_l2vpn_evpn.l2vpn_evpn_config]
  disable              = var.bgp_l2vpn.flooding_disable
  head_end_replication = var.bgp_l2vpn.her
}

resource "vyos_protocols_bgp_peer_group" "peer_group_spine_overlay" {
  depends_on = [
    vyos_protocols_bgp.enable_bgp,
    vyos_policy_route_map_rule.evpn_spine_export_permit_other,
  ]
  identifier    = { peer_group = "spine_overlay" }
  remote_as     = "internal"
  update_source = var.node.vxlan_source_interface
  bfd           = {}
  address_family = {
    l2vpn_evpn = merge({
      soft_reconfiguration = { inbound = true }
      }, length(var.l2vni_subnet_policies) > 0 ? {
      route_map = { export = "RM-EVPN-SPINE-EXPORT" }
    } : {})
  }
}

resource "vyos_protocols_bgp_neighbor" "evpn_peering" {
  for_each   = var.spines
  depends_on = [vyos_protocols_bgp_peer_group.peer_group_spine_overlay]
  identifier = { neighbor = each.value.fabric_loopback_v6_net }
  peer_group = "spine_overlay"
}

moved {
  from = vyos_protocols_bgp_neighbor.vxlan_peering
  to   = vyos_protocols_bgp_neighbor.evpn_peering
}
