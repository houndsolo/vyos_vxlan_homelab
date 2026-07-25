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

  validation {
    condition = (
      can(cidrhost(var.fabric.defaults.ipv4_loopback_prefix, 0)) &&
      !strcontains(var.fabric.defaults.ipv4_loopback_prefix, ":") &&
      can(cidrhost(var.fabric.defaults.ipv6_underlay_prefix, 0)) &&
      strcontains(var.fabric.defaults.ipv6_underlay_prefix, ":") &&
      can(cidrhost(var.fabric.defaults.vyos_mgmt_prefix, 0)) &&
      !strcontains(var.fabric.defaults.vyos_mgmt_prefix, ":")
    )
    error_message = "ipv4_loopback_prefix and vyos_mgmt_prefix must be valid IPv4 CIDRs; ipv6_underlay_prefix must be a valid IPv6 CIDR."
  }

  validation {
    condition = alltrue([
      for id in concat(
        [for node in values(var.fabric.evpn_rr) : node.id],
        [for node in values(var.fabric.spines) : node.id],
        [for node in values(var.fabric.leaves) : node.id],
        [for node in values(var.fabric.fabric_ext_leaves) : node.id],
        [for node in values(var.fabric.border_leaves) : node.id],
        [for node in values(var.fabric.leaves_greatfox) : node.id],
      ) :
      id == floor(id) && id > 0 &&
      var.fabric.defaults.underlay_local_as_base + id <= 4294967295 &&
      can(cidrhost(var.fabric.defaults.ipv4_loopback_prefix, id)) &&
      can(cidrhost(var.fabric.defaults.ipv6_underlay_prefix, parseint(tostring(id), 16))) &&
      can(cidrhost(var.fabric.defaults.vyos_mgmt_prefix, id))
    ])
    error_message = "Every fabric node ID must be a positive integer that fits the derived ASN and configured loopback, underlay, and management prefixes."
  }

  validation {
    condition = length(distinct(concat(
      [for node in values(var.fabric.evpn_rr) : node.id],
      [for node in values(var.fabric.spines) : node.id],
      [for node in values(var.fabric.leaves) : node.id],
      [for node in values(var.fabric.fabric_ext_leaves) : node.id],
      [for node in values(var.fabric.border_leaves) : node.id],
      [for node in values(var.fabric.leaves_greatfox) : node.id],
      ))) == length(concat(
      [for node in values(var.fabric.evpn_rr) : node.id],
      [for node in values(var.fabric.spines) : node.id],
      [for node in values(var.fabric.leaves) : node.id],
      [for node in values(var.fabric.fabric_ext_leaves) : node.id],
      [for node in values(var.fabric.border_leaves) : node.id],
      [for node in values(var.fabric.leaves_greatfox) : node.id],
    ))
    error_message = "Fabric node IDs must be unique across all node-role maps."
  }

  validation {
    condition = (
      var.fabric.defaults.bgp_system_as >= 1 && var.fabric.defaults.bgp_system_as <= 4294967295 &&
      var.fabric.defaults.underlay_local_as_base >= 1 && var.fabric.defaults.underlay_local_as_base <= 4294967295 &&
      var.fabric.defaults.vyos_mgmt_cidr >= 0 && var.fabric.defaults.vyos_mgmt_cidr <= 32 &&
      var.fabric.defaults.vyos_provider_default_timeouts > 0 &&
      var.fabric.defaults.l2_service_bridge_id >= 0 && var.fabric.defaults.l2_service_bridge_id <= 9999
    )
    error_message = "ASNs must be 1..4294967295, vyos_mgmt_cidr 0..32, timeouts positive, and the bridge ID 0..9999."
  }
}

variable "dns" {
  description = "DNS configuration"
  type = object({
    name_servers  = list(string)
    domain_name   = string
    domain_search = list(string)
  })

  validation {
    condition = alltrue([
      for address in var.dns.name_servers :
      can(cidrhost("${address}${strcontains(address, ":") ? "/128" : "/32"}", 0))
    ])
    error_message = "Every DNS name server must be a valid IPv4 or IPv6 address without a prefix length."
  }

  validation {
    condition     = trimspace(var.dns.domain_name) != "" && alltrue([for domain in var.dns.domain_search : trimspace(domain) != ""])
    error_message = "DNS domain_name and every domain_search entry must be non-empty."
  }
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

  validation {
    condition = alltrue(flatten([
      for l3 in values(var.vnis.l3) : concat(
        [l3.vni >= 1 && l3.vni <= 16777215, l3.vrf_table >= 1 && l3.vrf_table <= 4294967295, trimspace(l3.vrf) != ""],
        [for l2 in values(l3.l2) :
          l2.vni >= 1 && l2.vni <= 16777215 &&
          l2.vlan_id >= 1 && l2.vlan_id <= 4094 &&
          l2.anycast_gw_cidr >= 0 && l2.anycast_gw_cidr <= 32 &&
          can(cidrhost("${l2.anycast_gw_ip}/${l2.anycast_gw_cidr}", 0)) &&
          !strcontains(l2.anycast_gw_ip, ":") &&
          can(regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", l2.anycast_mac))
        ]
      )
    ]))
    error_message = "VNIs must be 1..16777215, tables 1..4294967295, VRF names non-empty, VLANs 1..4094, and every L2 gateway/MAC must be valid IPv4/CIDR and six-octet MAC syntax."
  }

  validation {
    condition = length(distinct(concat(
      [for l3 in values(var.vnis.l3) : l3.vni],
      flatten([for l3 in values(var.vnis.l3) : [for l2 in values(l3.l2) : l2.vni]]),
      ))) == length(concat(
      [for l3 in values(var.vnis.l3) : l3.vni],
      flatten([for l3 in values(var.vnis.l3) : [for l2 in values(l3.l2) : l2.vni]]),
    ))
    error_message = "Every L2VNI and L3VNI must be unique."
  }
}

variable "external_l3" {
  description = "Border-leaf external L3 connectivity settings."
  type = object({
    interface       = string
    peer_group_name = string
    remote_asn      = number
  })

  validation {
    condition = (
      trimspace(var.external_l3.interface) != "" &&
      trimspace(var.external_l3.peer_group_name) != "" &&
      var.external_l3.remote_asn >= 1 && var.external_l3.remote_asn <= 4294967295
    )
    error_message = "External interface and peer-group names must be non-empty, and remote_asn must be 1..4294967295."
  }
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

  validation {
    condition = (
      var.proxmox_vtep_vm.cpu_cores > 0 &&
      var.proxmox_vtep_vm.memory_mb > 0 &&
      var.proxmox_vtep_vm.disk_size_gb > 0 &&
      length(var.proxmox_vtep_vm.default_underlay_bridges) > 0 &&
      alltrue([for bridge in var.proxmox_vtep_vm.default_underlay_bridges : trimspace(bridge) != ""])
    )
    error_message = "VM CPU, memory, and disk values must be positive, and at least one non-empty default underlay bridge is required."
  }
}
