###
# Local variables for main.tf.
#
locals {
  vol_nodes = {for i, v in var.volumes:
    "${v.identifier}-${i}" => {
      node = v.node_uuid
      identifier = v.identifier
      fs = v.filesystem != null ? v.filesystem : var.volume_default_filesystem
      # REMEMBER: binary gives sizes in bytes (hetzner wants them in GB)
      size = v.size != null ? v.size / 1024 / 1024 / 1024 : var.volume_default_size
    }
  }
  provisioned_nodes = {for v in var.nodes_output:
    v.labels.uuid => {
      id      = v.id,
      cluster = v.labels.cluster
    }
  }
}
