-- Milenium V3 Pro — Example (drop-in demo, copy-paste into executor)
-- Shows every core element + new V3 features |  работает и в Studio (loadstring)

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/main/MileniumV2.lua"))()
-- local library = require(path.to.MileniumV2)  -- alternative if using require

-- 1) Create window
local window = library:window({
    name = "milenium",
    suffix = "pro",
    gameInfo = "Milenium V3 for Studio Demo",
    size = UDim2.new(0, 740, 0, 580)
})

-- optional: blur background
-- window:fade_background(true)
-- window:set_accent(Color3.fromRGB(120, 160, 255))

-- 2) Tabs (each tab:tab call returns pages for its sub-tabs)
local aimTab = window:tab({ name = "Combat", tabs = {"Aimbot", "Checks", "Visual"} })
local visuals = window:tab({ name = "Visuals", tabs = {"ESP", "World", "View"} })
local playerTab = window:tab({ name = "Players", tabs = {"List", "Tools"} })
local settingsTab = window:tab({ name = "Settings", tabs = {"Main", "Themes"} })

-- 3) Aimbot page example
do
    local page = aimTab[1] -- "Aimbot"
    local colL = page:column({})
    local colR = page:column({})

    -- Left column — main aimbot controls
    local section = colL:section({ name = "Aimbot", icon = "rbxassetid://6031094670", size = 0.65 })
    section:toggle({ name = "Enabled", flag = "aim_enabled", default = false, callback = function(v) print("aim_enabled", v) end })
        :keybind({ name = "Hold Key", flag = "aim_key", key = Enum.KeyCode.E, mode = "Toggle", callback = function(active) print("aim active", active) end })
        :colorpicker({ name = "FOV Color", flag = "aim_fov_color", color = Color3.fromRGB(155,150,219) })

    section:slider({ name = "FOV Size", flag = "aim_fov", min = 10, max = 500, default = 120, suffix = "°", callback = function(v) print("fov", v) end })
    section:slider({ name = "Smoothness", flag = "aim_smooth", min = 0, max = 1, default = 0.45, intervals = 0.01, suffix = "" })
    section:dropdown({ name = "Target Part", flag = "aim_part", options = {"Head", "Torso", "Random", "Nearest"}, default = "Head" })
    section:dropdown({ name = "Prediction", flag = "aim_pred", options = {"Off", "Low", "Medium", "High"}, default = "Medium" })

    section:divider()
    section:banner({ text = "TIP: Hold E to aim, right-click sections for context menu.", type = "info" })
    section:radio({ name = "Aim Mode", flag = "aim_mode", options = {"Camera", "Mouse", "Silent"}, default = "Camera", callback = function(v) print("aim_mode", v) end })

    section:button({ name = "Test Notification (success)", callback = function()
        library:notify("Aim config applied!", "success", "Aimbot")
    end })
    section:button({ name = "Test Prompt", callback = function()
        library:prompt({
            title = "Reset aimbot?",
            text = "This will reset all aim settings to defaults.",
            yes = function() library:notify("Reset done", "success") end,
            no = function() library:notify("Cancelled", "warn") end
        })
    end })

    -- Tooltip demo (hover tooltip on any element)
    local t = section:toggle({ name = "Silent Aim", flag = "silent_aim", default = false, info = "No camera movement (server-side)." })
    if library.tooltip then
        -- attaches tooltip to last created element (the toggle)
        t:tooltip({ text = "Silent aim hides your camera snap — may be detected on some games.", delay = 0.2 })
    end

    -- Right column — checks
    local checks = colR:section({ name = "Checks", size = 1, icon = "rbxassetid://6031090997" })
    checks:toggle({ name = "Wall Check", flag = "wall_check", default = true })
    checks:toggle({ name = "Team Check", flag = "team_check", default = true })
    checks:toggle({ name = "Distance Check", flag = "dist_check", default = false })
    checks:slider({ name = "Max Distance", flag = "max_dist", min = 100, max = 5000, default = 1200, suffix = " studs" })
    checks:input({ name = "Custom FOV (numeric input)", placeholder = "e.g. 120", default = 120, flag = "custom_fov", min = 0, max = 1000, integer = true })

    -- Context menu demo
    if library.context_menu then
        local menu = library:context_menu({ items = {
            { name = "Copy settings", callback = function() setclipboard(library:get_config()) library:notify("Copied config!", "success") end },
            { name = "Paste settings", callback = function() library:notify("Paste: use Load in Configs tab", "info") end },
            "sep",
            { name = "Reset page", callback = function() library:prompt({ title = "Reset?", text = "Reset this page?", yes = function() print("reset") end }) end },
        }})
        menu.attach(checks) -- right-click the section header to open menu
        -- also attach to a specific toggle
        -- menu.attach(checks) -- already
    end
end

-- 4) ESP visuals
do
    local page = visuals[1] -- "ESP"
    local col = page:column({})
    local esp = col:section({ name = "ESP", icon = "rbxassetid://6031094670" })

    esp:toggle({ name = "Boxes", flag = "esp_boxes", default = true })
        :colorpicker({ name = "Boxes Color", flag = "esp_boxes_color", color = Color3.fromRGB(155,150,219) })
    esp:toggle({ name = "Names", flag = "esp_names", default = true })
    esp:toggle({ name = "Health Bar", flag = "esp_health", default = true })
    esp:dropdown({ name = "Box Type", flag = "esp_box_type", options = {"2D", "3D", "Corner"}, default = "Corner" })
    esp:slider({ name = "Text Size", flag = "esp_text_size", min = 8, max = 24, default = 13, suffix = " px" })
    esp:progress_bar({ name = "ESP Update", value = 72, max = 100 })
    esp:divider({ height = 12 })
    esp:badge({ text = "BETA", color = Color3.fromRGB(90, 200, 120) })

    -- Hotbar demo
    local hotbar = library:hotbar({})
    hotbar.add_button({ name = "ESP", active = true, callback = function(v) library:set_flag("esp_boxes", v) end })
    hotbar.add_button({ name = "Aim", active = false, callback = function(v) library:set_flag("aim_enabled", v) end })
    hotbar.add_button({ name = "Fly", callback = function(v) library:notify(v and "Fly enabled" or "Fly disabled", v and "success" or "warn") end })
end

-- 5) Player list + search + card (V2/V3 new elements)
do
    local page = playerTab[1] -- "List"
    local col = page:column({})
    local plistSec = col:section({ name = "Players", icon = "rbxassetid://6034767608", size = 1 })

    -- Live player list (auto-refresh on join/leave)
    local plist = plistSec:player_list({
        name = "Online Players",
        flag = "selected_player",
        max_height = 220,
        callback = function(player) print("selected", player, player.DisplayName) library:notify("Selected: " .. player.DisplayName, "info") end
    })

    -- Filter bar (optional linked target demonstration)
    -- plistSec:search({ name = "Filter", placeholder = "type name...", target = plist }) -- uncomment if you want filtered list behaviour

    -- Player card (shows avatar + role)
    plistSec:player_card({ player = game.Players.LocalPlayer, name = game.Players.LocalPlayer.DisplayName, role = "Local Player", accent = Color3.fromRGB(155,150,219) })

    -- Multi-select (searchable)
    plistSec:multi_select({ name = "Whitelist", options = {"Player1","Player2","Player3","Player4","Player5","Player6"}, flag = "whitelist", callback = function(list) print("whitelist", table.concat(list, ", ")) end })

    -- Tab list (vertical selector)
    plistSec:tab_list({ name = "Action", options = {"Spectate","Teleport","Copy JobId","Kick (local)"}, default = 1, callback = function(opt, idx) print("action", opt, idx) end })

    -- Watermark (draggable, shows fps/ping)
    local wm = library:watermark({ text = "milenium.pro", sub = "v3.0.1 • studio" })
    -- wm.set_text("my watermark", "custom")

    -- Keybind list (floating)
    local kblist = library:keybind_list()
    -- Track keybinds (example manual track — real toggles auto-track via flag if you wire them)
    -- kblist.track("Aimbot", function() return library:get_flag("aim_enabled") end, function() return "E" end)
end

-- 6) Tools page — inputs & misc
do
    local page = playerTab[2]
    local col = page:column({})
    local sec = col:section({ name = "Tools" })
    sec:textbox({ name = "JobId", placeholder = "paste job id...", default = game.JobId, flag = "jobid" })
    sec:button({ name = "Copy JobId", callback = function() if setclipboard then setclipboard(game.JobId) library:notify("Copied!", "success") end end })
    sec:slider({ name = "WalkSpeed", flag = "ws", min = 16, max = 200, default = 16, suffix = " s" })
        :colorpicker({ name = "unused chained?", flag = "ws_color", color = Color3.fromRGB(120,120,255) }) -- chaining demo
    sec:divider()
    sec:label({ name = "Status: Ready", info = "All systems nominal. Drag window corners to resize." })
end

-- 7) Settings / Configs (init_config adds config saving/loading UI automatically)
-- We reuse the built-in config manager, but also demo custom settings
do
    local page = settingsTab[1] -- "Main"
    local col = page:column({})
    local sec = col:section({ name = "Interface" })

    sec:toggle({ name = "Acrylic Blur", flag = "acrylic", default = true, callback = function(v) window:fade_background(v) end })
    sec:dropdown({ name = "Animation", flag = "anim_style", options = {"tween","spring"}, default = "tween", callback = function(v) library:set_animation(v) library:notify("Animation: " .. v, "info") end })
    sec:colorpicker({ name = "Accent", flag = "accent", color = Color3.fromRGB(155,150,219), callback = function(col) library:update_theme("accent", col) end })

    -- Also add the default config manager UI (save/load/delete)
    -- This must be called once globally (it creates its own tab sections):
    -- library:init_config(window) -- already handled if you call below
end

-- 8) Initialize config system (call once after defining all flags)
-- This creates a "Configs" tab with save/load/delete + accent + menu bind
library:init_config(window)

-- 9) Menu toggle keybind (visible in settings)
-- You can also toggle via code:
-- window.toggle_menu(false) -- hide
-- window.toggle_menu(true)  -- show

-- 10) Notifications showcase
library:notify("Welcome to Milenium V3 Pro!", "info", "milenium.pro")
task.delay(1.2, function() library:notify("Player list auto-refresh is live", "success", "Players") end)
task.delay(2.4, function() library:notify("Right-click sections for context menu", "warn", "Tip") end)

print("[milenium] demo loaded — version", library:get_version() )
