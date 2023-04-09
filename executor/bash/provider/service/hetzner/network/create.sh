#!/usr/bin/env bash

carburator print terminal info "Invoking Hetzner's Terraform network provisioner..."

resource="network"
resource_dir="$INVOCATION_PATH/terraform"
terraform_resources="$PROVISIONER_PATH/providers/hetzner/$resource"
output="$INVOCATION_BASE/$resource.json"

# Make sure terraform resource dir exists.
mkdir -p "$resource_dir"

while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$resource_dir/$file"
done < <(find "$terraform_resources" -maxdepth 1 -iname '*.tf')

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
	--path "$INVOCATION_BASE/node.json")
export TF_VAR_nodes="$nodes"

provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" apply -auto-approve
	terraform -chdir="$1" output -json > "$2"

	# Assuming create failed as we cant load the output
	if ! carburator has json network.value --path "$2"; then
		carburator print terminal error "Create networks failed."
		rm -f "$2"; return 110
	fi
}

# Network setup is expected to come from service provider with each network
# zone separately
if [[ -e "$terraform_resources/.eu.nodes.json" ]]; then
	network_json=$(cat "$terraform_resources/.eu.nodes.json")
	export TF_VAR_networks="$network_json"

	# Analyze output json to determine if networks were registered OK.
	provisioner_call "$resource_dir" "$output"; exitcode=$?

	if [[ $exitcode -eq 0 ]]; then
		carburator print terminal success "Europe central networks created."	
	else
		exit 110
	fi
fi

if [[ -e "$terraform_resources/.us.east.nodes.json" ]]; then
	network_json=$(cat "$terraform_resources/.us.east.nodes.json")
	export TF_VAR_networks="$network_json"

	# Analyze output json to determine if networks were registered OK.
	provisioner_call "$resource_dir" "$output"; exitcode=$?

	if [[ $exitcode -eq 0 ]]; then
		carburator print terminal success "USA east networks created."
	else
		exit 110
	fi
fi

if [[ -e "$terraform_resources/.us.west.nodes.json" ]]; then
	network_json=$(cat "$INVOCATION_BASE/$resource/.us.east.west.json")
	export TF_VAR_networks="$network_json"

	# Analyze output json to determine if networks were registered OK.
	provisioner_call "$resource_dir" "$output"; exitcode=$?

	if [[ $exitcode -eq 0 ]]; then
		carburator print terminal success "USA west networks created."	
	else
		exit 110
	fi
fi

# Register network IP addresses
len=$(carburator get json node.value array --path "$output" | wc -l)
network_range=$(carburator get json "network.value.ip_range" string -p "$output")
nodes_len=$(carburator get json node.value array \
	-p "$INVOCATION_BASE/node.json" | wc -l)

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
	for (( j=0; j<nodes_len; j++ )); do
		node_id=$(carburator get json "node.value.$i.id" string \
			-p "$INVOCATION_BASE/node.json")

		# Not what we're looking for.
		if [[ $node_id != "$id" ]]; then continue; fi

		# Easiest way to find the right node is with it's UUID
		node_uuid=$(carburator get json "node.value.$i.labels.uuid" string \
			-p "$INVOCATION_BASE/node.json")

		# Register block and extract first (and the only) ip from it.
		net_uuid=$(carburator address register-block "$network_range" \
			--extract \
			--ip "$ip" \
			--uuid) || exit 120

		# Point address to node.
		carburator node address \
			--node-uuid "$node_uuid" \
			--address-uuid "$net_uuid"

		# Get the hell out of here and to the next network iteration.
		continue 2;
	done

	# We should be able to find all nodes, if not, crap.
	carburator print terminal error "Unable to find node matching ID '$id'"
	exit 120
done
