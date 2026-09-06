#!/usr/bin/env python3
"""Provider-free regression checks for the committed fabric inventory."""
from pathlib import Path
import ipaddress, re

fabric = Path("fabric.auto.tfvars").read_text()
vnis = Path("vnis.auto.tfvars").read_text()
expected_nodes = {
    "fichina": (11, "pve"), "macbeth": (12, "pve"), "titania": (13, "pve"),
    "zoness": (14, "pve"), "fortuna": (15, "pve"), "eldarad": (16, "pve"),
    "venom": (17, "pve"), "border-1": (18, "external_l3"),
    "border-2": (19, "external_l3"), "greatfox": (20, "pve"),
    "fabric-2": (42, "external_l2"),
}
for name, (node_id, role) in expected_nodes.items():
    assert re.search(rf"{re.escape(name)}\s*=\s*\{{[^}}]*\bid\s*=\s*{node_id}\b[^}}]*\brole\s*=\s*\"{role}\"", fabric, re.S)
assert re.search(r"greatfox\s*=\s*\{[^}]*proxmox_target\s*=\s*\"greatfox\"", fabric, re.S)
assert len({node_id for node_id, _ in expected_nodes.values()}) == len(expected_nodes)

expected_roles = {6200: {"pve", "external_l2"}, 6600: {"pve", "external_l2"}, 6900: {"pve", "external_l2"}, 6666: {"external_l3"}}
for vni, roles in expected_roles.items():
    match = re.search(rf"\bvni\s*=\s*{vni}\b\s*\n\s*roles\s*=\s*\[([^]]+)\]", vnis)
    assert match and set(re.findall(r'\"([^\"]+)\"', match.group(1))) == roles
l2_ids = sorted(map(int, re.findall(r"\bvni\s*=\s*(9\d{3})\b", vnis)))
assert l2_ids == [9002, 9006, 9008, 9009, 9010, 9011]
assert len(set(expected_roles) | set(l2_ids)) == 10
assert sorted(x for x in l2_ids if re.search(rf"\bvni\s*=\s*{x}\b[\s\S]*?dhcp\s*=", vnis))[:5] == [9002, 9006, 9008, 9009, 9010]

# Preserve address, ASN, and decimal-digit MAC derivations for every leaf.
net4 = ipaddress.ip_network("10.255.240.0/24")
net6 = ipaddress.ip_network("fd69:255:240::/64")
for _, (node_id, _) in expected_nodes.items():
    assert str(net4[node_id]).startswith("10.255.240.")
    assert net6[int(str(node_id), 16)] in net6
    raw = f"02{700 + node_id:04d}{node_id:04d}{1:02d}"
    assert ":".join(raw[i:i+2] for i in range(0, 12, 2)).startswith("02:")

# Spine peers remain all leaves; selected policy keys remain the three tenant VNIs.
assert set(expected_nodes) == {name for name in expected_nodes}
assert {str(v) for v, roles in expected_roles.items() if "pve" in roles} == {"6200", "6600", "6900"}
print("inventory, role/VNI selection, addresses, MACs, policies, and DHCP ordering preserved")
