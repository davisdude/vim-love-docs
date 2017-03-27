#!/bin/sh
cd "$(dirname "$0")"
set -e

cp -rf ./love-api/ ./love-conf/love-api/
cp -rf ./love-api/ ./lua/love-api/

mkdir -p ../../after/syntax/
love lua > ../../after/syntax/lua.vim
love love-conf > ../../after/syntax/love-conf.vim

rm -rf love-api
rm -rf love-conf/love-api
rm -rf lua/love-api
