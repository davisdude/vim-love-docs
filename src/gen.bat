@echo off

pushd %~dp0
rd /q /s love-api
git clone https://github.com/love2d-community/love-api
xcopy /E /Q /Y love-api syntax\love-api\
xcopy /E /Q /Y love-api doc\love-api\

call doc\gen.bat
call syntax\gen.bat
xcopy /y plugin ..\plugin\

rd /q /s love-api
popd