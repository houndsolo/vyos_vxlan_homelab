variable "fabric" {
  type = object({
    defaults = object({
      bgp_system_as                     = number
      underlay_local_as_base            = number
      ipv4_loopback_prefix              = string
      ipv6_underlay_prefix              = string
      vxlan_source_interface            = string
      l2_service_bridge_id              = number
      vyos_mgmt_prefix                  = string
      vyos_mgmt_cidr                    = number
      vyos_provider_default_timeouts    = number
      vyos_provider_disable_verify      = bool
      vyos_overwrite_existing_on_create = bool
    })
    bgp_l2vpn = object({
      flooding_disable = bool
      her              = bool
      advertise_svi    = bool
      advertise_vni    = bool
      rt_auto_derive   = bool
    })
    vxlan = object({
      mtu                       = number
      outer_mtu                 = number
      disable_forwarding        = bool
      disable_arp_filter        = bool
      enable_arp_accept         = bool
      enable_arp_announce       = bool
      enable_directed_broadcast = bool
      enable_proxy_arp          = bool
      proxy_arp_pvlan           = bool
      external                  = bool
      neighbor_suppress         = bool
      nolearning                = bool
      vni_filter                = bool
    })
    evpn_rr = optional(map(object({
      id               = number
      hypervisor_node  = optional(string, null)
      is_vm            = optional(bool, true)
      underlay_bridges = optional(list(string), null)
    })), {})
    spines = map(object({
      id              = number
      uplink_if       = optional(string, null)
      hypervisor_node = optional(string, null)
    }))

    leaves = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
    fabric_ext_leaves = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
    border_leaves = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
    leaves_greatfox = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
  })
}

variable "dns" {
  description = "DNS configuration"
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })
}

variable "vnis" {
  type = object({
    l3 = map(object({
      vni                              = number
      vrf                              = string
      vrf_table                        = number
      ipv4_rt_imports                  = optional(string, null)
      ipv4_rt_exports                  = optional(string, null)
      border_leaf_ipv4_rt_imports      = optional(string, null)
      border_leaf_ipv4_rt_exports      = optional(string, null)
      border_leaf_ipv4_vpn_import_bool = optional(bool, false)
      border_leaf_ipv4_vrf_imports     = optional(list(string), null)
      evpn_rt_imports                  = optional(list(string), [])
      evpn_rt_exports                  = optional(list(string), [])
      ext_l3_vlan                      = optional(number)
      export_vpn_ipv4                  = optional(bool, false)
      redistribute_ipv4 = optional(object({
        connected = optional(object({}), null)
        static    = optional(object({}), null)
      }))
      l2 = optional(map(object({
        vni                  = number
        vlan_id              = number
        anycast_gw_ip        = string
        anycast_gw_cidr      = number
        anycast_mac          = string
        advertise_default_gw = optional(bool, false)
        advertise_svi_ip     = optional(bool, false)
        export_ipv4_unicast  = optional(bool, false)
      })), {})
    }))
  })
}

variable "external_l3" {
  description = "Border-leaf external L3 connectivity settings."
  type = object({
    interface       = string
    peer_group_name = string
    remote_asn      = number
  })
}

variable "proxmox_vtep_vm" {
  description = "Proxmox VM settings for VyOS VTEP instances."
  type = object({
    datastore_id             = string
    import_image             = string
    cloud_init_datastore_id  = string
    user_data_file_id        = string
    management_bridge        = string
    default_underlay_bridges = list(string)
    cpu_cores                = number
    cpu_type                 = string
    memory_mb                = number
    disk_size_gb             = number
  })
}
