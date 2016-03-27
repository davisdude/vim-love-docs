#!/bin/sh
cd "$(dirname "$0")"
set -e
rm -rf love-api
git clone https://github.com/love2d-community/love-api
mkdir -p ../../after/syntax/
love lua > ../../after/syntax/lua.vim
love love-conf > ../../after/syntax/love-conf.vim
rm -rf love-api
