# Audio Switch Plasmoid

A KDE Plasma 6 panel widget that switches and rotates the default audio output device, inspired by [SoundSwitch](https://github.com/belphemur/soundswitch).

It uses `org.kde.plasma.private.volume`, the same QML module Plasma's own volume widget uses, so no third-party program is needed and it stays in sync with System Settings.

> This is a learning project to help me learn more about KDE Plasma development, so I welcome any feedback or suggestions.

## Usage

The icon follows the current output device and the tooltip names it. Each device gets the icon the system reports for it (speaker, headset...), or headphones when it reports none.

| Action | What it does |
|---|---|
| Left click | Opens the menu with the outputs by default. Configurable |
| Middle click | Switches to the next output by default. Configurable |
| Mouse wheel | Switches to the next or previous output |
| Right click | Lists all outputs in context menu |
| Keyboard shortcut | Switches to the next output. Set it in the widget's settings > *Keyboard Shortcuts* |

## Settings

Two tabs in the widget's settings.

- **General:** what the left and the middle click do, each one either *Switch output* or *Menu*. They can be the same.
- **Output devices:** drag the devices to set the rotation order, untick the ones to skip, and pick a custom icon for any of them. Devices not in the list yet go last.

## Install

### GitHub Releases

Download the [latest release](https://github.com/moxwel/audioswitch-plasmoid/releases/latest/download/audioswitch.plasmoid).

Install `audioswitch.plasmoid` from *Add or Manage Widgets...* > *Get New* > *Install Widget From Local File...*.

Restart plasmashell or log out and back in if it does not appear immediately.

### Manual

```sh
./install.sh
```

Then right-click your panel > *Add or Manage Widgets...* > search for **Audio Switch** and drag it onto the panel.

Re-run `./install.sh` after editing any file; it rebuilds the package, upgrades it and reloads plasmashell in one step.

To uninstall:

```sh
./install.sh remove
```

## Build

```sh
./build.sh
```

Writes `build/audioswitch.plasmoid`.

> [!TIP]
> Bump `Version` in `metadata.json` before each release, otherwise Plasma does not offer the update.

## Requirements

- Plasma 6 (developed and tested against 6.8.2)
- PipeWire with `pipewire-pulse`, or PulseAudio
- `kpackagetool6` (ships with KDE Frameworks 6)
- `gettext` to compile translations in `translate/` (`install.sh`, `build.sh`)
- `zip` (`install.sh`, `build.sh`)

> [!CAUTION]
> The widget reads and sets the default output through `org.kde.plasma.private.volume`, shipped by `plasma-pa`. It is a *private* module and carries no API stability guarantee, so a future Plasma release could require an update here.

## AI usage disclosure

I want to provide transparency and honesty about the use of AI in this project.

This project has been developed with the assistance of AI tools. AI was used to generate code snippets and documentation.

**ALL AI-generated content** has been **manually reviewed** and **edited by me (moxwel)**, to ensure code accuracy, readability, and quality with my personal standard coding practices.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
