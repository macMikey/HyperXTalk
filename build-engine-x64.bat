@echo off
setlocal

cd /d "%~dp0"
set LOGFILE=%~dp0build-engine-x64.log
set VCXPROJ_ENGINE=build-win-x86_64\livecode\engine\development.vcxproj
set VCXPROJ_BROWSER=build-win-x86_64\livecode\libbrowser\libbrowser.vcxproj
set VCXPROJ_DBMYSQL=build-win-x86_64\livecode\revdb\dbmysql.vcxproj
set VCXPROJ_LCB_MODULES=build-win-x86_64\livecode\engine\engine_lcb_modules.vcxproj
set VCXPROJ_LIBFFI=build-win-x86_64\livecode\thirdparty\libffi\libffi.vcxproj
set VCXPROJ_LIBFOUNDATION=build-win-x86_64\livecode\libfoundation\libFoundation.vcxproj
set VCXPROJ_LIBSCRIPT=build-win-x86_64\livecode\libscript\libScript.vcxproj
set VCXPROJ_STANDALONE=build-win-x86_64\livecode\engine\standalone.vcxproj
set VCXPROJ_KERNEL_STANDALONE=build-win-x86_64\livecode\engine\kernel-standalone.vcxproj

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
:: PostgreSQL 18 prerequisite check
:: The engine links against libpq.lib (PostgreSQL 18).
:: Run setup-pgsql-win.bat once after: scoop install postgresql
:: ----------------------------------------------------------
set "DEBUG_PG_LIB=build-win-x86_64\livecode\Debug\lib\libpq.lib"
if not exist "%DEBUG_PG_LIB%" (
    echo.
    echo NOTE: %DEBUG_PG_LIB% not found.
    echo Running setup-pgsql-win.bat to copy PostgreSQL 18 libs from Scoop...
    echo.
    call setup-pgsql-win.bat
    if errorlevel 1 (
        echo.
        echo PostgreSQL setup failed. Install PostgreSQL via Scoop first:
        echo   scoop install postgresql
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
:: ----------------------------------------------------------
:: Build libffi (x64 must use include_win64 so FFI_DEFAULT_ABI = FFI_WIN64 = 1,
:: matching what libffi.lib expects; using include_win32 gave FFI_MS_CDECL = 5
:: which caused ffi_prep_cif to return FFI_BAD_ABI and throw "unexpected libffi failure").
:: ----------------------------------------------------------
echo Building libffi ...
echo Building libffi ... >> "%LOGFILE%"
"%MSBUILD%" %VCXPROJ_LIBFFI% /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo LIBFFI BUILD FAILED. See %LOGFILE% for details.
    exit /b 1
)
echo libffi OK.

echo.
:: /t:Rebuild is required here — MSBuild does not detect include-path changes
:: in incremental builds, so foundation-handler.obj and foundation-typeinfo.obj
:: would keep the stale FFI_DEFAULT_ABI=5 value (from include_win32) baked in.
:: Rebuild guarantees they are compiled with include_win64 → FFI_DEFAULT_ABI=1.
echo Building libFoundation (FFI closure fix: x64 now uses include_win64 headers) ...
echo Building libFoundation ... >> "%LOGFILE%"
"%MSBUILD%" %VCXPROJ_LIBFOUNDATION% /t:Rebuild /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo LIBFOUNDATION BUILD FAILED. See %LOGFILE% for details.
    exit /b 1
)
echo libFoundation OK.

echo.
echo Building libScript ...
echo Building libScript ... >> "%LOGFILE%"
"%MSBUILD%" %VCXPROJ_LIBSCRIPT% /t:Rebuild /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo LIBSCRIPT BUILD FAILED. See %LOGFILE% for details.
    exit /b 1
)
echo libScript OK.

echo.
:: ----------------------------------------------------------
:: Build LCB engine modules (compiles engine/src/browser.lcb et al.
:: via lc-compile; produces engine_lcb_modules.cpp and .lci files).
:: Must run before the engine so any .lcb changes are picked up.
:: ----------------------------------------------------------
echo Building LCB engine modules ...
echo Building LCB engine modules ... >> "%LOGFILE%"
"%MSBUILD%" %VCXPROJ_LCB_MODULES% /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo.
    echo LCB MODULES BUILD FAILED. See %LOGFILE% for details.
    exit /b 1
)
echo LCB modules OK.

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
    echo ENGINE BUILD FAILED - HyperXTalk.exe was not produced.
    exit /b 1
)

echo Engine built: %EXE%

echo.
:: ----------------------------------------------------------
:: Build kernel-standalone.lib for x64.
:: The pre-built lib shipped as x86; we must compile it for x64 so that
:: standalone-community.exe can link against it.  Only the two mode source
:: files (mode_standalone.cpp, lextable.cpp) are compiled here — the
:: winnt.h SDK conflict does NOT affect these files.
:: BuildProjectReferences=false: encode_version and perfect are already
:: present from the engine build; no need to rebuild them.
:: ----------------------------------------------------------
echo Building kernel-standalone (x64 mode library) ...
echo Building kernel-standalone ... >> "%LOGFILE%"
set "KSTD_LOG=%~dp0build-kernel-standalone.log"
"%MSBUILD%" %VCXPROJ_KERNEL_STANDALONE% /t:Rebuild /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo > "%KSTD_LOG%" 2>&1
set KSTD_ERR=%ERRORLEVEL%
type "%KSTD_LOG%"
type "%KSTD_LOG%" >> "%LOGFILE%"
if %KSTD_ERR% NEQ 0 (
    echo.
    echo KERNEL-STANDALONE BUILD FAILED. See %KSTD_LOG% for details.
    exit /b 1
)
echo kernel-standalone OK.

echo.
:: ----------------------------------------------------------
:: Build standalone-community.exe (required by the standalone builder).
:: The IDE's revSBEnginePath resolves to standalone-community.exe when
:: editionType is "community" (or falls back to it for community builds).
:: ----------------------------------------------------------
echo Building standalone-community.exe ...
echo Building standalone-community.exe ... >> "%LOGFILE%"
set "STANDALONE_LOG=%~dp0build-standalone.log"
set "STANDALONE_EXE=build-win-x86_64\livecode\Debug\standalone-community.exe"
:: BuildProjectReferences=false: kernel-standalone.lib, security-community.lib and
:: kernel.lib are already pre-built; we just link against them without rebuilding
:: (rebuilding them triggers winnt.h SDK conflicts in those older vcxprojs).
"%MSBUILD%" %VCXPROJ_STANDALONE% /p:Configuration=Debug /p:Platform=x64 /p:BuildProjectReferences=false /v:minimal /nologo > "%STANDALONE_LOG%" 2>&1
set STANDALONE_ERR=%ERRORLEVEL%
type "%STANDALONE_LOG%" >> "%LOGFILE%"
if %STANDALONE_ERR% NEQ 0 goto standalone_failed
echo standalone-community.exe OK.
goto standalone_done
:standalone_failed
echo.
:: Write filtered errors to a small file for easy inspection.
set "STANDALONE_ERRORS=%~dp0build-standalone-errors.log"
findstr /v /r "LNK4099\|LNK4075" "%STANDALONE_LOG%" > "%STANDALONE_ERRORS%"
echo STANDALONE BUILD FAILED. Filtered errors (excluding LNK4099/LNK4075 noise):
type "%STANDALONE_ERRORS%"
if not exist "%STANDALONE_EXE%" (
    echo ERROR: standalone-community.exe is missing and could not be built.
    exit /b 1
)
echo WARNING: Using existing standalone-community.exe from a previous build.
:standalone_done

echo.
:: ----------------------------------------------------------
:: Recompile browser widget (browser.lcb → module.lcm).
:: We invoke lc-compile.exe directly rather than going through
:: server-community.exe + extension-utils.livecodescript, which
:: is unreliable in a plain cmd environment.
:: Only the browser widget is compiled here — it is the only LCB
:: file changed for the navigation-event fix.
:: ----------------------------------------------------------
echo.
echo Compiling browser widget (browser.lcb) ...
echo Compiling browser widget ... >> "%LOGFILE%"
set "LC_COMPILE=build-win-x86_64\livecode\Debug\lc-compile.exe"
set "LCI_DIR=build-win-x86_64\livecode\Debug\modules\lci"
set "BROWSER_PKG=build-win-x86_64\livecode\Debug\packaged_extensions\com.livecode.widget.browser"
set "BROWSER_LCB=extensions\widgets\browser\browser.lcb"

if not exist "%LC_COMPILE%" (
    echo ERROR: lc-compile.exe not found. Build the engine first.
    exit /b 1
)

:: Delete the old module to force a clean output.
if exist "%BROWSER_PKG%\module.lcm" del /F /Q "%BROWSER_PKG%\module.lcm"

set "LCOMPILE_LOG=%~dp0build-browser-widget.log"
"%LC_COMPILE%" --modulepath "%BROWSER_PKG%" --modulepath "%LCI_DIR%" --manifest "%BROWSER_PKG%\manifest.xml" --output "%BROWSER_PKG%\module.lcm" "%BROWSER_LCB%" > "%LCOMPILE_LOG%" 2>&1
set LC_ERR=%ERRORLEVEL%
type "%LCOMPILE_LOG%"
type "%LCOMPILE_LOG%" >> "%LOGFILE%"
if %LC_ERR% NEQ 0 (
    echo.
    echo BROWSER WIDGET COMPILE FAILED. Full output above / in %LCOMPILE_LOG%
    exit /b 1
)
if not exist "%BROWSER_PKG%\module.lcm" (
    echo.
    echo BROWSER WIDGET COMPILE FAILED - module.lcm was not produced.
    exit /b 1
)
:: Sync the updated source into the packaged extension folder.
copy /Y "%BROWSER_LCB%" "%BROWSER_PKG%\browser.lcb" > nul
echo Browser widget OK.

echo.
echo Build completed: %DATE% %TIME%
echo Build completed: %DATE% %TIME% >> "%LOGFILE%"
echo Full log: %LOGFILE%