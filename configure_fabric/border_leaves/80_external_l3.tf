resource "vyos_interfaces_ethernet" "ext_l3" {
  identifier  = { ethernet = var.external_l3.interface }
  description = "ext_l3"
  mtu         = var.vxlan.outer_mtu
  lifecycle {
    ignore_changes = [
      hw_id,
      offload
    ]
  }
}

resource "vyos_interfaces_ethernet_vif" "set_eth3_vif_mtu" {
  depends_on = [
    resource.vyos_interfaces_ethernet.ext_l3,
    resource.vyos_vrf_name.create_vrfs
  ]
  for_each    = var.vnis.external_l3
  description = "${each.value.vrf} L3 external connectivity"
  identifier = {
    ethernet = var.external_l3.interface
    vif      = each.value.vlan_id
  }
  vrf = each.value.vrf
  mtu = var.vxlan.outer_mtu
}


resource "vyos_service_router_advert_interface" "enable_ipv6_ra_underlay_eth3" {
  for_each   = var.vnis.external_l3
  depends_on = [vyos_interfaces_ethernet_vif.set_eth3_vif_mtu]
  identifier = { interface = "${var.external_l3.interface}.${each.value.vlan_id}" }
}



resource "vyos_vrf_name_protocols_bgp_peer_group" "peer_group_FW_l3_out" {
  depends_on = [
    module.leaf_l2_common,
    vyos_interfaces_ethernet_vif.set_eth3_vif_mtu
  ]
  for_each = var.vnis.external_l3
  identifier = {
    peer_group = var.external_l3.peer_group_name
    name       = each.value.vrf
  }
  capability = {
    dynamic          = true
    extended_nexthop = true
  }
  remote_as = var.external_l3.remote_asn
  address_family = {
    ipv4_unicast = {
      soft_reconfiguration = { inbound = true }
    }
    #ipv6_unicast = {
    #  soft_reconfiguration = { inbound = true }
    #}
  }
}


resource "vyos_vrf_name_protocols_bgp_neighbor" "fw_wan_conectivity" {
  depends_on = [
    module.leaf_l2_common,
    vyos_vrf_name_protocols_bgp_peer_group.peer_group_FW_l3_out,
    vyos_interfaces_ethernet_vif.set_eth3_vif_mtu
  ]
  for_each = var.vnis.external_l3
  identifier = {
    name     = each.value.vrf
    neighbor = "${var.external_l3.interface}.${each.value.vlan_id}"
  }
  interface = {
    v6only = {
      peer_group = var.external_l3.peer_group_name
    }
  }
}
