resource "vyos_interfaces_pseudo_ethernet" "anycast_gateway_peth" {
  for_each         = var.vnis.l2
  depends_on       = [vyos_interfaces_bridge_member_interface.br0_vxlan0]
  identifier       = { pseudo_ethernet = "peth${each.value.vni}" }
  source_interface = "br0.${each.value.vlan}"
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
