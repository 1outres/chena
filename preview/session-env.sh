# Prints, split by NUL, the environment that a login of this home would get.
home_dir=$1

set -a
# shellcheck source=/dev/null
. "$home_dir/.nix-profile/etc/profile.d/hm-session-vars.sh"
for file in "$home_dir"/.config/environment.d/*.conf; do
  # shellcheck source=/dev/null
  [[ -e $file ]] && . "$file"
done
set +a

exec env -0
