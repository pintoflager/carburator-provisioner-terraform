#!/bin/bash

# ATTENTION: Scripts run from carburator project's public root directory:
# echo "$PWD"

# ATTENTION: to check the environment variables uncomment:
# env

###
# Registers project with hetzner and adds ssh key for project root.
#

# Create terraform data dir beforehand to avoid warnings.
mkdir -p "$PROVISIONER_HOME/.terraform"

###
# Get API token from secrets or fail early.
#
token=$(carburator get secret "$PROVIDER_SECRET_0") || exit 1
if [[ -z $token ]]; then
	carburator fn paint red \
		"Hetzner API token from secret came back empty. Unable to proceed"
fi

export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

export TF_VAR_apitoken="$token"
export TF_VAR_keyname="root"
export TF_VAR_pubkey="$SSHKEY_ROOT_PUBLIC"
export TF_VAR_identifier="$PROJECT_IDENTIFIER"

terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" init
terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" apply -auto-approve
terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" output -json > \
	"$PROVISIONER_PATH/project.json"

