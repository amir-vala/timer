#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Builds the NOIR CHROME Windows desktop release and packages it as a
    portable zip.

.EXAMPLE
    pwsh -File tool/build_windows.ps1
#>
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    Write-Host 'Building Windows release…'
    flutter pub get
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build failed with exit code $LASTEXITCODE"
    }

    $release = Join-Path $root 'build\windows\x64\runner\Release'
    $exe = Join-Path $release 'my_timer.exe'
    if (-not (Test-Path $exe)) {
        throw "Release executable not found: $exe"
    }

    $dist = Join-Path $root 'dist'
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    $zip = Join-Path $dist 'NOIR-CHROME-windows-x64.zip'
    if (Test-Path $zip) {
        Remove-Item $zip -Force
    }

    Compress-Archive -Path (Join-Path $release '*') -DestinationPath $zip
    $size = [math]::Round((Get-Item $zip).Length / 1MB, 1)
    Write-Host "Packaged: $zip ($size MB)"
}
finally {
    Pop-Location
}
