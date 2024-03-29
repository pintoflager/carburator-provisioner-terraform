#!/usr/bin/env bash

carburator log info "Invoking Terraform github repository provisioner..."

###
# Creates repository to the managed github account.
#
resource="repository"
resource_dir="$PROVISIONER_GIT_PROVIDER_PATH/.tf-$resource"
output="$PROVISIONER_GIT_PROVIDER_PATH/$resource.json"

# Make sure terraform directories exist.
mkdir -p "$PROVISIONER_PATH/.terraform" "$resource_dir"

# Copy terraform configuration files to .tf-repository dir (don't overwrite)
# These files can be modified without risk of unwarned overwrite.
while read -r tf_file; do
	file=$(basename "$tf_file")
	cp -n "$tf_file" "$PROVISIONER_GIT_PROVIDER_PATH/.tf-$resource/$file"
done < <(find "$PROVISIONER_GIT_PROVIDER_PATH/$resource" -maxdepth 1 -iname '*.tf')

###
# Get API token from secrets or bail early.
#
token=$(carburator get secret "$PROVISIONER_GIT_PROVIDER_SECRETS_0" --user root); exitcode=$?

if [[ -z $token || $exitcode -gt 0 ]]; then
	carburator log error \
		"Could not load Github API token from secret. Unable to proceed"
	exit 120
fi

# TODO: prompt private / public var and save it as env or json or toml ....
export TF_VAR_visibility="TODO"

export TF_DATA_DIR="$PROVISIONER_PATH/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_PATH/.terraform"

export TF_VAR_access_token="$token"
export TF_VAR_name="$PROJECT_IDENTIFIER"
export TF_VAR_description="Automatically created and managed with git provider @ \
terraform"

provisioner_call() {
	terraform -chdir="$1" init || return 1
	terraform -chdir="$1" apply -auto-approve || return 1
	terraform -chdir="$1" output -json > "$2" || return 1

	# Assuming terraform failed as output doesn't have what was expected.
	local id;
	id=$(carburator get json repository.value.id string --path "$2") || return 1

	if [[ -z $id ]]; then
		rm -f "$2"; exit 110
	fi
}

# Analyze output json to determine if repository was registered OK.
if provisioner_call "$resource_dir" "$output"; then
	# Save repository urls to project repo toml.
	repo_path="$PROJECT_PUBLIC/repositories"
	repo_toml="$repo_path/$PROJECT_IDENTIFIER.toml"

	# Get and put
	https_clone=$(carburator get json repository.value.https_url \
		-p "$output") || exit 120
	carburator put toml url_https "$https_clone" -p "$repo_toml"

	ssh_clone=$(carburator get json repository.value.ssh_url \
		-p "$output") || exit 120
	carburator put toml url_ssh "$ssh_clone" -p "$repo_toml"

	carburator log success "Terraform provisioner terminated successfully"
fi
