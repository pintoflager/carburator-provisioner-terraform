#!/usr/bin/env bash

carburator log info "Invoking Hetzner's Terraform server provisioner..."

resource="volume"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
node_out="$data_dir/node.json"

# Make sure terraform resource dir exist.
mkdir -p "$resource_dir"

# Copy terraform files from package to execution dir.
# This way files can be modified and package update won't overwrite
# the changes.
while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$resource_dir/$file"
done < <(find "$terraform_sourcedir" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail early.
#
user=${PROVISIONER_SERVICE_PROVIDER_PACKAGE_USER_PUBLIC_IDENTIFIER:-root}
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRETS_0" \
	--user "$user"); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

volumes=$(carburator get json volumes array-raw -p .exec.json)

if [[ -z $volumes ]]; then
	carburator log error "Could not load volumes array from .exec.json"
	exit 120
fi

export TF_VAR_volumes="$volumes"

# Nodes as they're output from terraform.
# 
# We only connect volumes provisioned with terraform.
nodes_output=$(carburator get json node.value array-raw -p "$node_out")

export TF_VAR_nodes_output="$nodes_output"

provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" destroy -auto-approve
}

provisioner_call "$resource_dir"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator log success \
		"Node volume(s) destroyed successfully with Terraform."
elif [[ $exitcode -eq 110 ]]; then
	carburator log error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator log error \
		"Terraform failed to destroy volumes. Exitcode $exitcode"
	exit 120
fi