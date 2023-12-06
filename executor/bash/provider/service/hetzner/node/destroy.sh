#!/usr/bin/env bash

carburator log info "Invoking Hetzner's Terraform server provisioner..."

resource="node"
resource_dir="$INVOCATION_PATH/terraform"
data_dir="$PROVISIONER_PATH/providers/hetzner"
terraform_sourcedir="$data_dir/$resource"

# Resource data paths
project_out="$data_dir/project.json"

# Make sure terraform resource dir exist.
mkdir -p "$resource_dir"

# Copy terraform files from package to execution dir.
# This way files can be modified and package update won't overwrite
# the changes.
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

sshkey_id=$(carburator get json project.value.sshkey_id string \
	-p "$project_out"); exitcode=$?

if [[ -z $sshkey_id || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load $PROVIDER_NAME sshkey id. Unable to proceed."
	exit 120
fi

export TF_VAR_hcloud_token="$token"
export TF_VAR_ssh_id="$sshkey_id"
export TF_VAR_project_id="$PROJECT_IDENTIFIER"
export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

# Set nodes array as servers config source.
nodes=$(carburator get json nodes array-raw -p .exec.json)

if [[ -z $nodes ]]; then
	carburator log error "Could not load nodes array from .exec.json"
	exit 120
fi

export TF_VAR_nodes="$nodes"


provisioner_call() {
	terraform -chdir="$1" init
	terraform -chdir="$1" destroy -auto-approve
}

provisioner_call "$resource_dir"; exitcode=$?

if [[ $exitcode -eq 0 ]]; then
	carburator log success \
		"Server nodes destroyed successfully with Terraform."
else
	carburator log error \
		"Terraform node destroy failed with exitcode $exitcode"
	exit 120
fi
