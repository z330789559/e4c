#!/bin/bash

# check dependencies are available.
for i in jq sui; do
  if ! command -V ${i} 2>/dev/null; then
    echo "${i} is not installed"
    exit 1
  fi
done

# default network is testnet
NETWORK="https://fullnode.testnet.sui.io:443"

# If otherwise specified chose testnet or devnet
if [ $# -ne 0 ]; then
  if [ $1 = "testnet" ]; then
    NETWORK="https://fullnode.testnet.sui.io:443"
  fi
  if [ $1 = "devnet" ]; then
    NETWORK="https://fullnode.devnet.sui.io:443"
  fi
fi

publish_res=$(sui client publish --gas-budget 200000000 --json ../e4c)

echo ${publish_res} | jq '.' > .publish.res_e4c.json

if [[ "$publish_res" =~ "error" ]]; then
  # If yes, print the error message and exit the script
  echo "Error during move contract publishing.  Details : $publish_res"
  exit 1
fi
echo "Contract Deployment finished!"

echo "Setting up environmental variables..."

DIGEST=$(echo "${publish_res}" | jq -r '.digest')
# Extract PACKAGE_ID using the correct jq query
PACKAGE_ID=$(echo "${publish_res}" | jq -r '.objectChanges[] | select(.type == "published").packageId')

# Checking if the PACKAGE_ID is extracted successfully
if [ -z "$PACKAGE_ID" ]
then
  echo "Failed to extract PACKAGE_ID"
  exit 1
else
  echo "PACKAGE_ID extracted: $PACKAGE_ID"
fi

echo "update E4C Move.toml file"
# Update Move.toml with the extracted packageId on macOS
sed -i '' "s/e4c = \"0x0\"/e4c = \"$PACKAGE_ID\"/" ../e4c/Move.toml

sed -i '' "/^edition = \"2024.beta\"$/a\\
published-at = \"$PACKAGE_ID\"
" ../e4c/Move.toml

echo "E4C Move.toml updated "

echo "update E4C staking Move.toml file"

awk -v package_id="$PACKAGE_ID" '
  BEGIN { in_addresses = 0 }
  /^\[package\]/ { in_addresses = 0 }
  /^\[addresses\]/ { in_addresses = 1 }
  /^#/ { print; next } # Keep comments untouched.
  in_addresses && /e4c =/ {
    sub(/"0x0"/, "\"" package_id "\"")
  }
  { print }
' ../e4c_staking/Move.toml > ../e4c_staking/Move.tmp && mv ../e4c_staking/Move.tmp ../e4c_staking/Move.toml

echo "E4C staking Move.toml updated "

cat >src/.env <<-API_ENV
SUI_NETWORK=$NETWORK
DIGEST=$DIGEST
E4C_PACKAGE=$PACKAGE_ID
API_ENV