#!/bin/bash

local app="$1" vip_json vip_instance_dir sp_secretkey cloud_token rundir;
local run_context="$PWD/$app/.tf-virtual_ip"
rundir=$(project-rundir)
vip_json="$PWD/$app/virtual_ip.json"
vip_instance_dir="$PWD/$app/virtual_ip_instances"
sp_secretkey=$(get-env SERVICE_PROVIDER_SECRET_KEY)
cloud_token=$(get-secret "$sp_secretkey")

# Quantity of virtual IP addresses is determined from provided vip instances
local vipv4_names vipv6_names vip vipname;
while read -r vip; do
vipname=$(grep "^vip_name:" "$vip_instance_dir/$vip" | awk -F': ' '{print $2}')
if grep -qE "^vip_provision_ipv4: true$" "$vip_instance_dir/$vip"; then
  if [[ -z $vipv4_names ]]; then vipv4_names="\"$vipname\""
  else vipv4_names="$vipv4_names,\"$vipname\""; fi
fi
if grep -qE "^vip_provision_ipv6: true$" "$vip_instance_dir/$vip"; then
  if [[ -z $vipv6_names ]]; then vipv6_names="\"$vipname\""
  else vipv6_names="$vipv6_names,\"$vipname\""; fi
fi
done <<< "$(lsf "$vip_instance_dir")"

export TF_VAR_hcloud_token="$cloud_token"
export TF_VAR_vip_v4="[$vipv4_names]"
export TF_VAR_vip_v6="[$vipv6_names]"
export TF_DATA_DIR="$rundir/.terraform"
export TF_PLUGIN_CACHE_DIR="$rundir/.terraform"

terraform -chdir="$run_context" init
terraform -chdir="$run_context" apply -auto-approve
terraform -chdir="$run_context" output -json > "$vip_json"

# Retry if we have empty response.
provider-response-valid "$vip_json" || provision-virtual_ip "$@"

