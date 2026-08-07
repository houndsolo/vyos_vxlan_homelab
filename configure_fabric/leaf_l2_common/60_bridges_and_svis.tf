resource "vyos_interfaces_bridge" "vxlan_bridge_L2" {
  for_each   = var.l2_vnis
  depends_on = [vyos_interfaces_vxlan.vxlan_interfaces_L3]
  identifier = { bridge = "br${each.value.vni}" }
  ip = {
    enable_arp_accept = true
  }
  mtu = var.vxlan.outer_mtu
  address = [
    "${each.value.anycast_gw_ip}/${each.value.anycast_gw_cidr}"
  ]
  mac = each.value.anycast_mac
  vrf = each.value.vrf
}



resource "vyos_interfaces_bridge" "vxlan_bridge_L3" {
  for_each   = var.vnis.l3
  depends_on = [vyos_interfaces_vxlan.vxlan_interfaces_L3]
  identifier = { bridge = "br${each.value.vni}" }
  mtu        = var.vxlan.outer_mtu
  vrf        = each.value.vrf
}

resource "vyos_interfaces_bridge_member_interface" "brN_vxlanN_l2" {
  depends_on = [
    vyos_interfaces_bridge.vxlan_bridge_L2,
    vyos_interfaces_bridge.vxlan_bridge_L3
  ]
  for_each = var.l2_vnis
  disable_learning = true
  identifier = {
    bridge    = "br${each.value.vni}"
    interface = "vxlan${each.value.vni}"
  }
}

resource "vyos_interfaces_bridge_member_interface" "brN_vxlanN_l3" {
  depends_on = [
    vyos_interfaces_bridge.vxlan_bridge_L2,
    vyos_interfaces_bridge.vxlan_bridge_L3
  ]
  for_each = var.vnis.l3
  disable_learning = true
  identifier = {
    bridge    = "br${each.value.vni}"
    interface = "vxlan${each.value.vni}"
  }
}

