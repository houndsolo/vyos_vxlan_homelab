resource "vyos_interfaces_ethernet" "link_to_vms" {
  depends_on  = [module.leaf_l2_common]
  identifier  = { ethernet = "eth3" }
  description = "link to L2 switch"
  mtu         = var.vxlan.mtu
  lifecycle {
    ignore_changes = [
      hw_id,
      offload
    ]
  }
}

resource "vyos_interfaces_ethernet_vif" "eth_3_vifs" {
  depends_on = [
    module.leaf_l2_common
  ]
  for_each = var.l2_vnis
  identifier = {
    ethernet = "eth3"
    vif      = each.value.vlan_id
  }
}

resource "vyos_interfaces_bridge_member_interface" "br0_eth3" {
  depends_on = [
    vyos_interfaces_ethernet_vif.eth_3_vifs,
    module.leaf_l2_common,
  ]

  for_each = var.l2_vnis
  identifier = {
    bridge    = "br${each.value.vni}"
    interface = "eth3.${each.value.l2_key}"
  }
}

resource "vyos_interfaces_pseudo_ethernet" "peth_dag_test" {
  identifier  = { pseudo_ethernet = "peth69" }
  description = "testing"
  mtu         = var.vxlan.mtu
  source_interface = "br69"
  anycast_gateway = true
  mac = "bc:24:11:69:69:69"
  depends_on = [vyos_interfaces_bridge.test_bridge]
  lifecycle {
    ignore_changes = [
    ]
  }
}

resource "vyos_interfaces_bridge" "test_bridge" {
  identifier = { bridge = "br69" }
  mtu         = var.vxlan.mtu
}


