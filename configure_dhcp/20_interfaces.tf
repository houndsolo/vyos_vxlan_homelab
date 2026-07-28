resource "vyos_interfaces_ethernet" "attachment" {
  for_each    = var.attachments
  identifier  = { ethernet = each.value.interface }
  address     = ["${cidrhost(each.value.subnet, var.node.service_host_offset)}/${split("/", each.value.subnet)[1]}"]
  description = "DHCP L2VNI ${each.value.vni} via ${each.value.bridge}"
  lifecycle {
    ignore_changes = [
      hw_id,
      offload
    ]
  }
}
