#!/bin/sh
cd "$(dirname "$0")"
( "./doc/gen.sh" )
( "./syntax/gen.sh" )
rm -rf ./../plugin/
cp -rf ./plugin/ ./../plugin/
read 
