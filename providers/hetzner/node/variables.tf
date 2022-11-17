# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

# Has to be added as TF_VAR before running init / apply
variable "ssh_id" {
  type = string
  default = ""
}

variable "identifier" {
  type = string
  description = "Server node identifier"
}

variable "locations" {
  type    = list(string)
  default = ["nbg1", "fsn1", "hel1"]
}

variable "servers" {
  type = list(object({
    name          = string
    image         = string
    location      = string
    type          = string
    ipv4_enabled  = bool
    ipv6_enabled  = bool
  }))
  default = [
    {
      name          = ""
      image         = ""
      location      = ""
      type          = ""
      ipv4_enabled  = true
      ipv6_enabled  = true
    }
  ]
}
