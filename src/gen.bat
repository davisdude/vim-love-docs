@echo off

cd %~dp0

call doc\gen.bat

cd %~dp0
call syntax\gen.bat

cd %~dp0
xcopy /y plugin ..\plugin\