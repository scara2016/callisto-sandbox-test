@echo off
if not exist "./out/" mkdir "./out"
odin build . -debug -out:"./out/callisto-sandbox.exe" -o:"none" && ^
.\out\callisto-sandbox.exe
