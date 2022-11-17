#!/usr/bin/env bash


carburator fn echo info "Invoking Terraform provisioner..."

###
# Registers project with hetzner and adds ssh key for project root.
#
resource_dir="$PROVISIONER_PROVIDER_PATH/.tf-project"
output="$PROVISIONER_PROVIDER_PATH/project.json"

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVIDER_SECRET_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator fn echo error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

export TF_VAR_apitoken="$token"
export TF_VAR_keyname="${PROJECT_IDENTIFIER}-root"
export TF_VAR_pubkey="$SSHKEY_ROOT_PUBLIC"
export TF_VAR_identifier="$PROJECT_IDENTIFIER"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" destroy -auto-approve || return 1
}

if provisioner_call "$resource_dir"; then
	carburator fn echo success "Terraform provisioner terminated successfully"

	rm -rf "$resource_dir"
	rm -f "$output"

	carburator fn echo success "Project destroyed from service provider Hetzner"
else
	exit 110
fi
