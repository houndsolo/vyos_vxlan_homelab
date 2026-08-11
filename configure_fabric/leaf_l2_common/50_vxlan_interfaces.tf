resource "vyos_interfaces_vxlan" "vxlan_interface" {
  identifier = { vxlan = "vxlan0" }
  #source_interface = var.node.vxlan_source_interface
  source_address = var.node.vxlan_loopback_v6_net
  mac            = format("00:13:37:00:00:%02d", var.node.id)
  mtu            = var.vxlan.mtu
  ip = {
    disable_arp_filter        = var.vxlan.disable_arp_filter
    disable_forwarding        = var.vxlan.disable_forwarding
    enable_arp_accept         = var.vxlan.enable_arp_accept
    enable_arp_announce       = var.vxlan.enable_arp_announce
    enable_directed_broadcast = var.vxlan.enable_directed_broadcast
    enable_proxy_arp          = var.vxlan.enable_proxy_arp
    proxy_arp_pvlan           = var.vxlan.proxy_arp_pvlan
  }
  ipv6 = {
    disable_forwarding = false
  }
  parameters = {
    external          = var.vxlan.external
    neighbor_suppress = var.vxlan.neighbor_suppress
    nolearning        = var.vxlan.nolearning
    vni_filter        = var.vxlan.vni_filter
  }
}
#resource "vyos_interfaces_vxlan" "vxlan_interfaces_L2" {
#  for_each         = var.l2_vnis
#  identifier       = { vxlan = "vxlan${each.value.vni}" }
#  source_interface = var.node.vxlan_source_interface
#  source_address   = var.node.vxlan_loopback_v6_net
#  mtu              = var.vxlan.mtu
#  ip = {
#    disable_arp_filter        = var.vxlan.disable_arp_filter
#    disable_forwarding        = var.vxlan.disable_forwarding
#    enable_arp_accept         = var.vxlan.enable_arp_accept
#    enable_arp_announce       = var.vxlan.enable_arp_announce
#    enable_directed_broadcast = var.vxlan.enable_directed_broadcast
#    enable_proxy_arp          = var.vxlan.enable_proxy_arp
#    proxy_arp_pvlan           = var.vxlan.proxy_arp_pvlan
#  }
#  ipv6 = {
#    disable_forwarding = false
#  }
#  parameters = {
#    external          = var.vxlan.external
#    neighbor_suppress = var.vxlan.neighbor_suppress
#    nolearning        = var.vxlan.nolearning
#    vni_filter        = var.vxlan.vni_filter
#  }
#  vni = each.value.vni
#}
#
#resource "vyos_interfaces_vxlan" "vxlan_interfaces_L3" {
#  for_each         = var.vnis.l3
#  identifier       = { vxlan = "vxlan${each.value.vni}" }
#  description      = "Layer 3 for ${each.value.vrf} vrf"
#  source_interface = var.node.vxlan_source_interface
#  source_address   = var.node.vxlan_loopback_v6_net
#  mtu              = var.vxlan.mtu
#  ip = {
#    disable_arp_filter        = var.vxlan.disable_arp_filter
#    disable_forwarding        = var.vxlan.disable_forwarding
#    enable_arp_accept         = var.vxlan.enable_arp_accept
#    enable_arp_announce       = var.vxlan.enable_arp_announce
#    enable_directed_broadcast = var.vxlan.enable_directed_broadcast
#    enable_proxy_arp          = var.vxlan.enable_proxy_arp
#    proxy_arp_pvlan           = var.vxlan.proxy_arp_pvlan
#  }
#  ipv6 = {
#    disable_forwarding = false
#  }
#  parameters = {
#    external          = var.vxlan.external
#    neighbor_suppress = var.vxlan.neighbor_suppress
#    nolearning        = var.vxlan.nolearning
#    vni_filter        = var.vxlan.vni_filter
#  }
#  vni = each.value.vni
#}
