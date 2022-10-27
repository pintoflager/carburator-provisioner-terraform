#!/bin/bash

local app="$1" cloud_token tf_context sp_secretkey cloud_token rundir;
rundir=$(project-rundir)
sp_secretkey=$(get-env SERVICE_PROVIDER_SECRET_KEY)
cloud_token=$(get-secret "$sp_secretkey")
tf_context="$PWD/$app/.tf-virtual_ip"

export TF_VAR_hcloud_token="$cloud_token"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

if [[ -e $tf_context ]]; then
	terraform -chdir="$tf_context" init
	terraform -chdir="$tf_context" destroy -auto-approve
	echo-success "Virtual IP addresses for $app destroyed"
fi

