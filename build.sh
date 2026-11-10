#!/bin/sh
# Package the Audio Switch widget, with its compiled translations, as a .plasmoid file ready to share or
# upload to the KDE Store. The package is assembled in build/audioswitch/ first, so the compiled translations
# stay out of the source tree. install.sh installs the .plasmoid file.
#
# Usage:
#   ./build.sh   write build/audioswitch/ and build/audioswitch.plasmoid
#
# Needs zip, and msgfmt from gettext.

set -e
cd "$(dirname "$0")"

log() {
    echo "[build] $*"
}

fail() {
    echo "[build] ERROR: $*" >&2
    exit 1
}

# Stops the build unless a tool is installed. Takes the tool name and what the build needs it for.
require_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "'$1' not found, needed to $2"
    log "  found $1: $(command -v "$1")"
}

log "Checking tools..."
require_tool zip "pack the .plasmoid file"
require_tool msgfmt "compile the translations (package gettext)"

log "Reading metadata.json..."
PLUGIN_ID=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)
[ -n "$PLUGIN_ID" ] || fail "no \"Id\" found in metadata.json"
log "  id: $PLUGIN_ID"
PACKAGE_DIR="build/audioswitch"
OUTPUT="build/audioswitch.plasmoid"

log "Building $PLUGIN_ID..."
log "  cleaning $PACKAGE_DIR and $OUTPUT"
rm -rf "$PACKAGE_DIR" "$OUTPUT"
mkdir -p "$PACKAGE_DIR"

log "  copying metadata.json, contents/ and LICENSE to $PACKAGE_DIR"
cp -r metadata.json contents LICENSE "$PACKAGE_DIR/"

log "  compiling translations"
translate/compile.sh "$PACKAGE_DIR"

log "  packing $OUTPUT"
(cd "$PACKAGE_DIR" && zip -qr ../audioswitch.plasmoid metadata.json contents LICENSE)
log "  packed $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"

log "Output: $OUTPUT"
log "Done."
