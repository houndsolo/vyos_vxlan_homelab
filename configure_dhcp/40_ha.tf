resource "vyos_service_dhcp_server_high_availability" "node" {
  mode           = var.dhcp.ha.mode
  status         = var.node.ha_role
  source_address = local.source
  remote         = local.remote
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
