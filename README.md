# NOIR CHROME — Timer

A monochrome, liquid-chrome session timer with a 3-minute cycle tracker.
Built with Flutter; it runs in the browser **and** as a native Windows
desktop application.

## Features

- Large rolling odometer clock (05:00 default) with a liquid-mercury timeline
- 3-minute cycle counter, pulse animation and completion chime
- Presets (25 / 45 / 60 / 90 min) and a custom hours-minutes-seconds sheet
- Focus mode that hides the HUD, light/dark theme, mouse hover + press states
- Keyboard control: `Space` start/pause, `R` reset, `C` cycle, `F` focus,
  `T` custom timer, `Esc` leave focus
- The HUD scales to fit the window — no scrolling, nothing ever falls off
  screen, from the 680×620 minimum up to a full desktop
- Native Windows window: centred launch, sensible minimum size, dark title bar
  and the NOIR CHROME app icon

---

## Windows (desktop)

### Requirements

- Windows 10 or 11 (x64)
- Flutter 3.32+ (developed against 3.47)
- Visual Studio 2022/2026 with the **Desktop development with C++** workload
  and the Windows 10/11 SDK

Check the toolchain with:

```powershell
flutter doctor -v
```

### Run

```powershell
flutter pub get
flutter run -d windows
```

### Build a release

```powershell
flutter build windows --release
```

The app is produced at:

```text
build\windows\x64\runner\Release\my_timer.exe
```

Keep the whole `Release` folder together — `my_timer.exe` needs the sibling
`data\`, `flutter_windows.dll` and `audioplayers_windows_plugin.dll` files.
The folder is fully portable; copy it anywhere and run the `.exe`.

### Releases

Every merge to `main` that bumps `version:` in `pubspec.yaml` publishes a
GitHub Release (`vX.Y.Z`) with the portable folder as
`NOIR-CHROME-windows-x64-vX.Y.Z.zip` — unzip anywhere and run
`my_timer.exe`. The release notes come from the merged pull request.

CI runs only after a pull request is merged (a push to `main`); pull requests
themselves are not built. Running the *Flutter Timer CI/CD* workflow manually
with `force_release` refreshes the release for the current version.

### Package a portable zip

```powershell
pwsh -File tool/build_windows.ps1
```

This builds the release and writes `dist\NOIR-CHROME-windows-x64.zip`.

### Windows implementation notes

- The `windows/` runner is a standard Flutter target, with `cmake_minimum_required`
  raised to **3.15** because `audioplayers_windows` relies on the CMP0091 policy
  when built with Visual Studio 2022/2026.
- The title bar follows the in-app light/dark theme through the small
  `noir/window` method channel (`windows/runner/flutter_window.cpp` ↔
  `lib/window_chrome.dart`). The channel is a no-op on web and in tests.
- The window opens centred at 1200×840, shrinks to fit the desktop work area,
  and enforces a 680×620 minimum so the layout stays usable.
- Haptic feedback is mobile-only; `lib/haptics.dart` turns those calls into
  no-ops on desktop instead of raising `MissingPluginException`.
- Chimes use the bundled WAV assets through `audioplayers` and play on the
  default Windows output device.
- App icon and version metadata live in `windows/runner/resources/app_icon.ico`
  and `windows/runner/Runner.rc`.

---

## Web

```powershell
flutter run -d chrome
flutter build web
```

Every merge to `main` builds the web app and uploads it as the `web-build` workflow artifact. Nothing is hosted automatically - take the artifact from the run, or run it locally.

---

## Performance

The NOIR CHROME look is deliberately rich — film grain, chrome streaks, glass
slabs, odometer digits. Built naively it was *heavy*: on an Intel UHD / 60 Hz
machine an idle window sat at ~55 % of a core at 7 fps, and every frame
overran the 16.7 ms budget.

Three things caused it:

1. **The ambient stage repainted the whole window every vsync.** Three
   repeating `AnimationController`s drove a full-screen `CustomPaint` with ten
   large gradient rounded rects plus a radial glow: ~110–150 ms of raster per
   frame, forever, even with the timer stopped.
2. **No repaint isolation.** A 6 px blinking dot and the odometer digits lived
   in the route's own layer, so each of their frames re-rasterised every glass
   panel — including eight blurred `BoxShadow`s (~39 ms per frame while
   running).
3. **A 1 s width tween on the timeline** kept a 60 fps animation alive for the
   entire session in order to move the fill by about 1.5 px.

What changed:

- the ambient stage is **baked once into a `ui.Image`** and drawn as a single
  unfiltered quad. It drifts a few pixels at 2.5 Hz and only while a session
  runs, so a resting window renders **no frames at all**;
- the clock, cycle card, log rail, dock, preset chips and status dot each sit
  behind a `RepaintBoundary`, so a ticking counter or a breathing dot repaints
  only its own pixels;
- the mercury bar is the one element that animates continuously, so it got the
  most attention: its painter caches every gradient, the fill **glides** to its
  target instead of stepping once a second, and the sheen is driven by a plain
  timer at 12 fps with a 12 s sweep — ~6 px of travel per update instead of the
  43 px jumps a naive low frame rate produces;
- odometer rolls run for 180 ms instead of 550 ms.

### Why the bar is not 60 fps

On this class of machine every presented frame costs ~11–13 ms of raster no
matter how little moved — the window is composited on the CPU. So frame count
*is* the budget: 60 fps would eat ~70 % of a core to slide a soft highlight a
few pixels. 12 fps with a slow sweep keeps the motion below the eye's threshold
for stepping while costing ~5 %.

| | before | after |
| --- | --- | --- |
| idle CPU | ~55 % of a core | ~2 % |
| idle frames | 6.7 fps, 100 % late | 0 fps — nothing scheduled |
| running CPU | ~107 % of a core | ~30 % |
| running raster per frame | 39 ms | ~11 ms |
| running frames over 16.7 ms | 100 % | ~16 % |
| bar motion per update | — | ~6 px (was 43 px at 6 fps) |
| working set | ~1.9 GB | ~0.3 GB |

Re-measure any of this with the bundled probe:

```powershell
flutter build windows --release -t tool/perf_main.dart
powershell -File tool/perf/run.ps1 -Variant idle
powershell -File tool/perf/run.ps1 -Variant running -AutoStart
```

See [`tool/perf/README.md`](tool/perf/README.md).

---

## Tests

```powershell
flutter analyze
flutter test
```

The suite includes a guard that the idle screen holds no tickers, so the
ambient-animation regression cannot come back unnoticed.

---

## Project layout

```text
lib/
  main.dart          app shell, timer engine and NOIR CHROME UI
  noir_palette.dart  monochrome design tokens
  rolling_time.dart  odometer-style clock
  chime_player.dart  cycle / completion chimes
  haptics.dart       platform-safe haptics
  window_chrome.dart native title-bar sync (Windows)
windows/             native Windows runner
web/                 PWA shell and manifest
assets/              fonts and WAV chimes
```
