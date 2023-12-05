###
# Local variables for main.tf.
#
locals {
  clusters = {for i, v in distinct(var.net_nodes[*].cluster):
    "cluster-${v}" => "${var.net_range}.${i}.0/24"
  }
  zones = {for i, v in distinct(var.net_nodes[*].cluster):
    "cluster-${v}" =>
      var.net_nodes[i].location.name == "ash" ? "us-east" :
      var.net_nodes[i].location.name == "hil" ? "us-west" :
      "eu-central"
  }
  nodes_in_clusters = {for n in var.net_nodes:
    n.uuid => n.cluster
  }
  provisioned_nodes = {for v in var.nodes_output:
    v.labels.uuid => v.id
  }
}
