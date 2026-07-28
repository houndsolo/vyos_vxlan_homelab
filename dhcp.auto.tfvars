dhcp_nodes = {
  vyos-DHCP-1 = {
    name = "vyos-DHCP-1"
    mgmt_addr = "10.20.10.251"
    mgmt_subnet = "16"
    node_id    = 251
    hypervisor_node   = "fichina"
    hypervisor_vm_id  = 771
    dhcp_ha_role   = "primary"
    dhcp_ha_source = "10.6.10.251"
    dhcp_ha_remote = "10.6.10.252"
    dhcp_ha_peer_name = "vyos-DHCP-2"
  },
  vyos-DHCP-2 = {
    name = "vyos-DHCP-2"
    mgmt_addr = "10.20.10.252"
    mgmt_subnet = "16"
    node_id    = 252
    hypervisor_node   = "fortuna"
    hypervisor_vm_id  = 772
    dhcp_ha_role   = "secondary"
    dhcp_ha_source = "10.6.10.252"
    dhcp_ha_remote = "10.6.10.251"
    dhcp_ha_peer_name = "vyos-DHCP-1"
  }
}

dhcp_scopes = {
  #3 = {
  #  subnet = "10.3.0.0/16"
  #  default_router = "10.3.0.5"
  #  name_server  = ["10.8.6.9"]
  #  domain_name = "lyalt.space"
  #  range = {
  #    0 = {
  #      start = "10.3.5.1"
  #      stop = "10.3.5.99"
  #    }
  #  }
  #}
  8 = {
    subnet = "10.8.0.0/16"
    default_router = "10.8.0.5"
    name_server  = ["10.8.6.9"]
    domain_name = "lyalt.space"
    range = {
      0 = {
        start = "10.8.5.1"
        stop = "10.8.5.99"
      }
    }
  }
  9 = {
    subnet = "10.9.0.0/16"
    default_router = "10.9.0.5"
    name_server  = ["10.8.6.9"]
    domain_name = "lyalt.space"
    range = {
      0 = {
        start = "10.9.5.1"
        stop = "10.9.5.99"
      }
    }
  }
}

