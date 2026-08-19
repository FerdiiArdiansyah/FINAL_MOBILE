@echo off
echo Menyiapkan EduTech SMK...

:: Buat virtual drive tanpa spasi untuk Flutter SDK
subst X: "C:\Users\ACER ID\Downloads\flutter" 2>nul

:: Set Pub cache ke path tanpa spasi
set PUB_CACHE=C:\PubCache

:: Masuk ke folder project
cd /d "%~dp0"

echo Menjalankan aplikasi di browser...
X:\bin\flutter.bat run -d edge

pause
