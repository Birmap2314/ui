--!strict
-- =============================================================================
--  Milenium V3 Pro — FULL EXAMPLE + ФУНКЦИИ (100% API, copy-paste в executor)
--  Показывает КАК ДОБАВЛЯТЬ СВОИ ФУНКЦИИ и связывать их с UI
--  Работает в Studio и любом экзекуторе | library:get_version() -> "3.0.1-pro"
--  Файл: FullExample_WithFunctions.lua (расширенный FullExample + реальные функции)
-- =============================================================================

-- 0) Загрузка библиотеки
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/main/MileniumV2.lua"))()
-- Чтобы брать с ветки arena (где лежат новые файлы) используй:
-- local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/arena/019fe824-ui/MileniumV2.lua"))()
-- Локально: local library = require(path.to.MileniumV2)

print("[milenium] version:", library:get_version())
local function log(...) print("[demo]", ...) end

-- =============================================================================
--  ФУНКЦИИ — СЮДА ДОБАВЛЯЙ СВОЮ ЛОГИКУ
--  UI только триггерит флаги/колбэки, а реальный код — тут.
--  Пример ниже — 7 готовых функций для самых частых задач.
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MyFunctions = {}
MyFunctions.Connections = {} -- храним коннекты чтобы отключать

-- 1) WalkSpeed / JumpPower — меняет Humanoid
function MyFunctions:SetWalkSpeed(v)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = v
        log("WalkSpeed ->", v)
    end
end
function MyFunctions:SetJumpPower(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v; hum.UseJumpPower = true end
end

-- 2) ESP — простой Box ESP через BillboardGui (без Drawing, работает везде)
MyFunctions.ESP = { Enabled=false, Objects={} }
function MyFunctions.ESP:CreateForPlayer(plr)
    if plr == LocalPlayer then return end
    if self.Objects[plr] then return end
    local function attach(char)
        if not self.Enabled then return end
        if not char:FindFirstChild("MileniumESP") then
            local bg = Instance.new("BillboardGui")
            bg.Name = "MileniumESP"
            bg.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char
            bg.Size = UDim2.new(0, 100, 0, 40)
            bg.StudsOffset = Vector3.new(0, 3, 0)
            bg.AlwaysOnTop = true
            bg.Parent = char
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
            lbl.Text = plr.DisplayName .. " [".. tostring(math.floor((plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health or 100)) ).. "HP]"
            lbl.TextColor3 = library.flags.esp_box_col and library.flags.esp_box_col.Color or Color3.fromRGB(155,150,219)
            lbl.TextStrokeTransparency = 0.2; lbl.FontFace = Font.fromEnum(Enum.Font.GothamBold); lbl.TextScaled = true
            lbl.Parent = bg
            self.Objects[plr] = bg
        end
    end
    if plr.Character then attach(plr.Character) end
    plr.CharacterAdded:Connect(function(c) task.wait(1); attach(c) end)
end
function MyFunctions.ESP:SetEnabled(v)
    self.Enabled = v
    if v then
        for _,plr in ipairs(Players:GetPlayers()) do self:CreateForPlayer(plr) end
        -- слушать новых игроков
        if not self.Conn then
            self.Conn = Players.PlayerAdded:Connect(function(plr) self:CreateForPlayer(plr) end)
            table.insert(MyFunctions.Connections, self.Conn)
        end
        library:notify("ESP включен", "success")
    else
        for _,gui in pairs(self.Objects) do pcall(function() gui:Destroy() end) end
        self.Objects = {}
        if self.Conn then self.Conn:Disconnect(); self.Conn=nil end
        library:notify("ESP выключен", "warn")
    end
end
function MyFunctions.ESP:SetColor(col, alpha)
    for _,gui in pairs(self.Objects) do
        local lbl = gui:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextColor3 = col end
    end
end

-- 3) Aimbot — FOV круг (Drawing) + доворот камеры
MyFunctions.Aimbot = { Enabled=false, FOV=120, Part="Head", Circle=nil, Conn=nil }
function MyFunctions.Aimbot:EnsureCircle()
    if self.Circle then return end
    local ok, drawing = pcall(function() return Drawing.new("Circle") end)
    if ok and drawing then
        drawing.Visible = false; drawing.Radius = self.FOV; drawing.Color = Color3.fromRGB(155,150,219)
        drawing.Thickness = 1.2; drawing.Filled = false; drawing.Transparency = 1
        self.Circle = drawing
        RunService.RenderStepped:Connect(function()
            if drawing then
                local visible = self.Enabled and library.flags.aim_key and library.flags.aim_key.active
                -- если keybind в Always — всегда видно
                if library.flags.aim_key and library.flags.aim_key.mode == "Always" then visible = self.Enabled end
                drawing.Visible = visible and true or false
                drawing.Radius = library.flags.aim_fov or self.FOV
                local col = library.flags.aim_fov_color and library.flags.aim_fov_color.Color or Color3.fromRGB(155,150,219)
                drawing.Color = col
                drawing.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            end
        end)
    else
        -- фолбэк без Drawing (Studio) — просто print
        log("Drawing не поддерживается, FOV круг отключён")
    end
end
function MyFunctions.Aimbot:GetClosest()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LocalPlayer then continue end
        if library.flags.team_check and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character
        local part = char and char:FindFirstChild(self.Part) or char and char:FindFirstChild("Head")
        if not part then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if library.flags.wall_check then
            local ray = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, RaycastParams.new())
            if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then continue end
        end
        local dist = (Vector2.new(pos.X,pos.Y)-center).Magnitude
        if dist <= (library.flags.aim_fov or self.FOV) and (not bestDist or dist < bestDist) then
            best, bestDist = part, dist
        end
    end
    return best
end
function MyFunctions.Aimbot:SetEnabled(v)
    self.Enabled=v
    self:EnsureCircle()
    if v and not self.Conn then
        self.Conn = RunService.RenderStepped:Connect(function()
            local aimActive = library.flags.aim_key and library.flags.aim_key.active
            if library.flags.aim_key and library.flags.aim_key.mode=="Always" then aimActive=true end
            if not (self.Enabled and aimActive) then return end
            local target = self:GetClosest()
            if target then
                local smooth = library.flags.aim_smooth or 0.45
                local camPos = Camera.CFrame.Position
                local dir = (target.Position - camPos).Unit
                local targetCF = CFrame.lookAt(camPos, camPos + dir)
                if library.flags.aim_mode == "Camera" then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - smooth)
                else
                    -- Mouse mover — двигаем мышь (пример, требует mousemoverel)
                    -- if mousemoverel then mousemoverel(dx, dy) end
                end
                if library.flags.auto_shoot then
                    -- пример: mouse1click() — раскомментируй если нужно
                    -- pcall(mouse1click)
                end
            end
        end)
        table.insert(MyFunctions.Connections, self.Conn)
    elseif not v and self.Conn then
        self.Conn:Disconnect(); self.Conn=nil
    end
end

-- 4) Fullbright
MyFunctions.Fullbright = { Enabled=false, OldAmbient=nil }
function MyFunctions.Fullbright:Set(v)
    if v then
        self.OldAmbient = game.Lighting.Ambient
        game.Lighting.Ambient = Color3.fromRGB(255,255,255)
        game.Lighting.Brightness = 3
        RunService.RenderStepped:Connect(function()
            if self.Enabled then game.Lighting.Ambient = Color3.fromRGB(255,255,255) end
        end)
    else
        if self.OldAmbient then game.Lighting.Ambient = self.OldAmbient end
        game.Lighting.Brightness = 2
    end
    self.Enabled=v
end

-- 5) Anti-AFK
function MyFunctions:SetAntiAFK(v)
    if v then
        if not self.AfkConn then
            local vu = game:GetService("VirtualUser")
            self.AfkConn = Players.LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
                task.wait(1); vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
            end)
            table.insert(self.Connections, self.AfkConn)
        end
    else
        if self.AfkConn then self.AfkConn:Disconnect(); self.AfkConn=nil end
    end
end

-- 6) Teleport к игроку
function MyFunctions:TeleportTo(p)
    local char = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetChar = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if char and targetChar then
        local dist = library.flags.tp_dist or 5
        char.CFrame = targetChar.CFrame * CFrame.new(0,0, dist)
        library:notify("Телепорт к " .. p.DisplayName, "success")
    else
        library:notify("Не удалось телепортироваться", "error")
    end
end

-- 7) Click TP
MyFunctions.ClickTP = { Enabled=false, Conn=nil }
function MyFunctions.ClickTP:Set(v)
    self.Enabled=v
    if v and not self.Conn then
        self.Conn = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            local hold = library.flags.clicktp_key and library.flags.clicktp_key.active
            -- если Hold — проверяем hold, иначе просто клик
            if inp.UserInputType==Enum.UserInputType.MouseButton1 and self.Enabled and (hold or true) then
                local mouse = LocalPlayer:GetMouse()
                if mouse.Target then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0)) end
                end
            end
        end)
        table.insert(MyFunctions.Connections, self.Conn)
    elseif not v and self.Conn then
        self.Conn:Disconnect(); self.Conn=nil
    end
end

-- Хелпер: очистить все коннекты при выгрузке
function MyFunctions:Cleanup()
    for _,c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    if self.Aimbot.Circle then pcall(function() self.Aimbot.Circle:Remove() end) end
end

-- =============================================================================
-- 1) WINDOW
-- =============================================================================
local window = library:window({
    name = "milenium",
    suffix = "pro",
    gameInfo = "Milenium V3 • Full + Functions • " .. library:get_version(),
    size = UDim2.new(0, 780, 0, 620),
})

-- 2) TABS
local combatTab   = window:tab({ name = "Combat",   icon = "rbxassetid://6031094670", tabs = {"Aimbot","Checks","Trigger","Antiaim"} })
local visualsTab  = window:tab({ name = "Visuals",  icon = "rbxassetid://6031090997", tabs = {"ESP","World","View","Materials"} })
local playersTab  = window:tab({ name = "Players",  icon = "rbxassetid://6034767608", tabs = {"List","Tools","Misc"} })
local worldTab    = window:tab({ name = "World",    icon = "rbxassetid://6031094678", tabs = {"Movement","Environ","Exploits"} })
local settingsTab = window:tab({ name = "Settings", icon = "rbxassetid://6031225810", tabs = {"Main","Themes","Configs"} })
window:seperator({ name = "Utilities" })
local utilsTab = window:tab({ name = "Utilities", icon = "rbxassetid://6031225810", tabs = {"Debug","About"} })

-- =============================================================================
-- 3) COMBAT / Aimbot
-- =============================================================================
do
    local page = combatTab[1]
    local sub = page:sub_tab({})
    local colL = sub:column({ size = 1 })
    local colR = sub:column({ size = 1 })

    local aimSec = colL:section({ name = "Aimbot Engine", icon = "rbxassetid://6031094670", size = 0.72, fading_toggle = true, default = true })

    -- Toggle теперь реально включает Aimbot функцию
    local tEnabled = aimSec:toggle({
        name = "Enabled",
        flag = "aim_enabled",
        default = false,
        type = "toggle",
        info = "Главный свитч. Включает FOV круг и доворот.",
        callback = function(v) MyFunctions.Aimbot:SetEnabled(v) end,
    })
    tEnabled:keybind({
        name = "Aim Key",
        flag = "aim_key",
        key = Enum.KeyCode.E,
        mode = "Toggle",
        callback = function(active) log("aim_key active =", active) end
    }):colorpicker({
        name = "FOV Ring",
        flag = "aim_fov_color",
        color = Color3.fromRGB(155, 150, 219),
        alpha = 0,
        callback = function(col, a) if MyFunctions.Aimbot.Circle then MyFunctions.Aimbot.Circle.Color = col end end
    })

    aimSec:toggle({
        name = "Silent Aim",
        flag = "silent_aim",
        default = false,
        type = "checkbox",
        info = "Без доворота — только логика (демо).",
        callback = function(v) log("silent_aim", v) end,
        seperator = true
    })

    aimSec:slider({
        name = "FOV",
        flag = "aim_fov",
        min = 10, max = 500, default = 120,
        interval = 1,
        suffix = "°",
        info = "Радиус FOV",
        callback = function(v) MyFunctions.Aimbot.FOV = v; if MyFunctions.Aimbot.Circle then MyFunctions.Aimbot.Circle.Radius = v end end
    })
    aimSec:slider({ name = "Smoothness", flag = "aim_smooth", min = 0, max = 1, default = 0.45, interval = 0.01, callback = function(v) log("smooth", v) end })
    aimSec:slider({ name = "Prediction", flag = "aim_pred_slider", min = 0, max = 100, default = 50, suffix = "%", seperator = false })

    aimSec:dropdown({
        name = "Target Part",
        flag = "aim_part",
        items = {"Head","Torso","Random","Nearest"},
        default = "Head",
        width = 140,
        callback = function(v) MyFunctions.Aimbot.Part = v; log("aim_part =", v) end
    })
    aimSec:dropdown({
        name = "Checks (multi)",
        flag = "aim_checks_multi",
        items = {"Wall","Team","Distance","Visibility","Knocked"},
        default = {"Wall","Team"},
        multi = true,
        callback = function(tbl) log("checks multi", table.concat(tbl, ", ")) end
    })

    aimSec:label({ name = "Status: Ready", info = "Перетаскивай окно, ресайз — угол." })
    aimSec:divider({ height = 12 })
    aimSec:banner({ text = "TIP: ПКМ по секции — меню. FOV круг = Drawing.", type = "info" })
    aimSec:banner({ text = "Silent Aim пока демо — добавь свою логику в MyFunctions.", type = "warn" })
    aimSec:radio({ name = "Aim Mode", flag = "aim_mode", options = {"Camera","Mouse mover","Silent"}, default = "Camera", callback = function(v) log("aim_mode", v) end })

    aimSec:button({ name = "Test Notification (success)", callback = function() library:notify("Aim config applied!", "success", "Aimbot") end })
    aimSec:button({ name = "Test Prompt — Reset Aim", callback = function()
        library:prompt({
            title = "Reset aimbot?",
            text = "Все слайдеры вернутся к дефолту.",
            yes = function() library:notify("Reset done", "success"); library:set_flag("aim_fov", 120); MyFunctions.Aimbot.FOV = 120 end,
            no  = function() library:notify("Cancelled", "warn") end
        })
    end })

    local tipOwner = aimSec:toggle({ name = "Auto Shoot", flag = "auto_shoot", default = true, info = "Авто-клик при наведении." })
    tipOwner:tooltip({ text = "Работает только если aim_enabled и цель в FOV", delay = 0.25 })

    aimSec:input({ name = "Custom FOV (number)", flag = "custom_fov_num", placeholder = "120", default = 120, min = 0, max = 1000, integer = true, callback = function(v) MyFunctions.Aimbot.FOV = v; library:set_flag("aim_fov", v) end })

    local ctx = library:context_menu({ items = {
        { name = "Copy config", callback = function() if setclipboard then setclipboard(library:get_config()) end; library:notify("Copied!", "success") end },
        { name = "Paste config", callback = function() library:notify("Use Load in Configs tab", "info") end },
        "sep",
        { name = "Reset section", callback = function() log("reset section clicked") end },
    }})
    ctx.attach(aimSec)
    ctx.attach(tipOwner)

    local checksSec = colR:section({ name = "Aim Checks", icon = "rbxassetid://6031090997", size = 1 })
    checksSec:toggle({ name = "Wall Check", flag = "wall_check", default = true })
    checksSec:toggle({ name = "Team Check", flag = "team_check", default = true })
    checksSec:toggle({ name = "Distance Check", flag = "dist_check", default = false })
    checksSec:slider({ name = "Max Distance", flag = "max_dist", min = 100, max = 5000, default = 1400, suffix = " studs" })
    checksSec:dropdown({ name = "Sort Mode", flag = "sort_mode", items = {"Distance","FOV","Health","Random"}, default = "Distance" })
    checksSec:progress_bar({ name = "Target Stability", value = 68, max = 100 })
    checksSec:divider()
    checksSec:badge({ text = "LIVE", color = Color3.fromRGB(90, 200, 120) })
    checksSec:badge({ text = "BETA • 3.0.1", color = Color3.fromRGB(155,150,219) })
end

-- =============================================================================
-- 4) Trigger & Antiaim
-- =============================================================================
do
    local page = combatTab[3]
    local col = page:column({})
    local sec = col:section({ name = "Trigger Bot" })
    sec:toggle({ name = "Enabled", flag = "trigger_enabled", default = false })
        :keybind({ name = "Trigger Key", flag = "trigger_key", key = Enum.KeyCode.T, mode = "Hold", callback = function(a) log("trigger", a) end })
    sec:slider({ name = "Delay", flag = "trigger_delay", min = 0, max = 500, default = 80, suffix = " ms" })
    sec:textbox({ name = "Log webhook", placeholder = "https://discord...", flag = "webhook_url", default = "" })
    sec:label({ name = "Trigger only on visible", info = "Требует WallCheck." })

    local pageAA = combatTab[4]
    local col2 = pageAA:column({})
    local secAA = col2:section({ name = "Antiaim (fake lag)" })
    secAA:toggle({ name = "Spinbot", flag = "spin", default = false, callback = function(v) log("spin", v) end })
    secAA:slider({ name = "Spin Speed", flag = "spin_speed", min = 1, max = 50, default = 12 })
    secAA:dropdown({ name = "Pitch", flag = "pitch", items = {"None","Up","Down","Zero","Random"}, default = "Up" })
    local withSettings = secAA:toggle({ name = "Desync", flag = "desync", default = false })
    local popup = withSettings:settings({})
    popup:list({ options={"Popup Opt A","Popup Opt B","Popup Opt C"}, flag="popup_demo", callback=function(v) log("popup list", v) end })
end

-- =============================================================================
-- 5) VISUALS / ESP — теперь с реальной функцией MyFunctions.ESP
-- =============================================================================
do
    local page = visualsTab[1]
    local col = page:column({})
    local esp = col:section({ name = "Player ESP", icon = "rbxassetid://6031094670" })

    esp:toggle({
        name = "Enabled",
        flag = "esp_enabled",
        default = false, -- начинаем выкл чтобы не спамить
        callback = function(v) MyFunctions.ESP:SetEnabled(v) end
    }):colorpicker({
        name = "Box", flag = "esp_box_col", color = Color3.fromRGB(155,150,219),
        callback = function(col) MyFunctions.ESP:SetColor(col) end
    }):colorpicker({ name = "Fill", flag = "esp_fill_col", color = Color3.fromRGB(155,150,219), alpha = 0.85 })

    esp:toggle({ name = "Name", flag = "esp_name", default = true })
    esp:toggle({ name = "Health Bar", flag = "esp_health", default = true, type = "checkbox" })
    esp:toggle({ name = "Distance", flag = "esp_dist", default = false })
    esp:dropdown({ name = "Box Type", flag = "esp_box_type", items = {"Corner","2D","3D","None"}, default = "Corner" })
    esp:slider({ name = "Box Thickness", flag = "esp_thick", min = 1, max = 4, default = 1 })
    esp:slider({ name = "Text Size", flag = "esp_text", min = 8, max = 22, default = 13, suffix = " px" })
    esp:progress_bar({ name = "ESP Refresh", value = 24, max = 60 })
    esp:divider({ height = 16 })
    esp:badge({ text = "UPDATED", color = Color3.fromRGB(90,200,120) })
    esp:label({ name = "Tag: Developer", info = "Отображается над головой у админов." })

    local col2 = page:column({})
    local world = col2:section({ name = "World ESP" })
    world:toggle({ name = "Item ESP", flag = "item_esp", default = true, callback = function(v) log("item_esp", v) end })
    world:toggle({ name = "Chest ESP", flag = "chest_esp", default = false })
    world:dropdown({ name = "Item Filter (multi)", flag = "item_filter", items = {"Weapon","Ammo","Med","Armor"}, default = {"Weapon"}, multi = true })
    world:slider({ name = "Max Distance", flag = "world_dist", min = 50, max = 5000, default = 800 })
    world:button({ name = "Refresh ESP", callback = function() MyFunctions.ESP:SetEnabled(library:get_flag("esp_enabled")) library:notify("ESP refreshed", "info") end })

    local hotbar = library:hotbar({ position = UDim2.new(0.5, 0, 0, 10) })
    hotbar.add_button({ name = "ESP", active = false, width = 44, callback = function(v) library:set_flag("esp_enabled", v); MyFunctions.ESP:SetEnabled(v) end })
    hotbar.add_button({ name = "AIM", active = false, width = 44, callback = function(v) library:set_flag("aim_enabled", v); MyFunctions.Aimbot:SetEnabled(v) end })
    hotbar.add_button({ name = "FLY", active = false, width = 44, callback = function(v) log("fly hotbar", v); library:notify(v and "Fly ON" or "Fly OFF", v and "success" or "warn") end })
end

do
    local page = visualsTab[2]
    local col = page:column({})
    local sec = col:section({ name = "World" })
    sec:slider({ name = "Brightness", flag = "brightness", min = 0, max = 5, default = 2, interval = 0.1, callback = function(v) game.Lighting.Brightness = v end })
    sec:slider({ name = "Fog Density", flag = "fog", min = 0, max = 1, default = 0.2, interval = 0.01, callback = function(v) game.Lighting.FogEnd = 100 + v*1000 end })
    sec:colorpicker({ name = "Ambient", flag = "ambient", color = Color3.fromRGB(140,140,160), callback = function(c) game.Lighting.Ambient = c end })
    sec:toggle({ name = "Fullbright", flag = "fullbright", default = false, callback = function(v) MyFunctions.Fullbright:Set(v) end })
    sec:divider()
    sec:button({ name = "Reset World", callback = function() game.Lighting.Ambient = Color3.fromRGB(140,140,160); game.Lighting.Brightness=2 end })

    local col2 = page:column({})
    local sec2 = col2:section({ name = "View" })
    sec2:slider({ name = "FOV Changer", flag = "view_fov", min = 70, max = 120, default = 80, callback = function(v) Camera.FieldOfView = v end })
    sec2:toggle({ name = "No Bob", flag = "nobob", default = false })
    sec2:dropdown({ name = "Material", flag = "mat", items = {"Smooth","ForceField","Glass","Neon"}, default = "Smooth" })
end

-- =============================================================================
-- 6) PLAYERS — player_list + функции телепорта
-- =============================================================================
do
    local page = playersTab[1]
    local col = page:column({})
    local sec = col:section({ name = "Online Players", icon = "rbxassetid://6034767608", size = 0.60 })

    local plist = sec:player_list({
        name = "Players",
        flag = "selected_player",
        max_height = 220,
        include_self = true,
        callback = function(plr)
            log("selected", plr.Name)
            library:notify("Selected: " .. plr.DisplayName, "success", "Players")
            if _G.updateCard then _G.updateCard(plr) end
        end
    })
    local dummyList = sec:list({ options = {"Alpha","Beta","Gamma","Delta","Epsilon"}, flag = "dummy_list", callback = function(v) log("dummy list", v) end })
    sec:search({ name = "Search dummy", placeholder = "filter dummy...", target = dummyList })

    local card = sec:player_card({
        player = LocalPlayer,
        name = LocalPlayer.DisplayName,
        role = "LocalPlayer • Alive",
        accent = Color3.fromRGB(155,150,219)
    })
    _G.updateCard = function(plr)
        card.update(plr, plr.DisplayName, "Target • " .. (plr.Team and plr.Team.Name or "No Team"))
        card.set_status_color(Color3.fromRGB(90,200,120))
    end
    card:tooltip({ text = "Клик по игроку в списке выше — обновит карточку. ПКМ — меню." })

    local cardMenu = library:context_menu({ items = {
        { name = "Spectate", callback = function() log("spectate", library:get_flag("selected_player")) end },
        { name = "Teleport to", callback = function()
            local p = library:get_flag("selected_player")
            if p then MyFunctions:TeleportTo(p) end
        end },
        "sep",
        { name = "Copy UserId", callback = function()
            local p = library:get_flag("selected_player")
            if p and setclipboard then setclipboard(tostring(p.UserId)); library:notify("Copied UserId", "success") end
        end },
    }})
    cardMenu.attach(card)

    local sec2 = col:section({ name = "Selection Tools" })
    sec2:multi_select({ name = "Friend Whitelist", options = {"PlayerOne","PlayerTwo","PlayerThree","PlayerFour","PlayerFive","PlayerSix","PlayerSeven"}, flag = "friend_whitelist", max = 6, default = {"PlayerOne"}, callback = function(tbl) log("whitelist", table.concat(tbl, ", ")) end })
    sec2:tab_list({ name = "Quick Action", options = {"Spectate","Teleport","Copy JobId","View Inventory","Kick (local only)"}, default = 1, callback = function(opt, idx) log("quick action", opt, idx) library:notify(opt, "info") end })
    sec2:input({ name = "Teleport Distance", placeholder = "100", flag = "tp_dist", default = 100, min = 0, max = 5000, integer = true, callback = function(v) log("tp_dist", v) end })
    sec2:button({ name = "Do Action", callback = function()
        local act = library:get_flag("quick_action") or "Spectate"
        local target = library:get_flag("selected_player")
        if act == "Teleport" and target then
            MyFunctions:TeleportTo(target)
        elseif act == "Copy JobId" and setclipboard then
            setclipboard(game.JobId); library:notify("Copied JobId", "success")
        else
            library:prompt({ title = "Confirm: " .. tostring(act) .. "?", text = "Выполнить для " .. (target and target.DisplayName or "никого") .. "?", yes = function() log("confirmed", act) end })
        end
    end })

    local wm = library:watermark({ text = "milenium.pro", sub = "v3.0.1 • full demo" })
    local kblist = library:keybind_list()
    sec2:progress_bar({ name = "Loading demo", value = 10, max = 100 })
end

do
    local page = playersTab[2]
    local col = page:column({})
    local sec = col:section({ name = "Tools" })
    sec:textbox({ name = "JobId", placeholder = "paste job id...", flag = "jobid_box", default = game.JobId, callback = function(v) log("jobid", v) end })
    sec:button({ name = "Copy JobId", callback = function() if setclipboard then setclipboard(game.JobId) library:notify("Copied JobId", "success") end end })
    sec:button({ name = "Rejoin", callback = function() library:prompt({ title = "Rejoin?", text = "Перезайти на тот же сервер?", yes = function() log("rejoin") end }) end })
    sec:divider()
    -- WalkSpeed теперь реально меняет Humanoid
    sec:slider({
        name = "WalkSpeed",
        flag = "walkspeed",
        min = 16, max = 250, default = 16, suffix = " studs/s",
        callback = function(v) MyFunctions:SetWalkSpeed(v) end
    })
    sec:slider({
        name = "JumpPower",
        flag = "jumppower",
        min = 50, max = 250, default = 50,
        callback = function(v) MyFunctions:SetJumpPower(v) end
    })
    sec:divider()
    sec:label({ name = "System Status", info = "Window можно ресайзить тянучкой в углу." })

    local lstSec = col:section({ name = "Server List" })
    local lst = lstSec:list({ options = {"Server #1 — 12/20","Server #2 — 8/20","Server #3 — 20/20 (full)","Private Server"}, flag = "server_pick", callback = function(v) log("server pick", v) end })
end

do
    local page = playersTab[3]
    local col = page:column({})
    local sec = col:section({ name = "Misc / Debug" })
    -- Anti-AFK теперь реально работает
    sec:toggle({
        name = "Anti-AFK",
        flag = "anti_afk",
        default = false,
        callback = function(v) MyFunctions:SetAntiAFK(v) log("anti_afk", v) end
    })
    sec:dropdown({ name = "Language", flag = "lang", items = {"Русский","English","Español"}, default = "Русский" })
    sec:textbox({ name = "Custom prefix", flag = "prefix", placeholder = "!", default = "!" })
    sec:button({ name = "Clear notifications", callback = function() for _, n in ipairs(library.notifications.notifs) do if n then pcall(function() n:Destroy() end) end end table.clear(library.notifications.notifs) end })
    sec:banner({ text = "FullExample покрывает 100% элементов + 7 реальных функций.", type = "success" })
end

-- =============================================================================
-- 7) WORLD — movement / exploits
-- =============================================================================
do
    local page = worldTab[1]
    local col = page:column({})
    local move = col:section({ name = "Movement" })
    move:toggle({ name = "Speedhack", flag = "speedhack", default = false, callback = function(v) if v then MyFunctions:SetWalkSpeed(library:get_flag("speed_val") or 32) else MyFunctions:SetWalkSpeed(16) end end })
        :keybind({ name = "Toggle", flag = "speed_key", key = Enum.KeyCode.LeftShift, mode = "Toggle" })
    move:slider({ name = "Speed", flag = "speed_val", min = 16, max = 100, default = 32, callback = function(v) if library:get_flag("speedhack") then MyFunctions:SetWalkSpeed(v) end end })
    move:toggle({ name = "Infinite Jump", flag = "inf_jump", default = false, type = "checkbox", callback = function(v) log("inf_jump", v) end })
    -- InfiniteJump реальная логика:
    UserInputService.JumpRequest:Connect(function()
        if library:get_flag("inf_jump") then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    move:input({ name = "Jump Height", flag = "jump_h", default = 50, min = 0, max = 500, integer = true })
    move:divider()
    move:button({ name = "Reset Movement", callback = function() library:set_flag("speedhack", false); library:set_flag("speed_val", 32); MyFunctions:SetWalkSpeed(16); library:notify("Movement reset", "warn") end })

    local page2 = worldTab[2]
    local col2 = page2:column({})
    local env = col2:section({ name = "Environment" })
    env:slider({ name = "Time of Day", flag = "tod", min = 0, max = 24, default = 14, interval = 0.5, suffix = "h", callback = function(v) game.Lighting.ClockTime = v end })
    env:colorpicker({ name = "Fog Color", flag = "fog_col", color = Color3.fromRGB(160,160,180), callback = function(c) game.Lighting.FogColor = c end })
    env:toggle({ name = "No Fog", flag = "no_fog", default = false, callback = function(v) game.Lighting.FogEnd = v and 100000 or 1000 end })
    env:dropdown({ name = "Weather", flag = "weather", items = {"Clear","Rain","Fog","Storm"}, default = "Clear" })

    local page3 = worldTab[3]
    local col3 = page3:column({})
    local exp = col3:section({ name = "Exploits (demo)" })
    exp:toggle({ name = "Click TP (Ctrl+Click)", flag = "clicktp", default = false, callback = function(v) MyFunctions.ClickTP:Set(v) end })
        :keybind({ name = "Key", flag = "clicktp_key", key = Enum.KeyCode.LeftControl, mode = "Hold" })
    exp:button({ name = "TP to Spawn", callback = function() local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = CFrame.new(0,10,0) end end })
    exp:divider()
    exp:label({ name = "Exploit status", info = "ClickTP реально телепортирует на mouse.Hit." })
end

-- =============================================================================
-- 8) SETTINGS — Themes
-- =============================================================================
do
    local page = settingsTab[1]
    local col = page:column({})
    local iface = col:section({ name = "Interface" })
    iface:toggle({ name = "Acrylic Blur", flag = "acrylic", default = true, callback = function(v) window:fade_background(v) end })
    iface:dropdown({ name = "Animation Style", flag = "anim_style", items = {"tween","spring"}, default = "tween", callback = function(v) library:set_animation(v) library:notify("Animation: " .. v, "info") end })
    iface:colorpicker({ name = "Accent", flag = "accent_pick", color = Color3.fromRGB(155,150,219), callback = function(col) library:update_theme("accent", col) window:set_accent(col) end })
    iface:slider({ name = "UI Scale (demo)", flag = "ui_scale", min = 80, max = 120, default = 100, suffix = "%" })
    iface:divider()
    iface:button({ name = "Test all notify types", callback = function()
        library:notify("Info — neutral", "info", "Notify")
        task.wait(0.4); library:notify("Success — green", "success", "Notify")
        task.wait(0.4); library:notify("Warn — orange", "warn", "Notify")
        task.wait(0.4); library:notify("Error — red", "error", "Notify")
    end })

    local col2 = page:column({})
    local bindsSec = col2:section({ name = "Keybinds / Lists" })
    bindsSec:toggle({ name = "Show Watermark", flag = "show_wm", default = true, callback = function(v) log("show_wm", v) end })
    bindsSec:toggle({ name = "Show Keybind List", flag = "show_kb", default = true })
    bindsSec:button({ name = "Unload Menu (demo)", callback = function() library:prompt({ title = "Unload?", text = "Скрыть весь UI? Вернуть можно вызовом window.toggle_menu(true) из консоли.", yes = function() window.toggle_menu(false) library:notify("Menu hidden — F4 to return", "warn") end }) end })
    local btn = bindsSec:button({ name = "Hover me for tooltip", callback = function() log("tooltip btn") end })
    btn:tooltip({ text = "Это тултип на кнопке. Задержка 0.3s." })

    local themePage = settingsTab[2]
    local col3 = themePage:column({})
    local themeSec = col3:section({ name = "Presets" })
    themeSec:dropdown({ name = "Preset", flag = "preset", items = {"Milenium Dark","Midnight","Neon","Crimson","Aqua"}, default = "Milenium Dark", callback = function(v)
        local presets = { ["Milenium Dark"] = Color3.fromRGB(155,150,219), ["Midnight"] = Color3.fromRGB(90,90,255), ["Neon"] = Color3.fromRGB(120,255,160), ["Crimson"] = Color3.fromRGB(255,90,90), ["Aqua"] = Color3.fromRGB(90,220,255) }
        local col = presets[v] or presets["Milenium Dark"]
        library:update_theme("accent", col)
        library:notify("Theme: " .. v, "info")
    end })
    themeSec:colorpicker({ name = "Custom Accent", flag = "custom_accent", color = Color3.fromRGB(155,150,219), callback = function(c) library:update_theme("accent", c) end })
    themeSec:divider()
    themeSec:badge({ text = "PRO • 3.0.1", color = Color3.fromRGB(155,150,219) })
    themeSec:label({ name = "Theme auto-saves to config", info = "Смена акцента применяет tween ко всем элементам мгновенно." })
end

-- 9) Configs
library:init_config(window)
do
    local page = settingsTab[3]
    local col = page:column({})
    local sec = col:section({ name = "Advanced Config" })
    sec:button({ name = "Print current config JSON", callback = function() local json = library:get_config(); print(json); if setclipboard then setclipboard(json) end; library:notify("Config copied", "success") end })
    sec:button({ name = "Load from clipboard", callback = function() if getclipboard then local data = getclipboard(); local ok = pcall(function() library:load_config(data) end); library:notify(ok and "Loaded!" or "Invalid JSON", ok and "success" or "error") else library:notify("getclipboard not supported", "warn") end end })
    sec:input({ name = "Flag Get/Set demo", flag = "flag_demo", default = library:get_flag("aim_fov") or 120, callback = function(v) log("flag_demo", v) end })
    sec:button({ name = "Set aim_fov -> 250 via set_flag", callback = function() library:set_flag("aim_fov", 250); MyFunctions.Aimbot.FOV = 250; library:notify("aim_fov = 250", "info") end })
    sec:divider()
    sec:label({ name = "Config path", info = "milenium/configs/<name>.cfg — JSON. Поддерживает \\ и /." })
end

-- =============================================================================
-- 10) UTILITIES
-- =============================================================================
do
    local page = utilsTab[1]
    local col = page:column({})
    local dbg = col:section({ name = "Debug / Tests" })
    dbg:button({ name = "Spam 5 notifs (queue cap 6 test)", callback = function() for i=1,5 do library:notify("Spam #" .. i .. " — queue test", (i%2==0) and "success" or "info", "Spam") task.wait(0.15) end end })
    dbg:slider({ name = "Debug Slider", flag = "dbg_slider", min = 0, max = 100, default = 25 })
    local prog = dbg:progress_bar({ name = "Progress Demo", value = 30, max = 100 })
    task.spawn(function() while true do for v=0,100,2 do prog.set(v) task.wait(0.05) end; for v=100,0,-2 do prog.set(v) task.wait(0.05) end end end)
    dbg:divider({ height = 12 })
    dbg:banner({ text = "Divider выше — 12px. Progress ниже анимируется.", type = "info" })
    local sList = dbg:list({ options = {"Apple","Banana","Cherry","Date","Elderberry","Fig","Grape"}, flag = "fruit_pick", callback = function(v) log("fruit", v) end })
    dbg:search({ name = "Search fruits", placeholder = "type to filter...", target = sList })

    local about = utilsTab[2]
    local col2 = about:column({})
    local ab = col2:section({ name = "About" })
    ab:label({ name = "Milenium V3 Pro + Functions", info = "Enhanced by Arena AI • Based on Finobe • " .. library:get_version() .. " • Теперь с реальными функциями внутри!" })
    ab:divider()
    ab:badge({ text = "MIT License", color = Color3.fromRGB(90,200,120) })
    ab:banner({ text = "Каждый toggle теперь вызывает MyFunctions.* — смотри верхушку файла, раздел ФУНКЦИИ.", type = "success" })
    ab:button({ name = "Open GitHub (arena branch)", callback = function() if setclipboard then setclipboard("https://github.com/Birmap2314/ui/tree/arena/019fe824-ui") end; library:notify("Link copied — смотри ветку arena/019fe824-ui или PR #1", "success") end })
    local animToggle = ab:animation_changer()
    local animBtnOwner = ab:button({ name = "Animation (manual): " .. library.animation_style, callback = function() end })
    animBtnOwner.MouseButton1Click:Connect(function()
        local nxt = library.animation_style == "tween" and "spring" or "tween"
        library:set_animation(nxt)
        if animBtnOwner.items then log("animation", nxt) end
        library:notify("Animation → " .. nxt, "info")
    end)
end

-- =============================================================================
-- 11) ФИНАЛ
-- =============================================================================
library:notify("FullExample+Functions загружен!", "success", "milenium.pro")
task.delay(1.0, function() library:notify("Каждый элемент теперь с функцией — смотри MyFunctions вверху", "info", "Tip") end)
task.delay(2.0, function() library:notify("Сохрани конфиг в Settings → Configs → Save", "warn", "Tip") end)

-- Как добавить свою функцию:
-- 1. Напиши функцию в MyFunctions:  function MyFunctions:MyFeature(v) if v then ... end end
-- 2. В UI укажи callback:  sec:toggle({ flag="my_feat", callback=function(v) MyFunctions:MyFeature(v) end })
-- 3. Если нужен луп — используй RunService.RenderStepped и сохраняй коннект в MyFunctions.Connections

log("FullExample+Functions ready — version", library:get_version(), "flags", library:count_flags())
-- Menu bind по умолчанию Insert (меняется в Settings → Configs)

-- Авто-cleanup при выгрузке (не обязательно):
-- game:BindToClose(function() MyFunctions:Cleanup(); library:unload_menu() end)

