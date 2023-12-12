###
# Volume details.
#
output "volumes" {
  description = "Volume details for ansible."
  value = [
    for i, v in hcloud_volume.volumes: ({
      cloud_provider = "hetzner"
      name           = v.name
      id             = v.id
      size           = v.size
      filesystem     = v.format
      location       = v.location
      server_id      = v.server_id
      device         = v.linux_device
      labels         = v.labels
    })
  ]
}
