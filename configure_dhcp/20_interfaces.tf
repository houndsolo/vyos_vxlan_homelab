resource "vyos_interfaces_ethernet" "attachment" {
  for_each    = var.attachments
  identifier  = { ethernet = each.value.interface }
  address     = ["${cidrhost(cidrsubnet(each.value.subnet, 8, 10), var.node.id)}/${split("/", each.value.subnet)[1]}"]
  description = "DHCP L2VNI ${each.value.vni} via ${each.value.bridge}"
  hw_id       = format("02:70:00:%02x:%02x:%02x", var.node.ha_role == "primary" ? 1 : 2, floor(each.value.vlan_id / 256), each.value.vlan_id % 256)
  lifecycle {
    ignore_changes = [
      offload
    ]
  }
}
