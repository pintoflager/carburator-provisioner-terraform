#!/usr/bin/env bash

# TODO: environment.

app="$1"
vol_instance_dir="$PWD/$app/volume_instances"
rundir=$(project-rundir)
vol_json="$PWD/$app/volume.json"
loc=$(get-env DEFAULT_SERVER_LOCATION "$PWD/$app/.env")
tf_context="$PWD/$app/.tf-volume"
declare -a volumes;

# Quantity of volumes is determined from provisioned server instances
while read -r vol; do
	name=$(get-var vol_name "$vol_instance_dir/$vol")
	server_name=$(get-var vol_attached "$vol_instance_dir/$vol")
	size=$(get-var vol_size "$vol_instance_dir/$vol")
	format=$(get-var vol_format "$vol_instance_dir/$vol")

	# Search for the server to attach the volume to.
	if [[ -n $server_name ]]; then
	  # Server name provided but server.json was not found.
	  if [[ ! -e $PWD/$app/server.json ]]; then
		echo-error "Unable to locate server id for volume from '$app'" && return 1
	  fi

	  # Take server id from server.json where server instance name matches node name.
	  sid=$(jq -rc \
		".servers.value[] | select(.name == \"$server_name\") | .id" \
		"$PWD/$app/server.json")

	  if [[ -z $sid ]]; then
		echo-error "Server id not found for volume '$name', volume will" \
		  "be created but left unassigned"
	  else
		volumes+=(
		  "{\"name\":\"$name\",\"server_id\":$sid,\"size\":$size,\"format\":\"$format\"}"
		)

		# Next please.
		continue
	  fi
	fi

	# Volume can be left as un-attached. Stupid but possible.
	# In this case we need the location of the volume.
	volumes+=(
	  "{\"name\":\"$name\",\"location\":\"$loc\",\"size\":$size,\"format\":\"$format\"}"
	)
done <<< "$(lsf "$vol_instance_dir")"

# Array to comma separated string. TF_VAR_volumes removes trailing comma
# and adds brackets to form an json array.
printf -v joined '%s,' "${volumes[@]}"

export TF_VAR_hcloud_token="$cloud_token"
export TF_VAR_volumes="[${joined%,}]"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

terraform -chdir="$tf_context" init
terraform -chdir="$tf_context" apply -auto-approve
terraform -chdir="$tf_context" output -json > "$vol_json"

