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
variable "api_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "identifier" {
  type = string
  description = "Project identifier"
}

# Has to be added as TF_VAR before running init / apply
variable "sshkey" {
  type = map
  default = {
    "name"  = "SSH-key-of-the-project-controller"
    "path"  = ""
  }
}
