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
# Networks.
#
resource "hcloud_network" "private_networks" {
  for_each = local.clusters
  name     = "${each.key}-private"
  ip_range = var.net_range
}

# Subnet from instance.
resource "hcloud_network_subnet" "private_networks_subnet" {
  for_each     = local.clusters
  network_id   = hcloud_network[each.key].private_networks.id
  type         = var.net_type
  network_zone = local.zones[each.key]
  ip_range     = var.net_range
  depends_on   = [
    hcloud_network.private_networks
  ]
}

# Add server nodes to subnet.
resource "hcloud_server_network" "private_networks_servers" {
  for_each     = local.nodes
  server_id    = each.value.id
  network_id   = hcloud_network[each.value.cluster].private_networks.id
}
