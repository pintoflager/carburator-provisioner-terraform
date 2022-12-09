terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.0"
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
  name     = "${var.networks.network.name}-private"
  ip_range = var.networks.network.range
}

# Subnet from instance.
resource "hcloud_network_subnet" "private_networks_subnet" {
  network_id   = hcloud_network.private_networks.id
  type         = var.networks.network.type
  network_zone = var.networks.network.zone
  ip_range     = var.networks.network.range
  depends_on   = [
    hcloud_network.private_networks
  ]
}

# Add server nodes to subnet.
resource "hcloud_server_network" "private_networks_servers" {
  count        = length(var.networks.nodes)
  server_id    = var.nodes[index(var.nodes.*.name, var.networks.nodes[count.index])].id
  network_id   = hcloud_network.private_networks.id
}
