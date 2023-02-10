#!/usr/bin/env bash

# ATTENTION: Runs only on commander, pointless to read platform from $1

# Terraform is required.
if carburator fn integration-installed terraform; then
  carburator print terminal info "Terraform found, skipping install..."
  exit
fi

# TODO: Untested below.

carburator print terminal warn \
  "Missing required program Terraform. Trying to install it before proceeding..."

# Try to download and install terraform binary
version="1.3.6"
arch="$(uname -m)"

if [ "$arch" = "x86_64" ]; then
  arch="amd64"
elif [ "$arch" = "armv7" ]; then
  arch="arm"
elif [ "$arch" = "aarch64" ]; then
  arch="arm64"
else
  carburator print terminal error
    "Unsupported arch: $arch" && exit 120
fi

path="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_${arch}.zip"

sudo wget -qO- "$path" | bsdtar -xvf- -C /usr/local/bin/
