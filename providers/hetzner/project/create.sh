#!/bin/bash

# TODO: pass environment variables to script before exec.

# TODO: try to make as generic as possible.

project="$1" pr_id="$2" project_json rundir;

rundir="$PWD/$pr_id"
project_json="$rundir/$project.json"

# Register project with hetzner. Adds ssh key for project root user.
key_path=$(get-env EXECUTOR_SSH_KEY "$PWD/.env")
keypub_path=$(get-env EXECUTOR_SSH_KEY_PUB "$PWD/.env")
comm=$(awk '{print $3}' "$keypub_path")
tf_context="$rundir/.tf-$project"

# Create terraform data dir before hand to avoid warnings.
mkdir -p "$rundir/.terraform"

export TF_VAR_api_token="$cloud_token"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"
export TF_VAR_sshkey="{name = \"$comm\", path = \"$key_path\"}"
export TF_VAR_identifier="$project"

terraform -chdir="$tf_context" init
terraform -chdir="$tf_context" apply -auto-approve
terraform -chdir="$tf_context" output -json > "$project_json"

