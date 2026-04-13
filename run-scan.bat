@echo off
setlocal enabledelayedexpansion

REM IMPORTANT: Use SONAR_USER_HOME without spaces to avoid Windows username path issues
set "SONAR_USER_HOME=D:\sonar"

REM Set Java home
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
set "PATH=!JAVA_HOME!\bin;!PATH!"

REM Create sonar home directory if it doesn't exist
if not exist "%SONAR_USER_HOME%" mkdir "%SONAR_USER_HOME%"

REM Load token from .env.sonar if SONAR_TOKEN is not already set
if not defined SONAR_TOKEN (
  if exist "%~dp0.env.sonar" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%~dp0.env.sonar") do (
      if /i "%%A"=="SONAR_TOKEN" set "SONAR_TOKEN=%%B"
    )
  )
)

if not defined SONAR_TOKEN (
  echo ERROR: SONAR_TOKEN is not set.
  echo   Set it via environment variable, or create packages\app\.env.sonar with:
  echo   SONAR_TOKEN=your_token_here
  exit /b 1
)

REM Run sonar-scanner - reads sonar-project.properties from current directory
"D:\301io\homeiq-monorepo\node_modules\.bin\sonar-scanner.cmd" ^
  -D"sonar.host.url=http://localhost:9000" ^
  -D"sonar.token=!SONAR_TOKEN!"

endlocal
