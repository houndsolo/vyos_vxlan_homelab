locals {
  # Keep the per-leaf router MAC derivation in one place so every interface
  # that identifies the VTEP uses the same value.
  rmac = format("00:13:37:00:00:%02d", var.node.id)
}
