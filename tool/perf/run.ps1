# [PERF-PROBE] Runs the instrumented NOIR CHROME build with a variant
# environment, then reports CPU (core %), GPU engine %, memory and the
# in-app frame stats written by lib/perf_probe.dart.
#
#   & .\tool\perf\run.ps1 -Variant idle
#   & .\tool\perf\run.ps1 -Variant running -AutoStart
#
# -AutoStart sets NOIR_AUTOSTART=1, which makes tool/perf_main.dart tap the
# play key through the gesture pipeline: no window focus, no mouse input.
param(
  [string]$Variant = 'baseline',
  [switch]$AutoStart,
  [int]$WarmupSec = 6,
  [int]$SampleSec = 16,
  [string]$Exe = '',
  [string]$OutDir = ''
)

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $Exe) { $Exe = Join-Path $root 'build\windows\x64\runner\Release\my_timer.exe' }
if (-not $OutDir) { $OutDir = Join-Path $root 'perf' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Get-Process my_timer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

$probeFile = Join-Path $OutDir ("{0}.jsonl" -f $Variant)
if (Test-Path $probeFile) { Remove-Item $probeFile -Force }
$env:PERF_OUT = $probeFile
$env:NOIR_AUTOSTART = if ($AutoStart) { '1' } else { '0' }

$sw = [Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath $Exe -WorkingDirectory (Split-Path $Exe) -PassThru

$remaining = $WarmupSec - [int]$sw.Elapsed.TotalSeconds
if ($remaining -gt 0) { Start-Sleep -Seconds $remaining }

$proc = Get-Process -Id $p.Id
$cpu0 = $proc.CPU
$threads0 = @{}
foreach ($th in $proc.Threads) { $threads0[$th.Id] = $th.TotalProcessorTime.TotalSeconds }

$gpuSamples = @()
try {
  $gpuSamples = Get-Counter '\GPU Engine(*)\Utilization Percentage' -SampleInterval 1 -MaxSamples $SampleSec -ErrorAction Stop
} catch {
  $gpuSamples = @()
  Start-Sleep -Seconds $SampleSec
}

$proc = Get-Process -Id $p.Id
$cpu1 = $proc.CPU
$elapsed = $sw.Elapsed.TotalSeconds - $WarmupSec
$rss = [math]::Round($proc.WorkingSet64 / 1MB, 0)

$threadDeltas = @()
foreach ($th in $proc.Threads) {
  $before = if ($threads0.ContainsKey($th.Id)) { $threads0[$th.Id] } else { 0 }
  $threadDeltas += [pscustomobject]@{ Id = $th.Id; CpuS = [math]::Round($th.TotalProcessorTime.TotalSeconds - $before, 2) }
}

$gpu3d = @(); $gpuAll = @()
foreach ($set in $gpuSamples) {
  $mine = $set.CounterSamples | Where-Object { $_.InstanceName -like "*pid_$($p.Id)_*" }
  if (-not $mine) { $gpuAll += 0; $gpu3d += 0; continue }
  $gpuAll += ($mine | Measure-Object -Property CookedValue -Sum).Sum
  $gpu3d += ($mine | Where-Object { $_.InstanceName -like '*engtype_3D*' } | Measure-Object -Property CookedValue -Sum).Sum
}
Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue

$probe = @()
if (Test-Path $probeFile) {
  $probe = Get-Content $probeFile | ForEach-Object { $_ | ConvertFrom-Json }
}
$secs = @($probe | Where-Object { $_.t -eq 'sec' })
$fps = @($secs | ForEach-Object { $_.fps } | Sort-Object)
$build = @($secs | ForEach-Object { $_.build_avg_ms } | Sort-Object)
$raster = @($secs | ForEach-Object { $_.raster_avg_ms } | Sort-Object)
function Median($arr) { if (-not $arr -or $arr.Count -eq 0) { return 0 }; return $arr[[int][math]::Floor($arr.Count / 2)] }

[pscustomobject]@{
  Variant      = $Variant
  CpuPctOfCore = [math]::Round(100.0 * ($cpu1 - $cpu0) / $elapsed, 1)
  Gpu3dAvg     = [math]::Round((($gpu3d | Measure-Object -Average).Average), 1)
  FpsMedian    = (Median $fps)
  BuildAvgMs   = [math]::Round((Median $build), 2)
  RasterAvgMs  = [math]::Round((Median $raster), 2)
  RssMb        = $rss
  TopThreads   = ($threadDeltas | Sort-Object CpuS -Descending | Select-Object -First 3 | ForEach-Object { "t$($_.Id)=$($_.CpuS)s" }) -join ' '
}
