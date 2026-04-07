@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Setup environment
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x86

REM Add Cygwin to PATH
set PATH=C:\cygwin64\bin;%PATH%

REM Set paths
set _ROOT_DIR=C:\Users\user\Documents\GitHub\HyperXTalk\prebuilt
set BUILDTRIPLE=x86-win32
set MODE=Release
set ARCH=x86

cd "%_ROOT_DIR%"

SET ICU_VERSION=58.2
SET ICU_TGZ=%_ROOT_DIR%\build\icu-%ICU_VERSION%.tar.gz
SET ICU_SRC=%_ROOT_DIR%\build\icu-%ICU_VERSION%-src
SET ICU_BIN=%_ROOT_DIR%\build\icu-%ICU_VERSION%-x86-win32-bin

echo Checking for ICU source...

if not exist "%ICU_SRC%" (
    echo Unpacking ICU with Cygwin...
    C:\cygwin64\bin\bash.exe -lc "cd /cygdrive/c/Users/user/Documents/GitHub/HyperXTalk/prebuilt/build && tar -xzf icu-58.2.tar.gz"
    move /Y build\icu-%ICU_VERSION% "%ICU_SRC%"
)

if not exist "%ICU_BIN%" mkdir "%ICU_BIN%"

cd "%ICU_SRC%\source"

REM Configure ICU
echo Configuring ICU...
SET ICU_CONFIG=--prefix=/cygdrive/c/Users/user/Documents/GitHub/HyperXTalk/prebuilt/build/icu-58.2-x86-win32-bin --with-data-packaging=archive --enable-static --disable-shared --disable-samples --disable-tests --disable-extras

bash -c "CPP= CC=cl CXX=cl CFLAGS='-Zi -MT' CXXFLAGS='-Zi -MT' ./runConfigureICU Cygwin/MSVC %ICU_CONFIG%" > icu_build.log 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Configure failed!
    type icu_build.log
    exit /b 1
)

echo Building ICU (this may take a while)...
bash -c "make" >> icu_build.log 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    type icu_build.log
    exit /b 1
)

echo Installing ICU...
bash -c "make DESTDIR= install" >> icu_build.log 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Install failed!
    type icu_build.log
    exit /b 1
)

echo ICU build complete!
echo Output: %ICU_BIN%

exit /b 0