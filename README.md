# VyOS EVPN/VXLAN homelab

OpenTofu configuration for a small VyOS/FRR EVPN-VXLAN fabric hosted primarily on Proxmox. Two MikroTik CRS326 switches act as out-of-band-managed EVPN route reflectors; this repository creates VyOS VMs and configures the VyOS leaf roles.

> **Lab-specific repository:** committed `.auto.tfvars` files contain real topology and addressing intent, but not credentials. Review them before applying anywhere other than this lab.

## What is managed

The root configuration invokes three independent modules:

| Module | Responsibility |
| --- | --- |
| `create_fabric_vms` | Creates virtual standard, border, extension, and `greatfox` leaves in Proxmox. Bare-metal inventory entries are skipped. |
| `configure_fabric` | Configures the currently enabled border leaves through the VyOS API. |
| `configure_dhcp` | Configures only the two dedicated VyOS Kea DHCP nodes: system identity/DNS, physical service interfaces, scopes, HA, and disabled IPv4 forwarding. |

Standard, fabric-extension, and `greatfox` leaves have provider definitions, but their configuration module calls are not enabled. The MikroTik spines are inventory/peering targets only and are configured outside this repository. This distinction is important: an apply does **not** configure every entry in `fabric`.

### Design at a glance

- IPv6 link-local eBGP provides the routed underlay.
- IPv4 VTEP loopbacks use `10.255.240.<node_id>/32` by default.
- IPv6 overlay addresses are derived from `fd69:255:240::/64`.
- EVPN peers use the shared BGP AS `700`; underlay local ASNs are `700 + node_id`.
- L2VNIs share bridge `br9000`; L3VNIs map to VRFs.
- Border leaves provide optional per-VRF external L3 connectivity over VLAN subinterfaces.
- Route distinguishers are unique per VTEP (`<router-id>:<vni>`), while route targets are shared per service (`target:<fabric-as>:<vni>`).

See [`configure_fabric/README.md`](configure_fabric/README.md) for module ownership and routing details.

## Repository map

```text
.
├── main.tf                       # root module wiring
├── vars.tf                       # public input contracts
├── versions.tf                  # provider constraints
├── fabric.auto.tfvars           # nodes, fabric defaults, VRFs, and VNIs
├── proxmox_vm.auto.tfvars       # VM sizing, storage, bridges, and DNS
├── dhcp.auto.tfvars             # DHCP defaults, HA selection, and node inventory
├── external_l3.auto.tfvars      # border-leaf upstream settings
├── configure_fabric/
│   ├── leaf_common/             # system, underlay, and BGP EVPN
│   ├── leaf_l2_common/          # VXLAN devices, bridges, and SVIs
│   ├── pve_leaves/              # ordinary/extension leaf role
│   └── border_leaves/           # border policy and external routing
├── configure_dhcp/              # isolated VyOS DHCP system/interface/Kea/HA configuration
└── create_fabric_vms/
    └── proxmox_vteps/           # one VyOS VM resource
```

`single_vrf_fabric.auto.tfvars.no` is a disabled alternative intent file retained as a reference. OpenTofu does not load it because its suffix is not `.tfvars`.

## Prerequisites

- OpenTofu (the commands in this repository intentionally use `tofu`, not `terraform`).
- Access to the Proxmox APIs and VyOS HTTPS APIs referenced by the committed lab settings.
- The provider plugins declared in `versions.tf`. The Proxmox provider uses the custom source `local/mechanic/proxmox`, so it must be installed in your OpenTofu provider mirror.
- `~/.ssh/id_rsa` authorized as `root` on the Proxmox targets.
- Existing Proxmox storage objects, bridges, VyOS image, and cloud-init snippet named in `proxmox_vm.auto.tfvars`.
- MikroTik RouterOS 7.24.1 or newer on the route reflectors (the lab depends on an EVPN route-reflector fix).

## Credentials

Supply all three sensitive root variables without committing them:

```bash
export TF_VAR_vyos_key='...'
export TF_VAR_pve_api_token='...'
export TF_VAR_gf_api_token='...'
```

The credentials are:

- `vyos_key`: VyOS HTTPS API key.
- `pve_api_token`: API token for the primary Proxmox cluster.
- `gf_api_token`: API token for the separate `greatfox` Proxmox endpoint.

State and plan files can also contain secrets. The included `.gitignore` excludes common local state, plan, override, and credential files; use a secure remote state backend if this evolves beyond a personal lab.

## Workflow

```bash
# Install modules/providers and create/update the dependency lock file.
tofu init

# Normalize and statically check configuration.
tofu fmt -recursive
tofu validate

# Always inspect the proposed device and VM changes.
tofu plan -out=lab.tfplan

# Apply exactly the reviewed plan.
tofu apply lab.tfplan
```

Convenience targets are available as `make fmt`, `make fmt-check`, `make init`, `make validate`, and `make check`.

Because VM creation and device configuration are root sibling modules, OpenTofu may operate on them concurrently. On a first deployment, create/reach the VyOS VMs before enabling their configuration module calls. On an established lab, normal plan/apply is appropriate.

## Editing the lab

### Nodes

Edit the appropriate map in `fabric.auto.tfvars`:

```hcl
leaves = {
  newleaf = { hypervisor_node = "newleaf", id = 21, is_vm = true }
}
```

- `id` drives VM ID (`700 + id`), BGP local AS, loopback addresses, and management address.
- `hypervisor_node` is required for VMs.
- `is_vm = false` prevents VM creation.
- `underlay_bridges` overrides the default Proxmox bridge list.
- `underlay_peer_vlan` is used by fabric-extension underlay interfaces.

Node IDs must therefore be unique and fit all configured CIDR ranges. A spine needs an `id` and `uplink_if`; its overlay address is derived from its ID.

For a configured border or fabric-extension leaf, set `configure = false` and
apply once before removing its inventory entry. This retains the dynamic VyOS
provider while OpenTofu removes that node's configuration resources.

### VRFs and VNIs

Edit `vnis.l3` in `fabric.auto.tfvars`. Each L3 entry describes a VRF, table, L3VNI, EVPN route targets, optional VPN import/export behavior, and optional `ext_l3_vlan`. Nested `l2` entries describe VLAN/VNI pairs, anycast gateways/MACs, and advertisement/export switches.

Useful conventions:

- Keep one L3VNI and table number per VRF.
- Keep one L2VNI per VLAN and ensure VNI/VLAN values are unique.
- Use a unique anycast MAC and valid gateway CIDR for each L2 segment.
- Omit `ext_l3_vlan` for an internal-only VRF.
- Carefully review RT imports: they define which tenant routes can cross policy boundaries.

### VM defaults

Edit `proxmox_vm.auto.tfvars` for image, storage, cloud-init, management/underlay bridges, CPU, memory, and disk defaults. Per-node underlay bridges remain in `fabric.auto.tfvars`.

### DHCP architecture

DHCP intent lives with each L2VNI rather than in a duplicate scope map. The outer
`dhcp` object attaches both DHCP VMs to that L2VNI. Attachments are ordered by
VNI, and VNI 900X uses the existing Proxmox SDN bridge `vnetX`. An optional nested `scope` enables
Kea service on that interface. The configuration derives the normalized subnet,
gateway, Kea subnet ID, server addresses, DNS/domain defaults, interface name,
and bridge name from the L2VNI, root DNS, and DHCP cluster objects.

The fixed layout is:

| Interface | Existing Proxmox bridge | Function | Derived node addresses |
| --- | --- | --- | --- |
| `eth0` | management bridge from `proxmox_vm.auto.tfvars` | VyOS management/API | management prefix host IDs 251 and 252 |
| `eth1` | `vnet6` | HA only (no client scope) | `10.6.10.251/16`, `10.6.10.252/16` |
| `eth2` | `vnet8` | L2VNI 9008 scope | `10.8.10.251/16`, `10.8.10.252/16` |
| `eth3` | `vnet9` | L2VNI 9009 scope | `10.9.10.251/16`, `10.9.10.252/16` |

This dedicated-interface design creates no VLAN subinterfaces and contains no
separately maintained NIC indexes. `vnet6`, `vnet8`, and `vnet9` must
already exist on both `titania` and `zoness`; this configuration deliberately
does not manage Proxmox Linux bridges. The HA peers communicate over L2VNI 9006
and require TCP port 647 between `10.6.10.251` and `10.6.10.252`.

IPv4 forwarding is disabled on both DHCP nodes. Because their physical NICs are
directly attached to L2VNIs in different fabric VRFs, forwarding could otherwise
turn a DHCP server into an unintended inter-VRF transit router.

Before removing a DHCP node from the inventory, set its optional `configure`
field to `false` and apply once. This destroys its VyOS configuration while its
dynamic provider instance still exists; the inventory entry can then be removed
in a subsequent change without orphaning provider-managed resources.

Useful DHCP checks on either VyOS node:

```text
show configuration commands | match 'service dhcp-server'
show dhcp server leases
show dhcp server statistics
show log | match 'kea|dhcp'
sudo journalctl -u kea-dhcp4-server --since today
sudo ss -ntp | grep ':647'
```

## Operations and troubleshooting

Useful VyOS/FRR checks:

```text
show bgp summary
show bgp ipv4 vpn
show bgp l2vpn evpn summary
show bgp l2vpn evpn route
show ip route vrf all
monitor traffic interface any filter 'port not 22'
```

Useful MikroTik checks:

```routeros
/routing/bgp/session/print detail
/routing/route/print detail where afi=evpn
/routing/bgp/advertisements/print detail
```

Known limitation: EVPN host-route redistribution directly into the IPv4-VPN address family has not behaved reliably in this lab. The working direction is IPv4-VPN into VRF IPv4 unicast, then advertisement into EVPN. External connectivity currently uses per-VRF IPv4-unicast BGP over IPv6 link-local; an IPv4-VPN/MPLS/LDP/OSPF alternative has also been tested.
