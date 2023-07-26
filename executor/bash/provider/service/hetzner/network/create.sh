#!/usr/bin/env bash

carburator print terminal info "Invoking Hetzner's Terraform network provisioner..."

resource="network"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
network_out="$data_dir/$resource.json"
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
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRETS_0" --user root)
exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

# Defaults. Reserves /24 block for each cluster starting from the given prefix.
# Meaning '10.10.${cluster index}.0/24' --- 254 addresses per cluster.
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
	terraform -chdir="$1" apply -auto-approve
	terraform -chdir="$1" output -json > "$2"

	# Assuming create failed as we cant load the output
	if ! carburator has json network.value --path "$2"; then
		carburator print terminal error "Create networks failed."
		rm -f "$2"; return 110
	fi
}

provisioner_call "$resource_dir" "$network_out"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator print terminal success \
		"Private network created successfully with Terraform."
else
	exit 110
fi

###
# Register node private network IP addresses to project
#
net_len=$(carburator get json network.value array --path "$network_out" | wc -l)
net_nodes_len=$(carburator get json node.value array --path "$network_out" | wc -l)
nodes_len=$(carburator get json node.value array -p "$node_out" | wc -l)

# Loop all networks created.
for (( a=0; a<net_len; a++ )); do
	block=$(carburator get json "network.value.$a.ip_range" string -p "$network_out")

	if [[ -z $block ]]; then
		carburator print terminal error "Unable to read network range from '$network_out'"
		exit 120
	fi

	# Loop all nodes attached to private network.
	for (( i=0; i<net_nodes_len; i++ )); do
		# Find node uuid with help of the terraform node id.
		net_node_id=$(carburator get json "node.value.$i.server_id" number -p "$network_out")

		if [[ -z $net_node_id ]]; then
			carburator print terminal error "Unable to read node ID from '$network_out'"
			exit 120
		fi
		
		# Private network addresses are always ipv4
		ip=$(carburator get json "node.value.$i.ip" string -p "$network_out")

		if [[ -z $ip || $ip == null ]]; then
			carburator print terminal error "Unable to find IP for node with ID '$net_node_id'"
			exit 120
		fi

		# Loop all nodes from node.json, find node uuid, add block and address.
		for (( g=0; g<nodes_len; g++ )); do
			node_id=$(carburator get json "node.value.$g.id" string -p "$node_out")

			# Not what we're looking for, next round please.
			if [[ $node_id != "$net_node_id" ]]; then continue; fi

			# Easiest way to locate the right node is with it's UUID
			node_uuid=$(carburator get json "node.value.$g.labels.uuid" string \
				-p "$node_out")

			# Register block and extract first (and the only) ip from it.
			net_uuid=$(carburator register net-block "$block" \
				--extract \
				--provider hetzner \
				--provisioner terraform \
				--ip "$ip" \
				--uuid); exitcode=$?

			if [[ $exitcode -gt 0 ]]; then
				carburator print terminal error \
					"Unable to register network block '$block' and extract IP '$ip'"
				exit 120
			fi

			# Point address to node.
			carburator node address \
				--node-uuid "$node_uuid" \
				--address-uuid "$net_uuid"

			# Get the hell out of here and to the next network iteration.
			continue 2;
		done

		# We should be able to find all nodes, if not, well, shit.
		carburator print terminal error "Unable to find node matching ID '$net_node_id'"
		exit 120
	done
done
