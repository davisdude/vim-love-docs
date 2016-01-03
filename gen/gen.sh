#!/bin/sh

rm -r love-api
git clone https://github.com/rm-code/love-api
love .> out.txt
rm -r love-api