###
# Private network output.
#
output "network" {
  description = "Private network connecting nodes"
  value       = [
    for i, v in hcloud_network.private_networks: ({
      name        = v.name
      id          = v.id
      ip_range    = v.ip_range
      subnet      = {
        id     = hcloud_network_subnet.private_networks_subnet[i].id
        range  = hcloud_network_subnet.private_networks_subnet[i].ip_range
        zone   = hcloud_network_subnet.private_networks_subnet[i].network_zone
      }
    })
  ]
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
