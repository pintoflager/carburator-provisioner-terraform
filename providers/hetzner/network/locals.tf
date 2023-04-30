###
# Local variables for main.tf.
#
locals {
  # returns [cluster_name]
  clusters = toset(distinct(var.net_nodes[*].cluster.name))
  # returns {cluster_name: network_zone}
  zones = {for v in var.net_nodes:
    "${v.cluster.name}" =>
      v.location.name == "ash" ? "us-east" :
      v.location.name == "hil" ? "us-west" :
      "eu-central"
  }
  # returns {hostname: {cluster: cluster_name, id: server_id}}
  nodes = {for v in var.nodes_output:
    "${v.name}" => {
      "cluster": v.labels.cluster
      "id": v.id
    }
  }
}
