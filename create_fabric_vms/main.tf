module "create_vyos_vms" {
  for_each = merge(
    { for name, leaf in var.fabric.leaves : name => merge(leaf, { hostname = "vtep-${name}" }) if leaf.is_vm },
    { for name, leaf in var.fabric.border_leaves : name => merge(leaf, { hostname = "vtep-border-${leaf.id}" }) if leaf.is_vm },
    { for name, leaf in var.fabric.fabric_ext_leaves : name => merge(leaf, { hostname = "vtep-fabric-ext-${leaf.id}" }) if leaf.is_vm },
  )
  source          = "./proxmox_vteps"
  host_node       = each.value
  vm_config       = var.proxmox_vtep_vm
  fabric_defaults = var.fabric.defaults
}

module "create_vyos_vms_greatfox" {
  for_each = {
    for name, leaf in var.fabric.leaves_greatfox :
    name => merge(leaf, { hostname = "vtep-${name}" }) if leaf.is_vm
  }
  source          = "./proxmox_vteps"
  host_node       = each.value
  vm_config       = var.proxmox_vtep_vm
  fabric_defaults = var.fabric.defaults

  providers = {
    proxmox = proxmox.greatfox
  }
}

module "create_dhcp_vms" {
  for_each  = var.dhcp.nodes
  source    = "./proxmox_vteps"
  vm_config = var.proxmox_vtep_vm
  host_node = {
    hostname           = each.key
    id                 = each.value.id
    hypervisor_node    = each.value.hypervisor_node
    vm_id              = each.value.vm_id
    management_address = cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)
    started            = true
    tags               = ["opentofu", "debian", "vyos", "dhcp"]
    network_bridges    = [for vni in sort(keys(var.dhcp_attachments)) : var.dhcp_attachments[vni].bridge]
  }
  fabric_defaults = var.fabric.defaults
}
