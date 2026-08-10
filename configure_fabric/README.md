# Fabric configuration internals

This module converts the root fabric/VNI intent into per-node values and applies VyOS configuration. It currently instantiates **border leaves** and **fabric-extension leaves**. Standard and `greatfox` leaves are present in inventory/provider setup but are not instantiated in `main.tf`.

## Data flow

1. `vars.tf` derives ASNs, IPv4/IPv6 loopbacks, hostnames, bridge names, and reusable policy names from the root inputs.
2. `main.tf` selects enabled node roles and passes their derived values to role modules.
3. Each role composes `leaf_common` and `leaf_l2_common`, then adds role-specific resources.
4. Provider aliases in `providers.tf` direct each module instance to the correct VyOS management endpoint.

## Module ownership

```text
configure_fabric/
├── leaf_common/       system settings, underlay interfaces, prefix/route policy,
│                     underlay BGP, and EVPN overlay BGP
├── leaf_l2_common/    L2/L3 VXLAN interfaces, shared bridge, bridge membership,
│                     and anycast-gateway SVIs
├── pve_leaves/        normal leaf VRF/L3VNI policy and VM-facing access on eth3
└── border_leaves/     border VRF/L3VNI policy and external per-VRF BGP on VLANs
```

The two role modules intentionally retain separate `40_vrf_l3vni.tf` files: border leaves have VPN import/export and EVPN advertisement policy that ordinary leaves do not share. Everything genuinely common is composed through the two shared modules.

## Underlay and overlay

The physical topology uses two switches and two MikroTik route reflectors. Each leaf can reach both route reflectors through redundant paths. Underlay interfaces use IPv6 router advertisements/link-local addresses and eBGP; overlay sessions use derived IPv6 loopbacks in the shared AS.

The default derivation is:

```text
underlay local ASN = underlay_local_as_base + node_id
IPv4 VTEP          = cidrhost(ipv4_loopback_prefix, node_id)/32
IPv6 overlay       = cidrhost(ipv6_underlay_prefix, hexadecimal(node_id))/128
router MAC (RMAC)  = 00:13:37:00:00:<zero-padded node_id>
```

The shared `leaf_l2_common` module derives the RMAC once per leaf and applies
the same value to both `br0` and `vxlan0`.

The hexadecimal conversion preserves the lab's established IPv6 address convention. Do not replace it with a decimal host offset without planning an addressing migration.

## VXLAN and VRFs

- `leaf_l2_common` flattens nested L2 intent supplied by the parent and creates one VXLAN interface per L2VNI and L3VNI.
- L2 interfaces attach to the shared service bridge; L3 interfaces attach to their VRFs.
- Bridge VIFs carry the anycast gateway addresses and MACs.
- A VRF gains external connectivity only when its L3 intent includes `ext_l3_vlan`.
- Border external BGP uses an IPv6 link-local interface neighbor in the configured peer group.

## State compatibility

Shared resources once lived directly in role modules. Their current addresses include a nested module, for example:

```text
module.configure_fabric.module.border_leaves["border-1"].module.leaf_common...
module.configure_fabric.module.fabric_ext_leaf_vms["fabric-1"].module.leaf_l2_common...
```

If migrating older state, inspect it with `tofu state list` and move matching addresses with `tofu state mv`; otherwise OpenTofu may propose delete/recreate operations. Never copy state blindly between nodes, because provider instances and node-specific identifiers differ.

## Known limitation

Direct redistribution of EVPN host routes into IPv4-VPN has not worked reliably in this lab. The proven direction is IPv4-VPN import into VRF IPv4 unicast followed by EVPN advertisement. Treat changes to route maps, route targets, and the border import/export booleans as reachability/security changes and inspect the plan carefully.
