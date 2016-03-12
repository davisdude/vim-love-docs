#!/bin/sh
cd "$(dirname "$0")"
set -e
rm -rf love-api
git clone https://github.com/love2d-community/love-api
mkdir -p ../../after/syntax/
love .> ../../after/syntax/lua.vim
rm -rf love-api
