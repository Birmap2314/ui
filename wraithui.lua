--[[
	Wraith.UI · premium Luau interface library
	liquid glass · micro-animations · full element set
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Wraith = {
	Flags = {},
	Setters = {},
	Theme = {
		Accent = Color3.fromRGB(129, 97, 255),
		Background = Color3.fromRGB(11, 11, 14),
		Topbar = Color3.fromRGB(15, 15, 19),
		Sidebar = Color3.fromRGB(13, 13, 17),
		Card = Color3.fromRGB(18, 18, 23),
		Element = Color3.fromRGB(23, 23, 29),
		Hover = Color3.fromRGB(29, 29, 36),
		Stroke = Color3.fromRGB(37, 37, 45),
		Text = Color3.fromRGB(236, 236, 242),
		Sub = Color3.fromRGB(126, 126, 140),
	},
	Logo = "rbxassetid://129691721280832",
	Folder = "WraithUI",
}
Wraith.__index = Wraith

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

local function Protect(gui)
	if protectgui then pcall(protectgui, gui)
	elseif syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
end

local function GetHost()
	if gethui then local ok, h = pcall(gethui) if ok and h then return h end end
	return CoreGui
end

local function New(class, props)
	local inst = Instance.new(class)
	if props then
		local parent = props.Parent
		props.Parent = nil
		for k, v in pairs(props) do inst[k] = v end
		props.Parent = parent
		if parent then inst.Parent = parent end
	end
	return inst
end

local function Tween(inst, time, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Corner(inst, r)
	return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = inst })
end

local function Glass(inst, r, trans)
	inst.BackgroundTransparency = trans or 0.4
	Corner(inst, r)
	local s = New("UIStroke", { Color = Wraith.Theme.Stroke, Thickness = 1, Transparency = 0.35, Parent = inst })
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 0.85),
		}),
		Parent = s,
	})
	New("UIGradient", {
		Rotation = 32,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.88),
			NumberSequenceKeypoint.new(0.5, 0.96),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = inst,
	})
	return s
end

local function Sheen(host)
	local line = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.5,
		Size = UDim2.new(0, 34, 1, 30),
		Position = UDim2.new(-0.35, 0, 0, -15),
		Rotation = 18,
		Visible = false,
		ZIndex = 9,
		Parent = host,
	})
	Corner(line, 99)
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = line,
	})
	host.MouseEnter:Connect(function()
		line.Visible = true
		line.Position = UDim2.new(-0.35, 0, 0, -15)
		local tw = Tween(line, 0.55, { Position = UDim2.new(1.15, 0, 0, -15) }, Enum.EasingStyle.Quad)
		tw.Completed:Connect(function() line.Visible = false end)
	end)
end

local function Hover(inst, enter, leave)
	inst.MouseEnter:Connect(function() Tween(inst, 0.18, enter) end)
	inst.MouseLeave:Connect(function() Tween(inst, 0.18, leave) end)
end

local function Round(value, step)
	local m = 1 / (step or 1)
	return math.floor(value * m + 0.5) / m
end

local function CaptureTransparency(root)
	local function cap(inst)
		if inst:IsA("GuiObject") then inst:SetAttribute("BaseBT", inst.BackgroundTransparency) end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then inst:SetAttribute("BaseTT", inst.TextTransparency) end
		if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then inst:SetAttribute("BaseIT", inst.ImageTransparency) end
		if inst:IsA("UIStroke") then inst:SetAttribute("BaseST", inst.Transparency) end
	end
	cap(root)
	for _, d in ipairs(root:GetDescendants()) do cap(d) end
end

local function FadeGui(root, show, speed)
	speed = speed or 0.25
	local function apply(inst)
		local bb = inst:GetAttribute("BaseBT")
		if bb then Tween(inst, speed, { BackgroundTransparency = show and bb or 1 }) end
		local tt = inst:GetAttribute("BaseTT")
		if tt then Tween(inst, speed, { TextTransparency = show and tt or 1 }) end
		local it = inst:GetAttribute("BaseIT")
		if it then Tween(inst, speed, { ImageTransparency = show and it or 1 }) end
		local st = inst:GetAttribute("BaseST")
		if st then Tween(inst, speed, { Transparency = show and st or 1 }) end
	end
	apply(root)
	for _, d in ipairs(root:GetDescendants()) do apply(d) end
end

local Blur = { Part = nil, Mesh = nil, Effect = nil, Frame = nil, Conn = nil }

function Blur:Bind(frame)
	self.Frame = frame
	if self.Conn then return end
	pcall(function()
		self.Part = New("Part", {
			Material = Enum.Material.Glass, Transparency = 1, Reflectance = 1,
			CastShadow = false, Anchored = true, CanCollide = false, CanQuery = false,
			Size = Vector3.new(0.01, 0.01, 0.01), Color = Color3.fromRGB(0, 0, 0), Parent = Camera,
		})
		self.Mesh = New("BlockMesh", { Parent = self.Part })
		self.Effect = New("DepthOfFieldEffect", {
			Parent = Lighting, Enabled = true, FarIntensity = 0, FocusDistance = 0, InFocusRadius = 1000, NearIntensity = 0,
		})
	end)
	if not self.Part then return end
	self.Conn = RunService.RenderStepped:Connect(function()
		local f = self.Frame
		if not f or not f.Parent or not f.Visible then
			self.Effect.NearIntensity = math.max(self.Effect.NearIntensity - 0.06, 0)
			self.Mesh.Scale = Vector3.new(0, 0, 0)
			return
		end
		self.Effect.NearIntensity = math.min(self.Effect.NearIntensity + 0.06, 1)
		local c0 = f.AbsolutePosition
		local c1 = c0 + f.AbsoluteSize
		local r0 = Camera:ScreenPointToRay(c0.X, c0.Y, 1)
		local r1 = Camera:ScreenPointToRay(c1.X, c1.Y, 1)
		local origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ)
		local n = Camera.CFrame.LookVector
		local function hit(ro, rd)
			local v = ro - origin
			local num = n.X * v.X + n.Y * v.Y + n.Z * v.Z
			local den = n.X * rd.X + n.Y * rd.Y + n.Z * rd.Z
			return origin + (-num / den) * rd
		end
		local p0 = Camera.CFrame:PointToObjectSpace(hit(r0.Origin, r0.Direction))
		local p1 = Camera.CFrame:PointToObjectSpace(hit(r1.Origin, r1.Direction))
		self.Mesh.Offset = (p0 + p1) / 2
		self.Mesh.Scale = (p1 - p0) / 0.0101
		self.Part.CFrame = Camera.CFrame
		self.Part.Transparency = 0.97
	end)
end

local NotifGui = nil

function Wraith:Notify(cfg)
	cfg = cfg or {}
	if not NotifGui then
		NotifGui = New("ScreenGui", { Name = "WraithNotifs", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
		Protect(NotifGui)
		NotifGui.Parent = GetHost()
	end
	local holder = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 40, 0, 16 + #NotifGui:GetChildren() * 74),
		Size = UDim2.new(0, 300, 0, 64),
		BackgroundTransparency = 1,
		Parent = NotifGui,
	})
	local card = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Wraith.Theme.Card,
		ClipsDescendants = true,
		Parent = holder,
	})
	Glass(card, 10, 0.25)
	local bar = New("Frame", {
		Size = UDim2.new(0, 3, 1, -20),
		Position = UDim2.new(0, 8, 0, 10),
		BackgroundColor3 = Wraith.Theme.Accent,
		Parent = card,
	})
	Corner(bar, 99)
	local title = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 9),
		Size = UDim2.new(1, -30, 0, 16),
		Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Title or "Wraith",
		Parent = card,
	})
	local desc = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 27),
		Size = UDim2.new(1, -30, 0, 30),
		Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = Wraith.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = cfg.Description or "",
		Parent = card,
	})
	local progress = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Wraith.Theme.Accent,
		BackgroundTransparency = 0.4,
		Parent = card,
	})
	CaptureTransparency(holder)
	Tween(holder, 0.35, { Position = UDim2.new(1, -16, 0, 16 + (#NotifGui:GetChildren() - 1) * 74) }, Enum.EasingStyle.Back)
	Tween(progress, cfg.Duration or 4, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay((cfg.Duration or 4) + 0.1, function()
		FadeGui(holder, false, 0.2)
		task.wait(0.25)
		holder:Destroy()
	end)
end

function Wraith:CreateWindow(cfg)
	cfg = cfg or {}
	if cfg.Accent then Wraith.Theme.Accent = cfg.Accent end
	local win = setmetatable({}, Window)
	win.Tabs = {}
	win.Registry = {}
	win.AccentAppliers = {}
	win.Open = true
	win.Title = cfg.Title or "Wraith"

	if isfolder and not isfolder(Wraith.Folder) then pcall(makefolder, Wraith.Folder) end

	local gui = New("ScreenGui", { Name = "WraithUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998 })
	Protect(gui)
	gui.Parent = GetHost()
	win.Gui = gui

	local shadow = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, (cfg.Size and cfg.Size.X.Offset or 680) + 40, 0, (cfg.Size and cfg.Size.Y.Offset or 460) + 40),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Parent = gui,
	})

	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = cfg.Size or UDim2.new(0, 680, 0, 460),
		BackgroundColor3 = Wraith.Theme.Background,
		ClipsDescendants = true,
		Parent = gui,
	})
	win.Main = main
	Glass(main, 14, 0.12)

	local scale = New("UIScale", { Scale = 0.94, Parent = main })

	local topbar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Wraith.Theme.Topbar,
		BackgroundTransparency = 0.35,
		ClipsDescendants = true,
		Parent = main,
	})
	New("Frame", {
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Wraith.Theme.Stroke,
		Parent = topbar,
	})

	local logo = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1,
		Image = cfg.Logo or Wraith.Logo,
		ImageColor3 = Wraith.Theme.Accent,
		Parent = topbar,
	})

	local title = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 46, 0.5, -8),
		Size = UDim2.new(0, 220, 0, 16),
		Font = Enum.Font.GothamBlack, TextSize = 15,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = win.Title,
		Parent = topbar,
	})
	local subtitle = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 46, 0.5, 8),
		Size = UDim2.new(0, 220, 0, 12),
		Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = Wraith.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Subtitle or "premium interface",
		Parent = topbar,
	})

	local search = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -96, 0.5, 0),
		Size = UDim2.new(0, 170, 0, 28),
		BackgroundColor3 = Wraith.Theme.Element,
		Text = "", PlaceholderText = "search...",
		PlaceholderColor3 = Wraith.Theme.Sub,
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		ClearTextOnFocus = false,
		Parent = topbar,
	})
	Glass(search, 8, 0.5)
	New("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = search })

	local closeBtn = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 28),
		AutoButtonColor = false, Text = "",
		BackgroundColor3 = Wraith.Theme.Element,
		ClipsDescendants = true,
		Parent = topbar,
	})
	Glass(closeBtn, 8, 0.5)
	local closeIcon = New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Wraith.Theme.Sub,
		Text = "X",
		Parent = closeBtn,
	})
	Hover(closeBtn, { BackgroundColor3 = Color3.fromRGB(60, 24, 32) }, { BackgroundColor3 = Wraith.Theme.Element })
	Hover(closeIcon, { TextColor3 = Color3.fromRGB(255, 90, 100) }, { TextColor3 = Wraith.Theme.Sub })
	Sheen(closeBtn)

	local sidebar = New("Frame", {
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(0, 150, 1, -48),
		BackgroundColor3 = Wraith.Theme.Sidebar,
		BackgroundTransparency = 0.35,
		Parent = main,
	})
	New("Frame", {
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Wraith.Theme.Stroke,
		Parent = sidebar,
	})

	local tabScroll = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -20),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	local tabLayout = New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabScroll })
	New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = tabScroll })

	local indicator = New("Frame", {
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(0, 3, 0, 24),
		BackgroundColor3 = Wraith.Theme.Accent,
		Parent = sidebar,
	})
	Corner(indicator, 99)
	win.Indicator = indicator

	local pages = New("Frame", {
		Position = UDim2.new(0, 150, 0, 48),
		Size = UDim2.new(1, -150, 1, -48),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})
	win.Pages = pages

	local dragging, dragStart, startPos = false, nil, nil
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			shadow.Position = main.Position
		end
	end)

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = search.Text:lower()
		for _, entry in ipairs(win.Registry) do
			entry.Frame.Visible = (q == "" or entry.Name:find(q, 1, true) ~= nil)
		end
	end)

	closeBtn.MouseButton1Click:Connect(function() win:Destroy() end)

	function win:SelectTab(target)
		for _, t in ipairs(win.Tabs) do
			local active = (t == target)
			t.Page.Visible = active
			if active then
				t.Page.Position = UDim2.new(0, 14, 0, 0)
				Tween(t.Page, 0.35, { Position = UDim2.new(0, 0, 0, 0) })
			end
			Tween(t.Button, 0.2, { BackgroundTransparency = active and 0.25 or 0.65 })
			Tween(t.Label, 0.2, { TextColor3 = active and Wraith.Theme.Text or Wraith.Theme.Sub })
			Tween(t.Icon, 0.2, { ImageColor3 = active and Wraith.Theme.Accent or Wraith.Theme.Sub })
			t.Stroke.Transparency = active and 0.1 or 0.5
		end
		Tween(indicator, 0.3, { Position = UDim2.new(0, 0, 0, target.Button.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + 6) }, Enum.EasingStyle.Back)
		win.ActiveTab = target
	end

	function win:AddTab(cfg)
		cfg = cfg or {}
		local tab = setmetatable({}, Tab)
		tab.Window = win
		tab.Name = cfg.Name or "Tab"

		local btn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 36),
			AutoButtonColor = false, Text = "",
			BackgroundColor3 = Wraith.Theme.Element,
			ClipsDescendants = true,
			Parent = tabScroll,
		})
		tab.Button = btn
		tab.Stroke = Glass(btn, 9, 0.65)
		Sheen(btn)
		Hover(btn, { BackgroundTransparency = 0.4 }, { BackgroundTransparency = win.ActiveTab == tab and 0.25 or 0.65 })

		local icon = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			Image = cfg.Icon or "rbxassetid://10709782497",
			ImageColor3 = Wraith.Theme.Sub,
			Parent = btn,
		})
		tab.Icon = icon
		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 36, 0, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Wraith.Theme.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = tab.Name,
			Parent = btn,
		})
		tab.Label = label

		local page = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = pages,
		})
		tab.Page = page
		local cols = {}
		for i = 1, 2 do
			local col = New("ScrollingFrame", {
				Position = UDim2.new((i - 1) * 0.5, i == 1 and 6 or 3, 0, 6),
				Size = UDim2.new(0.5, -9, 1, -12),
				BackgroundTransparency = 1,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Wraith.Theme.Stroke,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = page,
			})
			col.Visible = true
			New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
			cols[i] = col
		end
		tab.Columns = cols

		btn.MouseButton1Click:Connect(function() win:SelectTab(tab) end)

		table.insert(win.Tabs, tab)
		if #win.Tabs == 1 then
			task.wait()
			win:SelectTab(tab)
		end
		CaptureTransparency(btn)
		return tab
	end

	function win:SetOpen(bool)
		win.Open = bool
		if bool then main.Visible = true; shadow.Visible = true end
		FadeGui(gui, bool, 0.25)
		Tween(scale, 0.3, { Scale = bool and 1 or 0.96 })
		task.wait(0.26)
		if not bool then main.Visible = false; shadow.Visible = false end
	end

	function win:Toggle() win:SetOpen(not win.Open) end

	function win:Destroy()
		FadeGui(gui, false, 0.2)
		task.wait(0.25)
		gui:Destroy()
	end

	function win:ChangeAccent(color)
		Wraith.Theme.Accent = color
		logo.ImageColor3 = color
		indicator.BackgroundColor3 = color
		for _, fn in ipairs(win.AccentAppliers) do pcall(fn) end
	end

	function win:Notify(n) Wraith:Notify(n) end

	function win:SaveConfig(name)
		if not writefile then return end
		local data = {}
		for flag, value in pairs(Wraith.Flags) do
			data[flag] = Wraith.Encode(value)
		end
		writefile(Wraith.Folder .. "/" .. (name or "default") .. ".json", HttpService:JSONEncode(data))
	end

	function win:LoadConfig(name)
		if not readfile or not isfile then return end
		local path = Wraith.Folder .. "/" .. (name or "default") .. ".json"
		if not isfile(path) then return end
		local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
		if not ok then return end
		for flag, enc in pairs(decoded) do
			local setter = Wraith.Setters[flag]
			if setter then pcall(setter, Wraith.Decode(enc)) end
		end
	end

	function win:GetConfigs()
		if not listfiles then return {} end
		local out = {}
		for _, f in ipairs(listfiles(Wraith.Folder)) do
			local name = f:match("([^\\/]+)%.json$")
			if name then table.insert(out, name) end
		end
		return out
	end

	function win:DeleteConfig(name)
		if delfile and isfile and isfile(Wraith.Folder .. "/" .. name .. ".json") then
			delfile(Wraith.Folder .. "/" .. name .. ".json")
		end
	end

	win.ToggleKey = cfg.Keybind or Enum.KeyCode.RightControl
	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == win.ToggleKey then win:Toggle() end
	end)

	if cfg.Blur ~= false then Blur:Bind(main) end

	CaptureTransparency(gui)
	Tween(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	FadeGui(gui, true, 0.4)

	return win
end

function Wraith.Encode(v)
	local tv = typeof(v)
	if tv == "Color3" then return { __t = "c", r = v.R, g = v.G, b = v.B } end
	if tv == "table" then
		local out = {}
		for k, vv in pairs(v) do out[k] = Wraith.Encode(vv) end
		return out
	end
	if tv == "EnumItem" then return v.Name end
	return v
end

function Wraith.Decode(v)
	if type(v) == "table" then
		if v.__t == "c" then return Color3.new(v.r or 1, v.g or 1, v.b or 1) end
		local out = {}
		for k, vv in pairs(v) do out[k] = Wraith.Decode(vv) end
		return out
	end
	return v
end

function Tab:AddSection(cfg)
	cfg = cfg or {}
	local sec = setmetatable({}, Section)
	sec.Window = self.Window
	sec.Tab = self
	local side = math.clamp(cfg.Side or 1, 1, 2)

	local root = New("Frame", {
		BackgroundColor3 = Wraith.Theme.Card,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Columns[side],
	})
	sec.Root = root
	Glass(root, 10, 0.55)

	local header = New("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local dot = New("Frame", {
		Position = UDim2.new(0, 12, 0.5, -1),
		Size = UDim2.new(0, 6, 0, 6),
		BackgroundColor3 = Wraith.Theme.Accent,
		Parent = header,
	})
	Corner(dot, 99)
	table.insert(self.Window.AccentAppliers, function() dot.BackgroundColor3 = Wraith.Theme.Accent end)
	local name = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 26, 0.5, -8),
		Size = UDim2.new(1, -34, 0, 15),
		Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Section",
		Parent = header,
	})
	if cfg.Description then
		local d = New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 26, 0.5, 7),
			Size = UDim2.new(1, -34, 0, 11),
			Font = Enum.Font.Gotham, TextSize = 10,
			TextColor3 = Wraith.Theme.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = cfg.Description,
			Parent = header,
		})
		header.Size = UDim2.new(1, 0, 0, 40)
	end
	New("Frame", {
		Position = UDim2.new(0, 10, 1, 0),
		Size = UDim2.new(1, -20, 0, 1),
		BackgroundColor3 = Wraith.Theme.Stroke,
		Parent = header,
	})

	local content = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = root,
	})
	sec.Content = content
	New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	New("UIPadding", {
		PadTop = UDim.new(0, 8), PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
		Parent = content,
	})

	function sec:Register(frame, label)
		table.insert(self.Window.Registry, { Name = (label or ""):lower(), Frame = frame })
	end

	CaptureTransparency(root)
	return sec
end

function Section:AddLabel(text)
	local lbl = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "   " .. tostring(text),
		Parent = self.Content,
	})
	self:Register(lbl, tostring(text))
	CaptureTransparency(lbl)
	local obj = {}
	function obj:SetText(t) lbl.Text = "   " .. tostring(t) end
	return obj
end

function Section:AddParagraph(cfg)
	cfg = cfg or {}
	local root = New("Frame", {
		BackgroundColor3 = Wraith.Theme.Element,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Content,
	})
	Glass(root, 8, 0.5)
	local t = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 16),
		Position = UDim2.new(0, 8, 0, 6),
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Title or "",
		Parent = root,
	})
	local c = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 24),
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = Wraith.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = cfg.Content or "",
		Parent = root,
	})
	self:Register(root, cfg.Title)
	CaptureTransparency(root)
	local obj = {}
	function obj:Set(nc) if nc.Title then t.Text = nc.Title end if nc.Content then c.Text = nc.Content end end
	return obj
end

function Section:AddDivider()
	local d = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 6),
		Parent = self.Content,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -20, 0, 1),
		BackgroundColor3 = Wraith.Theme.Stroke,
		Parent = d,
	})
	CaptureTransparency(d)
	return d
end

function Section:AddButton(cfg)
	cfg = cfg or {}
	local btn = New("TextButton", {
		AutoButtonColor = false, Text = "",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Wraith.Theme.Element,
		ClipsDescendants = true,
		Parent = self.Content,
	})
	Glass(btn, 8, 0.5)
	Sheen(btn)
	Hover(btn, { BackgroundColor3 = Wraith.Theme.Hover }, { BackgroundColor3 = Wraith.Theme.Element })
	local label = New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		Text = cfg.Name or "Button",
		Parent = btn,
	})
	local bs = New("UIScale", { Scale = 1, Parent = btn })
	btn.MouseButton1Down:Connect(function() Tween(bs, 0.1, { Scale = 0.96 }) end)
	btn.MouseButton1Up:Connect(function() Tween(bs, 0.25, { Scale = 1 }, Enum.EasingStyle.Back) end)
	btn.MouseButton1Click:Connect(function() if cfg.Callback then task.spawn(cfg.Callback) end end)
	self:Register(btn, cfg.Name)
	CaptureTransparency(btn)
	local obj = {}
	function obj:Fire() if cfg.Callback then task.spawn(cfg.Callback) end end
	function obj:SetText(t) label.Text = t end
	return obj
end

function Section:AddToggle(cfg)
	cfg = cfg or {}
	local value = cfg.Default or false
	local row = New("TextButton", {
		AutoButtonColor = false, Text = "",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Wraith.Theme.Element,
		ClipsDescendants = true,
		Parent = self.Content,
	})
	Glass(row, 8, 0.5)
	Hover(row, { BackgroundColor3 = Wraith.Theme.Hover }, { BackgroundColor3 = Wraith.Theme.Element })
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Toggle",
		Parent = row,
	})
	local track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -44, 0.5, 0),
		Size = UDim2.new(0, 34, 0, 18),
		BackgroundColor3 = Color3.fromRGB(42, 42, 52),
		Parent = row,
	})
	Corner(track, 99)
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = Wraith.Theme.Text,
		Parent = track,
	})
	Corner(knob, 99)

	local function Set(v, fire)
		value = v and true or false
		if cfg.Flag then Wraith.Flags[cfg.Flag] = value end
		Tween(knob, 0.3, { Position = UDim2.new(0, value and 19 or 3, 0.5, 0) }, Enum.EasingStyle.Back)
		Tween(track, 0.3, { BackgroundColor3 = value and Wraith.Theme.Accent or Color3.fromRGB(42, 42, 52) })
		Tween(label, 0.2, { TextTransparency = value and 0 or 0.35 })
		if fire ~= false and cfg.Callback then task.spawn(cfg.Callback, value) end
	end

	row.MouseButton1Click:Connect(function() Set(not value) end)
	if cfg.Flag then Wraith.Setters[cfg.Flag] = function(v) Set(v, false) end end
	table.insert(self.Window.AccentAppliers, function()
		if value then track.BackgroundColor3 = Wraith.Theme.Accent end
	end)
	self:Register(row, cfg.Name)
	CaptureTransparency(row)
	Set(value, false)
	local obj = {}
	function obj:Set(v) Set(v) end
	function obj:Get() return value end
	return obj
end

function Section:AddSlider(cfg)
	cfg = cfg or {}
	local min = cfg.Min or 0
	local max = cfg.Max or 100
	local step = cfg.Decimals or cfg.Round or 1
	local value = cfg.Default or min
	local suffix = cfg.Suffix or ""

	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Wraith.Theme.Element,
		Parent = self.Content,
	})
	Glass(row, 8, 0.5)
	Hover(row, { BackgroundColor3 = Wraith.Theme.Hover }, { BackgroundColor3 = Wraith.Theme.Element })
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 6),
		Size = UDim2.new(0.6, 0, 0, 14),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Slider",
		Parent = row,
	})
	local val = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.55, 0, 0, 6),
		Size = UDim2.new(0.45, -10, 0, 14),
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Wraith.Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(value) .. suffix,
		Parent = row,
	})
	table.insert(self.Window.AccentAppliers, function() val.TextColor3 = Wraith.Theme.Accent end)
	local track = New("Frame", {
		Position = UDim2.new(0, 10, 1, -14),
		Size = UDim2.new(1, -20, 0, 6),
		BackgroundColor3 = Color3.fromRGB(42, 42, 52),
		Parent = row,
	})
	Corner(track, 99)
	local fill = New("Frame", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundColor3 = Wraith.Theme.Accent,
		Parent = track,
	})
	Corner(fill, 99)
	local fg = New("UIGradient", {
		Color = ColorSequence.new(Wraith.Theme.Accent, Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.5) }),
		Parent = fill,
	})
	table.insert(self.Window.AccentAppliers, function()
		fg.Color = ColorSequence.new(Wraith.Theme.Accent, Color3.fromRGB(255, 255, 255))
	end)

	local function Set(v, fire)
		value = math.clamp(Round(v, step), min, max)
		if cfg.Flag then Wraith.Flags[cfg.Flag] = value end
		Tween(fill, 0.15, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) })
		val.Text = tostring(value) .. suffix
		if fire ~= false and cfg.Callback then task.spawn(cfg.Callback, value) end
	end

	local sliding = false
	local function fromInput(pos)
		local rel = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		Set(min + rel * (max - min))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			fromInput(input.Position)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromInput(input.Position)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
	end)

	if cfg.Flag then Wraith.Setters[cfg.Flag] = function(v) Set(v, false) end end
	self:Register(row, cfg.Name)
	CaptureTransparency(row)
	Set(value, false)
	local obj = {}
	function obj:Set(v) Set(v) end
	function obj:Get() return value end
	return obj
end

function Section:AddDropdown(cfg)
	cfg = cfg or {}
	local multi = cfg.Multi or false
	local options = cfg.Options or {}
	local selected = multi and {} or nil
	local open = false

	if cfg.Default then
		if multi then
			if type(cfg.Default) == "table" then for _, v in ipairs(cfg.Default) do selected[v] = true end end
		else
			selected = cfg.Default
		end
	end

	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Wraith.Theme.Element,
		ClipsDescendants = true,
		Parent = self.Content,
	})
	Glass(row, 8, 0.5)
	local header = New("TextButton", {
		AutoButtonColor = false, Text = "",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.5, -10, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Dropdown",
		Parent = header,
	})
	local val = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, -30, 1, 0),
		Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Wraith.Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	local arrow = New("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 16),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10709790948",
		ImageColor3 = Wraith.Theme.Sub,
		Parent = row,
	})
	local holder = New("Frame", {
		Position = UDim2.new(0, 6, 0, 34),
		Size = UDim2.new(1, -12, 0, 0),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local list = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Wraith.Theme.Stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = holder,
	})
	local layout = New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local function displayText()
		if multi then
			local parts = {}
			for _, o in ipairs(options) do if selected[o] then table.insert(parts, o) end end
			return #parts > 0 and table.concat(parts, ", ") or "..."
		end
		return selected or "..."
	end

	local function fire()
		if cfg.Flag then
			Wraith.Flags[cfg.Flag] = multi and (function()
				local l = {}
				for _, o in ipairs(options) do if selected[o] then table.insert(l, o) end end
				return l
			end)() or selected
		end
		if cfg.Callback then task.spawn(cfg.Callback, Wraith.Flags[cfg.Flag] or selected) end
	end

	local function setOpen(bool)
		open = bool
		local h = open and math.min(#options * 24 + 6, 130) or 0
		Tween(row, 0.3, { Size = UDim2.new(1, 0, 0, 32 + (open and h + 8 or 0)) })
		Tween(holder, 0.3, { Size = UDim2.new(1, -12, 0, h) })
		Tween(arrow, 0.3, { Rotation = open and 180 or 0 })
	end

	local function rebuild()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, opt in ipairs(options) do
			local isSel = multi and selected[opt] or selected == opt
			local ob = New("TextButton", {
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 21),
				BackgroundColor3 = isSel and Wraith.Theme.Accent or Wraith.Theme.Card,
				BackgroundTransparency = isSel and 0.35 or 0.6,
				Font = Enum.Font.Gotham, TextSize = 11,
				TextColor3 = Wraith.Theme.Text,
				Text = "  " .. opt,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = list,
			})
			Corner(ob, 6)
			Hover(ob, { BackgroundTransparency = 0.25 }, { BackgroundTransparency = isSel and 0.35 or 0.6 })
			ob.MouseButton1Click:Connect(function()
				if multi then
					selected[opt] = not selected[opt] or nil
				else
					selected = opt
					setOpen(false)
				end
				val.Text = displayText()
				rebuild()
				fire()
			end)
		end
		val.Text = displayText()
	end

	header.MouseButton1Click:Connect(function() setOpen(not open) end)
	if cfg.Flag then Wraith.Setters[cfg.Flag] = function(v)
		if multi then
			selected = {}
			if type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end end
		else
			selected = v
		end
		rebuild()
	end end
	self:Register(row, cfg.Name)
	rebuild()
	CaptureTransparency(row)

	local obj = {}
	function obj:Add(o) table.insert(options, o) rebuild() end
	function obj:Remove(o)
		for i, v in ipairs(options) do if v == o then table.remove(options, i) break end end
		rebuild()
	end
	function obj:Refresh(l) options = l rebuild() end
	function obj:Get() return Wraith.Flags[cfg.Flag] or selected end
	return obj
end

function Section:AddTextbox(cfg)
	cfg = cfg or {}
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Wraith.Theme.Element,
		Parent = self.Content,
	})
	Glass(row, 8, 0.5)
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.45, -10, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Input",
		Parent = row,
	})
	local box = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 22),
		BackgroundColor3 = Wraith.Theme.Card,
		Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = Wraith.Theme.Text,
		PlaceholderColor3 = Wraith.Theme.Sub,
		PlaceholderText = cfg.Placeholder or "...",
		Text = cfg.Default or "",
		ClearTextOnFocus = false,
		Parent = row,
	})
	Glass(box, 6, 0.4)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = box })

	local function commit(text)
		local v = text
		if cfg.Numeric then v = tonumber(text) or tonumber(v) and v or nil end
		if cfg.Flag then Wraith.Flags[cfg.Flag] = v end
		if cfg.Callback then task.spawn(cfg.Callback, v) end
	end

	if cfg.Finished then
		box.FocusLost:Connect(function(enter) if enter then commit(box.Text) end end)
	else
		box:GetPropertyChangedSignal("Text"):Connect(function() commit(box.Text) end)
	end
	if cfg.Flag then Wraith.Setters[cfg.Flag] = function(v) box.Text = tostring(v) end end
	self:Register(row, cfg.Name)
	CaptureTransparency(row)
	local obj = {}
	function obj:Set(v) box.Text = tostring(v) commit(tostring(v)) end
	function obj:Get() return box.Text end
	return obj
end

function Section:AddKeybind(cfg)
	cfg = cfg or {}
	local key = cfg.Default or nil
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Wraith.Theme.Element,
		Parent = self.Content,
	})
	Glass(row, 8, 0.5)
	Hover(row, { BackgroundColor3 = Wraith.Theme.Hover }, { BackgroundColor3 = Wraith.Theme.Element })
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -100, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Keybind",
		Parent = row,
	})
	local disp = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 70, 0, 20),
		AutoButtonColor = false,
		BackgroundColor3 = Wraith.Theme.Card,
		Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Wraith.Theme.Sub,
		Text = key and tostring(key):gsub("Enum.KeyCode.", "") or "none",
		Parent = row,
	})
	Glass(disp, 6, 0.4)

	local listening = false
	local function Set(k)
		key = k
		if cfg.Flag then Wraith.Flags[cfg.Flag] = k and k.Name or nil end
		disp.Text = k and tostring(k):gsub("Enum.KeyCode.", "") or "none"
	end

	disp.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		disp.Text = "..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				Set(input.KeyCode)
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				Set(nil)
			end
			listening = false
			conn:Disconnect()
			if cfg.Callback then task.spawn(cfg.Callback, key) end
		end)
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not key then return end
		if input.KeyCode == key and cfg.Callback then task.spawn(cfg.Callback, key) end
	end)

	if cfg.Flag then Wraith.Setters[cfg.Flag] = function(v)
		if type(v) == "string" then Set(Enum.KeyCode[v]) end
	end end
	self:Register(row, cfg.Name)
	CaptureTransparency(row)
	local obj = {}
	function obj:Set(k) Set(k) end
	function obj:Get() return key end
	return obj
end

function Section:AddColorpicker(cfg)
	cfg = cfg or {}
	local color = cfg.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = color:ToHSV()
	local open = false

	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Wraith.Theme.Element,
		ClipsDescendants = true,
		Parent = self.Content,
	})
	Glass(row, 8, 0.5)
	local header = New("TextButton", {
		AutoButtonColor = false, Text = "",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local label = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Wraith.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = cfg.Name or "Color",
		Parent = header,
	})
	local swatch = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 16),
		Size = UDim2.new(0, 22, 0, 14),
		BackgroundColor3 = color,
		Parent = row,
	})
	Corner(swatch, 5)
	New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7, Parent = swatch })

	local panel = New("Frame", {
		Position = UDim2.new(0, 8, 0, 36),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local palette = New("TextButton", {
		AutoButtonColor = false, Text = "",
		Size = UDim2.new(1, 0, 0, 90),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		Parent = panel,
	})
	Corner(palette, 6)
	local sat = New("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = palette })
	New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = sat })
	local valF = New("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), Parent = palette })
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = valF })
	local pDrag = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = palette,
	})
	Corner(pDrag, 99)
	New("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.4, Parent = pDrag })

	local hue = New("TextButton", {
		AutoButtonColor = false, Text = "",
		Position = UDim2.new(0, 0, 0, 96),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = panel,
	})
	Corner(hue, 99)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hue,
	})
	local hDrag = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 6, 0, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = hue,
	})
	Corner(hDrag, 99)

	local function update(fire)
		color = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = color
		palette.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		pDrag.Position = UDim2.new(s, 0, 1 - v, 0)
		hDrag.Position = UDim2.new(h, 0, 0.5, 0)
		if cfg.Flag then Wraith.Flags[cfg.Flag] = color end
		if fire ~= false and cfg.Callback then task.spawn(cfg.Callback, color) end
	end

	local slideP, slideH = false, false
	palette.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slideP = true end
	end)
	hue.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slideH = true end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slideP, slideH = false, false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			if slideP then
				s = math.clamp((i.Position.X - palette.AbsolutePosition.X) / palette.AbsoluteSize.X, 0, 1)
				v = math.clamp(1 - (i.Position.Y - palette.AbsolutePosition.Y) / palette.AbsoluteSize.Y, 0, 1)
				update()
			elseif slideH then
				h = math.clamp((i.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
				update()
			end
		end
	end)

	local function setOpen(bool)
		open = bool
		Tween(row, 0.3, { Size = UDim2.new(1, 0, 0, open and 152 or 32) })
		Tween(panel, 0.3, { Size = UDim2.new(1, -16, 0, open and 110 or 0) })
	end
	header.MouseButton1Click:Connect(function() setOpen(not open) end)

	if cfg.Flag then Wraith.Setters[cfg.Flag] = function(c)
		if typeof(c) == "Color3" then color = c h, s, v = c:ToHSV() update(false) end
	end end
	self:Register(row, cfg.Name)
	update(false)
	CaptureTransparency(row)
	local obj = {}
	function obj:Set(c) color = c h, s, v = c:ToHSV() update() end
	function obj:Get() return color end
	return obj
end

getgenv().Wraith = Wraith
return Wraith
