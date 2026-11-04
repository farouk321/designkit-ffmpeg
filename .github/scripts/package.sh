# Packs one built ffmpeg into dist/<name>.<zip|tar.xz>, the archive holding <name>/bin/ffmpeg[.exe] (the folder
# DesignKit extracts), <name>/LICENSES/ and <name>/BUILDINFO.txt.
# Usage: package.sh <platform> <built executable> <zip|tar.xz>
set -eu
platform="$1"
exe="$2"
format="$3"
name="ffmpeg-$FFMPEG_TAG-lgpl-openh264-$OPENH264_VERSION-$platform"
src="ffmpeg-$FFMPEG_TAG"
rm -rf "stage" "dist"
mkdir -p "stage/$name/bin" "stage/$name/LICENSES" dist
cp "$exe" "stage/$name/bin/"
cp "$src/COPYING.LGPLv2.1" "stage/$name/LICENSES/ffmpeg-COPYING.LGPLv2.1"
cp "$src/LICENSE.md" "stage/$name/LICENSES/ffmpeg-LICENSE.md"
cp "openh264-$OPENH264_VERSION/LICENSE" "stage/$name/LICENSES/openh264-LICENSE"
{
  echo "$name"
  echo "platform: $platform"
  echo "licence: LGPL-2.1-or-later (FFmpeg, no GPL / version3 / nonfree parts) + BSD-2-Clause (openh264, built from source)"
  echo "built by: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID ($GITHUB_REF_NAME, $GITHUB_SHA)"
  cat SOURCES.txt
  echo "sources: ffmpeg-$FFMPEG_TAG-source.tar.xz, openh264-$OPENH264_VERSION-source.tar.xz (same release)"
  printf 'configuration: '
  grep '#define FFMPEG_CONFIGURATION' "$src/config.h" | sed 's/^#define FFMPEG_CONFIGURATION //'
  grep '#define CONFIG_GPL ' "$src/config.h"
  grep '#define CONFIG_NONFREE ' "$src/config.h"
} > "stage/$name/BUILDINFO.txt"
cat "stage/$name/BUILDINFO.txt"
for want in 'CONFIG_GPL 0' 'CONFIG_NONFREE 0' 'CONFIG_VERSION3 0' 'CONFIG_LIBOPENH264_ENCODER 1'; do
  # component switches live in config_components.h (FFmpeg >= 6), the licence switches in config.h
  cat "$src/config.h" "$src/config_components.h" | grep -q "#define $want\$" || { echo "config lacks: $want"; exit 1; }
done
cd stage
if [ "$format" = zip ]; then
  zip -r -X -9 "../dist/$name.zip" "$name"
else
  tar -cJf "../dist/$name.tar.xz" "$name"
fi
ls -l ../dist
