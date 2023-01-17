#!/usr/bin/env bash

carburator print terminal info "Invoking Hetzner's Terraform server provisioner..."

###
# Registers project with hetzner and adds ssh key for project root.
#

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

resource="node"
resource_dir="$PROVISIONER_PROVIDER_PATH/.tf-$resource"
output="$PROVISIONER_PROVIDER_PATH/$resource.json"

# Make sure terraform resource dir exist.
mkdir -p "$resource_dir"

while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$PROVISIONER_PROVIDER_PATH/.tf-$resource/$file"
done < <(find "$PROVISIONER_PROVIDER_PATH/$resource" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVIDER_SECRET_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

project_output="$PROVISIONER_PROVIDER_PATH/project.json"
sshkey_id=$(carburator get json project.value.sshkey_id string \
	-p "$project_output"); exitcode=$?

if [[ -z $sshkey_id || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load $PROVIDER_NAME sshkey id from terraform/.env. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_ssh_id="$sshkey_id"
export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

node_group=$(carburator get json node_group_name string \
	--path "$PROVISIONER_PROVIDER_PATH/$resource/.provider.exec.json")
export TF_VAR_node_group="$node_group"

nodes=$(carburator get json nodes array-raw \
	--path "$PROVISIONER_PROVIDER_PATH/$resource/.provider.exec.json")
export TF_VAR_nodes="$nodes"


provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" apply -auto-approve
	terraform -chdir="$1" output -json > "$2"

	# Assuming create failed as we cant load the output
	if ! carburator has json node.value --path "$2"; then
		carburator print terminal error "Create nodes failed."
		rm -f "$2"; return 110
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

		# Register block and grab first (and only) ip from it.
		if [[ -n $ipv4 && $ipv4 != null ]]; then
			address_block_uuid=$(carburator-rule address register-block "$ipv4" \
				--grab \
				--grab-ip "$ipv4" \
				--uuid \
				--cidr 32) || exit 120

			# Point address to node.
			carburator-rule node address \
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
			address_block_uuid=$(carburator-rule address register-block "$ipv6_block" \
				--uuid \
				--grab \
				--grab-ip "$ipv6") || exit 120

			# Point address to node.
			carburator-rule node address \
				--node-uuid "$node_uuid" \
				--address-uuid "$address_block_uuid" || exit 120
		fi
	done
elif [[ $exitcode -eq 110 ]]; then
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode"
	exit 120
fi
