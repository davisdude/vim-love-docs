@echo off

REM Set the current directory to the location of this script
pushd %~dp0

REM Update the doc directory
rd /q /s ..\..\doc
mkdir ..\..\doc

REM Generate documentation
%lua% main.lua > ..\..\doc\love.txt

REM Generate helptags
%vim% -c "helptags ..\..\doc\" -c "qa!"

REM Cleanup
rd /q /s love-api

popd
