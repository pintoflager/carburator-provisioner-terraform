#!/usr/bin/env bash

carburator log info "Invoking Digital Ocean's Terraform server provisioner..."

resource="node"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/digitalocean"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
node_out="$data_dir/$resource.json"
project_out="$data_dir/project.json"

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
		"Could not load Digital Ocean API token from secret. Unable to proceed"
	exit 120
fi

sshkey_id=$(carburator get json project.value.sshkey_id string \
	-p "$project_out"); exitcode=$?

if [[ -z $sshkey_id || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load $PROVIDER_NAME sshkey id. Unable to proceed."
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_ssh_id="$sshkey_id"
export TF_VAR_project_id="$PROJECT_IDENTIFIER"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

# Set nodes array as servers config source.
nodes=$(carburator get json nodes array-raw -p .exec.json)

if [[ -z $nodes ]]; then
	carburator log error "Could not load nodes array from .exec.json"
	exit 120
fi

export TF_VAR_nodes="$nodes"


provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" apply -auto-approve
	terraform -chdir="$1" output -json > "$2"

	# Assuming create failed as we cant load the output
	if ! carburator has json node.value -p "$2"; then
		carburator log error "Create nodes failed."
		return 110
	fi
}

provisioner_call "$resource_dir" "$node_out"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator log success \
		"Server nodes created successfully with Terraform."

	len=$(carburator get json node.value array -p "$node_out" | wc -l)
	for (( i=0; i<len; i++ )); do
		# Easiest way to find the right node is with it's UUID
		node_uuid=$(carburator get json "node.value.$i.labels.uuid" string -p "$node_out")

		name=$(carburator get json "node.value.$i.name" string -p "$node_out")
		carburator log info "Locking node '$name' provisioner to Terraform..."
		carburator node lock-provisioner 'terraform' --node-uuid "$node_uuid"

		# With Digital Ocean we know ipv4 comes without cidr. That's pretty obvious as these
		# blocks are expensive and ipv4's are running out.
		#
		# We have to define the CIDR block we use.
		# register-block value could be suffixed with /32 as well but lets leave a
		# reminder how to use the --cidr flag.
		ipv4=$(carburator get json "node.value.$i.ipv4" string -p "$node_out")

		# Register block and extract first (and the only) ip from it.
		if [[ -n $ipv4 && $ipv4 != null ]]; then
			carburator log info \
				"Extracting IPv4 address blocks from node '$name' IP..."

			address_block_uuid=$(carburator register net-block "$ipv4" \
				--extract \
				--ip "$ipv4" \
				--uuid \
				--provider digitalocean \
				--provisioner terraform \
				--cidr 32) || exit 120

			# Point address to node.
			carburator node address \
				--node-uuid "$node_uuid" \
				--address-uuid "$address_block_uuid"
		fi

		# Digital Ocean gives with each ipv6 address a full /64 block so let's register
		# that then.
		ipv6_block=$(carburator get json "node.value.$i.ipv6_block" string -p "$node_out")
		
		# Register block and the IP that Digital Ocean has set up for the node.
		if [[ -n $ipv6_block && $ipv6_block != null ]]; then
			carburator log info \
				"Extracting IPv6 address blocks from node '$name' IP..."

			ipv6=$(carburator get json "node.value.$i.ipv6" string -p "$node_out")

			# This is the other way to handle the address block registration.
			# register-block value has /cidr.
			address_block_uuid=$(carburator register net-block "$ipv6_block" \
				--uuid \
				--extract \
				--provider digitalocean \
				--provisioner terraform \
				--ip "$ipv6") || exit 120

			# Point address to node.
			carburator node address \
				--node-uuid "$node_uuid" \
				--address-uuid "$address_block_uuid" || exit 120
		fi
	done

	carburator log success "IP address blocks registered."
elif [[ $exitcode -eq 110 ]]; then
	carburator log error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator log error \
		"Terraform provisioner failed with exitcode $exitcode"
	exit 120
fi
