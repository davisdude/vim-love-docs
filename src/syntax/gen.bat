@echo off

REM Allows mkdir to create parent directories automatically
setlocal EnableExtensions

REM Set the current directory to the location of this script
pushd %~dp0

REM Copy love-api to child directories
xcopy /e /q /y love-api love-conf\love-api\
xcopy /e /q /y love-api lua\love-api\

REM Update after\syntax
rd /q /s ..\..\after\syntax
mkdir ..\..\after\syntax

REM Copy nongenerated help syntax
copy help.vim ..\..\after\syntax\.

REM Create syntax files
!lua! lua\main.lua > ..\..\after\syntax\lua.vim
!lua! love-conf\main.lua > ..\..\after\syntax\love-conf.vim

REM Cleanup
rd /q /s love-api
rd /q /s love-conf\love-api
rd /q /s lua\love-api

popd
