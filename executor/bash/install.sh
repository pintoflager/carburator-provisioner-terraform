#!/usr/bin/env bash

role="$1"

# Package installation tasks on a local client node. Runs first
#
#
if [ "$role" = 'client' ]; then
    carburator print terminal info "Executing terraform install script on $role"

    if ! carburator has program terraform; then
        carburator print terminal warn \
            "Missing terraform on local client machine."

        carburator prompt yes-no \
            "Should we try to install terraform? Installs on your PC." \
            --yes-val "Yes try to install with a script" \
            --no-val "No, I'll install everything"; exitcode=$?

        if [[ $exitcode -ne 0 ]]; then
          exit 120
        fi
    fi
fi

# Package installation tasks on remote commander node.
#
#
carburator print terminal info "Executing install script on $role"

# Terraform is required.
if carburator has program terraform; then
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

carburator sudo wget -qO- "$path" | bsdtar -xvf- -C /usr/local/bin/
