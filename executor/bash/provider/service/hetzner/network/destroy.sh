#!/usr/bin/env bash

carburator log info "Invoking Hetzner's Terraform network provisioner..."

resource="network"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
node_out="$data_dir/node.json"

# Make sure terraform resource dir exists.
mkdir -p "$resource_dir"

while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$resource_dir/$file"
done < <(find "$terraform_sourcedir" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail out early.
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
export TF_VAR_net_range="10.10"
export TF_VAR_net_type="cloud"

# Nodes as they're seen from the project
nodes=$(carburator get json nodes array-raw -p .exec.json)

export TF_VAR_net_nodes="$nodes"

# Nodes as they're output from terraform.
# 
# We only connect nodes provisioned with terraform.
nodes_output=$(carburator get json node.value array-raw -p "$node_out")

export TF_VAR_nodes_output="$nodes_output"

provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" destroy -auto-approve
}

provisioner_call "$resource_dir"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator log success \
		"Private network destroyed successfully with Terraform."
else
	carburator log error \
		"Terraform private network destroy failed with exitcode $exitcode"
	exit 120
fi