
hl.window_rule({
    name = "greedyApps",
    match = { class = ".*" },
    suppress_event = "maximize"
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name        = "xWaylandFix",
    match       = {
        class       = "^$",
        title       = "^$",
        xwayland    = true,
        float       = true,
        fullscreen  = false,
        pin         = false,
    },

    no_focus    = true,
})

-- BlueTooth Manager_OverSkride
hl.window_rule({
    name    = "init_OverSkride",
    match   = { class = "io.github.kaii_lb.Overskride" },
    float   = true,
    center  = true,
    opacity = 0.7,
})

-- Steam
hl.window_rule({
    name    = "init_SteamFloat",
    
    match   = {
        class = "^(steam)$",
        title = "^(Friends List)$"
    },

    size    = { 500, 700 },
    float   = true,
    center  = true,
    opacity = 0.7
})

-- Picture in Picture
hl.window_rule({
    name        = "init_PicInPic",
    match       = { title = "Picture-in-Picture" },
    float       = true,
    pin         = true,
    rounding    = 0,
    opaque      = true
})

-- Waypaper
hl.window_rule({
    name    = "init_waypaper",
    match   = { class = "waypaper" },
    size    = { 1200, 900 },
    float   = true,
    center  = true,
    opacity = 0.7
})

-- BlenderLauncher
hl.window_rule({
    name    = "init_BlenderLauncher",
    match   = { class = "blenderlauncher" },
    size    = { 1280, 720 },
    float   = true,
    center  = true,
    opacity = 0.7
})

-- MPV
hl.window_rule({
    name    = "init_mpv",
    match   = { class = "mpv" },
    float   = true,
    center  = true
})

-- Disable Quickshell animations
hl.layer_rule({
    name    = "disable_quickshell_animations",
    match   = { namespace = "quickshell" },
    no_anim = true
})

-- Thunar
hl.window_rule({
    name    = "init_Thunar",
    match   = { class = "thunar" },
    size    = { 1500, 900 },
    float   = true,
    center  = true,
    opacity = 0.7
})

-- Zenity
hl.window_rule({
    name    = "init_Zenity",
    match   = { class = "zenity" },
    opacity = 0.7
})

-- Spotify
hl.window_rule({
    name    = "init_Spotify",
    match   = { class = "Spotify" },
    opacity = 0.7
})

-- Rofi
hl.window_rule({
    name    = "init_Rofi",
    match   = { class = "Rofi" },
    opacity = 0.7
})

-- Power Menu Blur
hl.layer_rule({
    name         = "init_powermenu_blur",
    match        = { namespace = "power-menu" },
    blur         = true,
    ignore_alpha = 0.0,
    no_anim      = true  -- <--- Disables Hyprland's default zoom!
})

-- Shortcuts Menu Blur & Animation Fix
hl.layer_rule({
    name         = "init_shortcutsmenu_blur",
    match        = { namespace = "shortcuts-menu" },
    blur         = true,
    ignore_alpha = 0.0,
    no_anim      = true  -- <--- Disables Hyprland's default zoom!
})

-- Blur all Quickshell bars and attached popups
hl.layer_rule({
    name         = "blur_quickshell_main",
    match        = { namespace = "quickshell" },
    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.0
})
