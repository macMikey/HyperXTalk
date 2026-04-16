#Requires -Version 5.1
<#
.SYNOPSIS
    Downloads and builds OpenSSL 3 static libraries for Windows x64 (VS2019 / v142).

.DESCRIPTION
    Clones openssl-3.x from GitHub, builds Debug and Release static libs with
    Visual Studio 2019 (VC-WIN64A / no-shared), and places the headers and libs
    under:
        <repo>\prebuilt\unpacked\openssl3\x86_64-win32-v142_static_Debug\
        <repo>\prebuilt\unpacked\openssl3\x86_64-win32-v142_static_Release\

    Prerequisites (must be on PATH before running this script):
        - Visual Studio 2019 Build Tools (or full IDE) with C++ workload
        - Perl  - Strawberry Perl recommended: https://strawberryperl.com/
        - NASM  - https://www.nasm.us/  (add install dir to PATH)
        - Git   - https://git-scm.com/

.PARAMETER OpenSSLTag
    Git tag to check out.  Defaults to "openssl-3.6.1".

.PARAMETER SkipIfExists
    Skip the build if output libs are already present.

.EXAMPLE
    # Open a plain PowerShell window (NOT a VS Developer Prompt) and run:
    cd C:\Users\user\Documents\GitHub\HyperXTalk\build-win-x86_64
    .\setup-openssl3.ps1
#>
param(
    [string]$OpenSSLTag   = "openssl-3.6.1",
    [switch]$SkipIfExists
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir          # HyperXTalk\
$PrebuiltBase = Join-Path $RepoRoot "prebuilt\unpacked\openssl3"
$SrcDir       = Join-Path $ScriptDir "openssl3-src"

$DebugOut   = Join-Path $PrebuiltBase "x86_64-win32-v142_static_Debug"
$ReleaseOut = Join-Path $PrebuiltBase "x86_64-win32-v142_static_Release"

# ---------------------------------------------------------------------------
# Quick exit if already built
# ---------------------------------------------------------------------------
if ($SkipIfExists) {
    $DbgLib = Join-Path $DebugOut "lib\libcrypto.lib"
    $RelLib = Join-Path $ReleaseOut "lib\libcrypto.lib"
    if ((Test-Path $DbgLib) -and (Test-Path $RelLib)) {
        Write-Host "[setup-openssl3] Output libs already present - skipping build." -ForegroundColor Cyan
        exit 0
    }
}

# ---------------------------------------------------------------------------
# Helper: locate VS2019 vcvarsall.bat
# ---------------------------------------------------------------------------
function Find-VcVarsAll {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) {
        throw "vswhere.exe not found. Please install Visual Studio 2019 Build Tools."
    }
    $vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
                         -property installationPath 2>$null | Select-Object -First 1
    if (-not $vsPath) {
        throw "No Visual Studio installation with C++ tools found by vswhere."
    }
    $vcvars = Join-Path $vsPath "VC\Auxiliary\Build\vcvarsall.bat"
    if (-not (Test-Path $vcvars)) {
        throw "vcvarsall.bat not found at: $vcvars"
    }
    return $vcvars
}

# ---------------------------------------------------------------------------
# Helper: check required tools
# ---------------------------------------------------------------------------
function Assert-Tool([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool '$Name' not found on PATH.`n" +
              "Perl : https://strawberryperl.com/`n" +
              "NASM : https://www.nasm.us/`n" +
              "Git  : https://git-scm.com/"
    }
}

Assert-Tool "perl"
Assert-Tool "nasm"
Assert-Tool "git"

$vcvars = Find-VcVarsAll
Write-Host "[setup-openssl3] Using vcvarsall: $vcvars" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Clone / update source
# ---------------------------------------------------------------------------
if (-not (Test-Path $SrcDir)) {
    Write-Host "[setup-openssl3] Cloning OpenSSL $OpenSSLTag ..." -ForegroundColor Cyan
    git clone --depth 1 --branch $OpenSSLTag https://github.com/openssl/openssl.git $SrcDir
} else {
    # Source exists - check whether it's already at the requested tag.
    $currentTag = & git -C $SrcDir describe --tags --exact-match HEAD 2>$null
    if ($currentTag -eq $OpenSSLTag) {
        Write-Host "[setup-openssl3] Source already at $OpenSSLTag - skipping fetch." -ForegroundColor Cyan
    } else {
        Write-Host "[setup-openssl3] Source is at '$currentTag', switching to $OpenSSLTag ..." -ForegroundColor Cyan
        & git -C $SrcDir fetch --depth 1 origin "refs/tags/${OpenSSLTag}:refs/tags/${OpenSSLTag}"
        & git -C $SrcDir checkout $OpenSSLTag
        & git -C $SrcDir clean -fdx
    }
}

# ---------------------------------------------------------------------------
# Build function
# ---------------------------------------------------------------------------
function Build-OpenSSL([string]$Config, [string]$OutDir) {
    Write-Host ""
    Write-Host "=== Building OpenSSL $Config ===" -ForegroundColor Yellow

    $buildDir = Join-Path $SrcDir "build-$Config"
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    New-Item -ItemType Directory -Path $buildDir | Out-Null

    # Extra Configure flags for Debug vs Release
    $extraFlags = if ($Config -eq "Debug") { "--debug" } else { "" }

    # We run everything inside a single cmd session so VS env vars persist
    $cmds = @(
        "call `"$vcvars`" x64",
        "cd /d `"$buildDir`"",
        "perl `"$SrcDir\Configure`" VC-WIN64A no-shared no-tests --prefix=`"$OutDir`" --openssldir=`"$OutDir\ssl`" $extraFlags",
        "if errorlevel 1 exit /b 1",
        "nmake",
        "if errorlevel 1 exit /b 1",
        "nmake install_sw",
        "if errorlevel 1 exit /b 1"
    )

    $script = $cmds -join "`r`n"
    $tmpBat = Join-Path $env:TEMP "build_openssl_$Config.bat"
    [System.IO.File]::WriteAllText($tmpBat, "@echo off`r`n" + $script)

    Write-Host "[setup-openssl3] Running build (this takes ~5-10 minutes) ..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tmpBat`"" `
                          -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        throw "OpenSSL $Config build failed with exit code $($proc.ExitCode)"
    }

    Write-Host "[setup-openssl3] $Config build complete. Libs at: $OutDir\lib\" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Build Debug and Release
# ---------------------------------------------------------------------------
Build-OpenSSL "Debug"   $DebugOut
Build-OpenSSL "Release" $ReleaseOut

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "OpenSSL 3 setup complete!" -ForegroundColor Green
Write-Host "  Headers : $DebugOut\include\openssl\"
Write-Host "  Debug   : $DebugOut\lib\libcrypto.lib + libssl.lib"
Write-Host "  Release : $ReleaseOut\lib\libcrypto.lib + libssl.lib"
Write-Host ""
Write-Host "You can now run the normal MSBuild:"
Write-Host "  msbuild engine\development.vcxproj /nologo /m /p:Configuration=Debug /p:Platform=x64"
