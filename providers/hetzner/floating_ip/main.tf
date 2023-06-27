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
# Floating IPs.
#
resource "hcloud_floating_ip" "floating_ip_v4" {
  count      = var.floating_ip_v4 ? 1 : 0
  type       = "ipv4"
  name       = "${var.floating_ip_name}-v4"
  server_id  = local.provisioned_nodes[local.labels_v4["primary"]]
  labels     = local.labels_v4
}

resource "hcloud_floating_ip" "floating_ip_v6" {
  count      = var.floating_ip_v6 ? 1 : 0
  type       = "ipv6"
  name       = "${var.floating_ip_name}-v6"
  server_id  = local.provisioned_nodes[local.labels_v6["primary"]]
  labels     = local.labels_v6
}
