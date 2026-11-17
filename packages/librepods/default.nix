# LibrePods sets the AirPods to an A2DP profile when they go in the ears.
# Upstream tries SBC-XQ first, which skips AAC on AirPods.
{ librepods }:

librepods.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./prefer-the-best-codec.patch ];
})
