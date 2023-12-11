###
# Local variables for main.tf.
#
locals {
  volumes = {for i, v in var.nodes:
    "${var.volume_name}-${i}" => v.uuid
  if v.toggles.proxy}
  provisioned_nodes = {for v in var.nodes_output:
    v.labels.uuid => v.id
  }
}
