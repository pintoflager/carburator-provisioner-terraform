#!/usr/bin/env bash


carburator print terminal info "Invoking Hetzner's Terraform server provisioner..."

tag=$(carburator get env IP_NAME -p .exec.env)
ipv4=$(carburator get env IP_V4 -p .exec.env || echo "false")
ipv6=$(carburator get env IP_V6 -p .exec.env || echo "false")

if [[ -z $tag ]]; then
    carburator print terminal error "Floating IP name missing from exec.env"
    exit 120
fi

if [[ $ipv4 == false && $ipv6 == false ]]; then
    carburator print terminal error \
        "Trying to create floating IP without defining IP protocol."
    exit 120
fi

resource="floating_ip"
resource_dir="$INVOCATION_PATH/terraform_$tag"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
node_out="$data_dir/node.json"
fip_out="$data_dir/${resource}_$tag.json"

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
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRETS_0" --user root)
exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_floating_ip_name="$tag"
export TF_VAR_floating_ip_v4="$ipv4"
export TF_VAR_floating_ip_v6="$ipv6"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

# We should have list of nodes where we plan to pingpong this IP on.
nodes=$(carburator get json nodes array-raw -p .exec.json)

if [[ -z $nodes ]]; then
	carburator print terminal error "Could not load nodes array from .exec.json"
	exit 120
fi

export TF_VAR_nodes="$nodes"

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
	if ! carburator has json floating_ip.value -p "$2"; then
		carburator print terminal error "Create floating IP failed."
		return 110
	fi
}

provisioner_call "$resource_dir" "$fip_out"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator print terminal success \
		"Floating IP address(es) created successfully with Terraform."

    # Check if IPv4 was provisioned
    fip4=$(carburator get json floating_ip.value.ipv4.ip_address \
        string -p "$fip_out")

    if [[ -n $fip4 ]]; then
        carburator print terminal info \
            "Extracting IPv4 address block from floating IP '$tag'..."
        
        v4_block_uuid=$(carburator register net-block "$fip4" \
            --extract \
            --ip "$fip4" \
            --uuid \
            --floating \
            --provider hetzner \
            --provisioner terraform \
            --cidr 32) || exit 120

        # Point address to node.
        v4_node_uuid=$(carburator get json floating_ip.value.ipv4.labels.primary \
            string -p "$fip_out")
        
        carburator node address \
            --node-uuid "$v4_node_uuid" \
            --address-uuid "$v4_block_uuid"

        carburator print terminal success "IPv4 address block registered."
    fi

	# Same as above but for IPv6 which is a real network block of /64
    fip6=$(carburator get json floating_ip.value.ipv6.ip_address \
        string -p "$fip_out")
    
    if [[ -n $fip6 ]]; then
        carburator print terminal info \
            "Extracting IPv6 address block from floating IP '$tag'..."
        
        block_v6=$(carburator get json floating_ip.value.ipv6.ip_network \
            string -p "$fip_out")

        v6_block_uuid=$(carburator register net-block "$block_v6" \
            --extract \
            --ip "$fip6" \
            --uuid \
            --floating \
            --provider hetzner \
            --provisioner terraform) || exit 120

        # Point address to node.
        v6_node_uuid=$(carburator get json floating_ip.value.ipv6.labels.primary \
            string -p "$fip_out")

        carburator node address \
            --node-uuid "$v6_node_uuid" \
            --address-uuid "$v6_block_uuid"

        carburator print terminal success "IPv6 address block registered."
    fi
elif [[ $exitcode -eq 110 ]]; then
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode"
	exit 120
fi
