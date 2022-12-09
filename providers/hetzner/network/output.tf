###
# Private network output.
#
output "network" {
  description = "Private network connecting nodes"
  value       = {
    name        = hcloud_network.private_networks.name
    id          = hcloud_network.private_networks.id
    ip_range    = hcloud_network.private_networks.ip_range
    subnet      = {
      id     = hcloud_network_subnet.private_networks_subnet.id
      range  = hcloud_network_subnet.private_networks_subnet.ip_range
      zone   = hcloud_network_subnet.private_networks_subnet.network_zone
    }
  }
}

###
# Nodes in network
#
output "node" {
  description = "Private network nodes"
  value = [
    for i, v in hcloud_server_network.private_networks_servers: ({
      id                  = v.id
      ip                  = v.ip
      server_id           = v.server_id
      network_id          = v.network_id
    })
  ]
}
