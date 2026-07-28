resource "vyos_service_dhcp_server" "kea" {
  depends_on       = [vyos_service_dhcp_server_shared_network_name.scope]
  listen_interface = [for attachment in values(var.attachments) : attachment.interface if attachment.scope != null]
}

resource "vyos_service_dhcp_server_shared_network_name" "scope" {
  for_each   = { for vni, attachment in var.attachments : vni => attachment if attachment.scope != null }
  identifier = { shared_network_name = "l2vni${each.value.vni}" }

  authoritative = coalesce(each.value.scope.authoritative, var.dhcp.defaults.authoritative)
  subnet = {
    (each.value.subnet) = {
      subnet_id = each.value.vni
      lease     = coalesce(each.value.scope.lease_seconds, var.dhcp.defaults.lease_seconds)
      range     = each.value.scope.ranges
      option = {
        default_router = each.value.default_router
        name_server    = coalesce(each.value.scope.name_servers, var.dhcp.defaults.client_name_servers)
        domain_name    = coalesce(each.value.scope.domain_name, var.dns.domain_name)
        domain_search  = coalesce(each.value.scope.domain_search, var.dns.domain_search)
      }
    }
  }

  depends_on = [vyos_interfaces_ethernet.attachment]
}
