###
# Principal output for nodes.
#
output "node" {
  description = "Server nodes from provider"
  value = [
    for i, v in digitalocean_droplet.servers: ({
      id                  = v.id
      name                = v.name
      image               = v.image
      type                = v.size
      ipv4                = v.ipv4_address
      ipv6                = v.ipv6_address
      location            = v.region
      tags                = v.tags
    })
  ]
}
