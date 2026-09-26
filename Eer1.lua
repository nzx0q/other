local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

pcall(function()
	local a = PlayerGui:FindFirstChild("MM2AdaptiveMenu")
	if a then a:Destroy() end
	local b = game:GetService("CoreGui"):FindFirstChild("MM2AdaptiveMenu")
	if b then b:Destroy() end
end)

local DESIGN = Vector2.new(1280, 720)
local MENU_SIZE = Vector2.new(560, 340)
local BTN_SIZE = 56
local DRAG_THRESHOLD = 8
local OPEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local SWITCH_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TOGGLE_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Colors = {
	Bg = Color3.fromRGB(14, 14, 18),
	Panel = Color3.fromRGB(22, 22, 28),
	Sidebar = Color3.fromRGB(18, 18, 23),
	Stroke = Color3.fromRGB(48, 48, 58),
	Accent = Color3.fromRGB(220, 55, 70),
	AccentDim = Color3.fromRGB(140, 30, 42),
	Text = Color3.fromRGB(235, 235, 240),
	Muted = Color3.fromRGB(150, 150, 162),
	ToggleOff = Color3.fromRGB(42, 42, 52),
	Row = Color3.fromRGB(28, 28, 36),
}

local State = {
	Open = false,
	Busy = false,
	Category = "Visuals",
	Flags = { Glow = false, MenuScale = 100 },
}

local Categories = {
	{ Id = "Combat", Label = "Combat" },
	{ Id = "Movement", Label = "Movement" },
	{ Id = "Visuals", Label = "Visuals" },
	{ Id = "Misc", Label = "Misc" },
	{ Id = "Settings", Label = "Settings" },
}

local Features = {
	Combat = {},
	Movement = {},
	Visuals = {
		{ Kind = "toggle", Id = "Glow", Text = "Glow" },
	},
	Misc = {},
	Settings = {
		{ Kind = "slider", Id = "MenuScale", Text = "Menu Scale", Min = 70, Max = 130, Default = 100, Step = 5 },
	},
}

local Highlights = {}

local function clearGlow(player)
	local h = Highlights[player]
	if h then
		h:Destroy()
		Highlights[player] = nil
	end
end

local function applyGlow(player)
	if player == LP then
		return
	end
	if not State.Flags.Glow then
		clearGlow(player)
		return
	end
	local char = player.Character
	if not char then
		clearGlow(player)
		return
	end
	local h = Highlights[player]
	if h and h.Parent == char then
		return
	end
	if h then
		h:Destroy()
	end
	h = Instance.new("Highlight")
	h.Name = "MM2Glow"
	h.Adornee = char
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.FillColor = Color3.fromRGB(220, 55, 70)
	h.OutlineColor = Color3.fromRGB(255, 255, 255)
	h.FillTransparency = 0.65
	h.OutlineTransparency = 0
	h.Parent = char
	Highlights[player] = h
end

local function refreshGlow()
	for _, player in ipairs(Players:GetPlayers()) do
		applyGlow(player)
	end
	for player in pairs(Highlights) do
		if not player.Parent then
			clearGlow(player)
		end
	end
end

local function setGlow(on)
	State.Flags.Glow = on
	if on then
		refreshGlow()
	else
		for player in pairs(Highlights) do
			clearGlow(player)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if State.Flags.Glow then
			applyGlow(player)
		end
	end)
	player.CharacterRemoving:Connect(function()
		clearGlow(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	clearGlow(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		if State.Flags.Glow then
			applyGlow(player)
		end
	end)
	player.CharacterRemoving:Connect(function()
		clearGlow(player)
	end)
end

RunService.Heartbeat:Connect(function()
	if State.Flags.Glow then
		refreshGlow()
	end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2AdaptiveMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
local ok = pcall(function()
	ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
	ScreenGui.Parent = PlayerGui
end

local RootScale = Instance.new("UIScale")
RootScale.Parent = ScreenGui

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function applyScale()
	local v = viewport()
	if v.X < 1 or v.Y < 1 then
		RootScale.Scale = 1
		return
	end
	local s = math.min(v.X / DESIGN.X, v.Y / DESIGN.Y)
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then
		s = s * 1.08
	end
	s = s * ((State.Flags.MenuScale or 100) / 100)
	RootScale.Scale = math.clamp(s, 0.55, 1.45)
end

local function clampPos(pos, size)
	local v = viewport()
	local inset = GuiService:GetGuiInset()
	local x = math.clamp(pos.X.Offset, 8, math.max(8, v.X - size.X - 8))
	local y = math.clamp(pos.Y.Offset, inset.Y + 8, math.max(inset.Y + 8, v.Y - size.Y - 8))
	return UDim2.fromOffset(x, y)
end

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.AutoButtonColor = false
OpenBtn.Text = "MM2"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 14
OpenBtn.TextColor3 = Colors.Text
OpenBtn.BackgroundColor3 = Colors.Accent
OpenBtn.Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE)
OpenBtn.Parent = ScreenGui

local function defaultBtnPos()
	local v = viewport()
	return UDim2.fromOffset(v.X - BTN_SIZE - 16, v.Y - BTN_SIZE - 16)
end
OpenBtn.Position = defaultBtnPos()

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 16)
BtnCorner.Parent = OpenBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Color3.fromRGB(255, 120, 130)
BtnStroke.Transparency = 0.45
BtnStroke.Thickness = 1
BtnStroke.Parent = OpenBtn

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.BackgroundColor3 = Colors.Bg
Menu.BorderSizePixel = 0
Menu.Visible = false
Menu.AnchorPoint = Vector2.new(0.5, 0.5)
Menu.Size = UDim2.fromOffset(MENU_SIZE.X, MENU_SIZE.Y)
Menu.Parent = ScreenGui

local MenuScale = Instance.new("UIScale")
MenuScale.Scale = 0.92
MenuScale.Parent = Menu

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 14)
MenuCorner.Parent = Menu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Colors.Stroke
MenuStroke.Thickness = 1
MenuStroke.Parent = Menu

local Top = Instance.new("Frame")
Top.BackgroundColor3 = Colors.Panel
Top.BorderSizePixel = 0
Top.Size = UDim2.new(1, 0, 0, 40)
Top.Parent = Menu

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = Top

local TopFix = Instance.new("Frame")
TopFix.BackgroundColor3 = Colors.Panel
TopFix.BorderSizePixel = 0
TopFix.Position = UDim2.new(0, 0, 1, -14)
TopFix.Size = UDim2.new(1, 0, 0, 14)
TopFix.Parent = Top

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "Murder Mystery 2"
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Colors.Text
Title.Position = UDim2.fromOffset(14, 0)
Title.Size = UDim2.new(1, -54, 1, 0)
Title.Parent = Top

local CloseBtn = Instance.new("TextButton")
CloseBtn.AutoButtonColor = false
CloseBtn.Text = "x"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Colors.Muted
CloseBtn.BackgroundTransparency = 1
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Parent = Top

local Body = Instance.new("Frame")
Body.BackgroundTransparency = 1
Body.Position = UDim2.fromOffset(0, 40)
Body.Size = UDim2.new(1, 0, 1, -40)
Body.Parent = Menu

local Side = Instance.new("Frame")
Side.BackgroundColor3 = Colors.Sidebar
Side.BorderSizePixel = 0
Side.Size = UDim2.new(0, 148, 1, 0)
Side.Parent = Body

local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 6)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Parent = Side

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 10)
SidePad.PaddingRight = UDim.new(0, 10)
SidePad.Parent = Side

local Right = Instance.new("Frame")
Right.BackgroundTransparency = 1
Right.Position = UDim2.fromOffset(148, 0)
Right.Size = UDim2.new(1, -148, 1, 0)
Right.ClipsDescendants = true
Right.Parent = Body

local Content = Instance.new("ScrollingFrame")
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Colors.Accent
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Size = UDim2.fromScale(1, 1)
Content.Parent = Right

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 8)
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = Content

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 12)
ContentPad.PaddingBottom = UDim.new(0, 12)
ContentPad.PaddingLeft = UDim.new(0, 12)
ContentPad.PaddingRight = UDim.new(0, 12)
ContentPad.Parent = Content

local CatButtons = {}

local function styleCat(btn, active)
	TweenService:Create(btn, SWITCH_INFO, {
		BackgroundColor3 = active and Colors.Accent or Colors.Row,
		TextColor3 = active and Colors.Text or Colors.Muted,
	}):Play()
end

local function clearContent()
	for _, c in ipairs(Content:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function onToggle(id, on)
	if id == "Glow" then
		setGlow(on)
	end
end

local function makeToggle(id, text)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Colors.Row
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 40)
	row.Parent = Content
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Font = Enum.Font.Gotham
	lab.Text = text
	lab.TextSize = 14
	lab.TextColor3 = Colors.Text
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.Position = UDim2.fromOffset(12, 0)
	lab.Size = UDim2.new(1, -74, 1, 0)
	lab.Parent = row
	local track = Instance.new("TextButton")
	track.AutoButtonColor = false
	track.Text = ""
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -12, 0.5, 0)
	track.Size = UDim2.fromOffset(44, 24)
	track.BackgroundColor3 = State.Flags[id] and Colors.Accent or Colors.ToggleOff
	track.Parent = row
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = track
	local knob = Instance.new("Frame")
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Size = UDim2.fromOffset(18, 18)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = State.Flags[id] and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
	knob.Parent = track
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = knob
	track.MouseButton1Click:Connect(function()
		State.Flags[id] = not State.Flags[id]
		local on = State.Flags[id]
		TweenService:Create(track, TOGGLE_INFO, {
			BackgroundColor3 = on and Colors.Accent or Colors.ToggleOff,
		}):Play()
		TweenService:Create(knob, TOGGLE_INFO, {
			Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}):Play()
		onToggle(id, on)
	end)
end

local function makeSlider(id, text, minv, maxv, step)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Colors.Row
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 58)
	row.Parent = Content
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Font = Enum.Font.Gotham
	lab.Text = text
	lab.TextSize = 14
	lab.TextColor3 = Colors.Text
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.Position = UDim2.fromOffset(12, 4)
	lab.Size = UDim2.new(1, -70, 0, 20)
	lab.Parent = row
	local valLab = Instance.new("TextLabel")
	valLab.BackgroundTransparency = 1
	valLab.Font = Enum.Font.GothamBold
	valLab.Text = tostring(State.Flags[id])
	valLab.TextSize = 13
	valLab.TextColor3 = Colors.Accent
	valLab.TextXAlignment = Enum.TextXAlignment.Right
	valLab.AnchorPoint = Vector2.new(1, 0)
	valLab.Position = UDim2.new(1, -12, 0, 4)
	valLab.Size = UDim2.fromOffset(50, 20)
	valLab.Parent = row
	local bar = Instance.new("TextButton")
	bar.AutoButtonColor = false
	bar.Text = ""
	bar.BackgroundColor3 = Colors.ToggleOff
	bar.Position = UDim2.fromOffset(12, 32)
	bar.Size = UDim2.new(1, -24, 0, 8)
	bar.Parent = row
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = bar
	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = Colors.Accent
	fill.Size = UDim2.new((State.Flags[id] - minv) / (maxv - minv), 0, 1, 0)
	fill.Parent = bar
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill
	local dragging = false
	local function setFromX(x)
		local w = bar.AbsoluteSize.X
		if w <= 0 then return end
		local a = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
		local snapped = math.clamp(math.floor(((minv + a * (maxv - minv)) / step) + 0.5) * step, minv, maxv)
		State.Flags[id] = snapped
		valLab.Text = tostring(snapped)
		fill.Size = UDim2.new((snapped - minv) / (maxv - minv), 0, 1, 0)
		if id == "MenuScale" then
			applyScale()
		end
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function renderCategory(id)
	clearContent()
	local list = Features[id]
	if not list then return end
	for _, f in ipairs(list) do
		if f.Kind == "toggle" then
			makeToggle(f.Id, f.Text)
		else
			makeSlider(f.Id, f.Text, f.Min, f.Max, f.Step)
		end
	end
	Content.CanvasPosition = Vector2.zero
end

local function selectCategory(id)
	if State.Category == id then return end
	State.Category = id
	for cid, btn in pairs(CatButtons) do
		styleCat(btn, cid == id)
	end
	TweenService:Create(Content, SWITCH_INFO, { GroupTransparency = 1 }):Play()
	task.delay(0.08, function()
		if State.Category \~= id then return end
		renderCategory(id)
		Content.GroupTransparency = 1
		TweenService:Create(Content, SWITCH_INFO, { GroupTransparency = 0 }):Play()
	end)
end

for i, cat in ipairs(Categories) do
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Font = Enum.Font.GothamMedium
	b.Text = cat.Label
	b.TextSize = 13
	b.TextColor3 = Colors.Muted
	b.BackgroundColor3 = Colors.Row
	b.Size = UDim2.new(1, 0, 0, 34)
	b.LayoutOrder = i
	b.Parent = Side
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	CatButtons[cat.Id] = b
	if cat.Id == State.Category then
		styleCat(b, true)
	end
	b.MouseButton1Click:Connect(function()
		selectCategory(cat.Id)
	end)
end

local function placeMenu()
	local v = viewport()
	Menu.Position = UDim2.fromOffset(v.X * 0.5, v.Y * 0.5)
end

local function setOpen(open)
	if State.Busy or State.Open == open then return end
	State.Busy = true
	State.Open = open
	if open then
		placeMenu()
		Menu.Visible = true
		Menu.BackgroundTransparency = 1
		MenuScale.Scale = 0.92
		TweenService:Create(Menu, OPEN_INFO, { BackgroundTransparency = 0 }):Play()
		local tw = TweenService:Create(MenuScale, OPEN_INFO, { Scale = 1 })
		tw:Play()
		tw.Completed:Connect(function()
			State.Busy = false
		end)
		TweenService:Create(OpenBtn, OPEN_INFO, { BackgroundColor3 = Colors.AccentDim }):Play()
	else
		TweenService:Create(Menu, OPEN_INFO, { BackgroundTransparency = 1 }):Play()
		local tw = TweenService:Create(MenuScale, OPEN_INFO, { Scale = 0.92 })
		tw:Play()
		tw.Completed:Connect(function()
			if not State.Open then
				Menu.Visible = false
			end
			State.Busy = false
		end)
		TweenService:Create(OpenBtn, OPEN_INFO, { BackgroundColor3 = Colors.Accent }):Play()
	end
end

local draggingBtn = false
local dragged = false
local dragStart
local startPos

OpenBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingBtn = true
		dragged = false
		dragStart = input.Position
		startPos = OpenBtn.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if not draggingBtn then return end
	if input.UserInputType \~= Enum.UserInputType.MouseMovement and input.UserInputType \~= Enum.UserInputType.Touch then
		return
	end
	local d = input.Position - dragStart
	if d.Magnitude > DRAG_THRESHOLD then
		dragged = true
	end
	if dragged then
		OpenBtn.Position = clampPos(UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y), Vector2.new(BTN_SIZE, BTN_SIZE))
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if draggingBtn and not dragged then
			setOpen(not State.Open)
		end
		draggingBtn = false
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

local function relayout()
	applyScale()
	OpenBtn.Position = clampPos(OpenBtn.Position, Vector2.new(BTN_SIZE, BTN_SIZE))
	if State.Open then
		placeMenu()
	end
end

applyScale()
placeMenu()
renderCategory(State.Category)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
		relayout()
	end
end)
