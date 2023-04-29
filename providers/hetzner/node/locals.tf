###
# Local variables for main.tf.
#
locals {
  nodes    = toset(var.nodes)
  clusters = toset(distinct(var.nodes[*].cluster.name))
}
