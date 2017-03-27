@echo off
:: Push directory, so can be run by another file
pushd %~dp0
xcopy /E /Q /Y love-api love-conf\love-api\
xcopy /E /Q /Y love-api lua\love-api\

if not exist ..\..\after\syntax mkdir ..\..\after\syntax
love lua > ..\..\after\syntax\lua.vim
love love-conf > ..\..\after\syntax\love-conf.vim

rd /q /s love-api
rd /q /s love-conf\love-api
rd /q /s lua\love-api
popd