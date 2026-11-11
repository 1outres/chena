local style = require("chena.settings").style

hl.config({
    misc = {
        background_color         = style.colors.desktop,
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})
