external_l3 = {
  interface       = "eth3"
  peer_group_name = "FW_L3_out"
  remote_asn      = 420
}
external_l2 = {
  bond_slave     = "eth3"
  bond_interface = "bond0"
  bond_mode      = "802.3ad"
  lacp_rate      = "slow"
  esi = {
    esi_id           = 100
    esi_system_mac   = "bc:24:11:00:00:02"
    esi_df_pref_base = 1000
  }
}
