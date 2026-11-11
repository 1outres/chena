local style = require("chena.settings").style

hl.config({
    general = {
        gaps_in     = style.gaps_in,
        gaps_out    = style.gaps_out,
        border_size = style.border_size,

        col = {
            active_border   = style.colors.active_border,
            inactive_border = style.colors.inactive_border,
        },

        resize_on_border = true,

        -- See https://wiki.hypr.land/configuring/extra/tearing/ before turning this on.
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = style.rounding,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},    {1, 1}    } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1}  } })

hl.animation({ leaf = "global",      enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "border",      enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 95%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2, bezier = "linear",       style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "layers",      enabled = true, speed = 3, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
