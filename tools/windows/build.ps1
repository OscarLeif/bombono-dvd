param(
    [string]$MsysRoot = 'C:\msys64',
    [int]$Jobs = 4,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SConsArgs
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$toolBin = Join-Path $MsysRoot 'ucrt64/bin'
$python = Join-Path $toolBin 'python.exe'
if (!(Test-Path $python)) {
    throw "Install the MSYS2 UCRT64 Python and SCons packages first. Missing: $python"
}

$oldPath = $env:PATH
$oldPkgPath = $env:PKG_CONFIG_PATH
Push-Location $repoRoot
try {
    $deps = Join-Path $repoRoot 'build-windows/deps'
    $env:PATH = "$deps/bin;$toolBin;$MsysRoot/usr/bin;$oldPath"
    $env:PKG_CONFIG_PATH = "$deps/lib/pkgconfig;$MsysRoot/ucrt64/lib/pkgconfig"
    & $python -m SCons '-j' $Jobs 'BUILD_DIR=build-windows/app' `
        'CFG_FILE=build-windows/config.opts' 'USE_EXT_BOOST=1' `
        "BOOST_INCLUDE=$deps/include" "BOOST_LIBPATH=$deps/lib" `
        'BUILD_QUICK=false' 'BUILD_BRIEF=true' @SConsArgs
    if ($LASTEXITCODE -ne 0) {
        throw "SCons failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
    $env:PATH = $oldPath
    $env:PKG_CONFIG_PATH = $oldPkgPath
}
