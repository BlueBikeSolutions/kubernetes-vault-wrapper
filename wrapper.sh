#!/bin/bash

set -e
set -x

# Dir in which the rest of the kubernetes-vault files are found
VAULT_CONFIG_DIR="${TOKEN_CONFIG_DIR:-/var/run/secrets/boostport.com}"
# JSON file that containes data for connecting to Vault
VAULT_TOKEN_FILE="${TOKEN_CONFIG_FILE:-vault-token}"
# Cert file that kubernetes-vault creates if using a custom CA
VAULT_CA_FILE="${TOKEN_CONFIG_FILE:-ca.crt}"

# Env var prefix for config
PREFIX=FROMVAULT_
# Separator to separate location and param name
LOCATION_SEP=.

# Get the vars to set from env
OLDIFS="$IFS"
IFS=$'\n'
vars=($(env | grep "^$PREFIX"))
IFS="$OLDIFS"

jq_args=(--raw-output --exit-status)

# Wait for the token file
while [[ ! -e "$VAULT_CONFIG_DIR/$VAULT_TOKEN_FILE" ]]; do
  echo "Token config doesn't exist yet" >&2
  sleep 2
done

# Get the vault address from the config JSON
vault_addr="$(jq "${jq_args[@]}" '.vaultAddr' < "$VAULT_CONFIG_DIR/$VAULT_TOKEN_FILE")"
echo "Using vault at $vault_addr" >&2

# Get the vault token from the config JSON
vault_token="$(jq "${jq_args[@]}" '.clientToken' < "$VAULT_CONFIG_DIR/$VAULT_TOKEN_FILE")"

# Setup curl args with vault token
curl_args=(--header "X-Vault-Token:$vault_token" --silent --fail)

# Add curl args to use the CA if one is given
if [[ -e "$VAULT_CONFIG_DIR/$VAULT_CA_FILE" ]]; then
  curl_args+=(--cacert "$VAULT_CONFIG_DIR/$VAULT_CA_FILE")
fi

# Wait for vault
while ! curl "$vault_addr/v1/sys/health" "${curl_args[@]}"; do
  echo "Vault isn't ready yet" >&2
  sleep 2
done

# Loop all vars, get their values, set their env
for var in "${vars[@]}"; do
  # Split the env line into the final var name, and the location.param
  name="$(echo "$var" | awk '{split($0, a, "="); sub(/^'"$PREFIX"'/, "", a[1]); print a[1]}')"
  value="$(echo "$var" | awk '{split($0, a, "="); print a[2]}')"

  # Split the location into location and param pair (or use "value" if no param)
  location="$(echo $value | awk '{split($0, a, "'"$LOCATION_SEP"'"); sub(/^\/?/, "", a[1]); print a[1]}')"
  param="$(echo $value | awk '{split($0, a, "'"$LOCATION_SEP"'"); print a[2]}')"
  param="${param:-value}"

  echo "Setting $name from $location using the $param parameter" >&2

  # Get the value from Vault
  data="$(curl "${curl_args[@]}" "$vault_addr/v1/$location")"

  # Extract the secret
  set +e
  secret="$(echo "$data" | jq "${jq_args[@]}" ".data.$param")"
  jq_rc=$?
  set -e

  if [[ $jq_rc -ne 0 ]]; then
    echo "Couldn't find $param in $location" >&2
    exit 1
  fi

  # Export the secret
  eval "export $name='$secret'"
done

# Replace ourself with the command args
exec "$@"
