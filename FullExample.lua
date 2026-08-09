--!strict
-- =============================================================================
--  Milenium V3 Pro — FULL EXAMPLE (абсолютно всё, copy-paste в executor)
--  Покрывает 100% API: window/tab/column/section + все 25+ элементов + новые V3
--  Работает в Studio и в любом экзекуторе (Synapse/KRNL/Fluxus/Electron/Delta)
--  Версия библиотеки: library:get_version() -> "3.0.1-pro"
-- =============================================================================

-- 0) Загрузка библиотеки -------------------------------------------------------
-- Вариант A: с GitHub (executor)
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/main/MileniumV2.lua"))()
-- Вариант B: локально (Studio) — раскомментируй если файл рядом:
-- local library = require(script.Parent.MileniumV2)
-- Вариант C: из getcustomasset / loadfile — любой способ, главное что вернёт table library

print("[milenium] version:", library:get_version())

-- Хелпер для демо-колбэков
local function log(...) print("[demo]", ...) end

-- =============================================================================
-- 1) WINDOW — главное окно
-- =============================================================================
local window = library:window({
    name = "milenium",                -- левая часть заголовка (цвет accent)
    suffix = "pro",                   -- правая часть (белая)
    gameInfo = "Milenium V3 • Full Demo • Studio", -- подпись снизу
    size = UDim2.new(0, 780, 0, 620),  -- размер окна, можно менять мышью (resizify)
    -- suffix / Suffix / gameInfo / GameInfo — все алиасы работают
})
-- window:fade_background(true/false) — вкл/выкл BlurEffect за окном
-- window:set_accent(Color3) — алиас к library:update_theme("accent", ...)
-- window.toggle_menu(bool) — показать/скрыть всё меню (используется keybind из init_config)

-- =============================================================================
-- 2) TABS — вкладки слева + верхние sub-tabs
-- =============================================================================
-- Каждая window:tab создаёт кнопку слева. Внутри — верхние секции (multi tabs)
local combatTab   = window:tab({ name = "Combat",   icon = "rbxassetid://6031094670", tabs = {"Aimbot","Checks","Trigger","Antiaim"} })
local visualsTab  = window:tab({ name = "Visuals",  icon = "rbxassetid://6031090997", tabs = {"ESP","World","View","Materials"} })
local playersTab  = window:tab({ name = "Players",  icon = "rbxassetid://6034767608", tabs = {"List","Tools","Misc"} })
local worldTab    = window:tab({ name = "World",    icon = "rbxassetid://6031094678", tabs = {"Movement","Environ","Exploits"} })
local settingsTab = window:tab({ name = "Settings", icon = "rbxassetid://6031225810", tabs = {"Main","Themes","Configs"} })

-- Разделитель в списке вкладок слева
window:seperator({ name = "Utilities" })
local utilsTab = window:tab({ name = "Utilities", icon = "rbxassetid://6031225810", tabs = {"Debug","About"} })

-- =============================================================================
-- 3) COMBAT / Aimbot — показываем column / sub_tab / section + все базовые элементы
-- =============================================================================
do
    -- combatTab[1] == "Aimbot", [2]=="Checks" и т.д. (порядок как в tabs)
    local page = combatTab[1] -- Aimbot
    -- sub_tab позволяет сделать строчку из колонок с flex
    local sub = page:sub_tab({})
    local colL = sub:column({ size = 1 })
    local colR = sub:column({ size = 1 })

    -- Section с fading_toggle (переключатель в заголовке секции)
    local aimSec = colL:section({
        name = "Aimbot Engine",
        icon = "rbxassetid://6031094670",
        size = 0.72,               -- 0..1 доля высоты колонки
        fading_toggle = true,      -- переключатель в шапке (затеняет секцию)
        default = true
    })

    -- TOGGLE: два визуальных типа — "toggle" (pill) и "checkbox" (квадрат)
    -- Можно форсить тип: type="toggle" | type="checkbox"
    local tEnabled = aimSec:toggle({
        name = "Enabled",
        flag = "aim_enabled",
        default = false,
        type = "toggle",           -- или "checkbox"
        info = "Главный свитч аимбота. Поддерживает :colorpicker и :keybind чейном.",
        callback = function(v) log("aim_enabled =", v) end,
        seperator = false          -- добавить линию снизу
    })
    -- Чейнинг: toggle → keybind → colorpicker (все три в одной строке справа)
    tEnabled:keybind({
        name = "Aim Key",
        flag = "aim_key",
        key = Enum.KeyCode.E,      -- по умолчанию
        mode = "Toggle",           -- Hold / Toggle / Always
        callback = function(active) log("aim_key active =", active) end
    }):colorpicker({
        name = "FOV Ring",
        flag = "aim_fov_color",
        color = Color3.fromRGB(155, 150, 219),
        alpha = 0,                 -- 0..1 прозрачность (1 - alpha в API)
        callback = function(col, a) log("fov color", col, a) end
    })

    -- второй toggle с type checkbox и seperator
    aimSec:toggle({
        name = "Silent Aim",
        flag = "silent_aim",
        default = false,
        type = "checkbox",
        info = "Без доворота камеры — меньше палива.",
        callback = function(v) log("silent_aim", v) end,
        seperator = true
    })

    -- SLIDER: все параметры
    aimSec:slider({
        name = "FOV",
        flag = "aim_fov",
        min = 10, max = 500, default = 120,
        interval = 1,              -- шаг, алиас decimal
        suffix = "°",              -- постфикс
        info = "Радиус FOV круга",
        callback = function(v) log("FOV", v) end
    })
    aimSec:slider({
        name = "Smoothness",
        flag = "aim_smooth",
        min = 0, max = 1, default = 0.45,
        interval = 0.01,
        suffix = "",
        callback = function(v) log("smooth", v) end
    })
    -- Slider без линии разделителя
    aimSec:slider({
        name = "Prediction",
        flag = "aim_pred_slider",
        min = 0, max = 100, default = 50, suffix = "%",
        seperator = false
    })

    -- DROPDOWN: single и multi, scrolling, width
    aimSec:dropdown({
        name = "Target Part",
        flag = "aim_part",
        items = {"Head","Torso","Random","Nearest"},
        default = "Head",          -- или {"Head","Torso"} если multi=true
        multi = false,
        scrolling = false,         -- нужен ли скролл при >6 итемов
        width = 140,               -- ширина кнопки дропдауна
        callback = function(v) log("aim_part =", v) end
    })
    aimSec:dropdown({
        name = "Checks (multi)",
        flag = "aim_checks_multi",
        items = {"Wall","Team","Distance","Visibility","Knocked"},
        default = {"Wall","Team"},
        multi = true,
        callback = function(tbl) log("checks multi", table.concat(tbl, ", ")) end
    })

    -- LABEL + info
    aimSec:label({ name = "Status: Ready", info = "Все системы в норме. Перетаскивай окно за шапку, ресайз — правый-нижний угол." })
    aimSec:divider({ height = 12 }) -- тонкая линия

    -- BANNER (новый V3) — типы info/success/warn/error
    aimSec:banner({ text = "TIP: ПКМ по секции — контекстное меню. Колесом — скролл.", type = "info" })
    aimSec:banner({ text = "Включен Silent Aim — WallCheck отключён автоматически.", type = "warn" })

    -- RADIO (новый V3)
    aimSec:radio({
        name = "Aim Mode",
        flag = "aim_mode",
        options = {"Camera","Mouse mover","Silent"},
        default = "Camera",
        callback = function(v) log("aim_mode", v) end
    })

    -- BUTTON
    aimSec:button({ name = "Test Notification (success)", callback = function()
        library:notify("Aim config applied!", "success", "Aimbot")
    end })
    aimSec:button({ name = "Test Prompt — Reset Aim", callback = function()
        library:prompt({
            title = "Reset aimbot?",
            text = "Все слайдеры и дропдауны вернутся к дефолту. Продолжить?",
            yes = function() library:notify("Reset done", "success"); library:set_flag("aim_fov", 120) end,
            no  = function() library:notify("Cancelled", "warn") end
        })
    end })

    -- TOOLTIP (новый V3) — можно на любой элемент
    local tipOwner = aimSec:toggle({ name = "Auto Shoot", flag = "auto_shoot", default = true, info = "Авто-выстрел при наведении." })
    tipOwner:tooltip({ text = "Работает только если aim_enabled = true и цель в FOV", delay = 0.25 })
    -- Альтернативно: library:tooltip({ text="...", target=tipOwner })

    -- INPUT (новый V3) — числовой инпут с min/max
    aimSec:input({
        name = "Custom FOV (number)",
        flag = "custom_fov_num",
        placeholder = "120",
        default = 120,
        min = 0, max = 1000,
        integer = true,
        callback = function(v) log("custom_fov_num", v) end
    })

    -- CONTEXT MENU (новый V3)
    local ctx = library:context_menu({ items = {
        { name = "Copy config", callback = function() if setclipboard then setclipboard(library:get_config()) end; library:notify("Copied!", "success") end },
        { name = "Paste config", callback = function() library:notify("Use Load in Configs tab", "info") end },
        "sep",
        { name = "Reset section", callback = function() log("reset section clicked") end },
    }})
    ctx.attach(aimSec) -- ПКМ по секции
    ctx.attach(tipOwner) -- можно и по конкретному элементу

    -- Правая колонка — Checks
    local checksSec = colR:section({ name = "Aim Checks", icon = "rbxassetid://6031090997", size = 1 })
    checksSec:toggle({ name = "Wall Check", flag = "wall_check", default = true })
    checksSec:toggle({ name = "Team Check", flag = "team_check", default = true })
    checksSec:toggle({ name = "Distance Check", flag = "dist_check", default = false })
    checksSec:slider({ name = "Max Distance", flag = "max_dist", min = 100, max = 5000, default = 1400, suffix = " studs" })
    checksSec:dropdown({ name = "Sort Mode", flag = "sort_mode", items = {"Distance","FOV","Health","Random"}, default = "Distance" })
    checksSec:progress_bar({ name = "Target Stability", value = 68, max = 100 }) -- полоска
    checksSec:divider()
    checksSec:badge({ text = "LIVE", color = Color3.fromRGB(90, 200, 120) })
    checksSec:badge({ text = "BETA • 3.0.1", color = Color3.fromRGB(155,150,219) })
end

-- =============================================================================
-- 4) COMBAT / Trigger & Antiaim — textbox, keybind, keybind_list демо
-- =============================================================================
do
    local page = combatTab[3] -- Trigger
    local col = page:column({})
    local sec = col:section({ name = "Trigger Bot" })
    sec:toggle({ name = "Enabled", flag = "trigger_enabled", default = false })
        :keybind({ name = "Trigger Key", flag = "trigger_key", key = Enum.KeyCode.T, mode = "Hold", callback = function(a) log("trigger", a) end })
    sec:slider({ name = "Delay", flag = "trigger_delay", min = 0, max = 500, default = 80, suffix = " ms" })
    sec:textbox({ name = "Log webhook", placeholder = "https://discord.com/api/webhooks/...", flag = "webhook_url", default = "" })
    sec:label({ name = "Trigger only on visible", info = "Требует WallCheck = true в Aimbot/Checks." })

    local pageAA = combatTab[4] -- Antiaim
    local col2 = pageAA:column({})
    local secAA = col2:section({ name = "Antiaim (fake lag)" })
    secAA:toggle({ name = "Spinbot", flag = "spin", default = false })
    secAA:slider({ name = "Spin Speed", flag = "spin_speed", min = 1, max = 50, default = 12 })
    secAA:dropdown({ name = "Pitch", flag = "pitch", items = {"None","Up","Down","Zero","Random"}, default = "Up" })
    -- settings — маленькая шестерёнка справа от элемента (открывает popup)
    local withSettings = secAA:toggle({ name = "Desync", flag = "desync", default = false })
    local popup = withSettings:settings({}) -- создаёт тул-бар с иконкой ⚙ (ПКМ по шестерёнке открывает)
    -- В popup можно добавлять элементы как в секцию (popup:list / popup:toggle и т.д.):
    popup:list({ options={"Popup Opt A","Popup Opt B","Popup Opt C"}, flag="popup_demo", callback=function(v) log("popup list", v) end })
    -- popup сам — Frame, не секция, но благодаря setmetatable наследует все library-методы
end

-- =============================================================================
-- 5) VISUALS / ESP — hotbar, progress, badge, colorpicker c alpha, divider
-- =============================================================================
do
    local page = visualsTab[1] -- ESP
    local col = page:column({})
    local esp = col:section({ name = "Player ESP", icon = "rbxassetid://6031094670" })

    esp:toggle({ name = "Enabled", flag = "esp_enabled", default = true })
        :colorpicker({ name = "Box", flag = "esp_box_col", color = Color3.fromRGB(155,150,219), alpha = 0.1 })
        :colorpicker({ name = "Fill", flag = "esp_fill_col", color = Color3.fromRGB(155,150,219), alpha = 0.85 })
    esp:toggle({ name = "Name", flag = "esp_name", default = true })
    esp:toggle({ name = "Health Bar", flag = "esp_health", default = true, type = "checkbox" })
    esp:toggle({ name = "Distance", flag = "esp_dist", default = false })
    esp:dropdown({ name = "Box Type", flag = "esp_box_type", items = {"Corner","2D","3D","None"}, default = "Corner" })
    esp:slider({ name = "Box Thickness", flag = "esp_thick", min = 1, max = 4, default = 1 })
    esp:slider({ name = "Text Size", flag = "esp_text", min = 8, max = 22, default = 13, suffix = " px" })
    esp:progress_bar({ name = "ESP Refresh", value = 24, max = 60 }) -- для красоты, можно анимировать через :set()
    esp:divider({ height = 16 })
    esp:badge({ text = "UPDATED", color = Color3.fromRGB(90,200,120) })
    esp:label({ name = "Tag: Developer", info = "Отображается над головой у админов." })

    -- вторая колонка ESP
    local col2 = page:column({})
    local world = col2:section({ name = "World ESP" })
    world:toggle({ name = "Item ESP", flag = "item_esp", default = true })
    world:toggle({ name = "Chest ESP", flag = "chest_esp", default = false })
    world:dropdown({ name = "Item Filter (multi)", flag = "item_filter", items = {"Weapon","Ammo","Med","Armor"}, default = {"Weapon"}, multi = true })
    world:slider({ name = "Max Distance", flag = "world_dist", min = 50, max = 5000, default = 800 })
    world:button({ name = "Refresh ESP", callback = function() library:notify("ESP refreshed", "info") end })

    -- HOTBAR (плавающая панель кнопок)
    local hotbar = library:hotbar({ position = UDim2.new(0.5, 0, 0, 10) })
    hotbar.add_button({ name = "ESP", active = true, width = 44, callback = function(v) library:set_flag("esp_enabled", v); log("hotbar ESP", v) end })
    hotbar.add_button({ name = "AIM", active = false, width = 44, callback = function(v) library:set_flag("aim_enabled", v) end })
    hotbar.add_button({ name = "FLY", active = false, width = 44, callback = function(v) log("fly hotbar", v); library:notify(v and "Fly ON" or "Fly OFF", v and "success" or "warn") end })
    -- hotbar.set_visible(false) — скрыть
end

-- World & View
do
    local page = visualsTab[2] -- World
    local col = page:column({})
    local sec = col:section({ name = "World" })
    sec:slider({ name = "Brightness", flag = "brightness", min = 0, max = 5, default = 2, interval = 0.1 })
    sec:slider({ name = "Fog Density", flag = "fog", min = 0, max = 1, default = 0.2, interval = 0.01 })
    sec:colorpicker({ name = "Ambient", flag = "ambient", color = Color3.fromRGB(140,140,160) })
    sec:toggle({ name = "Fullbright", flag = "fullbright", default = false })
    sec:divider()
    sec:button({ name = "Reset World", callback = function() log("reset world") end })

    local col2 = page:column({})
    local sec2 = col2:section({ name = "View" })
    sec2:slider({ name = "FOV Changer", flag = "view_fov", min = 70, max = 120, default = 80 })
    sec2:toggle({ name = "No Bob", flag = "nobob", default = false })
    sec2:dropdown({ name = "Material", flag = "mat", items = {"Smooth","ForceField","Glass","Neon"}, default = "Smooth" })
end

-- =============================================================================
-- 6) PLAYERS — player_list + search + player_card + multi_select + tab_list + input
-- =============================================================================
do
    local page = playersTab[1] -- List
    local col = page:column({})
    local sec = col:section({ name = "Online Players", icon = "rbxassetid://6034767608", size = 0.60 })

    -- PLAYER_LIST — живой список (авто-обновляется при входе/выходе)
    local plist = sec:player_list({
        name = "Players",
        flag = "selected_player",   -- в flags будет Instance игрока
        max_height = 220,
        include_self = true,        -- показывать себя?
        callback = function(plr)
            log("selected", plr.Name, plr.DisplayName)
            library:notify("Selected: " .. plr.DisplayName, "success", "Players")
            -- можно сразу обновить карточку:
            if _G.updateCard then _G.updateCard(plr) end
        end
    })
    -- Дополнительный ручной search (если хочешь фильтровать отдельный list)
    -- Создаём отдельный list и фильтруем его через search:
    local dummyList = sec:list({ options = {"Alpha","Beta","Gamma","Delta","Epsilon"}, flag = "dummy_list", callback = function(v) log("dummy list", v) end })
    sec:search({ name = "Search dummy", placeholder = "filter dummy...", target = dummyList })

    -- PLAYER_CARD — карточка игрока с аватаркой
    local card = sec:player_card({
        player = game.Players.LocalPlayer,
        name = game.Players.LocalPlayer.DisplayName,
        role = "LocalPlayer • Alive",
        accent = Color3.fromRGB(155,150,219)
    })
    _G.updateCard = function(plr)
        card.update(plr, plr.DisplayName, "Target • " .. (plr.Team and plr.Team.Name or "No Team"))
        card.set_status_color(Color3.fromRGB(90,200,120))
    end
    -- tooltip на карточке
    card:tooltip({ text = "Клик по игроку в списке выше — обновит карточку. ПКМ — меню." })

    -- CONTEXT MENU на карточке
    local cardMenu = library:context_menu({ items = {
        { name = "Spectate", callback = function() log("spectate", library:get_flag("selected_player")) end },
        { name = "Teleport to", callback = function() log("tp") end },
        "sep",
        { name = "Copy UserId", callback = function()
            local p = library:get_flag("selected_player")
            if p and setclipboard then setclipboard(tostring(p.UserId)); library:notify("Copied UserId", "success") end
        end },
    }})
    cardMenu.attach(card)

    local sec2 = col:section({ name = "Selection Tools" })
    -- MULTI_SELECT — мульти-выбор с поиском внутри
    sec2:multi_select({
        name = "Friend Whitelist",
        options = {"PlayerOne","PlayerTwo","PlayerThree","PlayerFour","PlayerFive","PlayerSix","PlayerSeven"},
        flag = "friend_whitelist",
        max = 6,                   -- лимит выбора (nil = бесконечно)
        default = {"PlayerOne"},
        callback = function(tbl) log("whitelist", table.concat(tbl, ", ")) end
    })
    -- TAB_LIST — вертикальный список-табы (для настроек)
    sec2:tab_list({
        name = "Quick Action",
        options = {"Spectate","Teleport","Copy JobId","View Inventory","Kick (local only)"},
        default = 1,
        callback = function(opt, idx) log("quick action", opt, idx) library:notify(opt, "info") end
    })
    -- INPUT — числовой/текстовый инпут (отдельно от слайдера)
    sec2:input({
        name = "Teleport Distance",
        placeholder = "100",
        flag = "tp_dist",
        default = 100,
        min = 0, max = 5000, integer = true,
        callback = function(v) log("tp_dist", v) end
    })
    sec2:button({ name = "Do Action", callback = function()
        local act = library:get_flag("quick_action") or "Spectate"
        library:prompt({ title = "Confirm: " .. tostring(act) .. "?", text = "Выполнить действие для выбранного игрока?", yes = function() log("confirmed", act) end })
    end })

    -- KEYBIND_LIST + WATERMARK — плавающие панели
    local wm = library:watermark({ text = "milenium.pro", sub = "v3.0.1 • full demo" })
    -- wm.set_text("new title", "new sub")
    -- wm.set_visible(false)

    local kblist = library:keybind_list()
    -- kblist.track("Aimbot", function() return library:get_flag("aim_enabled") end, function() return library:get_flag("aim_key") and library:get_flag("aim_key").key or "NONE" end)
    -- авто-трекинг уже происходит если ты используешь :keybind — kblist обновляется каждую 0.25с

    -- PROGRESS_BAR demo (анимируем)
    sec2:progress_bar({ name = "Loading demo", value = 10, max = 100 })
end

-- Tools
do
    local page = playersTab[2]
    local col = page:column({})
    local sec = col:section({ name = "Tools" })
    sec:textbox({ name = "JobId", placeholder = "paste job id...", flag = "jobid_box", default = game.JobId, callback = function(v) log("jobid", v) end })
    sec:button({ name = "Copy JobId", callback = function() if setclipboard then setclipboard(game.JobId) library:notify("Copied JobId", "success") end end })
    sec:button({ name = "Rejoin", callback = function()
        library:prompt({ title = "Rejoin?", text = "Перезайти на тот же сервер?", yes = function() log("rejoin") end })
    end })
    sec:divider()
    sec:slider({ name = "WalkSpeed", flag = "walkspeed", min = 16, max = 250, default = 16, suffix = " studs/s" })
    sec:slider({ name = "JumpPower", flag = "jumppower", min = 50, max = 250, default = 50 })
    sec:divider()
    sec:label({ name = "System Status", info = "Все модули загружены. Window можно ресайзить тянучкой в углу." })

    -- LIST — простой список кнопок
    local lstSec = col:section({ name = "Server List" })
    local lst = lstSec:list({
        options = {"Server #1 — 12/20","Server #2 — 8/20","Server #3 — 20/20 (full)","Private Server"},
        flag = "server_pick",
        callback = function(v) log("server pick", v) end
    })
    -- lst.refresh_options({"new","list"}) — обновить извне
end

-- Misc
do
    local page = playersTab[3]
    local col = page:column({})
    local sec = col:section({ name = "Misc / Debug" })
    sec:toggle({ name = "Anti-AFK", flag = "anti_afk", default = false, callback = function(v) log("anti_afk", v) end })
    sec:dropdown({ name = "Language", flag = "lang", items = {"Русский","English","Español"}, default = "Русский" })
    sec:textbox({ name = "Custom prefix", flag = "prefix", placeholder = "!", default = "!" })
    sec:button({ name = "Clear notifications", callback = function()
        for _, n in ipairs(library.notifications.notifs) do if n then pcall(function() n:Destroy() end) end end
        table.clear(library.notifications.notifs)
    end })
    sec:banner({ text = "FullExample покрывает 100% элементов. Смотри код — каждый вызов прокомментирован.", type = "success" })
end

-- =============================================================================
-- 7) WORLD — movement / exploits / environ
-- =============================================================================
do
    local page = worldTab[1] -- Movement
    local col = page:column({})
    local move = col:section({ name = "Movement" })
    move:toggle({ name = "Speedhack", flag = "speedhack", default = false })
        :keybind({ name = "Toggle", flag = "speed_key", key = Enum.KeyCode.LeftShift, mode = "Toggle" })
    move:slider({ name = "Speed", flag = "speed_val", min = 16, max = 100, default = 32 })
    move:toggle({ name = "Infinite Jump", flag = "inf_jump", default = false, type = "checkbox" })
    move:input({ name = "Jump Height", flag = "jump_h", default = 50, min = 0, max = 500, integer = true })
    move:divider()
    move:button({ name = "Reset Movement", callback = function()
        library:set_flag("speedhack", false); library:set_flag("speed_val", 32)
        library:notify("Movement reset", "warn")
    end })

    local page2 = worldTab[2]
    local col2 = page2:column({})
    local env = col2:section({ name = "Environment" })
    env:slider({ name = "Time of Day", flag = "tod", min = 0, max = 24, default = 14, interval = 0.5, suffix = "h" })
    env:colorpicker({ name = "Fog Color", flag = "fog_col", color = Color3.fromRGB(160,160,180) })
    env:toggle({ name = "No Fog", flag = "no_fog", default = false })
    env:dropdown({ name = "Weather", flag = "weather", items = {"Clear","Rain","Fog","Storm"}, default = "Clear" })

    local page3 = worldTab[3]
    local col3 = page3:column({})
    local exp = col3:section({ name = "Exploits (demo)" })
    exp:toggle({ name = "Click TP (Ctrl+Click)", flag = "clicktp", default = false })
        :keybind({ name = "Key", flag = "clicktp_key", key = Enum.KeyCode.LeftControl, mode = "Hold" })
    exp:button({ name = "TP to Spawn", callback = function() log("tp spawn") end })
    exp:divider()
    exp:label({ name = "Exploit status", info = "Только демо-кнопки, без реального эксплойта." })
end

-- =============================================================================
-- 8) SETTINGS / Themes — colorpicker accent + animation + blur + watermark toggle
-- =============================================================================
do
    local page = settingsTab[1] -- Main
    local col = page:column({})
    local iface = col:section({ name = "Interface" })
    iface:toggle({ name = "Acrylic Blur", flag = "acrylic", default = true, callback = function(v) window:fade_background(v) end })
    iface:dropdown({
        name = "Animation Style",
        flag = "anim_style",
        items = {"tween","spring"},
        default = "tween",
        callback = function(v) library:set_animation(v) library:notify("Animation: " .. v, "info") end
    })
    iface:colorpicker({ name = "Accent", flag = "accent_pick", color = Color3.fromRGB(155,150,219), callback = function(col) library:update_theme("accent", col) window:set_accent(col) end })
    iface:slider({ name = "UI Scale (demo)", flag = "ui_scale", min = 80, max = 120, default = 100, suffix = "%" }) -- визуально не скейлит, но флаг есть
    iface:divider()
    iface:button({ name = "Test all notify types", callback = function()
        library:notify("Info — neutral", "info", "Notify")
        task.wait(0.4); library:notify("Success — green", "success", "Notify")
        task.wait(0.4); library:notify("Warn — orange", "warn", "Notify")
        task.wait(0.4); library:notify("Error — red", "error", "Notify")
    end })

    local col2 = page:column({})
    local bindsSec = col2:section({ name = "Keybinds / Lists" })
    bindsSec:toggle({ name = "Show Watermark", flag = "show_wm", default = true, callback = function(v)
        -- watermark — глобальная панель, найдём её и спрячем (демо-костыль)
        -- В реале храни ссылку: local wm = library:watermark(...)
        log("show_wm", v)
    end })
    bindsSec:toggle({ name = "Show Keybind List", flag = "show_kb", default = true })
    bindsSec:button({ name = "Unload Menu (demo)", callback = function()
        library:prompt({ title = "Unload?", text = "Скрыть весь UI? Вернуть можно вызовом window.toggle_menu(true) из консоли.", yes = function() window.toggle_menu(false) library:notify("Menu hidden — F4 to return", "warn") end })
    end })
    -- tooltip / context_menu ещё раз на кнопке
    local btn = bindsSec:button({ name = "Hover me for tooltip", callback = function() log("tooltip btn") end })
    btn:tooltip({ text = "Это тултип на кнопке. Задержка 0.3s." })

    local themePage = settingsTab[2] -- Themes
    local col3 = themePage:column({})
    local themeSec = col3:section({ name = "Presets" })
    themeSec:dropdown({ name = "Preset", flag = "preset", items = {"Milenium Dark","Midnight","Neon","Crimson","Aqua"}, default = "Milenium Dark", callback = function(v)
        local presets = {
            ["Milenium Dark"] = Color3.fromRGB(155,150,219),
            ["Midnight"] = Color3.fromRGB(90,90,255),
            ["Neon"] = Color3.fromRGB(120,255,160),
            ["Crimson"] = Color3.fromRGB(255,90,90),
            ["Aqua"] = Color3.fromRGB(90,220,255),
        }
        local col = presets[v] or presets["Milenium Dark"]
        library:update_theme("accent", col)
        library:notify("Theme: " .. v, "info")
    end })
    themeSec:colorpicker({ name = "Custom Accent", flag = "custom_accent", color = Color3.fromRGB(155,150,219), callback = function(c) library:update_theme("accent", c) end })
    themeSec:divider()
    themeSec:badge({ text = "PRO • 3.0.1", color = Color3.fromRGB(155,150,219) })
    themeSec:label({ name = "Theme auto-saves to config", info = "Смена акцента применяет tween ко всем элементам мгновенно." })
end

-- =============================================================================
-- 9) SETTINGS / Configs — init_config (обязателен один раз в конце)
-- =============================================================================
-- Создаёт внутри window отдельную систему: Config List + Textbox + Save/Load/Delete
-- + Menu Bind + Accent (дублирует, но пусть). Должно вызываться после всех flags.
library:init_config(window)

-- Доп. секция в Configs для демо get_flag/set_flag
do
    local page = settingsTab[3] -- Configs (создан init_config)
    -- init_config уже создал колонки, но мы можем добавить ещё секцию рядом через тот же tab
    -- Найдём последнюю страницу Configs и добавим секцию (демо — создаём новую колонку)
    local col = page:column({})
    local sec = col:section({ name = "Advanced Config" })
    sec:button({ name = "Print current config JSON", callback = function()
        local json = library:get_config()
        print(json)
        if setclipboard then setclipboard(json) end
        library:notify("Config copied to clipboard/log", "success")
    end })
    sec:button({ name = "Load from clipboard", callback = function()
        if getclipboard then
            local data = getclipboard()
            local ok = pcall(function() library:load_config(data) end)
            library:notify(ok and "Loaded!" or "Invalid JSON", ok and "success" or "error")
        else
            library:notify("getclipboard not supported", "warn")
        end
    end })
    sec:input({ name = "Flag Get/Set demo", flag = "flag_demo", default = library:get_flag("aim_fov") or 120, callback = function(v) log("flag_demo", v) end })
    sec:button({ name = "Set aim_fov -> 250 via set_flag", callback = function()
        library:set_flag("aim_fov", 250)
        library:notify("aim_fov = 250", "info")
    end })
    sec:divider()
    sec:label({ name = "Config path", info = "milenium/configs/<name>.cfg — JSON. Поддерживает \\ и / в путях, авто-сортировка." })
end

-- =============================================================================
-- 10) UTILITIES / Debug — лист с search, divider, progress, banner, etc.
-- =============================================================================
do
    local page = utilsTab[1] -- Debug
    local col = page:column({})
    local dbg = col:section({ name = "Debug / Tests" })
    dbg:button({ name = "Spam 5 notifs (queue cap 6 test)", callback = function()
        for i=1,5 do library:notify("Spam #" .. i .. " — queue test", (i%2==0) and "success" or "info", "Spam") task.wait(0.15) end
    end })
    dbg:slider({ name = "Debug Slider", flag = "dbg_slider", min = 0, max = 100, default = 25 })
    local prog = dbg:progress_bar({ name = "Progress Demo", value = 30, max = 100 })
    -- анимируем progress
    task.spawn(function()
        while true do
            for v=0,100,2 do prog.set(v) task.wait(0.05) end
            for v=100,0,-2 do prog.set(v) task.wait(0.05) end
        end
    end)
    dbg:divider({ height = 12 })
    dbg:banner({ text = "Divider выше — 12px. Progress ниже анимируется.", type = "info" })
    -- LIST + SEARCH (search фильтрует list)
    local sList = dbg:list({ options = {"Apple","Banana","Cherry","Date","Elderberry","Fig","Grape"}, flag = "fruit_pick", callback = function(v) log("fruit", v) end })
    dbg:search({ name = "Search fruits", placeholder = "type to filter...", target = sList })

    local about = utilsTab[2]
    local col2 = about:column({})
    local ab = col2:section({ name = "About" })
    ab:label({ name = "Milenium V3 Pro", info = "Enhanced by Arena AI • Based on Finobe • 2026-08-09 • " .. library:get_version() })
    ab:divider()
    ab:badge({ text = "MIT License", color = Color3.fromRGB(90,200,120) })
    ab:banner({ text = "Все элементы выше — реальные вызовы API. Копируй блоки в свой проект. Flags сохраняются через Configs.", type = "success" })
    ab:button({ name = "Open GitHub", callback = function() if setclipboard then setclipboard("https://github.com/Birmap2314/ui") end; library:notify("Link copied", "success") end })

    -- ANIMATION_CHANGER demo (создаёт кнопку переключения tween/spring)
    -- Правильный вызов V3: section:animation_changer()
    -- Создаст кнопку "Animation: tween" и переключит library.animation_style по клику
    local animToggle = ab:animation_changer() -- вернёт {toggle=function() ... end}
    -- Альтернативно — ручная реализация для кастома:
    local animBtnOwner = ab:button({ name = "Animation (manual): " .. library.animation_style, callback = function() end })
    -- вручную повесим логику (демо):
    animBtnOwner.MouseButton1Click:Connect(function()
        local nxt = library.animation_style == "tween" and "spring" or "tween"
        library:set_animation(nxt)
        if animBtnOwner.items then log("animation", nxt) end -- в реале текст кнопки меняется сам
        library:notify("Animation → " .. nxt, "info")
    end)
end

-- =============================================================================
-- 11) Финальные штрихи — уведомления и хелперы
-- =============================================================================
library:notify("FullExample загружен — 100% API покрыто!", "success", "milenium.pro")
task.delay(1.0, function() library:notify("ПКМ по секциям — меню • Тяни окно за шапку • Ресайз — угол", "info", "Tip") end)
task.delay(2.0, function() library:notify("Сохрани конфиг в Settings → Configs → Save", "warn", "Tip") end)

-- Пример ручного управления covenant:
-- library:set_flag("aim_enabled", true)
-- print(library:get_flag("aim_enabled"))
-- library:update_theme("accent", Color3.fromRGB(255, 120, 140))
-- window:fade_background(false) — убрать блюр
-- library:unload_menu() — полностью удалить GUI

log("FullExample ready — version", library:get_version(), "flags", library:count_flags())
-- Не забудь: library:init_config(window) уже вызван — меню бинд по умолчанию (обычно Insert)
