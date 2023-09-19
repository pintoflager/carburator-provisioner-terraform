# Has to be added as TF_VAR before running init / apply
variable "digitalocean_token" {
  type = string
  description = "The token that will be used to connect to the Digital Ocean Cloud API."
  sensitive = true
}

# Has to be added as TF_VAR before running init / apply
variable "ssh_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "nodes" {
  type = list(
    object({
      cluster = string
      hostname = string
      ownership = object({
        ref = string
      })
      os = object({
        name = string
      })
      plan = object({
        name = string
      })
      location = object({
        name = string
      })
      toggles = object({
        ipv4 = bool
        ipv6 = bool
      })
    })  
  )
}
