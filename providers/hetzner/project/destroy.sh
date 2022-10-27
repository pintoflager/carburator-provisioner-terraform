#!/bin/bash

# TODO: pass environment variables to script before exec.

# TODO: try to make as generic as possible.

local project="$1" pr_id="$2" tf_context key_path keypub_path ssh_name rundir;
rundir="$PWD/$pr_id"
tf_context="$rundir/.tf-$project"
key_path=$(get-env EXECUTOR_SSH_KEY "$PWD/.env")
keypub_path=$(get-env EXECUTOR_SSH_KEY_PUB "$PWD/.env")

ssh_name=$(awk '{print $2}' "$keypub_path")

export TF_VAR_hcloud_token="$cloud_token"
export TF_VAR_sshkey="{\name = \"$ssh_name\", \path = \"$key_path\"}"
export TF_VAR_identifier="$project"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

if [[ -e $tf_context ]]; then
	terraform -chdir="$tf_context" init
	terraform -chdir="$tf_context" destroy -auto-approve

	# Destroy terraform resources and output for project
	rm -rf "$tf_context"
	rm -f "$rundir/$project.json"

	echo-success "Project destroyed from service provider Hetzner"
fi

