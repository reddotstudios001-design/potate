--[[
	Library UI  |  Roblox UI Library
	Sidebar + sub-tabs + groupboxes, toggles, sliders, dropdowns (multi / search),
	inputs, buttons, color pickers, key pickers, watermark and notifications.

	Usage:
		local Library = loadstring(game:HttpGet("<raw url>/Library.lua"))()
		local Window  = Library:CreateWindow({ Title = "Library" })
]]

--// Services
local cloneref = cloneref or function(o) return o end
local function Service(name) return cloneref(game:GetService(name)) end

local Players = Service("Players")
local UserInputService = Service("UserInputService")
local TweenService = Service("TweenService")
local RunService = Service("RunService")
local CoreGui = Service("CoreGui")
local Stats = Service("Stats")
local LocalPlayer = Players.LocalPlayer

--// Library table
local Library = {
	Version = "1.0.0",
	Toggles = {},
	Options = {},
	Windows = {},
	Connections = {},
	Registry = {},
	Refreshers = {},
	UnloadCallbacks = {},
	Unloaded = false,
	Visible = true,
	Popup = nil,
	Gui = nil,
	Theme = {
		Background = Color3.fromRGB(16, 16, 18),
		Sidebar = Color3.fromRGB(14, 14, 16),
		Main = Color3.fromRGB(20, 20, 22),
		Groupbox = Color3.fromRGB(25, 25, 28),
		Element = Color3.fromRGB(33, 33, 37),
		ElementHover = Color3.fromRGB(42, 42, 47),
		Outline = Color3.fromRGB(40, 40, 45),
		Line = Color3.fromRGB(92, 100, 114),
		Accent = Color3.fromRGB(152, 207, 255),
		AccentText = Color3.fromRGB(14, 20, 28),
		Text = Color3.fromRGB(235, 235, 240),
		SubText = Color3.fromRGB(135, 135, 145),
		Dim = Color3.fromRGB(78, 78, 86),
		Success = Color3.fromRGB(72, 204, 98),
		Warning = Color3.fromRGB(240, 184, 64),
		Error = Color3.fromRGB(236, 88, 88),
	},
}

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

local ROW_PAD = 6
local layoutCounter = 0
local function nextOrder()
	layoutCounter = layoutCounter + 1
	return layoutCounter
end

--// Utilities
local function Clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function Round(v, decimals)
	local m = 10 ^ (decimals or 0)
	return math.floor(v * m + 0.5) / m
end

local function Tween(obj, props, time, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function Library:Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self.Connections, c)
	return c
end

function Library:Register(inst, props)
	table.insert(self.Registry, { Instance = inst, Props = props })
	for prop, key in pairs(props) do
		inst[prop] = self.Theme[key]
	end
	return inst
end

function Library:UpdateTheme()
	for i = #self.Registry, 1, -1 do
		local r = self.Registry[i]
		if r.Instance.Parent == nil then
			table.remove(self.Registry, i)
		else
			for prop, key in pairs(r.Props) do
				r.Instance[prop] = self.Theme[key]
			end
		end
	end
	for _, fn in ipairs(self.Refreshers) do
		pcall(fn)
	end
end

function Library:SetTheme(tbl)
	for k, v in pairs(tbl) do
		self.Theme[k] = v
	end
	self:UpdateTheme()
end

--// Instance builder (strings on *Color3 / Color props are theme keys)
local function New(class, props, children)
	local o = Instance.new(class)
	local themed = {}

	if o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
		o.BackgroundTransparency = 1
		o.FontFace = FONT
		o.TextSize = 12
		themed.TextColor3 = "Text"
	end
	if o:IsA("TextButton") then
		o.AutoButtonColor = false
		o.Text = ""
	end
	if o:IsA("TextBox") then
		o.ClearTextOnFocus = false
	end
	if o:IsA("ImageLabel") or o:IsA("ImageButton") then
		o.BackgroundTransparency = 1
	end
	if o:IsA("ScrollingFrame") then
		o.BackgroundTransparency = 1
		o.ScrollBarThickness = 2
		o.ScrollBarImageColor3 = Library.Theme.Outline
		o.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		o.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		o.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	end

	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		elseif type(v) == "string" and (k:sub(-6) == "Color3" or k == "Color") and Library.Theme[v] then
			themed[k] = v
		else
			themed[k] = nil
			o[k] = v
		end
	end
	if next(themed) then
		Library:Register(o, themed)
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function Corner(r)
	return New("UICorner", { CornerRadius = UDim.new(0, r or 4) })
end

local function Stroke(key, thickness)
	return New("UIStroke", {
		Color = key or "Outline",
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Pad(l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0),
		PaddingBottom = UDim.new(0, b or t or l or 0),
	})
end

local function List(padding, dir, parent)
	return New("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function IsOver(gui)
	if not gui or not gui.Parent then return false end
	local m = UserInputService:GetMouseLocation()
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end

local function IsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- Calls fn(mouseLocation) while the user presses/drags on `obj`
local function Drag(obj, fn)
	Library:Connect(obj.InputBegan, function(input)
		if not IsPress(input) then return end
		fn(UserInputService:GetMouseLocation())
		local move, finish
		move = UserInputService.InputChanged:Connect(function(i)
			if IsMove(i) then fn(UserInputService:GetMouseLocation()) end
		end)
		finish = UserInputService.InputEnded:Connect(function(i)
			if IsPress(i) then
				move:Disconnect()
				finish:Disconnect()
			end
		end)
	end)
end

local function MakeDraggable(handle, target)
	local dragging, dragStart, startPos
	Library:Connect(handle.InputBegan, function(input)
		if IsPress(input) then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			Library:ClosePopup()
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
				end
			end)
		end
	end)
	Library:Connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then
			local d = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- 3x3 dot "grid" icon used on dropdowns
local function GridIcon(parent)
	local holder = New("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(11, 11),
		Parent = parent,
	}, {
		New("UIGridLayout", {
			CellSize = UDim2.fromOffset(3, 3),
			CellPadding = UDim2.fromOffset(1, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for _ = 1, 9 do
		New("Frame", { BackgroundColor3 = "SubText", Parent = holder }, { Corner(1) })
	end
	return holder
end

-- Icon: accepts rbxassetid / number (image) or a short glyph string
local function MakeIcon(icon, size, parent, props)
	props = props or {}
	if icon == nil then return nil end
	if type(icon) == "number" or (type(icon) == "string" and icon:sub(1, 4) == "rbx") then
		local id = type(icon) == "number" and ("rbxassetid://" .. icon) or icon
		props.TextColor3 = nil
		props.Image = id
		props.Size = UDim2.fromOffset(size, size)
		props.Parent = parent
		return New("ImageLabel", props)
	end
	props.ImageColor3 = nil
	props.Text = tostring(icon)
	props.FontFace = FONT_BOLD
	props.TextSize = size
	props.Size = UDim2.fromOffset(size, size)
	props.Parent = parent
	return New("TextLabel", props)
end

--// Base element class (OnChanged / callbacks)
local Element = {}
Element.__index = Element

function Element:OnChanged(fn)
	table.insert(self._changed, fn)
	return self
end

function Element:_fire(...)
	if self.Callback then task.spawn(self.Callback, ...) end
	for _, fn in ipairs(self._changed) do task.spawn(fn, ...) end
end

local function Args(idx, info)
	if type(idx) == "table" then return nil, idx end
	return idx, info or {}
end

--// Gui / popups
function Library:GetGui()
	if self.Gui then return self.Gui end

	local gui = Instance.new("ScreenGui")
	gui.Name = "LibraryUI_" .. tostring(math.random(1000, 9999))
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local ok = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
		gui.Parent = (gethui and gethui()) or CoreGui
	end)
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	self.Gui = gui

	-- close popups when clicking outside
	self:Connect(UserInputService.InputBegan, function(input)
		if IsPress(input) and self.Popup then
			if not IsOver(self.Popup.Frame) and not IsOver(self.Popup.Owner) then
				self:ClosePopup()
			end
		end
	end)

	return gui
end

function Library:ClosePopup()
	local p = self.Popup
	self.Popup = nil
	if p and p.Close then p.Close() end
end

function Library:SetPopup(owner, frame, close)
	self:ClosePopup()
	self.Popup = { Owner = owner, Frame = frame, Close = close }
end

-- Places `frame` under `anchor` (flips above when there's no room)
function Library:PlacePopup(frame, anchor, alignRight)
	local screen = self.Gui.AbsoluteSize
	local size = frame.AbsoluteSize
	local x = anchor.AbsolutePosition.X
	if alignRight then x = anchor.AbsolutePosition.X + anchor.AbsoluteSize.X - size.X end
	x = Clamp(x, 6, math.max(6, screen.X - size.X - 6))
	local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
	if y + size.Y > screen.Y - 6 then
		y = anchor.AbsolutePosition.Y - size.Y - 4
	end
	frame.Position = UDim2.fromOffset(x, y)
end

--// Visibility / unload
function Library:SetVisible(state)
	self.Visible = state
	for _, w in ipairs(self.Windows) do
		w.Main.Visible = state
	end
	if not state then self:ClosePopup() end
end

function Library:Toggle()
	self:SetVisible(not self.Visible)
end

function Library:OnUnload(fn)
	table.insert(self.UnloadCallbacks, fn)
end

function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	for _, fn in ipairs(self.UnloadCallbacks) do pcall(fn) end
	for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
	if self.Gui then self.Gui:Destroy() end
	table.clear(self.Toggles)
	table.clear(self.Options)
end

--// Notifications
function Library:Notify(info, time)
	if type(info) == "string" then info = { Title = info, Time = time } end
	local gui = self:GetGui()

	if not self.NotifyHolder then
		self.NotifyHolder = New("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 58),
			Size = UDim2.fromOffset(240, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = gui,
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})
	end

	local duration = info.Time or 4
	local barColor = Library.Theme.Success
	if info.Type == "Error" then barColor = Library.Theme.Error
	elseif info.Type == "Warning" then barColor = Library.Theme.Warning
	elseif info.Type == "Info" then barColor = Library.Theme.Accent end
	if info.Color then barColor = info.Color end

	local wrapper = New("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = nextOrder(),
		Parent = self.NotifyHolder,
	})
	local card = New("Frame", {
		BackgroundColor3 = "Background",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = wrapper,
	}, { Corner(6), Stroke("Outline"), Pad(10, 8, 10, 8), List(3) })

	New("TextLabel", {
		Text = info.Title or "Notification",
		FontFace = FONT_BOLD,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = card,
	})
	if info.Description then
		New("TextLabel", {
			Text = info.Description,
			TextSize = 11,
			TextColor3 = "Dim",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = card,
		})
	end

	local bar
	if info.Bar ~= false and duration > 0 then
		local track = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 2),
			LayoutOrder = 3,
			Parent = card,
		})
		bar = New("Frame", { BackgroundColor3 = barColor, Size = UDim2.new(1, 0, 1, 0), Parent = track }, { Corner(1) })
	end

	local notif = {}
	local closed = false
	function notif:Destroy()
		if closed then return end
		closed = true
		Tween(wrapper, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
		task.delay(0.25, function() wrapper:Destroy() end)
	end

	task.spawn(function()
		local tries = 0
		while card.AbsoluteSize.Y <= 0 and tries < 20 do
			task.wait()
			tries = tries + 1
		end
		if closed then return end
		Tween(wrapper, { Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y) }, 0.2)
		if bar then Tween(bar, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear) end
		if duration > 0 then
			task.wait(duration)
			notif:Destroy()
		end
	end)

	return notif
end

--// Watermark
function Library:CreateWatermark(cfg)
	cfg = cfg or {}
	local gui = self:GetGui()
	local wm = {}

	wm.Frame = New("Frame", {
		BackgroundColor3 = "Background",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = gui,
	}, {
		Corner(7),
		Stroke("Outline"),
		Pad(14, 0, 14, 0),
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 18),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function segment(order)
		return New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = order,
			Parent = wm.Frame,
		}, { List(6, Enum.FillDirection.Horizontal), })
	end
	local function lbl(parent, text, color)
		local l = New("TextLabel", {
			Text = text,
			TextColor3 = color or "Text",
			FontFace = FONT_BOLD,
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = parent,
		})
		return l
	end

	-- title
	local s1 = segment(1)
	local logo = MakeIcon(cfg.Icon or "✦", 12, s1, { TextColor3 = "Text", LayoutOrder = 0 })
	if logo then logo.Size = UDim2.fromOffset(12, 16) end
	wm.TitleLabel = lbl(s1, cfg.Title or "Library")

	-- ping
	if cfg.ShowPing ~= false then
		local s2 = segment(2)
		local bars = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 16), Parent = s2 })
		for i = 1, 3 do
			New("Frame", {
				BackgroundColor3 = "Success",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, (i - 1) * 4, 1, -3),
				Size = UDim2.fromOffset(3, 3 + i * 2),
				Parent = bars,
			}, { Corner(1) })
		end
		wm.PingLabel = lbl(s2, "0 MS", "Success")
	end

	-- user
	if cfg.ShowUser ~= false then
		local s3 = segment(3)
		local icon = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 16), Parent = s3 })
		New("Frame", {
			BackgroundColor3 = "Text",
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.fromOffset(6, 6),
			Parent = icon,
		}, { Corner(3) })
		New("Frame", {
			BackgroundColor3 = "Text",
			Position = UDim2.fromOffset(0, 9),
			Size = UDim2.fromOffset(10, 5),
			Parent = icon,
		}, { Corner(3) })
		wm.UserLabel = lbl(s3, cfg.User or LocalPlayer.Name)
	end

	-- fps
	if cfg.ShowFPS then
		wm.FpsLabel = lbl(segment(4), "0 FPS")
	end

	local frames, last = 0, os.clock()
	Library:Connect(RunService.RenderStepped, function()
		frames = frames + 1
		if os.clock() - last >= 0.5 then
			if wm.PingLabel then
				local ok, ping = pcall(function()
					return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				wm.PingLabel.Text = (ok and tostring(math.floor(ping)) or "0") .. " MS"
			end
			if wm.FpsLabel then
				wm.FpsLabel.Text = math.floor(frames / (os.clock() - last)) .. " FPS"
			end
			frames, last = 0, os.clock()
		end
	end)

	function wm:SetVisible(v) self.Frame.Visible = v end
	function wm:SetTitle(t) self.TitleLabel.Text = t end

	self.Watermark = wm
	return wm
end

--// Containers (groupboxes / rows) -------------------------------------------------
local Container = {}
Container.__index = Container

function Container:_root(height, auto)
	local size = UDim2.new(1, 0, 0, height)
	if self.Cols then
		size = UDim2.new(1 / self.Cols, -(ROW_PAD * (self.Cols - 1) / self.Cols), 0, height)
	end
	local f = New("Frame", {
		BackgroundTransparency = 1,
		Size = size,
		LayoutOrder = nextOrder(),
		Parent = self.Content,
	})
	if auto then f.AutomaticSize = Enum.AutomaticSize.Y end
	return f
end

-- Places elements side by side: Groupbox:AddRow(2):AddSlider(...)
function Container:AddRow(cols)
	local row = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
		Parent = self.Content,
	})
	List(ROW_PAD, Enum.FillDirection.Horizontal, row)
	return setmetatable({ Content = row, Cols = cols or 2 }, Container)
end

local function AddonHolder(root)
	return New("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0, 9),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 3,
		Parent = root,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function WithAddons(el, root)
	local holder = AddonHolder(root)
	-- the created picker also exposes AddColorPicker / AddKeyPicker so calls can be chained
	local function chain(obj)
		obj.AddColorPicker = el.AddColorPicker
		obj.AddKeyPicker = el.AddKeyPicker
		return obj
	end
	function el:AddColorPicker(idx, info)
		idx, info = Args(idx, info)
		return chain(Library:_colorpicker(idx, info, holder))
	end
	function el:AddKeyPicker(idx, info)
		idx, info = Args(idx, info)
		return chain(Library:_keypicker(idx, info, holder, el))
	end
	return el
end

local function Labeled(root, text)
	return New("TextLabel", {
		Text = text,
		TextColor3 = "SubText",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		Parent = root,
	})
end

--// Label
function Container:AddLabel(text, wrap)
	local info = type(text) == "table" and text or { Text = text, DoesWrap = wrap }
	local l = setmetatable({ Type = "Label", _changed = {} }, Element)
	local root = self:_root(16, true)
	local label = New("TextLabel", {
		Text = info.Text or "Label",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = info.DoesWrap == true,
		Size = UDim2.new(1, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = root,
	})
	function l:SetText(t) label.Text = t end
	function l:SetVisible(v) root.Visible = v end
	return WithAddons(l, root)
end

--// Divider
function Container:AddDivider()
	local root = self:_root(7)
	New("Frame", { BackgroundColor3 = "Outline", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), Parent = root })
end

--// Toggle
function Container:AddToggle(idx, info)
	idx, info = Args(idx, info)
	local t = setmetatable({
		Type = "Toggle",
		Value = info.Default == true,
		Text = info.Text or "Toggle",
		Disabled = info.Disabled == true,
		Risky = info.Risky == true,
		Callback = info.Callback,
		_changed = {},
	}, Element)

	local root = self:_root(18)
	local box = New("Frame", {
		BackgroundColor3 = "Element",
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.fromOffset(14, 14),
		Parent = root,
	}, { Corner(3), Stroke("Outline") })
	local check = New("TextLabel", {
		Text = "✓",
		FontFace = FONT_BOLD,
		TextSize = 11,
		TextColor3 = "AccentText",
		TextTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = box,
	})
	local label = New("TextLabel", {
		Text = t.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -22, 1, 0),
		Parent = root,
	})
	local button = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = root })

	local function update()
		local on = t.Value
		Tween(box, { BackgroundColor3 = on and Library.Theme.Accent or Library.Theme.Element }, 0.12)
		Tween(check, { TextTransparency = on and 0 or 1 }, 0.12)
		local col = on and Library.Theme.Text or Library.Theme.SubText
		if t.Risky then col = Library.Theme.Error end
		if t.Disabled then col = Library.Theme.Dim end
		label.TextColor3 = col
	end
	table.insert(Library.Refreshers, update)
	update()

	function t:SetValue(v)
		v = v and true or false
		if self.Value == v then return end
		self.Value = v
		update()
		self:_fire(v)
	end
	function t:SetText(s) self.Text = s label.Text = s end
	function t:SetDisabled(v) self.Disabled = v update() end
	function t:SetVisible(v) root.Visible = v end

	Library:Connect(button.MouseButton1Click, function()
		if not t.Disabled then t:SetValue(not t.Value) end
	end)

	if idx then Library.Toggles[idx] = t end
	return WithAddons(t, root)
end

--// Slider
function Container:AddSlider(idx, info)
	idx, info = Args(idx, info)
	local s = setmetatable({
		Type = "Slider",
		Min = info.Min or 0,
		Max = info.Max or 100,
		Rounding = info.Rounding or 0,
		Text = info.Text or "Slider",
		Prefix = info.Prefix or "",
		Suffix = info.Suffix or "",
		Disabled = info.Disabled == true,
		Callback = info.Callback,
		FormatDisplayValue = info.FormatDisplayValue,
		_changed = {},
	}, Element)
	s.Value = Clamp(info.Default or s.Min, s.Min, s.Max)

	local compact = info.Compact == true
	local root = self:_root(compact and 10 or 32)
	local label = New("TextLabel", {
		Text = s.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		Visible = not compact,
		Parent = root,
	})
	local valueLabel = New("TextLabel", {
		TextColor3 = "SubText",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(1, 0, 0, 14),
		Visible = not compact,
		Parent = root,
	})
	local bar = New("Frame", {
		BackgroundColor3 = "Element",
		Position = UDim2.fromOffset(0, compact and 1 or 20),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = root,
	}, { Corner(4) })
	local fill = New("Frame", { BackgroundColor3 = "Accent", Size = UDim2.fromScale(0, 1), Parent = bar }, { Corner(4) })
	local hit = New("TextButton", {
		Position = UDim2.fromOffset(0, compact and -4 or 14),
		Size = UDim2.new(1, 0, 0, compact and 18 or 18),
		Parent = root,
	})

	local function render()
		local a = (s.Max == s.Min) and 0 or (s.Value - s.Min) / (s.Max - s.Min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		local txt
		if s.FormatDisplayValue then txt = s.FormatDisplayValue(s, s.Value) end
		valueLabel.Text = txt or (s.Prefix .. tostring(s.Value) .. s.Suffix)
		label.TextColor3 = s.Disabled and Library.Theme.Dim or Library.Theme.Text
	end
	table.insert(Library.Refreshers, render)
	render()

	function s:SetValue(v)
		v = Round(Clamp(tonumber(v) or self.Min, self.Min, self.Max), self.Rounding)
		if v == self.Value then return end
		self.Value = v
		render()
		self:_fire(v)
	end
	function s:SetMin(v) self.Min = v self.Value = Clamp(self.Value, self.Min, self.Max) render() end
	function s:SetMax(v) self.Max = v self.Value = Clamp(self.Value, self.Min, self.Max) render() end
	function s:SetText(t) label.Text = t end
	function s:SetDisabled(v) self.Disabled = v render() end
	function s:SetVisible(v) root.Visible = v end

	Drag(hit, function(m)
		if s.Disabled then return end
		local a = Clamp((m.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
		s:SetValue(s.Min + (s.Max - s.Min) * a)
	end)

	if idx then Library.Options[idx] = s end
	return s
end

--// Button (supports sub buttons on the same row)
function Container:AddButton(info, func)
	if type(info) == "string" then info = { Text = info, Func = func } end
	local root = self:_root(24)
	List(ROW_PAD, Enum.FillDirection.Horizontal, root)
	local group = { Buttons = {} }

	local function relayout()
		local n = #group.Buttons
		for _, b in ipairs(group.Buttons) do
			b._btn.Size = UDim2.new(1 / n, -(ROW_PAD * (n - 1) / n), 1, 0)
		end
	end

	local function make(cfg)
		local b = { Type = "Button", Text = cfg.Text or "Button", Func = cfg.Func or cfg.Callback, Disabled = cfg.Disabled == true, Risky = cfg.Risky == true, DoubleClick = cfg.DoubleClick == true }
		local btn = New("TextButton", {
			BackgroundTransparency = 0,
			BackgroundColor3 = "Element",
			Text = b.Text,
			LayoutOrder = nextOrder(),
			Size = UDim2.fromScale(1, 1),
			Parent = root,
		}, { Corner(4), Stroke("Outline") })
		b._btn = btn

		local function color()
			btn.TextColor3 = b.Disabled and Library.Theme.Dim or (b.Risky and Library.Theme.Error or Library.Theme.Text)
		end
		table.insert(Library.Refreshers, color)
		color()

		local armed = false
		Library:Connect(btn.MouseEnter, function()
			if not b.Disabled then Tween(btn, { BackgroundColor3 = Library.Theme.ElementHover }, 0.1) end
		end)
		Library:Connect(btn.MouseLeave, function()
			Tween(btn, { BackgroundColor3 = Library.Theme.Element }, 0.1)
		end)
		Library:Connect(btn.MouseButton1Click, function()
			if b.Disabled then return end
			if b.DoubleClick and not armed then
				armed = true
				btn.Text = "Click again"
				task.delay(2, function()
					if armed then armed = false btn.Text = b.Text end
				end)
				return
			end
			armed = false
			btn.Text = b.Text
			if b.Func then task.spawn(b.Func) end
		end)

		function b:SetText(t) self.Text = t btn.Text = t end
		function b:SetDisabled(v) self.Disabled = v color() end
		function b:SetVisible(v) btn.Visible = v end
		function b:AddButton(c, f)
			if type(c) == "string" then c = { Text = c, Func = f } end
			return make(c)
		end

		table.insert(group.Buttons, b)
		relayout()
		return b
	end

	return make(info)
end

--// Dropdown
function Container:AddDropdown(idx, info)
	idx, info = Args(idx, info)
	local d = setmetatable({
		Type = "Dropdown",
		Values = info.Values or {},
		Multi = info.Multi == true,
		AllowNull = info.AllowNull == true,
		Searchable = info.Searchable == true,
		Disabled = info.Disabled == true,
		MaxVisible = info.MaxVisible or 8,
		Callback = info.Callback,
		_changed = {},
	}, Element)

	local function playerNames()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if not (info.ExcludeLocalPlayer and p == LocalPlayer) then t[#t + 1] = p.Name end
		end
		return t
	end
	if info.SpecialType == "Player" then d.Values = playerNames() end

	local hasLabel = info.Text ~= nil
	local root = self:_root(hasLabel and 42 or 24)
	local title = hasLabel and Labeled(root, info.Text) or nil
	if title then title.TextColor3 = Library.Theme.Text end

	local box = New("TextButton", {
		BackgroundTransparency = 0,
		BackgroundColor3 = "Element",
		Position = UDim2.fromOffset(0, hasLabel and 18 or 0),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = root,
	}, { Corner(4), Stroke("Outline") })
	local valueLabel = New("TextLabel", {
		TextColor3 = "SubText",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Parent = box,
	})
	local search
	if d.Searchable then
		search = New("TextBox", {
			Text = "",
			PlaceholderText = "",
			PlaceholderColor3 = Library.Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Parent = box,
		})
		valueLabel.Visible = false
	end
	GridIcon(box)

	d.Value = d.Multi and {} or nil

	local function isSelected(v)
		if d.Multi then return d.Value[v] == true end
		return d.Value == v
	end

	local menu, list, build

	local function display()
		local text
		if d.Multi then
			local t = {}
			for _, v in ipairs(d.Values) do
				if d.Value[v] then t[#t + 1] = tostring(v) end
			end
			text = #t > 0 and table.concat(t, ", ") or "--"
		else
			text = d.Value ~= nil and tostring(d.Value) or "--"
		end
		valueLabel.Text = text
		if search then search.PlaceholderText = text end
	end

	local function close()
		if menu then menu:Destroy() menu = nil end
	end

	function d:SetValue(v)
		if self.Multi then
			local nv = {}
			if type(v) == "table" then
				for k, val in pairs(v) do
					if type(k) == "number" then
						if self.Values[val] ~= nil and type(val) == "number" and not table.find(self.Values, val) then val = self.Values[val] end
						nv[val] = true
					elseif val then
						nv[k] = true
					end
				end
			end
			self.Value = nv
		else
			if type(v) == "number" and not table.find(self.Values, v) and self.Values[v] ~= nil then v = self.Values[v] end
			if v ~= nil and not table.find(self.Values, v) then v = nil end
			self.Value = v
		end
		display()
		self:_fire(self.Value)
	end

	function d:SetValues(values)
		self.Values = values
		if not self.Multi and self.Value ~= nil and not table.find(values, self.Value) then self.Value = nil end
		if self.Multi then
			for k in pairs(self.Value) do
				if not table.find(values, k) then self.Value[k] = nil end
			end
		end
		display()
		if menu then build() end
	end
	function d:SetDisabled(v) self.Disabled = v end
	function d:SetVisible(v) root.Visible = v end
	function d:SetText(t) if title then title.Text = t end end

	function build()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
		end
		local filter = search and search.Text:lower() or ""
		local n = 0
		for _, v in ipairs(d.Values) do
			local s = tostring(v)
			if filter == "" or s:lower():find(filter, 1, true) then
				n = n + 1
				local sel = isSelected(v)
				local b = New("TextButton", {
					BackgroundColor3 = "Element",
					BackgroundTransparency = 1,
					Text = s,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = sel and Library.Theme.Accent or Library.Theme.SubText,
					Size = UDim2.new(1, 0, 0, 22),
					LayoutOrder = n,
					Parent = list,
				}, { Corner(3), Pad(8, 0, 8, 0) })
				b.MouseEnter:Connect(function() if not isSelected(v) then b.TextColor3 = Library.Theme.Text end b.BackgroundTransparency = 0.5 end)
				b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 b.TextColor3 = isSelected(v) and Library.Theme.Accent or Library.Theme.SubText end)
				b.MouseButton1Click:Connect(function()
					if d.Multi then
						local nv = {}
						for k, val in pairs(d.Value) do nv[k] = val end
						nv[v] = (not nv[v]) or nil
						d:SetValue(nv)
						build()
					else
						if d.Value == v and d.AllowNull then d:SetValue(nil) else d:SetValue(v) end
						if search then search.Text = "" end
						Library:ClosePopup()
					end
				end)
			end
		end
		if n == 0 then
			New("TextLabel", { Text = "No results", TextColor3 = "Dim", Size = UDim2.new(1, 0, 0, 22), Parent = list })
			n = 1
		end
		menu.Size = UDim2.fromOffset(box.AbsoluteSize.X, math.min(n, d.MaxVisible) * 22 + 8)
		Library:PlacePopup(menu, box)
	end

	local function open()
		if d.Disabled or menu then return end
		menu = New("Frame", {
			BackgroundColor3 = "Groupbox",
			Size = UDim2.fromOffset(box.AbsoluteSize.X, 30),
			ZIndex = 50,
			Parent = Library.Gui,
		}, { Corner(4), Stroke("Outline") })
		list = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ZIndex = 51,
			Parent = menu,
		}, { Pad(4), List(0) })
		Library:SetPopup(box, menu, close)
		build()
	end

	Library:Connect(box.MouseButton1Click, function()
		if menu then Library:ClosePopup() else open() end
	end)
	if search then
		Library:Connect(search.Focused, open)
		Library:Connect(search:GetPropertyChangedSignal("Text"), function()
			if menu then build() else open() end
		end)
	end

	if info.SpecialType == "Player" then
		Library:Connect(Players.PlayerAdded, function() d:SetValues(playerNames()) end)
		Library:Connect(Players.PlayerRemoving, function() task.defer(function() d:SetValues(playerNames()) end) end)
	end

	d.Value = d.Multi and {} or nil
	if info.Default ~= nil then d:SetValue(info.Default) else display() end

	if idx then Library.Options[idx] = d end
	return d
end

--// Input
function Container:AddInput(idx, info)
	idx, info = Args(idx, info)
	local i = setmetatable({
		Type = "Input",
		Value = info.Default or "",
		Numeric = info.Numeric == true,
		Finished = info.Finished == true,
		Callback = info.Callback,
		_changed = {},
	}, Element)

	local hasLabel = info.Text ~= nil
	local root = self:_root(hasLabel and 42 or 24)
	local title = hasLabel and Labeled(root, info.Text) or nil
	if title then title.TextColor3 = Library.Theme.Text end

	local stroke = Stroke("Outline")
	local box = New("Frame", {
		BackgroundColor3 = "Element",
		Position = UDim2.fromOffset(0, hasLabel and 18 or 0),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = root,
	}, { Corner(4), stroke })
	local tb = New("TextBox", {
		Text = i.Value,
		PlaceholderText = info.Placeholder or "Type here...",
		PlaceholderColor3 = Library.Theme.Dim,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Parent = box,
	})

	Library:Connect(tb.Focused, function() Tween(stroke, { Color = Library.Theme.Accent }, 0.12) end)
	Library:Connect(tb.FocusLost, function(enter)
		Tween(stroke, { Color = Library.Theme.Outline }, 0.12)
		if i.Finished and enter then i:_fire(i.Value) end
	end)
	Library:Connect(tb:GetPropertyChangedSignal("Text"), function()
		local txt = tb.Text
		if i.Numeric then
			local f = (txt:gsub("[^%d%.%-]", ""))
			if f ~= txt then tb.Text = f return end
		end
		if info.MaxLength and #txt > info.MaxLength then
			tb.Text = txt:sub(1, info.MaxLength)
			return
		end
		i.Value = txt
		if not i.Finished then i:_fire(txt) end
	end)

	function i:SetValue(v) tb.Text = tostring(v) end
	function i:SetText(t) if title then title.Text = t end end
	function i:SetVisible(v) root.Visible = v end

	if idx then Library.Options[idx] = i end
	return i
end

--// Color picker (used through Toggle/Label:AddColorPicker) ------------------------
function Library:_colorpicker(idx, info, holder)
	local default = info.Default or Color3.fromRGB(255, 255, 255)
	local cp = setmetatable({
		Type = "ColorPicker",
		Transparency = info.Transparency,
		Rainbow = false,
		Fading = false,
		Callback = info.Callback,
		_changed = {},
	}, Element)
	cp.Hue, cp.Sat, cp.Vib = default:ToHSV()
	cp.Value = default

	local swatch = New("TextButton", {
		BackgroundTransparency = 0,
		BackgroundColor3 = default,
		Size = UDim2.fromOffset(28, 14),
		LayoutOrder = nextOrder(),
		Parent = holder,
	}, { Corner(3), Stroke("Outline") })

	local ui, conn

	local function rgbOf(c)
		return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
	end

	local function visuals()
		if not ui then return end
		ui.sv.BackgroundColor3 = Color3.fromHSV(cp.Hue, 1, 1)
		ui.svCursor.Position = UDim2.new(cp.Sat, 0, 1 - cp.Vib, 0)
		ui.hueCursor.Position = UDim2.new(cp.Hue, 0, 0.5, 0)
		if ui.alphaFill then
			ui.alphaFill.BackgroundColor3 = cp.Value
			ui.alphaCursor.Position = UDim2.new(1 - cp.Transparency, 0, 0.5, 0)
		end
		local r, g, b = rgbOf(cp.Value)
		if not ui.rgb:IsFocused() then ui.rgb.Text = string.format("%d, %d, %d", r, g, b) end
		if not ui.hex:IsFocused() then ui.hex.Text = "#" .. cp.Value:ToHex():upper() end
		ui.rainbow.TextColor3 = cp.Rainbow and Library.Theme.Accent or Library.Theme.SubText
		ui.fading.TextColor3 = cp.Fading and Library.Theme.Accent or Library.Theme.SubText
	end

	local function refresh(fire)
		local v = cp.Vib
		if cp.Fading then v = cp.Vib * (0.3 + 0.7 * (0.5 + 0.5 * math.sin(os.clock() * 3))) end
		cp.Value = Color3.fromHSV(cp.Hue, cp.Sat, v)
		swatch.BackgroundColor3 = cp.Value
		visuals()
		if fire then cp:_fire(cp.Value) end
	end

	local function loop()
		local need = cp.Rainbow or cp.Fading
		if need and not conn then
			conn = Library:Connect(RunService.RenderStepped, function()
				if cp.Rainbow then cp.Hue = (os.clock() * 0.15) % 1 end
				refresh(true)
			end)
		elseif not need and conn then
			conn:Disconnect()
			conn = nil
		end
	end

	function cp:SetValue(v, transparency)
		if typeof(v) == "Color3" then
			self.Hue, self.Sat, self.Vib = v:ToHSV()
		elseif type(v) == "table" then
			self.Hue, self.Sat, self.Vib = v[1], v[2], v[3]
		end
		if transparency ~= nil then self.Transparency = transparency end
		refresh(true)
	end
	function cp:SetValueRGB(c, t) self:SetValue(c, t) end

	local function close()
		if ui then ui.frame:Destroy() ui = nil end
	end

	local function open()
		local hasAlpha = cp.Transparency ~= nil
		local W, H = 220, hasAlpha and 226 or 208
		local frame = New("Frame", {
			BackgroundColor3 = "Groupbox",
			Size = UDim2.fromOffset(W, H),
			ZIndex = 50,
			Parent = Library.Gui,
		}, { Corner(5), Stroke("Outline") })
		ui = { frame = frame }

		local y = 10
		ui.sv = New("Frame", {
			BackgroundColor3 = Color3.fromHSV(cp.Hue, 1, 1),
			Position = UDim2.fromOffset(10, y),
			Size = UDim2.new(1, -20, 0, 110),
			ZIndex = 51,
			Parent = frame,
		}, { Corner(3) })
		local white = New("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = 52, Parent = ui.sv }, {
			Corner(3),
			New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }),
		})
		New("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1), ZIndex = 53, Parent = ui.sv }, {
			Corner(3),
			New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
		})
		ui.svCursor = New("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(9, 9),
			ZIndex = 55,
			Parent = ui.sv,
		}, { Corner(5), New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }) })
		y = y + 110 + 10

		ui.hue = New("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromOffset(10, y),
			Size = UDim2.new(1, -20, 0, 8),
			ZIndex = 51,
			Parent = frame,
		}, {
			Corner(4),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
					ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
					ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
					ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
					ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				}),
			}),
		})
		ui.hueCursor = New("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cp.Hue, 0.5),
			Size = UDim2.fromOffset(11, 11),
			ZIndex = 55,
			Parent = ui.hue,
		}, { Corner(6), New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }) })
		y = y + 8 + 10

		if hasAlpha then
			ui.alpha = New("Frame", {
				BackgroundColor3 = "ElementHover",
				Position = UDim2.fromOffset(10, y),
				Size = UDim2.new(1, -20, 0, 8),
				ZIndex = 51,
				Parent = frame,
			}, { Corner(4) })
			ui.alphaFill = New("Frame", { BackgroundColor3 = cp.Value, Size = UDim2.fromScale(1, 1), ZIndex = 52, Parent = ui.alpha }, {
				Corner(4),
				New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
			})
			ui.alphaCursor = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(11, 11),
				ZIndex = 55,
				Parent = ui.alpha,
			}, { Corner(6), New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }) })
			y = y + 8 + 10
		end

		-- Rainbow / Fading
		ui.rainbow = New("TextButton", {
			Text = "Rainbow",
			TextSize = 11,
			Position = UDim2.fromOffset(10, y),
			Size = UDim2.new(0.5, -10, 0, 16),
			ZIndex = 51,
			Parent = frame,
		})
		ui.fading = New("TextButton", {
			Text = "Fading",
			TextSize = 11,
			Position = UDim2.new(0.5, 0, 0, y),
			Size = UDim2.new(0.5, -10, 0, 16),
			ZIndex = 51,
			Parent = frame,
		})
		y = y + 16 + 8

		ui.rgb = New("TextBox", {
			TextSize = 11,
			TextColor3 = "SubText",
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(10, y),
			Size = UDim2.new(0.5, -10, 0, 16),
			ZIndex = 51,
			Parent = frame,
		})
		ui.hex = New("TextBox", {
			TextSize = 11,
			TextColor3 = "SubText",
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.5, 0, 0, y),
			Size = UDim2.new(0.5, -10, 0, 16),
			ZIndex = 51,
			Parent = frame,
		})

		-- interactions
		Drag(ui.sv, function(m)
			cp.Sat = Clamp((m.X - ui.sv.AbsolutePosition.X) / ui.sv.AbsoluteSize.X, 0, 1)
			cp.Vib = 1 - Clamp((m.Y - ui.sv.AbsolutePosition.Y) / ui.sv.AbsoluteSize.Y, 0, 1)
			refresh(true)
		end)
		Drag(ui.hue, function(m)
			cp.Rainbow = false
			loop()
			cp.Hue = Clamp((m.X - ui.hue.AbsolutePosition.X) / ui.hue.AbsoluteSize.X, 0, 1)
			refresh(true)
		end)
		if ui.alpha then
			Drag(ui.alpha, function(m)
				cp.Transparency = 1 - Clamp((m.X - ui.alpha.AbsolutePosition.X) / ui.alpha.AbsoluteSize.X, 0, 1)
				refresh(true)
			end)
		end
		ui.rainbow.MouseButton1Click:Connect(function() cp.Rainbow = not cp.Rainbow loop() refresh(true) end)
		ui.fading.MouseButton1Click:Connect(function() cp.Fading = not cp.Fading loop() refresh(true) end)
		ui.hex.FocusLost:Connect(function()
			local ok, c = pcall(Color3.fromHex, ui.hex.Text)
			if ok and c then cp:SetValue(c) else visuals() end
		end)
		ui.rgb.FocusLost:Connect(function()
			local r, g, b = ui.rgb.Text:match("(%d+)%D+(%d+)%D+(%d+)")
			if r then cp:SetValue(Color3.fromRGB(Clamp(tonumber(r), 0, 255), Clamp(tonumber(g), 0, 255), Clamp(tonumber(b), 0, 255))) else visuals() end
		end)

		Library:SetPopup(swatch, frame, close)
		Library:PlacePopup(frame, swatch, true)
		visuals()
	end

	Library:Connect(swatch.MouseButton1Click, function()
		if ui then Library:ClosePopup() else open() end
	end)

	if idx then Library.Options[idx] = cp end
	return cp
end

--// Key picker (used through Toggle/Label:AddKeyPicker) ----------------------------
local KEY_NAMES = { MouseButton1 = "MouseLeft", MouseButton2 = "MouseRight", MouseButton3 = "MouseMiddle" }
local KEY_REVERSE = { MouseLeft = "MouseButton1", MouseRight = "MouseButton2", MouseMiddle = "MouseButton3" }

local function normKey(k)
	if typeof(k) == "EnumItem" then k = k.Name end
	if k == nil then return "None" end
	return KEY_REVERSE[k] or k
end

function Library:_keypicker(idx, info, holder, parentToggle)
	local kp = setmetatable({
		Type = "KeyPicker",
		Value = normKey(info.Default),
		Mode = info.Mode or "Toggle",
		Toggled = false,
		Holding = false,
		Waiting = false,
		SyncToggleState = info.SyncToggleState == true,
		Callback = info.Callback,
		_changed = {},
		_clicked = {},
	}, Element)

	local btn = New("TextButton", {
		TextColor3 = "SubText",
		TextSize = 11,
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = nextOrder(),
		Parent = holder,
	})

	local function showKey()
		btn.Text = kp.Waiting and "..." or (KEY_NAMES[kp.Value] or kp.Value)
	end
	showKey()

	function kp:GetState()
		if self.Mode == "Always" then return true end
		if self.Mode == "Hold" then return self.Holding end
		return self.Toggled
	end

	local function notify()
		local s = kp:GetState()
		if kp.SyncToggleState and parentToggle then parentToggle:SetValue(s) end
		kp:_fire(s)
	end

	function kp:OnClick(fn) table.insert(self._clicked, fn) return self end

	function kp:SetValue(key, mode)
		if type(key) == "table" then key, mode = key[1], key[2] end
		if key ~= nil then self.Value = normKey(key) end
		if mode ~= nil then self.Mode = mode end
		self.Toggled, self.Holding = false, false
		showKey()
		notify()
	end

	local function matches(input)
		return input.KeyCode.Name == kp.Value or input.UserInputType.Name == kp.Value
	end

	Library:Connect(UserInputService.InputBegan, function(input, gpe)
		if kp.Waiting then
			local key
			if input.UserInputType == Enum.UserInputType.Keyboard then
				key = input.KeyCode == Enum.KeyCode.Escape and "None" or input.KeyCode.Name
			elseif KEY_NAMES[input.UserInputType.Name] then
				key = input.UserInputType.Name
			end
			if key then
				kp.Waiting = false
				kp:SetValue(key)
			end
			return
		end
		if gpe or kp.Value == "None" or kp.Mode == "Always" then return end
		if matches(input) then
			if kp.Mode == "Toggle" then kp.Toggled = not kp.Toggled else kp.Holding = true end
			for _, fn in ipairs(kp._clicked) do task.spawn(fn) end
			notify()
		end
	end)
	Library:Connect(UserInputService.InputEnded, function(input)
		if kp.Mode == "Hold" and kp.Holding and matches(input) then
			kp.Holding = false
			notify()
		end
	end)

	if parentToggle and kp.SyncToggleState then
		parentToggle:OnChanged(function(v)
			if kp.Mode == "Toggle" and kp.Toggled ~= v then kp.Toggled = v end
		end)
	end

	-- left click: bind, right click: mode menu
	Library:Connect(btn.MouseButton1Click, function()
		task.wait()
		kp.Waiting = true
		showKey()
	end)

	local menu
	local function closeMenu() if menu then menu:Destroy() menu = nil end end
	Library:Connect(btn.MouseButton2Click, function()
		if menu then Library:ClosePopup() return end
		menu = New("Frame", {
			BackgroundColor3 = "Groupbox",
			Size = UDim2.fromOffset(78, 3 * 22 + 8),
			ZIndex = 50,
			Parent = Library.Gui,
		}, { Corner(4), Stroke("Outline"), Pad(4), List(0) })
		for _, mode in ipairs({ "Always", "Toggle", "Hold" }) do
			local b = New("TextButton", {
				Text = mode,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = kp.Mode == mode and Library.Theme.Accent or Library.Theme.SubText,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = nextOrder(),
				ZIndex = 51,
				Parent = menu,
			}, { Pad(6, 0, 6, 0) })
			b.MouseButton1Click:Connect(function()
				kp:SetValue(nil, mode)
				Library:ClosePopup()
			end)
		end
		Library:SetPopup(btn, menu, closeMenu)
		Library:PlacePopup(menu, btn, true)
	end)

	if idx then Library.Options[idx] = kp end
	return kp
end

--// Groupbox ------------------------------------------------------------------------
local function CreateGroupbox(column, name, icon)
	local gb = setmetatable({ Name = name }, Container)

	local frame = New("Frame", {
		BackgroundColor3 = "Groupbox",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = nextOrder(),
		Parent = column,
	}, { Corner(5), Stroke("Outline") })

	New("Frame", { BackgroundColor3 = "Line", Size = UDim2.new(1, 0, 0, 2), ZIndex = 2, Parent = frame })

	local header = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = frame,
	})
	if icon then
		MakeIcon(icon, 12, header, { Position = UDim2.fromOffset(10, 8), TextColor3 = "Text" })
	else
		-- default diamond icon
		New("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(16, 14),
			Size = UDim2.fromOffset(8, 8),
			Rotation = 45,
			Parent = header,
		}, { New("UIStroke", { Color = Library.Theme.Text, Thickness = 1.5 }) })
		New("Frame", {
			BackgroundColor3 = "Text",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(16, 14),
			Size = UDim2.fromOffset(3, 3),
			Parent = header,
		}, { Corner(2) })
	end
	New("TextLabel", {
		Text = name,
		FontFace = FONT_BOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Parent = header,
	})

	gb.Frame = frame
	gb.Content = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	}, { Pad(10, 2, 10, 12), List(7) })

	function gb:SetVisible(v) frame.Visible = v end
	return gb
end

--// Window ---------------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local gui = self:GetGui()
	local Window = { Tabs = {}, ActiveTab = nil }
	local sidebarWidth = 180

	Window.Main = New("Frame", {
		Name = "Window",
		BackgroundColor3 = "Background",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = cfg.Position or UDim2.fromScale(0.5, 0.5),
		Size = cfg.Size or UDim2.fromOffset(700, 470),
		ClipsDescendants = true,
		Active = true,
		Parent = gui,
	}, { Corner(7), Stroke("Outline") })
	Window.Main.Visible = self.Visible
	table.insert(self.Windows, Window)

	-- sidebar
	local sidebar = New("Frame", {
		BackgroundColor3 = "Sidebar",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		Parent = Window.Main,
	})
	New("Frame", { BackgroundColor3 = "Outline", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), Parent = sidebar })

	local header = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58), Parent = sidebar })
	local iconHolder = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 17), Size = UDim2.fromOffset(24, 24), Parent = header })
	if cfg.Icon then
		MakeIcon(cfg.Icon, 20, iconHolder, { Position = UDim2.fromOffset(2, 2), TextColor3 = "Accent", ImageColor3 = "Accent" })
	else
		-- default sparkle logo
		for _, rot in ipairs({ 0, 60, 120 }) do
			New("Frame", {
				BackgroundColor3 = "Accent",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(3, 20),
				Rotation = rot,
				Parent = iconHolder,
			}, { Corner(2) })
		end
	end
	New("TextLabel", {
		Text = cfg.Title or "Library",
		FontFace = FONT_BOLD,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Parent = header,
	})

	local tabList = New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -58),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Parent = sidebar,
	}, { Pad(10, 0, 10, 10), List(3) })

	-- content
	local content = New("Frame", {
		BackgroundColor3 = "Main",
		Position = UDim2.fromOffset(sidebarWidth, 0),
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
		Parent = Window.Main,
	})
	local topBar = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), Parent = content })
	local pages = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 1, -38),
		Parent = content,
	}, { Pad(12, 0, 12, 12) })

	MakeDraggable(header, Window.Main)
	MakeDraggable(topBar, Window.Main)

	-- tabs ---------------------------------------------------------------
	local TabClass = {}
	TabClass.__index = TabClass
	local SubClass = {}
	SubClass.__index = SubClass

	function Window:AddCategory(name)
		New("TextLabel", {
			Text = name,
			TextSize = 10,
			TextColor3 = "Dim",
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = nextOrder(),
			Parent = tabList,
		}, { Pad(8, 6, 0, 0) })
	end

	function TabClass:_refresh()
		local active = Window.ActiveTab == self
		self.Bar.Visible = active
		for _, sub in ipairs(self.SubTabs) do
			local show = active and self.ActiveSub == sub
			sub.Page.Visible = show
			sub.Button.BackgroundTransparency = show and 0 or 1
			sub.Button.TextColor3 = show and Library.Theme.Text or Library.Theme.SubText
		end
	end

	function Window:SelectTab(tab)
		Library:ClosePopup()
		self.ActiveTab = tab
		for _, t in ipairs(self.Tabs) do
			local on = t == tab
			Tween(t.Button, { BackgroundTransparency = on and 0 or 1 }, 0.12)
			t.Label.TextColor3 = on and Library.Theme.Text or Library.Theme.SubText
			if t.IconObj then
				local c = on and Library.Theme.Text or Library.Theme.SubText
				if t.IconObj:IsA("TextLabel") then t.IconObj.TextColor3 = c else t.IconObj.ImageColor3 = c end
			end
			t:_refresh()
		end
	end

	function Window:AddTab(name, icon)
		if type(name) == "table" then name, icon = name.Name, name.Icon end
		local tab = setmetatable({ Name = name, SubTabs = {} }, TabClass)

		tab.Button = New("TextButton", {
			BackgroundColor3 = "Element",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = nextOrder(),
			Parent = tabList,
		}, { Corner(5) })
		tab.IconObj = MakeIcon(icon, 14, tab.Button, {
			Position = UDim2.fromOffset(10, 8),
			TextColor3 = Library.Theme.SubText,
			ImageColor3 = Library.Theme.SubText,
		})
		tab.Label = New("TextLabel", {
			Text = name,
			TextColor3 = Library.Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(icon and 34 or 12, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Parent = tab.Button,
		})
		tab.Bar = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = topBar,
		}, {
			Pad(12, 0, 12, 0),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		Library:Connect(tab.Button.MouseButton1Click, function() Window:SelectTab(tab) end)
		Library:Connect(tab.Button.MouseEnter, function()
			if Window.ActiveTab ~= tab then tab.Label.TextColor3 = Library.Theme.Text end
		end)
		Library:Connect(tab.Button.MouseLeave, function()
			if Window.ActiveTab ~= tab then tab.Label.TextColor3 = Library.Theme.SubText end
		end)

		table.insert(self.Tabs, tab)
		if not self.ActiveTab then self:SelectTab(tab) end
		return tab
	end

	function TabClass:AddSubTab(name)
		local sub = setmetatable({ Name = name, Tab = self }, SubClass)

		sub.Button = New("TextButton", {
			BackgroundColor3 = "Element",
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Library.Theme.SubText,
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = nextOrder(),
			Parent = self.Bar,
		}, { Corner(5), Pad(10, 0, 10, 0) })

		sub.Page = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = pages,
		})
		local function column(left)
			return New("ScrollingFrame", {
				Position = left and UDim2.new() or UDim2.new(0.5, 6, 0, 0),
				Size = UDim2.new(0.5, -6, 1, 0),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 0,
				Parent = sub.Page,
			}, { List(10) })
		end
		sub.Left = column(true)
		sub.Right = column(false)

		Library:Connect(sub.Button.MouseButton1Click, function() sub:Select() end)
		table.insert(self.SubTabs, sub)
		if not self.ActiveSub then self.ActiveSub = sub end
		self:_refresh()
		return sub
	end

	function SubClass:Select()
		Library:ClosePopup()
		self.Tab.ActiveSub = self
		self.Tab:_refresh()
	end
	function SubClass:AddLeftGroupbox(name, icon) return CreateGroupbox(self.Left, name, icon) end
	function SubClass:AddRightGroupbox(name, icon) return CreateGroupbox(self.Right, name, icon) end

	-- direct groupboxes on a tab (uses an automatic "General" sub tab)
	function TabClass:_default()
		if not self.DefaultSub then self.DefaultSub = self:AddSubTab("General") end
		return self.DefaultSub
	end
	function TabClass:AddLeftGroupbox(name, icon) return self:_default():AddLeftGroupbox(name, icon) end
	function TabClass:AddRightGroupbox(name, icon) return self:_default():AddRightGroupbox(name, icon) end

	-- window api
	function Window:SetVisible(v) Library:SetVisible(v) end
	function Window:Destroy() Window.Main:Destroy() end

	local toggleKey = cfg.ToggleKeybind or Enum.KeyCode.RightShift
	Library:Connect(UserInputService.InputBegan, function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then Library:Toggle() end
	end)

	if cfg.Watermark ~= false and not self.Watermark then
		self:CreateWatermark({ Title = cfg.Title or "Library", Icon = cfg.WatermarkIcon })
	end

	return Window
end

return Library
