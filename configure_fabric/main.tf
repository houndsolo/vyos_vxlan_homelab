module "spines" {
  for_each  = { for name, node in var.fabric.nodes.spines : name => node if node.configure }
  source    = "./spines_mikrotik"
  node      = var.fabric.nodes.spines[each.key]
  providers = { routeros = routeros.spines[each.key] }
  fabric    = var.fabric
}

module "border_leaves" {
  for_each  = { for name, node in local.leaves_by_role.external_l3 : name => node if node.configure }
  source    = "./border_leaves"
  providers = { vyos = vyos.border_leaves[each.key] }
  node      = local.leaves_by_role.external_l3[each.key]
  dns       = var.dns

  bgp_l2vpn   = var.fabric.bgp_l2vpn
  vnis        = local.vnis_by_role.external_l3
  external_l3 = var.external_l3

  vxlan  = var.fabric.vxlan
  spines = local.spines
}

module "fabric_ext_leaf_vms" {
  for_each  = { for name, node in local.leaves_by_role.external_l2 : name => node if node.configure }
  source    = "./fabric_leaves_trunk"
  providers = { vyos = vyos.fabric_leaves[each.key] }
  node      = local.leaves_by_role.external_l2[each.key]
  dns       = var.dns

  bgp_l2vpn   = var.fabric.bgp_l2vpn
  vnis        = local.vnis_by_role.external_l2
  external_l2 = var.external_l2

  vxlan   = var.fabric.vxlan
  spines  = local.spines
  l2_vnis = local.l2_vnis_by_role.external_l2

  l2vni_subnet_policies            = local.l2vni_subnet_policies_by_role.external_l2
  evpn_ipv4_advertisement_policies = local.evpn_ipv4_advertisement_policies_by_role.external_l2
}

module "greatfox_leaf_vms" {
  for_each  = { for name, node in { for name, node in local.leaves_by_role.pve : name => node if node.proxmox_target == "greatfox" } : name => node if node.configure }
  source    = "./pve_leaves"
  providers = { vyos = vyos.greatfox }
  node      = local.leaves_by_role.pve[each.key]
  dns       = var.dns

  bgp_l2vpn = var.fabric.bgp_l2vpn
  vnis      = local.vnis_by_role.pve

  vxlan   = var.fabric.vxlan
  spines  = local.spines
  l2_vnis = local.l2_vnis_by_role.pve

  l2vni_subnet_policies            = local.l2vni_subnet_policies_by_role.pve
  evpn_ipv4_advertisement_policies = local.evpn_ipv4_advertisement_policies_by_role.pve
}

module "pve_leaves_vms" {
  for_each  = { for name, node in local.leaves_by_role.pve : name => node if node.configure && node.proxmox_target == "pve" }
  source    = "./pve_leaves"
  providers = { vyos = vyos.leaves[each.key] }
  node      = local.leaves_by_role.pve[each.key]
  dns       = var.dns

  bgp_l2vpn = var.fabric.bgp_l2vpn
  vnis      = local.vnis_by_role.pve

  vxlan   = var.fabric.vxlan
  spines  = local.spines
  l2_vnis = local.l2_vnis_by_role.pve

  l2vni_subnet_policies            = local.l2vni_subnet_policies_by_role.pve
  evpn_ipv4_advertisement_policies = local.evpn_ipv4_advertisement_policies_by_role.pve
}
