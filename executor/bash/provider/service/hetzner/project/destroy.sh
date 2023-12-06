#!/usr/bin/env bash

carburator log info "Invoking Terraform project provisioner..."

###
# Registers project with hetzner and adds ssh key for project root.
#
resource="project"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Make sure terraform directories exist.
mkdir -p "$PROVISIONER_PATH/.terraform" "$resource_dir"

# Copy terraform configuration files to .tf-project dir (don't overwrite)
# These files can be modified without risk of unwarned overwrite.
while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$resource_dir/$file"
done < <(find "$terraform_sourcedir" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail early.
#
user=${PROVISIONER_SERVICE_PROVIDER_PACKAGE_USER_PUBLIC_IDENTIFIER:-root}
token=$(carburator get secret "$PROVISIONER_SERVICE_PROVIDER_SECRETS_0" \
	--user "$user"); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load Hetzner API token from secret. Unable to proceed"
	exit 120
fi

export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

export TF_VAR_apitoken="$token"
export TF_VAR_keyname="${PROJECT_IDENTIFIER}-root"
export TF_VAR_pubkey="$ROOT_SSH_PUBKEY"
export TF_VAR_identifier="$PROJECT_IDENTIFIER"

provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" destroy -auto-approve
}

# Analyze output json to determine if project was registered OK.
provisioner_call "$resource_dir"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator log success "Project resources destroyed with Terraform successfully"
else
	carburator log error \
		"Terraform project destroy failed with exitcode $exitcode"
	exit 120
fi
