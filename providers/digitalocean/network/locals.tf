###
# Local variables for main.tf.
#
locals {
  clusters = {for i, v in distinct(var.net_nodes[*].cluster):
    "cluster-${v}" => "${var.net_range}.${i}.0/24"
  }
  regions = {for i, v in distinct(var.net_nodes[*].cluster):
    "cluster-${v}" => var.net_nodes[i].location.name
  }
}
