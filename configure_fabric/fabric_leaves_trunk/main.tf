module "leaf_common" {
  source = "../leaf_common"

  providers = { vyos = vyos }

  node                   = var.node
  dns                    = var.dns
  bgp_l2vpn              = var.bgp_l2vpn
  vnis                   = var.vnis
  vxlan                  = var.vxlan
  spines                 = var.spines
  l2_vnis                = var.l2_vnis
  ipv4_vpn_export_policy = var.ipv4_vpn_export_policy
}

module "leaf_l2_common" {
  source = "../leaf_l2_common"

  providers = { vyos = vyos }

  depends_on = [
    module.leaf_common,
    vyos_vrf_name.create_vrfs
  ]

  node                   = var.node
  dns                    = var.dns
  bgp_l2vpn              = var.bgp_l2vpn
  vnis                   = var.vnis
  vxlan                  = var.vxlan
  spines                 = var.spines
  l2_vnis                = var.l2_vnis
  ipv4_vpn_export_policy = var.ipv4_vpn_export_policy
}
