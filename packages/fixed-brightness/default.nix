# Sets each given backlight, or every backlight when none is given, to a fixed
# level. It runs as root, so it writes sysfs directly.
{
  writeShellScript,
  coreutils,
  level,
}:

writeShellScript "chena-fixed-brightness" ''
  shopt -s nullglob
  devices=("$@")
  [ ''${#devices[@]} -gt 0 ] || devices=(/sys/class/backlight/*)
  for device in "''${devices[@]}"; do
    max=$(${coreutils}/bin/cat "$device/max_brightness")
    echo $(( max * ${toString level} / 100 )) > "$device/brightness"
  done
''
