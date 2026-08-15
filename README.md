# VyOS EVPN/VXLAN homelab

OpenTofu configuration for a small VyOS/FRR EVPN-VXLAN fabric hosted primarily on Proxmox. Two MikroTik CRS326 switches act as out-of-band-managed Spines/EVPN route reflectors; this repository creates VyOS VMs and configures the VyOS leaf roles.
There are Bare Metal VyOS nodes for L2 and L3 out.

> **Lab-specific repository:** committed `.auto.tfvars` files contain real topology and addressing intent, but not credentials. Review them before applying anywhere other than this lab.

## What is managed

The root configuration invokes three independent modules:

| Module | Responsibility |
| --- | --- |
| `create_fabric_vms` | Creates virtual standard, border, extension, and `greatfox` leaves in Proxmox. Bare-metal inventory entries are skipped. |
| `configure_fabric` | Configures the currently enabled border leaves through the VyOS API. |
| `configure_dhcp` | Configures only the two dedicated VyOS Kea DHCP nodes: system identity/DNS, physical service interfaces, scopes, HA, and disabled IPv4 forwarding. |

There are 4 types of leaves:
- cluster_leaves: VMs in PVE Cluster
- single_leafs: stand alone PVE node (my main workstation btw)
- border_leaves: external L3 connectivity to the rest of my lab/internet
- fabric_leaves: external L2 connectivity to switches, For wireless clients and other physical devices.
    - only a single fabric leaf until EVPN MH Split Horizon filters work for me
  

### Design at a glance

- IPv6 link-local eBGP provides the routed underlay.
- IPv6 overlay addresses are derived from `fd69:255:240::/64`.
- BGP Router IDs are `10.255.240.<node_id>`
- EVPN peering via iBGP, AS `700`
- IPv6 underlay via eBGP, AS `700 + node_id`.
- Single VxLAN Device design. `vxlan0` and `br0`
- Symmetric IRB
- External L3 peering via dedicated Border Leaves. Single peering to `service` tennant, with EVPN Route Leaking via Downstream VNI
- L2 out via single link. EVPN MH Split Horizon filters not yet implemented.
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
|   |
│   ├── pve_leaves/              # VRFs/VM facing interfaces
│   ├── fabric_leaves/           # VRFs/external interfaces    
│   └── border_leaves/           # VRFs/external interfaces/peering
|   
├── configure_dhcp/              # isolated VyOS DHCP system/interface/Kea/HA configuration
└── create_fabric_vms/
    └── pve_vm/                  # reusable VM resource with bridge/VLAN NICs
```

`single_vrf_fabric.auto.tfvars.no` is a disabled alternative intent file retained as a reference. OpenTofu does not load it because its suffix is not `.tfvars`.

## Prerequisites

- OpenTofu (the commands in this repository intentionally use `tofu`, not `terraform`).
- Access to the Proxmox APIs and VyOS HTTPS APIs referenced by the committed lab settings.
- `~/.ssh/id_rsa` authorized as `user` on the Proxmox targets.
- Existing Proxmox storage objects, bridges, VyOS image, and cloud-init snippet named in `proxmox_vm.auto.tfvars`.
- Existing Spine/EVPN Route Reflectors

## Credentials

The credentials are:

- `vyos_key`: VyOS HTTPS API key.
- `pve_api_token`: API token for the primary Proxmox cluster.

## Workflow

```bash
tofu apply --target=module.create_fabric_vms
tofu apply --target=module.configure_fabric
```
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
- `is_vm = true` creates vm.
- `started = true` powers the VM on. It defaults to `false`, allowing each leaf,
  border leaf, fabric-extension leaf, `greatfox` leaf, or DHCP VM to be created
  without automatically starting it.
- `underlay_bridges` overrides the default Proxmox bridge list.

Node IDs must therefore be unique. Currently must be in range \[1-255\]


### VRFs and VNIs

Edit `vnis.l3` in `fabric.auto.tfvars`. Each L3 entry describes a VRF, table, L3VNI, EVPN route targets, and optional VPN import/export behavior. Nested `l2` entries describe VLAN/VNI pairs, anycast gateways/MACs, and advertisement/export switches.

Useful conventions:

- Keep one L3VNI and table number per VRF.
- Keep one L2VNI per VLAN and ensure VNI/VLAN values are unique.
- Use a unique anycast MAC and valid gateway CIDR for each L2 segment.
- Carefully review RT imports: they define which tenant routes can cross policy boundaries.

### VM defaults

Edit `proxmox_vm.auto.tfvars` for image, storage, cloud-init, management/underlay bridges, CPU, memory, and disk defaults.

### DHCP architecture

DHCP intent lives with each L2VNI rather than in a duplicate scope map. The outer
`dhcp` object attaches both DHCP VMs to that L2VNI. Attachments are ordered by
VNI.  The nested `scope` enables
Kea service on that interface. The configuration derives the normalized subnet,
gateway, Kea subnet ID, server addresses, DNS/domain defaults, interface name,
and bridge name from the L2VNI, root DNS, and DHCP cluster objects.

The generated layout is:

| Interface | Existing Proxmox bridge | Function | Derived node addresses |
| --- | --- | --- | --- |
| `eth0` | management bridge from `proxmox_vm.auto.tfvars` | VyOS management/API | management prefix host IDs 251 and 252 |
| `eth1` onward | `vmbr4000`, tagged with `l2.vlan_id` | One NIC per DHCP-enabled L2VNI, in VNI order | Derived from the segment subnet and node ID |

The HA peers communicate over L2VNI 9006
and require TCP port 647 between `10.6.10.251` and `10.6.10.252`.

IPv4 forwarding is disabled on both DHCP nodes. Because their physical NICs are
directly attached to L2VNIs in different fabric VRFs, forwarding could otherwise
turn a DHCP server into an unintended inter-VRF transit router.


## Operations and troubleshooting

Useful VyOS/FRR checks:

```text
show bgp summary
show bgp vrf all ipv4
show bgp l2vpn evpn summary
show bgp l2vpn evpn route type [1-5]
show ip route vrf all
monitor traffic interface any filter 'port not 22 and not 3784 and not 4784' (no ssh or bfd)
```

Useful MikroTik checks: (my current SPINE EVPN RRs)

```routeros
/routing/bgp/session/print detail
/routing/route/print detail where afi=evpn
/routing/bgp/advertisements/print detail
```


