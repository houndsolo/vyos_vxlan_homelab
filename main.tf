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
  fabric_macs = {
    for node in concat(values(var.fabric.leaves), values(var.fabric.border_leaves), values(var.fabric.fabric_ext_leaves), values(var.fabric.leaves_greatfox)) :
    node.id => {
      for interface_number in range(1, 4) :
      "eth${interface_number}" => format("02:70:%02x:%02x:00:%02x", floor(node.id / 256), node.id % 256, interface_number)
    }
  }

  fabric = merge(var.fabric, {
    leaves = {
      for name, node in var.fabric.leaves : name => merge(node, {
        fabric_macs = local.fabric_macs[node.id]
      })
    }
    border_leaves = {
      for name, node in var.fabric.border_leaves : name => merge(node, {
        fabric_macs = local.fabric_macs[node.id]
      })
    }
    fabric_ext_leaves = {
      for name, node in var.fabric.fabric_ext_leaves : name => merge(node, {
        fabric_macs = local.fabric_macs[node.id]
      })
    }
    leaves_greatfox = {
      for name, node in var.fabric.leaves_greatfox : name => merge(node, {
        fabric_macs = local.fabric_macs[node.id]
      })
    }
  })
}
