#!/usr/bin/env bash

# ATTENTION: Supports only client nodes, pointless to read role from $1
if [[ $1 == "server" ]]; then
    carburator print terminal error \
        "Provisioners register only on client nodes. Package configuration error."
    exit 120
fi

if ! carburator has program wget; then
    carburator print terminal error \
        "Host machine is missing 'wget' program. Install it before trying again."
    exit 120
fi

if ! carburator has program unzip; then
    carburator print terminal error \
        "Host machine is missing 'unzip' program. Install it before trying again."
    exit 120
fi

if ! carburator has program terraform; then
    carburator print terminal warn "Missing terraform on client machine."

    carburator prompt yes-no \
        "Should we try to install terraform?" \
        --yes-val "Yes try to install with a script" \
        --no-val "No, I'll install everything"; exitcode=$?

    if [[ $exitcode -ne 0 ]]; then
        exit 120
    fi
else
    carburator print terminal success "Terraform found from the client"
    exit 0
fi

# TODO: Untested below.
carburator print terminal warn \
  "Missing required program Terraform. Trying to install it before proceeding..."

# Try to download and install terraform binary
version="1.6.5"
arch="$(uname -m)"

if [ "$arch" = "x86_64" ]; then
    arch="amd64"
elif [ "$arch" = "armv7" ]; then
    arch="arm"
elif [ "$arch" = "aarch64" ]; then
    arch="arm64"
else
    carburator print terminal error "Host has unsupported chip architecture: $arch"
    exit 120
fi

# https://releases.hashicorp.com/terraform/1.6.5/terraform_1.6.5_linux_amd64.zip
path="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_${arch}.zip"
temp_dir="$HOME/Downloads"

# Create downloads dir if not there yet, pull zip archive, unzip to local bins
mkdir -p "$temp_dir"
wget -O "$temp_dir/terraform.zip" "$path"
unzip -u "$temp_dir/terraform.zip" -d "$HOME/.local/bin/"

# Make sure extracted binary is executable and remove archive
chmod +x "$HOME/.local/bin/terraform"
rm -f "$temp_dir/terraform.zip"
