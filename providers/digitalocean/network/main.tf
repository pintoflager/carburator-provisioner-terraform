terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.30.0"
    }
  }
}

###
# Say hello.
#
provider "digitalocean" {
  token = var.digitalocean_token
}

###
# Networks, one for each cluster.
#
resource "digitalocean_vpc" "private_networks" {
  for_each = local.clusters
  name     = "${each.key}"
  region   = local.regions[each.key]
  ip_range = "${each.value}"
}
