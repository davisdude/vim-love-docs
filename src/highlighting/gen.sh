#!/bin/sh
cd "$(dirname "$0")"
set -e
rm -rf love-api
git clone https://github.com/love2d-community/love-api
love .> out.txt
rm -rf love-api
mv out.txt ../after/syntax/lua.vim