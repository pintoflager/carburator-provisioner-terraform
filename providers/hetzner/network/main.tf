terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.38.2"
    }
    template = {
      version = "~> 2.2.0"
    }
    local = {
      version = "~> 2.0.0"
    }
  }
}

###
# Say hello.
#
provider "hcloud" {
  token = var.hcloud_token
}

###
# Networks, one for each cluster.
#
resource "hcloud_network" "private_networks" {
  for_each = local.clusters
  name     = "${each.key}"
  ip_range = "${each.value}"
}

# Subnets, one for each network.
resource "hcloud_network_subnet" "private_networks_subnet" {
  for_each     = local.clusters
  network_id   = hcloud_network.private_networks[each.key].id
  type         = var.net_type
  network_zone = local.zones[each.key]
  ip_range     = "${each.value}"
  depends_on   = [
    hcloud_network.private_networks
  ]
}

# Add server nodes to subnet.
resource "hcloud_server_network" "private_networks_servers" {
  for_each     = local.nodes_in_clusters
  server_id    = lookup(local.provisioned_nodes, each.key, false)
  network_id   = hcloud_network.private_networks["cluster-${each.value}"].id
}
