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
grep -q '#define CONFIG_GPL 0' "$src/config.h"
grep -q '#define CONFIG_NONFREE 0' "$src/config.h"
grep -q '#define CONFIG_VERSION3 0' "$src/config.h"
grep -q '#define CONFIG_LIBOPENH264_ENCODER 1' "$src/config.h"
cd stage
if [ "$format" = zip ]; then
  zip -r -X -9 "../dist/$name.zip" "$name"
else
  tar -cJf "../dist/$name.tar.xz" "$name"
fi
ls -l ../dist
