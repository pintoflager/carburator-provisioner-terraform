###
# Local variables for main.tf.
#
locals {
  nodes    = {for v in var.nodes:
    "${v.hostname}" => v
  }
  clusters = {for v in distinct(var.nodes[*].cluster):
    "${v}" => "${var.project_id}-${v}"
  }
}
