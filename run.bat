@echo off
title Citrix Workspace All-In-One Setup
color 0b
echo =================================================================
echo       CITRIX WORKSPACE ALL-IN-ONE SETUP (MEGAFON VDI)
echo =================================================================
echo.
:: 1. Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Запрос прав Администратора...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Скачивание сценария на диск через curl (без Invoke-Expression / IEX)
echo Загрузка сценария настройки...
curl.exe -s -k -L -o "%TEMP%\citrix_install.ps1" "https://raw.githubusercontent.com/Maximka-L/citrix-vdi/main/install.ps1"

:: 3. Снятие метки зоны интернета (Mark of the Web)
powershell.exe -NoProfile -Command "Unblock-File -Path '%TEMP%\citrix_install.ps1' -ErrorAction SilentlyContinue"

:: 4. Запуск скрипта напрямую из файла
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\citrix_install.ps1"
