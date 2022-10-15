#!/bin/bash

# Terraform is required.
if ! carburator fn integration-installed terraform; then
echo-error "Missing required program Terraform. Please install it" \
  "before running this script." && exit 1
fi

