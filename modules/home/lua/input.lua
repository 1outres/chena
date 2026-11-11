local settings = require("chena.settings")

hl.config({
    input = {
        kb_layout  = settings.keyboard.layout,
        kb_options = table.concat(settings.keyboard.options, ","),

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = settings.touchpad.natural_scroll,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
