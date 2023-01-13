terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
  token = var.access_token
}

resource "github_repository" "repository" {
  name        = "${var.name}"
  description = "${var.description}"
  visibility = "${var.visibility}"
}
