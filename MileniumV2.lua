--[[

    Milenium Library V2 (Enhanced & Fixed)
    -> Enhanced & bug-fixed by Arena AI Agent
    -> Based on @finobe's original Milenium Library

    Changelog (V2 Enhanced):
        [BUG FIXES]
        - Fixed crash in library:settings() — items["fade"] was referenced but never created
        - Fixed notifications:fade() using instance.Transparency (nil) instead of BackgroundTransparency
        - Fixed dropdown name hardcoded as "Dropdown" instead of cfg.name
        - Fixed tab icon hardcoded instead of using cfg.icon
        - Fixed items["title"] Text = name (global) dead code
        - Renamed fag() to table_count()
        - Fixed cfg.enabled in toggle starting as nil instead of cfg.default
        - Fixed colorpicker_holder Visible = true on creation
        - Fixed dropdown_holder Visible = true on creation
        - Fixed slider fill size edge case when min == max
        - Fixed settings outline Position calculation
        - Fixed keybind set_visible position offset calculation

        [IMPROVEMENTS]
        - Smooth spring-like toggle animations with bounce easing & glow
        - Beautiful slider effects: glow on fill bar, pulse on drag circle, smooth snap
        - Logo holder in sidebar with custom image support (library:set_logo())
        - Improved player_list with built-in search bar
        - Better tab switch animation (fade + scale)
        - Hover ripple effects on interactive elements
        - Accent glow on active toggle/slider states

    API:
        library:window(properties)          -- Main window (now with logo support)
        library:set_logo(assetId)           -- Set logo image in sidebar
        library:tab(properties)             -- Tab with icon
        library:seperator(properties)       -- Sidebar section separator
        library:column(properties)          -- Content column
        library:sub_tab(properties)         -- Sub-tab layout
        library:section(properties)         -- Collapsible section
        library:toggle(options)             -- Toggle/checkbox with spring animation
        library:slider(options)             -- Slider with glow effects
        library:dropdown(options)           -- Dropdown menu
        library:colorpicker(options)        -- Color picker with hex input
        library:textbox(options)            -- Text input
        library:keybind(options)            -- Keybind picker
        library:button(options)             -- Button
        library:label(options)              -- Text label
        library:settings(options)           -- Settings popup
        library:list(properties)            -- Scrollable list
        library:player_list(options)        -- Player list with search + avatars
        library:search(options)             -- Search bar
        library:watermark(options)          -- Draggable watermark
        library:keybind_list()              -- Keybind viewer
        library:hotbar(options)             -- Floating button bar
        library:badge(options)              -- Status badge pill
        library:progress_bar(options)       -- Animated progress bar
        library:divider(options)            -- Visual divider
        library:player_card(options)        -- Player info card
        library:multi_select(options)       -- Multi-select list
        library:tab_list(options)           -- Vertical tab list
        library:input(options)              -- Numeric input
        library:init_config(window)         -- Config system setup
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
        animation_style = "tween",
        logo_items = {},
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
        [Enum.KeyCode.Escape] = "ESC",
        [Enum.KeyCode.Space] = "SPC",
        [Enum.KeyCode.Tab] = "TAB",
        [Enum.KeyCode.Delete] = "DEL",
        [Enum.KeyCode.Home] = "HOME",
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
        function Register_Font(Name, Weight, Style, Asset)
            if not isfile(Asset.Id) then
                writefile(Asset.Id, Asset.Font)
            end

            if isfile(Name .. ".font") then
                delfile(Name .. ".font")
            end

            local Data = {
                name = Name,
                faces = {
                    {
                        name = "Normal",
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Asset.Id),
                    },
                },
            }

            writefile(Name .. ".font", http_service:JSONEncode(Data))

            return getcustomasset(Name .. ".font");
        end

        local Medium = Register_Font("Medium", 200, "Normal", {
            Id = "Medium.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf"),
        })

        local SemiBold = Register_Font("SemiBold", 200, "Normal", {
            Id = "SemiBold.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf"),
        })

        fonts = {
            small = Font.new(Medium, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
            font = Font.new(SemiBold, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
        }
    end
--

-- Library functions
    -- Misc functions
        function library:tween(obj, properties, easing_style, time)
            local tween = tween_service:Create(obj, TweenInfo.new(time or 0.25, easing_style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0), properties):Play()
            return tween
        end

        -- Spring-like tween with slight overshoot (bounce)
        function library:tween_spring(obj, properties, time)
            local tween = tween_service:Create(obj, TweenInfo.new(time or 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0), properties):Play()
            return tween
        end

        -- Smooth ease out tween
        function library:tween_smooth(obj, properties, time)
            local tween = tween_service:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0), properties):Play()
            return tween
        end

        function library:resizify(frame)
            local Frame = Instance.new("TextButton")
            Frame.Position = dim2(1, -10, 1, -10)
            Frame.BorderColor3 = rgb(0, 0, 0)
            Frame.Size = dim2(0, 10, 0, 10)
            Frame.BorderSizePixel = 0
            Frame.BackgroundColor3 = rgb(255, 255, 255)
            Frame.Parent = frame
            Frame.BackgroundTransparency = 1
            Frame.Text = ""

            local resizing = false
            local start_size
            local start
            local og_size = frame.Size

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = true
                    start = input.Position
                    start_size = frame.Size
                end
            end)

            Frame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = false
                end
            end)

            library:connection(uis.InputChanged, function(input, game_event)
                if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local viewport_x = camera.ViewportSize.X
                    local viewport_y = camera.ViewportSize.Y

                    local current_size = dim2(
                        start_size.X.Scale,
                        math.clamp(
                            start_size.X.Offset + (input.Position.X - start.X),
                            og_size.X.Offset,
                            viewport_x
                        ),
                        start_size.Y.Scale,
                        math.clamp(
                            start_size.Y.Offset + (input.Position.Y - start.Y),
                            og_size.Y.Offset,
                            viewport_y
                        )
                    )

                    library:tween(frame, {Size = current_size}, Enum.EasingStyle.Linear, 0.05)
                end
            end)
        end

        function table_count(tbl)
            local Size = 0
            for _ in tbl do
                Size = Size + 1
            end
            return Size
        end

        function library:next_flag()
            local index = table_count(library.flags) + 1;
            local str = string.format("flagnumber%s", index)
            return str;
        end

        function library:mouse_in_frame(uiobject)
            local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
            local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X
            return (y_cond and x_cond)
        end

        function library:draggify(frame)
            local dragging = false
            local start_pos = frame.Position
            local start

            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    start = input.Position
                    start_pos = frame.Position
                end
            end)

            frame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            library:connection(uis.InputChanged, function(input, game_event)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local viewport_x = camera.ViewportSize.X
                    local viewport_y = camera.ViewportSize.Y

                    local current_position = dim2(
                        0,
                        clamp(
                            start_pos.X.Offset + (input.Position.X - start.X),
                            0,
                            viewport_x - frame.Size.X.Offset
                        ),
                        0,
                        math.clamp(
                            start_pos.Y.Offset + (input.Position.Y - start.Y),
                            0,
                            viewport_y - frame.Size.Y.Offset
                        )
                    )

                    library:tween(frame, {Position = current_position}, Enum.EasingStyle.Linear, 0.05)
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
            if not config_holder then
                return
            end
            local list = {}
            for idx, file in listfiles(library.directory .. "/configs") do
                local name = file:gsub(library.directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(library.directory .. "\\configs\\", "")
                list[#list + 1] = name
            end
            config_holder.refresh_options(list)
        end

        function library:get_config()
            local Config = {}
            for _, v in next, flags do
                if type(v) == "table" and v.key then
                    Config[_] = {active = v.active, mode = v.mode, key = tostring(v.key)}
                elseif type(v) == "table" and v["Transparency"] and v["Color"] then
                    Config[_] = {Transparency = v["Transparency"], Color = v["Color"]:ToHex()}
                else
                    Config[_] = v
                end
            end
            return http_service:JSONEncode(Config)
        end

        function library:load_config(config_json)
            local config = http_service:JSONDecode(config_json)
            for _, v in config do
                local function_set = library.config_flags[_]
                if _ == "config_name_list" then
                    continue
                end
                if function_set then
                    if type(v) == "table" and v["Transparency"] and v["Color"] then
                        function_set(hex(v["Color"]), v["Transparency"])
                    elseif type(v) == "table" and v["active"] then
                        function_set(v)
                    else
                        function_set(v)
                    end
                end
            end
        end

        function library:round(number, float)
            local multiplier = 1 / (float or 1)
            return floor(number * multiplier + 0.5) / multiplier
        end

        function library:apply_theme(instance, theme, property)
            insert(themes.utility[theme][property], instance)
        end

        function library:update_theme(theme, color)
            for _, property in themes.utility[theme] do
                for m, object in property do
                    if object[_] == themes.preset[theme] then
                        object[_] = color
                    end
                end
            end
            themes.preset[theme] = color
        end

        function library:connection(signal, callback)
            local connection = signal:Connect(callback)
            insert(library.connections, connection)
            return connection
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

        function library:create(instance, options)
            local ins = Instance.new(instance)
            for prop, value in options do
                ins[prop] = value
            end
            return ins
        end

        function library:unload_menu()
            if library["items"] then
                library["items"]:Destroy()
            end
            if library["other"] then
                library["other"]:Destroy()
            end
            for index, connection in library.connections do
                connection:Disconnect()
                connection = nil
            end
            library = nil
        end
    --

    -- ============================================================
    --   LOGO SUPPORT
    -- ============================================================

    function library:set_logo(assetId)
        if library.logo_items.image then
            library.logo_items.image.Image = assetId
        end
        if library.logo_items.glow then
            library.logo_items.glow.Image = assetId
        end
    end

    function library:hide_logo()
        if library.logo_items.container then
            library.logo_items.container.Visible = false
        end
    end

    function library:show_logo()
        if library.logo_items.container then
            library.logo_items.container.Visible = true
        end
    end

    -- ============================================================
    --   WINDOW
    -- ============================================================

    function library:window(properties)
        local cfg = {
            suffix = properties.suffix or properties.Suffix or "tech";
            name = properties.name or properties.Name or "nebula";
            logo = properties.logo or properties.Logo or "";
            game_name = properties.gameInfo or properties.game_info or properties.GameInfo or "Milenium V2 for Counter-Strike: Global Offensive";
            size = properties.size or properties.Size or dim2(0, 700, 0, 565);
            selected_tab;
            items = {};

            tween;
        }

        library["items"] = library:create("ScreenGui", {
            Parent = coregui;
            Name = "\0";
            Enabled = true;
            ZIndexBehavior = Enum.ZIndexBehavior.Global;
            IgnoreGuiInset = true;
        });

        library["other"] = library:create("ScreenGui", {
            Parent = coregui;
            Name = "\0";
            Enabled = false;
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
            IgnoreGuiInset = true;
        });

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

            -- LOGO HOLDER
            items["logo_container"] = library:create("Frame", {
                Parent = items["side_frame"];
                BackgroundTransparency = 1;
                Name = "\0";
                Position = dim2(0.5, 0, 0, 10);
                AnchorPoint = vec2(0.5, 0);
                Size = dim2(0, 60, 0, 60);
                BorderSizePixel = 0;
                BackgroundColor3 = rgb(255, 255, 255);
                ZIndex = 2;
            })
            library.logo_items.container = items["logo_container"]

            library:create("UICorner", {
                Parent = items["logo_container"];
                CornerRadius = dim(0, 12)
            })

            -- Logo glow (subtle accent glow behind logo)
            items["logo_glow"] = library:create("ImageLabel", {
                Parent = items["logo_container"];
                Name = "\0";
                BackgroundTransparency = 1;
                Size = dim2(1, 20, 1, 20);
                Position = dim2(0.5, 0, 0.5, 0);
                AnchorPoint = vec2(0.5, 0.5);
                Image = cfg.logo ~= "" and cfg.logo or "rbxassetid://6034767608";
                ImageColor3 = themes.preset.accent;
                ImageTransparency = 0.7;
                ScaleType = Enum.ScaleType.Fit;
                BorderSizePixel = 0;
                ZIndex = 1;
            })
            library:create("UICorner", {Parent = items["logo_glow"]; CornerRadius = dim(0, 16)})
            library:apply_theme(items["logo_glow"], "accent", "ImageColor3")
            library.logo_items.glow = items["logo_glow"]

            items["logo_image"] = library:create("ImageLabel", {
                Parent = items["logo_container"];
                Name = "\0";
                BackgroundTransparency = 1;
                Size = dim2(0.8, 0, 0.8, 0);
                Position = dim2(0.5, 0, 0.5, 0);
                AnchorPoint = vec2(0.5, 0.5);
                Image = cfg.logo ~= "" and cfg.logo or "rbxassetid://6034767608";
                ImageColor3 = themes.preset.accent;
                ImageTransparency = 0;
                ScaleType = Enum.ScaleType.Fit;
                BorderSizePixel = 0;
                ZIndex = 2;
            })
            library:create("UICorner", {Parent = items["logo_image"]; CornerRadius = dim(0, 10)})
            library:apply_theme(items["logo_image"], "accent", "ImageColor3")
            library.logo_items.image = items["logo_image"]

            -- If no logo provided, hide logo area and adjust title position
            if cfg.logo == "" then
                items["logo_container"].Size = dim2(0, 0, 0, 0)
                items["logo_container"].Visible = false
            end

            items["button_holder"] = library:create("Frame", {
                Parent = items["side_frame"];
                Name = "\0";
                BackgroundTransparency = 1;
                Position = dim2(0, 0, 0, cfg.logo ~= "" and 80 or 60);
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(1, 0, 1, cfg.logo ~= "" and -80 or -60);
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
                Parent = items["side_frame"];
                Name = "\0";
                Text = string.format('<u>%s</u><font color = "rgb(255, 255, 255)">%s</font>', cfg.name, cfg.suffix);
                BackgroundTransparency = 1;
                Size = dim2(1, 0, 0, 30);
                Position = dim2(0, 0, 0, cfg.logo ~= "" and 70 or 20);
                TextColor3 = themes.preset.accent;
                BorderSizePixel = 0;
                RichText = true;
                TextSize = 26;
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
        end

        return setmetatable(cfg, library)
    end

    -- ============================================================
    --   TAB
    -- ============================================================

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
                    Image = cfg.icon;
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

                -- Hover effect on tab button
                items["button"].MouseEnter:Connect(function()
                    if self.selected_tab and self.selected_tab[1] == items["button"] then return end
                    library:tween(items["name"], {TextColor3 = rgb(150, 150, 150)})
                end)
                items["button"].MouseLeave:Connect(function()
                    if self.selected_tab and self.selected_tab[1] == items["button"] then return end
                    library:tween(items["name"], {TextColor3 = rgb(72, 72, 73)})
                end)
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
                        library:tween_spring(data.accent, {BackgroundTransparency = 0}, 0.4)
                        library:tween(data.button, {BackgroundTransparency = 0})
                        library:tween_smooth(data.page, {Size = dim2(1, 0, 1, 0)}, 0.4)

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

            library:tween_smooth(items["button"], {BackgroundTransparency = 0})
            library:tween_spring(items["icon"], {ImageColor3 = themes.preset.accent}, 0.35)
            library:tween(items["name"], {TextColor3 = rgb(255, 255, 255)})
            library:tween_smooth(items["tab_holder"], {Size = dim2(1, -196, 1, -81)}, 0.4)

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

    -- ============================================================
    --   SECTION
    -- ============================================================

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

                items["fade"] = library:create("Frame", {
                    Parent = items["outline"];
                    BackgroundTransparency = 0.800000011920929;
                    Name = "\0";
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(0, 0, 0);
                    ZIndex = 5;
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
                library:tween_spring(items["toggle"], {BackgroundColor3 = bool and themes.preset.accent or rgb(58, 58, 62)}, 0.35)
                library:tween_spring(items["toggle_outline"], {BackgroundColor3 = bool and themes.preset.accent or rgb(50, 50, 50)}, 0.35)
                library:tween_spring(items["toggle_circle"], {
                    BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(86, 86, 88),
                    Position = bool and dim2(1, -14, 0, 2) or dim2(0, 2, 0, 2)
                }, 0.35)
                library:tween(items["fade"], {BackgroundTransparency = bool and 1 or 0.8}, Enum.EasingStyle.Quad)
            end

            -- Apply initial state
            cfg.toggle_section(cfg.default)
        end

        return setmetatable(cfg, library)
    end

    -- ============================================================
    --   TOGGLE (with beautiful spring animations)
    -- ============================================================

    function library:toggle(options)
        local rand = math.random(1, 2)
        local cfg = {
            enabled = options.default or false,
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
                BackgroundTransparency = 1;
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

                -- Glow behind checkbox when active
                items["glow"] = library:create("Frame", {
                    Parent = items["toggle_button"];
                    Name = "\0";
                    Size = dim2(1, 8, 1, 8);
                    Position = dim2(0.5, 0, 0.5, 0);
                    AnchorPoint = vec2(0.5, 0.5);
                    BorderSizePixel = 0;
                    BackgroundColor3 = themes.preset.accent;
                    BackgroundTransparency = 1;
                    ZIndex = -1;
                });
                library:create("UICorner", {Parent = items["glow"]; CornerRadius = dim(0, 6)})
                library:apply_theme(items["glow"], "accent", "BackgroundColor3")

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

                -- Glow behind toggle when active
                items["glow"] = library:create("Frame", {
                    Parent = items["toggle_button"];
                    Name = "\0";
                    Size = dim2(1, 10, 1, 10);
                    Position = dim2(0.5, 0, 0.5, 0);
                    AnchorPoint = vec2(0.5, 0.5);
                    BorderSizePixel = 0;
                    BackgroundColor3 = themes.preset.accent;
                    BackgroundTransparency = 1;
                    ZIndex = -1;
                });
                library:create("UICorner", {Parent = items["glow"]; CornerRadius = dim(0, 999)})
                library:apply_theme(items["glow"], "accent", "BackgroundColor3")

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
                -- Spring bounce on the checkbox itself
                library:tween_spring(items["toggle_button"], {Size = dim2(0, 18, 0, 18)}, 0.1)
                task.delay(0.1, function()
                    library:tween_spring(items["toggle_button"], {Size = dim2(0, 16, 0, 16)}, 0.15)
                end)
                library:tween_spring(items["tick"], {Rotation = bool and 0 or 45, ImageTransparency = bool and 0 or 1}, 0.3)
                library:tween_spring(items["toggle_button"], {BackgroundColor3 = bool and themes.preset.accent or rgb(67, 67, 68)}, 0.3)
                library:tween_spring(items["outline"], {BackgroundColor3 = bool and themes.preset.accent or rgb(22, 22, 24)}, 0.3)
                -- Glow pulse
                library:tween_spring(items["glow"], {BackgroundTransparency = bool and 0.7 or 1}, 0.35)
            else
                library:tween_spring(items["toggle_button"], {BackgroundColor3 = bool and themes.preset.accent or rgb(58, 58, 62)}, 0.35)
                library:tween_spring(items["inline"], {BackgroundColor3 = bool and themes.preset.accent or rgb(50, 50, 50)}, 0.35)
                library:tween_spring(items["circle"], {
                    BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(86, 86, 88),
                    Position = bool and dim2(1, -14, 0, 2) or dim2(0, 2, 0, 2)
                }, 0.35)
                -- Glow pulse
                library:tween_spring(items["glow"], {BackgroundTransparency = bool and 0.7 or 1}, 0.35)
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

    -- ============================================================
    --   SLIDER (with glow & pulse effects)
    -- ============================================================

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
                Size = dim2(1, 0, 0, 16);
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
                Size = dim2(1, -4, 0, 6);
                BorderSizePixel = 0;
                TextSize = 14;
                BackgroundColor3 = rgb(33, 33, 35)
            });

            library:create("UICorner", {
                Parent = items["slider"];
                CornerRadius = dim(0, 999)
            });

            -- Glow behind fill
            items["fill_glow"] = library:create("Frame", {
                Name = "\0";
                Parent = items["slider"];
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(0.5, 0, 1, 8);
                Position = dim2(0, 0, 0.5, 0);
                AnchorPoint = vec2(0, 0.5);
                BorderSizePixel = 0;
                BackgroundColor3 = themes.preset.accent;
                BackgroundTransparency = 0.85;
                ZIndex = 0;
            });
            library:create("UICorner", {Parent = items["fill_glow"]; CornerRadius = dim(0, 999)})
            library:apply_theme(items["fill_glow"], "accent", "BackgroundColor3")

            items["fill"] = library:create("Frame", {
                Name = "\0";
                Parent = items["slider"];
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(0.5, 0, 0, 6);
                BorderSizePixel = 0;
                BackgroundColor3 = themes.preset.accent;
                ZIndex = 1;
            });
            library:apply_theme(items["fill"], "accent", "BackgroundColor3");

            library:create("UICorner", {
                Parent = items["fill"];
                CornerRadius = dim(0, 999)
            });

            -- Shine effect on fill
            items["shine"] = library:create("Frame", {
                Parent = items["fill"];
                AnchorPoint = vec2(1, 0.5);
                Position = dim2(1, 0, 0.5, 0);
                Size = dim2(0, 12, 0.6, 0);
                BorderSizePixel = 0;
                BackgroundColor3 = rgb(255, 255, 255);
                BackgroundTransparency = 0.6;
                ZIndex = 2;
            });
            library:create("UICorner", {Parent = items["shine"]; CornerRadius = dim(0, 999)});

            -- Circle (thumb) with glow
            items["circle_glow"] = library:create("Frame", {
                AnchorPoint = vec2(0.5, 0.5);
                Parent = items["fill"];
                Name = "\0";
                Position = dim2(1, 0, 0.5, 0);
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(0, 18, 0, 18);
                BorderSizePixel = 0;
                BackgroundColor3 = themes.preset.accent;
                BackgroundTransparency = 0.85;
                ZIndex = 2;
            });
            library:create("UICorner", {Parent = items["circle_glow"]; CornerRadius = dim(0, 999)})
            library:apply_theme(items["circle_glow"], "accent", "BackgroundColor3")

            items["circle"] = library:create("Frame", {
                AnchorPoint = vec2(0.5, 0.5);
                Parent = items["fill"];
                Name = "\0";
                Position = dim2(1, 0, 0.5, 0);
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(0, 12, 0, 12);
                BorderSizePixel = 0;
                BackgroundColor3 = rgb(244, 244, 244);
                ZIndex = 3;
            });

            library:create("UICorner", {
                Parent = items["circle"];
                CornerRadius = dim(0, 999)
            });

            library:create("UIPadding", {
                Parent = items["right_components"];
                PaddingTop = dim(0, 5)
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

            local ratio = (cfg.max ~= cfg.min) and ((cfg.value - cfg.min) / (cfg.max - cfg.min)) or 0

            library:tween(items["fill"], {Size = dim2(ratio, 0, 1, 0)}, Enum.EasingStyle.Quint, 0.08)
            library:tween(items["fill_glow"], {Size = dim2(ratio, 0, 1, 8)}, Enum.EasingStyle.Quint, 0.08)
            items["value"].Text = tostring(cfg.value) .. cfg.suffix

            flags[cfg.flag] = cfg.value
            cfg.callback(flags[cfg.flag])
        end

        items["slider"].MouseButton1Down:Connect(function()
            cfg.dragging = true
            library:tween(items["value"], {TextColor3 = rgb(255, 255, 255)}, Enum.EasingStyle.Quad, 0.2)
            -- Pulse the circle glow when starting drag
            library:tween_spring(items["circle_glow"], {Size = dim2(0, 22, 0, 22), BackgroundTransparency = 0.7}, 0.2)
            library:tween_spring(items["circle"], {Size = dim2(0, 14, 0, 14)}, 0.2)
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
                if cfg.dragging then
                    cfg.dragging = false
                    library:tween(items["value"], {TextColor3 = rgb(72, 72, 73)}, Enum.EasingStyle.Quad, 0.2)
                    -- Shrink circle back
                    library:tween_spring(items["circle_glow"], {Size = dim2(0, 18, 0, 18), BackgroundTransparency = 0.85}, 0.25)
                    library:tween_spring(items["circle"], {Size = dim2(0, 12, 0, 12)}, 0.25)
                end
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

    -- ============================================================
    --   DROPDOWN (fixed: name uses cfg.name)
    -- ============================================================

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
                Text = cfg.name;
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
                Visible = false;
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

            -- Hover effect on options
            button.MouseEnter:Connect(function()
                if button.TextColor3 ~= themes.preset.accent then
                    library:tween(button, {TextColor3 = rgb(150, 150, 150)})
                end
            end)
            button.MouseLeave:Connect(function()
                if button.TextColor3 ~= themes.preset.accent then
                    library:tween(button, {TextColor3 = rgb(72, 72, 73)})
                end
            end)

            return button
        end

        function cfg.set_visible(bool)
            items["dropdown_holder"].Visible = bool
            local a = bool and cfg.y_size or 0
            library:tween_smooth(items["dropdown_holder"], {Size = dim_offset(items["dropdown"].AbsoluteSize.X, a)})

            items["dropdown_holder"].Position = dim2(0, items["dropdown"].AbsolutePosition.X, 0, items["dropdown"].AbsolutePosition.Y + 80)

            -- Rotate indicator
            library:tween_spring(items["indicator"], {Rotation = bool and 180 or 0}, 0.3)

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

    -- ============================================================
    --   LABEL
    -- ============================================================

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

    -- ============================================================
    --   COLORPICKER
    -- ============================================================

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
                Visible = false;
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

            items["saturation_hold"] = library:create("Frame", {
                Parent = items["colorpicker_components"];
                Name = "\0";
                Position = dim2(0, 7, 0, 7);
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(1, -14, 1, -80);
                BorderSizePixel = 0;
                BackgroundColor3 = rgb(255, 39, 39)
            });

            items["sat"] = library:create("TextButton", {
                Parent = items["saturation_hold"];
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
                Parent = items["saturation_hold"];
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
                Parent = items["saturation_hold"];
                CornerRadius = dim(0, 4)
            });

            items["satvalpicker"] = library:create("TextButton", {
                BorderColor3 = rgb(0, 0, 0);
                AutoButtonColor = false;
                Text = "";
                AnchorPoint = vec2(0, 1);
                Parent = items["saturation_hold"];
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
                BackgroundColor3 = rgb(33, 33, 35);
                TextColor3 = rgb(72, 72, 72);
                BorderColor3 = rgb(0, 0, 0);
                Position = dim2(1, -8, 1, -11);
                Size = dim2(1, -16, 0, 18);
            });

            library:create("UICorner", {
                Parent = items["input"];
                CornerRadius = dim(0, 3)
            });

            library:create("UICorner", {
                Parent = items["colorpicker_holder"];
                CornerRadius = dim(0, 4)
            });
        end;

        function cfg.set_visible(bool)
            items["colorpicker_holder"].Visible = bool
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
            library:tween(items["satvalpicker"], {Position = dim2(0, s * (items["saturation_hold"].AbsoluteSize.X - items["satvalpicker"].AbsoluteSize.X), 1, 1 - v * (items["saturation_hold"].AbsoluteSize.Y - items["satvalpicker"].AbsoluteSize.Y))}, Enum.EasingStyle.Linear, 0.05)

            items["alpha_indicator"]:FindFirstChildOfClass("UIGradient").Color = rgbseq{rgbkey(0, rgb(112, 112, 112)), rgbkey(1, hsv(h, 1, 1))};

            items["colorpicker"].BackgroundColor3 = Color
            items["colorpicker_inline"].BackgroundColor3 = Color
            items["saturation_hold"].BackgroundColor3 = hsv(h, 1, 1)

            items["hue_picker"].BackgroundColor3 = hsv(h, 1, 1)
            items["alpha_picker"].BackgroundColor3 = hsv(h, 1, 1 - a)
            items["satvalpicker"].BackgroundColor3 = hsv(h, s, v)

            flags[cfg.flag] = {
                Color = Color;
                Transparency = a
            }

            local colorVal = items["colorpicker"].BackgroundColor3
            items["input"].Text = string.format("%s, %s, %s, ", library:round(colorVal.R * 255), library:round(colorVal.G * 255), library:round(colorVal.B * 255))
            items["input"].Text ..= library:round(1 - a, 0.01)

            cfg.callback(Color, a)
        end

        function cfg.update_color()
            local mouse_pos = uis:GetMouseLocation()
            local offset = vec2(mouse_pos.X, mouse_pos.Y - gui_offset)

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
            local r, g, b, a_val = library:convert(text)

            if r and g and b and a_val then
                cfg.set(rgb(r, g, b), 1 - a_val)
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

    -- ============================================================
    --   TEXTBOX
    -- ============================================================

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

    -- ============================================================
    --   KEYBIND
    -- ============================================================

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
                BackgroundTransparency = 1;
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
                Text = "NONE";
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

            local kb_options = {"Hold", "Toggle", "Always"}

            cfg.y_size = 20
            for _, option in kb_options do
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

            items["key"].Text = __text or "NONE"

            flags[cfg.flag] = {
                mode = cfg.mode,
                key = cfg.key,
                active = cfg.active
            }
        end

        function cfg.set_visible(bool)
            local size = bool and cfg.y_size or 0
            library:tween(items["dropdown"], {Size = dim_offset(items["keybind_holder"].AbsoluteSize.X, size)})

            items["dropdown"].Position = dim_offset(
                items["keybind_holder"].AbsolutePosition.X,
                items["keybind_holder"].AbsolutePosition.Y + items["keybind_holder"].AbsoluteSize.Y + 60
            )
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

    -- ============================================================
    --   BUTTON
    -- ============================================================

    function library:button(options)
        local cfg = {
            name = options.name or "Button",
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

            -- Flash accent color then fade back
            items["name"].TextColor3 = themes.preset.accent
            library:tween(items["name"], {TextColor3 = rgb(245, 245, 245)})

            -- Slight scale pulse
            library:tween_spring(items["button"], {Size = dim2(1, -6, 0, 31)}, 0.1)
            task.delay(0.1, function()
                library:tween_spring(items["button"], {Size = dim2(1, -8, 0, 30)}, 0.15)
            end)
        end)

        -- Hover effect
        items["button"].MouseEnter:Connect(function()
            library:tween(items["button"], {BackgroundColor3 = rgb(40, 40, 42)})
        end)
        items["button"].MouseLeave:Connect(function()
            library:tween(items["button"], {BackgroundColor3 = rgb(33, 33, 35)})
        end)

        return setmetatable(cfg, library)
    end

    -- ============================================================
    --   SETTINGS (fixed: removed broken items["fade"] reference)
    -- ============================================================

    function library:settings(options)
        local cfg = {
            open = false;
            items = {};
            sanity = true;
        }

        local items = cfg.items; do
            items["outline"] = library:create("Frame", {
                Name = "\0";
                Visible = false;
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
            items["outline"].Visible = bool
            library:tween_smooth(items["outline"], {Size = dim_offset(bool and 240 or 0, 0)})
            items["outline"].Position = dim_offset(
                items["tick"].AbsolutePosition.X,
                items["tick"].AbsolutePosition.Y + 90
            )
            library:close_element(cfg)
        end

        items["tick"].MouseButton1Click:Connect(function()
            cfg.open = not cfg.open

            cfg.set_visible(cfg.open)
        end)

        return setmetatable(cfg, library)
    end

    -- ============================================================
    --   LIST
    -- ============================================================

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

            cfg.data_store = {}

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

    -- ============================================================
    --   INIT CONFIG
    -- ============================================================

    function library:init_config(window)
        window:seperator({name = "Settings"})
        local main = window:tab({name = "Configs", tabs = {"Main"}})

        local column = main:column({})
        local section = column:section({name = "Configs", size = 1, default = true, icon = "rbxassetid://139628202576511"})
        config_holder = section:list({options = {"Report", "This", "Error", "To", "Finobe"}, callback = function(option) end, flag = "config_name_list"}); library:update_config_list()

        local column = main:column({})
        local section = column:section({name = "Settings", side = "right", size = 1, default = true, icon = "rbxassetid://129380150574313"})
        section:textbox({name = "Config name:", flag = "config_name_text"})
        section:button({name = "Save", callback = function() writefile(library.directory .. "/configs/" .. flags["config_name_text"] or flags["config_name_list"] .. ".cfg", library:get_config()) library:update_config_list() notifications:create_notification({name = "Configs", info = "Saved config to:\n" .. flags["config_name_list"] or flags["config_name_text"]}) end})
        section:button({name = "Load", callback = function() library:load_config(readfile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg"))  library:update_config_list() notifications:create_notification({name = "Configs", info = "Loaded config:\n" .. flags["config_name_list"]}) end})
        section:button({name = "Delete", callback = function() delfile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg")  library:update_config_list() notifications:create_notification({name = "Configs", info = "Deleted config:\n" .. flags["config_name_list"]}) end})
        section:colorpicker({name = "Menu Accent", callback = function(color, alpha) library:update_theme("accent", color) end, color = themes.preset.accent})
        section:keybind({name = "Menu Bind", callback = function(bool) window.toggle_menu(bool) end, default = true})
    end

    -- ============================================================
    --   PLAYER LIST (improved: search, avatar, displayname, username)
    -- ============================================================

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
            all_players_data = {},
        }

        flags[cfg.flag] = cfg.current_selection

        local items = cfg.items; do
            items["list_object"] = library:create("Frame", {
                Parent = self.items["elements"];
                Name = "\0";
                BackgroundTransparency = 1;
                Size = dim2(1, 0, 0, 0);
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.Y;
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

            -- Search bar built-in
            items["search"] = library:create("TextBox", {
                FontFace = fonts.font;
                Text = "";
                Parent = items["list_object"];
                Name = "\0";
                PlaceholderText = "Search players...";
                PlaceholderColor3 = rgb(80, 80, 82);
                BorderSizePixel = 0;
                CursorPosition = -1;
                ClearTextOnFocus = false;
                TextSize = 13;
                BackgroundColor3 = rgb(28, 28, 30);
                TextColor3 = rgb(245, 245, 245);
                Position = dim2(0, 4, 0, 20);
                Size = dim2(1, -8, 0, 26);
            });
            library:create("UICorner", {Parent = items["search"]; CornerRadius = dim(0, 5)});
            library:create("UIPadding", {Parent = items["search"]; PaddingLeft = dim(0, 6); PaddingRight = dim(0, 6)});

            -- Scrolling container for player rows
            items["scroll"] = library:create("ScrollingFrame", {
                ScrollBarImageColor3 = themes.preset.accent;
                Active = true;
                AutomaticCanvasSize = Enum.AutomaticSize.Y;
                ScrollBarThickness = 2;
                BorderSizePixel = 0;
                BorderColor3 = rgb(0, 0, 0);
                CanvasSize = dim2(0, 0, 0, 0);
                Parent = items["list_object"];
                Name = "\0";
                BackgroundColor3 = rgb(18, 18, 20);
                Size = dim2(1, 0, 0, cfg.max_height);
                Position = dim2(0, 0, 0, 50);
            });
            library:apply_theme(items["scroll"], "accent", "ScrollBarImageColor3")

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
                Padding = dim(0, 2);
                SortOrder = Enum.SortOrder.LayoutOrder;
            });

            library:create("UIPadding", {
                PaddingRight = dim(0, 4);
                PaddingLeft = dim(0, 4);
                Parent = items["scroll"]
            });

            -- Player count label
            items["count"] = library:create("TextLabel", {
                FontFace = fonts.small;
                TextColor3 = rgb(72, 72, 73);
                BorderColor3 = rgb(0, 0, 0);
                Text = "0 players";
                Parent = items["list_object"];
                Name = "\0";
                Size = dim2(0, 0, 0, 0);
                Position = dim2(1, -4, 0, 0);
                AnchorPoint = vec2(1, 0);
                BackgroundTransparency = 1;
                TextXAlignment = Enum.TextXAlignment.Right;
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.XY;
                TextSize = 12;
                BackgroundColor3 = rgb(255, 255, 255)
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
                Size = dim2(1, 0, 0, 34);
                BorderSizePixel = 0;
                TextSize = 14;
                BackgroundColor3 = rgb(28, 28, 30)
            });

            library:create("UICorner", {
                Parent = row;
                CornerRadius = dim(0, 5)
            });

            -- Accent indicator bar on left (hidden until selected)
            local indicator = library:create("Frame", {
                Parent = row;
                Name = "\0";
                Size = dim2(0, 3, 0.6, 0);
                Position = dim2(0, 0, 0.5, 0);
                AnchorPoint = vec2(0, 0.5);
                BorderSizePixel = 0;
                BackgroundColor3 = themes.preset.accent;
                BackgroundTransparency = 1;
                ZIndex = 2;
            });
            library:create("UICorner", {Parent = indicator; CornerRadius = dim(0, 999)})
            library:apply_theme(indicator, "accent", "BackgroundColor3")

            local headshot_size = 24
            local avatar = library:create("ImageLabel", {
                Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", player.UserId);
                BorderColor3 = rgb(0, 0, 0);
                Parent = row;
                Name = "\0";
                BackgroundColor3 = rgb(40, 40, 42);
                Size = dim2(0, headshot_size, 0, headshot_size);
                Position = dim2(0, 8, 0.5, 0);
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
                Size = dim2(1, -70, 0, 16);
                Position = dim2(0, 38, 0, 4);
                BackgroundTransparency = 1;
                TextXAlignment = Enum.TextXAlignment.Left;
                BorderSizePixel = 0;
                TextTruncate = Enum.TextTruncate.AtEnd;
                TextSize = 13;
                BackgroundColor3 = rgb(255, 255, 255)
            });

            local username = library:create("TextLabel", {
                FontFace = fonts.small;
                TextColor3 = rgb(80, 80, 82);
                BorderColor3 = rgb(0, 0, 0);
                Text = "@" .. player.Name;
                Parent = row;
                Name = "\0";
                Size = dim2(1, -70, 0, 12);
                Position = dim2(0, 38, 0, 19);
                BackgroundTransparency = 1;
                TextXAlignment = Enum.TextXAlignment.Left;
                BorderSizePixel = 0;
                TextTruncate = Enum.TextTruncate.AtEnd;
                TextSize = 11;
                BackgroundColor3 = rgb(255, 255, 255)
            });

            -- "You" badge for local player
            if player == lp then
                local badge = library:create("TextLabel", {
                    FontFace = fonts.small;
                    TextColor3 = rgb(255, 255, 255);
                    Text = "YOU";
                    Parent = row;
                    Name = "\0";
                    Size = dim2(0, 0, 0, 14);
                    Position = dim2(1, -8, 0.5, 0);
                    AnchorPoint = vec2(1, 0.5);
                    AutomaticSize = Enum.AutomaticSize.X;
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    BorderSizePixel = 0;
                    TextSize = 10;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                library:create("UIPadding", {Parent = badge; PaddingLeft = dim(0, 4); PaddingRight = dim(0, 4)});
            end

            row.MouseButton1Click:Connect(function()
                for _, b in cfg.player_buttons do
                    if b and b.Parent then
                        library:tween(b, {BackgroundColor3 = rgb(28, 28, 30)})
                        local ind = b:FindFirstChildWhichIsA("Frame")
                        if ind then
                            library:tween(ind, {BackgroundTransparency = 1})
                        end
                    end
                end
                cfg.current_selection = player
                flags[cfg.flag] = player
                library:tween_spring(row, {BackgroundColor3 = rgb(35, 35, 40)}, 0.2)
                library:tween_spring(indicator, {BackgroundTransparency = 0}, 0.25)
                cfg.callback(player)
            end)

            row.MouseEnter:Connect(function()
                if cfg.current_selection ~= player then
                    library:tween(row, {BackgroundColor3 = rgb(35, 35, 37)})
                end
            end)

            row.MouseLeave:Connect(function()
                if cfg.current_selection ~= player then
                    library:tween(row, {BackgroundColor3 = rgb(28, 28, 30)})
                end
            end)

            return row, player
        end

        local function refresh(filter)
            filter = filter or items["search"].Text or ""

            for _, b in cfg.player_buttons do
                if b and b.Parent then
                    b:Destroy()
                end
            end
            cfg.player_buttons = {}

            local list = {}
            for _, p in players:GetPlayers() do
                if p ~= lp or cfg.include_self then
                    local match = filter == ""
                        or p.DisplayName:lower():find(filter:lower(), 1, true)
                        or p.Name:lower():find(filter:lower(), 1, true)
                    if match then
                        list[#list + 1] = p
                    end
                end
            end
            table.sort(list, function(a, b)
                return a.DisplayName:lower() < b.DisplayName:lower()
            end)

            for _, p in list do
                local row = make_row(p)
                cfg.player_buttons[#cfg.player_buttons + 1] = row
            end

            items["count"].Text = #list .. " player" .. (#list ~= 1 and "s" or "")
        end

        refresh("")

        -- Search filter
        items["search"]:GetPropertyChangedSignal("Text"):Connect(function()
            refresh(items["search"].Text)
        end)

        items["search"].Focused:Connect(function()
            library:tween(items["search"], {BackgroundColor3 = rgb(35, 35, 37)})
        end)
        items["search"].FocusLost:Connect(function()
            library:tween(items["search"], {BackgroundColor3 = rgb(28, 28, 30)})
        end)

        -- Auto-refresh when players join/leave
        library:connection(players.PlayerAdded, function()
            refresh()
        end)
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

    -- ============================================================
    --   V2 NEW ELEMENTS
    -- ============================================================

    function library:search(options)
        options = options or {}
        local cfg = {
            name = options.name or "Search",
            placeholder = options.placeholder or "search...",
            flag = options.flag or library:next_flag(),
            target = options.target,
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

        function cfg.track(name, get_active, get_key)
            cfg.tracked[#cfg.tracked + 1] = {name = name, get_active = get_active, get_key = get_key, row = nil}
        end

        function cfg.refresh()
            for _, child in items["list"]:GetChildren() do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end

            for _, entry in cfg.tracked do
                local active = entry.get_active and entry.get_active() or false
                local key = entry.get_key and entry.get_key() or "?"

                if key and key ~= "NONE" and tostring(key) ~= "Enums" then
                    library:create("TextLabel", {
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

        task.spawn(function()
            while library and library.items and items["outline"] and items["outline"].Parent do
                cfg.refresh()
                task.wait(0.25)
            end
        end)

        return setmetatable(cfg, library)
    end

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
                TextColor3 = rgb(245, 245, 245);
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
                library:tween_spring(btn, {BackgroundColor3 = btn_cfg.active and themes.preset.accent or rgb(33, 33, 35)})
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
            local ratio = (cfg.max ~= cfg.min) and ((cfg.value - cfg.min) / (cfg.max - cfg.min)) or 0
            library:tween_smooth(items["fill"], {Size = dim2(ratio, 0, 1, 0)}, cfg.smoothing)
            items["value"].Text = string.format("%d / %d", cfg.value, cfg.max)
            cfg.callback(cfg.value)
        end

        cfg.set(cfg.value)

        function cfg.set_color(color)
            items["fill"].BackgroundColor3 = color
        end

        return setmetatable(cfg, library)
    end

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

    function library:set_animation(style)
        library.animation_style = style
    end
    --

    -- ============================================================
    --   NOTIFICATION LIBRARY (fixed: BackgroundTransparency bug)
    -- ============================================================

    function notifications:refresh_notifs()
        local offset = 50
        for i, v in notifications.notifs do
            if v and v.Parent then
                local Position = vec2(20, offset)
                library:tween(v, {Position = dim_offset(Position.X, Position.Y)}, Enum.EasingStyle.Quad, 0.4)
                offset += (v.AbsoluteSize.Y + 10)
            end
        end
        return offset
    end

    function notifications:fade(path, is_fading)
        local fading = is_fading and 1 or 0

        library:tween(path, {BackgroundTransparency = fading}, Enum.EasingStyle.Quad, 1)

        for _, instance in path:GetDescendants() do
            if instance:IsA("UIStroke") then
                library:tween(instance, {Transparency = fading}, Enum.EasingStyle.Quad, 1)
            elseif instance:IsA("TextLabel") then
                library:tween(instance, {TextTransparency = fading})
            elseif instance:IsA("Frame") then
                local target_transparency = is_fading and 1 or 0.6
                library:tween(instance, {BackgroundTransparency = target_transparency}, Enum.EasingStyle.Quad, 1)
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

            items["bar"] = library:create("Frame", {
                AnchorPoint = vec2(0, 1);
                Parent = items["notification"];
                Name = "\0";
                Position = dim2(0, 8, 1, -6);
                BorderColor3 = rgb(0, 0, 0);
                Size = dim2(0, 0, 0, 5);
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                BackgroundColor3 = themes.preset.accent
            });
            library:apply_theme(items["bar"], "accent", "BackgroundColor3");

            library:create("UICorner", {
                Parent = items["bar"];
                CornerRadius = dim(0, 999)
            });

            library:create("UIPadding", {
                PaddingRight = dim(0, 8);
                Parent = items["notification"]
            });
        end

        local index = #notifications.notifs + 1
        notifications.notifs[index] = items["notification"]

        notifications:fade(items["notification"], false)

        local offset = notifications:refresh_notifs()

        items["notification"].Position = dim_offset(20, offset)

        library:tween(items["notification"], {AnchorPoint = vec2(0, 0)}, Enum.EasingStyle.Quad, 1)
        library:tween(items["bar"], {Size = dim2(1, -8, 0, 5)}, Enum.EasingStyle.Quad, cfg.lifetime)

        task.spawn(function()
            task.wait(cfg.lifetime)

            notifications.notifs[index] = nil

            notifications:fade(items["notification"], true)

            library:tween(items["notification"], {AnchorPoint = vec2(1, 0)}, Enum.EasingStyle.Quad, 1)

            task.wait(1)

            if items["notification"] and items["notification"].Parent then
                items["notification"]:Destroy()
            end
        end)
    end
--

return library
