#!/usr/bin/env bash

carburator print terminal info "Invoking Terraform project provisioner..."

###
# Registers project with digitalocean and adds ssh key for project root.
#
resource="project"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/digitalocean"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
project_out="$data_dir/$resource.json"

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
	carburator print terminal error \
		"Could not load Digital Ocean API token from secret. Unable to proceed"
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
	terraform -chdir="$1" apply -auto-approve
	terraform -chdir="$1" output -json > "$2"

	# Assuming terraform failed as output doesn't have what was expected.
	local id;
	id=$(carburator get json project.value.sshkey_id string --path "$2")

	if [[ -z $id ]]; then
		rm -f "$2"; return 110
	fi
}

# Analyze output json to determine if project was registered OK.
provisioner_call "$resource_dir" "$project_out"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator print terminal success "Terraform provisioner terminated successfully"
elif [[ $exitcode -eq 110 ]]; then
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode, allow retry..."
	exit 110
else
	carburator print terminal error \
		"Terraform provisioner failed with exitcode $exitcode"
	exit 120
fi
