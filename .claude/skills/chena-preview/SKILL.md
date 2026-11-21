---
name: chena-preview
description: Run the chena shell (Waybar, Walker, mako, SwayOSD, hyprlock) in a hidden nested Hyprland, take screenshots, press keys and click, and read logs, without touching the real desktop. Use it to look at, improve, test or debug the "chena" shell, such as "make the bar look better", "check that the launcher works", "fix the lock screen", or any change under modules/home that shows on screen.
---

# chena preview

`nix run .#preview -- COMMAND` runs the chena shell from this checkout inside
a nested Hyprland. The nested Hyprland is a window of a KWin that has only a
virtual screen, so nothing shows on the real screens and the user can keep
working. The preview has its own HOME, runtime dir, session bus and system
bus. The system services the shell reads (logind, UPower, BlueZ,
NetworkManager, polkit) are mocks from python-dbusmock.

The preview always uses `shell = "chena"`. Its Home Manager config is
`preview/home.nix`.

## Loop

1. Start: `nix run .#preview -- start`. Add `--mode 2560x1600@60 --scale 2`
   to see a HiDPI screen.
2. Look: `nix run .#preview -- shot -s 0.5` prints the path of a PNG. Read
   it. Use `-g "X,Y WxH"` without `-s` to see a part at full size.
3. Act: press keys, type, click, then look again.
4. Change the code. Flakes only see files that git knows, so run
   `git add -N` on new files.
5. Restart to pick up the change: `nix run .#preview -- stop` then
   `nix run .#preview -- start`. `nix run` builds the new config.
6. Check: `nix flake check`. Add a test under `tests/` when the change has
   logic that a test can hold.
7. Stop the preview when done: `nix run .#preview -- stop`.

Build once and keep the path to skip the build on every call:
`p=$(nix build .#preview --print-out-paths)/bin/chena-preview`.

## Commands

| Command | What it does |
| --- | --- |
| `start [--mode WxH@HZ] [--scale S]` | Start. Default 1920x1200@60, scale 1 |
| `stop` | Stop every preview process and remove `/tmp/chena-preview` |
| `status` | Show which parts run. All should say `running` |
| `logs [NAME]` | List logs, or print one. `hyprland-core` is Hyprland's own log |
| `shot [-g "X,Y WxH"] [-s S] [FILE]` | Save a screenshot, print its path |
| `key COMBO` | Press a key: `SUPER+space`, `ALT+SHIFT+h`, `Escape`, `Return` |
| `type TEXT` | Type text |
| `click X Y [left\|right\|middle]` | Click at a point |
| `move X Y` | Move the pointer, such as to show a tooltip |
| `scroll STEPS` | Scroll down, or up when negative |
| `hyprctl ARGS...` | hyprctl against the preview, such as `clients`, `layers` |
| `run CMD...` | Run a command in the preview and wait for it |
| `spawn CMD...` | Start a command in the preview, logged under its name |
| `unlock` | Unlock the preview's hyprlock without a password |
| `env` | Print the preview environment as `export` lines |

Key names are XKB keysym names. Modifiers are `SUPER`, `ALT`, `CTRL` and
`SHIFT`. chena uses SUPER for apps and the system, and ALT for windows. See
`modules/home/hyprland/lua/binds.lua`.

## Coordinates

`click`, `move` and `-g` take layout pixels. A screenshot has `S` image
pixels per layout pixel, where `S` is the `-s` value, or the monitor scale
when `-s` is not given. So a point in an image is at layout `(x / S, y / S)`.

## Mocks

Change what the shell sees with calls on the preview system bus, such as a
connected Bluetooth device:

```sh
call() { "$p" run gdbus call --system --dest org.bluez "$@"; }
call --object-path / --method org.bluez.Mock.AddDevice hci0 11:22:33:44:55:66 "AirPods Pro"
# bluetui quits without a word when a device has no battery level.
call --object-path /org/bluez/hci0/dev_11_22_33_44_55_66 \
  --method org.freedesktop.DBus.Mock.AddProperty org.bluez.Battery1 Percentage "<byte 80>"
call --object-path / --method org.bluez.Mock.PairDevice hci0 11:22:33:44:55:66
call --object-path / --method org.bluez.Mock.ConnectDevice hci0 11:22:33:44:55:66
```

The methods of each mock are in the python-dbusmock templates
(`dbusmock/templates/*.py`). The logind mock has one session, `auto`, and
sends Lock and Unlock to it the way logind does, so SUPER+L locks.

## Safety

- Reach the preview only through this command. The shell you run in has the
  real `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE` and D-Bus addresses,
  so a plain `hyprctl`, `notify-send` or `wtype` acts on the real desktop.
- Never use `pkill`, `killall` or `pidof` by name. They also hit the real
  session, which may be locked with its own hyprlock. Use `stop` and
  `unlock`, which only touch processes that carry the preview runtime dir.
- `preview/home.nix` turns off the parts that would change the real machine,
  such as the brightness that the session saves and restores. Keep new parts
  that touch hardware out of the preview the same way.

## Limits

- The battery and the network in the bar come from the real machine, since
  Waybar reads them from sysfs and netlink.
- greetd, Plymouth, brightness keys, AirPods and lid switches do not run.
- The polkit agent registers with the mock, but nothing asks it for a
  password.
- hypridle runs, so the preview locks itself after five minutes without
  input. Use `unlock`.
- Binds are matched by keysym (`input.resolve_binds_by_sym`) because wtype
  sends key codes of its own keymap. Real keyboards behave the same with the
  single layout that chena sets.
- The launcher lists the apps of the real system too, since `XDG_DATA_DIRS`
  includes `/run/current-system/sw/share`.
