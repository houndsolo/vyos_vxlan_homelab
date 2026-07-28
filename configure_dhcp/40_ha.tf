resource "vyos_service_dhcp_server_high_availability" "node" {
  mode           = var.dhcp.ha.mode
  status         = var.node.ha_role
  source_address = cidrhost(cidrsubnet(local.ha.subnet, 8, 10), var.node.id)
  remote         = cidrhost(cidrsubnet(local.ha.subnet, 8, 10), var.nodes[local.peer_name].id)
  name           = local.peer_name

  lifecycle {
    precondition {
      condition     = local.peer_name != var.node_name
      error_message = "The DHCP HA peer name must differ from the local hostname."
    }
  }

  depends_on = [
    vyos_interfaces_ethernet.attachment,
    vyos_service_dhcp_server_shared_network_name.scope,
  ]
}
