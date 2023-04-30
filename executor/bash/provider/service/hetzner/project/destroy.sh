#!/usr/bin/env bash

resource="project"
resource_dir="$INVOCATION_PATH/terraform"
output="$INVOCATION_PATH/$resource.json"

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRETS_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

export TF_VAR_apitoken="$token"
export TF_VAR_keyname="${PROJECT_IDENTIFIER}-root"
export TF_VAR_pubkey="$SSHKEY_ROOT_PUBLIC"
export TF_VAR_identifier="$PROJECT_IDENTIFIER"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" destroy -auto-approve || return 1
}

if provisioner_call "$resource_dir"; then
	carburator print terminal success "Terraform provisioner terminated successfully"

	rm -rf "$resource_dir"
	rm -f "$output"

	carburator print terminal success "Project destroyed from service provider Hetzner"
else
	exit 110
fi
