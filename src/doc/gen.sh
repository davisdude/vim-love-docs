#!/usr/bin/env sh

# Set the current directory to the location of this script
pushd "$(dirname "$0")"

# Quit on errors and unset vars
set -o errexit
set -o nounset

# Update the doc directory
rm -rf ../../doc
mkdir ../../doc

# Generate documentation
${lua:-lua} main.lua  > ../../doc/love.txt

# Generate helptags
${vim:-vim} -c "helptags ../../doc/" -c "qa!"

# Cleanup
rm -rf love-api

popd
