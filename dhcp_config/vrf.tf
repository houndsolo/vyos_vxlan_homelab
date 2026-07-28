resource "vyos_system" "host_parameters" {
  domain_name = var.dns.domain_name
  domain_search = var.dns.domain_search
  name_server = var.dns.name_servers
  host_name = var.node.name
}

resource "vyos_interfaces_ethernet_vif" "dhcp_interfaces"{
  for_each = var.dhcp_scopes
  identifier = {
    ethernet = "eth1"
    vif = each.key
  }
  address = ["10.${each.key}.10.${var.node.node_id}/16"]
}

resource "vyos_service_dhcp_server" "listen_address" {
  depends_on = [
    vyos_interfaces_ethernet_vif.dhcp_interfaces,
    vyos_service_dhcp_server_shared_network_name.network_names
  ]
 listen_interface = local.dhcp_listen_interfaces
}

resource "vyos_service_dhcp_server_shared_network_name" "network_names" {
  depends_on = [
    vyos_interfaces_ethernet_vif.dhcp_interfaces,
  ]
  for_each = var.dhcp_scopes
  identifier = {shared_network_name = "vlan${each.key}"}
  subnet = {
    "${each.value.subnet}" = {
      subnet_id = each.key
      range = each.value.range
      option = {
        default_router = each.value.default_router
        name_server = each.value.name_server
        domain_name = each.value.domain_name
      }
    }
  }
}

resource "vyos_interfaces_ethernet_vif" "dhcp_HA_peering"{
  identifier = {
    ethernet = "eth1"
    vif = 6
  }
  address = ["10.6.10.${var.node.node_id}/16"]
}

resource "vyos_service_dhcp_server_high_availability" "dhcp_HA" {
  depends_on = [
    vyos_interfaces_ethernet_vif.dhcp_interfaces,
    vyos_service_dhcp_server_shared_network_name.network_names,
    vyos_interfaces_ethernet_vif.dhcp_HA_peering
  ]
  mode = "active-passive"
  source_address = var.node.dhcp_ha_source
  remote = var.node.dhcp_ha_remote
  status = var.node.dhcp_ha_role
  name = var.node.dhcp_ha_peer_name
}

#resource "vyos_vrf_name" "mgmt" {
#  identifier = { name = "mgmt" }
#  table = 8008
#}
#
#resource "vyos_vrf_name" "lylat_lan" {
#  identifier = { name = "lylat_lan" }
#  table = 1337
#}

#resource "vyos_vrf_name" "lylat_infra" {
#  identifier = { name = "lylat_infra" }
#  table = 700
#}
#
#resource "vyos_vrf_name" "lylat_service" {
#  identifier = { name = "lylat_service" }
#  table = 1000
#}
#
#resource "vyos_vrf_name" "vpn_me" {
#  identifier = { name = "vpn_me" }
#  table = 1200
#}
#
#resource "vyos_vrf_name" "vpn_hay" {
#  identifier = { name = "vpn_hay" }
#  table = 4004
#}
#
#resource "vyos_vrf_name" "vpn_vultr" {
#  identifier = { name = "vpn_vultr" }
#  table = 2000
#}

