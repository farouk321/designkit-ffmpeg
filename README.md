# designkit-ffmpeg

LGPL builds of FFmpeg with H.264 by openh264 (built from source), for DesignKit's MP4 export.
One FFmpeg release tag, one openh264 release, one configure line, four targets: win32-x64, linux-x64 (musl, static),
darwin-x64, darwin-arm64. Each release also carries the exact source archives and SHA256SUMS.

- Build: push a tag `ffmpeg-<ffmpeg tag>-openh264-<version>-r<n>` matching `env` in `.github/workflows/build.yml`.
- Releases are never replaced or pruned; a rebuild is a new `r<n>`.
- Archive layout: `<name>/bin/ffmpeg[.exe]` (self-contained), `<name>/LICENSES/`, `<name>/BUILDINFO.txt`.
- Licence: FFmpeg LGPL-2.1-or-later (no GPL, version3 or nonfree parts); openh264 BSD-2-Clause. Builds of openh264
  from source are not covered by Cisco's H.264 patent licence (that covers only Cisco's own binaries).
