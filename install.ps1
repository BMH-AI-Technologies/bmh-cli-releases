# bmh installer for Windows (PowerShell).
#   $env:BMH_ORG="family"; irm https://raw.githubusercontent.com/BMH-AI-Technologies/bmh-cli-releases/main/install.ps1 | iex
# Downloaded by PowerShell, so the file carries no "from the internet" mark and
# SmartScreen doesn't block it.
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$ProgressPreference = "SilentlyContinue"  # the progress bar makes Invoke-WebRequest ~10x slower

$releases = if ($env:BMH_RELEASES) { $env:BMH_RELEASES } else { "https://github.com/BMH-AI-Technologies/bmh-cli-releases/releases/latest/download" }
$bmhHome = if ($env:BMH_HOME) { $env:BMH_HOME } else { Join-Path $env:USERPROFILE ".bmh" }
$binDir = Join-Path $bmhHome "bin"

if (-not [Environment]::Is64BitOperatingSystem) { Write-Host "Cần Windows 64-bit."; exit 1 }
$asset = "bmh-windows-x64.exe"  # ARM Windows runs x64 binaries through emulation

Write-Host "✦ Đang tải bmh ($asset)…"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
$tmp = Join-Path $binDir "bmh.exe.tmp"
Invoke-WebRequest -Uri "$releases/$asset" -OutFile $tmp -UseBasicParsing
$exe = Join-Path $binDir "bmh.exe"
if (Test-Path $exe) {
  # A running bmh.exe can't be overwritten, but it can be renamed.
  Remove-Item "$exe.old" -Force -ErrorAction SilentlyContinue
  Rename-Item $exe "bmh.exe.old"
}
Rename-Item $tmp "bmh.exe"

# Add to the user's PATH (no admin needed) and to this window's PATH.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not ($userPath -split ";" | Where-Object { $_ -eq $binDir })) {
  [Environment]::SetEnvironmentVariable("Path", "$binDir;$userPath", "User")
}
$env:Path = "$binDir;$env:Path"

Write-Host "✓ Đã cài bmh vào $binDir"
$setupArgs = @("setup")
if ($env:BMH_ORG) { $setupArgs += @("--org", $env:BMH_ORG) }
if ($env:BMH_INVITE) { $setupArgs += @("--invite", $env:BMH_INVITE) }  # registers the laptop with the BMH server
& $exe @setupArgs
Write-Host ""
Write-Host "Mở cửa sổ PowerShell mới (hoặc terminal trong Antigravity), vào thư mục làm việc rồi gõ: bmh"
