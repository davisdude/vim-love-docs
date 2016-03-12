#!/bin/sh
cd "$(dirname "$0")"
set -e
rm -rf love-api
git clone https://github.com/love2d-community/love-api
mkdir -p ../../doc/
love .> ../../doc/love.txt
vim -c "helptags ../../doc/" -c "qa!"
rm -rf love-api

