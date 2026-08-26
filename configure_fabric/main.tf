module "spines" {
  for_each  = { for name, node in var.fabric.spines : name => node if node.configure }
  source    = "./spines_mikrotik"
  node      = var.fabric.spines[each.key]
  providers = { routeros = routeros.spines[each.key]}
  fabric  = var.fabric
}

module "border_leaves" {
  for_each  = { for name, node in var.fabric.border_leaves : name => node if node.configure }
  source    = "./border_leaves"
  providers = { vyos = vyos.border_leaves[each.key] }
  node      = local.border_leaves[each.key]
  dns       = var.dns

  bgp_l2vpn   = var.fabric.bgp_l2vpn
  vnis        = var.vnis
  external_l3 = var.external_l3

  vxlan  = var.fabric.vxlan
  spines = local.spines
}

module "fabric_ext_leaf_vms" {
  for_each  = { for name, node in var.fabric.fabric_ext_leaves : name => node if node.configure }
  source    = "./fabric_leaves_trunk"
  providers = { vyos = vyos.fabric_leaves[each.key] }
  node      = local.fabric_leaves[each.key]
  dns       = var.dns

  bgp_l2vpn   = var.fabric.bgp_l2vpn
  vnis        = var.vnis
  external_l2 = var.external_l2

  vxlan   = var.fabric.vxlan
  spines  = local.spines
  l2_vnis = local.l2_vnis

  l2vni_subnet_policies            = local.l2vni_subnet_policies
  evpn_ipv4_advertisement_policies = local.evpn_ipv4_advertisement_policies
}

module "greatfox_leaf_vms" {
  for_each  = { for name, node in var.fabric.leaves_greatfox : name => node if node.configure }
  source    = "./pve_leaves"
  providers = { vyos = vyos.greatfox }
  node      = local.greatfox_leaves[each.key]
  dns       = var.dns

  bgp_l2vpn = var.fabric.bgp_l2vpn
  vnis      = var.vnis

  vxlan   = var.fabric.vxlan
  spines  = local.spines
  l2_vnis = local.l2_vnis

  l2vni_subnet_policies            = local.l2vni_subnet_policies
  evpn_ipv4_advertisement_policies = local.evpn_ipv4_advertisement_policies
}

module "pve_leaves_vms" {
  for_each  = { for name, node in var.fabric.leaves : name => node if node.configure }
  source    = "./pve_leaves"
  providers = { vyos = vyos.leaves[each.key] }
  node      = local.pve_leaves[each.key]
  dns       = var.dns

  bgp_l2vpn = var.fabric.bgp_l2vpn
  vnis      = var.vnis

  vxlan   = var.fabric.vxlan
  spines  = local.spines
  l2_vnis = local.l2_vnis

  l2vni_subnet_policies            = local.l2vni_subnet_policies
  evpn_ipv4_advertisement_policies = local.evpn_ipv4_advertisement_policies
}
