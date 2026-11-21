hl.monitor({
    output   = "",
    mode     = os.getenv("CHENA_PREVIEW_MODE"),
    position = "0x0",
    scale    = tonumber(os.getenv("CHENA_PREVIEW_SCALE")),
})

-- Each preview starts with an empty HOME, so Hyprland would treat every
-- start as an update and cover the screen with its news.
hl.config({
    ecosystem = {
        no_update_news = true,
    },

    -- The script presses keys with wtype, which sends key codes of its own
    -- keymap. Binds read key codes with the configured layout by default, so
    -- they would see other keys.
    input = {
        resolve_binds_by_sym = true,
    },
})
