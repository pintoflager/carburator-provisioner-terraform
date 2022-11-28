terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.34.3"
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
# Server placement.
#
resource "hcloud_placement_group" "__server_placement" {
  name = "${var.identifier}-placement"
  type = "spread"
}

###
# Servers.
#
resource "hcloud_server" "servers" {
  count       = length(var.servers)
  name        = "${var.servers[count.index].hostname}"
  image       = "${var.servers[count.index].os.name}"
  server_type = "${var.servers[count.index].plan.name}"
  location    = length(var.servers[count.index].location.name) > 0 ? var.servers[count.index].location : local.randl[count.index][1]
  public_net {
    ipv4_enabled = var.servers[count.index].connectivity.public_ipv4
    ipv6_enabled = var.servers[count.index].connectivity.public_ipv6
  }
  ssh_keys = [var.ssh_id]
  placement_group_id = hcloud_placement_group.__server_placement.id
}
