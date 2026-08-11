fabric = {
  defaults = {
    bgp_system_as                     = 700
    underlay_local_as_base            = 700
    ipv4_loopback_prefix              = "10.255.240.0/24"
    ipv6_underlay_prefix              = "fd69:255:240::/64"
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
    rtr1 = { id = 1, uplink_if = "eth1" }
    #mikrotik 326
    rtr2 = { id = 2, uplink_if = "eth2" }
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
      id    = 42
      is_vm = false
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

vnis = {
  external_l3 = {
    6666 = {
      vlan_id     = 1000
      vni         = 6666
      vrf         = "lylat_external"
      vrf_table   = 6666
      anycast_mac = "bc:24:11:00:66:66"
      #ipv4_rt_imports = "700:6200 700:6900"
      #ipv4_rt_exports = "700:6600"
      #border_leaf_ipv4_rt_imports = "420:1337 420:666"
      #border_leaf_ipv4_vrf_imports = [
      #]
      ext_l3                           = true
      border_leaf_ipv4_rt_imports      = "700:6900 700:6600 700:6200"
      border_leaf_ipv4_rt_exports      = "700:6666"
      border_leaf_ipv4_vpn_import_bool = true
      export_vpn_ipv4                  = true
      evpn_rt_imports = [
        "700:6666",
        "700:6900",
        "700:6600",
      ]
      evpn_rt_exports = [
        "700:6666",
      ]
    }
  }
  l3 = {


    6600 = {
      vlan_id         = 66
      vni             = 6600
      vrf             = "lylat_service"
      vrf_table       = 1000
      ipv4_rt_imports = "700:6200 700:6900"
      ipv4_rt_exports = "700:6600"
      #border_leaf_ipv4_rt_imports = "420:1337 420:666"
      #border_leaf_ipv4_vrf_imports = [
      #]
      #border_leaf_ipv4_rt_imports      = "700:6666 700:6900 700:6200"
      #border_leaf_ipv4_rt_exports      = "700:6600"
      border_leaf_ipv4_vpn_import_bool = true
      export_vpn_ipv4                  = true
      #anycast_mac          = "bc:24:11:00:66:00"
      evpn_rt_imports = [
        "700:6600",
        "700:6900",
        "700:6666",
      ]
      evpn_rt_exports = [
        "700:6600",
      ]
      #redistribute_ipv4 = {
      #  connected = {}
      #}

      l2 = {
        6 = {
          vni                  = 9006
          vlan_id              = 6
          anycast_gw_ip        = "10.6.0.5"
          anycast_gw_cidr      = 16
          anycast_mac          = "bc:24:11:00:66:00"
          advertise_default_gw = false
          advertise_svi_ip     = false
          export_ipv4_unicast  = true
          dhcp = {
            scope = {
              ranges = {
                0 = { start = "10.6.5.1", stop = "10.6.5.99" }
              }
            }
          }
        }
        8 = {
          vni                  = 9008
          vlan_id              = 8
          anycast_gw_ip        = "10.8.0.5"
          anycast_gw_cidr      = 16
          anycast_mac          = "bc:24:11:00:66:00"
          advertise_default_gw = false
          advertise_svi_ip     = false
          export_ipv4_unicast  = true
          dhcp = {
            scope = {
              ranges = {
                0 = { start = "10.8.5.1", stop = "10.8.5.99" }
              }
            }
          }
        }
      }
    }
    6900 = {
      vlan_id   = 69
      vni       = 6900
      vrf       = "lylat_lan"
      vrf_table = 1337
      #anycast_mac          = "bc:24:11:00:69:00"
      ipv4_rt_imports = "700:6600"
      ipv4_rt_exports = "700:6900"
      #border_leaf_ipv4_vrf_imports = [
      #  "lylat_service",
      #]
      #border_leaf_ipv4_rt_imports      = "700:6666 700:6600 700:6200"
      #border_leaf_ipv4_rt_exports      = "700:6900"
      border_leaf_ipv4_vpn_import_bool = true
      export_vpn_ipv4                  = true
      #redistribute_ipv4 = {
      #  connected = {}
      #}
      evpn_rt_imports = [
        "700:6900",
        "700:6600",
        "700:6666",
      ]
      evpn_rt_exports = [
        "700:6900",
      ]

      l2 = {
        9 = {
          vni                  = 9009
          vlan_id              = 9
          anycast_gw_ip        = "10.9.0.5"
          anycast_gw_cidr      = 16
          anycast_mac          = "bc:24:11:00:69:00"
          advertise_default_gw = false
          advertise_svi_ip     = false
          export_ipv4_unicast  = true
          dhcp = {
            scope = {
              ranges = {
                0 = { start = "10.9.5.1", stop = "10.9.5.99" }
              }
            }
          }
        }
        10 = {
          vni                  = 9010
          vlan_id              = 10
          anycast_gw_ip        = "10.10.0.5"
          anycast_gw_cidr      = 16
          anycast_mac          = "bc:24:11:00:69:00"
          advertise_default_gw = false
          advertise_svi_ip     = false
          export_ipv4_unicast  = true
          dhcp = {
            scope = {
              ranges = {
                0 = { start = "10.10.5.1", stop = "10.10.5.99" }
              }
            }
          }
        }
      }
    }

    6200 = {
      vlan_id         = 62
      vni             = 6200
      vrf             = "lylat_infra"
      vrf_table       = 700
      ipv4_rt_imports = "700:6600"
      ipv4_rt_exports = "700:6200"
      #border_leaf_ipv4_vrf_imports = [
      #  "lylat_service",
      #]
      #border_leaf_ipv4_rt_imports      = "700:6666 700:6600 700:6900"
      #border_leaf_ipv4_rt_exports      = "700:6200"
      #anycast_mac          = "bc:24:11:00:62:00"
      border_leaf_ipv4_vpn_import_bool = true
      export_vpn_ipv4                  = true
      evpn_rt_imports = [
        "700:6200",
      ]
      evpn_rt_exports = [
        "700:6200",
      ]
      #redistribute_ipv4 = {
      #  connected = {}
      #}

      l2 = {
        2 = {
          vni                  = 9002
          vlan_id              = 2
          anycast_gw_ip        = "10.2.0.5"
          anycast_gw_cidr      = 16
          anycast_mac          = "bc:24:11:00:62:00"
          advertise_default_gw = false
          advertise_svi_ip     = false
          export_ipv4_unicast  = true
          dhcp = {
            scope = {
              ranges = {
                0 = { start = "10.2.5.1", stop = "10.2.5.99" }
              }
            }
          }
        }
      }
    }
  }
}
