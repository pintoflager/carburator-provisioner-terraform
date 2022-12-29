#!/usr/bin/env bash

carburator print terminal info "Invoking Hetzner's Terraform network provisioner..."

# REMEMBER: runtime variables for provisioner are next to this script as:
# .exec.env << Same as the sourced environment (check with 'env' command)
# .exec.json
# .exec.yaml
# .exec.toml

# REMEMBER: runtime variables for provider are expected to be next to this script as:
# .provider.exec.env
# .provider.exec.json
# .provider.exec.yaml
# .provider.exec.toml

resource="network"
resource_dir="$PROVISIONER_PROVIDER_PATH/.tf-$resource"
output="$PROVISIONER_PROVIDER_PATH/$resource.json"

# Make sure terraform resource dir exist.
mkdir -p "$resource_dir"

while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$PROVISIONER_PROVIDER_PATH/.tf-$resource/$file"
done < <(find "$PROVISIONER_PROVIDER_PATH/$resource" -maxdepth 1 -iname '*.tf')

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
export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

# We only connect nodes provisioned with terraform.
nodes=$(carburator get json node.value array-raw \
	--path "$PROVISIONER_PROVIDER_PATH/node.json")
export TF_VAR_nodes="$nodes"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" apply -auto-approve || return 1
	terraform -chdir="$1" output -json > "$2" || return 1

	# Assuming create failed as we cant load the output
	if ! carburator has json network.value --path "$2"; then
		carburator print terminal error "Create networks failed."
		rm -f "$2"; return 1
	fi
}

# Network setup is expected to come from service provider with each network
# zone separately
if [[ -e "$PROVISIONER_PROVIDER_PATH/$resource/.eu.nodes.json" ]]; then
	network_json=$(cat "$PROVISIONER_PROVIDER_PATH/$resource/.eu.nodes.json")
	export TF_VAR_networks="$network_json"

	# Analyze output json to determine if networks were registered OK.
	if provisioner_call "$resource_dir" "$output"; then
		carburator print terminal success "Europe central networks created."	
	else
		exit 110
	fi
fi

if [[ -e "$PROVISIONER_PROVIDER_PATH/$resource/.us.east.nodes.json" ]]; then
	network_json=$(cat "$PROVISIONER_PROVIDER_PATH/$resource/.us.east.nodes.json")
	export TF_VAR_networks="$network_json"

	# Analyze output json to determine if networks were registered OK.
	if provisioner_call "$resource_dir" "$output"; then
		carburator print terminal success "USA east networks created."
	else
		exit 110
	fi
fi

if [[ -e "$PROVISIONER_PROVIDER_PATH/$resource/.us.west.nodes.json" ]]; then
	network_json=$(cat "$PROVISIONER_PROVIDER_PATH/$resource/.us.east.west.json")
	export TF_VAR_networks="$network_json"

	# Analyze output json to determine if networks were registered OK.
	if provisioner_call "$resource_dir" "$output"; then
		carburator print terminal success "USA west networks created."	
	else
		exit 110
	fi
fi

# Register network IP addresses
len=$(carburator get json node.value array --path "$output" | wc -l)
network_range=$(carburator get json "network.value.ip_range" string -p "$output")
nlen=$(carburator get json node.value array \
	-p "$PROVISIONER_PROVIDER_PATH/node.json" | wc -l)

# Loop all nodes attached to private network.
for (( i=0; i<len; i++ )); do
	# Find node uuid with terraform node id.
	id=$(carburator get json "node.value.$i.server_id" number \
		-p "$output") || exit 120
	
	# Private network addresses are always ipv4
	ip=$(carburator get json "node.value.$i.ip" string -p "$output") || exit 120

	if [[ -z $ip || $ip == null ]]; then
		carburator print terminal error "Unable to find IP for node with ID '$id'"
		exit 120
	fi

	# Loop all nodes from node.json, find node uuid, add block and address.
	for (( j=0; j<nlen; j++ )); do
		node_id=$(carburator get json "node.value.$i.id" string \
			-p "$PROVISIONER_PROVIDER_PATH/node.json")

		# Not what we're looking for.
		if [[ $node_id != "$id" ]]; then continue; fi

		# Easiest way to find the right node is with it's UUID
		node_uuid=$(carburator get json "node.value.$i.labels.uuid" string \
			-p "$PROVISIONER_PROVIDER_PATH/node.json")

		# Register block and grab first (and only) ip from it.
		net_uuid=$(carburator-commander address register-block "$network_range" \
			--grab \
			--uuid \
			--grab-ip "$ip" \
			--can-exist) || exit 120

		carburator-commander node address \
			--node-uuid "$node_uuid" \
			--address-uuid "$net_uuid"

		# Get the hell out of here and to the next network iteration.
		continue 2;
	done

	# We should be able to find all nodes, if not, crap.
	carburator print terminal error "Unable to find node matching ID '$id'"
	exit 120
done
