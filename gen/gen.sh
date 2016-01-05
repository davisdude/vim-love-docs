#!/bin/sh
cd "$(dirname "$0")"
set -e
rm -rf love-api
git clone https://github.com/rm-code/love-api
love .> out.txt
rm -rf love-api
mv out.txt ../syntax/lua.vim