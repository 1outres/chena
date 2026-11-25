# Hyprland destroys a wl_output global as soon as nobody holds it, even if it
# was removed a moment ago. A client that reads the add event a little late
# then binds a global that is gone, which is a fatal protocol error. This
# happens when the dock is unplugged with the lid closed: the only monitor goes
# away, Hyprland adds and removes its FALLBACK output at once, and the bar,
# the launcher, the wallpaper and most apps all lose their connection.
{ hyprland }:

hyprland.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./keep-removed-outputs-bindable.patch ];
})
