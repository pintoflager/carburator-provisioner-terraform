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
      server_id      = v.server_id
      mount          = v.linux_device
      path           = "/mnt/HC_Volume_${v.id}"
      format         = "${var.volumes[i].format}"
      labels         = v.labels
    })
  ]
}
