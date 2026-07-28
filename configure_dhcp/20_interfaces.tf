resource "vyos_interfaces_ethernet" "attachment" {
  for_each    = var.attachments
  identifier  = { ethernet = each.value.interface }
  address     = ["${cidrhost(cidrsubnet(each.value.subnet, 8, 10), var.node.id)}/${split("/", each.value.subnet)[1]}"]
  description = "DHCP L2VNI ${each.value.vni} via ${each.value.bridge}"
  lifecycle {
    Ignore_changes = [
      hw_id,
      offload
    ]
  }
}
