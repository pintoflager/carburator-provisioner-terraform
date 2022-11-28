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

identifier=$(carburator get env NODE_GROUP \
	--path "$PROVISIONER_PROVIDER_PATH/node/.provider.exec.env")
export TF_VAR_identifier="$identifier"

nodes_json=$(cat "$PROVISIONER_PROVIDER_PATH/node/.provider.exec.json")
export TF_VAR_servers="$nodes_json"



# declare -a servers;

# # Quantity of servers to provision is determined from created server instances
# server_instance_dir="$PWD/$app/server_instances"
# index=0;
# while read -r server; do
# 	sn=$(get-var serv_name "$server_instance_dir/$server")
# 	st=$(get-var serv_type "$server_instance_dir/$server")
# 	sl=$(get-var serv_location "$server_instance_dir/$server")
# 	si=$(get-var serv_image "$server_instance_dir/$server")
# 	v4=$(get-var serv_provision_ipv4 "$server_instance_dir/$server")
# 	v6=$(get-var serv_provision_ipv6 "$server_instance_dir/$server")
# 	servers+=(
# "{\"name\":\"$sn\",\"type\":\"$st\",\"image\":\"$si\",\"location\":\"$sl\",\
# \"ipv4_enabled\":\"$v4\",\"ipv6_enabled\":\"$v6\"}"
# )

# 	index=$((index + 1))
# done <<< "$(lsf "$server_instance_dir")"

# # Array to comma separated string. TF_VAR_servers removes trailing comma
# # and adds brackets to form an json array.
# printf -v joined '%s,' "${servers[@]}"

# export TF_VAR_servers="[${joined%,}]" # TODO: some better way to build that json.







provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" apply -auto-approve || return 1
	terraform -chdir="$1" output -json > "$2" || return 1

	# Assuming create failed as we cant load a zone id.
	if carburator get json servers.value array --path "$2"; then
		carburator print terminal error "Create nodes failed."
		rm -f "$2"; return 1
	fi
}

# Analyze output json to determine if nodes were registered OK.
if provisioner_call "$resource_dir" "$output"; then
	carburator print terminal success "Create nodes succeeded."	
else
	exit 110
fi
