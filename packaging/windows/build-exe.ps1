[CmdletBinding()]
param(
  [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$versionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*([^+\s]+)\+([0-9]+)' | Select-Object -First 1
if (-not $versionLine) { throw 'Could not read the version from pubspec.yaml.' }
$version = "$($versionLine.Matches[0].Groups[1].Value)-$($versionLine.Matches[0].Groups[2].Value)"
$bundleDir = Join-Path $projectRoot 'build/windows/x64/runner/Release'
$executable = Join-Path $bundleDir 'bangla_keyboard.exe'
$distDir = Join-Path $projectRoot 'dist'

Push-Location $projectRoot
try {
  flutter build windows --release
} finally {
  Pop-Location
}

if (-not (Test-Path $executable)) {
  throw "Flutter did not produce the expected executable: $executable"
}

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
if ($SkipInstaller) {
  $archive = Join-Path $distDir "BanglaKeyboard-$version-windows-x64.zip"
  if (Test-Path $archive) { Remove-Item $archive }
  Compress-Archive -Path (Join-Path $bundleDir '*') -DestinationPath $archive
  Write-Host "Created portable bundle: $archive"
  exit 0
}

$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if (-not $iscc) {
  throw 'Inno Setup 6 is required to create the installer. Install it, add ISCC.exe to PATH, or use -SkipInstaller for a portable ZIP.'
}

& $iscc.Source "/DMyAppVersion=$version" (Join-Path $PSScriptRoot 'installer.iss')
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE." }
