#!/usr/bin/env bash

# TODO: environment.

local app="$1" lscope="$2" tf_context volumes names rundir;
rundir=$(project-rundir)
tf_context="$PWD/$app/.tf-volume";

# Don't bother without resources.
if [[ ! -e "$PWD/$app/volume.json" ]]; then
	echo-error "Fail. volume.json was not found." && return 1
fi

# Scope of destruction can be defined with an argument
if [[ -z $lscope ]]; then
	volumes=$(jq -rc ".volumes.value" "$PWD/$app/volume.json")
else
	names=$(arr-to-jsonarr "${lscope//, / }")
	volumes=$(jq -rc \
	  ".volumes.value[] | select([.name] | inside($names))" \
	  "$PWD/$app/volume.json")
	fi

	export TF_VAR_hcloud_token="$cloud_token"
	export TF_VAR_volumes="$volumes"
	export TF_DATA_DIR="$rundir/.terraform"
	export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

	if [[ -e $tf_context ]]; then
	terraform -chdir="$tf_context" init
	terraform -chdir="$tf_context" destroy -auto-approve

	echo-success "Service provider volume for $app destroyed"
fi

