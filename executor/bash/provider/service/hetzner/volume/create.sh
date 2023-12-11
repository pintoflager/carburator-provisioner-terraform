#!/usr/bin/env bash

carburator log info "Invoking Hetzner's Terraform server provisioner..."

tag=$(carburator get env VOLUME_NAME -p .exec.env)
size=$(carburator get env VOLUME_SIZE -p .exec.env)
filesystem=$(carburator get env VOLUME_FILESYSTEM -p .exec.env)

if [[ -z $tag ]]; then
    carburator log error "Volume name missing from exec.env"
    exit 120
fi

resource="volume"
resource_dir="$INVOCATION_PATH/terraform_$tag"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
node_out="$data_dir/node.json"
vol_out="$data_dir/${resource}_$tag.json"

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
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_volume_name="$tag"
export TF_VAR_volume_size="$size"
export TF_VAR_volume_filesystem="$filesystem"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

nodes=$(carburator get json nodes array-raw -p .exec.json)

if [[ -z $nodes ]]; then
	carburator log error "Could not load nodes array from .exec.json"
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
	if ! carburator has json volume.value -p "$2"; then
		carburator log error "Create volume failed."
		return 110
	fi
}

provisioner_call "$resource_dir" "$vol_out"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator log success \
		"Node volume(s) created successfully with Terraform."
elif [[ $exitcode -eq 110 ]]; then
	carburator log error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator log error \
		"Terraform provisioner failed with exitcode $exitcode"
	exit 120
fi

# Loop all created volumes and register node trails.
vol_len=$(carburator get json volumes.value array --path "$vol_out" | wc -l)
node_len=$(carburator get json node.value array --path "$node_out" | wc -l)

for (( a=0; a<vol_len; a++ )); do
    server_id=$(carburator get json "volumes.value.$a.server_id" string -p "$vol_out")
    vol_id=$(carburator get json "volumes.value.$a.id" string -p "$vol_out")
    vol_trail="/mnt/HC_Volume_${vol_id}"
	
    # Loop all nodes from node.json, compare server_id's and add trail
    for (( g=0; g<node_len; g++ )); do
        node_id=$(carburator get json "node.value.$g.id" string -p "$node_out")

        # Not what we're looking for, next round please.
        if [[ $node_id != "$server_id" ]]; then continue; fi

        # Easiest way to locate the right node is with it's UUID
        node_uuid=$(carburator get json "node.value.$g.labels.uuid" string \
            -p "$node_out")

        carburator node trail \
            "$tag" \
            "$vol_trail"\
            --node-uuid "$node_uuid"; exitcode=$?

        if [[ $exitcode -gt 0 ]]; then
            carburator log error \
                "Unable to register trail to volume $vol_id on node $node_id"
            exit 120
        fi

        # Next volume
        continue 2;
    done

    # We should be able to find all nodes, if not, well, shit.
    carburator log error \
        "Unable to find node matching server_id $server_id from volume"
    exit 120
done
