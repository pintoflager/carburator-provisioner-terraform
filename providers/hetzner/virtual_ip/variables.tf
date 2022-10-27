# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "vip_v4" {
  type    = list(string)
  default = []
}

variable "vip_v6" {
  type    = list(string)
  default = []
}
