provider "routeros" {
  alias    = "spines"
  for_each = var.fabric.spines
  hosturl  = each.value.hosturl
  username = "admin"
  password = "admin"
  insecure = true
}

provider "vyos" {
  alias    = "leaves"
  for_each = var.fabric.leaves
  endpoint = "https://${cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)}"
  api_key  = var.vyos_key
  certificate = {
    disable_verify = var.fabric.defaults.vyos_provider_disable_verify
  }
  default_timeouts                       = var.fabric.defaults.vyos_provider_default_timeouts
  overwrite_existing_resources_on_create = var.fabric.defaults.vyos_overwrite_existing_on_create
  manual_binding_overrides = {

    "protocols bgp"                           = "bgp"
    "protocols bgp address-family l2vpn-evpn" = "bgp-evpn"
    "protocols bgp address-family ipv4-vpn"   = "bgp-vpnv4"

    "vrf"               = "vrf"
    "interfaces vxlan"  = "vxlan"
    "interfaces bridge" = "bridge"
  }
}

provider "vyos" {
  alias    = "fabric_leaves"
  for_each = var.fabric.fabric_ext_leaves
  endpoint = "https://${cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)}"
  api_key  = var.vyos_key
  certificate = {
    disable_verify = var.fabric.defaults.vyos_provider_disable_verify
  }
  default_timeouts                       = var.fabric.defaults.vyos_provider_default_timeouts
  overwrite_existing_resources_on_create = var.fabric.defaults.vyos_overwrite_existing_on_create
  manual_binding_overrides = {

    "protocols bgp"                           = "bgp"
    "protocols bgp address-family l2vpn-evpn" = "bgp-evpn"
    "protocols bgp address-family ipv4-vpn"   = "bgp-vpnv4"

    "vrf"               = "vrf"
    "interfaces vxlan"  = "vxlan_bridges"
    "interfaces bridge" = "vxlan_bridges"
  }
}

provider "vyos" {
  alias    = "spines"
  for_each = var.fabric.spines
  endpoint = "https://${cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)}"
  api_key  = var.vyos_key
  certificate = {
    disable_verify = var.fabric.defaults.vyos_provider_disable_verify
  }
  default_timeouts                       = var.fabric.defaults.vyos_provider_default_timeouts
  overwrite_existing_resources_on_create = var.fabric.defaults.vyos_overwrite_existing_on_create
  manual_binding_overrides = {

    "protocols mpls" = "mpls"

    "protocols bgp"                           = "bgp"
    "protocols bgp address-family l2vpn-evpn" = "bgp-evpn"
    "protocols bgp address-family ipv4-vpn"   = "bgp-vpnv4"

    "vrf"               = "vrf"
    "interfaces vxlan"  = "vxlan"
    "interfaces bridge" = "bridge"
  }
}

provider "vyos" {
  alias    = "greatfox"
  endpoint = "https://${cidrhost(var.fabric.defaults.vyos_mgmt_prefix, one(values(var.fabric.leaves_greatfox)).id)}"
  api_key  = var.vyos_key
  certificate = {
    disable_verify = var.fabric.defaults.vyos_provider_disable_verify
  }
  default_timeouts                       = var.fabric.defaults.vyos_provider_default_timeouts
  overwrite_existing_resources_on_create = var.fabric.defaults.vyos_overwrite_existing_on_create
  manual_binding_overrides = {

    "protocols bgp"                           = "bgp"
    "protocols bgp address-family l2vpn-evpn" = "bgp-evpn"
    "protocols bgp address-family ipv4-vpn"   = "bgp-vpnv4"

    "vrf"               = "vrf"
    "interfaces vxlan"  = "vxlan"
    "interfaces bridge" = "bridge"
  }
}

provider "vyos" {
  alias    = "border_leaves"
  for_each = var.fabric.border_leaves
  endpoint = "https://${cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)}"
  api_key  = var.vyos_key
  certificate = {
    disable_verify = var.fabric.defaults.vyos_provider_disable_verify
  }
  default_timeouts                         = var.fabric.defaults.vyos_provider_default_timeouts
  overwrite_existing_resources_on_create   = var.fabric.defaults.vyos_overwrite_existing_on_create
  ignore_missing_parent_resource_on_create = true

  # Batch all MPLS resources into one VyOS configure/commit transaction.
  manual_binding_overrides = {
    "protocols mpls"     = "mpls"
    "protocols mpls ldp" = "mpls"

    "protocols bgp"                           = "bgp"
    "protocols bgp address-family l2vpn-evpn" = "bgp-evpn"
    "protocols bgp address-family ipv4-vpn"   = "bgp-vpnv4"

    "vrf"               = "vrf"
    "interfaces vxlan"  = "vxlan"
    "interfaces bridge" = "bridge"
  }
}
