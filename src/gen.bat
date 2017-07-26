@echo off
setlocal EnableDelayedExpansion

REM Set the current directory to the location of this script
pushd %~dp0

REM Read in env.txt
for /F "tokens=*" %%A in ('type "env.txt"') do (
	REM To execute the string, it must be set as a variable
	set "var=set %%A"
	!var!
)

REM Asisgn fallbacks in case the values are invalid
if [!love!]==[] (
	set "love=love"
)
if [!git!]==[] (
	set "git=git"
)
if [!vim!]==[] (
	set "vim=vim"
)

REM Remove the old love-api and clone in the new one
rd /q /s love-api
!git! clone https://github.com/love2d-community/love-api

REM Copy love-api to the specified directories
xcopy /e /q /y love-api syntax\love-api\
xcopy /e /q /y love-api doc\love-api\

REM Run the generation scripts
call doc\gen.bat
call syntax\gen.bat

REM Update the plugin
rd /q /s ..\plugin
xcopy /y plugin ..\plugin\

REM REmove love-api
rd /q /s love-api

popd
