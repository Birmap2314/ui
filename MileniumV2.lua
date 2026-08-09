--[[
    Milenium Library V3 — Enhanced Pro  (drop-in compatible with V2)
    -> Originally by @finobe  |  V2 enhancements by Arena AI Agent  |  V3 Pro refactor 2026-08-09
    -> Single-file, no dependencies, exploit-agnostic, Studio-safe

    ── QUICK START ─────────────────────────────────────────────────────────────
        local lib = loadstring(game:HttpGet("...MileniumV2.lua"))()
        -- or local lib = require(path)
        local win = lib:window({name="milenium", suffix="pro", gameInfo="My Game"})
        local tab = win:tab({name="Main", tabs={"Combat","Visuals","Settings"}})
        local sec = tab[1]:column({}):section({name="Aimbot", icon="rbxassetid://..."})
        sec:toggle({name="Enabled", flag="aim_enabled", default=false, callback=function(v) print(v) end})
           :colorpicker({name="Color", flag="aim_color", color=Color3.fromRGB(155,150,219)})
           :keybind({name="Key", flag="aim_key", key=Enum.KeyCode.E, mode="Toggle"})
        sec:slider({name="FOV", flag="aim_fov", min=0, max=500, default=120, suffix="°"})
        sec:dropdown({name="Target Part", flag="aim_part", options={"Head","Torso","Random"}, default="Head"})
        sec:button({name="Apply", callback=function() lib.notifications:create_notification({name="Done", info="Applied!"}) end})

    ── NEW / FIXED IN V3 ─────────────────────────────────────────────────────
        FIXES (no breaking changes):
        • library:tween now returns Tween correctly (was returning nil after :Play())
        • library:update_theme / apply_theme fixed
        • library:create now uses pairs safely
        • get_config / load_config flag iteration fixed
        • update_config_list handles both \\ and / + missing folder
        • resizify clamped to min size + viewport, draggify clamped correctly
        • notifications:fade fixed, queue capped at 6
        • slider fill math fixed, dropdown positioning fixed
        • colorpicker drag math fixed + hex input
        • keybind handles MB4/MB5 correctly
        • window parent gethui() fallback + DisplayOrder + safe pcall
        • font loader pcall+fallback to Gotham
        • makefolder/isfile wrapped for Studio

        VISUAL POLISH:
        • acrylic blur option, consistent 7-8px radius, softer shadows
        • focused inputs glow accent, notification types with colored bar
        • slider value pills, dropdown search, section toggle spring

        NEW API (all optional, backward compatible):
        • library:tooltip(options)        -- hover tooltip
        • library:context_menu(options)   -- right-click menu
        • library:banner(options)         -- inline alert banner
        • library:radio(options)          -- single-choice radio
        • library:notify(text,type)       -- shorthand
        • library:prompt(options)         -- confirm dialog
        • library:get_flag / set_flag
        • window:fade_background(bool)
        • library:animation_changer()

        COMPAT: Synapse X / KRNL / Fluxus / Electron / Delta / Solara / Studio
]]

-- Variables
    local uis = game:GetService("UserInputService")
    local players = game:GetService("Players")
    local ws = game:GetService("Workspace")
    local rs = game:GetService("ReplicatedStorage")
    local http_service = game:GetService("HttpService")
    local gui_service = game:GetService("GuiService")
    local lighting = game:GetService("Lighting")
    local run = game:GetService("RunService")
    local stats = game:GetService("Stats")
    local coregui = game:GetService("CoreGui")
    local debris = game:GetService("Debris")
    local tween_service = game:GetService("TweenService")
    local sound_service = game:GetService("SoundService")

    local vec2 = Vector2.new
    local vec3 = Vector3.new
    local dim2 = UDim2.new
    local dim = UDim.new
    local rect = Rect.new
    local cfr = CFrame.new
    local empty_cfr = cfr()
    local point_object_space = empty_cfr.PointToObjectSpace
    local angle = CFrame.Angles
    local dim_offset = UDim2.fromOffset

    local color = Color3.new
    local rgb = Color3.fromRGB
    local hex = Color3.fromHex
    local hsv = Color3.fromHSV
    local rgbseq = ColorSequence.new
    local rgbkey = ColorSequenceKeypoint.new
    local numseq = NumberSequence.new
    local numkey = NumberSequenceKeypoint.new

    local camera = ws.CurrentCamera
    local lp = players.LocalPlayer
    local mouse = lp:GetMouse()
    local gui_offset = gui_service:GetGuiInset().Y

    local max = math.max
    local floor = math.floor
    local min = math.min
    local abs = math.abs
    local noise = math.noise
    local rad = math.rad
    local random = math.random
    local pow = math.pow
    local sin = math.sin
    local pi = math.pi
    local tan = math.tan
    local atan2 = math.atan2
    local clamp = math.clamp

    local insert = table.insert
    local find = table.find
    local remove = table.remove
    local concat = table.concat
--


-- Safe executor abstraction (Studio & missing functions fallback)
    local function safe_call(fn, ...) if fn then local ok, r = pcall(fn, ...) if ok then return r end end return nil end
    if not getgenv then getgenv = function() return _G end end
    if not makefolder then makefolder = function() end end
    if not isfile then isfile = function() return false end end
    if not isfolder then isfolder = function() return false end end
    if not listfiles then listfiles = function() return {} end end
    if not writefile then writefile = function() end end
    if not readfile then readfile = function() return "" end end
    if not delfile then delfile = function() end end
    if not getcustomasset then getcustomasset = function(p) return p end end
    local function gethui_safe()
        local ok, hui = pcall(function() return gethui and gethui() end)
        if ok and hui then return hui end
        ok, hui = pcall(function() return get_hidden_gui and get_hidden_gui() end)
        if ok and hui then return hui end
        if syn and syn.protect_gui then local g = Instance.new("ScreenGui") pcall(syn.protect_gui, syn, g) return g.Parent end
        return coregui
    end
    local function headshot_url(uid) return string.format("rbxassetid://%d", 0) end
    local function get_headshot(uid) return string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", uid) end
    local TWEEN_DEFAULT = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
--
-- Library init
    getgenv().library = {
        directory = "milenium",
        folders = {
            "/fonts",
            "/configs",
        },
        flags = {},
        config_flags = {},
        connections = {},
        notifications = {notifs = {}},
        current_open;
        cache = nil,
        animation_style = "tween", -- "tween" or "spring"
    }

    local themes = {
        preset = {
            accent = rgb(155, 150, 219),
        },

        utility = {
            accent = {
                BackgroundColor3 = {},
                TextColor3 = {},
                ImageColor3 = {},
                ScrollBarImageColor3 = {}
            },
        }
    }

    local keys = {
        [Enum.KeyCode.LeftShift] = "LS",
        [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC",
        [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.Insert] = "INS",
        [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Return] = "Ent",
        [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA",
        [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.KeyCode.One] = "1",
        [Enum.KeyCode.Two] = "2",
        [Enum.KeyCode.Three] = "3",
        [Enum.KeyCode.Four] = "4",
        [Enum.KeyCode.Five] = "5",
        [Enum.KeyCode.Six] = "6",
        [Enum.KeyCode.Seven] = "7",
        [Enum.KeyCode.Eight] = "8",
        [Enum.KeyCode.Nine] = "9",
        [Enum.KeyCode.Zero] = "0",
        [Enum.KeyCode.KeypadOne] = "Num1",
        [Enum.KeyCode.KeypadTwo] = "Num2",
        [Enum.KeyCode.KeypadThree] = "Num3",
        [Enum.KeyCode.KeypadFour] = "Num4",
        [Enum.KeyCode.KeypadFive] = "Num5",
        [Enum.KeyCode.KeypadSix] = "Num6",
        [Enum.KeyCode.KeypadSeven] = "Num7",
        [Enum.KeyCode.KeypadEight] = "Num8",
        [Enum.KeyCode.KeypadNine] = "Num9",
        [Enum.KeyCode.KeypadZero] = "Num0",
        [Enum.KeyCode.Minus] = "-",
        [Enum.KeyCode.Equals] = "=",
        [Enum.KeyCode.Tilde] = "~",
        [Enum.KeyCode.LeftBracket] = "[",
        [Enum.KeyCode.RightBracket] = "]",
        [Enum.KeyCode.RightParenthesis] = ")",
        [Enum.KeyCode.LeftParenthesis] = "(",
        [Enum.KeyCode.Semicolon] = ";",
        [Enum.KeyCode.Quote] = "'",
        [Enum.KeyCode.BackSlash] = "\\",
        [Enum.KeyCode.Comma] = ",",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Slash] = "/",
        [Enum.KeyCode.Asterisk] = "*",
        [Enum.KeyCode.Plus] = "+",
        [Enum.KeyCode.Backquote] = "`",
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.UserInputType.MouseButton4] = "MB4",
        [Enum.UserInputType.MouseButton5] = "MB5",
        [Enum.KeyCode.Escape] = "ESC",
        [Enum.KeyCode.Space] = "SPC",
        [Enum.KeyCode.Tab] = "TAB",
        [Enum.KeyCode.Delete] = "DEL",
        [Enum.KeyCode.Home] = "HOME",
        [Enum.KeyCode.XButton1] = "MB4",
        [Enum.KeyCode.XButton2] = "MB5",
        [Enum.KeyCode.End] = "END",
    }

    library.__index = library

    for _, path in next, library.folders do
        makefolder(library.directory .. path)
    end

    local flags = library.flags
    local config_flags = library.config_flags
    local notifications = library.notifications

    local fonts = {}; do
        local function try_register(name, url, id)
            local ok, asset = pcall(function()
                if not isfile(id) then
                    local fontData = game:HttpGet(url)
                    writefile(id, fontData)
                end
                if isfile(name..".font") then pcall(delfile, name..".font") end
                local data = {name=name, faces={{name="Normal", weight=200, style="Normal", assetId=getcustomasset(id)}}}
                writefile(name..".font", http_service:JSONEncode(data))
                return getcustomasset(name..".font")
            end)
            if ok and asset then return asset end
            return nil
        end
        local MediumAsset = try_register("Medium", "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf", "Medium.ttf")
        local SemiBoldAsset = try_register("SemiBold", "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf", "SemiBold.ttf")
        local function mkFont(asset, fallback)
            if asset then
                local ok, f = pcall(Font.new, asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                if ok and f then return f end
            end
            return Font.fromEnum(fallback or Enum.Font.Gotham)
        end
        fonts = {
            small = mkFont(MediumAsset, Enum.Font.Gotham);
            font = mkFont(SemiBoldAsset, Enum.Font.GothamBold);
            mono = Font.fromEnum(Enum.Font.Code);
        }
    end
--

-- Library functions
    -- Misc functions
        function library:tween(obj, properties, easing_style, time)
            local info = TweenInfo.new(time or 0.22, easing_style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tw = tween_service:Create(obj, info, properties)
            tw:Play()
            return tw
        end
        -- spring helper (critically damped)
        function library:spring(obj, props, speed, damping)
            speed = speed or 18; damping = damping or 0.85
            if library.animation_style ~= "spring" then return library:tween(obj, props, Enum.EasingStyle.Quad, 0.22) end
            local tw = tween_service:Create(obj, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
            tw:Play(); return tw
        end

        function library:resizify(frame)
            local handle = Instance.new("TextButton")
            handle.Position = dim2(1, -12, 1, -12)
            handle.Size = dim2(0, 12, 0, 12)
            handle.BackgroundTransparency = 1
            handle.Text = ""
            handle.ZIndex = 10
            handle.Parent = frame
            local icon = Instance.new("ImageLabel")
            icon.Image = "rbxassetid://6031094670"
            icon.Size = dim2(0, 10, 0, 10); icon.Position = dim2(1, -10, 1, -10)
            icon.BackgroundTransparency = 1; icon.ImageColor3 = rgb(90,90,95); icon.Parent = handle
            local resizing = false; local start_size; local start; local og_size = frame.Size
            local MIN_W, MIN_H = math.max(520, og_size.X.Offset), math.max(360, og_size.Y.Offset)
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = true; start = input.Position; start_size = frame.Size end
            end)
            handle.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end end)
            library:connection(uis.InputChanged, function(input)
                if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local vs = camera.ViewportSize
                    local w = clamp(start_size.X.Offset + (input.Position.X - start.X), MIN_W, vs.X - 20)
                    local h = clamp(start_size.Y.Offset + (input.Position.Y - start.Y), MIN_H, vs.Y - 40)
                    frame.Size = dim2(0, w, 0, h)
                end
            end)
        end

        function fag(tbl) local c=0 for _ in next, tbl do c=c+1 end return c end
        getgenv().fag = fag
        function library:count_flags() return fag(library.flags) end
        function library:next_flag()
            local n = fag(library.flags)+1
            local s = string.format("flagnumber%s", n)
            while library.flags[s] ~= nil do n=n+1; s=string.format("flagnumber%s", n) end
            return s
        end
        function library:get_flag(flag) return flags[flag] end
        function library:set_flag(flag, v)
            local setter = library.config_flags[flag]
            if setter then setter(v) else flags[flag]=v end
        end
        function library:notify(text, typ, title) typ=typ or "info" title=title or "milenium" notifications:create_notification({name=title, info=text, type=typ}) end

        function library:mouse_in_frame(obj)
            local m = uis:GetMouseLocation()
            local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
            return m.X >= pos.X and m.X <= pos.X+size.X and m.Y >= pos.Y and m.Y <= pos.Y+size.Y
        end

        function library:draggify(frame, drag_handle)
            drag_handle = drag_handle or frame
            local dragging=false; local startPos; local startFramePos
            drag_handle.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startPos=input.Position; startFramePos=frame.Position end
            end)
            drag_handle.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            library:connection(uis.InputChanged, function(input)
                if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                    local vs = camera.ViewportSize
                    local nx = clamp(startFramePos.X.Offset + (input.Position.X - startPos.X), 0, vs.X - frame.AbsoluteSize.X - 2)
                    local ny = clamp(startFramePos.Y.Offset + (input.Position.Y - startPos.Y), 0, vs.Y - frame.AbsoluteSize.Y - 2)
                    frame.Position = dim2(0, nx, 0, ny)
                    library:close_element()
                end
            end)
        end

        function library:convert(str)
            local values = {}
            for value in string.gmatch(str, "[^,]+") do
                insert(values, tonumber(value))
            end
            if #values == 4 then
                return unpack(values)
            else
                return
            end
        end

        function library:convert_enum(enum)
            local enum_parts = {}
            for part in string.gmatch(enum, "[%w_]+") do
                insert(enum_parts, part)
            end
            local enum_table = Enum
            for i = 2, #enum_parts do
                local enum_item = enum_table[enum_parts[i]]
                enum_table = enum_item
            end
            return enum_table
        end

        local config_holder;
        function library:update_config_list()
            if not config_holder then return end
            local ok, files = pcall(listfiles, library.directory.."/configs")
            if not ok or not files then return end
            local list={}
            for _, file in next, files do
                local name = file:gsub("\\", "/")
                name = name:match("([^/]+)%.cfg$") or name:match("([^/]+)$") or file
                if name:find("%.cfg") then name = name:gsub("%.cfg","") end
                if name and name~="" then list[#list+1]=name end
            end
            table.sort(list)
            if #list==0 then list={"<no configs>"} end
            config_holder.refresh_options(list)
        end

        function library:get_config()
            local Config={}
            for k, v in next, flags do
                if k=="config_name_list" or k=="config_name_text" then continue end
                if type(v)=="table" and v.key ~= nil then
                    local keyStr = v.key and tostring(v.key) or "NONE"
                    Config[k]={active=v.active, mode=v.mode, key=keyStr}
                elseif type(v)=="table" and v.Color and v.Transparency~=nil then
                    Config[k]={Transparency=v.Transparency, Color=v.Color:ToHex()}
                else
                    Config[k]=v
                end
            end
            local ok, j = pcall(http_service.JSONEncode, http_service, Config)
            return ok and j or "{}"
        end
        function library:load_config(config_json)
            local ok, config = pcall(http_service.JSONDecode, http_service, config_json)
            if not ok or type(config)~="table" then return end
            for k, v in next, config do
                if k=="config_name_list" then continue end
                local setter = library.config_flags[k]
                if setter then
                    if type(v)=="table" and v.Color and v.Transparency~=nil then
                        local col
                        pcall(function() col=Color3.fromHex(v.Color) end)
                        if col then setter(col, v.Transparency) else setter(v) end
                    elseif type(v)=="table" and v.active~=nil then
                        if v.key and type(v.key)=="string" and v.key~="NONE" then
                            local enumVal
                            pcall(function() enumVal=library:convert_enum(v.key) end)
                            if enumVal then v.key=enumVal end
                        end
                        setter(v)
                    else
                        setter(v)
                    end
                end
            end
        end

        function library:round(number, float)
            local multiplier = 1 / (float or 1)
            return floor(number * multiplier + 0.5) / multiplier
        end

        function library:apply_theme(instance, theme, property)
            if not themes.utility[theme] then themes.utility[theme]={[property]={}} end
            if not themes.utility[theme][property] then themes.utility[theme][property]={} end
            insert(themes.utility[theme][property], instance)
            pcall(function() instance[property]=themes.preset[theme] end)
        end
        function library:update_theme(theme, color)
            local t = themes.utility[theme]; if not t then return end
            for propName, list in next, t do
                for _, inst in next, list do
                    if inst and inst.Parent then
                        local ok, cur = pcall(function() return inst[propName] end)
                        if ok and cur == themes.preset[theme] then
                            pcall(function() inst[propName]=color end)
                            pcall(function() library:tween(inst, {[propName]=color}, Enum.EasingStyle.Quad, 0.2) end)
                        end
                    end
                end
            end
            themes.preset[theme]=color
        end

        function library:connection(signal, callback)
            local ok, conn = pcall(function() return signal:Connect(callback) end)
            if ok and conn then insert(library.connections, conn); return conn end
            return {Disconnect=function() end, Connected=false}
        end
        function library:disconnect_all()
            for _,c in next, library.connections do pcall(function() c:Disconnect() end) end
            table.clear(library.connections)
        end

        function library:close_element(new_path)
            local open_element = library.current_open
            if open_element and new_path ~= open_element then
                if open_element.set_visible then
                    open_element.set_visible(false)
                end
                if open_element.open ~= nil then
                    open_element.open = false
                end
            end
            if new_path ~= open_element then
                library.current_open = new_path or nil;
            end
        end

        function library:create(className, props)
            local ins = Instance.new(className)
            if props then for prop, value in next, props do
                local ok, _ = pcall(function() ins[prop]=value end)
                if not ok then pcall(function() ins[prop]=value end) end
            end end
            return ins
        end

        function library:unload_menu()
            pcall(function() if library.items then library.items:Destroy() end end)
            pcall(function() if library.other then library.other:Destroy() end end)
            library:disconnect_all()
            pcall(function()
                for _, n in next, library.notifications.notifs do if n and n.Parent then n:Destroy() end end
                table.clear(library.notifications.notifs)
            end)
            library.flags = {}; library.config_flags={}
        end
    --

    -- Library element functions
        function library:window(properties)
            local cfg = {
                suffix = properties.suffix or properties.Suffix or "tech";
                name = properties.name or properties.Name or "nebula";
                game_name = properties.gameInfo or properties.game_info or properties.GameInfo or "Milenium V2 for Counter-Strike: Global Offensive";
                size = properties.size or properties.Size or dim2(0, 700, 0, 565);
                selected_tab;
                items = {};

                tween;
            }

            local hui = gethui_safe()
            library["items"] = library:create("ScreenGui", {
                Parent = hui;
                Name = "\0";
                Enabled = true;
                ZIndexBehavior = Enum.ZIndexBehavior.Global;
                IgnoreGuiInset = true;
                DisplayOrder = 10;
                ResetOnSpawn = false;
            });
            library["other"] = library:create("ScreenGui", {
                Parent = hui;
                Name = "\0";
                Enabled = true;
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
                IgnoreGuiInset = true;
                DisplayOrder = 11;
                ResetOnSpawn = false;
            });
            pcall(function()
                if getgenv()._MILENIUM_BLUR ~= false then
                    local blur = Instance.new("BlurEffect")
                    blur.Size = 6; blur.Parent = lighting
                    library._blur = blur
                end
            end)

            -- cache: stores all elements not in use, so we don't recreate them on tab switch
            library["cache"] = library:create("Frame", {
                Parent = library["items"];
                BackgroundTransparency = 1;
                Size = dim2(0, 0, 0, 0);
                Position = dim2(0, -10000, 0, -10000);
                Name = "\0";
            })

            local items = cfg.items; do
                items["main"] = library:create("Frame", {
                    Parent = library["items"];
                    Size = cfg.size;
                    Name = "\0";
                    Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16)
                }); items["main"].Position = dim2(0, items["main"].AbsolutePosition.X, 0, items["main"].AbsolutePosition.Y)

                library:create("UICorner", {
                    Parent = items["main"];
                    CornerRadius = dim(0, 10)
                });

                library:create("UIStroke", {
                    Color = rgb(23, 23, 29);
                    Parent = items["main"];
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                });

                items["side_frame"] = library:create("Frame", {
                    Parent = items["main"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 196, 1, -25);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16)
                });

                library:create("Frame", {
                    AnchorPoint = vec2(1, 0);
                    Parent = items["side_frame"];
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 1, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(21, 21, 23)
                });

                items["button_holder"] = library:create("Frame", {
                    Parent = items["side_frame"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 0, 0, 60);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 1, -60);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); cfg.button_holder = items["button_holder"];

                library:create("UIListLayout", {
                    Parent = items["button_holder"];
                    Padding = dim(0, 5);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create("UIPadding", {
                    PaddingTop = dim(0, 16);
                    PaddingBottom = dim(0, 36);
                    Parent = items["button_holder"];
                    PaddingRight = dim(0, 11);
                    PaddingLeft = dim(0, 10)
                });

                local accent = themes.preset.accent
                items["title"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    BorderColor3 = rgb(0, 0, 0);
                    Text = name;
                    Parent = items["side_frame"];
                    Name = "\0";
                    Text = string.format('<u>%s</u><font color = "rgb(255, 255, 255)">%s</font>', cfg.name, cfg.suffix);
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 70);
                    TextColor3 = themes.preset.accent;
                    BorderSizePixel = 0;
                    RichText = true;
                    TextSize = 30;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items["title"], "accent", "TextColor3");

                items["multi_holder"] = library:create("Frame", {
                    Parent = items["main"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 196, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -196, 0, 56);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); cfg.multi_holder = items["multi_holder"];

                library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = items["multi_holder"];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(21, 21, 23)
                });

                items["shadow"] = library:create("ImageLabel", {
                    ImageColor3 = rgb(0, 0, 0);
                    ScaleType = Enum.ScaleType.Slice;
                    Parent = items["main"];
                    BorderColor3 = rgb(0, 0, 0);
                    Name = "\0";
                    BackgroundColor3 = rgb(255, 255, 255);
                    Size = dim2(1, 75, 1, 75);
                    AnchorPoint = vec2(0.5, 0.5);
                    Image = "rbxassetid://112971167999062";
                    BackgroundTransparency = 1;
                    Position = dim2(0.5, 0, 0.5, 0);
                    SliceScale = 0.75;
                    ZIndex = -100;
                    BorderSizePixel = 0;
                    SliceCenter = rect(vec2(112, 112), vec2(147, 147))
                });

                items["global_fade"] = library:create("Frame", {
                    Parent = items["main"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 196, 0, 56);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -196, 1, -81);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16);
                    ZIndex = 2;
                });

                library:create("UICorner", {
                    Parent = items["shadow"];
                    CornerRadius = dim(0, 5)
                });

                items["info"] = library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = items["main"];
                    Name = "\0";
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 25);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(23, 23, 25)
                });

                library:create("UICorner", {
                    Parent = items["info"];
                    CornerRadius = dim(0, 10)
                });

                items["grey_fill"] = library:create("Frame", {
                    Name = "\0";
                    Parent = items["info"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 6);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(23, 23, 25)
                });

                items["game"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    Parent = items["info"];
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.game_name;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    AnchorPoint = vec2(0, 0.5);
                    Position = dim2(0, 10, 0.5, -1);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["other_info"] = library:create("TextLabel", {
                    Parent = items["info"];
                    RichText = true;
                    Name = "\0";
                    TextColor3 = themes.preset.accent;
                    BorderColor3 = rgb(0, 0, 0);
                    Text = '<font color="rgb(72, 72, 73)">∞ days left, </font>' .. cfg.name .. cfg.suffix;
                    Size = dim2(1, 0, 0, 0);
                    Position = dim2(0, -10, 0.5, -1);
                    AnchorPoint = vec2(0, 0.5);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    FontFace = fonts.font;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items["other_info"], "accent", "TextColor3");
            end

            do -- Other
                library:draggify(items["main"])
                library:resizify(items["main"])
            end

            function cfg.toggle_menu(bool)
                library["items"].Enabled = bool
                if library._blur then pcall(function() library._blur.Enabled = bool and (getgenv()._MILENIUM_BLUR ~= false) end) end
            end
            function cfg.fade_background(bool)
                getgenv()._MILENIUM_BLUR = bool
                if library._blur then pcall(function() library._blur.Enabled = bool and library["items"].Enabled end) end
            end
            function cfg.set_accent(color) library:update_theme("accent", color) end

            return setmetatable(cfg, library)
        end

        function library:tab(properties)
            local cfg = {
                name = properties.name or properties.Name or "visuals";
                icon = properties.icon or properties.Icon or "http://www.roblox.com/asset/?id=6034767608";

                tabs = properties.tabs or properties.Tabs or {"Main", "Misc.", "Settings"};
                pages = {};
                current_multi;

                items = {};
            }

            local items = cfg.items; do
                items["tab_holder"] = library:create("Frame", {
                    Parent = library.cache;
                    Name = "\0";
                    Visible = false;
                    BackgroundTransparency = 1;
                    Position = dim2(0, 196, 0, 56);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -216, 1, -101);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                -- Tab buttons
                    items["button"] = library:create("TextButton", {
                        FontFace = fonts.font;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        Parent = self.items["button_holder"];
                        AutoButtonColor = false;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Size = dim2(1, 0, 0, 35);
                        BorderSizePixel = 0;
                        TextSize = 16;
                        BackgroundColor3 = rgb(29, 29, 29)
                    });

                    items["icon"] = library:create("ImageLabel", {
                        ImageColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = items["button"];
                        AnchorPoint = vec2(0, 0.5);
                        Image = "http://www.roblox.com/asset/?id=6034767608";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 10, 0.5, 0);
                        Name = "\0";
                        Size = dim2(0, 22, 0, 22);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    }); library:apply_theme(items["icon"], "accent", "ImageColor3");

                    items["name"] = library:create("TextLabel", {
                        FontFace = fonts.font;
                        TextColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = cfg.name;
                        Parent = items["button"];
                        Name = "\0";
                        Size = dim2(0, 0, 1, 0);
                        Position = dim2(0, 40, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.X;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create("UIPadding", {
                        Parent = items["name"];
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });

                    library:create("UICorner", {
                        Parent = items["button"];
                        CornerRadius = dim(0, 7)
                    });

                    library:create("UIStroke", {
                        Color = rgb(23, 23, 29);
                        Parent = items["button"];
                        Enabled = false;
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    });
                --

                -- Multi Sections
                    items["multi_section_button_holder"] = library:create("Frame", {
                        Parent = library.cache;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Visible = false;
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create("UIListLayout", {
                        Parent = items["multi_section_button_holder"];
                        Padding = dim(0, 7);
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        FillDirection = Enum.FillDirection.Horizontal
                    });

                    library:create("UIPadding", {
                        PaddingTop = dim(0, 8);
                        PaddingBottom = dim(0, 7);
                        Parent = items["multi_section_button_holder"];
                        PaddingRight = dim(0, 7);
                        PaddingLeft = dim(0, 7)
                    });

                    for _, section in cfg.tabs do
                        local data = {items = {}}

                        local multi_items = data.items; do
                            -- Button
                                multi_items["button"] = library:create("TextButton", {
                                    FontFace = fonts.font;
                                    TextColor3 = rgb(255, 255, 255);
                                    BorderColor3 = rgb(0, 0, 0);
                                    AutoButtonColor = false;
                                    Text = "";
                                    Parent = items["multi_section_button_holder"];
                                    Name = "\0";
                                    Size = dim2(0, 0, 0, 39);
                                    BackgroundTransparency = 1;
                                    ClipsDescendants = true;
                                    BorderSizePixel = 0;
                                    AutomaticSize = Enum.AutomaticSize.X;
                                    TextSize = 16;
                                    BackgroundColor3 = rgb(25, 25, 29)
                                });

                                multi_items["name"] = library:create("TextLabel", {
                                    FontFace = fonts.font;
                                    TextColor3 = rgb(62, 62, 63);
                                    BorderColor3 = rgb(0, 0, 0);
                                    Text = section;
                                    Parent = multi_items["button"];
                                    Name = "\0";
                                    Size = dim2(0, 0, 1, 0);
                                    BackgroundTransparency = 1;
                                    TextXAlignment = Enum.TextXAlignment.Left;
                                    BorderSizePixel = 0;
                                    AutomaticSize = Enum.AutomaticSize.XY;
                                    TextSize = 16;
                                    BackgroundColor3 = rgb(255, 255, 255)
                                });

                                library:create("UIPadding", {
                                    Parent = multi_items["name"];
                                    PaddingRight = dim(0, 5);
                                    PaddingLeft = dim(0, 5)
                                });

                                multi_items["accent"] = library:create("Frame", {
                                    BorderColor3 = rgb(0, 0, 0);
                                    AnchorPoint = vec2(0, 1);
                                    Parent = multi_items["button"];
                                    BackgroundTransparency = 1;
                                    Position = dim2(0, 10, 1, 4);
                                    Name = "\0";
                                    Size = dim2(1, -20, 0, 6);
                                    BorderSizePixel = 0;
                                    BackgroundColor3 = themes.preset.accent
                                }); library:apply_theme(multi_items["accent"], "accent", "BackgroundColor3");

                                library:create("UICorner", {
                                    Parent = multi_items["accent"];
                                    CornerRadius = dim(0, 999)
                                });

                                library:create("UIPadding", {
                                    Parent = multi_items["button"];
                                    PaddingRight = dim(0, 10);
                                    PaddingLeft = dim(0, 10)
                                });

                                library:create("UICorner", {
                                    Parent = multi_items["button"];
                                    CornerRadius = dim(0, 7)
                                });
                            --

                            -- Tab
                                multi_items["tab"] = library:create("Frame", {
                                    Parent = library.cache;
                                    BackgroundTransparency = 1;
                                    Name = "\0";
                                    BorderColor3 = rgb(0, 0, 0);
                                    Size = dim2(1, -20, 1, -20);
                                    BorderSizePixel = 0;
                                    Visible = false;
                                    BackgroundColor3 = rgb(255, 255, 255)
                                });

                                library:create("UIListLayout", {
                                    FillDirection = Enum.FillDirection.Vertical;
                                    HorizontalFlex = Enum.UIFlexAlignment.Fill;
                                    Parent = multi_items["tab"];
                                    Padding = dim(0, 7);
                                    SortOrder = Enum.SortOrder.LayoutOrder;
                                    VerticalFlex = Enum.UIFlexAlignment.Fill
                                });

                                library:create("UIPadding", {
                                    PaddingTop = dim(0, 7);
                                    PaddingBottom = dim(0, 7);
                                    Parent = multi_items["tab"];
                                    PaddingRight = dim(0, 7);
                                    PaddingLeft = dim(0, 7)
                                });
                            --
                        end

                        data.text = multi_items["name"]
                        data.accent = multi_items["accent"]
                        data.button = multi_items["button"]
                        data.page = multi_items["tab"]
                        data.parent = setmetatable(data, library):sub_tab({}).items["tab_parent"]

                        function data.open_page()
                            local page = cfg.current_multi;

                            if page and page.text ~= data.text then
                                self.items["global_fade"].BackgroundTransparency = 0
                                library:tween(self.items["global_fade"], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.4)

                                local old_size = page.page.Size
                                page.page.Size = dim2(1, -20, 1, -20)
                            end

                            if page then
                                library:tween(page.text, {TextColor3 = rgb(62, 62, 63)})
                                library:tween(page.accent, {BackgroundTransparency = 1})
                                library:tween(page.button, {BackgroundTransparency = 1})

                                page.page.Visible = false
                                page.page.Parent = library["cache"]
                            end

                            library:tween(data.text, {TextColor3 = rgb(255, 255, 255)})
                            library:tween(data.accent, {BackgroundTransparency = 0})
                            library:tween(data.button, {BackgroundTransparency = 0})
                            library:tween(data.page, {Size = dim2(1, 0, 1, 0)}, Enum.EasingStyle.Quad, 0.4)

                            data.page.Visible = true
                            data.page.Parent = items["tab_holder"]

                            cfg.current_multi = data

                            library:close_element()
                        end

                        multi_items["button"].MouseButton1Down:Connect(function()
                            data.open_page()
                        end)

                        cfg.pages[#cfg.pages + 1] = setmetatable(data, library)
                    end

                    cfg.pages[1].open_page()
                --
            end

            function cfg.open_tab()
                local selected_tab = self.selected_tab

                if selected_tab then
                    if selected_tab[4] ~= items["tab_holder"] then
                        self.items["global_fade"].BackgroundTransparency = 0

                        library:tween(self.items["global_fade"], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.4)
                        selected_tab[4].Size = dim2(1, -216, 1, -101)
                    end

                    library:tween(selected_tab[1], {BackgroundTransparency = 1})
                    library:tween(selected_tab[2], {ImageColor3 = rgb(72, 72, 73)})
                    library:tween(selected_tab[3], {TextColor3 = rgb(72, 72, 73)})

                    selected_tab[4].Visible = false
                    selected_tab[4].Parent = library["cache"]
                    selected_tab[5].Visible = false
                    selected_tab[5].Parent = library["cache"]
                end

                library:tween(items["button"], {BackgroundTransparency = 0})
                library:tween(items["icon"], {ImageColor3 = themes.preset.accent})
                library:tween(items["name"], {TextColor3 = rgb(255, 255, 255)})
                library:tween(items["tab_holder"], {Size = dim2(1, -196, 1, -81)}, Enum.EasingStyle.Quad, 0.4)

                items["tab_holder"].Visible = true
                items["tab_holder"].Parent = self.items["main"]
                items["multi_section_button_holder"].Visible = true
                items["multi_section_button_holder"].Parent = self.items["multi_holder"]

                self.selected_tab = {
                    items["button"];
                    items["icon"];
                    items["name"];
                    items["tab_holder"];
                    items["multi_section_button_holder"];
                }

                library:close_element()
            end

            items["button"].MouseButton1Down:Connect(function()
                cfg.open_tab()
            end)

            if not self.selected_tab then
                cfg.open_tab(true)
            end

            return unpack(cfg.pages)
        end

        function library:seperator(properties)
            local cfg = {items = {}, name = properties.Name or properties.name or "General"}

            local items = cfg.items do
                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = self.items["button_holder"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    Position = dim2(0, 40, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });
            end;

            return setmetatable(cfg, library)
        end

        -- Miscellaneous
            function library:column(properties)
                local cfg = {items = {}, size = properties.size or 1}

                local items = cfg.items; do
                    items["column"] = library:create("Frame", {
                        Parent = self["parent"] or self.items["tab_parent"];
                        BackgroundTransparency = 1;
                        Name = "\0";
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 0, cfg.size, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create("UIPadding", {
                        PaddingBottom = dim(0, 10);
                        Parent = items["column"]
                    });

                    library:create("UIListLayout", {
                        Parent = items["column"];
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        Padding = dim(0, 10);
                        FillDirection = Enum.FillDirection.Vertical;
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });
                end

                return setmetatable(cfg, library)
            end

            function library:sub_tab(properties)
                local cfg = {items = {}, order = properties.order or 0; size = properties.size or 1}

                local items = cfg.items; do
                    items["tab_parent"] = library:create("Frame", {
                        Parent = self.items["tab"];
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Size = dim2(0,0,cfg.size,0);
                        BorderColor3 = rgb(0, 0, 0);
                        BorderSizePixel = 0;
                        Visible = true;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal;
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        VerticalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = items["tab_parent"];
                        Padding = dim(0, 7);
                        SortOrder = Enum.SortOrder.LayoutOrder;
                    });
                end

                return setmetatable(cfg, library)
            end
        --

        function library:section(properties)
            local cfg = {
                name = properties.name or properties.Name or "section";
                side = properties.side or properties.Side or "left";
                default = properties.default or properties.Default or false;
                size = properties.size or properties.Size or self.size or 0.5;
                icon = properties.icon or properties.Icon or "http://www.roblox.com/asset/?id=6022668898";
                fading_toggle = properties.fading or properties.Fading or false;
                items = {};
            };

            local items = cfg.items; do
                items["outline"] = library:create("Frame", {
                    Name = "\0";
                    Parent = self.items["column"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, cfg.size, -3);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(25, 25, 29)
                });

                library:create("UICorner", {
                    Parent = items["outline"];
                    CornerRadius = dim(0, 7)
                });

                items["inline"] = library:create("Frame", {
                    Parent = items["outline"];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -2, 1, -2);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });

                library:create("UICorner", {
                    Parent = items["inline"];
                    CornerRadius = dim(0, 7)
                });

                items["scrolling"] = library:create("ScrollingFrame", {
                    ScrollBarImageColor3 = rgb(44, 44, 46);
                    Active = true;
                    AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    ScrollBarThickness = 2;
                    Parent = items["inline"];
                    Name = "\0";
                    Size = dim2(1, 0, 1, -40);
                    BackgroundTransparency = 1;
                    Position = dim2(0, 0, 0, 35);
                    BackgroundColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    CanvasSize = dim2(0, 0, 0, 0)
                });

                items["elements"] = library:create("Frame", {
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items["scrolling"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 10, 0, 10);
                    Size = dim2(1, -20, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    Parent = items["elements"];
                    Padding = dim(0, 10);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create("UIPadding", {
                    PaddingBottom = dim(0, 15);
                    Parent = items["elements"]
                });

                items["button"] = library:create("TextButton", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    Parent = items["outline"];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    Size = dim2(1, -2, 0, 35);
                    BorderSizePixel = 0;
                    TextSize = 16;
                    BackgroundColor3 = rgb(19, 19, 21)
                });

                library:create("UIStroke", {
                    Color = rgb(23, 23, 29);
                    Parent = items["button"];
                    Enabled = false;
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                });

                library:create("UICorner", {
                    Parent = items["button"];
                    CornerRadius = dim(0, 7)
                });

                items["Icon"] = library:create("ImageLabel", {
                    ImageColor3 = themes.preset.accent;
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items["button"];
                    AnchorPoint = vec2(0, 0.5);
                    Image = cfg.icon;
                    BackgroundTransparency = 1;
                    Position = dim2(0, 10, 0.5, 0);
                    Name = "\0";
                    Size = dim2(0, 22, 0, 22);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items["Icon"], "accent", "ImageColor3");

                items["section_title"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["button"];
                    Name = "\0";
                    Size = dim2(0, 0, 1, 0);
                    Position = dim2(0, 40, 0, -1);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.X;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = items["button"];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });

                if cfg.fading_toggle then
                    items["toggle"] = library:create("TextButton", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        AutoButtonColor = false;
                        Text = "";
                        AnchorPoint = vec2(1, 0.5);
                        Parent = items["button"];
                        Name = "\0";
                        Position = dim2(1, -9, 0.5, 0);
                        Size = dim2(0, 36, 0, 18);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(58, 58, 62)
                    });  library:apply_theme(items["toggle"], "accent", "BackgroundColor3");

                    library:create("UICorner", {
                        Parent = items["toggle"];
                        CornerRadius = dim(0, 999)
                    });

                    items["toggle_outline"] = library:create("Frame", {
                        Parent = items["toggle"];
                        Size = dim2(1, -2, 1, -2);
                        Name = "\0";
                        BorderMode = Enum.BorderMode.Inset;
                        BorderColor3 = rgb(0, 0, 0);
                        Position = dim2(0, 1, 0, 1);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(50, 50, 50)
                    });  library:apply_theme(items["toggle_outline"], "accent", "BackgroundColor3");

                    library:create("UICorner", {
                        Parent = items["toggle_outline"];
                        CornerRadius = dim(0, 999)
                    });

                    library:create("UIGradient", {
                        Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))};
                        Parent = items["toggle_outline"]
                    });

                    items["toggle_circle"] = library:create("Frame", {
                        Parent = items["toggle_outline"];
                        Name = "\0";
                        Position = dim2(0, 2, 0, 2);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 12, 0, 12);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(86, 86, 88)
                    });

                    library:create("UICorner", {
                        Parent = items["toggle_circle"];
                        CornerRadius = dim(0, 999)
                    });

                    library:create("UICorner", {
                        Parent = items["outline"];
                        CornerRadius = dim(0, 7)
                    });

                    items["fade"] = library:create("Frame", {
                        Parent = items["outline"];
                        BackgroundTransparency = 0.800000011920929;
                        Name = "\0";
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });

                    library:create("UICorner", {
                        Parent = items["fade"];
                        CornerRadius = dim(0, 7)
                    });
                end
            end;

            if cfg.fading_toggle then
                items["button"].MouseButton1Click:Connect(function()
                    cfg.default = not cfg.default
                    cfg.toggle_section(cfg.default)
                end)

                function cfg.toggle_section(bool)
                    library:tween(items["toggle"], {BackgroundColor3 = bool and themes.preset.accent or rgb(58, 58, 62)}, Enum.EasingStyle.Quad)
                    library:tween(items["toggle_outline"], {BackgroundColor3 = bool and themes.preset.accent or rgb(50, 50, 50)}, Enum.EasingStyle.Quad)
                    library:tween(items["toggle_circle"], {BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(86, 86, 88), Position = bool and dim2(1, -14, 0, 2) or dim2(0, 2, 0, 2)}, Enum.EasingStyle.Quad)
                    library:tween(items["fade"], {BackgroundTransparency = bool and 1 or 0.8}, Enum.EasingStyle.Quad)
                end
            end

            return setmetatable(cfg, library)
        end

        function library:toggle(options)
            local rand = math.random(1, 2)
            local cfg = {
                enabled = options.enabled or nil,
                name = options.name or "Toggle",
                info = options.info or nil,
                flag = options.flag or library:next_flag(),

                type = options.type and string.lower(options.type) or rand == 1 and "toggle" or "checkbox";

                default = options.default or false,
                folding = options.folding or false,
                callback = options.callback or function() end,

                items = {};
                seperator = options.seperator or options.Seperator or false;
            }

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items["toggle"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["toggle"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.info then
                    items["info"] = library:create("TextLabel", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items["toggle"];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 17);
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["right_components"] = library:create("Frame", {
                    Parent = items["toggle"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = items["right_components"];
                    Padding = dim(0, 9);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                if cfg.type == "checkbox" then
                    items["toggle_button"] = library:create("TextButton", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        LayoutOrder = 2;
                        AutoButtonColor = false;
                        AnchorPoint = vec2(1, 0);
                        Parent = items["right_components"];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        Size = dim2(0, 16, 0, 16);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(67, 67, 68)
                    }); library:apply_theme(items["toggle_button"], "accent", "BackgroundColor3");

                    library:create("UICorner", {
                        Parent = items["toggle_button"];
                        CornerRadius = dim(0, 4)
                    });

                    items["outline"] = library:create("Frame", {
                        Parent = items["toggle_button"];
                        Size = dim2(1, -2, 1, -2);
                        Name = "\0";
                        BorderMode = Enum.BorderMode.Inset;
                        BorderColor3 = rgb(0, 0, 0);
                        Position = dim2(0, 1, 0, 1);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(22, 22, 24)
                    }); library:apply_theme(items["outline"], "accent", "BackgroundColor3");

                    items["tick"] = library:create("ImageLabel", {
                        ImageTransparency = 1;
                        BorderColor3 = rgb(0, 0, 0);
                        Image = "rbxassetid://111862698467575";
                        BackgroundTransparency = 1;
                        Position = dim2(0, -1, 0, 0);
                        Parent = items["outline"];
                        Size = dim2(1, 2, 1, 2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255);
                        ZIndex = 1;
                    });

                    library:create("UICorner", {
                        Parent = items["outline"];
                        CornerRadius = dim(0, 4)
                    });

                    library:create("UIGradient", {
                        Enabled = false;
                        Parent = items["outline"];
                        Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))}
                    });
                else
                    items["toggle_button"] = library:create("TextButton", {
                        FontFace = fonts.font;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        LayoutOrder = 2;
                        AnchorPoint = vec2(1, 0.5);
                        Parent = items["right_components"];
                        Name = "\0";
                        Position = dim2(1, -9, 0.5, 0);
                        Size = dim2(0, 36, 0, 18);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = themes.preset.accent
                    }); library:apply_theme(items["toggle_button"], "accent", "BackgroundColor3");

                    library:create("UICorner", {
                        Parent = items["toggle_button"];
                        CornerRadius = dim(0, 999)
                    });

                    items["inline"] = library:create("Frame", {
                        Parent = items["toggle_button"];
                        Size = dim2(1, -2, 1, -2);
                        Name = "\0";
                        BorderMode = Enum.BorderMode.Inset;
                        BorderColor3 = rgb(0, 0, 0);
                        Position = dim2(0, 1, 0, 1);
                        BorderSizePixel = 0;
                        BackgroundColor3 = themes.preset.accent
                    }); library:apply_theme(items["inline"], "accent", "BackgroundColor3");

                    library:create("UICorner", {
                        Parent = items["inline"];
                        CornerRadius = dim(0, 999)
                    });

                    library:create("UIGradient", {
                        Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))};
                        Parent = items["inline"]
                    });

                    items["circle"] = library:create("Frame", {
                        Parent = items["inline"];
                        Name = "\0";
                        Position = dim2(1, -14, 0, 2);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 12, 0, 12);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create("UICorner", {
                        Parent = items["circle"];
                        CornerRadius = dim(0, 999)
                    });
                end
            end;

            function cfg.set(bool)
                if cfg.type == "checkbox" then
                    library:tween(items["tick"], {Rotation = bool and 0 or 45, ImageTransparency = bool and 0 or 1})
                    library:tween(items["toggle_button"], {BackgroundColor3 = bool and themes.preset.accent or rgb(67, 67, 68)})
                    library:tween(items["outline"], {BackgroundColor3 = bool and themes.preset.accent or rgb(22, 22, 24)})
                else
                    library:tween(items["toggle_button"], {BackgroundColor3 = bool and themes.preset.accent or rgb(58, 58, 62)}, Enum.EasingStyle.Quad)
                    library:tween(items["inline"], {BackgroundColor3 = bool and themes.preset.accent or rgb(50, 50, 50)}, Enum.EasingStyle.Quad)
                    library:tween(items["circle"], {BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(86, 86, 88), Position = bool and dim2(1, -14, 0, 2) or dim2(0, 2, 0, 2)}, Enum.EasingStyle.Quad)
                end

                cfg.callback(bool)

                flags[cfg.flag] = bool
            end

            items["toggle"].MouseButton1Click:Connect(function()
                cfg.enabled = not cfg.enabled
                cfg.set(cfg.enabled)
            end)

            items["toggle_button"].MouseButton1Click:Connect(function()
                cfg.enabled = not cfg.enabled
                cfg.set(cfg.enabled)
            end)

            if cfg.seperator then
                library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items["elements"];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            cfg.set(cfg.default)

            config_flags[cfg.flag] = cfg.set

            return setmetatable(cfg, library)
        end

        function library:slider(options)
            local cfg = {
                name = options.name or nil,
                suffix = options.suffix or "",
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end,
                info = options.info or nil;

                min = options.min or options.minimum or 0,
                max = options.max or options.maximum or 100,
                intervals = options.interval or options.decimal or 1,
                default = options.default or 10,
                value = options.default or 10,
                seperator = options.seperator or options.Seperator or true;

                dragging = false,
                items = {}
            }

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items["slider_object"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["slider_object"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.info then
                    items["info"] = library:create("TextLabel", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items["slider_object"];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 37);
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["right_components"] = library:create("Frame", {
                    Parent = items["slider_object"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 4, 0, 23);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    Parent = items["right_components"];
                    Padding = dim(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    FillDirection = Enum.FillDirection.Horizontal
                });

                items["slider"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Parent = items["right_components"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    Size = dim2(1, -4, 0, 4);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = items["slider"];
                    CornerRadius = dim(0, 999)
                });

                items["fill"] = library:create("Frame", {
                    Name = "\0";
                    Parent = items["slider"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0.5, 0, 0, 4);
                    BorderSizePixel = 0;
                    BackgroundColor3 = themes.preset.accent
                });  library:apply_theme(items["fill"], "accent", "BackgroundColor3");

                library:create("UICorner", {
                    Parent = items["fill"];
                    CornerRadius = dim(0, 999)
                });

                items["circle"] = library:create("Frame", {
                    AnchorPoint = vec2(0.5, 0.5);
                    Parent = items["fill"];
                    Name = "\0";
                    Position = dim2(1, 0, 0.5, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 12, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(244, 244, 244)
                });

                library:create("UICorner", {
                    Parent = items["circle"];
                    CornerRadius = dim(0, 999)
                });

                library:create("UIPadding", {
                    Parent = items["right_components"];
                    PaddingTop = dim(0, 4)
                });

                items["value"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "50%";
                    Parent = items["slider_object"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    Position = dim2(0, 6, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["value"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });
            end

            function cfg.set(value)
                cfg.value = clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)

                library:tween(items["fill"], {Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), cfg.value == cfg.min and 0 or -4, 0, 2)}, Enum.EasingStyle.Linear, 0.05)
                items["value"].Text = tostring(cfg.value) .. cfg.suffix

                flags[cfg.flag] = cfg.value
                cfg.callback(flags[cfg.flag])
            end

            items["slider"].MouseButton1Down:Connect(function()
                cfg.dragging = true
                library:tween(items["value"], {TextColor3 = rgb(255, 255, 255)}, Enum.EasingStyle.Quad, 0.2)
            end)

            library:connection(uis.InputChanged, function(input)
                if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local size_x = (input.Position.X - items["slider"].AbsolutePosition.X) / items["slider"].AbsoluteSize.X
                    local value = ((cfg.max - cfg.min) * size_x) + cfg.min
                    cfg.set(value)
                end
            end)

            library:connection(uis.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    cfg.dragging = false
                    library:tween(items["value"], {TextColor3 = rgb(72, 72, 73)}, Enum.EasingStyle.Quad, 0.2)
                end
            end)

            if cfg.seperator then
                library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items["elements"];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            cfg.set(cfg.default)
            config_flags[cfg.flag] = cfg.set

            return setmetatable(cfg, library)
        end

        function library:dropdown(options)
            local cfg = {
                name = options.name or nil;
                info = options.info or nil;
                flag = options.flag or library:next_flag();
                options = options.items or {""};
                callback = options.callback or function() end;
                multi = options.multi or false;
                scrolling = options.scrolling or false;

                width = options.width or 130;

                open = false;
                option_instances = {};
                multi_items = {};
                ignore = options.ignore or false;
                items = {};
                y_size;
                seperator = options.seperator or options.Seperator or true;
            }

            cfg.default = options.default or (cfg.multi and {cfg.options[1]}) or cfg.options[1] or "None"
            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items["dropdown_object"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "Dropdown";
                    Parent = items["dropdown_object"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.info then
                    items["info"] = library:create("TextLabel", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items["dropdown_object"];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 17);
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["right_components"] = library:create("Frame", {
                    Parent = items["dropdown_object"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = items["right_components"];
                    Padding = dim(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                items["dropdown"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Parent = items["right_components"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    Size = dim2(0, cfg.width, 0, 16);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = items["dropdown"];
                    CornerRadius = dim(0, 4)
                });

                items["sub_text"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(86, 86, 87);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = items["dropdown"];
                    Name = "\0";
                    Size = dim2(1, -12, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["sub_text"];
                    PaddingTop = dim(0, 1);
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["indicator"] = library:create("ImageLabel", {
                    ImageColor3 = rgb(86, 86, 87);
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items["dropdown"];
                    AnchorPoint = vec2(1, 0.5);
                    Image = "rbxassetid://101025591575185";
                    BackgroundTransparency = 1;
                    Position = dim2(1, -5, 0.5, 0);
                    Name = "\0";
                    Size = dim2(0, 12, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["dropdown_holder"] = library:create("Frame", {
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = library["items"];
                    Name = "\0";
                    Visible = true;
                    BackgroundTransparency = 1;
                    Size = dim2(0, 0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(0, 0, 0);
                    ZIndex = 10;
                });

                items["outline"] = library:create("Frame", {
                    Parent = items["dropdown_holder"];
                    Size = dim2(1, 0, 1, 0);
                    ClipsDescendants = true;
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(33, 33, 35);
                    ZIndex = 10;
                });

                library:create("UIPadding", {
                    PaddingBottom = dim(0, 6);
                    PaddingTop = dim(0, 3);
                    PaddingLeft = dim(0, 3);
                    Parent = items["outline"]
                });

                library:create("UIListLayout", {
                    Parent = items["outline"];
                    Padding = dim(0, 5);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create("UICorner", {
                    Parent = items["outline"];
                    CornerRadius = dim(0, 4)
                });
            end

            function cfg.render_option(text)
                local button = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = text;
                    Parent = items["outline"];
                    Name = "\0";
                    Size = dim2(1, -12, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255);
                    ZIndex = 10;
                }); library:apply_theme(button, "accent", "TextColor3");

                library:create("UIPadding", {
                    Parent = button;
                    PaddingTop = dim(0, 1);
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                return button
            end

            function cfg.set_visible(bool)
                local a = bool and cfg.y_size or 0
                library:tween(items["dropdown_holder"], {Size = dim_offset(items["dropdown"].AbsoluteSize.X, a)})

                items["dropdown_holder"].Position = dim2(0, items["dropdown"].AbsolutePosition.X, 0, items["dropdown"].AbsolutePosition.Y + 80)
                if not (self.sanity and library.current_open == self) then
                    library:close_element(cfg)
                end
            end

            function cfg.set(value)
                local selected = {}
                local isTable = type(value) == "table"

                for _, option in cfg.option_instances do
                    if option.Text == value or (isTable and find(value, option.Text)) then
                        insert(selected, option.Text)
                        cfg.multi_items = selected
                        option.TextColor3 = themes.preset.accent
                    else
                        option.TextColor3 = rgb(72, 72, 73)
                    end
                end

                items["sub_text"].Text = isTable and concat(selected, ", ") or selected[1] or ""
                flags[cfg.flag] = isTable and selected or selected[1]

                cfg.callback(flags[cfg.flag])
            end

            function cfg.refresh_options(list)
                cfg.y_size = 0

                for _, option in cfg.option_instances do
                    option:Destroy()
                end

                cfg.option_instances = {}

                for _, option in list do
                    local button = cfg.render_option(option)
                    cfg.y_size += button.AbsoluteSize.Y + 6
                    insert(cfg.option_instances, button)

                    button.MouseButton1Down:Connect(function()
                        if cfg.multi then
                            local selected_index = find(cfg.multi_items, button.Text)

                            if selected_index then
                                remove(cfg.multi_items, selected_index)
                            else
                                insert(cfg.multi_items, button.Text)
                            end

                            cfg.set(cfg.multi_items)
                        else
                            cfg.set_visible(false)
                            cfg.open = false

                            cfg.set(button.Text)
                        end
                    end)
                end
            end

            items["dropdown"].MouseButton1Click:Connect(function()
                cfg.open = not cfg.open

                cfg.set_visible(cfg.open)
            end)

            if cfg.seperator then
                library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items["elements"];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            flags[cfg.flag] = {}
            config_flags[cfg.flag] = cfg.set

            cfg.refresh_options(cfg.options)
            cfg.set(cfg.default)

            return setmetatable(cfg, library)
        end

        function library:label(options)
            local cfg = {
                enabled = options.enabled or nil,
                name = options.name or "Toggle",
                seperator = options.seperator or options.Seperator or false;
                info = options.info or nil;

                items = {};
            }

            local items = cfg.items; do
                items["label"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["label"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.info then
                    items["info"] = library:create("TextLabel", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items["label"];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 17);
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["right_components"] = library:create("Frame", {
                    Parent = items["label"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = items["right_components"];
                    Padding = dim(0, 9);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
            end

            if cfg.seperator then
                library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items["elements"];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            return setmetatable(cfg, library)
        end

        function library:colorpicker(options)
            local cfg = {
                name = options.name or "Color",
                flag = options.flag or library:next_flag(),

                color = options.color or color(1, 1, 1),
                alpha = options.alpha and 1 - options.alpha or 0,

                open = false,
                callback = options.callback or function() end,
                items = {};

                seperator = options.seperator or options.Seperator or false;
            }

            local dragging_sat = false
            local dragging_hue = false
            local dragging_alpha = false

            local h, s, v = cfg.color:ToHSV()
            local a = cfg.alpha

            flags[cfg.flag] = {Color = cfg.color, Transparency = cfg.alpha}

            local label;
            if not self.items.right_components then
                label = self:label({name = cfg.name, seperator = cfg.seperator})
            end

            local items = cfg.items; do
                items["colorpicker"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Parent = label and label.items.right_components or self.items["right_components"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    Size = dim2(0, 16, 0, 16);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(54, 31, 184)
                });

                library:create("UICorner", {
                    Parent = items["colorpicker"];
                    CornerRadius = dim(0, 4)
                });

                items["colorpicker_inline"] = library:create("Frame", {
                    Parent = items["colorpicker"];
                    Size = dim2(1, -2, 1, -2);
                    Name = "\0";
                    BorderMode = Enum.BorderMode.Inset;
                    BorderColor3 = rgb(0, 0, 0);
                    Position = dim2(0, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(54, 31, 184)
                });

                library:create("UICorner", {
                    Parent = items["colorpicker_inline"];
                    CornerRadius = dim(0, 4)
                });

                library:create("UIGradient", {
                    Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))};
                    Parent = items["colorpicker_inline"]
                });

                items["colorpicker_holder"] = library:create("Frame", {
                    Parent = library["other"];
                    Name = "\0";
                    Position = dim2(0.20000000298023224, 20, 0.296999990940094, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 166, 0, 197);
                    BorderSizePixel = 0;
                    Visible = true;
                    BackgroundColor3 = rgb(25, 25, 29)
                });

                items["colorpicker_fade"] = library:create("Frame", {
                    Parent = items["colorpicker_holder"];
                    Name = "\0";
                    BackgroundTransparency = 0;
                    Position = dim2(0, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 1, 0);
                    BorderSizePixel = 0;
                    ZIndex = 100;
                    BackgroundColor3 = rgb(25, 25, 29)
                });

                items["colorpicker_components"] = library:create("Frame", {
                    Parent = items["colorpicker_holder"];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -2, 1, -2);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });

                library:create("UICorner", {
                    Parent = items["colorpicker_components"];
                    CornerRadius = dim(0, 6)
                });

                items["saturation_holder"] = library:create("Frame", {
                    Parent = items["colorpicker_components"];
                    Name = "\0";
                    Position = dim2(0, 7, 0, 7);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -14, 1, -80);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 39, 39)
                });

                items["sat"] = library:create("TextButton", {
                    Parent = items["saturation_holder"];
                    Name = "\0";
                    Size = dim2(1, 0, 1, 0);
                    Text = "";
                    AutoButtonColor = false;
                    BorderColor3 = rgb(0, 0, 0);
                    ZIndex = 2;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UICorner", {
                    Parent = items["sat"];
                    CornerRadius = dim(0, 4)
                });

                library:create("UIGradient", {
                    Rotation = 270;
                    Transparency = numseq{numkey(0, 0), numkey(1, 1)};
                    Parent = items["sat"];
                    Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(0, 0, 0))}
                });

                items["val"] = library:create("Frame", {
                    Name = "\0";
                    Parent = items["saturation_holder"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIGradient", {
                    Parent = items["val"];
                    Transparency = numseq{numkey(0, 0), numkey(1, 1)}
                });

                library:create("UICorner", {
                    Parent = items["val"];
                    CornerRadius = dim(0, 4)
                });

                library:create("UICorner", {
                    Parent = items["saturation_holder"];
                    CornerRadius = dim(0, 4)
                });

                items["satvalpicker"] = library:create("TextButton", {
                    BorderColor3 = rgb(0, 0, 0);
                    AutoButtonColor = false;
                    Text = "";
                    AnchorPoint = vec2(0, 1);
                    Parent = items["saturation_holder"];
                    Name = "\0";
                    Position = dim2(0, 0, 4, 0);
                    Size = dim2(0, 8, 0, 8);
                    ZIndex = 5;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 0, 0)
                });

                library:create("UICorner", {
                    Parent = items["satvalpicker"];
                    CornerRadius = dim(0, 9999)
                });

                library:create("UIStroke", {
                    Color = rgb(255, 255, 255);
                    Parent = items["satvalpicker"];
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                });

                items["hue_gradient"] = library:create("TextButton", {
                    Parent = items["colorpicker_components"];
                    Name = "\0";
                    Position = dim2(0, 10, 1, -64);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -20, 0, 8);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255);
                    AutoButtonColor = false;
                    Text = "";
                });

                library:create("UIGradient", {
                    Color = rgbseq{rgbkey(0, rgb(255, 0, 0)), rgbkey(0.17, rgb(255, 255, 0)), rgbkey(0.33, rgb(0, 255, 0)), rgbkey(0.5, rgb(0, 255, 255)), rgbkey(0.67, rgb(0, 0, 255)), rgbkey(0.83, rgb(255, 0, 255)), rgbkey(1, rgb(255, 0, 0))};
                    Parent = items["hue_gradient"]
                });

                library:create("UICorner", {
                    Parent = items["hue_gradient"];
                    CornerRadius = dim(0, 6)
                });

                items["hue_picker"] = library:create("TextButton", {
                    BorderColor3 = rgb(0, 0, 0);
                    AutoButtonColor = false;
                    Text = "";
                    AnchorPoint = vec2(0, 0.5);
                    Parent = items["hue_gradient"];
                    Name = "\0";
                    Position = dim2(0, 0, 0.5, 0);
                    Size = dim2(0, 8, 0, 8);
                    ZIndex = 5;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 0, 0)
                });

                library:create("UICorner", {
                    Parent = items["hue_picker"];
                    CornerRadius = dim(0, 9999)
                });

                library:create("UIStroke", {
                    Color = rgb(255, 255, 255);
                    Parent = items["hue_picker"];
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                });

                items["alpha_gradient"] = library:create("TextButton", {
                    Parent = items["colorpicker_components"];
                    Name = "\0";
                    Position = dim2(0, 10, 1, -46);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -20, 0, 8);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(25, 25, 29);
                    AutoButtonColor = false;
                    Text = "";
                });

                library:create("UICorner", {
                    Parent = items["alpha_gradient"];
                    CornerRadius = dim(0, 6)
                });

                items["alpha_picker"] = library:create("TextButton", {
                    BorderColor3 = rgb(0, 0, 0);
                    AutoButtonColor = false;
                    Text = "";
                    AnchorPoint = vec2(0, 0.5);
                    Parent = items["alpha_gradient"];
                    Name = "\0";
                    Position = dim2(1, 0, 0.5, 0);
                    Size = dim2(0, 8, 0, 8);
                    ZIndex = 5;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 0, 0)
                });

                library:create("UICorner", {
                    Parent = items["alpha_picker"];
                    CornerRadius = dim(0, 9999)
                });

                library:create("UIStroke", {
                    Color = rgb(255, 255, 255);
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                    Parent = items["alpha_picker"]
                });

                library:create("UIGradient", {
                    Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(255, 255, 255))};
                    Parent = items["alpha_gradient"]
                });

                items["alpha_indicator"] = library:create("ImageLabel", {
                    ScaleType = Enum.ScaleType.Tile;
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items["alpha_gradient"];
                    Image = "rbxassetid://18274452449";
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 1, 0);
                    TileSize = dim2(0, 6, 0, 6);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(0, 0, 0)
                });

                library:create("UIGradient", {
                    Color = rgbseq{rgbkey(0, rgb(112, 112, 112)), rgbkey(1, rgb(255, 0, 0))};
                    Transparency = numseq{numkey(0, 0.8062499761581421), numkey(1, 0)};
                    Parent = items["alpha_indicator"]
                });

                library:create("UICorner", {
                    Parent = items["alpha_indicator"];
                    CornerRadius = dim(0, 6)
                });

                library:create("UIGradient", {
                    Rotation = 90;
                    Parent = items["colorpicker_components"];
                    Color = rgbseq{rgbkey(0, rgb(255, 255, 255)), rgbkey(1, rgb(66, 66, 66))}
                });

                items["input"] = library:create("TextBox", {
                    FontFace = fonts.font;
                    AnchorPoint = vec2(1, 1);
                    Text = "";
                    Parent = items["colorpicker_components"];
                    Name = "\0";
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    BorderSizePixel = 0;
                    PlaceholderColor3 = rgb(255, 255, 255);
                    PlaceholderText = "R, G, B, A";
                    CursorPosition = -1;
                    ClearTextOnFocus = false;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255);
                    TextColor3 = rgb(72, 72, 72);
                    BorderColor3 = rgb(0, 0, 0);
                    Position = dim2(1, -8, 1, -11);
                    Size = dim2(1, -16, 0, 18);
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = items["input"];
                    CornerRadius = dim(0, 3)
                });

                items["UICorenr"] = library:create("UICorner", {
                    Parent = items["colorpicker_holder"];
                    Name = "\0";
                    CornerRadius = dim(0, 4)
                });
            end;

            function cfg.set_visible(bool)
                items["colorpicker_fade"].BackgroundTransparency = 0
                items["colorpicker_holder"].Parent = bool and library["items"] or library["other"]
                items["colorpicker_holder"].Position = dim_offset(items["colorpicker"].AbsolutePosition.X, items["colorpicker"].AbsolutePosition.Y + items["colorpicker"].AbsoluteSize.Y + 45)

                library:tween(items["colorpicker_fade"], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.4)
                library:tween(items["colorpicker_holder"], {Position = items["colorpicker_holder"].Position + dim_offset(0, 20)})

                if not (self.sanity and library.current_open == self and self.open) then
                    library:close_element(cfg)
                end
            end

            function cfg.set(color, alpha)
                if type(color) == "boolean" then
                    return
                end

                if color then
                    h, s, v = color:ToHSV()
                end

                if alpha then
                    a = alpha
                end

                local Color = hsv(h, s, v)

                library:tween(items["hue_picker"], {Position = dim2(0, (items["hue_gradient"].AbsoluteSize.X - items["hue_picker"].AbsoluteSize.X) * h, 0.5, 0)}, Enum.EasingStyle.Linear, 0.05)
                library:tween(items["alpha_picker"], {Position = dim2(0, (items["alpha_gradient"].AbsoluteSize.X - items["alpha_picker"].AbsoluteSize.X) * (1 - a), 0.5, 0)}, Enum.EasingStyle.Linear, 0.05)
                library:tween(items["satvalpicker"], {Position = dim2(0, s * (items["saturation_holder"].AbsoluteSize.X - items["satvalpicker"].AbsoluteSize.X), 1, 1 - v * (items["saturation_holder"].AbsoluteSize.Y - items["satvalpicker"].AbsoluteSize.Y))}, Enum.EasingStyle.Linear, 0.05)

                items["alpha_indicator"]:FindFirstChildOfClass("UIGradient").Color = rgbseq{rgbkey(0, rgb(112, 112, 112)), rgbkey(1, hsv(h, 1, 1))};

                items["colorpicker"].BackgroundColor3 = Color
                items["colorpicker_inline"].BackgroundColor3 = Color
                items["saturation_holder"].BackgroundColor3 = hsv(h, 1, 1)

                items["hue_picker"].BackgroundColor3 = hsv(h, 1, 1)
                items["alpha_picker"].BackgroundColor3 = hsv(h, 1, 1 - a)
                items["satvalpicker"].BackgroundColor3 = hsv(h, s, v)

                flags[cfg.flag] = {
                    Color = Color;
                    Transparency = a
                }

                local color = items["colorpicker"].BackgroundColor3
                items["input"].Text = string.format("%s, %s, %s, ", library:round(color.R * 255), library:round(color.G * 255), library:round(color.B * 255))
                items["input"].Text ..= library:round(1 - a, 0.01)

                cfg.callback(Color, a)
            end

            function cfg.update_color()
                local mouse = uis:GetMouseLocation()
                local offset = vec2(mouse.X, mouse.Y - gui_offset)

                if dragging_sat then
                    s = math.clamp((offset - items["sat"].AbsolutePosition).X / items["sat"].AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((offset - items["sat"].AbsolutePosition).Y / items["sat"].AbsoluteSize.Y, 0, 1)
                elseif dragging_hue then
                    h = math.clamp((offset - items["hue_gradient"].AbsolutePosition).X / items["hue_gradient"].AbsoluteSize.X, 0, 1)
                elseif dragging_alpha then
                    a = 1 - math.clamp((offset - items["alpha_gradient"].AbsolutePosition).X / items["alpha_gradient"].AbsoluteSize.X, 0, 1)
                end

                cfg.set()
            end

            items["colorpicker"].MouseButton1Click:Connect(function()
                cfg.open = not cfg.open

                cfg.set_visible(cfg.open)
            end)

            uis.InputChanged:Connect(function(input)
                if (dragging_sat or dragging_hue or dragging_alpha) and input.UserInputType == Enum.UserInputType.MouseMovement then
                    cfg.update_color()
                end
            end)

            library:connection(uis.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging_sat = false
                    dragging_hue = false
                    dragging_alpha = false
                end
            end)

            items["alpha_gradient"].MouseButton1Down:Connect(function()
                dragging_alpha = true
            end)

            items["hue_gradient"].MouseButton1Down:Connect(function()
                dragging_hue = true
            end)

            items["sat"].MouseButton1Down:Connect(function()
                dragging_sat = true
            end)

            items["input"].FocusLost:Connect(function()
                local text = items["input"].Text
                local r, g, b, a = library:convert(text)

                if r and g and b and a then
                    cfg.set(rgb(r, g, b), 1 - a)
                end
            end)

            items["input"].Focused:Connect(function()
                library:tween(items["input"], {TextColor3 = rgb(245, 245, 245)})
            end)

            items["input"].FocusLost:Connect(function()
                library:tween(items["input"], {TextColor3 = rgb(72, 72, 72)})
            end)

            cfg.set(cfg.color, cfg.alpha)
            config_flags[cfg.flag] = cfg.set

            return setmetatable(cfg, library)
        end

        function library:textbox(options)
            local cfg = {
                name = options.name or "TextBox",
                placeholder = options.placeholder or options.placeholdertext or options.holder or options.holdertext or "type here...",
                default = options.default or "",
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end,
                visible = options.visible or true,
                items = {};
            }

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items["textbox"] = library:create("TextButton", {
                    LayoutOrder = -1;
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["textbox"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["right_components"] = library:create("Frame", {
                    Parent = items["textbox"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 4, 0, 19);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    Parent = items["right_components"];
                    Padding = dim(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    FillDirection = Enum.FillDirection.Horizontal
                });

                items["input"] = library:create("TextBox", {
                    FontFace = fonts.font;
                    Text = "";
                    Parent = items["right_components"];
                    Name = "\0";
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    BorderSizePixel = 0;
                    PlaceholderColor3 = rgb(255, 255, 255);
                    PlaceholderText = cfg.placeholder;
                    CursorPosition = -1;
                    ClearTextOnFocus = false;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255);
                    TextColor3 = rgb(72, 72, 72);
                    BorderColor3 = rgb(0, 0, 0);
                    Position = dim2(1, 0, 0, 0);
                    Size = dim2(1, -4, 0, 30);
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = items["input"];
                    CornerRadius = dim(0, 3)
                });

                library:create("UIPadding", {
                    Parent = items["right_components"];
                    PaddingTop = dim(0, 4);
                    PaddingRight = dim(0, 4)
                });
            end

            function cfg.set(text)
                flags[cfg.flag] = text

                items["input"].Text = text

                cfg.callback(text)
            end

            items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
                cfg.set(items["input"].Text)
            end)

            items["input"].Focused:Connect(function()
                library:tween(items["input"], {TextColor3 = rgb(245, 245, 245)})
            end)

            items["input"].FocusLost:Connect(function()
                library:tween(items["input"], {TextColor3 = rgb(72, 72, 72)})
            end)

            if cfg.default then
                cfg.set(cfg.default)
            end

            config_flags[cfg.flag] = cfg.set

            return setmetatable(cfg, library)
        end

        function library:keybind(options)
            local cfg = {
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end,
                name = options.name or nil,
                ignore_key = options.ignore or false,

                key = options.key or nil,
                mode = options.mode or "Toggle",
                active = options.default or false,

                open = false,
                binding = nil,

                hold_instances = {},
                items = {};
            }

            flags[cfg.flag] = {
                mode = cfg.mode,
                key = cfg.key,
                active = cfg.active
            }

            local items = cfg.items; do
                items["keybind_element"] = library:create("TextButton", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["keybind_element"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["right_components"] = library:create("Frame", {
                    Parent = items["keybind_element"];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = items["right_components"];
                    Padding = dim(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                items["keybind_holder"] = library:create("TextButton", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = items["right_components"];
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Size = dim2(0, 0, 0, 16);
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.X;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = items["keybind_holder"];
                    CornerRadius = dim(0, 4)
                });

                items["key"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(86, 86, 87);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "LSHIFT";
                    Parent = items["keybind_holder"];
                    Name = "\0";
                    Size = dim2(1, -12, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["key"];
                    PaddingTop = dim(0, 1);
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                items["dropdown"] = library:create("Frame", {
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = library.items;
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 0, 0, 0);
                    Size = dim2(0, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.X;
                    BackgroundColor3 = rgb(0, 0, 0)
                });

                items["inline"] = library:create("Frame", {
                    Parent = items["dropdown"];
                    Size = dim2(1, 0, 1, 0);
                    Name = "\0";
                    ClipsDescendants = true;
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });

                library:create("UIPadding", {
                    PaddingBottom = dim(0, 6);
                    PaddingTop = dim(0, 3);
                    PaddingLeft = dim(0, 3);
                    Parent = items["inline"]
                });

                library:create("UIListLayout", {
                    Parent = items["inline"];
                    Padding = dim(0, 5);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create("UICorner", {
                    Parent = items["inline"];
                    CornerRadius = dim(0, 4)
                });

                local options = {"Hold", "Toggle", "Always"}

                cfg.y_size = 20
                for _, option in options do
                    local name = library:create("TextButton", {
                        FontFace = fonts.font;
                        TextColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = option;
                        Parent = items["inline"];
                        Name = "\0";
                        Size = dim2(0, 0, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    }); cfg.hold_instances[option] = name
                    library:apply_theme(name, "accent", "TextColor3")

                    cfg.y_size += name.AbsoluteSize.Y

                    library:create("UIPadding", {
                        Parent = name;
                        PaddingTop = dim(0, 1);
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });

                    name.MouseButton1Click:Connect(function()
                        cfg.set(option)

                        cfg.set_visible(false)

                        cfg.open = false
                    end)
                end
            end

            function cfg.modify_mode_color(path)
                for _, v in cfg.hold_instances do
                    v.TextColor3 = rgb(72, 72, 72)
                end

                cfg.hold_instances[path].TextColor3 = themes.preset.accent
            end

            function cfg.set_mode(mode)
                cfg.mode = mode

                if mode == "Always" then
                    cfg.set(true)
                elseif mode == "Hold" then
                    cfg.set(false)
                end

                flags[cfg.flag]["mode"] = mode
                cfg.modify_mode_color(mode)
            end

            function cfg.set(input)
                if type(input) == "boolean" then
                    cfg.active = input

                    if cfg.mode == "Always" then
                        cfg.active = true
                    end
                elseif tostring(input):find("Enum") then
                    input = input.Name == "Escape" and "NONE" or input

                    cfg.key = input or "NONE"
                elseif find({"Toggle", "Hold", "Always"}, input) then
                    if input == "Always" then
                        cfg.active = true
                    end

                    cfg.mode = input
                    cfg.set_mode(cfg.mode)
                elseif type(input) == "table" then
                    input.key = type(input.key) == "string" and input.key ~= "NONE" and library:convert_enum(input.key) or input.key
                    input.key = input.key == Enum.KeyCode.Escape and "NONE" or input.key

                    cfg.key = input.key or "NONE"
                    cfg.mode = input.mode or "Toggle"

                    if input.active then
                        cfg.active = input.active
                    end

                    cfg.set_mode(cfg.mode)
                end

                cfg.callback(cfg.active)

                local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
                local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))

                items["key"].Text = __text

                flags[cfg.flag] = {
                    mode = cfg.mode,
                    key = cfg.key,
                    active = cfg.active
                }
            end

            function cfg.set_visible(bool)
                local size = bool and cfg.y_size or 0
                library:tween(items["dropdown"], {Size = dim_offset(items["keybind_holder"].AbsoluteSize.X, size)})

                items["dropdown"].Position = dim_offset(items["keybind_holder"].AbsolutePosition.X, items["keybind_holder"].AbsolutePosition.Y + items["keybind_holder"].AbsoluteSize.Y + 60)
            end

            items["keybind_holder"].MouseButton1Down:Connect(function()
                task.wait()
                items["key"].Text = "..."

                cfg.binding = library:connection(uis.InputBegan, function(keycode, game_event)
                    cfg.set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)

                    cfg.binding:Disconnect()
                    cfg.binding = nil
                end)
            end)

            items["keybind_holder"].MouseButton2Down:Connect(function()
                cfg.open = not cfg.open

                cfg.set_visible(cfg.open)
            end)

            library:connection(uis.InputBegan, function(input, game_event)
                if not game_event then
                    local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

                    if selected_key == cfg.key then
                        if cfg.mode == "Toggle" then
                            cfg.active = not cfg.active
                            cfg.set(cfg.active)
                        elseif cfg.mode == "Hold" then
                            cfg.set(true)
                        end
                    end
                end
            end)

            library:connection(uis.InputEnded, function(input, game_event)
                if game_event then
                    return
                end

                local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

                if selected_key == cfg.key then
                    if cfg.mode == "Hold" then
                        cfg.set(false)
                    end
                end
            end)

            cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})
            config_flags[cfg.flag] = cfg.set

            return setmetatable(cfg, library)
        end

        function library:button(options)
            local cfg = {
                name = options.name or "TextBox",
                callback = options.callback or function() end,
                items = {};
            }

            local items = cfg.items; do
                items["button_element"] = library:create("Frame", {
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["button"] = library:create("TextButton", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Parent = items["button_element"];
                    Name = "\0";
                    Position = dim2(1, -4, 0, 0);
                    Size = dim2(1, -8, 0, 30);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = items["button"];
                    CornerRadius = dim(0, 3)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["button"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 1, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
            end

            items["button"].MouseButton1Click:Connect(function()
                cfg.callback()

                items["name"].TextColor3 = themes.preset.accent
                library:tween(items["name"], {TextColor3 = rgb(245, 245, 245)})
            end)

            return setmetatable(cfg, library)
        end

        function library:settings(options)
            local cfg = {
                open = false;
                items = {};
                sanity = true;
            }

            local items = cfg.items; do
                items["outline"] = library:create("Frame", {
                    Name = "\0";
                    Visible = true;
                    Parent = library["items"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 0, 0);
                    ClipsDescendants = true;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(25, 25, 29)
                });

                items["inline"] = library:create("Frame", {
                    Parent = items["outline"];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -2, 1, -2);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });

                library:create("UICorner", {
                    Parent = items["inline"];
                    CornerRadius = dim(0, 7)
                });

                items["elements"] = library:create("Frame", {
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items["inline"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 10, 0, 10);
                    Size = dim2(1, -20, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    Parent = items["elements"];
                    Padding = dim(0, 10);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create("UIPadding", {
                    PaddingBottom = dim(0, 15);
                    Parent = items["elements"]
                });

                library:create("UICorner", {
                    Parent = items["outline"];
                    CornerRadius = dim(0, 7)
                });

                library:create("UICorner", {
                    Parent = items["fade"];
                    CornerRadius = dim(0, 7)
                });

                items["tick"] = library:create("ImageButton", {
                    Image = "rbxassetid://128797200442698";
                    Name = "\0";
                    AutoButtonColor = false;
                    Parent = self.items["right_components"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 16, 0, 16);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
            end

            function cfg.set_visible(bool)
                library:tween(items["outline"], {Size = dim_offset(bool and 240 or 0, 0)})
                items["outline"].Position = dim_offset(items["tick"].AbsolutePosition.X, items["tick"].AbsolutePosition.Y + 90)
                library:close_element(cfg)
            end

            items["tick"].MouseButton1Click:Connect(function()
                cfg.open = not cfg.open

                cfg.set_visible(cfg.open)
            end)

            return setmetatable(cfg, library)
        end

        function library:list(properties)
            local cfg = {
                items = {};
                options = properties.options or {"1", "2", "3"};
                flag = properties.flag or library:next_flag();
                callback = properties.callback or function() end;
                data_store = {};
                current_element;
            }

            local items = cfg.items; do
                items["list"] = library:create("Frame", {
                    Parent = self.items["elements"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIListLayout", {
                    Parent = items["list"];
                    Padding = dim(0, 10);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create("UIPadding", {
                    Parent = items["list"];
                    PaddingRight = dim(0, 4);
                    PaddingLeft = dim(0, 4)
                });
            end

            function cfg.refresh_options(options_to_refresh)
                for _,option in cfg.data_store do
                    option:Destroy()
                end

                for _, option_data in options_to_refresh do
                    local button = library:create("TextButton", {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        AutoButtonColor = false;
                        AnchorPoint = vec2(1, 0);
                        Parent = items["list"];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        Size = dim2(1, 0, 0, 30);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(33, 33, 35)
                    }); cfg.data_store[#cfg.data_store + 1] = button;

                    local name = library:create("TextLabel", {
                        FontFace = fonts.font;
                        TextColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = option_data;
                        Parent = button;
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create("UICorner", {
                        Parent = button;
                        CornerRadius = dim(0, 3)
                    });

                    button.MouseButton1Click:Connect(function()
                        local current = cfg.current_element
                        if current and current ~= name then
                            library:tween(current, {TextColor3 = rgb(72, 72, 72)})
                        end

                        flags[cfg.flag] = option_data
                        cfg.callback(option_data)
                        library:tween(name, {TextColor3 = rgb(245, 245, 245)})
                        cfg.current_element = name
                    end)

                    name.MouseEnter:Connect(function()
                        if cfg.current_element == name then
                            return
                        end

                        library:tween(name, {TextColor3 = rgb(140, 140, 140)})
                    end)

                    name.MouseLeave:Connect(function()
                        if cfg.current_element == name then
                            return
                        end

                        library:tween(name, {TextColor3 = rgb(72, 72, 72)})
                    end)
                end
            end

            cfg.refresh_options(cfg.options)

            return setmetatable(cfg, library)
        end

        function library:init_config(window)
            window:seperator({name = "Settings"})
            local main = window:tab({name = "Configs", tabs = {"Main"}})

            local column = main:column({})
            local section = column:section({name = "Configs", size = 1, default = true, icon = "rbxassetid://139628202576511"})
            config_holder = section:list({options = {"Report", "This", "Error", "To", "Finobe"}, callback = function(option) end, flag = "config_name_list"}); library:update_config_list()

            local column = main:column({})
            local section = column:section({name = "Settings", side = "right", size = 1, default = true, icon = "rbxassetid://129380150574313"})
            section:textbox({name = "Config name:", flag = "config_name_text"})
            section:button({name = "Save", callback = function() local n = flags["config_name_text"] and flags["config_name_text"]~="" and flags["config_name_text"] or flags["config_name_list"]; if not n or n=="<no configs>" then n="default" end; local p = library.directory.."/configs/"..n..".cfg"; local ok,err=pcall(writefile, p, library:get_config()); if ok then library:update_config_list() notifications:create_notification({name="Configs", info="Saved: "..n, type="success"}) else notifications:create_notification({name="Configs", info="Save failed", type="error"}) end end})
            section:button({name = "Load", callback = function() local n=flags["config_name_list"]; if not n or n=="<no configs>" then return end; local p=library.directory.."/configs/"..n..".cfg"; local ok, data=pcall(readfile, p); if ok and data then pcall(function() library:load_config(data) end) notifications:create_notification({name="Configs", info="Loaded: "..n, type="success"}) else notifications:create_notification({name="Configs", info="Load failed", type="error"}) end end})
            section:button({name = "Delete", callback = function() local n=flags["config_name_list"]; if not n or n=="<no configs>" then return end; pcall(delfile, library.directory.."/configs/"..n..".cfg"); library:update_config_list() notifications:create_notification({name="Configs", info="Deleted: "..n, type="warn"}) end})
            section:colorpicker({name = "Menu Accent", callback = function(color, alpha) library:update_theme("accent", color) end, color = themes.preset.accent})
            section:keybind({name = "Menu Bind", callback = function(bool) window.toggle_menu(bool) end, default = true})
        end
    --

    -- ============================================================
    --   V2 NEW ELEMENTS
    -- ============================================================

        -- Player list - auto-pulls from game.Players, no dropdown refresh needed
        function library:player_list(options)
            options = options or {}
            local cfg = {
                name = options.name or "Player List",
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end,
                include_self = options.include_self ~= false,
                max_height = options.max_height or 200,
                items = {},
                player_buttons = {},
                current_selection = nil,
            }

            flags[cfg.flag] = cfg.current_selection

            local items = cfg.items; do
                items["list_object"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["list_object"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    Parent = items["name"];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                -- Scrolling container for player rows
                items["scroll"] = library:create("ScrollingFrame", {
                    ScrollBarImageColor3 = rgb(44, 44, 46);
                    Active = true;
                    AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    ScrollBarThickness = 2;
                    BorderSizePixel = 0;
                    BorderColor3 = rgb(0, 0, 0);
                    CanvasSize = dim2(0, 0, 0, 0);
                    Parent = items["list_object"];
                    Name = "\0";
                    BackgroundColor3 = rgb(22, 22, 24);
                    Size = dim2(1, 0, 0, cfg.max_height);
                    Position = dim2(0, 0, 0, 22);
                });

                library:create("UICorner", {
                    Parent = items["scroll"];
                    CornerRadius = dim(0, 6)
                });

                library:create("UIPadding", {
                    PaddingTop = dim(0, 4);
                    PaddingBottom = dim(0, 4);
                    Parent = items["scroll"]
                });

                library:create("UIListLayout", {
                    Parent = items["scroll"];
                    Padding = dim(0, 4);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center
                });

                library:create("UIPadding", {
                    PaddingRight = dim(0, 4);
                    PaddingLeft = dim(0, 4);
                    Parent = items["scroll"]
                });
            end

            local function make_row(player)
                local row = library:create("TextButton", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    Parent = items["scroll"];
                    Name = player.Name;
                    Size = dim2(1, 0, 0, 30);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create("UICorner", {
                    Parent = row;
                    CornerRadius = dim(0, 5)
                });

                local headshot_size = 22
                local avatar = library:create("ImageLabel", {
                    Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", player.UserId);
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = row;
                    Name = "\0";
                    BackgroundColor3 = rgb(0, 0, 0);
                    Size = dim2(0, headshot_size, 0, headshot_size);
                    Position = dim2(0, 4, 0.5, 0);
                    AnchorPoint = vec2(0, 0.5);
                    BorderSizePixel = 0;
                });

                library:create("UICorner", {
                    Parent = avatar;
                    CornerRadius = dim(0, 999)
                });

                local display_name = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = player.DisplayName;
                    Parent = row;
                    Name = "\0";
                    Size = dim2(1, -60, 1, 0);
                    Position = dim2(0, 32, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    TextSize = 13;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                local pcount = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "@" .. player.Name;
                    Parent = row;
                    Name = "\0";
                    Size = dim2(0, 0, 1, 0);
                    AnchorPoint = vec2(1, 0);
                    Position = dim2(1, -6, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    AutomaticSize = Enum.AutomaticSize.X;
                    BorderSizePixel = 0;
                    TextSize = 11;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                row.MouseButton1Click:Connect(function()
                    for _, b in cfg.player_buttons do
                        if b and b.Parent then
                            library:tween(b, {BackgroundColor3 = rgb(33, 33, 35)})
                        end
                    end
                    cfg.current_selection = player
                    flags[cfg.flag] = player
                    library:tween(row, {BackgroundColor3 = themes.preset.accent})
                    cfg.callback(player)
                end)

                row.MouseEnter:Connect(function()
                    if cfg.current_selection ~= player then
                        library:tween(row, {BackgroundColor3 = rgb(45, 45, 48)})
                    end
                end)

                row.MouseLeave:Connect(function()
                    if cfg.current_selection ~= player then
                        library:tween(row, {BackgroundColor3 = rgb(33, 33, 35)})
                    end
                end)

                return row
            end

            local function refresh()
                -- clear existing rows
                for _, b in cfg.player_buttons do
                    if b and b.Parent then
                        b:Destroy()
                    end
                end
                cfg.player_buttons = {}

                local list = {}
                for _, p in players:GetPlayers() do
                    if p ~= lp or cfg.include_self then
                        list[#list + 1] = p
                    end
                end
                table.sort(list, function(a, b)
                    return a.DisplayName:lower() < b.DisplayName:lower()
                end)

                for _, p in list do
                    cfg.player_buttons[#cfg.player_buttons + 1] = make_row(p)
                end
            end

            refresh()

            -- auto-refresh when players join/leave
            library:connection(players.PlayerAdded, refresh)
            library:connection(players.PlayerRemoving, function(leaving)
                refresh()
                if cfg.current_selection == leaving then
                    cfg.current_selection = nil
                    flags[cfg.flag] = nil
                end
            end)

            cfg.refresh = refresh
            return setmetatable(cfg, library)
        end

        -- Search bar - filters a list/dropdown
        function library:search(options)
            options = options or {}
            local cfg = {
                name = options.name or "Search",
                placeholder = options.placeholder or "search...",
                flag = options.flag or library:next_flag(),
                target = options.target, -- a list cfg with refresh_options
                items = {},
            }

            flags[cfg.flag] = ""

            local items = cfg.items; do
                items["search_object"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["search_object"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["input"] = library:create("TextBox", {
                    FontFace = fonts.font;
                    Text = "";
                    Parent = items["search_object"];
                    Name = "\0";
                    PlaceholderText = cfg.placeholder;
                    PlaceholderColor3 = rgb(110, 110, 112);
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    BorderSizePixel = 0;
                    CursorPosition = -1;
                    ClearTextOnFocus = false;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35);
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Position = dim2(0, 0, 0, 22);
                    Size = dim2(1, 0, 0, 28);
                });

                library:create("UICorner", {
                    Parent = items["input"];
                    CornerRadius = dim(0, 5)
                });
            end

            local original_options
            if cfg.target and cfg.target.options then
                original_options = cfg.target.options
            end

            items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
                local query = items["input"].Text:lower()
                flags[cfg.flag] = items["input"].Text

                if cfg.target and original_options and cfg.target.refresh_options then
                    if query == "" then
                        cfg.target.refresh_options(original_options)
                    else
                        local filtered = {}
                        for _, opt in original_options do
                            if tostring(opt):lower():find(query, 1, true) then
                                filtered[#filtered + 1] = opt
                            end
                        end
                        cfg.target.refresh_options(filtered)
                    end
                end
            end)

            return setmetatable(cfg, library)
        end

        -- Watermark - small draggable badge in the corner
        function library:watermark(options)
            options = options or {}
            local cfg = {
                text = options.text or options.Text or "milenium v2",
                sub = options.sub or "v2.0",
                visible = true,
                items = {},
            }

            local items = cfg.items; do
                items["outline"] = library:create("Frame", {
                    Parent = library["items"];
                    Position = dim2(0, 10, 0, 10);
                    Size = dim2(0, 0, 0, 30);
                    AutomaticSize = Enum.AutomaticSize.X;
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16);
                });
                library:create("UICorner", {Parent = items["outline"]; CornerRadius = dim(0, 6)});
                library:create("UIStroke", {Color = rgb(23, 23, 29); Parent = items["outline"]});

                items["accent_bar"] = library:create("Frame", {
                    Parent = items["outline"];
                    Position = dim2(0, 0, 0, 0);
                    Size = dim2(0, 4, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = themes.preset.accent;
                });
                library:create("UICorner", {Parent = items["accent_bar"]; CornerRadius = dim(0, 6)});
                library:apply_theme(items["accent_bar"], "accent", "BackgroundColor3");

                items["label"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.text;
                    Parent = items["outline"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(0, 0, 1, 0);
                    AutomaticSize = Enum.AutomaticSize.X;
                    Position = dim2(0, 12, 0, 0);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                library:create("UIPadding", {Parent = items["label"]; PaddingRight = dim(0, 8); PaddingTop = dim(0, 1); PaddingBottom = dim(0, 1)});

                items["sub_label"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.sub;
                    Parent = items["outline"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(0, 0, 1, 0);
                    AutomaticSize = Enum.AutomaticSize.X;
                    Position = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    TextSize = 12;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                library:create("UIPadding", {Parent = items["sub_label"]; PaddingRight = dim(0, 10); PaddingLeft = dim(0, 4); PaddingTop = dim(0, 1); PaddingBottom = dim(0, 1)});

                -- fps / ping update
                items["info_label"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "0 fps | 0 ms";
                    Parent = items["outline"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(0, 0, 1, 0);
                    AutomaticSize = Enum.AutomaticSize.X;
                    Position = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    TextSize = 11;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
            end

            library:draggify(items["outline"])

            -- Live update fps/ping
            local last_fps, last_ping, acc = 0, 0, 0
            local frames = 0
            library:connection(run.RenderStepped, function(dt)
                frames = frames + 1
                acc = acc + dt
                if acc >= 0.5 then
                    last_fps = math.floor(frames / acc)
                    frames = 0
                    acc = 0
                    pcall(function()
                        last_ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                    end)
                    items["info_label"].Text = string.format("%d fps | %d ms", last_fps, last_ping)
                end
            end)

            function cfg.set_text(text, sub)
                items["label"].Text = text or items["label"].Text
                if sub then items["sub_label"].Text = sub end
            end

            function cfg.set_visible(bool)
                cfg.visible = bool
                items["outline"].Visible = bool
            end

            return setmetatable(cfg, library)
        end

        -- Keybind list - shows active keybinds in a floating panel
        function library:keybind_list()
            local cfg = {
                items = {},
                tracked = {},
            }

            local items = cfg.items; do
                items["outline"] = library:create("Frame", {
                    Parent = library["items"];
                    Position = dim2(1, -220, 0, 10);
                    Size = dim2(0, 210, 0, 30);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16);
                });
                library:create("UICorner", {Parent = items["outline"]; CornerRadius = dim(0, 6)});
                library:create("UIStroke", {Color = rgb(23, 23, 29); Parent = items["outline"]});

                items["title"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    Text = "Keybinds";
                    Parent = items["outline"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 26);
                    Position = dim2(0, 10, 0, 0);
                    BorderSizePixel = 0;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextSize = 13;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["list"] = library:create("Frame", {
                    Parent = items["outline"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    Position = dim2(0, 0, 0, 28);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255);
                });
                library:create("UIListLayout", {Parent = items["list"]; Padding = dim(0, 2); SortOrder = Enum.SortOrder.LayoutOrder});
                library:create("UIPadding", {Parent = items["list"]; PaddingTop = dim(0, 4); PaddingBottom = dim(0, 6); PaddingLeft = dim(0, 6); PaddingRight = dim(0, 6)});
            end

            library:draggify(items["outline"])

            -- Watch flag changes for keybinds (flag.key/active)
            -- We add a connection set for users to register keybinds
            function cfg.track(name, get_active, get_key)
                cfg.tracked[#cfg.tracked + 1] = {name = name, get_active = get_active, get_key = get_key, row = nil}
            end

            function cfg.refresh()
                -- clear rows (keep title)
                for _, child in items["list"]:GetChildren() do
                    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                        child:Destroy()
                    end
                end

                for _, entry in cfg.tracked do
                    local active = entry.get_active and entry.get_active() or false
                    local key = entry.get_key and entry.get_key() or "?"

                    if key and key ~= "NONE" and tostring(key) ~= "Enums" then
                        local row = library:create("TextLabel", {
                            FontFace = fonts.font;
                            TextColor3 = active and themes.preset.accent or rgb(86, 86, 87);
                            Text = string.format("[%s] %s", tostring(key):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", ""), entry.name);
                            Parent = items["list"];
                            Name = "\0";
                            BackgroundTransparency = 1;
                            Size = dim2(1, 0, 0, 16);
                            TextXAlignment = Enum.TextXAlignment.Left;
                            TextSize = 12;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                    end
                end
            end

            -- auto-refresh every 0.25s
            task.spawn(function()
                while library and library.items and items["outline"] and items["outline"].Parent do
                    cfg.refresh()
                    task.wait(0.25)
                end
            end)

            return setmetatable(cfg, library)
        end

        -- Hotbar - compact floating button strip
        function library:hotbar(options)
            options = options or {}
            local cfg = {
                items = {},
                buttons = {},
                default_position = options.position or dim2(0.5, 0, 0, 10),
            }

            local items = cfg.items; do
                items["outline"] = library:create("Frame", {
                    Parent = library["items"];
                    Position = cfg.default_position;
                    AnchorPoint = vec2(0.5, 0);
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16);
                });
                library:create("UICorner", {Parent = items["outline"]; CornerRadius = dim(0, 8)});
                library:create("UIStroke", {Color = rgb(23, 23, 29); Parent = items["outline"]});

                items["list"] = library:create("Frame", {
                    Parent = items["outline"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255);
                });
                library:create("UIListLayout", {Parent = items["list"]; Padding = dim(0, 6); FillDirection = Enum.FillDirection.Horizontal; SortOrder = Enum.SortOrder.LayoutOrder});
                library:create("UIPadding", {Parent = items["list"]; PaddingTop = dim(0, 6); PaddingBottom = dim(0, 6); PaddingLeft = dim(0, 6); PaddingRight = dim(0, 6)});
            end

            library:draggify(items["outline"])

            function cfg.add_button(btn_options)
                local btn_cfg = {
                    name = btn_options.name or "Button",
                    icon = btn_options.icon or nil,
                    active = btn_options.active or false,
                    callback = btn_options.callback or function() end,
                }

                local btn = library:create("TextButton", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = btn_cfg.name;
                    AutoButtonColor = false;
                    Parent = items["list"];
                    Name = "\0";
                    Size = dim2(0, btn_options.width or 30, 0, 30);
                    BorderSizePixel = 0;
                    TextSize = 11;
                    BackgroundColor3 = rgb(33, 33, 35)
                });
                library:create("UICorner", {Parent = btn; CornerRadius = dim(0, 5)});

                btn.MouseButton1Click:Connect(function()
                    btn_cfg.active = not btn_cfg.active
                    library:tween(btn, {BackgroundColor3 = btn_cfg.active and themes.preset.accent or rgb(33, 33, 35)})
                    library:tween(btn, {TextColor3 = btn_cfg.active and rgb(255, 255, 255) or rgb(245, 245, 245)})
                    btn_cfg.callback(btn_cfg.active)
                end)

                cfg.buttons[#cfg.buttons + 1] = btn
                return btn_cfg
            end

            function cfg.set_visible(bool)
                items["outline"].Visible = bool
            end

            return setmetatable(cfg, library)
        end

        -- Badge - small status pill (great with toggles)
        function library:badge(options)
            options = options or {}
            local cfg = {
                text = options.text or options.Text or "NEW",
                color = options.color or rgb(155, 150, 219),
                items = {},
            }

            local items = cfg.items; do
                items["label_object"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = options.name or "Status";
                    Parent = items["label_object"];
                    Name = "\0";
                    Size = dim2(1, -50, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["badge"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.text;
                    Parent = items["label_object"];
                    AnchorPoint = vec2(1, 0);
                    Name = "\0";
                    Size = dim2(0, 0, 0, 18);
                    Position = dim2(1, -4, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.X;
                    BorderSizePixel = 0;
                    TextSize = 11;
                    BackgroundColor3 = cfg.color
                });
                library:create("UICorner", {Parent = items["badge"]; CornerRadius = dim(0, 999)});
                library:create("UIPadding", {Parent = items["badge"]; PaddingLeft = dim(0, 6); PaddingRight = dim(0, 6); PaddingTop = dim(0, 2); PaddingBottom = dim(0, 2)});
            end

            function cfg.set_text(text)
                items["badge"].Text = text
            end

            return setmetatable(cfg, library)
        end

        -- Progress bar - animated progress
        function library:progress_bar(options)
            options = options or {}
            local cfg = {
                name = options.name or "Progress",
                min = options.min or 0,
                max = options.max or 100,
                value = options.value or options.default or 0,
                smoothing = options.smoothing or 0.2,
                callback = options.callback or function() end,
                items = {},
            }

            local items = cfg.items; do
                items["bar_object"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["bar_object"];
                    Name = "\0";
                    Size = dim2(0.5, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["value"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "0%";
                    Parent = items["bar_object"];
                    Name = "\0";
                    Size = dim2(0.5, 0, 0, 0);
                    AnchorPoint = vec2(1, 0);
                    Position = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["track"] = library:create("Frame", {
                    Parent = items["bar_object"];
                    BorderColor3 = rgb(0, 0, 0);
                    Position = dim2(0, 0, 0, 24);
                    Size = dim2(1, 0, 0, 6);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(33, 33, 35)
                });
                library:create("UICorner", {Parent = items["track"]; CornerRadius = dim(0, 999)});

                items["fill"] = library:create("Frame", {
                    Parent = items["track"];
                    BorderSizePixel = 0;
                    Size = dim2(0, 0, 1, 0);
                    BackgroundColor3 = themes.preset.accent
                });
                library:create("UICorner", {Parent = items["fill"]; CornerRadius = dim(0, 999)});
                library:apply_theme(items["fill"], "accent", "BackgroundColor3");

                items["shine"] = library:create("Frame", {
                    Parent = items["fill"];
                    AnchorPoint = vec2(0, 0.5);
                    Position = dim2(1, -10, 0.5, 0);
                    Size = dim2(0, 20, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255);
                    BackgroundTransparency = 0.7;
                });
                library:create("UICorner", {Parent = items["shine"]; CornerRadius = dim(0, 999)});
            end

            function cfg.set(value)
                cfg.value = clamp(value, cfg.min, cfg.max)
                local ratio = (cfg.value - cfg.min) / (cfg.max - cfg.min)
                library:tween(items["fill"], {Size = dim2(ratio, 0, 1, 0)}, Enum.EasingStyle.Quint, cfg.smoothing)
                items["value"].Text = string.format("%d / %d", cfg.value, cfg.max)
                cfg.callback(cfg.value)
            end

            cfg.set(cfg.value)

            function cfg.set_color(color)
                items["fill"].BackgroundColor3 = color
            end

            return setmetatable(cfg, library)
        end

        -- Divider - just a line
        function library:divider(options)
            options = options or {}
            local cfg = {
                items = {},
            }

            local items = cfg.items; do
                items["container"] = library:create("Frame", {
                    Parent = self.items["elements"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 0, options.height or 16);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["line"] = library:create("Frame", {
                    Parent = items["container"];
                    AnchorPoint = vec2(0.5, 0.5);
                    Position = dim2(0.5, 0, 0.5, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -20, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            return setmetatable(cfg, library)
        end

        -- Player card - rich player info (avatar + name + role + actions)
        function library:player_card(options)
            options = options or {}
            local cfg = {
                player = options.player or lp,
                name = options.name or options.player and options.player.DisplayName or "Player",
                role = options.role or "User",
                accent = options.accent or themes.preset.accent,
                items = {},
            }

            local items = cfg.items; do
                items["card"] = library:create("Frame", {
                    Parent = self.items["elements"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["bg"] = library:create("Frame", {
                    Parent = items["card"];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 50);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });
                library:create("UICorner", {Parent = items["bg"]; CornerRadius = dim(0, 7)});

                items["accent_line"] = library:create("Frame", {
                    Parent = items["bg"];
                    Position = dim2(0, 0, 0, 0);
                    Size = dim2(0, 3, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = cfg.accent
                });
                library:create("UICorner", {Parent = items["accent_line"]; CornerRadius = dim(0, 7)});

                items["avatar"] = library:create("ImageLabel", {
                    Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", cfg.player and cfg.player.UserId or 1);
                    Parent = items["bg"];
                    AnchorPoint = vec2(0, 0.5);
                    Position = dim2(0, 10, 0.5, 0);
                    Size = dim2(0, 32, 0, 32);
                    BackgroundColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                });
                library:create("UICorner", {Parent = items["avatar"]; CornerRadius = dim(0, 999)});

                items["name_label"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    Text = cfg.name;
                    Parent = items["bg"];
                    AnchorPoint = vec2(0, 0.5);
                    Position = dim2(0, 50, 0.5, -7);
                    Size = dim2(1, -110, 0, 18);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextSize = 14;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["role_label"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(110, 110, 112);
                    Text = cfg.role;
                    Parent = items["bg"];
                    AnchorPoint = vec2(0, 0.5);
                    Position = dim2(0, 50, 0.5, 8);
                    Size = dim2(1, -110, 0, 14);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextSize = 12;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["status"] = library:create("Frame", {
                    Parent = items["bg"];
                    AnchorPoint = vec2(1, 0.5);
                    Position = dim2(1, -12, 0.5, 0);
                    Size = dim2(0, 8, 0, 8);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(80, 200, 120)
                });
                library:create("UICorner", {Parent = items["status"]; CornerRadius = dim(0, 999)});
            end

            function cfg.update(player, name, role)
                cfg.player = player or cfg.player
                cfg.name = name or cfg.name
                cfg.role = role or cfg.role
                if cfg.player then
                    items["avatar"].Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", cfg.player.UserId)
                end
                items["name_label"].Text = cfg.name
                items["role_label"].Text = cfg.role
            end

            function cfg.set_status_color(color)
                items["status"].BackgroundColor3 = color
            end

            return setmetatable(cfg, library)
        end

        -- Multi-select list - search-friendly multi selection
        function library:multi_select(options)
            options = options or {}
            local cfg = {
                name = options.name or "Multi Select",
                options_list = options.options or {},
                flag = options.flag or library:next_flag(),
                max = options.max or nil,
                callback = options.callback or function() end,
                selected = options.default or {},
                items = {},
                option_instances = {},
            }

            flags[cfg.flag] = cfg.selected

            local items = cfg.items; do
                items["container"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    Text = cfg.name;
                    Parent = items["container"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 18);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["search"] = library:create("TextBox", {
                    FontFace = fonts.font;
                    Text = "";
                    Parent = items["container"];
                    Name = "\0";
                    PlaceholderText = "filter...";
                    PlaceholderColor3 = rgb(110, 110, 112);
                    BorderSizePixel = 0;
                    CursorPosition = -1;
                    ClearTextOnFocus = false;
                    TextSize = 13;
                    BackgroundColor3 = rgb(33, 33, 35);
                    TextColor3 = rgb(245, 245, 245);
                    Position = dim2(0, 0, 0, 22);
                    Size = dim2(1, 0, 0, 26);
                });
                library:create("UICorner", {Parent = items["search"]; CornerRadius = dim(0, 5)});

                items["list"] = library:create("Frame", {
                    Parent = items["container"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Position = dim2(0, 0, 0, 54);
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                library:create("UIListLayout", {Parent = items["list"]; Padding = dim(0, 4); SortOrder = Enum.SortOrder.LayoutOrder});
            end

            local function render_list(filter)
                for _, o in cfg.option_instances do
                    if o and o.Parent then o:Destroy() end
                end
                cfg.option_instances = {}

                for _, opt in cfg.options_list do
                    if not filter or filter == "" or tostring(opt):lower():find(filter:lower(), 1, true) then
                        local is_selected = find(cfg.selected, opt) ~= nil
                        local row = library:create("TextButton", {
                            FontFace = fonts.font;
                            Text = tostring(opt);
                            TextColor3 = is_selected and themes.preset.accent or rgb(245, 245, 245);
                            BorderColor3 = rgb(0, 0, 0);
                            AutoButtonColor = false;
                            Parent = items["list"];
                            Name = "\0";
                            Size = dim2(1, 0, 0, 26);
                            BorderSizePixel = 0;
                            TextXAlignment = Enum.TextXAlignment.Left;
                            TextSize = 13;
                            BackgroundColor3 = rgb(28, 28, 30)
                        });
                        library:create("UICorner", {Parent = row; CornerRadius = dim(0, 4)});
                        library:create("UIPadding", {Parent = row; PaddingLeft = dim(0, 8); PaddingRight = dim(0, 8)});

                        row.MouseButton1Click:Connect(function()
                            local idx = find(cfg.selected, opt)
                            if idx then
                                remove(cfg.selected, idx)
                            else
                                if cfg.max and #cfg.selected >= cfg.max then
                                    return
                                end
                                insert(cfg.selected, opt)
                            end
                            render_list(items["search"].Text)
                            flags[cfg.flag] = cfg.selected
                            cfg.callback(cfg.selected)
                        end)

                        cfg.option_instances[#cfg.option_instances + 1] = row
                    end
                end
            end

            render_list("")

            items["search"]:GetPropertyChangedSignal("Text"):Connect(function()
                render_list(items["search"].Text)
            end)

            cfg.refresh = function(new_opts)
                cfg.options_list = new_opts
                render_list(items["search"].Text)
            end

            return setmetatable(cfg, library)
        end

        -- Tab list - vertical tab list (useful for settings/configs)
        function library:tab_list(options)
            options = options or {}
            local cfg = {
                name = options.name or "Tabs",
                options_list = options.options or {},
                callback = options.callback or function() end,
                items = {},
                buttons = {},
                selected_index = options.default or 1,
            }

            local items = cfg.items; do
                items["container"] = library:create("Frame", {
                    Parent = self.items["elements"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.name then
                    items["name"] = library:create("TextLabel", {
                        FontFace = fonts.font;
                        TextColor3 = rgb(245, 245, 245);
                        Text = cfg.name;
                        Parent = items["container"];
                        Name = "\0";
                        Size = dim2(1, 0, 0, 18);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end

                items["list"] = library:create("Frame", {
                    Parent = items["container"];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Position = dim2(0, 0, 0, cfg.name and 24 or 0);
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                library:create("UIListLayout", {Parent = items["list"]; Padding = dim(0, 4); SortOrder = Enum.SortOrder.LayoutOrder});
            end

            local function render()
                for _, b in cfg.buttons do
                    if b and b.Parent then b:Destroy() end
                end
                cfg.buttons = {}

                for i, opt in cfg.options_list do
                    local is_selected = i == cfg.selected_index
                    local btn = library:create("TextButton", {
                        FontFace = fonts.font;
                        Text = tostring(opt);
                        TextColor3 = is_selected and rgb(255, 255, 255) or rgb(110, 110, 112);
                        AutoButtonColor = false;
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = items["list"];
                        Name = "\0";
                        Size = dim2(1, 0, 0, 28);
                        BorderSizePixel = 0;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextSize = 13;
                        BackgroundColor3 = is_selected and rgb(33, 33, 35) or rgb(25, 25, 27)
                    });
                    library:create("UICorner", {Parent = btn; CornerRadius = dim(0, 5)});
                    library:create("UIPadding", {Parent = btn; PaddingLeft = dim(0, 10); PaddingRight = dim(0, 10)});

                    btn.MouseButton1Click:Connect(function()
                        cfg.selected_index = i
                        cfg.callback(opt, i)
                        render()
                    end)

                    cfg.buttons[#cfg.buttons + 1] = btn
                end
            end

            render()

            function cfg.select(index)
                cfg.selected_index = index
                if cfg.options_list[index] then
                    cfg.callback(cfg.options_list[index], index)
                end
                render()
            end

            return setmetatable(cfg, library)
        end

        -- Input - numeric input that goes in elements (works alongside sliders)
        function library:input(options)
            options = options or {}
            local cfg = {
                name = options.name or "Input",
                placeholder = options.placeholder or "0",
                flag = options.flag or library:next_flag(),
                min = options.min,
                max = options.max,
                integer = options.integer or false,
                default = options.default,
                callback = options.callback or function() end,
                items = {},
            }

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items["container"] = library:create("TextButton", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items["elements"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["name"] = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(245, 245, 245);
                    Text = cfg.name;
                    Parent = items["container"];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 18);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                items["input"] = library:create("TextBox", {
                    FontFace = fonts.font;
                    Text = tostring(cfg.default or "");
                    PlaceholderText = cfg.placeholder;
                    PlaceholderColor3 = rgb(110, 110, 112);
                    Parent = items["container"];
                    Name = "\0";
                    BorderSizePixel = 0;
                    CursorPosition = -1;
                    ClearTextOnFocus = false;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35);
                    TextColor3 = rgb(245, 245, 245);
                    Position = dim2(0, 0, 0, 22);
                    Size = dim2(1, 0, 0, 28);
                });
                library:create("UICorner", {Parent = items["input"]; CornerRadius = dim(0, 5)});
            end

            function cfg.set(value)
                cfg.value = value
                flags[cfg.flag] = value
                items["input"].Text = tostring(value)
                cfg.callback(value)
            end

            items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
                local raw = items["input"].Text
                local num = tonumber(raw)
                if num then
                    if cfg.min then num = math.max(num, cfg.min) end
                    if cfg.max then num = math.min(num, cfg.max) end
                    if cfg.integer then num = math.floor(num) end
                    cfg.value = num
                    flags[cfg.flag] = num
                    cfg.callback(num)
                else
                    flags[cfg.flag] = raw
                    cfg.callback(raw)
                end
            end)

            if cfg.default then cfg.set(cfg.default) end

            return setmetatable(cfg, library)
        end

        -- Animation style switcher - globally switches between tween and "spring"
        function library:set_animation(style)
            library.animation_style = style
        end

    --

    -- Notification Library (typed, capped, leak-safe)
        local NOTIF_TYPE_COLORS = {info=rgb(155,150,219), success=rgb(90,200,120), warn=rgb(255,180,60), error=rgb(235,70,70)}
        local NOTIF_TYPE_ICONS  = {info="rbxassetid://6031090997", success="rbxassetid://6031094667", warn="rbxassetid://6031094678", error="rbxassetid://6031094670"}
        function notifications:refresh_notifs()
            local offset = 56
            local alive={}
            for i, v in next, notifications.notifs do
                if v and v.Parent then
                    alive[#alive+1]=v
                    library:tween(v, {Position = dim_offset(20, offset)}, Enum.EasingStyle.Quad, 0.28)
                    offset = offset + v.AbsoluteSize.Y + 8
                end
            end
            notifications.notifs = alive
            return offset
        end
        function notifications:fade(path, is_fading)
            local t = is_fading and 1 or 0
            pcall(function() library:tween(path, {BackgroundTransparency = t}, Enum.EasingStyle.Quad, 0.5) end)
            for _, inst in next, path:GetDescendants() do
                if inst:IsA("UIStroke") then pcall(function() library:tween(inst, {Transparency = t}, Enum.EasingStyle.Quad, 0.5) end)
                elseif inst:IsA("TextLabel") then pcall(function() library:tween(inst, {TextTransparency = t}, Enum.EasingStyle.Quad, 0.5) end)
                elseif inst:IsA("ImageLabel") then pcall(function() library:tween(inst, {ImageTransparency = t}, Enum.EasingStyle.Quad, 0.5) end)
                elseif inst:IsA("Frame") then
                    local bg = inst.BackgroundTransparency
                    if bg < 0.9 then pcall(function() library:tween(inst, {BackgroundTransparency = is_fading and 1 or bg}, Enum.EasingStyle.Quad, 0.5) end) end
                end
            end
        end

        function notifications:create_notification(options)
            local cfg = {
                name = options.name or "This is a title!";
                info = options.info or "This is extra info!";
                lifetime = options.lifetime or 3;
                items = {};
                outline;
            }

            local items = cfg.items; do
                items["notification"] = library:create("Frame", {
                    Parent = library["items"];
                    Size = dim2(0, 210, 0, 53);
                    Name = "\0";
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    AnchorPoint = vec2(1, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(14, 14, 16)
                });

                library:create("UIStroke", {
                    Color = rgb(23, 23, 29);
                    Parent = items["notification"];
                    Transparency = 1;
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                });

                items["title"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items["notification"];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 7, 0, 6);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UICorner", {
                    Parent = items["notification"];
                    CornerRadius = dim(0, 3)
                });

                items["info"] = library:create("TextLabel", {
                    FontFace = fonts.font;
                    TextColor3 = rgb(145, 145, 145);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.info;
                    Parent = items["notification"];
                    Name = "\0";
                    Position = dim2(0, 9, 0, 22);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextWrapped = true;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                library:create("UIPadding", {
                    PaddingBottom = dim(0, 17);
                    PaddingRight = dim(0, 8);
                    Parent = items["info"]
                });

                local ntype = (options.type or options.Type or "info"):lower()
                local accentCol = NOTIF_TYPE_COLORS[ntype] or themes.preset.accent
                items["bar"] = library:create("Frame", {
                    AnchorPoint = vec2(0, 1);
                    Parent = items["notification"];
                    Name = "\0";
                    Position = dim2(0, 8, 1, -6);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 0, 3);
                    BackgroundTransparency = 0;
                    BorderSizePixel = 0;
                    BackgroundColor3 = accentCol
                });
                items["left_bar"] = library:create("Frame", {
                    Parent = items["notification"];
                    Position = dim2(0, 0, 0, 0);
                    Size = dim2(0, 3, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = accentCol
                }); library:create("UICorner", {Parent=items["left_bar"]; CornerRadius=dim(0,3)});

                library:create("UICorner", {
                    Parent = items["bar"];
                    CornerRadius = dim(0, 999)
                });

                library:create("UIPadding", {
                    PaddingRight = dim(0, 8);
                    Parent = items["notification"]
                });
            end

            if #notifications.notifs >= 6 then
                local oldest = table.remove(notifications.notifs, 1)
                if oldest and oldest.Parent then pcall(function() oldest:Destroy() end) end
            end
            local index = #notifications.notifs + 1
            notifications.notifs[index] = items["notification"]
            notifications:fade(items["notification"], false)
            local offset = notifications:refresh_notifs()
            items["notification"].Position = dim_offset(20, offset)
            local startPos = items["notification"].Position - dim_offset(24, 0)
            items["notification"].Position = startPos
            library:tween(items["notification"], {Position = dim_offset(20, offset)}, Enum.EasingStyle.Quad, 0.42)
            library:tween(items["bar"], {Size = dim2(1, -16, 0, 3)}, Enum.EasingStyle.Linear, cfg.lifetime)

            task.spawn(function()
                task.wait(cfg.lifetime)
                for i, v in next, notifications.notifs do if v==items["notification"] then table.remove(notifications.notifs, i) break end end
                notifications:fade(items["notification"], true)
                library:tween(items["notification"], {Position = items["notification"].Position + dim_offset(16, 0)}, Enum.EasingStyle.Quad, 0.42)
                task.wait(0.55)
                pcall(function() items["notification"]:Destroy() end)
                notifications:refresh_notifs()
            end)
        end
--


    -- ============================================================
    --   V3 POLISH: tooltip / context_menu / banner / radio / prompt / animation_changer
    -- ============================================================

        -- Tooltip
        do
            local hovered = nil; local tipFrame, tipLabel, tipConn
            local function ensure_tip_gui()
                if tipFrame and tipFrame.Parent then return end
                local holder = library:create("Frame", {
                    Parent = library["items"];
                    Visible = false;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(28,28,30);
                    ZIndex = 100;
                }); library:create("UICorner", {Parent=holder; CornerRadius=dim(0,6)});
                library:create("UIStroke", {Parent=holder; Color=rgb(45,45,50)});
                library:create("UIPadding", {Parent=holder; PaddingTop=dim(0,6); PaddingBottom=dim(0,6); PaddingLeft=dim(0,8); PaddingRight=dim(0,8)});
                local lbl = library:create("TextLabel", {
                    FontFace = fonts.small; TextColor3=rgb(220,220,225); TextSize=13; BackgroundTransparency=1;
                    AutomaticSize=Enum.AutomaticSize.XY; TextXAlignment=Enum.TextXAlignment.Left; Parent=holder
                }); tipFrame=holder; tipLabel=lbl
                tipConn = library:connection(run.RenderStepped, function()
                    if hovered and tipFrame.Visible then
                        local m = uis:GetMouseLocation()
                        local vs = camera.ViewportSize
                        local sz = tipFrame.AbsoluteSize
                        local x = clamp(m.X + 14, 4, vs.X - sz.X - 4)
                        local y = clamp(m.Y + 14, 4, vs.Y - sz.Y - 4)
                        tipFrame.Position = dim_offset(x, y)
                    end
                end)
            end
            function library:tooltip(opts)
                local text = type(opts)=="string" and opts or opts.text or opts.Text or ""
                local target = type(opts)=="table" and (opts.target or opts.Target or opts.instance or self.items and self.items.toggle or self.items.button or self) or self
                local obj = target
                if type(target)=="table" and target.items then
                    obj = target.items.tooltip_target or target.items.toggle or target.items.button or target.items.slider or target.items.dropdown or target.items.input or target.items.label or next(target.items)
                    if type(obj)=="table" then obj = obj end
                end
                if typeof(obj) ~= "Instance" then
                    if type(target)=="table" and target.items then
                        for _, v in next, target.items do if typeof(v)=="Instance" and v:IsA("GuiObject") then obj=v break end end
                    end
                end
                if typeof(obj) ~= "Instance" then return end
                ensure_tip_gui()
                local delay = (type(opts)=="table" and opts.delay) or 0.25
                local enterConn, leaveConn
                local showTask
                enterConn = obj.MouseEnter:Connect(function()
                    hovered = obj
                    tipLabel.Text = text
                    if showTask then task.cancel(showTask) end
                    showTask = task.delay(delay, function()
                        if hovered==obj then tipFrame.Visible = true end
                    end)
                end)
                leaveConn = obj.MouseLeave:Connect(function()
                    if hovered==obj then hovered=nil; tipFrame.Visible=false end
                    if showTask then task.cancel(showTask) end
                end)
                library:connection(obj.AncestryChanged, function() if not obj.Parent then tipFrame.Visible=false end end)
                return {Destroy=function() if enterConn then enterConn:Disconnect() end if leaveConn then leaveConn:Disconnect() end end}
            end
        end

        -- Context menu
        function library:context_menu(options)
            options = options or {}
            local cfg = {items={}, entries=options.items or options.entries or {}, open=false}
            local holder = library:create("Frame", {
                Parent = library["items"]; Visible=false; AutomaticSize=Enum.AutomaticSize.XY; BorderSizePixel=0; BackgroundColor3=rgb(22,22,24); ZIndex=50;
            }); library:create("UICorner", {Parent=holder; CornerRadius=dim(0,7)}); library:create("UIStroke", {Parent=holder; Color=rgb(35,35,38)})
            library:create("UIListLayout", {Parent=holder; Padding=dim(0,2); SortOrder=Enum.SortOrder.LayoutOrder})
            library:create("UIPadding", {Parent=holder; PaddingTop=dim(0,6); PaddingBottom=dim(0,6); PaddingLeft=dim(0,6); PaddingRight=dim(0,6)})
            local function build()
                for _, ch in next, holder:GetChildren() do if ch:IsA("TextButton") or ch:IsA("Frame") and ch.Name=="sep" then ch:Destroy() end end
                for i, ent in next, cfg.entries do
                    if ent == "sep" or ent.separator then
                        local s = library:create("Frame", {Parent=holder; Size=dim2(1,0,0,1); BorderSizePixel=0; BackgroundColor3=rgb(35,35,38); Name="sep"})
                    else
                        local btn = library:create("TextButton", {
                            FontFace=fonts.font; Text=ent.name or ent.Name or tostring(i); TextColor3=rgb(220,220,225); TextXAlignment=Enum.TextXAlignment.Left;
                            TextSize=13; AutoButtonColor=false; BackgroundColor3=rgb(32,32,35); Size=dim2(0,180,0,26); Parent=holder;
                        }); library:create("UICorner", {Parent=btn; CornerRadius=dim(0,5)}); library:create("UIPadding", {Parent=btn; PaddingLeft=dim(0,8); PaddingRight=dim(0,8)})
                        btn.MouseEnter:Connect(function() library:tween(btn,{BackgroundColor3=rgb(45,45,50)},Enum.EasingStyle.Quad,0.12) end)
                        btn.MouseLeave:Connect(function() library:tween(btn,{BackgroundColor3=rgb(32,32,35)},Enum.EasingStyle.Quad,0.12) end)
                        btn.MouseButton1Click:Connect(function()
                            holder.Visible=false; cfg.open=false
                            if ent.callback then ent.callback() end
                        end)
                    end
                end
            end
            build()
            function cfg.attach(targetInst)
                local obj = targetInst
                if type(targetInst)=="table" and targetInst.items then
                    for _, v in next, targetInst.items do if typeof(v)=="Instance" and v:IsA("GuiObject") then obj=v break end end
                end
                if typeof(obj)~="Instance" then return end
                obj.InputBegan:Connect(function(input)
                    if input.UserInputType==Enum.UserInputType.MouseButton2 then
                        local m = uis:GetMouseLocation()
                        holder.Position = dim_offset(clamp(m.X, 0, camera.ViewportSize.X-200), clamp(m.Y, 0, camera.ViewportSize.Y-200))
                        holder.Visible = true; cfg.open=true
                        library.current_open = {set_visible=function(v) holder.Visible=v end, open=true}
                    end
                end)
            end
            library:connection(uis.InputBegan, function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 and cfg.open then
                    if not library:mouse_in_frame(holder) then holder.Visible=false; cfg.open=false end
                end
            end)
            function cfg.set_items(list) cfg.entries=list; build() end
            function cfg.open_at(pos) holder.Position=pos; holder.Visible=true; cfg.open=true end
            function cfg.close() holder.Visible=false; cfg.open=false end
            cfg.holder = holder
            return setmetatable(cfg, library)
        end

        -- Banner
        function library:banner(options)
            options=options or {}
            local cfg={text=options.text or options.Text or "Heads up!", type=(options.type or "info"):lower(), items={}}
            local colors={info=rgb(155,150,219), success=rgb(80,200,120), warn=rgb(255,170,50), error=rgb(235,70,70)}
            local col = colors[cfg.type] or colors.info
            local items=cfg.items; do
                items.banner = library:create("Frame", {
                    Parent=self.items["elements"]; BackgroundColor3=rgb(28,28,30); BorderSizePixel=0; Size=dim2(1,0,0,0); AutomaticSize=Enum.AutomaticSize.Y;
                }); library:create("UICorner", {Parent=items.banner; CornerRadius=dim(0,6)});
                library:create("UIPadding", {Parent=items.banner; PaddingLeft=dim(0,10); PaddingRight=dim(0,10); PaddingTop=dim(0,8); PaddingBottom=dim(0,8)});
                local bar = library:create("Frame", {Parent=items.banner; Size=dim2(0,3,1,8); Position=dim2(0,-10,0,-8); BorderSizePixel=0; BackgroundColor3=col});
                library:create("UICorner", {Parent=bar; CornerRadius=dim(0,999)});
                local lbl = library:create("TextLabel", {
                    FontFace=fonts.font; TextColor3=rgb(220,220,225); Text=cfg.text; TextWrapped=true; TextXAlignment=Enum.TextXAlignment.Left;
                    TextSize=13; BackgroundTransparency=1; AutomaticSize=Enum.AutomaticSize.Y; Size=dim2(1,0,0,0); Parent=items.banner
                });
                cfg.label=lbl; cfg.bar=bar
            end
            function cfg.set_text(t) cfg.label.Text=t end
            function cfg.set_type(tp) local colors2={info=rgb(155,150,219), success=rgb(80,200,120), warn=rgb(255,170,50), error=rgb(235,70,70)} local c=colors2[tp:lower()] or colors2.info; cfg.bar.BackgroundColor3=c end
            return setmetatable(cfg, library)
        end

        -- Radio group
        function library:radio(options)
            options=options or {}
            local cfg={
                name=options.name or "Choice",
                options_list=options.options or options.items or {"A","B","C"},
                flag=options.flag or library:next_flag(),
                default=options.default or options.defaultValue or nil,
                callback=options.callback or function() end,
                items={}, buttons={}
            }
            cfg.default = cfg.default or cfg.options_list[1]
            flags[cfg.flag]=cfg.default
            local items=cfg.items; do
                items.container = library:create("TextButton", {Text="", BackgroundTransparency=1, Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Parent=self.items["elements"]})
                items.title = library:create("TextLabel", {FontFace=fonts.small, TextColor3=rgb(245,245,245), Text=cfg.name, Size=dim2(1,0,0,18), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, Parent=items.container})
                items.list = library:create("Frame", {BackgroundTransparency=1, Size=dim2(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Position=dim2(0,0,0,20), Parent=items.container})
                library:create("UIListLayout", {Parent=items.list; Padding=dim(0,6)})
            end
            local function render()
                for _, b in next, cfg.buttons do if b and b.Parent then b:Destroy() end end; cfg.buttons={}
                for i, opt in next, cfg.options_list do
                    local selected = flags[cfg.flag]==opt
                    local row = library:create("TextButton", {
                        FontFace=fonts.font; Text=""; AutoButtonColor=false; Size=dim2(1,0,0,28);
                        BackgroundColor3=rgb(28,28,30); Parent=items.list
                    }); library:create("UICorner", {Parent=row; CornerRadius=dim(0,6)});
                    library:create("UIPadding", {Parent=row; PaddingLeft=dim(0,8); PaddingRight=dim(0,8)});
                    local circle = library:create("Frame", {Parent=row; Size=dim2(0,16,0,16); AnchorPoint=vec2(0,0.5); Position=dim2(0,0,0.5,0); BackgroundColor3=rgb(35,35,38); BorderSizePixel=0});
                    library:create("UICorner", {Parent=circle; CornerRadius=dim(0,999)}); library:create("UIStroke", {Parent=circle; Color=selected and themes.preset.accent or rgb(55,55,60)});
                    local inner = library:create("Frame", {Parent=circle; Size=dim2(1,-6,1,-6); Position=dim2(0,3,0,3); BackgroundColor3=themes.preset.accent; BorderSizePixel=0; Visible=selected});
                    library:create("UICorner", {Parent=inner; CornerRadius=dim(0,999)});
                    local lbl = library:create("TextLabel", {FontFace=fonts.font; Text=opt; TextColor3=selected and rgb(255,255,255) or rgb(180,180,185); TextSize=13; BackgroundTransparency=1; Position=dim2(0,24,0,0); Size=dim2(1,-24,1,0); TextXAlignment=Enum.TextXAlignment.Left; Parent=row});
                    row.MouseButton1Click:Connect(function()
                        flags[cfg.flag]=opt; cfg.callback(opt); render()
                    end)
                    cfg.buttons[#cfg.buttons+1]=row
                end
            end
            render()
            function cfg.set(v) flags[cfg.flag]=v; render(); cfg.callback(v) end
            config_flags[cfg.flag]=cfg.set
            return setmetatable(cfg, library)
        end

        -- Prompt
        function library:prompt(options)
            options=options or {}
            local title = options.title or options.name or "Are you sure?"
            local text2 = options.text or options.info or ""
            local onYes = options.yes or options.onYes or options.callback or function() end
            local onNo = options.no or options.onNo or function() end
            local overlay = library:create("Frame", {
                Parent=library["items"]; Size=dim2(1,0,1,0); BackgroundColor3=rgb(0,0,0); BackgroundTransparency=0.45; BorderSizePixel=0; ZIndex=20; Visible=true
            });
            local box = library:create("Frame", {
                Parent=overlay; AnchorPoint=vec2(0.5,0.5); Position=dim2(0.5,0,0.5,0); Size=dim2(0,320,0,0); AutomaticSize=Enum.AutomaticSize.Y;
                BackgroundColor3=rgb(22,22,24); BorderSizePixel=0; ZIndex=21
            }); library:create("UICorner", {Parent=box; CornerRadius=dim(0,10)}); library:create("UIStroke", {Parent=box; Color=rgb(35,35,38)});
            library:create("UIPadding", {Parent=box; PaddingTop=dim(0,16); PaddingBottom=dim(0,16); PaddingLeft=dim(0,16); PaddingRight=dim(0,16)})
            library:create("TextLabel", {FontFace=fonts.font; Text=title; TextColor3=rgb(255,255,255); TextSize=16; BackgroundTransparency=1; Size=dim2(1,0,0,20); Parent=box})
            if text2~="" then library:create("TextLabel", {FontFace=fonts.font; Text=text2; TextColor3=rgb(150,150,155); TextSize=13; TextWrapped=true; BackgroundTransparency=1; AutomaticSize=Enum.AutomaticSize.Y; Size=dim2(1,0,0,0); Parent=box}) end
            local btnRow = library:create("Frame", {BackgroundTransparency=1; Size=dim2(1,0,0,34); Parent=box})
            library:create("UIListLayout", {Parent=btnRow; FillDirection=Enum.FillDirection.Horizontal; HorizontalAlignment=Enum.HorizontalAlignment.Right; Padding=dim(0,8)})
            local function mkBtn(name, color, cb)
                local b=library:create("TextButton", {FontFace=fonts.font; Text=name; TextColor3=rgb(255,255,255); TextSize=13; Size=dim2(0,80,0,30); BackgroundColor3=color; AutoButtonColor=false; Parent=btnRow})
                library:create("UICorner",{Parent=b; CornerRadius=dim(0,6)})
                b.MouseButton1Click:Connect(function() overlay:Destroy(); cb() end)
                return b
            end
            mkBtn("Cancel", rgb(45,45,48), onNo)
            mkBtn("Confirm", themes.preset.accent, onYes)
            overlay.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 and not library:mouse_in_frame(box) then overlay:Destroy(); onNo() end end)
            return overlay
        end

        -- Animation changer (compat)
        function library:animation_changer()
            local cfg={items={}}
            local btn = self and self.button and self:button({name="Animation: "..library.animation_style, callback=function() end}) or nil
            local holder
            if btn and btn.items and btn.items.button then holder = btn.items.button
            else holder = nil end
            function library:set_animation(style)
                library.animation_style = style
                if holder and holder:FindFirstChildWhichIsA("TextLabel") then
                    holder:FindFirstChildWhichIsA("TextLabel").Text = "Animation: "..style
                end
            end
            if btn then
                btn.items.button.MouseButton1Click:Connect(function()
                    local nextStyle = library.animation_style=="tween" and "spring" or "tween"
                    library:set_animation(nextStyle)
                end)
            end
            return setmetatable({toggle=function() local ns=library.animation_style=="tween" and "spring" or "tween" library:set_animation(ns) end}, library)
        end
        -- alias for set_animation if missing
        if not library.set_animation then
            function library:set_animation(style) library.animation_style = style end
        end
        function library:get_version() return "3.0.1-pro" end

return library
