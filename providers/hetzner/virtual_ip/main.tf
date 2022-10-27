terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.34.1"
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
resource "hcloud_floating_ip" "virtual_ipv4" {
  count                = length(var.vip_v4)
  type                 = "ipv4"
  name                 = "${var.vip_v4[count.index]}-ipv4"
  home_location        = local.randl[0][1]
}

resource "hcloud_floating_ip" "virtual_ipv6" {
  count                = length(var.vip_v6)
  type                 = "ipv6"
  name                 = "${var.vip_v6[count.index]}-ipv6"
  home_location        = local.randl[0][1]
}
