module "create_vyos_vms" {
  for_each = var.dhcp_nodes
  source   = "./create_vyos_vms"

  node = each.value # self
  dns     = var.dns
}

module "vyos_system_config" {
  for_each = var.dhcp_nodes
  source   = "./vyos_system"

  node = each.value # self
  dns     = var.dns
  dhcp_scopes = var.dhcp_scopes
  providers = {
    vyos    = vyos.vyos_nodes[each.key]
  }
}

#module "vyos_interface_config" {
#  depends_on = [module.vyos_system_config]
#  for_each = var.vyos_nodes
#  source   = "./vyos_interfaces"
#
#  node = each.value # self
#  nodes = var.vyos_nodes # all other nodes
#  providers = {
#    vyos    = vyos.vyos_nodes[each.key]
#  }
#}
#
#module "vyos_bgp_peering" {
#  depends_on = [module.vyos_interface_config]
#  for_each = var.vyos_nodes
#  source   = "./vyos_bgp_peering"
#  node = each.value # self
#  nodes = var.vyos_nodes # all other nodes
#  vyos_fw_node = var.vyos_fw_node
#  providers = {
#    vyos    = vyos.vyos_nodes[each.key]
#  }
#}
#
#module "vyos_bgp_peering_fw_wan" {
#  source   = "./vyos_fw_WAN_non_fw"
#  node = var.vyos_fw_node
#  nodes = var.vyos_nodes # all other nodes
#  dns     = var.dns
#  providers = {
#    vyos    = vyos.fw-wan
#  }
#}
#

#module "n100_FW_WAN" {
#  source = "./vyos_fw_WAN_no_fw"
#  providers = {
#    vyos = vyos.fw-wan
#  }
#  vyos_n100s = var.vyos_n100s # all other BM
#}

#module "firewall_groups" {
#  source = "./vyos_fw_WAN"
#  providers = {
#    vyos = vyos.fw-wan
#  }
#  #  interface_groups = var.interface_groups
#  #  interface_includes = var.interface_includes
#  #  network_groups   = var.network_groups
#  #  network_includes = var.network_includes
#  #  address_groups   = var.address_groups
#  #  address_includes = var.address_includes
#}

