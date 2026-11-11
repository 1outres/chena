local style = require("chena.settings").style

for _, namespace in ipairs(style.blurred_layers) do
    hl.layer_rule({
        name  = "blur-" .. namespace,
        match = { namespace = "^" .. namespace .. "$" },

        blur         = true,
        ignore_alpha = 0,
    })
end

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Unnamed floating XWayland windows break dragging when they take focus.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "float-chena-tools",
    match = { class = "^chena\\.floating$" },

    float  = true,
    center = true,
    size   = "900 600",
})
