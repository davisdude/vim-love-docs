#!/bin/bash

# Set the current directory to the location of this script
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

# Quit on errors and unset vars
set -o errexit
set -o nounset

# Copy love-api to child directories
cp -rf love-api love-conf
cp -rf love-api lua

# Update after/syntax
rm -rf ../../after/syntax
mkdir -p ../../after/syntax

# Copy nongenerated help syntax
cp help.vim ../../after/syntax/.

# Create syntax files
$lua lua/main.lua > ../../after/syntax/lua.vim
$lua love-conf/main.lua > ../../after/syntax/love-conf.vim

# Cleanup
rm -rf love-api
rm -rf love-conf/love-api
rm -rf lua/love-api

popd > /dev/null
