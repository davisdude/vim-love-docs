#!/bin/sh
cd "$(dirname "$0")"
set -e
mkdir -p ../../doc/
love .> ../../doc/love.txt
vim -c "helptags ../../doc/" -c "qa!"
rm -rf love-api

