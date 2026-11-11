--// NebulaUI v1.0.0
--// Uma UI Library original para Roblox / Luau
--// Inspirada no conceito de Rayfield, mas com design, API e implementação próprios.
--// Uso:
--//   local NebulaUI = loadstring(game:HttpGet("https://SEU-LINK/NebulaUI.lua"))()
--//   local Window = NebulaUI:CreateWindow({ Title = "Meu Script", Theme = "Nebula" })
--//
--// Licença: MIT - código 100% original, não copia o código do Rayfield.

local NebulaUI = {}
NebulaUI.__index = NebulaUI
NebulaUI.Version = "1.0.0"
NebulaUI.Name = "NebulaUI"
NebulaUI.Author = "Nebula Team"

--// Serviços
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")

-- Container do GUI (gethui quando disponível, senão PlayerGui/CoreGui)
local GuiContainer = (function()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	if typeof(get_hidden_gui) == "function" then
		local ok, hui = pcall(get_hidden_gui)
		if ok and hui then return hui end
	end
	return PlayerGui or game:GetService("CoreGui")
end)()

--// Temas (diferentes do Rayfield: paleta própria, glass + gradiente)
local Themes = {
	Nebula = {
		Background = Color3.fromRGB(16, 16, 26),
		Sidebar = Color3.fromRGB(22, 22, 36),
		Element = Color3.fromRGB(30, 30, 48),
		ElementHover = Color3.fromRGB(38, 38, 60),
		Stroke = Color3.fromRGB(52, 52, 80),
		Accent = Color3.fromRGB(124, 58, 237),
		Accent2 = Color3.fromRGB(236, 72, 153),
		Text = Color3.fromRGB(240, 240, 250),
		SubText = Color3.fromRGB(160, 160, 185),
		Track = Color3.fromRGB(42, 42, 62),
		Success = Color3.fromRGB(52, 211, 153),
		Error = Color3.fromRGB(248, 113, 113),
	},
	Midnight = {
		Background = Color3.fromRGB(10, 15, 30),
		Sidebar = Color3.fromRGB(14, 20, 40),
		Element = Color3.fromRGB(20, 28, 52),
		ElementHover = Color3.fromRGB(28, 38, 68),
		Stroke = Color3.fromRGB(40, 52, 90),
		Accent = Color3.fromRGB(59, 130, 246),
		Accent2 = Color3.fromRGB(34, 211, 238),
		Text = Color3.fromRGB(235, 242, 255),
		SubText = Color3.fromRGB(140, 155, 185),
		Track = Color3.fromRGB(30, 40, 68),
		Success = Color3.fromRGB(52, 211, 153),
		Error = Color3.fromRGB(248, 113, 113),
	},
	Sunset = {
		Background = Color3.fromRGB(28, 16, 20),
		Sidebar = Color3.fromRGB(36, 22, 28),
		Element = Color3.fromRGB(48, 30, 38),
		ElementHover = Color3.fromRGB(60, 38, 48),
		Stroke = Color3.fromRGB(80, 52, 62),
		Accent = Color3.fromRGB(249, 115, 22),
		Accent2 = Color3.fromRGB(236, 72, 153),
		Text = Color3.fromRGB(255, 240, 235),
		SubText = Color3.fromRGB(190, 160, 155),
		Track = Color3.fromRGB(58, 38, 46),
		Success = Color3.fromRGB(74, 222, 128),
		Error = Color3.fromRGB(248, 113, 113),
	},
	Ocean = {
		Background = Color3.fromRGB(8, 28, 34),
		Sidebar = Color3.fromRGB(12, 38, 46),
		Element = Color3.fromRGB(18, 50, 60),
		ElementHover = Color3.fromRGB(24, 64, 76),
		Stroke = Color3.fromRGB(36, 82, 96),
		Accent = Color3.fromRGB(20, 184, 166),
		Accent2 = Color3.fromRGB(56, 189, 248),
		Text = Color3.fromRGB(230, 250, 250),
		SubText = Color3.fromRGB(140, 180, 185),
		Track = Color3.fromRGB(24, 60, 72),
		Success = Color3.fromRGB(52, 211, 153),
		Error = Color3.fromRGB(248, 113, 113),
	},
	Forest = {
		Background = Color3.fromRGB(14, 24, 16),
		Sidebar = Color3.fromRGB(20, 34, 22),
		Element = Color3.fromRGB(28, 46, 30),
		ElementHover = Color3.fromRGB(36, 58, 38),
		Stroke = Color3.fromRGB(52, 78, 54),
		Accent = Color3.fromRGB(34, 197, 94),
		Accent2 = Color3.fromRGB(163, 230, 53),
		Text = Color3.fromRGB(235, 250, 235),
		SubText = Color3.fromRGB(150, 175, 155),
		Track = Color3.fromRGB(36, 56, 40),
		Success = Color3.fromRGB(52, 211, 153),
		Error = Color3.fromRGB(248, 113, 113),
	},
	Light = {
		Background = Color3.fromRGB(245, 246, 250),
		Sidebar = Color3.fromRGB(255, 255, 255),
		Element = Color3.fromRGB(255, 255, 255),
		ElementHover = Color3.fromRGB(240, 242, 248),
		Stroke = Color3.fromRGB(220, 224, 235),
		Accent = Color3.fromRGB(124, 58, 237),
		Accent2 = Color3.fromRGB(236, 72, 153),
		Text = Color3.fromRGB(30, 30, 45),
		SubText = Color3.fromRGB(120, 122, 140),
		Track = Color3.fromRGB(230, 232, 240),
		Success = Color3.fromRGB(16, 185, 129),
		Error = Color3.fromRGB(239, 68, 68),
	},
}

--// Utilidades
local function Create(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			pcall(function() inst[k] = v end)
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function Tween(inst, info, props)
	local tw = TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

local TweenFast = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenNormal = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSlow = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function Corner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function Stroke(parent, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Color3.fromRGB(255,255,255),
		Thickness = thickness or 1,
		Transparency = transparency or 0.85,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Gradient(parent, color1, color2, rotation)
	return Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color1),
			ColorSequenceKeypoint.new(1, color2),
		}),
		Rotation = rotation or 0,
		Parent = parent,
	})
end

local function Padding(parent, left, right, top, bottom)
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		Parent = parent,
	})
end

local function MakeDraggable(frame, handle)
	local dragging = false
	local dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function FormatKey(key)
	if typeof(key) == "EnumItem" then
		if key == Enum.KeyCode.Unknown then return "None" end
		local name = key.Name
		name = name:gsub("Right", "R"):gsub("Left", "L")
		return name
	end
	return tostring(key or "None")
end

--// Mini slider (usado no ColorPicker RGB - diferente do HSV do Rayfield)
local function CreateMiniSlider(parent, label, min, max, value, onChange, order)
	local container = Create("Frame", {
		Size = UDim2.new(1, -16, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = order or 1,
		Parent = parent,
	})
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), Parent = container })
	local lbl = Create("TextLabel", { Text = label, Size = UDim2.fromOffset(14, 16), BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(200,200,215), Parent = container })
	local track = Create("Frame", { Size = UDim2.new(1, -70, 0, 8), BackgroundColor3 = Color3.fromRGB(42,42,62), BorderSizePixel = 0, Parent = container })
	Corner(track, 4)
	local fill = Create("Frame", { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = Color3.fromRGB(124,58,237), BorderSizePixel = 0, Parent = track })
	Corner(fill, 4)
	local handle = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, ZIndex = 5, Parent = track })
	Corner(handle, 7)
	local valLabel = Create("TextLabel", { Text = tostring(value), Size = UDim2.fromOffset(36, 16), BackgroundTransparency = 1, TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(180,180,200), Parent = container })

	local function setFromRatio(ratio)
		ratio = math.clamp(ratio, 0, 1)
		local v = math.round(min + (max - min) * ratio)
		fill.Size = UDim2.fromScale(ratio, 1)
		handle.Position = UDim2.fromScale(ratio, 0.5)
		valLabel.Text = tostring(v)
		onChange(v)
	end
	setFromRatio((value - min) / (max - min))

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local pos = track.AbsolutePosition
			local size = track.AbsoluteSize
			local mouse = UserInputService:GetMouseLocation()
			setFromRatio((mouse.X - pos.X) / size.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local pos = track.AbsolutePosition
			local size = track.AbsoluteSize
			if size.X > 0 then setFromRatio((input.Position.X - pos.X) / size.X) end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	return container
end

--//==================================================
--// CONSTRUTORES DE ELEMENTOS
--//==================================================

local function RegisterFlag(window, element, props)
	local flag = props.Flag or props.flag
	if flag and flag ~= "" then
		element.Flag = flag
		window.Flags[flag] = element
	end
end

local function NewSection(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 26), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local dot = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, Parent = main })
	Corner(dot, 3)
	local title = Create("TextLabel", { Text = (props.Name or "Section"):upper(), Position = UDim2.new(0, 16, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 1, TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	return { Main = main, Name = props.Name }
end

local function NewDivider(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 20), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local line = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Stroke, BorderSizePixel = 0, BackgroundTransparency = 0.4, Parent = main })
	if props.Text and props.Text ~= "" then
		local lbl = Create("TextLabel", { Text = props.Text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(120, 16), BackgroundColor3 = theme.Background, BorderSizePixel = 0, TextSize = 11, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, Parent = main })
	end
	return { Main = main }
end

local function NewButton(parent, window, props, order)
	local theme = window.Theme
	local main = Create("TextButton", {
		Size = UDim2.new(1, -16, 0, 38), BackgroundColor3 = theme.Element, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = order, Parent = parent,
	})
	Corner(main, 10); Stroke(main, theme.Stroke)
	Gradient(main, theme.Accent, theme.Accent2, 0).Transparency = NumberSequence.new(0.85)
	local title = Create("TextLabel", { Text = props.Name or "Button", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, Parent = main })
	main.MouseEnter:Connect(function() Tween(main, TweenFast, { BackgroundColor3 = theme.ElementHover }) end)
	main.MouseLeave:Connect(function() Tween(main, TweenFast, { BackgroundColor3 = theme.Element }) end)
	main.MouseButton1Click:Connect(function()
		if props.Callback then task.spawn(props.Callback) end
	end)
	return { Main = main, Name = props.Name }
end

local function NewToggle(parent, window, props, order)
	local theme = window.Theme
	local hasDesc = props.Description and props.Description ~= ""
	local height = hasDesc and 52 or 42
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, height), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local left = Create("Frame", { Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -72, 0, height - 8), BackgroundTransparency = 1, Parent = main })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 2), Parent = left })
	local title = Create("TextLabel", { Text = props.Name or "Toggle", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = left })
	if hasDesc then
		Create("TextLabel", { Text = props.Description, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = left })
	end
	-- Switch
	local switch = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(44, 22), BackgroundColor3 = theme.Track, BorderSizePixel = 0, Parent = main })
	Corner(switch, 11)
	local knob = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Parent = switch })
	Corner(knob, 8)
	local btn = Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = main })

	local element = { Main = main, Name = props.Name, Value = props.Value or props.Default or false, Callback = props.Callback }
	RegisterFlag(window, element, props)

	local function render(animate)
		local on = element.Value
		local targetPos = on and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
		local targetColor = on and theme.Accent or theme.Track
		if animate then
			Tween(knob, TweenNormal, { Position = targetPos })
			Tween(switch, TweenNormal, { BackgroundColor3 = targetColor })
		else
			knob.Position = targetPos
			switch.BackgroundColor3 = targetColor
		end
	end
	function element:Set(value, skipCallback)
		element.Value = value and true or false
		render(true)
		if not skipCallback and element.Callback then task.spawn(element.Callback, element.Value) end
	end
	function element:Get() return element.Value end
	btn.MouseButton1Click:Connect(function() element:Set(not element.Value) end)
	render(false)
	return element
end

local function NewSlider(parent, window, props, order)
	local theme = window.Theme
	local range = props.Range or {0, 100}
	local min, max = range[1], range[2]
	local increment = props.Increment or 1
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 62), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Slider", Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -80, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local valueLabel = Create("TextLabel", { Text = "", Position = UDim2.new(1, -12, 0, 8), AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(60, 16), BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = main })
	local track = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = theme.Track, BorderSizePixel = 0, Parent = main })
	Corner(track, 4)
	local fill = Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, Parent = track })
	Corner(fill, 4); Gradient(fill, theme.Accent, theme.Accent2, 0)
	local handle = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, ZIndex = 5, Parent = track })
	Corner(handle, 8)

	local element = { Main = main, Name = props.Name, Value = props.Value or props.Default or min, Min = min, Max = max, Callback = props.Callback }
	RegisterFlag(window, element, props)

	local function snap(v)
		v = math.clamp(v, min, max)
		if increment and increment > 0 then v = math.round(v / increment) * increment end
		return v
	end
	local function render()
		local ratio = (element.Value - min) / (max - min)
		fill.Size = UDim2.fromScale(ratio, 1)
		handle.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = tostring(element.Value) .. (props.Suffix or "")
	end
	function element:Set(value, skipCallback)
		element.Value = snap(tonumber(value) or element.Value)
		render()
		if not skipCallback and element.Callback then task.spawn(element.Callback, element.Value) end
	end
	function element:Get() return element.Value end

	local dragging = false
	local function updateFromMouse()
		local pos = track.AbsolutePosition
		local size = track.AbsoluteSize
		if size.X <= 0 then return end
		local mouse = UserInputService:GetMouseLocation()
		local ratio = math.clamp((mouse.X - pos.X) / size.X, 0, 1)
		element:Set(min + (max - min) * ratio)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; updateFromMouse()
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateFromMouse() end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	render()
	return element
end

local function NewDropdown(parent, window, props, order)
	local theme = window.Theme
	local options = props.Options or {}
	local multi = props.MultiSelect or props.Multi or false
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 42), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Dropdown", Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.45, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local selected = Create("TextLabel", { Text = props.Placeholder or "Select...", Position = UDim2.new(1, -28, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0.5, -10, 0, 16), BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Right, Parent = main })
	local arrow = Create("TextLabel", { Text = "v", Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = theme.SubText, Parent = main })
	local btn = Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = main })

	local popup = Create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 1, 4), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 20, Parent = main,
	})
	Corner(popup, 8); Stroke(popup, theme.Stroke)
	Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = popup })
	Padding(popup, 4, 4, 4, 4)

	local element = { Main = main, Name = props.Name, Options = options, Multi = multi, Value = {}, Callback = props.Callback, _open = false }
	if props.Value then
		if type(props.Value) == "table" then element.Value = table.clone(props.Value) else element.Value = { props.Value } end
	end
	RegisterFlag(window, element, props)

	local function refreshLabel()
		if #element.Value == 0 then selected.Text = props.Placeholder or "Select..."
		elseif #element.Value == 1 then selected.Text = element.Value[1]
		else selected.Text = #element.Value .. " selected" end
	end
	local function buildOptions()
		for _, child in ipairs(popup:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
		for i, opt in ipairs(element.Options) do
			local isSel = table.find(element.Value, opt) ~= nil
			local b = Create("TextButton", {
				Size = UDim2.new(1, -4, 0, 28), BackgroundColor3 = isSel and theme.Accent or theme.Element, BorderSizePixel = 0, Text = (isSel and "[x] " or "[ ] ") .. opt,
				TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = isSel and Color3.fromRGB(255,255,255) or theme.Text, AutoButtonColor = false, LayoutOrder = i, ZIndex = 21, Parent = popup,
			})
			Corner(b, 6)
			b.MouseButton1Click:Connect(function()
				if multi then
					local idx = table.find(element.Value, opt)
					if idx then table.remove(element.Value, idx) else table.insert(element.Value, opt) end
				else
					element.Value = { opt }
					element._open = false; popup.Visible = false; main.Size = UDim2.new(1, -16, 0, 42)
				end
				refreshLabel(); buildOptions()
				if element.Callback then task.spawn(element.Callback, multi and table.clone(element.Value) or element.Value[1]) end
			end)
		end
	end
	function element:Set(value, skipCallback)
		if type(value) == "table" then element.Value = table.clone(value) else element.Value = { value } end
		-- filtra apenas opções válidas
		local filtered = {}
		for _, v in ipairs(element.Value) do if table.find(element.Options, v) then table.insert(filtered, v) end end
		element.Value = filtered
		refreshLabel(); buildOptions()
		if not skipCallback and element.Callback then task.spawn(element.Callback, multi and table.clone(element.Value) or element.Value[1]) end
	end
	function element:Get() return multi and table.clone(element.Value) or element.Value[1] end
	function element:Refresh(newOptions)
		element.Options = newOptions or {}
		element:Set(element.Value, true)
	end

	btn.MouseButton1Click:Connect(function()
		element._open = not element._open
		popup.Visible = element._open
		local h = math.min(#element.Options * 32 + 8, 180)
		main.Size = UDim2.new(1, -16, 0, element._open and (42 + h) or 42)
		if element._open then buildOptions() end
	end)
	refreshLabel(); buildOptions()
	return element
end

local function NewInput(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 42), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Input", Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.4, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local box = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.55, -8, 0, 26),
		BackgroundColor3 = theme.Track, BorderSizePixel = 0, Text = props.Value or props.Default or "", PlaceholderText = props.Placeholder or "...",
		TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, ClearTextOnFocus = false, Parent = main,
	})
	Corner(box, 7)
	local element = { Main = main, Name = props.Name, Value = box.Text, Callback = props.Callback }
	RegisterFlag(window, element, props)
	function element:Set(value, skipCallback)
		element.Value = tostring(value or "")
		box.Text = element.Value
		if not skipCallback and element.Callback then task.spawn(element.Callback, element.Value) end
	end
	function element:Get() return element.Value end
	box.FocusLost:Connect(function(enter)
		if enter then element:Set(box.Text) end
	end)
	return element
end

local function NewKeybind(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 42), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Keybind", Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.5, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local btn = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(80, 26),
		BackgroundColor3 = theme.Track, BorderSizePixel = 0, Text = "...", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, AutoButtonColor = false, Parent = main,
	})
	Corner(btn, 7)
	local element = { Main = main, Name = props.Name, Value = props.Value or props.Default or Enum.KeyCode.Unknown, Callback = props.Callback, OnChanged = props.OnChanged, _recording = false, Hold = props.Hold or false }
	RegisterFlag(window, element, props)
	local function render() btn.Text = element._recording and "..." or FormatKey(element.Value) end
	function element:Set(value, skipCallback)
		element.Value = value
		render()
		if not skipCallback and element.OnChanged then task.spawn(element.OnChanged, element.Value) end
	end
	function element:Get() return element.Value end
	btn.MouseButton1Click:Connect(function()
		element._recording = true; render()
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then element._recording = false; render(); conn:Disconnect(); return end
				if input.KeyCode == Enum.KeyCode.Backspace then element:Set(Enum.KeyCode.Unknown) else element:Set(input.KeyCode) end
				element._recording = false; render(); conn:Disconnect()
			end
		end)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or element._recording then return end
		if element.Value ~= Enum.KeyCode.Unknown and input.KeyCode == element.Value then
			if element.Callback then task.spawn(element.Callback, element.Value) end
		end
	end)
	render()
	return element
end

local function NewColorPicker(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 42), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Color", Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.5, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local preview = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(56, 26),
		BackgroundColor3 = props.Value or props.Default or Color3.fromRGB(255,255,255), BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = main,
	})
	Corner(preview, 7); Stroke(preview, theme.Stroke)

	local popup = Create("Frame", { Position = UDim2.new(0, 0, 1, 4), Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = main })
	Corner(popup, 8); Stroke(popup, theme.Stroke)
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = popup })
	Padding(popup, 8, 8, 8, 8)

	local element = { Main = main, Name = props.Name, Value = props.Value or props.Default or Color3.fromRGB(255,255,255), Callback = props.Callback, _open = false }
	RegisterFlag(window, element, props)

	local r, g, b = math.round(element.Value.R * 255), math.round(element.Value.G * 255), math.round(element.Value.B * 255)
	local function apply()
		element.Value = Color3.fromRGB(r, g, b)
		preview.BackgroundColor3 = element.Value
		if element.Callback then task.spawn(element.Callback, element.Value) end
	end
	CreateMiniSlider(popup, "R", 0, 255, r, function(v) r = v; apply() end, 1)
	CreateMiniSlider(popup, "G", 0, 255, g, function(v) g = v; apply() end, 2)
	CreateMiniSlider(popup, "B", 0, 255, b, function(v) b = v; apply() end, 3)

	function element:Set(value, skipCallback)
		if typeof(value) == "Color3" then element.Value = value
		elseif type(value) == "string" then
			local ok, c = pcall(Color3.fromHex, value:gsub("#", ""))
			if ok then element.Value = c end
		end
		r, g, b = math.round(element.Value.R * 255), math.round(element.Value.G * 255), math.round(element.Value.B * 255)
		preview.BackgroundColor3 = element.Value
		if not skipCallback and element.Callback then task.spawn(element.Callback, element.Value) end
	end
	function element:Get() return element.Value end
	preview.MouseButton1Click:Connect(function()
		element._open = not element._open
		popup.Visible = element._open
		main.Size = UDim2.new(1, -16, 0, element._open and 152 or 42)
	end)
	return element
end

local function NewParagraph(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	Padding(main, 12, 12, 10, 10)
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = main })
	if props.Name and props.Name ~= "" then
		Create("TextLabel", { Text = props.Name, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	end
	local body = Create("TextLabel", { Text = props.Text or props.Description or "", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = main })
	local el = { Main = main, Name = props.Name, Text = body.Text }
	function el:Set(text) body.Text = tostring(text or ""); el.Text = body.Text end
	return el
end

local function NewProgress(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 54), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Progress", Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local pct = Create("TextLabel", { Text = "0%", Position = UDim2.new(1, -12, 0, 8), AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(50, 16), BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = main })
	local track = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = theme.Track, BorderSizePixel = 0, Parent = main })
	Corner(track, 4)
	local fill = Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, Parent = track })
	Corner(fill, 4); Gradient(fill, theme.Accent, theme.Accent2, 0)
	local el = { Main = main, Name = props.Name, Value = 0 }
	function el:Set(value)
		el.Value = math.clamp(tonumber(value) or 0, 0, 100)
		pct.Text = math.round(el.Value) .. "%"
		Tween(fill, TweenNormal, { Size = UDim2.fromScale(el.Value / 100, 1) })
	end
	function el:Get() return el.Value end
	if props.Value then el:Set(props.Value) end
	return el
end

local function NewStat(parent, window, props, order)
	local theme = window.Theme
	local main = Create("Frame", { Size = UDim2.new(1, -16, 0, 42), BackgroundColor3 = theme.Element, BorderSizePixel = 0, LayoutOrder = order, Parent = parent })
	Corner(main, 10); Stroke(main, theme.Stroke)
	local title = Create("TextLabel", { Text = props.Name or "Stat", Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.5, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = main })
	local value = Create("TextLabel", { Text = tostring(props.Value or props.Default or "0"), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0.45, 0, 0, 16), BackgroundTransparency = 1, TextSize = 15, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Right, Parent = main })
	local el = { Main = main, Name = props.Name, Value = props.Value or props.Default or 0 }
	function el:Set(v) el.Value = v; value.Text = tostring(v) end
	function el:Get() return el.Value end
	return el
end

--//==================================================
--// TAB / GROUP
--//==================================================

local Tab = {}
Tab.__index = Tab

local function AttachElementMethods(obj)
	obj.CreateSection = function(self, props) self._order = self._order + 1; return NewSection(self.Page, self.Window, props or {}, self._order) end
	obj.CreateDivider = function(self, props) self._order = self._order + 1; return NewDivider(self.Page, self.Window, props or {}, self._order) end
	obj.CreateButton = function(self, props) self._order = self._order + 1; return NewButton(self.Page, self.Window, props or {}, self._order) end
	obj.CreateToggle = function(self, props) self._order = self._order + 1; local el = NewToggle(self.Page, self.Window, props or {}, self._order); table.insert(self.Elements, el); return el end
	obj.CreateSwitch = obj.CreateToggle
	obj.CreateSlider = function(self, props) self._order = self._order + 1; local el = NewSlider(self.Page, self.Window, props or {}, self._order); table.insert(self.Elements, el); return el end
	obj.CreateDropdown = function(self, props) self._order = self._order + 1; local el = NewDropdown(self.Page, self.Window, props or {}, self._order); table.insert(self.Elements, el); return el end
	obj.CreateInput = function(self, props) self._order = self._order + 1; local el = NewInput(self.Page, self.Window, props or {}, self._order); table.insert(self.Elements, el); return el end
	obj.CreateKeybind = function(self, props) self._order = self._order + 1; local el = NewKeybind(self.Page, self.Window, props or {}, self._order); table.insert(self.Elements, el); return el end
	obj.CreateColorPicker = function(self, props) self._order = self._order + 1; local el = NewColorPicker(self.Page, self.Window, props or {}, self._order); table.insert(self.Elements, el); return el end
	obj.CreateParagraph = function(self, props) self._order = self._order + 1; return NewParagraph(self.Page, self.Window, props or {}, self._order) end
	obj.CreateText = obj.CreateParagraph
	obj.CreateProgress = function(self, props) self._order = self._order + 1; return NewProgress(self.Page, self.Window, props or {}, self._order) end
	obj.CreateStat = function(self, props) self._order = self._order + 1; return NewStat(self.Page, self.Window, props or {}, self._order) end
	obj.CreateLabel = obj.CreateStat
end

function Tab:Select()
	local window = self.Window
	window.SelectedTab = self
	for _, tab in ipairs(window.Tabs) do
		tab.Page.Visible = (tab == self)
		-- atualiza botão da sidebar
		local isSel = (tab == self)
		Tween(tab.Button, TweenFast, { BackgroundColor3 = isSel and window.Theme.Accent or window.Theme.Sidebar })
		Tween(tab.ButtonLabel, TweenFast, { TextColor3 = isSel and Color3.fromRGB(255,255,255) or window.Theme.SubText })
	end
end

function Tab:CreateGroup(props)
	props = props or {}
	local theme = self.Window.Theme
	self._order = self._order + 1
	local direction = props.Direction or "Horizontal"
	local isHorizontal = direction == "Horizontal"
	local groupFrame = Create("Frame", {
		Size = UDim2.new(1, -16, 0, isHorizontal and 42 or 0),
		AutomaticSize = isHorizontal and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = self._order, Parent = self.Page,
	})
	Create("UIListLayout", {
		FillDirection = isHorizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = groupFrame,
	})
	local group = { Page = groupFrame, Window = self.Window, Elements = {}, _order = 0, Main = groupFrame }
	-- Ajusta filhos do grupo para não usar margem -16 (usa flex)
	-- Para simplificar, os elementos do grupo usam Size 1,-0; o construtor usa -16, então corrigimos após criar
	local originalMethods = {}
	AttachElementMethods(group)
	-- Override para corrigir tamanho dentro do grupo
	local function fixSize(el)
		if el.Main then
			local s = el.Main.Size
			if isHorizontal then
				-- em grupo horizontal, cada item divide o espaço com flex
				el.Main.Size = UDim2.new(1, 0, s.Y.Scale, s.Y.Offset)
				Create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = el.Main })
			else
				el.Main.Size = UDim2.new(1, 0, s.Y.Scale, s.Y.Offset)
			end
		end
		return el
	end
	local origToggle = group.CreateToggle
	group.CreateToggle = function(self, p) return fixSize(origToggle(self, p)) end
	local origButton = group.CreateButton
	group.CreateButton = function(self, p) return fixSize(origButton(self, p)) end
	local origSlider = group.CreateSlider
	group.CreateSlider = function(self, p) return fixSize(origSlider(self, p)) end
	return group
end

--//==================================================
--// WINDOW
--//==================================================

local Window = {}
Window.__index = Window

function Window:CreateTab(props)
	props = props or {}
	local theme = self.Theme
	local tab = setmetatable({ Window = self, Name = props.Name or "Tab", Icon = props.Icon, Elements = {}, _order = 0 }, Tab)
	AttachElementMethods(tab)

	-- Botão na sidebar
	local btn = Create("TextButton", {
		Size = UDim2.new(1, -16, 0, 36), BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = self.TabList,
	})
	Corner(btn, 9)
	local lbl = Create("TextLabel", { Text = tab.Name, Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -20, 0, 16), BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })
	tab.Button = btn; tab.ButtonLabel = lbl
	btn.MouseButton1Click:Connect(function() tab:Select() end)

	-- Página
	local page = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = self.Content,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
	Padding(page, 8, 8, 8, 8)
	tab.Page = page

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then tab:Select() end
	return tab
end

function Window:Notify(props)
	props = props or {}
	local theme = self.Theme
	local duration = props.Duration or math.clamp(#(props.Content or "") * 0.05 + 3, 3, 8)
	local notif = Create("Frame", {
		Size = UDim2.new(0, 300, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0,
		Position = UDim2.new(1, 20, 0, 0), AnchorPoint = Vector2.new(1, 0), Parent = self.ScreenGui,
	})
	Corner(notif, 12); Stroke(notif, theme.Stroke)
	Padding(notif, 12, 12, 10, 10)
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = notif })
	Create("TextLabel", { Text = props.Title or "Notification", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = notif })
	if props.Content and props.Content ~= "" then
		Create("TextLabel", { Text = props.Content, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = notif })
	end
	Tween(notif, TweenNormal, { Position = UDim2.new(1, -16, 0, 16) })
	task.delay(duration, function()
		Tween(notif, TweenNormal, { Position = UDim2.new(1, 20, 0, 0) })
		task.wait(0.3)
		notif:Destroy()
	end)
	return notif
end

function Window:Popup(props)
	props = props or {}
	local theme = self.Theme
	local overlay = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 50, Parent = self.ScreenGui })
	local card = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, ZIndex = 51, Parent = overlay })
	Corner(card, 14); Stroke(card, theme.Stroke)
	Padding(card, 16, 16, 14, 14)
	Create("UIListLayout", { Padding = UDim.new(0, 10), Parent = card })
	Create("TextLabel", { Text = props.Title or "Popup", Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	if props.Content then
		Create("TextLabel", { Text = props.Content, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = card })
	end
	local btnRow = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = card })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), Parent = btnRow })
	local buttons = props.Buttons or { { Text = "OK", Callback = function() end } }
	for _, b in ipairs(buttons) do
		local btn = Create("TextButton", { Size = UDim2.fromOffset(80, 32), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, Text = b.Text or "OK", TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255,255,255), AutoButtonColor = false, Parent = btnRow })
		Corner(btn, 8)
		btn.MouseButton1Click:Connect(function()
			if b.Callback then task.spawn(b.Callback) end
			overlay:Destroy()
		end)
	end
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and props.Dismissable ~= false then overlay:Destroy() end
	end)
	return overlay
end

function Window:SetTheme(themeName)
	local newTheme = Themes[themeName] or Themes.Nebula
	self.Theme = newTheme
	self.ThemeName = themeName
	-- Reaplica cores principais (simplificado: atualiza Main/Sidebar)
	if self.Main then self.Main.BackgroundColor3 = newTheme.Background end
	if self.Sidebar then self.Sidebar.BackgroundColor3 = newTheme.Sidebar end
	self:Notify({ Title = "Tema alterado", Content = "Tema: " .. themeName, Duration = 2 })
end

function Window:ToggleVisible(force)
	self.Visible = force ~= nil and force or not self.Visible
	self.Main.Visible = self.Visible
	if self.Visible then
		self.Main.Size = UDim2.fromOffset(0, 0)
		Tween(self.Main, TweenSlow, { Size = self.Size })
	end
end

function Window:Destroy()
	if self.ScreenGui then self.ScreenGui:Destroy() end
end

-- Config (Flags)
function Window:SaveConfig(name)
	name = name or self.ConfigName or "default"
	if typeof(writefile) ~= "function" then warn("[NebulaUI] writefile não disponível neste executor."); return false end
	local data = {}
	for flag, el in pairs(self.Flags) do
		if el.Value ~= nil then
			if typeof(el.Value) == "Color3" then data[flag] = el.Value:ToHex()
			elseif typeof(el.Value) == "EnumItem" then data[flag] = el.Value.Name
			else data[flag] = el.Value end
		end
	end
	local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then return false end
	pcall(function() if typeof(makefolder) == "function" and not isfolder("NebulaUI/Configs") then makefolder("NebulaUI/Configs") end end)
	local ok2 = pcall(writefile, "NebulaUI/Configs/" .. name .. ".json", json)
	return ok2
end

function Window:LoadConfig(name)
	name = name or self.ConfigName or "default"
	if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then warn("[NebulaUI] readfile não disponível."); return false end
	local path = "NebulaUI/Configs/" .. name .. ".json"
	if not isfile(path) then warn("[NebulaUI] Config não encontrada: " .. name); return false end
	local ok, content = pcall(readfile, path)
	if not ok then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
	if not ok2 or type(data) ~= "table" then return false end
	for flag, value in pairs(data) do
		local el = self.Flags[flag]
		if el and el.Set then
			if typeof(el.Value) == "Color3" and type(value) == "string" then
				local ok3, c = pcall(Color3.fromHex, value)
				if ok3 then el:Set(c, true) end
			elseif typeof(el.Value) == "EnumItem" and type(value) == "string" then
				local ok3, k = pcall(function() return Enum.KeyCode[value] end)
				if ok3 then el:Set(k, true) end
			else
				el:Set(value, true)
			end
		end
	end
	return true
end

function Window:GetFlag(flag) local el = self.Flags[flag]; return el and el.Value end
function Window:SetFlag(flag, value) local el = self.Flags[flag]; if el and el.Set then el:Set(value) return true end return false end

--//==================================================
--// CREATE WINDOW
--//==================================================

function NebulaUI:CreateWindow(props)
	props = props or {}
	local themeName = props.Theme or "Nebula"
	local theme = Themes[themeName] or Themes.Nebula
	local size = props.Size or UDim2.fromOffset(640, 440)

	local window = setmetatable({
		Theme = theme, ThemeName = themeName, Size = size,
		Title = props.Title or "NebulaUI",
		Subtitle = props.Subtitle or "v" .. NebulaUI.Version,
		Tabs = {}, Flags = {}, Visible = true,
		ToggleKey = props.ToggleKey or Enum.KeyCode.RightShift,
		ConfigName = props.ConfigName or "default",
	}, Window)

	-- ScreenGui
	local gui = Create("ScreenGui", { Name = "NebulaUI_" .. tostring(math.random(1000, 9999)), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = GuiContainer })
	window.ScreenGui = gui

	-- Main
	local main = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size,
		BackgroundColor3 = theme.Background, BorderSizePixel = 0, Parent = gui,
	})
	Corner(main, 16); Stroke(main, theme.Stroke, 1, 0.7)
	window.Main = main

	-- Sidebar
	local sidebar = Create("Frame", { Size = UDim2.new(0, 180, 1, 0), BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, Parent = main })
	Corner(sidebar, 16)
	-- cobre canto direito da sidebar para ficar arredondado só à esquerda
	local cover = Create("Frame", { Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0, 16, 1, 0), BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, Parent = sidebar })
	window.Sidebar = sidebar

	local logo = Create("TextLabel", { Text = window.Title, Position = UDim2.new(0, 14, 0, 14), Size = UDim2.new(1, -20, 0, 20), BackgroundTransparency = 1, TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = sidebar })
	local sub = Create("TextLabel", { Text = window.Subtitle, Position = UDim2.new(0, 14, 0, 34), Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = sidebar })

	local tabList = Create("ScrollingFrame", { Position = UDim2.new(0, 8, 0, 58), Size = UDim2.new(1, -16, 1, -110), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = sidebar })
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = tabList })
	window.TabList = tabList

	local userLabel = Create("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -12), Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.Gotham, TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = sidebar })
	if LocalPlayer then userLabel.Text = "@" .. LocalPlayer.Name end

	-- Topbar / Content header
	local topbar = Create("Frame", { Position = UDim2.new(0, 180, 0, 0), Size = UDim2.new(1, -180, 0, 48), BackgroundTransparency = 1, Parent = main })
	local searchBox = Create("TextBox", {
		Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.5, -20, 0, 30),
		BackgroundColor3 = theme.Element, BorderSizePixel = 0, PlaceholderText = "Search...", Text = "", TextSize = 13, Font = Enum.Font.Gotham, TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, ClearTextOnFocus = false, Parent = topbar,
	})
	Corner(searchBox, 8); Stroke(searchBox, theme.Stroke)
	Padding(searchBox, 10, 10, 0, 0)

	local closeBtn = Create("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = theme.Element, BorderSizePixel = 0, Text = "X", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, AutoButtonColor = false, Parent = topbar })
	Corner(closeBtn, 8); Stroke(closeBtn, theme.Stroke)
	local minBtn = Create("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -48, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = theme.Element, BorderSizePixel = 0, Text = "-", TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = theme.Text, AutoButtonColor = false, Parent = topbar })
	Corner(minBtn, 8); Stroke(minBtn, theme.Stroke)

	-- Content
	local content = Create("Frame", { Position = UDim2.new(0, 180, 0, 48), Size = UDim2.new(1, -180, 1, -48), BackgroundTransparency = 1, Parent = main })
	window.Content = content

	-- Drag
	MakeDraggable(main, topbar)
	MakeDraggable(main, sidebar)

	-- Botões
	closeBtn.MouseButton1Click:Connect(function() window:ToggleVisible(false) end)
	minBtn.MouseButton1Click:Connect(function() window:ToggleVisible(false) end)

	-- Toggle key
	if window.ToggleKey then
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == window.ToggleKey then window:ToggleVisible() end
		end)
	end

	-- Search (filtra elementos da aba atual)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBox.Text or "")
		for _, tab in ipairs(window.Tabs) do
			for _, el in ipairs(tab.Elements) do
				if el.Main then
					local name = string.lower(el.Name or "")
					el.Main.Visible = (query == "" or string.find(name, query, 1, true) ~= nil)
				end
			end
		end
	end)

	-- Animação de entrada
	main.Size = UDim2.fromOffset(0, 0)
	Tween(main, TweenSlow, { Size = size })

	if props.OnLoad then task.spawn(props.OnLoad, window) end
	return window
end

-- Atalho estilo Rayfield: NebulaUI.CreateWindow(...)
NebulaUI.CreateWindow = NebulaUI.CreateWindow

return NebulaUI
