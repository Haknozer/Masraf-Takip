@echo off
echo ========================================
echo Firebase API Key Guncelleme Scripti
echo ========================================
echo.

set /p ANDROID_KEY="Yeni Android API Key'i girin: "
set /p IOS_KEY="Yeni iOS API Key'i girin: "

echo.
echo Guncelleme yapiliyor...

powershell -Command "(Get-Content .env) -replace 'FIREBASE_ANDROID_API_KEY=.*', 'FIREBASE_ANDROID_API_KEY=%ANDROID_KEY%' | Set-Content .env"
powershell -Command "(Get-Content .env) -replace 'FIREBASE_IOS_API_KEY=.*', 'FIREBASE_IOS_API_KEY=%IOS_KEY%' | Set-Content .env"

echo.
echo ========================================
echo Guncelleme tamamlandi!
echo ========================================
echo.
echo Guncellenmis .env dosyasi:
type .env
echo.
pause

