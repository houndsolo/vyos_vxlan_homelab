module "configure_fabric" {
  source = "./configure_fabric"

  fabric      = var.fabric
  dns         = var.dns
  vnis        = var.vnis
  vyos_key    = var.vyos_key
  external_l3 = var.external_l3
  external_l2 = var.external_l2
}

module "create_fabric_vms" {
  source = "./create_fabric_vms"

  fabric           = var.fabric
  dhcp             = var.dhcp
  dhcp_attachments = local.dhcp_attachments
  pve_api_token    = var.pve_api_token
  gf_api_token     = var.gf_api_token
  proxmox_vtep_vm  = var.proxmox_vtep_vm
}
