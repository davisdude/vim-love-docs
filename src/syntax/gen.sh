#!/bin/bash

# Set the current directory to the location of this script
pushd "$(dirname "$0")"

# Quit on errors and unset vars
set -o errexit
set -o nounset

# Copy love-api to child directories
cp -rf love-api love-conf
cp -rf love-api lua

# Update after/syntax
rm -rf ../../after/syntax
mkdir -p ../../after/syntax

# Create syntax files
${lua:-lua} lua/main.lua > ../../after/syntax/lua.vim
${lua:-lua} love-conf/main.lua > ../../after/syntax/love-conf.vim

# Cleanup
rm -rf love-api
rm -rf love-conf/love-api
rm -rf lua/love-api

popd
