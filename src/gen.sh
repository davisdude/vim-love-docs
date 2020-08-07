#!/bin/bash

# Set the current directory to the location of this script
pushd "$(dirname "$0")" > /dev/null

# Quit on errors and unset vars
set -o errexit
set -o nounset

# Read in env.txt
while read var; do
	eval "$var"
done < env.txt

# Assign fallbacks in case the values are invalid
export lua=${lua:-lua}
export git=${git:-git}
export vim=${vim:-vim}

# Remove the old love-api and clone in the new one
rm -rf love-api
$git clone https://github.com/love2d-community/love-api

# Copy love-api to the specified directories
cp -rf love-api syntax
cp -rf love-api doc

# Run the generation scripts
source doc/gen.sh
source syntax/gen.sh

# Update the plugin
rm -rf ../plugin
cp -rf plugin ../

# Remove love-api
rm -rf love-api

popd > /dev/null
