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
  type = list(
    object({
      hostname = string
      os = object({
        name = string
      })
      plan = object({
        name = string
      })
      location = object({
        name = string
      })
      connectivity = object({
        public_ipv4 = bool,
        public_ipv6 = bool
      })
    })
  )
}
