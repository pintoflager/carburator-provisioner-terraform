#!/usr/bin/env bash

resource="node"
resource_dir="$INVOCATION_PATH/terraform"
output="$INVOCATION_PATH/$resource.json"

# Make sure terraform resource dir exist.
mkdir -p "$resource_dir"

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRETS_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load Digital Ocean API token from secret. Unable to proceed"
	exit 120
fi

sshkey_id=$(carburator get env "${PROVIDER_NAME}_ROOT_SSHKEY_ID" \
	--provisioner terraform); exitcode=$?

if [[ -z $sshkey_id || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load $PROVIDER_NAME sshkey id from terraform/.env. Unable to proceed"
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_ssh_id="$sshkey_id"
export TF_VAR_project_id="$PROJECT_IDENTIFIER"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

nodes=$(carburator get json nodes array-raw -p .exec.json)
export TF_VAR_nodes="$nodes"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" destroy -auto-approve || return 1
}

provisioner_call "$resource_dir"

rm -f "$output"