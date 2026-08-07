resource "vyos_interfaces_bridge" "vxlan_bridge" {
  depends_on = [vyos_interfaces_vxlan.vxlan_interface]
  identifier = { bridge = "br0" }
   ip = {
     enable_arp_accept = true
   }
  mtu = var.vxlan.outer_mtu
  enable_vlan = true
}

resource "vyos_interfaces_bridge_vif" "vxlan_bridge_L2" {
  for_each   = var.l2_vnis
  depends_on = [vyos_interfaces_bridge.vxlan_bridge]
  identifier = {
    bridge = "br0"
    vif = each.value.vlan_id
  }
  ip = {
    enable_arp_accept = true
  }
  mtu = var.vxlan.outer_mtu
  #address = [
  #  "${each.value.anycast_gw_ip}/${each.value.anycast_gw_cidr}"
  #]
  #mac = each.value.anycast_mac
  vrf        = each.value.vrf
}



resource "vyos_interfaces_bridge_vif" "vxlan_bridge_L3" {
  for_each   = var.vnis.l3
  depends_on = [vyos_interfaces_bridge.vxlan_bridge]
  identifier = {
    bridge = "br0"
    vif = each.value.vlan_id
  }
  mtu        = var.vxlan.outer_mtu
  mac = each.value.anycast_mac
  vrf        = each.value.vrf
}

resource "vyos_interfaces_bridge_member_interface" "br0_vxlan0" {
  depends_on = [vyos_interfaces_bridge.vxlan_bridge]
  disable_learning = true
  identifier = {
    bridge    = "br0"
    interface = "vxlan0"
  }
}

resource "vyos_interfaces_pseudo_ethernet" "anycast_gateway_peth" {
  for_each         = var.l2_vnis
  depends_on       = [vyos_interfaces_bridge_member_interface.br0_vxlan0]
  identifier       = { pseudo_ethernet = "peth${each.value.vni}" }
  source_interface = "br0.${each.value.vlan_id}"
  ip = {
    disable_arp_filter = true
  }
  address = [
    #"${each.value.anycast_gw_ip}/${each.value.anycast_gw_cidr}"
    "${each.value.anycast_gw_ip}/${each.value.anycast_gw_cidr}"
  ]
  mac = each.value.anycast_mac
  vrf = each.value.vrf
}

resource "vyos_interfaces_vxlan_vlan_to_vni" "svd_mapping" {
  depends_on = [vyos_interfaces_bridge_member_interface.br0_vxlan0]
  identifier = {
    #vlan
    vlan_to_vni = "2-10"
    vxlan = "vxlan0"
  }
  vni = "9002-9010"
}

