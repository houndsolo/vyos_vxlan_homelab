fabric = {
  defaults = {
    bgp_system_as                     = 700
    underlay_local_as_base            = 700
    ipv4_fabric_loopback_prefix       = "10.255.240.0/24"
    ipv6_fabric_loopback_prefix       = "fd69:255:240::/64"
    vxlan_source_interface            = "dum240"
    l2_service_bridge_id              = 9000
    vyos_mgmt_prefix                  = "10.20.10.0/24"
    vyos_mgmt_cidr                    = 16
    vyos_provider_default_timeouts    = 1
    vyos_provider_disable_verify      = true
    vyos_overwrite_existing_on_create = true
  }

  bgp_l2vpn = {
    her              = true
    flooding_disable = false
    advertise_svi    = false
    advertise_vni    = true
    rt_auto_derive   = false
  }

  vxlan = {
    mtu                       = 9119
    outer_mtu                 = 9189
    disable_forwarding        = false
    disable_arp_filter        = false
    enable_arp_accept         = false
    enable_arp_announce       = false
    enable_directed_broadcast = false
    enable_proxy_arp          = false
    proxy_arp_pvlan           = false
    external                  = true
    neighbor_suppress         = false
    nolearning                = true
    vni_filter                = true
  }

  evpn_rr = {
    evpn-rr-1 = { hypervisor_node = "titania", id = 100, is_vm = true }
    evpn-rr-2 = { hypervisor_node = "fortuna", id = 200, is_vm = true }
  }
  spines = {
    #mikrotik 326
    rtr1 = {
      id        = 1
      uplink_if = "eth1"
      hosturl   = "http://10.20.0.5"
      as        = 810
    }
    #mikrotik 326
    rtr2 = {
      id        = 2
      uplink_if = "eth2"
      hosturl   = "http://10.20.0.6"
      as        = 810
    }
  }

  leaves = {
    fichina = { hypervisor_node = "fichina", id = 11, is_vm = true, started = true }
    macbeth = { hypervisor_node = "macbeth", id = 12, is_vm = true, started = true }
    titania = { hypervisor_node = "titania", id = 13, is_vm = true, started = true }
    zoness  = { hypervisor_node = "zoness", id = 14, is_vm = true, started = true }
    fortuna = { hypervisor_node = "fortuna", id = 15, is_vm = true, started = true }
    eldarad = { hypervisor_node = "eldarad", id = 16, is_vm = true, started = true }
    venom   = { hypervisor_node = "venom", id = 17, is_vm = true, started = true }
  }

  fabric_ext_leaves = {
    #fabric-1 = {
    #  hypervisor_node    = "eldarad", id = 41, is_vm = true
    #  underlay_peer_vlan = 400
    #  underlay_bridges   = ["vmbr4001", "vmbr4002", "vmbr100"]
    #  started            = true
    #}
    fabric-2 = {
      id           = 42
      is_vm        = false
      spine_uplink = "ether10"
    }

  }

  border_leaves = {
    # n100 mini pc
    border-1 = { id = 18, is_vm = false }
    # n100 mini pc
    border-2 = { id = 19, is_vm = false }
  }

  leaves_greatfox = {
    greatfox = {
      hypervisor_node = "greatfox"
      id              = 20
      is_vm           = true
      started         = true
    }
  }
}
