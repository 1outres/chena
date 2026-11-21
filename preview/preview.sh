# Runs the chena shell in a nested Hyprland inside a KWin with only a virtual
# screen, so nothing shows on the real screens. Everything gets its own HOME,
# runtime dir, session bus and system bus, so nothing reaches the real session
# or the real system services.

state_dir=$(dirname "$home_dir")
run_dir=$state_dir/run
log_dir=$state_dir/logs
pid_dir=$state_dir/pids
shot_dir=$state_dir/shots
env_file=$state_dir/env
kwin_socket=kwin
pointer_socket=$run_dir/pointer
# The real logind takes "auto" as the session of the caller, and loginctl and
# hypridle both ask for it. The logind mock only knows sessions by name.
session_id=auto

usage() {
  cat <<EOF
Usage: chena-preview COMMAND [ARGS]

Session:
  start [--mode WxH@HZ] [--scale S]   Start the preview (default 1920x1200@60, scale 1)
  stop                                Stop the preview and remove its state
  status                              Show which parts are running
  logs [NAME]                         List the logs, or print the log of NAME

Look:
  shot [-g "X,Y WxH"] [-s SCALE] [FILE]
                                      Save a screenshot and print its path

Act:
  key COMBO                           Press a key, such as SUPER+Space or Escape
  type TEXT                           Type text
  click X Y [left|right|middle]       Click at a point in layout pixels
  move X Y                            Move the pointer to a point in layout pixels
  scroll STEPS                        Scroll down, or up when negative
  hyprctl ARGS...                     Run hyprctl against the preview
  run COMMAND [ARGS...]               Run a command in the preview and wait
  spawn COMMAND [ARGS...]             Start a command in the preview, logged as its name
  env                                 Print the environment as export lines
  unlock                              Unlock hyprlock without the password

State lives in $state_dir.
EOF
}

die() {
  echo "chena-preview: $*" >&2
  exit 1
}

# Waits up to the given seconds for a command to succeed.
wait_for() {
  local seconds=$1
  shift
  local tries=$((seconds * 10))
  while ! "$@" >/dev/null 2>&1; do
    tries=$((tries - 1))
    [[ $tries -gt 0 ]] || return 1
    sleep 0.1
  done
}

base_env() {
  printf '%s\0' \
    "HOME=$home_dir" \
    "USER=$USER" \
    "LOGNAME=$USER" \
    "LANG=${LANG:-C.UTF-8}" \
    "PATH=$home_dir/.nix-profile/bin:$tools_path:/run/wrappers/bin:/run/current-system/sw/bin" \
    "XDG_RUNTIME_DIR=$run_dir" \
    "XDG_DATA_DIRS=$home_dir/.nix-profile/share:/run/current-system/sw/share" \
    "DBUS_SESSION_BUS_ADDRESS=unix:path=$run_dir/bus" \
    "DBUS_SYSTEM_BUS_ADDRESS=unix:path=$run_dir/system_bus" \
    "XDG_SESSION_ID=$session_id"
}

# Runs a command with only the preview environment. The caller's environment
# points at the real session, so none of it is passed on.
in_env() {
  local -a environment
  if [[ -f $env_file ]]; then
    mapfile -d "" -t environment <"$env_file"
  else
    mapfile -d "" -t environment < <(base_env)
  fi
  env -i "${environment[@]}" "$@"
}

# Starts a command in its own process group, with its output in a log.
launch() {
  local name=$1
  shift
  in_env env -C "$home_dir" setsid "$@" >"$log_dir/$name.log" 2>&1 &
  echo $! >"$pid_dir/$(next_index)-$name"
}

next_index() {
  local count
  count=$(find "$pid_dir" -mindepth 1 -maxdepth 1 | wc -l)
  printf '%02d' "$count"
}

is_running() {
  [[ -d $pid_dir ]] || return 1
  local pid_file
  for pid_file in "$pid_dir"/*; do
    [[ -e $pid_file ]] || continue
    kill -0 "$(<"$pid_file")" 2>/dev/null && return 0
  done
  return 1
}

require_running() {
  is_running && [[ -f $env_file ]] || die "the preview is not running"
}

prepare_home() {
  mkdir -p "$home_dir"
  cp -rsT --no-preserve=mode "$home_files" "$home_dir"
  ln -sfn "$home_path" "$home_dir/.nix-profile"
}

save_env() {
  local wayland_display=$1 signature=$2
  local -a session_env
  mapfile -d "" -t session_env < <(in_env "$session_env_script" "$home_dir")
  {
    base_env
    printf '%s\0' "${session_env[@]}" | grep -zvE '^(HOME|USER|LOGNAME|PATH|XDG_RUNTIME_DIR|XDG_DATA_DIRS|DBUS_[A-Z_]+|SHLVL|PWD|_)='
    printf '%s\0' \
      "WAYLAND_DISPLAY=$wayland_display" \
      "HYPRLAND_INSTANCE_SIGNATURE=$signature" \
      "XDG_CURRENT_DESKTOP=Hyprland" \
      "XDG_SESSION_DESKTOP=Hyprland" \
      "XDG_SESSION_TYPE=wayland"
  } >"$env_file"
}

hyprland_signature() {
  local dir
  for dir in "$run_dir"/hypr/*/; do
    [[ -S $dir/.socket.sock ]] || continue
    basename "$dir"
    return 0
  done
  return 1
}

hyprland_display() {
  local socket
  for socket in "$run_dir"/wayland-*; do
    [[ -S $socket ]] || continue
    basename "$socket"
    return 0
  done
  return 1
}

mock_call() {
  local name=$1 path=$2 method=$3
  shift 3
  in_env gdbus call --system --dest "$name" --object-path "$path" --method "$method" "$@" >/dev/null
}

mock_ready() {
  in_env gdbus introspect --system --dest "$1" --object-path "$2"
}

# Stand-ins for the system services that the shell reads, so it sees a
# believable machine and never reaches the real one.
start_mocks() {
  local -A objects=(
    [logind]="org.freedesktop.login1 /org/freedesktop/login1"
    [upower]="org.freedesktop.UPower /org/freedesktop/UPower"
    [bluez5]="org.bluez /"
    [networkmanager]="org.freedesktop.NetworkManager /org/freedesktop/NetworkManager"
    [polkitd]="org.freedesktop.PolicyKit1 /org/freedesktop/PolicyKit1/Authority"
  )
  local template
  for template in "${!objects[@]}"; do
    launch "mock-$template" python3 -m dbusmock --system --template "$template"
  done
  for template in "${!objects[@]}"; do
    # shellcheck disable=SC2086
    wait_for 10 mock_ready ${objects[$template]} \
      || die "the $template mock did not start; see $log_dir/mock-$template.log"
  done

  mock_call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.DBus.Mock.AddSession \
    "$session_id" seat0 "$(id -u)" "$USER" true
  # The template does nothing on these calls. The real logind sends Lock and
  # Unlock to the session, and hypridle locks the screen on Lock.
  local session_path=/org/freedesktop/login1/session/$session_id signal emit
  for signal in Lock Unlock; do
    emit="objects['$session_path'].EmitSignal('org.freedesktop.login1.Session', '$signal', '', [])"
    mock_call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.DBus.Mock.AddMethod \
      org.freedesktop.login1.Manager "${signal}Session" s "" "$emit"
    mock_call org.freedesktop.login1 "$session_path" org.freedesktop.DBus.Mock.AddMethod \
      org.freedesktop.login1.Session "$signal" "" "" "$emit"
  done
  mock_call org.bluez / org.bluez.Mock.AddAdapter hci0 preview
}

cmd_start() {
  local mode=1920x1200@60 scale=1
  while [[ $# -gt 0 ]]; do
    case $1 in
      --mode) mode=$2; shift 2 ;;
      --scale) scale=$2; shift 2 ;;
      *) die "start: unknown option $1" ;;
    esac
  done
  [[ $mode =~ ^([0-9]+)x([0-9]+)(@[0-9.]+)?$ ]] || die "start: --mode must look like 1920x1200@60"
  local width=${BASH_REMATCH[1]} height=${BASH_REMATCH[2]}

  is_running && die "the preview is already running; stop it first"
  rm -rf "$state_dir"
  mkdir -p "$run_dir" "$log_dir" "$pid_dir" "$shot_dir"
  chmod 700 "$run_dir"
  prepare_home

  launch system-bus dbus-daemon --session --nofork --address="unix:path=$run_dir/system_bus"
  launch session-bus dbus-daemon --session --nofork --address="unix:path=$run_dir/bus"
  wait_for 5 test -S "$run_dir/system_bus" || die "the system bus did not start"
  wait_for 5 test -S "$run_dir/bus" || die "the session bus did not start"

  start_mocks

  launch kwin kwin_wayland --virtual --width "$width" --height "$height" \
    --socket "$kwin_socket" --no-lockscreen
  wait_for 10 test -S "$run_dir/$kwin_socket" || die "KWin did not start; see $log_dir/kwin.log"

  launch hyprland env \
    WAYLAND_DISPLAY="$kwin_socket" \
    CHENA_PREVIEW_MODE="$mode" \
    CHENA_PREVIEW_SCALE="$scale" \
    start-hyprland -- -c "$home_dir/.config/hypr/hyprland.lua"
  wait_for 20 hyprland_signature || die "Hyprland did not start; see $log_dir/hyprland.log"
  wait_for 5 hyprland_display || die "Hyprland has no Wayland socket"
  save_env "$(hyprland_display)" "$(hyprland_signature)"

  launch pointer chena-preview-pointer serve "$pointer_socket" "$width" "$height" "$scale"
  wait_for 5 test -S "$pointer_socket" || die "the pointer did not start; see $log_dir/pointer.log"

  in_env dbus-update-activation-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE \
    XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
  in_env dconf load / <"$dconf_settings"

  local service
  for service in "$services"/*; do
    launch "$(basename "$service" | cut -d- -f2-)" "$service"
  done

  echo "started: $(in_env printenv WAYLAND_DISPLAY) at $mode, scale $scale"
}

# Hyprland starts apps in their own sessions, so the process groups of the
# launched parts miss them. Every process of the preview has its runtime dir.
preview_pids() {
  local environ
  for environ in /proc/[0-9]*/environ; do
    grep -qzx "XDG_RUNTIME_DIR=$run_dir" "$environ" 2>/dev/null || continue
    environ=${environ#/proc/}
    echo "${environ%/environ}"
  done
}

all_gone() {
  local pid
  for pid in "$@"; do
    kill -0 "$pid" 2>/dev/null && return 1
  done
  return 0
}

cmd_stop() {
  [[ -d $state_dir ]] || return 0
  local -a pids
  mapfile -t pids < <(preview_pids)
  if [[ ${#pids[@]} -gt 0 ]]; then
    kill -TERM "${pids[@]}" 2>/dev/null || true
    if ! wait_for 5 all_gone "${pids[@]}"; then
      kill -KILL "${pids[@]}" 2>/dev/null || true
    fi
  fi
  rm -rf "$state_dir"
}

cmd_status() {
  [[ -d $pid_dir ]] || { echo "not running"; return 0; }
  local pid_file name
  for pid_file in "$pid_dir"/*; do
    [[ -e $pid_file ]] || continue
    name=$(basename "$pid_file" | cut -d- -f2-)
    if kill -0 "$(<"$pid_file")" 2>/dev/null; then
      echo "running  $name"
    else
      echo "stopped  $name"
    fi
  done
}

cmd_logs() {
  if [[ $# -eq 0 ]]; then
    find "$log_dir" -name '*.log' -printf '%f\n' | sed 's/\.log$//' | sort
    echo hyprland-core
    return 0
  fi
  if [[ $1 == hyprland-core ]]; then
    cat "$run_dir"/hypr/*/hyprland.log
    return 0
  fi
  cat "$log_dir/$1.log"
}

cmd_shot() {
  require_running
  local -a grim_args=()
  local file
  while [[ $# -gt 0 ]]; do
    case $1 in
      -g|-s) grim_args+=("$1" "$2"); shift 2 ;;
      *) file=$1; shift ;;
    esac
  done
  file=${file:-$shot_dir/$(date +%H%M%S-%N).png}
  in_env grim "${grim_args[@]}" "$file"
  echo "$file"
}

modifier() {
  case ${1,,} in
    super|logo|win|mod4) echo logo ;;
    ctrl|control) echo ctrl ;;
    alt|mod1) echo alt ;;
    shift) echo shift ;;
    *) die "key: unknown modifier $1" ;;
  esac
}

cmd_key() {
  require_running
  [[ $# -eq 1 ]] || die "key: give one combo, such as SUPER+Space"
  local -a parts press=() release=()
  IFS=+ read -ra parts <<<"$1"
  local key=${parts[-1]} part mod
  for part in "${parts[@]:0:${#parts[@]}-1}"; do
    mod=$(modifier "$part")
    press+=(-M "$mod")
    release=(-m "$mod" "${release[@]}")
  done
  in_env wtype "${press[@]}" -k "$key" "${release[@]}"
}

cmd_type() {
  require_running
  in_env wtype -- "$*"
}

pointer() {
  in_env chena-preview-pointer send "$pointer_socket" "$@"
}

cmd_move() {
  require_running
  [[ $# -eq 2 ]] || die "move: give X and Y"
  pointer move "$1" "$2"
}

cmd_click() {
  require_running
  [[ $# -ge 2 ]] || die "click: give X and Y"
  pointer move "$1" "$2"
  pointer click "${3:-left}"
}

cmd_scroll() {
  require_running
  [[ $# -eq 1 ]] || die "scroll: give the steps"
  pointer scroll "$1"
}

cmd_spawn() {
  require_running
  [[ $# -ge 1 ]] || die "spawn: give a command"
  launch "$(basename "$1")" "$@"
}

cmd_env() {
  require_running
  local -a environment
  mapfile -d "" -t environment <"$env_file"
  local assignment
  for assignment in "${environment[@]}"; do
    printf 'export %s=%q\n' "${assignment%%=*}" "${assignment#*=}"
  done
}

# hyprlock unlocks on SIGUSR1. Only the preview's own hyprlock may get it,
# since the real session can be locked at the same time.
cmd_unlock() {
  require_running
  local pid
  while read -r pid; do
    if [[ $(cat "/proc/$pid/comm" 2>/dev/null) == hyprlock ]]; then
      kill -USR1 "$pid"
    fi
  done < <(preview_pids)
}

command=${1:-}
[[ $# -gt 0 ]] && shift
case $command in
  start) cmd_start "$@" ;;
  stop) cmd_stop ;;
  status) cmd_status ;;
  logs) cmd_logs "$@" ;;
  shot) cmd_shot "$@" ;;
  key) cmd_key "$@" ;;
  type) cmd_type "$@" ;;
  move) cmd_move "$@" ;;
  click) cmd_click "$@" ;;
  scroll) cmd_scroll "$@" ;;
  hyprctl) require_running; in_env hyprctl "$@" ;;
  run) require_running; in_env "$@" ;;
  spawn) cmd_spawn "$@" ;;
  env) cmd_env ;;
  unlock) cmd_unlock ;;
  ""|help|-h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
