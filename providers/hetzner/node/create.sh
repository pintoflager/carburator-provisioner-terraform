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

sshkey_id=$(carburator get env "${PROVIDER_NAME}_ROOT_SSHKEY_ID" \
	--provisioner terraform); exitcode=$?

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
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" apply -auto-approve || return 1
	terraform -chdir="$1" output -json > "$2" || return 1

	# Assuming create failed as we cant load the output
	if ! carburator has json node.value --path "$2"; then
		carburator print terminal error "Create nodes failed."
		rm -f "$2"; return 1
	fi
}

# Analyze output json to determine if nodes were registered OK.
if provisioner_call "$resource_dir" "$output"; then
	carburator print terminal success "Create nodes succeeded."
	carburator print terminal info "Extracting IP address blocks..."

	len=$(carburator get json node.value array --path "$output" | wc -l)
	for (( i=0; i<len; i++ )); do
		# Easiest way to find the right node is with it's UUID
		node_uuid=$(carburator get json "node.value.$i.labels.uuid" string -p "$output")

		# With Hetzner we know ipv4 comes without cidr, obviously these blocks are
		# expensive and ipv4's running out. Will be suffixed with /32 automatically.
		ipv4=$(carburator get json "node.value.$i.ipv4" string -p "$output")

		# Register block and grab first (and only) ip from it.
		if [[ -n $ipv4 && $ipv4 != null ]]; then
			uuid=$(carburator address register-block "$ipv4" --grab --uuid) || exit 1
			carburator node address --node-uuid "$node_uuid" --address-uuid "$uuid"
		fi

		# Hetzner gives with each ipv6 address a full /64 block so let's register
		# that then.
		ipv6=$(carburator get json "node.value.$i.ipv6_block" string -p "$output")
		
		# Register block and grab first ip from it (same as node.value.$i.ipv6)
		if [[ -n $ipv6 && $ipv6 != null ]]; then
			uuid=$(carburator address register-block "$ipv6" --grab --uuid) || exit 1
			carburator node address --node-uuid "$node_uuid" --address-uuid "$uuid"
		fi
	done

else
	exit 110
fi
