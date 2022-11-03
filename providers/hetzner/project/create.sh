#!/bin/bash

# ATTENTION: Scripts run from carburator project's public root directory:
# echo "$PWD"

# ATTENTION: to check the environment variables uncomment:
# env

# ATTENTION: Default exit codes for informing carburator's script runner:
# exitcode_can_retry = 110
# exitcode_unrecoverable = 120

carburator fn paint green "Invoking Terraform provisioner..."

###
# Registers project with hetzner and adds ssh key for project root.
#

# Make sure terraform directories exist. 
mkdir -p "$PROVISIONER_HOME/.terraform" "$PROVISIONER_PROVIDER_PATH/.tf-project"

# Copy terraform configuration files to .tf-project dir (don't overwrite)
# These files can be modified without risk of unwarned overwrite.
while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$PROVISIONER_PROVIDER_PATH/.tf-project/$file"
done < <(find "$PROVISIONER_PROVIDER_PATH/project" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVIDER_SECRET_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator fn paint red \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

export TF_VAR_apitoken="$token"
export TF_VAR_keyname="root"
export TF_VAR_pubkey="$SSHKEY_ROOT_PUBLIC"
export TF_VAR_identifier="$PROJECT_IDENTIFIER"

provisioner_call() {
	terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" init || return 1
	terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" apply -auto-approve || return 1
	terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" output -json > \
		"$PROVISIONER_PATH/project.json" || return 1
}

# Analyze output json to determine if project was registered OK.
if provisioner_call; then
	keyname=$(jq -rc ".project.value.sshkey_name" "$PROVISIONER_PATH/project.json")
	key_id=$(jq -rc ".project.value.sshkey_id" "$PROVISIONER_PATH/project.json")
	
	# Assuming terraform failed as output doesn't have what was expected.
	if [[ -z $key_id || -z $keyname ]]; then
		rm -f "$PROVISIONER_PATH/project.json"
		exit 110
	fi

# Terraform call failed.
else
	rm -f "$PROVISIONER_PATH/project.json"
	exit 110
fi
