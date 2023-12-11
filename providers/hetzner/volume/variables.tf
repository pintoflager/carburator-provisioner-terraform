# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "volume_name" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "volume_filesystem" {
  type = string
}

variable "nodes" {
  type = list(
    object({
      hostname = string
      uuid = string
      toggles = object({
        proxy = bool
      })
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
      })
    })
  )
}


# Has to be added as TF_VAR before running init / apply
# This can take volume.json as variable value.
# variable "volumes" {
#   type = list(object({
#     name        = string
#     server_id   = number
#     size        = number
#     format      = string
#   }))
#   default = [
#     {
#       name       = ""
#       server_id  = 0
#       size       = 10
#       format     = "ext4"
#     }
#   ]
# }
