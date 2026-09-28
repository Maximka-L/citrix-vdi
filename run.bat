@echo off
title Citrix Workspace All-In-One Setup
color 0b
echo =================================================================
echo       CITRIX WORKSPACE ALL-IN-ONE SETUP (MEGAFON VDI)
echo =================================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Maximka-L/citrix-vdi/main/install.ps1 | iex"
