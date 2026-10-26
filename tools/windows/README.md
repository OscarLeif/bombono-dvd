# Windows build

This checkout builds a native 64-bit Windows application with MSYS2 UCRT64,
Python 3, and SCons. MSVC is not used. The Linux build has not yet been verified.

## Run the current build

Double-click `run-bombono.cmd` in the repository root. The application is
`build-windows/app/bin/bombono-dvd.exe`; keep the DLLs and `resources` folder
beside it. The launcher also adds MSYS2 tools to PATH. Set `MSYS2_ROOT` if MSYS2
is installed somewhere other than `C:\msys64`.

This is a development build for this PC, not a standalone installer. GTK's
loaders and configuration may still reference the MSYS2 installation.
Disc authoring and burning have not been validated. External DVD tools such as
dvdauthor, spumux, and cdrecord are not provided by these build scripts; startup
currently reports that cdrecord is unavailable when probing disc drives.

## Set up the toolchain

Install MSYS2, then use its **UCRT64** shell. Run `pacman -Syu` and restart the
shell if the core update requests it, then run `pacman -Syu` again.

```sh
pacman -S --needed mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-gtk2 mingw-w64-ucrt-x86_64-glibmm \
  mingw-w64-ucrt-x86_64-cairomm mingw-w64-ucrt-x86_64-pangomm \
  mingw-w64-ucrt-x86_64-atkmm mingw-w64-ucrt-x86_64-libdvdread \
  mingw-w64-ucrt-x86_64-libxml2 mingw-w64-ucrt-x86_64-pkgconf \
  mingw-w64-ucrt-x86_64-python mingw-w64-ucrt-x86_64-scons \
  mingw-w64-ucrt-x86_64-meson mingw-w64-ucrt-x86_64-ninja \
  mingw-w64-ucrt-x86_64-gettext-tools make autoconf automake libtool
```

From the repository root in that shell:

```sh
bash tools/windows/build-deps.sh gtkmm
bash tools/windows/build-deps.sh libxmlpp
bash tools/windows/build-deps.sh ffmpeg
bash tools/windows/build-deps.sh boost
```

These download upstream GTKmm 2.24.5, libxml++ 2.42.3 (the 2.6 API),
FFmpeg 3.4.13, and Boost 1.74.0. Sources and outputs stay under the ignored
`build-windows` directory. FFmpeg is pinned for this application's legacy API;
the script patches its old x86 shift constraints for modern GCC. This does not
constitute a migration to current FFmpeg.

## Build and stage

From PowerShell at the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows/build.ps1 -Jobs 6
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows/stage.ps1
```

The execution-policy setting applies only to these processes. Close Bombono
before rebuilding or staging, since Windows locks running executables and DLLs.
The SCons configuration is `build-windows/config.opts`. Remove that generated
file when changing dependency locations so library paths are recalculated.

## Runtime validation

Build `windows-smoke` by passing `-SConsArgs windows-smoke` to `build.ps1`,
then stage again. Generate a video with the built FFmpeg:

```powershell
build-windows/app/bin/ffmpeg.exe -y -f lavfi -i testsrc=size=320x240:rate=25 -t 1 -c:v mpeg2video -pix_fmt yuv420p -f mpeg build-windows/smoke.mpg
build-windows/app/bin/windows-smoke.exe build-windows/smoke.mpg
```

Run from the repository root so the test can find `resources`. It verifies GTK
initialization, CPU detection, binary serialization of 64-bit values and strings,
Windows child-process exit codes and output, and repeated video open/decode/close.
The full build and these smoke checks passed with GCC 16.2.0 and SCons 4.11.1.
The main application was also launched successfully.
