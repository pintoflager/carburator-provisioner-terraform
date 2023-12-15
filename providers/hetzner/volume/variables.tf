# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "volume_default_size" {
  type = number
  default = 10
}

variable "volume_default_filesystem" {
  type = string
  default = "ext4"
}

variable "volumes" {
  type = list(
    object({
      identifier = string
      node_uuid = string
      # REMEMBER: If this is set, it's in BYTES
      size = optional(number),
      filesystem = optional(string)
    })
  )
}

# Output from node creation, needed for node ID's
variable "nodes_output" {
  type = list(
    object({
      name     = string
      id       = string
      labels   = object({
        uuid     = string
        cluster  = string
      })
    })
  )
}
