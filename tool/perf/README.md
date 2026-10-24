# Performance probe

A small harness for measuring what the NOIR CHROME UI actually costs on this
machine. It builds the **real app** (`lib/main.dart`) behind an instrumented
entrypoint that logs frame statistics to JSON, then samples the OS for CPU,
GPU and memory while the app runs.

It exists because this cost is invisible in the source — every widget looked
deliberate, and the bill was 40 ms per frame on a blinking 6 px dot.

## What it measures

`lib/perf_probe.dart` registers a persistent frame callback (frames per second)
and a timings callback (build and raster milliseconds per frame), then appends a
JSON line per second to `$env:PERF_OUT`.

`run.ps1` launches the app, optionally presses Play, samples the process with
`Get-Process` and the `\GPU Engine(*)\Utilization Percentage` counter, and
prints medians:

| column | meaning |
| --- | --- |
| `CpuPctOfCore` | one core = 100 %. A desktop timer should idle near 0. |
| `Gpu3dAvg` | average 3D engine utilisation for the app's PID |
| `FpsMedian` | frames delivered per second |
| `BuildAvgMs` | UI thread (layout/paint recording) |
| `RasterAvgMs` | raster thread — this is where a heavy scene shows up |
| `RssMb` | working set; a raster thread that cannot keep up queues frames and balloons this |

## Usage

```powershell
flutter build windows --release -t tool/perf_main.dart

powershell -File tool/perf/run.ps1 -Variant idle
powershell -File tool/perf/run.ps1 -Variant running -AutoStart
```

`-AutoStart` sets `NOIR_AUTOSTART=1`, which makes `tool/perf_main.dart` tap the
play key through Flutter's gesture pipeline — no window focus, no mouse input,
so measuring never disturbs whatever else is on screen. `-SampleSec`,
`-WarmupSec`, `-Exe` and `-OutDir` are also available. Raw samples land in
`perf/`, which is throwaway output.

Notes:

- Run the `-t tool/perf_main.dart` build, not the shipping one — the shipping
  build has no probe.
- Compare like with like: same window size, same warm-up, a machine that is not
  busy. Absolute numbers are specific to this GPU; the *ratios* between variants
  are what matter.
- The probe adds no animation; it only observes. Its own cost is a few
  microseconds per frame.

## Reading the result

The signature of the original bug was `RasterAvgMs ≈ 110–150` with
`FpsMedian ≈ 7` and `RssMb` climbing toward 2 GB: the raster thread was ~7× over
its 16.7 ms budget, so frames queued and each retained surface grew the working
set. A healthy idle app reports `FpsMedian = 0` — no frame is requested at all.
