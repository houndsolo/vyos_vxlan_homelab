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
      started            = optional(bool, false)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
    fabric_ext_leaves = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      started            = optional(bool, false)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
    border_leaves = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      started            = optional(bool, false)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
    leaves_greatfox = map(object({
      id                 = number
      hypervisor_node    = optional(string, null)
      is_vm              = optional(bool, true)
      started            = optional(bool, false)
      underlay_bridges   = optional(list(string), null)
      underlay_peer_vlan = optional(number, null)
    }))
  })
}

variable "pve_api_token" {
  type      = string
  sensitive = true
}

variable "gf_api_token" {
  type      = string
  sensitive = true
}

variable "dhcp" {
  type = any
}

variable "dhcp_attachments" {
  type = map(object({
    vni            = number
    interface      = string
    bridge         = string
    vlan_id        = number
    subnet         = string
    default_router = string
    scope          = any
  }))
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
