###
# Local variables for main.tf.
#
locals {
  labels_v6 = {for i, v in var.nodes:
    i == 0 ? "primary" : "secondary-${i}" => v.ownership.ref
  if v.toggles.ipv6}
  labels_v4 = {for i, v in var.nodes:
    i == 0 ? "primary" : "secondary-${i}" => v.ownership.ref
  if v.toggles.ipv4}
  provisioned_nodes = {for v in var.nodes_output:
    v.labels.uuid => v.id
  }
}
