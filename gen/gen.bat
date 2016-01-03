@echo off
:: Need to run as admin
cd %~dp0

rd /q /s love-api
git clone https://github.com/rm-code/love-api

"C:\Program Files\LOVE\0.10.0\love" . >out.txt

if not exist ..\syntax mkdir ..\syntax
move out.txt ..\syntax\lua.vim

rd /q /s love-api