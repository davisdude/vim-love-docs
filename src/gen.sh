#!/bin/sh
cd "$(dirname "$0")"
rm -rf love-api
git clone https://github.com/love2d-community/love-api
cp -rf ./love-api/ ./syntax/love-api/
cp -rf ./love-api/ ./doc/love-api/

( "./doc/gen.sh" )
( "./syntax/gen.sh" )
rm -rf ./../plugin/
cp -rf ./plugin/ ./../plugin/

rm -rf ./love-api/
