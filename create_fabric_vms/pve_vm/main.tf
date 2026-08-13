moved {
  from = proxmox_virtual_environment_vm.vyos_vxlan_vtep
  to   = proxmox_virtual_environment_vm.vm
}

resource "proxmox_virtual_environment_vm" "vm" {
  name            = var.host_node.hostname
  description     = "managed by opentofu"
  tags            = coalesce(var.host_node.tags, ["opentofu", "debian", "vyos", "vxlan"])
  started         = var.host_node.started
  keyboard_layout = "en-us"
  migrate         = false
  on_boot         = true
  reboot          = false
  stop_on_destroy = true

  node_name = var.host_node.hypervisor_node
  vm_id     = coalesce(var.host_node.vm_id, var.host_node.id + 700)

  agent {
    enabled = true
  }

  boot_order = [
    "virtio0",
  ]

  disk {
    datastore_id = var.vm_config.datastore_id
    import_from  = var.vm_config.import_image
    interface    = "virtio0"
    iothread     = true
    size         = var.vm_config.disk_size_gb
  }

  initialization {
    interface         = "scsi0"
    datastore_id      = var.vm_config.cloud_init_datastore_id
    user_data_file_id = var.vm_config.user_data_file_id
    ip_config {
      ipv4 {
        address = "${coalesce(var.host_node.management_address, cidrhost(var.fabric_defaults.vyos_mgmt_prefix, var.host_node.id))}/${var.fabric_defaults.vyos_mgmt_cidr}"
      }
    }
  }

  network_device {
    disconnected = false
    bridge       = var.vm_config.management_bridge
    model        = "virtio"
  }

  dynamic "network_device" {
    for_each = var.host_node.network_devices
    content {
      disconnected = false
      bridge       = network_device.value.bridge
      vlan_id      = network_device.value.vlan_id
      model        = "virtio"
      mtu          = 1
    }
  }

  serial_device {}

  cpu {
    #  architecture = "x86_64"
    cores      = var.vm_config.cpu_cores
    flags      = []
    hotplugged = 0
    limit      = 0
    numa       = false
    sockets    = 1
    type       = var.vm_config.cpu_type
    units      = 1024
  }

  memory {
    dedicated      = var.vm_config.memory_mb
    floating       = 0
    keep_hugepages = false
    shared         = 0
  }

  operating_system {
    type = "l26"
  }

  vga {
    #enabled = false
    memory = 16
    type   = "std"
  }
  timeout_clone       = 1800
  timeout_create      = 1800
  timeout_migrate     = 1800
  timeout_reboot      = 1800
  timeout_shutdown_vm = 1800
  timeout_start_vm    = 1800
  timeout_stop_vm     = 300

  lifecycle {
    ignore_changes = [
      #network_device[6].disconnected,
      initialization[0].user_account, # This ignores changes to the user_account block within initialization
      #vga[0].enabled,  # This ignores changes to the user_account block within initialization
    ]
  }
}
