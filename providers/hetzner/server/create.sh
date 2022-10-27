#!/bin/bash

# TODO: environment variables for the script.

app="$1" domain="$2"
tf_context="$PWD/$app/.tf-server"
servers_json="$PWD/$app/server.json"
rundir=$(project-rundir)

app_id=$(get-env IDENTIFIER "$PWD/$app/.env")
ssh_key_id=$(get-env PROJECT_SSH_KEY_ID)
declare -a servers;

# Quantity of servers to provision is determined from created server instances
server_instance_dir="$PWD/$app/server_instances"
index=0;
while read -r server; do
	sn=$(get-var serv_name "$server_instance_dir/$server")
	st=$(get-var serv_type "$server_instance_dir/$server")
	sl=$(get-var serv_location "$server_instance_dir/$server")
	si=$(get-var serv_image "$server_instance_dir/$server")
	v4=$(get-var serv_provision_ipv4 "$server_instance_dir/$server")
	v6=$(get-var serv_provision_ipv6 "$server_instance_dir/$server")
	servers+=(
"{\"name\":\"$sn\",\"type\":\"$st\",\"image\":\"$si\",\"location\":\"$sl\",\
\"ipv4_enabled\":\"$v4\",\"ipv6_enabled\":\"$v6\"}"
)

	index=$((index + 1))
done <<< "$(lsf "$server_instance_dir")"

# Array to comma separated string. TF_VAR_servers removes trailing comma
# and adds brackets to form an json array.
printf -v joined '%s,' "${servers[@]}"

export TF_VAR_hcloud_token="$cloud_token"
export TF_VAR_servers="[${joined%,}]"
export TF_VAR_domain="$domain"
export TF_VAR_identifier="$app_id"
export TF_VAR_ssh_id="$ssh_key_id"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

terraform -chdir="$tf_context" init
terraform -chdir="$tf_context" apply -auto-approve
terraform -chdir="$tf_context" output -json > "$servers_json"

