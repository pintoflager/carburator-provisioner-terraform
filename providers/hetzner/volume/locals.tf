###
# Local variables for main.tf.
#
locals {
  vol_nodes = {for i, v in var.volumes:
    "${v.identifier}-${i}" => {
      node = v.node_uuid
      identifier = v.identifier
      size = v.size != null ? v.size : var.volume_default_size
      fs = v.filesystem != null ? v.filesystem : var.volume_default_filesystem
    }
  }
  provisioned_nodes = {for v in var.nodes_output:
    v.labels.uuid => {
      id      = v.id,
      cluster = v.labels.cluster
    }
  }
}
