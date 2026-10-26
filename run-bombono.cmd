@echo off
setlocal
cd /d "%~dp0build-windows\app\bin"
if not defined MSYS2_ROOT set "MSYS2_ROOT=C:\msys64"
set "PATH=%~dp0build-windows\app\bin;%~dp0build-windows\deps\bin;%MSYS2_ROOT%\ucrt64\bin;%MSYS2_ROOT%\usr\bin;%PATH%"
"%~dp0build-windows\app\bin\bombono-dvd.exe" %*
