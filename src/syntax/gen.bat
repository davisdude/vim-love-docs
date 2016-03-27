@echo off
:: Need to run as admin
cd %~dp0

rd /q /s love-api
git clone https://github.com/love2d-community/love-api

if not exist ..\..\after\syntax mkdir ..\..\after\syntax
love lua > ..\..\after\syntax\lua.vim
love love-conf > ..\..\after\syntax\love-conf.vim

rd /q /s love-api