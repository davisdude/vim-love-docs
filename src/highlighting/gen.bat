@echo off
:: Need to run as admin
cd %~dp0

rd /q /s love-api
git clone https://github.com/love2d-community/love-api

love . >out.txt

if not exist ..\..\after\syntax mkdir ..\..\after\syntax
move out.txt ..\..\after\syntax\lua.vim

rd /q /s love-api
