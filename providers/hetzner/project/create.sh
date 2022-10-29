#!/bin/bash

# TODO: following env should be present
# PROVIDER_NAME = "hetzner"
# PROVIDER_DEFAULT = true
# PROVIDER_SECRET_0 = hetzner_cloud_apikey
# PROVIDER_TARGET = "production"
# PROVIDER_PATH = "/home/..../providers/service/{name}"

# PROVISIONER_NAME = "terraform"
# PROVISIONER_BIN = "\"terraform\""
# PROVISIONER_default = true
# PROVISIONER_retry_times = 3
# PROVISIONER_retry_interval = 10
# PROVISIONER_boot_wait = 20
# PROVISIONER_target = "production"
# PROVISIONER_PROVIDER_PATH = "/home/..../provisioners/{name}/providers{service_provider}"
# PROVISIONER_HOME = "/home/..../provisioners/{name}"

# TODO: not needed here but every script execution should include envs from project.toml
project="$1"
pr_id="$2"

# Register project with hetzner. Adds ssh key for project root.
# TODO: these are fixed now. Needs path to project private and public dirs.
key_path=$(get-env EXECUTOR_SSH_KEY "$PWD/.env")
keypub_path=$(get-env EXECUTOR_SSH_KEY_PUB "$PWD/.env")
comm=$(awk '{print $3}' "$keypub_path")

# Create terraform data dir beforehand to avoid warnings.
mkdir -p "$PROVISIONER_HOME/.terraform"

###
# Get API token from secrets or fail early.
#
token=$(carburator get secret "$PROVIDER_SECRET_0") || exit 1
if [[ -z $token ]]; then
	carburator fn paint red \
		"Hetzner API token from secret came back empty. Unable to proceed"
fi

export TF_DATA_DIR="$PROVISIONER_HOME/.terraform"
export TF_PLUGIN_CACHE_DIR="$PROVISIONER_HOME/.terraform"

export TF_VAR_api_token="$token"
export TF_VAR_sshkey="{name = \"$comm\", path = \"$key_path\"}"
# TODO: project.toml > env
export TF_VAR_identifier="$project"

terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" init
terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" apply -auto-approve
terraform -chdir="$PROVISIONER_PROVIDER_PATH/.tf-project" output -json > \
	"$PROVISIONER_PATH/project.json"

