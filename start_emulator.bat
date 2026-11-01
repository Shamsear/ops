@echo off
title Android Emulator - timemaps_app
echo Starting Android Emulator (Medium_Phone_2)...
start "" "C:\Users\shams\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_2

echo Waiting for emulator to connect...
"C:\Users\shams\AppData\Local\Android\Sdk\platform-tools\adb.exe" wait-for-device

echo Waiting for device boot to complete...
:wait_boot
for /f %%i in ('"C:\Users\shams\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell getprop sys.boot_completed 2^>nul') do set BOOT=%%i
if not "%BOOT%"=="1" (
    timeout /t 2 /nobreak >nul
    goto wait_boot
)

echo Setting up port forwarding for API...
"C:\Users\shams\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:5000 tcp:5000

echo Installing timemaps_app...
"C:\Users\shams\AppData\Local\Android\Sdk\platform-tools\adb.exe" install -r "C:\ops\timemaps_app\build\app\outputs\flutter-apk\app-debug.apk"

echo Launching timemaps_app...
"C:\Users\shams\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell am start -n io.flutter.examples.hello_world/io.flutter.embedding.android.FlutterActivity

echo Done! The app is now running on your emulator.
