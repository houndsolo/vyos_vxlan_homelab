# Local L2VNI subnet leaking

Normal VTEPs derive connected injection, local VPN-RIB export, and EVPN spine
suppression policies from `vnis.l3[*].l2`. An L2VNI participates when
`export_ipv4_unicast` is true.

## Control-plane pipeline

1. `RM-<VRF>-CONNECTED-TO-BGP` admits only the VRF's exact native L2VNI
   subnets from connected routes into its IPv4 BGP Loc-RIB.
2. `RM-<VRF>-BGP-TO-LOCAL-VPN` exports only those exact native subnets to
   FRR's local VPN RIB. The export RD is leaf-local, while VPN import/export RTs
   come directly from `var.vnis.l3[*].ipv4_rt_imports` and
   `var.vnis.l3[*].ipv4_rt_exports`.
3. Each VRF enables local `import vpn` and imports only routes whose RT matches
   its configured `ipv4_rt_imports`. No IPv4-VPN neighbor address family is
   configured, so the VPN RIB is only a local VRF-leaking intermediary and is
   not a fabric transport.
4. Feedback is prevented by the source VRF's VPN export route-map: a route
   imported from another VRF cannot match the importing VRF's own native-subnet
   prefix-list, so it cannot be exported back to the local VPN RIB under a new
   RD/RT.
5. `advertise ipv4 unicast` remains enabled so native subnets are visible as
   local EVPN Type-5 routes. Local inter-VRF reachability comes from the local
   VPN RIB rather than self-originated EVPN RT import.
6. `RM-EVPN-SPINE-EXPORT` has one reject rule for each participating VRF's
   existing `PL-<VRF>-L2VNI-SUBNETS` list, then permits everything else.

The pinned provider schema supports `export.vpn`, `import.vpn`, `rd.vpn.export`,
`route_target.vpn.import/export`, and `route_map.vpn.export` directly in the
`vyos_vrf_name` IPv4-unicast address family. It also supports route-maps on
connected redistribution, BGP-to-EVPN advertisement, and EVPN peer-group
export.

The spine export route-map rules match EVPN route type `prefix` as well as each
exact native-subnet prefix-list. Consequently Type-2, Type-3, and multihoming
NLRI do not match, while exact subnet entries also exclude shared `/32` routes.

Border leaves instantiate only external L3VNI 6666 and receive an empty native
L2VNI policy map. They do not receive tenant local-VPN export or spine
suppression policies, preserving external/default and shared Type-5
propagation.

## Runtime verification

Enter FRR with `vtysh`. On LEAF-20 run:

```text
show running-config bgpd
show bgp vrf lylat_service ipv4 unicast 10.8.0.0/16
show bgp vrf lylat_service ipv4 unicast 10.8.0.0/16 json
show bgp vrf lylat_lan ipv4 unicast 10.8.0.0/16
show bgp vrf lylat_lan ipv4 unicast 10.8.0.0/16 json
show ip route vrf lylat_service 10.9.0.0/16
show ip route vrf lylat_lan 10.8.0.0/16
show bgp ipv4 vpn 10.8.0.0/16
show bgp ipv4 vpn 10.8.0.0/16 json
show bgp l2vpn evpn route type 5 10.8.0.0/16
show bgp l2vpn evpn route type 5 10.8.0.0/16 json
show bgp l2vpn evpn neighbors fd69:255:240::1 advertised-routes
show bgp l2vpn evpn neighbors fd69:255:240::2 advertised-routes
show bgp l2vpn evpn neighbors fd69:255:240::1 advertised-routes json
show bgp l2vpn evpn neighbors fd69:255:240::2 advertised-routes json
show bgp l2vpn evpn route type 2
show bgp l2vpn evpn route type 3
show bgp l2vpn evpn route type 5
```

The source VRF must show weight 32768 and local redistribution. The local VPN
RIB must show the leaf-local RD and the source VRF's configured export RT. The
destination VRF must show the VPN-imported path with local next-hop resolution,
not a spine or remote VTEP next hop. The local EVPN table may show the locally
generated Type-5, while both advertised-route tables must omit the native `/16`.
Type-2, Type-3, external/default Type-5, and shared `/32` routes must remain.

Repeat the source/destination VRF, VPN-RIB, local Type-5, and advertised-route
checks on a second VTEP. Each VTEP must originate its own VPN route and install
its own local VPN-imported route. Neither may use the other VTEP as next hop for
the native subnet.
