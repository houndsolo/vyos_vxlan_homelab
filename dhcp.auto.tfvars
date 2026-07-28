dhcp = {
  defaults = {
    client_name_servers = ["10.8.6.9"]
    lease_seconds       = 86400
    authoritative       = true
  }

  ha = {
    mode  = "active-passive"
    l2vni = 9006
  }

  nodes = {
    vyos-DHCP-1 = {
      id              = 251
      hypervisor_node = "titania"
      vm_id           = 771
      ha_role         = "primary"
    }
    vyos-DHCP-2 = {
      id              = 252
      hypervisor_node = "zoness"
      vm_id           = 772
      ha_role         = "secondary"
    }
  }
}
