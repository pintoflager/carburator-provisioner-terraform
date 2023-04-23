#!/usr/bin/env bash

carburator print terminal info "Invoking Hetzner's Terraform server provisioner..."

resource="node"
resource_dir="$INVOCATION_PATH/terraform"
terraform_resources="$PROVISIONER_PATH/providers/hetzner/$resource"
output="$INVOCATION_BASE/$resource.json"

# Make sure terraform resource dir exist.
mkdir -p "$resource_dir"

while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$resource_dir/$file"
done < <(find "$terraform_resources" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRET_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

project_output="$INVOCATION_BASE/project.json"
sshkey_id=$(carburator get json project.value.sshkey_id string \
	-p "$project_output"); exitcode=$?

if [[ -z $sshkey_id || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load $PROVIDER_NAME sshkey id from terraform/.env. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_ssh_id="$sshkey_id"
export TF_VAR_project_id="$PROJECT_IDENTIFIER"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

# Set cluster name for server placement group
cluster=$(carburator get json cluster_name string \
	--path "$terraform_resources/.provider.exec.json")

if [[ -z $cluster ]]; then
	carburator print terminal error \
		"Could not load cluster name from .provider.exec.json"
	exit 120
fi

export TF_VAR_cluster="$cluster"

# Set nodes array as servers config source.
nodes=$(carburator get json nodes array-raw \
	--path "$terraform_resources/.provider.exec.json")

if [[ -z $nodes ]]; then
	carburator print terminal error \
		"Could not load nodes array from .provider.exec.json"
	exit 120
fi

export TF_VAR_nodes="$nodes"


provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" apply -auto-approve
	terraform -chdir="$1" output -json > "$2"

	# Assuming create failed as we cant load the output
	if ! carburator has json node.value --path "$2"; then
		carburator print terminal error "Create nodes failed."
		return 110
	fi
}

provisioner_call "$resource_dir" "$output"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator print terminal success "Create nodes succeeded."
	
	# Register IP address blocks and addresses
	carburator print terminal info "Extracting IP address blocks..."

	len=$(carburator get json node.value array --path "$output" | wc -l)
	for (( i=0; i<len; i++ )); do
		# Easiest way to find the right node is with it's UUID
		node_uuid=$(carburator get json "node.value.$i.labels.uuid" string -p "$output")

		# With Hetzner we know ipv4 comes without cidr. That's pretty obvious as these
		# blocks are expensive and ipv4's are running out.
		#
		# We have to define the CIDR block we use.
		# register-block value could be suffixed with /32 as well but lets leave a
		# reminder how to use the --cidr flag.
		ipv4=$(carburator get json "node.value.$i.ipv4" string -p "$output")

		# Register block and extract first (and the only) ip from it.
		if [[ -n $ipv4 && $ipv4 != null ]]; then
			address_block_uuid=$(carburator address register-block "$ipv4" \
				--extract \
				--ip "$ipv4" \
				--uuid \
				--cidr 32) || exit 120

			# Point address to node.
			carburator node address \
				--node-uuid "$node_uuid" \
				--address-uuid "$address_block_uuid"
		fi

		# Hetzner gives with each ipv6 address a full /64 block so let's register
		# that then.
		ipv6_block=$(carburator get json "node.value.$i.ipv6_block" string -p "$output")
		
		# Register block and the IP that Hetzner has set up for the node.
		if [[ -n $ipv6_block && $ipv6_block != null ]]; then
			ipv6=$(carburator get json "node.value.$i.ipv6" string -p "$output")

			# This is the other way to handle the address block registration.
			# register-block value has /cidr.
			address_block_uuid=$(carburator address register-block "$ipv6_block" \
				--uuid \
				--extract \
				--ip "$ipv6") || exit 120

			# Point address to node.
			carburator node address \
				--node-uuid "$node_uuid" \
				--address-uuid "$address_block_uuid" || exit 120
		fi
	done

	carburator print terminal success "IP address blocks registered."
elif [[ $exitcode -eq 110 ]]; then
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode"
	exit 120
fi
