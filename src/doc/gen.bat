@echo off

pushd %~dp0

rd /q /s love-api
git clone https://github.com/love2d-community/love-api

if not exist ..\..\doc mkdir ..\..\doc
love . > ..\..\doc\love.txt
vim -c "helptags ..\..\doc\" -c "qa!"

rd /q /s love-api

popd