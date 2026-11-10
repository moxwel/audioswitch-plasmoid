#!/bin/sh
# Install, upgrade or remove the Audio Switch widget, then reload plasmashell. Installing runs build.sh first
# and installs the .plasmoid file it writes to build/.
#
# Usage:
#   ./install.sh          install the widget, or upgrade it if it is already installed
#   ./install.sh remove   uninstall the widget
#
# Needs kpackagetool6, zip and msgfmt from gettext.

set -e
cd "$(dirname "$0")"

log() {
    echo "[install] $*"
}

fail() {
    echo "[install] ERROR: $*" >&2
    exit 1
}

ACTION=${1:-install}
case "$ACTION" in
    install|remove) ;;
    *) fail "unknown action '$ACTION', usage: $0 [install|remove]" ;;
esac

log "Action: $ACTION"
command -v kpackagetool6 >/dev/null 2>&1 || fail "'kpackagetool6' not found, needed to manage Plasma widgets"

log "Reading metadata.json..."
PLUGIN_ID=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)
[ -n "$PLUGIN_ID" ] || fail "no \"Id\" found in metadata.json"
log "  id: $PLUGIN_ID"
PACKAGE="build/audioswitch.plasmoid"

if [ "$ACTION" = remove ]; then
    log "Removing $PLUGIN_ID..."
    kpackagetool6 -t Plasma/Applet --remove "$PLUGIN_ID"
    log "  removed $PLUGIN_ID"
else
    log "Building the widget first..."
    ./build.sh
    [ -f "$PACKAGE" ] || fail "package $PACKAGE not found, the build did not produce it"
    log "Installing $PLUGIN_ID from $PACKAGE..."
    log "  trying to upgrade an existing install"
    if kpackagetool6 -t Plasma/Applet --upgrade "$PACKAGE" >/dev/null 2>&1; then
        log "  upgraded $PLUGIN_ID"
    else
        log "  not installed yet, installing"
        kpackagetool6 -t Plasma/Applet --install "$PACKAGE"
        log "  installed $PLUGIN_ID"
    fi
fi

log "Reloading plasmashell..."
systemctl --user restart plasma-plasmashell.service
log "  plasmashell restarted"

log "Done."
echo ""
