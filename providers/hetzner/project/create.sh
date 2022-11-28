#!/usr/bin/env bash

# ATTENTION: Scripts run from carburator project's public root directory:
# echo "$PWD"

# ATTENTION: to check the environment variables uncomment:
# env

# ATTENTION: Default exit codes for informing carburator's script runner:
# exitcode_can_retry = 110
# exitcode_unrecoverable = 120

carburator print terminal info "Invoking Terraform project provisioner..."

###
# Registers project with hetzner and adds ssh key for project root.
#
resource="project"
resource_dir="$PROVISIONER_PROVIDER_PATH/.tf-$resource"
output="$PROVISIONER_PROVIDER_PATH/$resource.json"

# Make sure terraform directories exist.
mkdir -p "$PROVISIONER_HOME/.terraform" "$resource_dir"

# Copy terraform configuration files to .tf-project dir (don't overwrite)
# These files can be modified without risk of unwarned overwrite.
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

export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

export TF_VAR_apitoken="$token"
export TF_VAR_keyname="${PROJECT_IDENTIFIER}-root"
export TF_VAR_pubkey="$SSHKEY_ROOT_PUBLIC"
export TF_VAR_identifier="$PROJECT_IDENTIFIER"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" apply -auto-approve || return 1
	terraform -chdir="$1" output -json > "$2" || return 1

	# Assuming terraform failed as output doesn't have what was expected.
	local id name;
	id=$(carburator get json project.value.sshkey_id string --path "$2") || return 1
	name=$(carburator get json project.value.sshkey_name string --path "$2") || return 1

	if [[ -z $id || -z $name ]]; then
		rm -f "$2"; exit 110

	else
		# TODO: renamed var: PROJECT_SSH_KEY_NAME => SSH_KEY_NAME
		carburator put env "${PROVIDER_NAME}_ROOT_SSHKEY_NAME" "$name" \
			--provisioner terraform

		# TODO: renamed var: PROJECT_SSH_KEY_ID => SSH_KEY_ID
		carburator put env "${PROVIDER_NAME}_ROOT_SSHKEY_NAME" "$id" \
			--provisioner terraform
	fi
}

# Analyze output json to determine if project was registered OK.
if provisioner_call "$resource_dir" "$output"; then
	carburator print terminal success "Terraform provisioner terminated successfully"
fi
