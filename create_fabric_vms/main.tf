module "create_leaf_vms" {
  for_each = { for name, leaf in var.fabric.leaves : name => merge(leaf, { hostname = "vtep-${name}" }) if leaf.is_vm }
  source   = "./pve_vm"
  host_node = merge(each.value, {
    network_devices = [for index, bridge in coalesce(each.value.underlay_bridges, var.proxmox_vtep_vm.default_underlay_bridges) : {
      bridge      = bridge
      mac_address = each.value.fabric_macs["eth${index + 1}"]
    }]
  })
  vm_config       = var.proxmox_vtep_vm
  fabric_defaults = var.fabric.defaults
}

module "create_border_leaf_vms" {
  for_each = { for name, leaf in var.fabric.border_leaves : name => merge(leaf, { hostname = "vtep-border-${leaf.id}" }) if leaf.is_vm }
  source   = "./pve_vm"
  host_node = merge(each.value, {
    network_devices = [for index, bridge in coalesce(each.value.underlay_bridges, var.proxmox_vtep_vm.default_underlay_bridges) : {
      bridge      = bridge
      mac_address = each.value.fabric_macs["eth${index + 1}"]
    }]
  })
  vm_config       = var.proxmox_vtep_vm
  fabric_defaults = var.fabric.defaults
}

module "create_fabric_ext_leaf_vms" {
  for_each = { for name, leaf in var.fabric.fabric_ext_leaves : name => merge(leaf, { hostname = "vtep-fabric-ext-${leaf.id}" }) if leaf.is_vm }
  source   = "./pve_vm"
  host_node = merge(each.value, {
    network_devices = [for index, bridge in coalesce(each.value.underlay_bridges, var.proxmox_vtep_vm.default_underlay_bridges) : {
      bridge      = bridge
      mac_address = each.value.fabric_macs["eth${index + 1}"]
    }]
  })
  vm_config       = var.proxmox_vtep_vm
  fabric_defaults = var.fabric.defaults
}

module "create_greatfox_leaf_vms" {
  for_each = { for name, leaf in var.fabric.leaves_greatfox : name => merge(leaf, { hostname = "vtep-${name}" }) if leaf.is_vm }
  source   = "./pve_vm"
  host_node = merge(each.value, {
    network_devices = [for index, bridge in coalesce(each.value.underlay_bridges, var.proxmox_vtep_vm.default_underlay_bridges) : {
      bridge      = bridge
      mac_address = each.value.fabric_macs["eth${index + 1}"]
    }]
  })
  vm_config       = var.proxmox_vtep_vm
  fabric_defaults = var.fabric.defaults

  providers = { proxmox = proxmox.greatfox }
}

module "create_dhcp_vms" {
  for_each  = var.dhcp.nodes
  source    = "./pve_vm"
  vm_config = var.proxmox_vtep_vm
  host_node = {
    hostname           = each.key
    id                 = each.value.id
    hypervisor_node    = each.value.hypervisor_node
    vm_id              = each.value.vm_id
    management_address = cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)
    started            = each.value.started
    tags               = ["opentofu", "debian", "vyos", "dhcp"]
    network_devices = [for vni in sort(keys(var.dhcp_attachments)) : {
      bridge  = var.dhcp_attachments[vni].bridge
      vlan_id = var.dhcp_attachments[vni].vlan_id
    }]
  }
  fabric_defaults = var.fabric.defaults
}
