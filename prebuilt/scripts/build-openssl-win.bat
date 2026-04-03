@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Setup environment
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x86

REM Set paths
set _ROOT_DIR=C:\Users\user\Documents\GitHub\HyperXTalk\prebuilt
set _PACKAGE_DIR=%_ROOT_DIR%
set BUILDTRIPLE=x86-win32
set MODE=Release
set ARCH=x86

cd "%_ROOT_DIR%"

SET OPENSSL_VERSION=1.1.1g
SET OPENSSL_TGZ=%_ROOT_DIR%\openssl-%OPENSSL_VERSION%.tar.gz
SET OPENSSL_SRC=%_ROOT_DIR%\openssl-%OPENSSL_VERSION%-x86-win32-src
SET OPENSSL_BIN=%_ROOT_DIR%\openssl-%OPENSSL_VERSION%-x86-win32-bin

echo Checking for OpenSSL source...

if not exist "%OPENSSL_SRC%" (
    echo Unpacking OpenSSL with Cygwin...
    C:\cygwin64\bin\bash.exe -lc "cd /cygdrive/c/Users/user/Documents/GitHub/HyperXTalk/prebuilt && tar -xzf build/openssl-1.1.1g.tar.gz"
    move /Y openssl-%OPENSSL_VERSION% "%OPENSSL_SRC%"
)

cd "%OPENSSL_SRC%"

REM Configure and build OpenSSL
SET OPENSSL_CONFIG=no-hw no-rc5 no-shared VC-WIN32 --prefix=%OPENSSL_BIN%

echo Configuring OpenSSL...
perl Configure %OPENSSL_CONFIG% > openssl_build.log 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Configure failed!
    type openssl_build.log
    exit /b 1
)

echo Building OpenSSL (this may take a while)...
nmake clean > NUL 2>NUL
nmake >> openssl_build.log 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    type openssl_build.log
    exit /b 1
)

echo Creating output directories...
if not exist "%OPENSSL_BIN%\include" mkdir "%OPENSSL_BIN%\include"
if not exist "%OPENSSL_BIN%\lib" mkdir "%OPENSSL_BIN%\lib"

echo Copying files...
xcopy /E /Y /I include\openssl\* "%OPENSSL_BIN%\include\openssl\" > NUL 2>&1
copy /Y libcrypto.lib "%OPENSSL_BIN%\lib\libeay32.lib" > NUL 2>&1
copy /Y libssl.lib "%OPENSSL_BIN%\lib\ssleay32.lib" > NUL 2>&1

echo OpenSSL build complete!
echo Output: %OPENSSL_BIN%

exit /b 0