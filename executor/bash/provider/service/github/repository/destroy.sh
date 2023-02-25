#!/usr/bin/env bash

resource="repository"
resource_dir="$PROVISIONER_GIT_PROVIDER_PATH/.tf-$resource"
output="$PROVISIONER_GIT_PROVIDER_PATH/$resource.json"

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVISIONER_GIT_PROVIDER_SECRET_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator print terminal error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

export TF_VAR_access_token="$token"
export TF_VAR_name="$PROJECT_IDENTIFIER"
export TF_VAR_description=""

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" destroy -auto-approve || return 1
}

if provisioner_call "$resource_dir"; then
	carburator print terminal success "Terraform provisioner terminated successfully"

	rm -rf "$resource_dir"
	rm -f "$output"

	carburator print terminal success "Repository destroyed from git provider Github"
else
	exit 110
fi
