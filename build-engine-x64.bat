@echo off
setlocal

cd /d "%~dp0"
set LOGFILE=%~dp0build-engine-x64.log
set VCXPROJ_ENGINE=build-win-x86_64\livecode\engine\development.vcxproj
set VCXPROJ_BROWSER=build-win-x86_64\livecode\libbrowser\libbrowser.vcxproj
set VCXPROJ_DBMYSQL=build-win-x86_64\livecode\revdb\dbmysql.vcxproj

:: ----------------------------------------------------------
:: MySQL 9.6.0 prerequisite check
:: The engine links against libmysql.lib (MySQL 9.6.0).
:: Run setup-mysql-win.bat once after: scoop install mysql
:: ----------------------------------------------------------
set "DEBUG_MYSQL_LIB=build-win-x86_64\livecode\Debug\lib\libmysql.lib"
if not exist "%DEBUG_MYSQL_LIB%" (
    echo.
    echo NOTE: %DEBUG_MYSQL_LIB% not found.
    echo Running setup-mysql-win.bat to copy MySQL 9.6.0 libs from Scoop...
    echo.
    call setup-mysql-win.bat
    if errorlevel 1 (
        echo.
        echo MySQL setup failed. Install MySQL via Scoop first:
        echo   scoop install mysql
        echo Then re-run this script.
        exit /b 1
    )
    echo.
)

:: ----------------------------------------------------------
:: Locate MSBuild via a temp PS1 file (avoids cmd mishandling of
:: parentheses inside %ProgramFiles(x86)% in inline commands)
:: ----------------------------------------------------------
set "FIND_PS1=%TEMP%\hxt_find_msbuild.ps1"
echo $pf = [System.Environment]::GetEnvironmentVariable('ProgramFiles(x86)')> "%FIND_PS1%"
echo $vs = "$pf\Microsoft Visual Studio\Installer\vswhere.exe">> "%FIND_PS1%"
echo if (Test-Path $vs) { ^& $vs -latest -products * -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' ^| Select-Object -First 1 }>> "%FIND_PS1%"
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%FIND_PS1%"') do set "MSBUILD=%%i"
del "%FIND_PS1%" 2>nul
if not defined MSBUILD (
    echo ERROR: MSBuild.exe not found. Install Visual Studio 2019 Build Tools with C++ workload.
    exit /b 1
)
echo Using MSBuild: %MSBUILD%

echo Build started: %DATE% %TIME%
echo Build started: %DATE% %TIME% > "%LOGFILE%"
echo. >> "%LOGFILE%"

echo Building libbrowser (WebView2 fix) ...
echo Building libbrowser (WebView2 fix) ... >> "%LOGFILE%"
"%MSBUILD%" %VCXPROJ_BROWSER% /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo LIBBROWSER BUILD FAILED. Errors:
    findstr /i " error " "%LOGFILE%"
    echo Full log: %LOGFILE%
    exit /b 1
)
echo libbrowser OK.

echo.
echo Building dbmysql (MySQL 9.6.0 database driver) ...
echo Building dbmysql ... >> "%LOGFILE%"
"%MSBUILD%" %VCXPROJ_DBMYSQL% /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo DBMYSQL BUILD FAILED. Errors:
    findstr /i " error " "%LOGFILE%"
    echo Full log: %LOGFILE%
    exit /b 1
)
echo dbmysql OK.

echo.
echo Building engine ...

set "EXE=build-win-x86_64\livecode\Debug\HyperXTalk.exe"
set "ENGINE_LOG=%~dp0build-engine-step.log"
set "LINK_TLOG=build-win-x86_64\livecode\engine\Debug\x64\obj\development\development.tlog\link.write.1.tlog"

:: If the exe is missing, delete the linker tlog so MSBuild is forced
:: to rerun the link step even when no source files changed.
if not exist "%EXE%" (
    if exist "%LINK_TLOG%" (
        del /F /Q "%LINK_TLOG%"
        echo Cleared linker tlog to force relink.
    )
)

"%MSBUILD%" %VCXPROJ_ENGINE% /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo > "%ENGINE_LOG%" 2>&1
set BUILD_ERR=%ERRORLEVEL%

:: Show the engine build output (errors and warnings) on the console.
type "%ENGINE_LOG%"
type "%ENGINE_LOG%" >> "%LOGFILE%"

if %BUILD_ERR% NEQ 0 (
    echo.
    echo ENGINE BUILD FAILED.
    exit /b 1
)

if not exist "%EXE%" (
    echo.
    echo ENGINE BUILD FAILED - Hyper