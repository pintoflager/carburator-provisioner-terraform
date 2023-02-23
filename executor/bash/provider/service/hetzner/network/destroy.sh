#!/usr/bin/env bash

resource="network"
resource_dir="$PROVISIONER_SERVICE_PROVIDER_PATH/.tf-$resource"
output="$PROVISIONER_SERVICE_PROVIDER_PATH/$resource.json"

while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$PROVISIONER_SERVICE_PROVIDER_PATH/.tf-$resource/$file"
done < <(find "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail out early.
#
token=$(carburator get secret "$PROVIDER_SECRET_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

# We only connect nodes provisioned with terraform.
nodes=$(carburator get json node.value array-raw \
	--path "$PROVISIONER_SERVICE_PROVIDER_PATH/node.json")
export TF_VAR_nodes="$nodes"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" destroy -auto-approve || return 1
}

# Network setup is expected to come from service provider with each network
# zone separately
if [[ -e "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource/.eu.nodes.json" ]]; then
	network_json=$(cat "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource/.eu.nodes.json")
	export TF_VAR_networks="$network_json"

	if provisioner_call "$resource_dir"; then
		carburator print terminal success "Europe central networks destroyed."	
	else
		exit 110
	fi
fi

if [[ -e "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource/.us.east.nodes.json" ]]; then
	network_json=$(cat "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource/.us.east.nodes.json")
	export TF_VAR_networks="$network_json"

	if provisioner_call "$resource_dir"; then
		carburator print terminal success "USA east networks destroyed."
	else
		exit 110
	fi
fi

if [[ -e "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource/.us.west.nodes.json" ]]; then
	network_json=$(cat "$PROVISIONER_SERVICE_PROVIDER_PATH/$resource/.us.east.west.json")
	export TF_VAR_networks="$network_json"

	if provisioner_call "$resource_dir"; then
		carburator print terminal success "USA west networks destroyed."	
	else
		exit 110
	fi
fi

# Destroy directories and files
rm -rf "$resource_dir"
rm -f "$output"