@echo off
title EduTech SMK - Launcher
color 1F
echo.
echo  ================================================
echo    EduTech SMK - Learning Management System
echo  ================================================
echo.

:: Buat virtual drive tanpa spasi untuk Flutter SDK
subst X: "C:\Users\ACER ID\Downloads\flutter" >nul 2>&1

:: Set Pub cache ke path tanpa spasi
set PUB_CACHE=C:\PubCache

cd /d "%~dp0"

echo  [1/2] Membangun aplikasi web...
echo        (Proses ini 1-3 menit, harap tunggu)
echo.
X:\bin\flutter.bat build web --release --no-tree-shake-icons

if errorlevel 1 (
    echo.
    echo  [ERROR] Build gagal! Periksa log di atas.
    pause
    exit /b 1
)

echo.
echo  [2/2] Menjalankan server lokal...
echo.
echo  ================================================
echo    Buka browser: http://localhost:8080
echo  ================================================
echo.
echo  Tekan Ctrl+C untuk menghentikan server.
echo.

:: Buka browser otomatis
start "" "http://localhost:8080"

npx serve build\web --listen 8080 --single

pause
