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

# Create terraform data dir beforehand to avoid warnings.
mkdir -p "$PROVISIONER_HOME/.terraform"

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
	terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" init
	terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" apply -auto-approve
	terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" output -json > \
		"$PROVISIONER_PATH/project.json"
}

# TODO: analyze output json, if it looks like it failed delete json and retry?
provisioner_call
