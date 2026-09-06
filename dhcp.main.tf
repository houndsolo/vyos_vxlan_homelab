locals {
  dhcp_segments = {
    for l2 in flatten([for l3 in values(local.vnis.l3) : values(l3.l2)]) :
    tostring(l2.vni) => l2 if l2.dhcp != null
  }
  dhcp_vnis = sort(keys(local.dhcp_segments))
  dhcp_attachments = {
    for vni, l2 in local.dhcp_segments : vni => {
      vni            = l2.vni
      interface      = "eth${index(local.dhcp_vnis, vni) + 1}"
      bridge         = "vmbr4000"
      vlan_id        = l2.vlan_id
      subnet         = cidrsubnet("${l2.anycast_gw_ip}/${l2.anycast_gw_cidr}", 0, 0)
      default_router = l2.anycast_gw_ip
      scope          = l2.dhcp.scope
    }
  }
  dhcp_scopes = { for vni, attachment in local.dhcp_attachments : vni => attachment if attachment.scope != null }
  dhcp_server_addresses = {
    for vni, attachment in local.dhcp_attachments : vni => {
      for name, node in var.dhcp.nodes : name => cidrhost(cidrsubnet(attachment.subnet, 8, 10), node.id)
    }
  }
}

provider "vyos" {
  alias    = "dhcp_nodes"
  for_each = var.dhcp.nodes
  endpoint = "https://${cidrhost(var.fabric.defaults.vyos_mgmt_prefix, each.value.id)}"
  api_key  = var.vyos_key
  certificate = {
    disable_verify = var.fabric.defaults.vyos_provider_disable_verify
  }
  default_timeouts                       = var.fabric.defaults.vyos_provider_default_timeouts
  overwrite_existing_resources_on_create = var.fabric.defaults.vyos_overwrite_existing_on_create
}

module "configure_dhcp" {
  for_each = { for name, node in var.dhcp.nodes : name => node if node.configure }
  source   = "./configure_dhcp"

  node_name   = each.key
  node        = each.value
  nodes       = var.dhcp.nodes
  dhcp        = var.dhcp
  attachments = local.dhcp_attachments
  dns         = var.dns

  providers = { vyos = vyos.dhcp_nodes[each.key] }
  #  depends_on = [module.create_fabric_vms]
}

check "dhcp_attachment_invariants" {
  assert {
    condition = (
      contains(keys(local.dhcp_attachments), tostring(var.dhcp.ha.l2vni)) &&
      alltrue([for attachment in values(local.dhcp_attachments) : attachment.vni > 9000 && attachment.vni < 10000])
    )
    error_message = "The HA L2VNI must be attached and DHCP attachment VNIs must use the 900X naming range."
  }
  assert {
    condition = alltrue([
      for attachment in values(local.dhcp_attachments) :
      cidrcontains(attachment.subnet, attachment.default_router) &&
      alltrue([for address in values(local.dhcp_server_addresses[tostring(attachment.vni)]) : cidrcontains(attachment.subnet, address)])
    ])
    error_message = "Every anycast gateway and derived DHCP server address must belong to its attachment subnet."
  }
  assert {
    condition = alltrue(flatten([
      for vni, attachment in local.dhcp_scopes : [
        length(attachment.scope.ranges) > 0,
        [for range in values(attachment.scope.ranges) :
          cidrcontains(attachment.subnet, range.start) && cidrcontains(attachment.subnet, range.stop) &&
          range.start != attachment.default_router && range.stop != attachment.default_router &&
          alltrue([for address in values(local.dhcp_server_addresses[vni]) : range.start != address && range.stop != address])
        ]
      ]
    ]))
    error_message = "Scopes need ranges whose endpoints are in-subnet and do not equal the gateway or a DHCP server address."
  }
}
