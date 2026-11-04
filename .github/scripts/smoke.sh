# Smoke test of one packaged ffmpeg on its own OS: extracts only <name>/bin as DesignKit does, checks it is
# self-contained and LGPL, then encodes the same raw RGBA frames twice with DesignKit's fixed MP4 arguments
# (packages/cli/src/commands/mp4.ts mp4Args) and requires byte-identical output with no encoder version string.
# Usage: smoke.sh <platform>
set -eu
platform="$1"
name="ffmpeg-$FFMPEG_TAG-lgpl-openh264-$OPENH264_VERSION-$platform"
mkdir -p x
case "$platform" in
  win32-*)
    /c/Windows/System32/tar.exe -xf "dist/$name.zip" -C x "$name/bin"
    exe="x/$name/bin/ffmpeg.exe" ;;
  *)
    tar -xf "dist/$name.tar.xz" -C x "$name/bin"
    exe="x/$name/bin/ffmpeg" ;;
esac
ls -l "x/$name/bin"
[ "$(ls "x/$name/bin" | wc -l)" -eq 1 ] || { echo "bin holds more than the executable"; exit 1; }
case "$platform" in
  linux-*)
    if ldd "$exe" 2>&1 | grep -q '=>'; then ldd "$exe"; echo "not static"; exit 1; fi ;;
  darwin-*)
    otool -L "$exe"
    if otool -L "$exe" | tail -n +2 | grep -v -E '^\s+(/usr/lib/|/System/Library/)'; then echo "links a non-system library"; exit 1; fi ;;
  win32-*)
    ldd "$exe"
    if ldd "$exe" | grep -v -i -E '/c/windows/|ntdll|kernel|KERNELBASE|apphelp'; then echo "links a non-system DLL"; exit 1; fi ;;
esac
"$exe" -hide_banner -version | tee version.txt
if grep -q -E -- '--enable-(gpl|nonfree|version3)' version.txt; then echo "not an LGPL build"; exit 1; fi
grep -q -- '--enable-libopenh264' version.txt
"$exe" -hide_banner -encoders | grep -q libopenh264
"$exe" -hide_banner -nostdin -loglevel error -y -f lavfi -i testsrc2=size=63x64:rate=12:duration=1 -pix_fmt rgba -f rawvideo frames.rgba
for run in a b; do
  "$exe" -hide_banner -nostdin -loglevel error -y \
    -threads 1 -filter_threads 1 -filter_complex_threads 1 \
    -f rawvideo -pix_fmt rgba -s 63x64 -framerate 12 -i - \
    -vf 'pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0:0xFFFFFF,format=yuv420p' -sws_flags bitexact+accurate_rnd+full_chroma_int \
    -c:v libopenh264 -threads 1 -rc_mode quality -b:v 4M -allow_skip_frames 0 -g 12 \
    -fflags +bitexact -flags:v +bitexact -map_metadata -1 -map_chapters -1 -metadata creation_time= \
    -movflags +faststart -f mp4 "$run.mp4" < frames.rgba
done
cmp a.mp4 b.mp4
if grep -a -q -E 'Lavf[0-9]|Lavc[0-9]' a.mp4; then echo "an encoder version string is in the MP4"; exit 1; fi
"$exe" -hide_banner -loglevel error -i a.mp4 -f null - 2>&1 | tee decode.txt
ls -l a.mp4
echo "smoke ok: $platform"
