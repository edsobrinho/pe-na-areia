@echo off
title Pe na Areia - Servidor Wi-Fi Mobile
cd /d "%~dp0\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar-wifi.ps1"
pause

