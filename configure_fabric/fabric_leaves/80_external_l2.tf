resource "vyos_interfaces_ethernet" "ext_l3" {
  identifier  = { ethernet = var.external_l2.bond_slave }
  description = "ext_l2"
  mtu         = var.vxlan.mtu
  lifecycle {
    ignore_changes = [
      hw_id,
      offload
    ]
  }
}

resource "vyos_interfaces_bonding" "l2out_esi_bond" {
  identifier = { bonding = var.external_l2.bond_interface }
  system_mac = var.external_l2.esi.esi_system_mac
  mode = var.external_l2.bond_mode
  member = {
    interface = [var.external_l2.bond_slave]
  }
  lacp_rate = var.external_l2.lacp_rate
  mtu         = var.vxlan.mtu
  #evpn = {
  #  uplink = true
  #  es_id = var.external_l2.esi.esi_id
  #  es_sys_mac = var.external_l2.esi.esi_system_mac
  #  es_df_pref = var.external_l2.esi.esi_df_pref_base + var.node.id
  #}
}

resource "vyos_interfaces_bonding_vif" "l2out_esi_bond_vifs" {
  depends_on = [
    module.leaf_l2_common,
    vyos_interfaces_bonding.l2out_esi_bond
  ]

  for_each = var.l2_vnis
  mtu         = var.vxlan.mtu
  identifier = {
    bonding    = var.external_l2.bond_interface
    vif = each.value.l2_key
  }
}

resource "vyos_interfaces_bridge_member_interface" "br0_bond0" {
  depends_on = [
    module.leaf_l2_common,
    vyos_interfaces_bonding_vif.l2out_esi_bond_vifs
  ]

  for_each = var.l2_vnis
  identifier = {
    bridge    = "br${each.value.vni}"
    interface = "${var.external_l2.bond_interface}.${each.value.l2_key}"
  }
}
