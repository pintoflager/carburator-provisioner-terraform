#!/usr/bin/env bash

resource="network"
resource_dir="$INVOCATION_PATH/terraform"
output="$INVOCATION_ROOT/$resource.json"

###
# Get API token from secrets or bail out early.
#
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRET_0" --user root); exitcode=$?

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
	--path "$INVOCATION_ROOT/node.json")
export TF_VAR_nodes="$nodes"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" destroy -auto-approve || return 1
}

# Network setup is expected to come from service provider with each network
# zone separately
if [[ -e "$INVOCATION_ROOT/$resource/.eu.nodes.json" ]]; then
	network_json=$(cat "$INVOCATION_ROOT/$resource/.eu.nodes.json")
	export TF_VAR_networks="$network_json"

	if provisioner_call "$resource_dir"; then
		carburator print terminal success "Europe central networks destroyed."	
	else
		exit 110
	fi
fi

if [[ -e "$INVOCATION_ROOT/$resource/.us.east.nodes.json" ]]; then
	network_json=$(cat "$INVOCATION_ROOT/$resource/.us.east.nodes.json")
	export TF_VAR_networks="$network_json"

	if provisioner_call "$resource_dir"; then
		carburator print terminal success "USA east networks destroyed."
	else
		exit 110
	fi
fi

if [[ -e "$INVOCATION_ROOT/$resource/.us.west.nodes.json" ]]; then
	network_json=$(cat "$INVOCATION_ROOT/$resource/.us.east.west.json")
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