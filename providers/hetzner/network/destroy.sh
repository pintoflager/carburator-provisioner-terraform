#!/usr/bin/env bash

# TODO: environment variables for the script.

local app="$1" lscope="$2" servers app_id ssh_key_id net_zone tf_context;
local server_json="$PWD/$app/server.json" rundir;
rundir=$(project-rundir)

# Don't bother without resources.
if [[ ! -e "$PWD/$app/server.json" ]]; then
	echo-error "Fail. server.json was not found." && return 1
fi

app_id=$(get-env IDENTIFIER "$PWD/$app/.env")
ssh_key_id=$(get-env PROJECT_SSH_KEY_ID)
net_zone=$(get-env NETWORK_ZONE "$PWD/$app/.env")
tf_context="$PWD/$app/.tf-server"

# Scope of destruction can be defined with an argument
if [[ -z $lscope ]]; then
	servers=$(jq -rc ".servers.value" "$server_json")
else
	local names; names=$(arr-to-jsonarr "${lscope//, / }")
	# REMEMBER: jq | how to select multiple matching objects from json array
	servers=$(jq -rc ".servers.value[] | select([.name] | inside($names))" \
	  "$server_json")
fi

export TF_VAR_hcloud_token="$cloud_token"
export TF_VAR_ssh_id="$ssh_key_id"
export TF_VAR_identifier="$app_id"
export TF_VAR_network_zone="$net_zone"
export TF_VAR_servers="$servers"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

if [[ -e $tf_context ]]; then
	terraform -chdir="$tf_context" init
	terraform -chdir="$tf_context" destroy -auto-approve
	echo-success "Service provider resource $app destroyed"
fi

