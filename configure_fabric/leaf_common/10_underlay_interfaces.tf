locals {
  underlay_peer_interfaces = {
    for spine_name, spine in var.spines :
    spine_name => var.node.underlay_peer_vlan == null ? spine.uplink_if : "${spine.uplink_if}.${var.node.underlay_peer_vlan}"
  }
}

resource "vyos_interfaces_dummy" "dummy_interface" {
  identifier = { dummy = var.node.vxlan_source_interface }
  address = [
    var.node.fabric_loopback_v4,
    var.node.fabric_loopback_v6
  ]
  mtu = var.vxlan.outer_mtu
}

resource "vyos_interfaces_ethernet" "link_to_spines" {
  for_each    = var.node.is_vm ? {} : var.spines
  identifier  = { ethernet = each.value.uplink_if }
  description = "p2p-spine-${each.value.id}"
  mtu         = var.vxlan.outer_mtu

  lifecycle {
    ignore_changes = [
      hw_id,
      offload
    ]
  }
}

resource "vyos_interfaces_ethernet" "vm_link_to_spines" {
  for_each    = var.node.is_vm ? var.spines : {}
  identifier  = { ethernet = each.value.uplink_if }
  description = "p2p-spine-${each.value.id}"
  mtu         = var.vxlan.outer_mtu
  hw_id       = var.node.fabric_macs[each.value.uplink_if]

  lifecycle {
    ignore_changes = [offload]
  }
}

resource "vyos_interfaces_ethernet_vif" "link_to_spines_underlay_peer_vlan" {
  depends_on = [
    vyos_interfaces_ethernet.link_to_spines,
    vyos_interfaces_ethernet.vm_link_to_spines
  ]
  for_each = var.node.underlay_peer_vlan == null ? {} : var.spines
  identifier = {
    ethernet = each.value.uplink_if
    vif      = var.node.underlay_peer_vlan
  }
  description = "p2p-spine-${each.value.id}-vlan-${var.node.underlay_peer_vlan}"
  mtu         = var.vxlan.outer_mtu
}

resource "vyos_service_router_advert_interface" "enable_ipv6_ra_underlay_eth" {
  depends_on = [
    vyos_interfaces_ethernet.link_to_spines,
    vyos_interfaces_ethernet.vm_link_to_spines,
    vyos_interfaces_ethernet_vif.link_to_spines_underlay_peer_vlan
  ]
  for_each   = var.spines
  identifier = { interface = local.underlay_peer_interfaces[each.key] }
}
