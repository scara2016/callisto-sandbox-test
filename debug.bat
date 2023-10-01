@echo off
odin build . -debug -out:"./out/callisto-sandbox.exe" -o:"none" && ^
remedybg -g -q "./out/callisto-sandbox.exe"
