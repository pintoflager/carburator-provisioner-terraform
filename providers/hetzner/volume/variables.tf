# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that is used to interact with the Hetzner Cloud API."
}

# Has to be added as TF_VAR before running init / apply
# This can take volume.json as variable value.
variable "volumes" {
  type = list(object({
    name        = string
    server_id   = number
    size        = number
    format      = string
  }))
  default = [
    {
      name       = ""
      server_id  = 0
      size       = 10
      format     = "ext4"
    }
  ]
}
