module "configure_fabric" {
  source = "./configure_fabric"

  fabric      = local.fabric
  dns         = var.dns
  vnis        = var.vnis
  vyos_key    = var.vyos_key
  external_l3 = var.external_l3
  external_l2 = var.external_l2
}

module "create_fabric_vms" {
  source = "./create_fabric_vms"

  fabric           = local.fabric
  dhcp             = var.dhcp
  dhcp_attachments = local.dhcp_attachments
  pve_api_token    = var.pve_api_token
  gf_api_token     = var.gf_api_token
  proxmox_vtep_vm  = var.proxmox_vtep_vm
}

locals {
  fabric_node_groups = {
    leaves            = var.fabric.leaves
    border_leaves     = var.fabric.border_leaves
    fabric_ext_leaves = var.fabric.fabric_ext_leaves
    leaves_greatfox   = var.fabric.leaves_greatfox
  }

  fabric = merge(var.fabric, {
    for group_name, nodes in local.fabric_node_groups : group_name => {
      for name, node in nodes : name => merge(node, {
        fabric_macs = {
          for interface_number in range(1, 4) :
          "eth${interface_number}" => join(":", regexall("..", format(
            "02%04d%04d%02d",
            var.fabric.defaults.underlay_local_as_base + node.id,
            node.id,
            interface_number,
          )))
        }
      })
    }
  })
}
