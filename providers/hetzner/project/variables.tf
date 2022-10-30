variable providers {
  hcloud = {
    source  = "hetznercloud/hcloud"
    version = "1.34.3"
  }
  template = {
    version = "~> 2.2.0"
  }
  local = {
    version = "~> 2.0.0"
  }
}

# Has to be added as TF_VAR before running init / apply
variable "apitoken" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "identifier" {
  type = string
  description = "Project identifier"
}

variable "keyname" {
  type = string
  description = "Project root SSH key name"
}

variable "pubkey" {
  type = string
  description = "Path to project roots' public SSH key"
}
