@echo off

pushd %~dp0
call doc\gen.bat
call syntax\gen.bat
xcopy /y plugin ..\plugin\
popd