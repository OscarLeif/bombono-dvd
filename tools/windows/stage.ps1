param([string]$MsysRoot = 'C:\msys64')
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$bin = Join-Path $repoRoot 'build-windows/app/bin'
$deps = Join-Path $repoRoot 'build-windows/deps/bin'
$toolBin = Join-Path $MsysRoot 'ucrt64/bin'
$objdump = Join-Path $toolBin 'objdump.exe'
if (!(Test-Path "$bin/bombono-dvd.exe")) { throw 'Build Bombono first.' }

# Copy the actual import closure, avoiding unrelated DLLs from MSYS2.
$queue = New-Object 'System.Collections.Generic.Queue[string]'
$seen = @{}
foreach ($name in @('bombono-dvd.exe', 'mviewer.exe', 'windows-smoke.exe')) {
    if (Test-Path "$bin/$name") { $queue.Enqueue("$bin/$name") }
}
foreach ($name in @('ffmpeg.exe', 'ffprobe.exe')) {
    Copy-Item -LiteralPath "$deps/$name" -Destination $bin -Force
    $queue.Enqueue("$bin/$name")
}
while ($queue.Count) {
    $file = $queue.Dequeue()
    foreach ($line in (& $objdump -p $file)) {
        if ($line -notmatch 'DLL Name:\s+(\S+)') { continue }
        $name = $Matches[1]
        if ($seen.ContainsKey($name)) { continue }
        $seen[$name] = $true
        $source = @("$deps/$name", "$toolBin/$name") |
            Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($source) {
            Copy-Item -LiteralPath $source -Destination $bin -Force
            $queue.Enqueue("$bin/$name")
        }
        elseif ($name -notlike 'api-ms-*' -and !(Test-Path "$env:WINDIR/System32/$name")) {
            throw "Unresolved DLL: $name (needed by $file)"
        }
    }
}
New-Item -ItemType Directory -Force "$bin/resources" | Out-Null
Copy-Item "$repoRoot/resources/*" "$bin/resources" -Recurse -Force
# Git checkouts without symlink support contain a link's text instead of Python.
Copy-Item "$repoRoot/tools/scripts/SConsTwin.py" "$bin/resources/scons_authoring/SConsTwin.py" -Force
Write-Output "Ready: $bin/bombono-dvd.exe"
