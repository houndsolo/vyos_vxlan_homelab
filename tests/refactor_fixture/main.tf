terraform { required_version = ">= 1.9.0" }

locals {
  catalogue = {
    "6200" = { vni = 6200, roles = toset(["pve", "external_l2"]), l2 = { "2" = { vni = 9002 } } }
    "6666" = { vni = 6666, roles = toset(["external_l3"]), l2 = {} }
    "7777" = { vni = 7777, roles = toset(["unused"]), l2 = {} }
  }
  roles = ["pve", "external_l2", "external_l3", "empty"]
  selected = {
    for role in local.roles : role => {
      l3 = { for key, l3 in local.catalogue : key => l3 if contains(l3.roles, role) }
    }
  }
  l2 = {
    for role, selected in local.selected : role => merge([
      for l3_key, l3 in selected.l3 : {
        for l2_key, l2 in l3.l2 : tostring(l2.vni) => merge(l2, { l3_key = l3_key, l2_key = l2_key })
      }
    ]...)
  }
}

check "role_filtering" {
  assert {
    condition = (
      keys(local.selected.pve.l3) == ["6200"] &&
      keys(local.selected.external_l2.l3) == ["6200"] &&
      keys(local.selected.external_l3.l3) == ["6666"] &&
      local.selected.empty.l3 == {} &&
      keys(local.l2.pve) == ["9002"] &&
      local.l2.external_l3 == {} && local.l2.empty == {}
    )
    error_message = "Role filtering must handle empty roles and selected L3VNIs without L2 children."
  }
}
