@echo off

cd %~dp0

rd /q /s love-api
git clone https://github.com/love2d-community/love-api
git ls-remote --tags https://github.com/love2d-community/love-api>tags.txt


love . >out.txt
