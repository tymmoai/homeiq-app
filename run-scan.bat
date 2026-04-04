@echo off
setlocal enabledelayedexpansion

REM IMPORTANT: Use SONAR_USER_HOME without spaces to avoid Windows username path issues
set "SONAR_USER_HOME=D:\sonar"

REM Set Java home
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
set "PATH=!JAVA_HOME!\bin;!PATH!"

REM Create sonar home directory if it doesn't exist
if not exist "%SONAR_USER_HOME%" mkdir "%SONAR_USER_HOME%"

REM Run sonar-scanner - reads sonar-project.properties from current directory
REM The properties file has all the correct settings for Dart/Flutter scanning
"D:\301io\homeiq-monorepo\node_modules\.bin\sonar-scanner.cmd" ^
  -D"sonar.host.url=http://localhost:9000" ^
  -D"sonar.token=sqp_cee8bc4b2640d7466124c59fdf5db3d2432dfb77"

endlocal
