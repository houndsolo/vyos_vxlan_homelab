resource "vyos_system" "dhcp" {
  host_name     = var.node_name
  domain_name   = var.dns.domain_name
  domain_search = var.dns.domain_search
  name_server   = var.dns.name_servers
}

resource "vyos_system_ip" "no_transit" {
  disable_forwarding = true
}
