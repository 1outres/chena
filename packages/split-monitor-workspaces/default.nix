# Gives each monitor its own set of workspaces. It is plain Lua, so chena only
# needs the source. Upstream keeps one branch per Hyprland release, and this rev
# is on release/0.57.x.
{ fetchFromGitHub }:

fetchFromGitHub {
  owner = "Duckonaut";
  repo = "split-monitor-workspaces";
  rev = "5fd2f066d12e727365535bb13beec78f8dbe4157";
  hash = "sha256-fy4pK/cuzazLOGdHR/597Yvik+2xbO/O6hehWtbd65k=";
}
