@echo off

pushd %~dp0
if not exist ..\..\doc mkdir ..\..\doc
love . > ..\..\doc\love.txt
vim -c "helptags ..\..\doc\" -c "qa!"

rd /q /s love-api
popd