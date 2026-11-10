--[[
	POTATO UI  —  v2.6
	A modern dark UI library for Roblox (single-file).

	Created by "potato". Free to use — just keep the credit:
	if you publish a script made with this UI, credit "potato".

	Usage:
		local Potato = loadstring(game:HttpGet(RAW_URL))()
		local Window = Potato:CreateWindow({
			Name = "potato",
			Version = "2.6",
			ToggleKey = Enum.KeyCode.P,
			ConfigFile = "potato/config.json", -- false to disable saving
		})
		local Tab = Window:CreateTab("Combat", "crosshair")
		Tab:AddToggle({
			Id = "MyToggle", -- unique id, used for saving
			Title = "My Toggle",
			Subtitle = "Does something cool",
			Icon = "sparkles",
			Default = false,
			Callback = function(value) print("toggled:", value) end,
		})
		v2.6 changelog: persistent settings, smart changelog, gradient fix,
		configurable watermark + presets, robust 3D-preview-ready layout.
]]

local LIB_VERSION = "2.6"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LUCIDE_REPO_RAW = "https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/lib/Icons.lua"
local DEFAULT_LOGO = "rbxthumb://type=Asset&id=136923910974092&w=150&h=150"

----------------------------------------------------------------------
-- ICONES (lucide)
----------------------------------------------------------------------
local LucideIconsData = nil
task.spawn(function()
	local ok, res = pcall(function()
		return game:HttpGet(LUCIDE_REPO_RAW)
	end)
	if ok and type(res) == "string" and #res > 0 then
		local fn = loadstring(res)
		if fn then
			local suc, tbl = pcall(fn)
			if suc and type(tbl) == "table" then
				LucideIconsData = tbl["48px"] or tbl
			end
		end
	end
end)

local LucideDirectAssets = {
	["eye"] = "rbxassetid://10723346959",
	["user"] = "rbxassetid://10747373176",
	["globe"] = "rbxassetid://10723404337",
	["sliders"] = "rbxassetid://10734963400",
	["sliders-horizontal"] = "rbxassetid://10734963400",
	["settings"] = "rbxassetid://10734950309",
	["folder"] = "rbxassetid://10723387563",
	["minus"] = "rbxassetid://10734896206",
	["maximize-2"] = "rbxassetid://10734886735",
	["x"] = "rbxassetid://10747384394",
	["refresh-cw"] = "rbxassetid://10734940376",
	["rotate-ccw"] = "rbxassetid://10734940376",
	["grip-vertical"] = "rbxassetid://10723405889",
	["arrow-left-right"] = "rbxassetid://10709768347",
	["move"] = "rbxassetid://10734900011",
	["search"] = "rbxassetid://10734943674",
	["check"] = "rbxassetid://10709790644",
	["sparkles"] = "rbxassetid://10734966248",
	["shield"] = "rbxassetid://10734951847",
	["crosshair"] = "rbxassetid://10709818534",
	["zap"] = "rbxassetid://10747386996",
	["sun"] = "rbxassetid://10734974297",
	["box"] = "rbxassetid://10709782497",
	["layers"] = "rbxassetid://10723424505",
	["compass"] = "rbxassetid://10709811445",
	["activity"] = "rbxassetid://10709752035",
	["palette"] = "rbxassetid://10734910430",
	["plus"] = "rbxassetid://10734924532",
	["trash"] = "rbxassetid://10747362393",
	["edit"] = "rbxassetid://10734883598"
}

local function ApplyLucideIcon(imgLabel, iconName)
	local entry = LucideIconsData and LucideIconsData[iconName]
	if entry and type(entry) == "table" and entry[1] then
		imgLabel.Image = "rbxassetid://" .. tostring(entry[1])
		if type(entry[2]) == "table" and type(entry[3]) == "table" then
			imgLabel.ImageRectSize = Vector2.new(entry[2][1] or 0, entry[2][2] or 0)
			imgLabel.ImageRectOffset = Vector2.new(entry[3][1] or 0, entry[3][2] or 0)
		end
	else
		imgLabel.Image = LucideDirectAssets[iconName] or LucideDirectAssets["sliders"]
		imgLabel.ImageRectSize = Vector2.zero
		imgLabel.ImageRectOffset = Vector2.zero
	end
end

local function CreateIcon(parent, iconName, sizePx, pos, color, zIndex)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon_" .. tostring(iconName)
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(0, sizePx, 0, sizePx)
	img.Position = pos or UDim2.new(0, 0, 0, 0)
	img.ImageColor3 = color or Color3.fromRGB(200, 200, 205)
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = zIndex or 2
	ApplyLucideIcon(img, iconName)
	img.Parent = parent
	return img
end

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
local function LerpColor(c1, c2, alpha)
	return Color3.new(
		c1.R + (c2.R - c1.R) * alpha,
		c1.G + (c2.G - c1.G) * alpha,
		c1.B + (c2.B - c1.B) * alpha
	)
end

local function Make3ColorSequence(c1, c2, c3)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.5, c2),
		ColorSequenceKeypoint.new(1, c3)
	})
end

local function BoostSequence(seq, factor)
	local pts = {}
	for _, kp in ipairs(seq.Keypoints) do
		local c = kp.Value
		table.insert(pts, ColorSequenceKeypoint.new(kp.Time, Color3.new(
			math.min(c.R * factor, 1),
			math.min(c.G * factor, 1),
			math.min(c.B * factor, 1)
		)))
	end
	return ColorSequence.new(pts)
end

local function ColorToTable(c)
	return {
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	}
end

local function TableToColor(t)
	if type(t) == "table" and type(t[1]) == "number" and type(t[2]) == "number" and type(t[3]) == "number" then
		return Color3.fromRGB(
			math.clamp(math.floor(t[1]), 0, 255),
			math.clamp(math.floor(t[2]), 0, 255),
			math.clamp(math.floor(t[3]), 0, 255)
		)
	end
	return nil
end

local function MeasureText(text, size, font)
	local ok, vec = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(1000, 100))
	end)
	if ok and vec then
		return vec.X
	end
	return #text * (size * 0.6)
end

local function BuildDerivedTheme(name, c1, c2, c3, accent)
	local avgBg = LerpColor(LerpColor(c1, c2, 0.5), c3, 0.35)
	local card1 = LerpColor(c1, Color3.new(1, 1, 1), 0.04)
	local card2 = LerpColor(c2, Color3.new(1, 1, 1), 0.03)
	local card3 = LerpColor(c3, Color3.new(1, 1, 1), 0.02)
	local cardBase = LerpColor(avgBg, Color3.new(1, 1, 1), 0.035)
	local cardHov = LerpColor(cardBase, Color3.new(1, 1, 1), 0.035)
	local ctrl = LerpColor(cardBase, Color3.new(1, 1, 1), 0.03)
	local ctrlHov = LerpColor(ctrl, Color3.new(1, 1, 1), 0.04)
	local border = LerpColor(cardBase, Color3.new(1, 1, 1), 0.09)
	local borderFocus = LerpColor(border, Color3.new(1, 1, 1), 0.12)
	return {
		Name = name,
		C1 = c1,
		C2 = c2,
		C3 = c3,
		Background = avgBg,
		Card = cardBase,
		CardHover = cardHov,
		Control = ctrl,
		ControlHov = ctrlHov,
		Border = border,
		BorderFocus = borderFocus,
		Accent = accent or Color3.fromRGB(255, 255, 255),
		Gradient = Make3ColorSequence(c1, c2, c3),
		CardGrad = Make3ColorSequence(card1, card2, card3)
	}
end

local function ThemePreviewSeq(t)
	local acc = t.Accent
	return Make3ColorSequence(
		LerpColor(t.C1, acc, 0.42),
		LerpColor(t.C2, acc, 0.24),
		LerpColor(t.C3, acc, 0.08)
	)
end

----------------------------------------------------------------------
-- TEMAS EMBUTIDOS
----------------------------------------------------------------------
local BuiltInThemeOrder = {"Pitch Black", "Midnight", "Emerald", "Crimson", "Amethyst", "Oceanic"}

local BuiltInThemes = {
	["Pitch Black"] = {
		Name = "Pitch Black",
		C1 = Color3.fromRGB(11, 11, 13),
		C2 = Color3.fromRGB(7, 7, 9),
		C3 = Color3.fromRGB(4, 4, 5),
		Background  = Color3.fromRGB(7, 7, 8),
		Card        = Color3.fromRGB(13, 13, 15),
		CardHover   = Color3.fromRGB(19, 19, 22),
		Control     = Color3.fromRGB(21, 21, 25),
		ControlHov  = Color3.fromRGB(29, 29, 35),
		Border      = Color3.fromRGB(28, 28, 33),
		BorderFocus = Color3.fromRGB(58, 58, 66),
		Accent      = Color3.fromRGB(255, 255, 255),
		Gradient    = Make3ColorSequence(Color3.fromRGB(14, 14, 17), Color3.fromRGB(8, 8, 10), Color3.fromRGB(4, 4, 5)),
		CardGrad    = Make3ColorSequence(Color3.fromRGB(18, 18, 22), Color3.fromRGB(13, 13, 16), Color3.fromRGB(9, 9, 11))
	},
	["Midnight"] = {
		Name = "Midnight",
		C1 = Color3.fromRGB(14, 19, 34),
		C2 = Color3.fromRGB(9, 12, 22),
		C3 = Color3.fromRGB(5, 7, 13),
		Background  = Color3.fromRGB(8, 10, 16),
		Card        = Color3.fromRGB(13, 17, 26),
		CardHover   = Color3.fromRGB(18, 24, 36),
		Control     = Color3.fromRGB(21, 27, 40),
		ControlHov  = Color3.fromRGB(29, 37, 54),
		Border      = Color3.fromRGB(28, 38, 56),
		BorderFocus = Color3.fromRGB(58, 82, 120),
		Accent      = Color3.fromRGB(95, 165, 255),
		Gradient    = Make3ColorSequence(Color3.fromRGB(15, 21, 36), Color3.fromRGB(9, 12, 22), Color3.fromRGB(5, 7, 13)),
		CardGrad    = Make3ColorSequence(Color3.fromRGB(20, 27, 44), Color3.fromRGB(14, 18, 30), Color3.fromRGB(10, 13, 21))
	},
	["Emerald"] = {
		Name = "Emerald",
		C1 = Color3.fromRGB(12, 26, 20),
		C2 = Color3.fromRGB(8, 17, 13),
		C3 = Color3.fromRGB(5, 10, 8),
		Background  = Color3.fromRGB(7, 12, 10),
		Card        = Color3.fromRGB(12, 20, 16),
		CardHover   = Color3.fromRGB(17, 28, 23),
		Control     = Color3.fromRGB(20, 33, 27),
		ControlHov  = Color3.fromRGB(28, 45, 37),
		Border      = Color3.fromRGB(26, 46, 36),
		BorderFocus = Color3.fromRGB(52, 98, 76),
		Accent      = Color3.fromRGB(75, 230, 155),
		Gradient    = Make3ColorSequence(Color3.fromRGB(13, 28, 21), Color3.fromRGB(8, 17, 13), Color3.fromRGB(5, 10, 8)),
		CardGrad    = Make3ColorSequence(Color3.fromRGB(18, 34, 26), Color3.fromRGB(12, 22, 18), Color3.fromRGB(9, 15, 12))
	},
	["Crimson"] = {
		Name = "Crimson",
		C1 = Color3.fromRGB(30, 12, 16),
		C2 = Color3.fromRGB(19, 8, 11),
		C3 = Color3.fromRGB(10, 5, 7),
		Background  = Color3.fromRGB(13, 7, 9),
		Card        = Color3.fromRGB(22, 12, 15),
		CardHover   = Color3.fromRGB(30, 17, 21),
		Control     = Color3.fromRGB(36, 20, 24),
		ControlHov  = Color3.fromRGB(48, 27, 33),
		Border      = Color3.fromRGB(50, 26, 31),
		BorderFocus = Color3.fromRGB(105, 50, 60),
		Accent      = Color3.fromRGB(255, 85, 105),
		Gradient    = Make3ColorSequence(Color3.fromRGB(30, 12, 16), Color3.fromRGB(19, 8, 11), Color3.fromRGB(10, 5, 7)),
		CardGrad    = Make3ColorSequence(Color3.fromRGB(36, 17, 22), Color3.fromRGB(24, 12, 16), Color3.fromRGB(16, 9, 11))
	},
	["Amethyst"] = {
		Name = "Amethyst",
		C1 = Color3.fromRGB(24, 14, 36),
		C2 = Color3.fromRGB(15, 9, 24),
		C3 = Color3.fromRGB(8, 5, 13),
		Background  = Color3.fromRGB(10, 7, 14),
		Card        = Color3.fromRGB(17, 13, 24),
		CardHover   = Color3.fromRGB(24, 18, 34),
		Control     = Color3.fromRGB(28, 21, 39),
		ControlHov  = Color3.fromRGB(38, 29, 52),
		Border      = Color3.fromRGB(40, 29, 56),
		BorderFocus = Color3.fromRGB(84, 60, 118),
		Accent      = Color3.fromRGB(185, 120, 255),
		Gradient    = Make3ColorSequence(Color3.fromRGB(24, 14, 36), Color3.fromRGB(15, 9, 24), Color3.fromRGB(8, 5, 13)),
		CardGrad    = Make3ColorSequence(Color3.fromRGB(30, 19, 44), Color3.fromRGB(20, 13, 30), Color3.fromRGB(13, 9, 20))
	},
	["Oceanic"] = {
		Name = "Oceanic",
		C1 = Color3.fromRGB(10, 26, 34),
		C2 = Color3.fromRGB(7, 17, 23),
		C3 = Color3.fromRGB(4, 10, 14),
		Background  = Color3.fromRGB(6, 11, 14),
		Card        = Color3.fromRGB(11, 19, 24),
		CardHover   = Color3.fromRGB(16, 27, 34),
		Control     = Color3.fromRGB(19, 32, 40),
		ControlHov  = Color3.fromRGB(26, 43, 54),
		Border      = Color3.fromRGB(24, 44, 55),
		BorderFocus = Color3.fromRGB(52, 95, 118),
		Accent      = Color3.fromRGB(70, 215, 245),
		Gradient    = Make3ColorSequence(Color3.fromRGB(10, 26, 34), Color3.fromRGB(7, 17, 23), Color3.fromRGB(4, 10, 14)),
		CardGrad    = Make3ColorSequence(Color3.fromRGB(16, 32, 42), Color3.fromRGB(11, 21, 28), Color3.fromRGB(8, 14, 19))
	}
}

local MAX_CUSTOM_THEMES = 3
local TAB_PAD = 10

-- configuracoes reservadas da library (aplicadas e salvas automaticamente)
local LIBRARY_DEFAULTS = {
	UseGradient = true,
	GradientAngle = 45,
	UIScale = 100,
	UITransparency = 0,
	ThemeName = "Pitch Black",
	Watermark = true,
	WmShowLogo = true,
	WmShowName = true,
	WmShowFps = true,
	WmShowPing = false,
	WmShowUser = true,
	WmShowTime = false,
	ToggleKey = Enum.KeyCode.P,
	PreviewOnLeft = false
}

local LIBRARY_RANGES = {
	GradientAngle = {0, 360},
	UIScale = {70, 130},
	UITransparency = {0, 75}
}

local DEFAULT_CHANGELOG = {
	{"v2.6  •  Persistent settings & smart changelog", "Every option, theme, custom theme, tab order, tab and content colors, card order, watermark position and preview side is saved automatically to the config file. This window only opens when an older saved version is detected; a first run opens nothing."},
	{"v2.6  •  Gradient themes fixed", "Gradient surfaces used to multiply a dark base color with a dark gradient, which turned everything almost black. Midnight, Emerald, Crimson, Amethyst, Oceanic and custom themes are now clearly visible, and the theme buttons show bright previews with an accent dot."},
	{"v2.6  •  Watermark settings", "New watermark controls: logo, name, FPS, ping, username and clock toggles, plus one-click presets (only potato, potato + FPS, potato + name, FPS + name, everything, logo only). The bar resizes itself and remembers where you dragged it."},
	{"v2.6  •  Preview, tabs and Tab Edit polish", "Character preview opens on the right by default (swap it in Tab Edit, it is saved) and loads more reliably. The tab underline is centered, the duplicate + on New Theme is gone, and Tab Edit now dims text instead of inverting the button or adding strokes."},
	{"v2.5  •  Custom Theme Studio & Brand Logo", "Added the potato logo next to the title, plus Custom Theme Studio (+ New Theme) supporting up to 3 user-made 3-color gradient themes with HSV color palette, presets, custom naming, edit, and delete."},
	{"v2.5  •  3D Character Preview Framing", "Adjusted optical camera distance and centered the ESP overlay so your entire character fits cleanly inside the preview bounding box."},
	{"v2.4  •  Visuals-Only 3D Preview & Independent Corner ESP", "3D character preview appears exclusively on the visuals tab, and Corner Box Style works both solo and combined with Bounding Box."},
	{"v2.3  •  In-Tab Edit & Drag Reordering", "Tab Edit mode inside every tab to drag options up/down, customize tab & content colors, and drag the preview header to swap left/right side."}
}

local Potato = {}
Potato.Version = LIB_VERSION

----------------------------------------------------------------------
-- CreateWindow
----------------------------------------------------------------------
function Potato:CreateWindow(opts)
	opts = opts or {}

	local AppName = opts.Name or "potato"
	local AppVersion = tostring(opts.Version or LIB_VERSION)
	local Logo = opts.Logo or DEFAULT_LOGO

	-- ToggleKey via opts: vira o default do keybind de esconder a UI
	-- (o que estiver salvo no config do usuario continua tendo prioridade)
	if typeof(opts.ToggleKey) == "EnumItem" then
		LIBRARY_DEFAULTS.ToggleKey = opts.ToggleKey
	end

	-- ConfigFile: nil = padrao (pasta com o nome do script), false = desativado
	local ConfigFile = opts.ConfigFile
	if ConfigFile == nil then
		ConfigFile = string.lower(tostring(AppName):gsub("%s+", "")) .. "/config.json"
	end
	if ConfigFile == false then
		ConfigFile = nil
	end
	local ConfigFolder = ConfigFile and (ConfigFile:match("^(.*)/[^/]+$")) or nil

	local ExpandedWidth = tonumber(opts.Width) or 760
	local ExpandedHeight = tonumber(opts.Height) or 470
	local MinimizedWidth = 195
	local MinimizedHeight = 46

	-- se a library for carregada de novo, descarrega a instancia anterior
	local Env = nil
	pcall(function()
		if typeof(getgenv) == "function" then
			Env = getgenv()
		end
	end)
	if Env and type(Env.__PotatoUnload) == "function" then
		pcall(Env.__PotatoUnload)
		Env.__PotatoUnload = nil
	end

	local Connections = {}
	local function Connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(Connections, c)
		return c
	end

	------------------------------------------------------------------
	-- CONFIG (ler / salvar)
	------------------------------------------------------------------
	local HasFS = (ConfigFile ~= nil)
		and (typeof(writefile) == "function") and (typeof(readfile) == "function") and (typeof(isfile) == "function")

	local function ReadConfigFile()
		if not HasFS then
			return nil
		end
		local okExists, exists = pcall(isfile, ConfigFile)
		if not okExists or not exists then
			return nil
		end
		local okRead, raw = pcall(readfile, ConfigFile)
		if not okRead or type(raw) ~= "string" or raw == "" then
			return nil
		end
		local okJson, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not okJson or type(data) ~= "table" then
			return nil
		end
		return data
	end

	local function WriteConfigFile(data)
		if not HasFS then
			return false
		end
		pcall(function()
			if ConfigFolder and typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(ConfigFolder) then
				makefolder(ConfigFolder)
			end
		end)
		local ok = pcall(function()
			writefile(ConfigFile, HttpService:JSONEncode(data))
		end)
		return ok
	end

	local Saved = ReadConfigFile()
	local SavedSettings = nil
	if type(Saved) == "table" then
		-- compatibilidade com o formato antigo (chave "State")
		if type(Saved.Settings) == "table" then
			SavedSettings = Saved.Settings
		elseif type(Saved.State) == "table" then
			SavedSettings = Saved.State
		end
	end
	SavedSettings = SavedSettings or {}

	local ShowChangelogOnStart = (Saved ~= nil) and (tostring(Saved.Version) ~= AppVersion)

	-- temas por janela (copias independentes dos embutidos)
	local Themes = {}
	for k, v in pairs(BuiltInThemes) do
		Themes[k] = v
	end
	local CustomThemes = {}

	-- estado da library (configs reservadas)
	local State = {}
	for k, v in pairs(LIBRARY_DEFAULTS) do
		State[k] = v
	end
	for key, default in pairs(LIBRARY_DEFAULTS) do
		local v = SavedSettings[key]
		if v ~= nil then
			if key == "ToggleKey" then
				local ok, kc = pcall(function()
					return Enum.KeyCode[v]
				end)
				if ok and kc and kc ~= Enum.KeyCode.Unknown then
					State[key] = kc
				end
			elseif key == "ThemeName" then
				if type(v) == "string" and (Themes[v] or v == "Pitch Black") then
					State[key] = v
				end
			elseif type(v) == type(default) then
				if type(v) == "number" and LIBRARY_RANGES[key] then
					v = math.clamp(v, LIBRARY_RANGES[key][1], LIBRARY_RANGES[key][2])
				end
				State[key] = v
			end
		end
	end

	local function LoadCustomThemes(saved, clearFirst)
		if clearFirst then
			for _, ct in ipairs(CustomThemes) do
				Themes[ct.Name] = nil
			end
			table.clear(CustomThemes)
		end
		if type(saved) ~= "table" or type(saved.CustomThemes) ~= "table" then
			return
		end
		for _, ct in ipairs(saved.CustomThemes) do
			if #CustomThemes >= MAX_CUSTOM_THEMES then
				break
			end
			if type(ct) == "table" and type(ct.Name) == "string" and not Themes[ct.Name] then
				local c1 = TableToColor(ct.C1)
				local c2 = TableToColor(ct.C2)
				local c3 = TableToColor(ct.C3)
				if c1 and c2 and c3 then
					local theme = BuildDerivedTheme(ct.Name, c1, c2, c3, TableToColor(ct.Accent))
					table.insert(CustomThemes, theme)
					Themes[ct.Name] = theme
				end
			end
		end
	end

	LoadCustomThemes(Saved, false)
	if not Themes[State.ThemeName] then
		State.ThemeName = "Pitch Black"
	end

	local Theme = {
		Background  = Color3.fromRGB(7, 7, 8),
		Card        = Color3.fromRGB(13, 13, 15),
		CardHover   = Color3.fromRGB(19, 19, 22),
		Control     = Color3.fromRGB(21, 21, 25),
		ControlHov  = Color3.fromRGB(29, 29, 35),
		Border      = Color3.fromRGB(28, 28, 33),
		BorderFocus = Color3.fromRGB(58, 58, 66),
		TextPrimary = Color3.fromRGB(245, 245, 247),
		TextSub     = Color3.fromRGB(145, 145, 152),
		TextMuted   = Color3.fromRGB(85, 85, 92),
		Accent      = Color3.fromRGB(255, 255, 255),
		Danger      = Color3.fromRGB(235, 70, 70)
	}

	local function SyncThemeTable(name)
		local t = Themes[name] or Themes["Pitch Black"]
		Theme.Background = t.Background
		Theme.Card = t.Card
		Theme.CardHover = t.CardHover
		Theme.Control = t.Control
		Theme.ControlHov = t.ControlHov
		Theme.Border = t.Border
		Theme.BorderFocus = t.BorderFocus
		Theme.Accent = t.Accent
	end
	SyncThemeTable(State.ThemeName)

	local UI = {
		Tabs = {},
		TabOrder = {},
		ActiveTab = nil,
		IsMinimized = false,
		IsHidden = false,
		ChangelogOpen = false,
		BindingKey = false,
		JustBound = false,
		Ready = false,
		SidePanel = nil,
		SidePanelTab = nil
	}

	local Controls = {}

	------------------------------------------------------------------
	-- TWEENS / REGISTROS DE TEMA
	------------------------------------------------------------------
	local function Tween(obj, info, props)
		local t = TweenService:Create(obj, info, props)
		t:Play()
		return t
	end

	local FastTween = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local SmoothTween = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local PopInTween = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local BaseTransparencies = setmetatable({}, {__mode = "k"})
	local ThemedStrokes = {}
	local ThemedDividers = {}
	local Surfaces = {}
	local SwitchRegistry = {}

	local function RegisterTrans(obj, prop, baseVal)
		if not BaseTransparencies[obj] then
			BaseTransparencies[obj] = {}
		end
		BaseTransparencies[obj][prop] = baseVal
	end

	local function ApplyUITransparency(alpha)
		for obj, props in pairs(BaseTransparencies) do
			if obj and obj.Parent then
				for prop, baseVal in pairs(props) do
					obj[prop] = math.clamp(baseVal + (1 - baseVal) * alpha, 0, 0.96)
				end
			end
		end
	end

	local function RegStroke(stroke, key)
		table.insert(ThemedStrokes, {Obj = stroke, Key = key or "Border"})
	end

	local function RegDivider(frame)
		table.insert(ThemedDividers, frame)
	end

	-- UIGradient multiplica a cor de fundo: com gradiente ligado o fundo vira branco
	local GRAD_TINT = 0.9

	local function SurfaceTint(s)
		if s.Grad and State.UseGradient then
			if s.Kind == "Bg" then
				return Color3.new(1, 1, 1)
			end
			local v = s.Hover and 1 or GRAD_TINT
			return Color3.new(v, v, v)
		end
		if s.Kind == "Card" then
			return s.Hover and Theme.CardHover or Theme.Card
		elseif s.Kind == "Control" then
			return s.Hover and Theme.ControlHov or Theme.Control
		end
		return Theme.Background
	end

	local function GradientFor(themeObj, isCard)
		if isCard then
			return BoostSequence(themeObj.CardGrad, 1 / GRAD_TINT)
		end
		return themeObj.Gradient
	end

	local function RegisterSurface(obj, kind, withGradient)
		local s = {Obj = obj, Kind = kind, Hover = false}
		if withGradient then
			local g = Instance.new("UIGradient")
			g.Rotation = State.GradientAngle
			g.Color = GradientFor(Themes[State.ThemeName], kind == "Card")
			g.Enabled = State.UseGradient
			g.Parent = obj
			s.Grad = g
		end
		obj.BackgroundColor3 = SurfaceTint(s)
		table.insert(Surfaces, s)
		return s
	end

	local function RefreshSurface(s, animate)
		if not (s.Obj and s.Obj.Parent) then
			return
		end
		if s.Grad then
			s.Grad.Color = GradientFor(Themes[State.ThemeName], s.Kind == "Card")
			s.Grad.Rotation = State.GradientAngle
			s.Grad.Enabled = State.UseGradient
		end
		local tint = SurfaceTint(s)
		if animate then
			Tween(s.Obj, FastTween, {BackgroundColor3 = tint})
		else
			s.Obj.BackgroundColor3 = tint
		end
	end

	-- forward declarations (atribuidas mais adiante, antes do uso real)
	local SaveScheduled = false
	local BuildConfigData, SaveConfig
	local function MarkDirty()
		if not UI.Ready or SaveScheduled then
			return
		end
		SaveScheduled = true
		task.delay(0.8, function()
			SaveScheduled = false
			if UI.Ready and SaveConfig then
				pcall(SaveConfig)
			end
		end)
	end

	local OldGui = PlayerGui:FindFirstChild("PotatoMinimalUI")
	if OldGui then
		OldGui:Destroy()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "PotatoMinimalUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.DisplayOrder = 100
	ScreenGui.Parent = PlayerGui

	local ApplyGlobalAccent -- definido depois (precisa das tabs)

	------------------------------------------------------------------
	-- WATERMARK (obrigatorio da library)
	------------------------------------------------------------------
	local WmFps = 60
	local WmPing = 0

	local function UpdateWatermark(animate)
		local wm = UI.Watermark
		if not wm then
			return
		end
		local parts = {}
		if State.WmShowName then
			table.insert(parts, tostring(AppName))
		end
		if State.WmShowFps then
			table.insert(parts, tostring(WmFps) .. " fps")
		end
		if State.WmShowPing then
			table.insert(parts, tostring(WmPing) .. " ms")
		end
		if State.WmShowUser then
			table.insert(parts, LocalPlayer.Name)
		end
		if State.WmShowTime then
			table.insert(parts, os.date("%H:%M"))
		end
		local text = table.concat(parts, "  |  ")
		local hasLogo = State.WmShowLogo
		local hasText = text ~= ""

		wm.Visible = State.Watermark and (hasLogo or hasText)
		UI.WatermarkLogo.Visible = hasLogo
		UI.WatermarkText.Text = text

		local textX = hasLogo and 30 or 10
		UI.WatermarkText.Position = UDim2.new(0, textX, 0, 0)
		UI.WatermarkText.Size = UDim2.new(1, -(textX + 8), 1, 0)

		local width
		if hasText then
			width = textX + math.ceil(MeasureText(text, 11, Enum.Font.Montserrat)) + 12
		else
			width = 30
		end
		local size = UDim2.new(0, width, 0, 26)
		if animate then
			Tween(wm, FastTween, {Size = size})
		else
			wm.Size = size
		end
	end

	do
		local Watermark = Instance.new("Frame")
		Watermark.Name = "Watermark"
		Watermark.AnchorPoint = Vector2.new(1, 0)
		Watermark.Size = UDim2.new(0, 220, 0, 26)
		Watermark.Position = UDim2.new(1, -18, 1, -42)
		Watermark.BorderSizePixel = 0
		Watermark.Active = true
		Watermark.Parent = ScreenGui
		Watermark.BackgroundTransparency = 0.05
		RegisterTrans(Watermark, "BackgroundTransparency", 0.05)
		RegisterSurface(Watermark, "Bg", true)
		UI.Watermark = Watermark
		if type(Saved) == "table" and type(Saved.WatermarkPos) == "table" and #Saved.WatermarkPos == 4 then
			local p = Saved.WatermarkPos
			if type(p[1]) == "number" and type(p[2]) == "number" and type(p[3]) == "number" and type(p[4]) == "number" then
				Watermark.Position = UDim2.new(p[1], p[2], p[3], p[4])
			end
		end

		local wmCorner = Instance.new("UICorner")
		wmCorner.CornerRadius = UDim.new(0, 6)
		wmCorner.Parent = Watermark

		local wmStroke = Instance.new("UIStroke")
		wmStroke.Color = Theme.Border
		wmStroke.Thickness = 1
		wmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		wmStroke.Parent = Watermark
		RegisterTrans(wmStroke, "Transparency", 0)
		RegStroke(wmStroke)

		local wmLogo = Instance.new("ImageLabel")
		wmLogo.Size = UDim2.new(0, 14, 0, 14)
		wmLogo.Position = UDim2.new(0, 8, 0.5, -7)
		wmLogo.BackgroundTransparency = 1
		wmLogo.Image = Logo
		wmLogo.ScaleType = Enum.ScaleType.Fit
		wmLogo.Parent = Watermark
		UI.WatermarkLogo = wmLogo

		local WatermarkText = Instance.new("TextLabel")
		WatermarkText.Size = UDim2.new(1, -38, 1, 0)
		WatermarkText.Position = UDim2.new(0, 30, 0, 0)
		WatermarkText.BackgroundTransparency = 1
		WatermarkText.Font = Enum.Font.Montserrat
		WatermarkText.TextSize = 11
		WatermarkText.TextColor3 = Theme.TextSub
		WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
		WatermarkText.TextTruncate = Enum.TextTruncate.AtEnd
		WatermarkText.Text = ""
		WatermarkText.Parent = Watermark
		UI.WatermarkText = WatermarkText

		local wmDragging, wmDragStart, wmStartPos = false, nil, nil
		local wmDirtyQueued = false
		Watermark.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				wmDragging = true
				wmDragStart = input.Position
				wmStartPos = Watermark.Position
			end
		end)
		Connect(UserInputService.InputChanged, function(input)
			if wmDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - wmDragStart
				Watermark.Position = UDim2.new(wmStartPos.X.Scale, wmStartPos.X.Offset + delta.X, wmStartPos.Y.Scale, wmStartPos.Y.Offset + delta.Y)
			end
		end)
		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and wmDragging then
				wmDragging = false
				MarkDirty()
			end
		end)
	end

	------------------------------------------------------------------
	-- JANELA PRINCIPAL
	------------------------------------------------------------------
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, ExpandedWidth, 0, ExpandedHeight)
	MainFrame.Position = UDim2.new(0.5, -ExpandedWidth / 2, 0.5, -ExpandedHeight / 2)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui
	RegisterTrans(MainFrame, "BackgroundTransparency", 0)
	RegisterSurface(MainFrame, "Bg", true)
	UI.MainFrame = MainFrame

	local MainScale = Instance.new("UIScale")
	MainScale.Scale = 1
	MainScale.Parent = MainFrame
	UI.MainScale = MainScale

	do
		local mainCorner = Instance.new("UICorner")
		mainCorner.CornerRadius = UDim.new(0, 8)
		mainCorner.Parent = MainFrame

		local mainStroke = Instance.new("UIStroke")
		mainStroke.Color = Theme.Border
		mainStroke.Thickness = 1
		mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		mainStroke.Parent = MainFrame
		RegisterTrans(mainStroke, "Transparency", 0)
		RegStroke(mainStroke)
	end

	do
		local TopBar = Instance.new("Frame")
		TopBar.Name = "TopBar"
		TopBar.Size = UDim2.new(1, 0, 0, 46)
		TopBar.BackgroundTransparency = 1
		TopBar.BorderSizePixel = 0
		TopBar.ZIndex = 3
		TopBar.Parent = MainFrame
		UI.TopBar = TopBar

		local TopDivider = Instance.new("Frame")
		TopDivider.Size = UDim2.new(1, 0, 0, 1)
		TopDivider.Position = UDim2.new(0, 0, 1, -1)
		TopDivider.BackgroundColor3 = Theme.Border
		TopDivider.BorderSizePixel = 0
		TopDivider.ZIndex = 4
		TopDivider.Parent = TopBar
		RegisterTrans(TopDivider, "BackgroundTransparency", 0)
		RegDivider(TopDivider)
		UI.TopDivider = TopDivider

		local BrandContainer = Instance.new("Frame")
		BrandContainer.Size = UDim2.new(0, 120, 1, 0)
		BrandContainer.Position = UDim2.new(0, 14, 0, 0)
		BrandContainer.BackgroundTransparency = 1
		BrandContainer.ZIndex = 4
		BrandContainer.Parent = TopBar

		local BrandLogo = Instance.new("ImageLabel")
		BrandLogo.Name = "BrandLogo"
		BrandLogo.Size = UDim2.new(0, 22, 0, 22)
		BrandLogo.Position = UDim2.new(0, 0, 0.5, -11)
		BrandLogo.BackgroundTransparency = 1
		BrandLogo.Image = Logo
		BrandLogo.ScaleType = Enum.ScaleType.Fit
		BrandLogo.ZIndex = 4
		BrandLogo.Parent = BrandContainer

		local BrandTitle = Instance.new("TextLabel")
		BrandTitle.Size = UDim2.new(1, -28, 1, 0)
		BrandTitle.Position = UDim2.new(0, 28, 0, 0)
		BrandTitle.BackgroundTransparency = 1
		BrandTitle.Font = Enum.Font.MontserratBold
		BrandTitle.Text = AppName
		BrandTitle.TextSize = 15
		BrandTitle.TextColor3 = Theme.TextPrimary
		BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
		BrandTitle.ZIndex = 4
		BrandTitle.Parent = BrandContainer

		local TabContainer = Instance.new("Frame")
		TabContainer.Name = "TabContainer"
		TabContainer.Size = UDim2.new(1, -235, 1, 0)
		TabContainer.Position = UDim2.new(0, 135, 0, 0)
		TabContainer.BackgroundTransparency = 1
		TabContainer.ZIndex = 4
		TabContainer.Parent = TopBar
		UI.TabContainer = TabContainer

		local ActiveTabLine = Instance.new("Frame")
		ActiveTabLine.Name = "ActiveTabLine"
		ActiveTabLine.Size = UDim2.new(0, 30, 0, 2)
		ActiveTabLine.Position = UDim2.new(0, TAB_PAD, 1, -2)
		ActiveTabLine.BackgroundColor3 = Theme.Accent
		ActiveTabLine.BorderSizePixel = 0
		ActiveTabLine.ZIndex = 5
		ActiveTabLine.Parent = TabContainer
		UI.ActiveTabLine = ActiveTabLine

		local WindowControls = Instance.new("Frame")
		WindowControls.Size = UDim2.new(0, 68, 0, 26)
		WindowControls.Position = UDim2.new(1, -78, 0.5, -13)
		WindowControls.BackgroundTransparency = 1
		WindowControls.ZIndex = 4
		WindowControls.Parent = TopBar

		local MinBtn = Instance.new("TextButton")
		MinBtn.Size = UDim2.new(0, 28, 0, 26)
		MinBtn.Position = UDim2.new(0, 0, 0, 0)
		MinBtn.Text = ""
		MinBtn.AutoButtonColor = false
		MinBtn.ZIndex = 4
		MinBtn.Parent = WindowControls
		RegisterTrans(MinBtn, "BackgroundTransparency", 0)
		local minSurf = RegisterSurface(MinBtn, "Card", false)
		UI.MinBtn = MinBtn

		local minCorner = Instance.new("UICorner")
		minCorner.CornerRadius = UDim.new(0, 5)
		minCorner.Parent = MinBtn

		local minStroke = Instance.new("UIStroke")
		minStroke.Color = Theme.Border
		minStroke.Thickness = 1
		minStroke.Parent = MinBtn
		RegisterTrans(minStroke, "Transparency", 0)
		RegStroke(minStroke)

		local MinIcon = CreateIcon(MinBtn, "minus", 13, UDim2.new(0.5, -6, 0.5, -6), Theme.TextSub, 5)
		UI.MinIcon = MinIcon

		local CloseBtn = Instance.new("TextButton")
		CloseBtn.Size = UDim2.new(0, 28, 0, 26)
		CloseBtn.Position = UDim2.new(0, 36, 0, 0)
		CloseBtn.Text = ""
		CloseBtn.AutoButtonColor = false
		CloseBtn.ZIndex = 4
		CloseBtn.Parent = WindowControls
		RegisterTrans(CloseBtn, "BackgroundTransparency", 0)
		local closeSurf = RegisterSurface(CloseBtn, "Card", false)
		UI.CloseBtn = CloseBtn

		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0, 5)
		closeCorner.Parent = CloseBtn

		local closeStroke = Instance.new("UIStroke")
		closeStroke.Color = Theme.Border
		closeStroke.Thickness = 1
		closeStroke.Parent = CloseBtn
		RegisterTrans(closeStroke, "Transparency", 0)
		RegStroke(closeStroke)

		local CloseIcon = CreateIcon(CloseBtn, "x", 13, UDim2.new(0.5, -6, 0.5, -6), Theme.TextSub, 5)

		MinBtn.MouseEnter:Connect(function()
			minSurf.Hover = true
			Tween(MinBtn, FastTween, {BackgroundColor3 = SurfaceTint(minSurf)})
			Tween(MinIcon, FastTween, {ImageColor3 = Theme.TextPrimary})
		end)
		MinBtn.MouseLeave:Connect(function()
			minSurf.Hover = false
			Tween(MinBtn, FastTween, {BackgroundColor3 = SurfaceTint(minSurf)})
			Tween(MinIcon, FastTween, {ImageColor3 = Theme.TextSub})
		end)

		CloseBtn.MouseEnter:Connect(function()
			Tween(CloseBtn, FastTween, {BackgroundColor3 = Theme.Danger})
			Tween(CloseIcon, FastTween, {ImageColor3 = Theme.TextPrimary})
		end)
		CloseBtn.MouseLeave:Connect(function()
			Tween(CloseBtn, FastTween, {BackgroundColor3 = SurfaceTint(closeSurf)})
			Tween(CloseIcon, FastTween, {ImageColor3 = Theme.TextSub})
		end)
	end

	local function FooterText()
		return "press [" .. State.ToggleKey.Name .. "] to toggle interface  •  drag tabs or enable tab edit"
	end

	do
		local FooterBar = Instance.new("Frame")
		FooterBar.Name = "FooterBar"
		FooterBar.Size = UDim2.new(1, 0, 0, 26)
		FooterBar.Position = UDim2.new(0, 0, 1, -26)
		FooterBar.BackgroundTransparency = 1
		FooterBar.BorderSizePixel = 0
		FooterBar.ZIndex = 3
		FooterBar.Parent = MainFrame
		UI.FooterBar = FooterBar

		local FooterDivider = Instance.new("Frame")
		FooterDivider.Size = UDim2.new(1, 0, 0, 1)
		FooterDivider.Position = UDim2.new(0, 0, 0, 0)
		FooterDivider.BackgroundColor3 = Theme.Border
		FooterDivider.BorderSizePixel = 0
		FooterDivider.ZIndex = 4
		FooterDivider.Parent = FooterBar
		RegisterTrans(FooterDivider, "BackgroundTransparency", 0)
		RegDivider(FooterDivider)

		local FooterLeft = Instance.new("TextLabel")
		FooterLeft.Size = UDim2.new(0.6, 0, 1, 0)
		FooterLeft.Position = UDim2.new(0, 14, 0, 0)
		FooterLeft.BackgroundTransparency = 1
		FooterLeft.Font = Enum.Font.Montserrat
		FooterLeft.Text = FooterText()
		FooterLeft.TextSize = 10
		FooterLeft.TextColor3 = Theme.TextMuted
		FooterLeft.TextXAlignment = Enum.TextXAlignment.Left
		FooterLeft.ZIndex = 4
		FooterLeft.Parent = FooterBar
		UI.FooterLeft = FooterLeft

		local VersionBtn = Instance.new("TextButton")
		VersionBtn.Name = "VersionBtn"
		VersionBtn.Size = UDim2.new(0, 86, 0, 18)
		VersionBtn.Position = UDim2.new(1, -96, 0.5, -9)
		VersionBtn.Font = Enum.Font.MontserratBold
		VersionBtn.Text = tostring(AppName) .. " " .. AppVersion
		VersionBtn.TextSize = 10
		VersionBtn.TextColor3 = Theme.TextSub
		VersionBtn.AutoButtonColor = false
		VersionBtn.ZIndex = 4
		VersionBtn.Parent = FooterBar
		RegisterTrans(VersionBtn, "BackgroundTransparency", 0)
		local verSurf = RegisterSurface(VersionBtn, "Card", false)
		UI.VersionBtn = VersionBtn

		local verCorner = Instance.new("UICorner")
		verCorner.CornerRadius = UDim.new(0, 4)
		verCorner.Parent = VersionBtn

		local verStroke = Instance.new("UIStroke")
		verStroke.Color = Theme.Border
		verStroke.Thickness = 1
		verStroke.Parent = VersionBtn
		RegisterTrans(verStroke, "Transparency", 0)
		RegStroke(verStroke)

		VersionBtn.MouseEnter:Connect(function()
			verSurf.Hover = true
			Tween(VersionBtn, FastTween, {BackgroundColor3 = SurfaceTint(verSurf), TextColor3 = Theme.TextPrimary})
		end)
		VersionBtn.MouseLeave:Connect(function()
			verSurf.Hover = false
			Tween(VersionBtn, FastTween, {BackgroundColor3 = SurfaceTint(verSurf), TextColor3 = Theme.TextSub})
		end)
	end

	local BodyFrame = Instance.new("Frame")
	BodyFrame.Name = "BodyFrame"
	BodyFrame.Size = UDim2.new(1, 0, 1, -72)
	BodyFrame.Position = UDim2.new(0, 0, 0, 46)
	BodyFrame.BackgroundTransparency = 1
	BodyFrame.ClipsDescendants = true
	BodyFrame.Parent = MainFrame
	UI.BodyFrame = BodyFrame

	local OptionsPanel = Instance.new("Frame")
	OptionsPanel.Name = "OptionsPanel"
	OptionsPanel.Size = UDim2.new(1, 0, 1, 0)
	OptionsPanel.BackgroundTransparency = 1
	OptionsPanel.ClipsDescendants = true
	OptionsPanel.Parent = BodyFrame
	UI.OptionsPanel = OptionsPanel

	------------------------------------------------------------------
	-- BOTAO COM ICONE (centralizado)
	------------------------------------------------------------------
	local function CreateIconButton(parent, text, iconName, size, position, textSize, zIndex)
		local btn = Instance.new("TextButton")
		btn.Size = size
		btn.Position = position
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ZIndex = zIndex or 2
		btn.Parent = parent

		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 1, 0)
		row.ZIndex = btn.ZIndex + 1
		row.Parent = btn

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 6)
		layout.Parent = row

		local icon = CreateIcon(row, iconName, textSize + 2, nil, Theme.TextSub, row.ZIndex)
		icon.LayoutOrder = 1

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 1, 0)
		label.Font = Enum.Font.MontserratBold
		label.Text = text
		label.TextSize = textSize
		label.TextColor3 = Theme.TextSub
		label.ZIndex = row.ZIndex
		label.LayoutOrder = 2
		label.Parent = row

		return btn, label, icon
	end

	------------------------------------------------------------------
	-- LAYOUT DO PAINEL LATERAL (opcional, criado com Window:CreateSidePanel)
	------------------------------------------------------------------
	local function ApplyPanelSideLayout(animate)
		local panel = UI.SidePanel
		local hasPanel = panel ~= nil
		local isPanelTab = hasPanel and UI.ActiveTab == UI.SidePanelTab

		if panel then
			panel.Frame.Visible = isPanelTab
		end

		local pPos, oPos, oSize, divPos
		if not isPanelTab then
			pPos = UDim2.new(0, 0, 0, 0)
			oPos = UDim2.new(0, 0, 0, 0)
			oSize = UDim2.new(1, 0, 1, 0)
			divPos = UDim2.new(1, -1, 0, 0)
		elseif State.PreviewOnLeft then
			pPos = UDim2.new(0, 0, 0, 0)
			oPos = UDim2.new(0, 265, 0, 0)
			oSize = UDim2.new(1, -265, 1, 0)
			divPos = UDim2.new(1, -1, 0, 0)
		else
			pPos = UDim2.new(1, -265, 0, 0)
			oPos = UDim2.new(0, 0, 0, 0)
			oSize = UDim2.new(1, -265, 1, 0)
			divPos = UDim2.new(0, 0, 0, 0)
		end

		if panel then
			panel.Divider.Position = divPos
		end
		OptionsPanel.Size = oSize
		if animate and isPanelTab then
			Tween(panel.Frame, SmoothTween, {Position = pPos})
			Tween(OptionsPanel, SmoothTween, {Position = oPos})
		else
			if panel then
				panel.Frame.Position = pPos
			end
			OptionsPanel.Position = oPos
		end
	end

	-- Cria o painel lateral (265px) vinculado a uma tab. O conteudo (viewport etc)
	-- fica por conta do seu script, dentro de panel.Body.
	local function CreateSidePanel(tabName, title)
		if type(tabName) ~= "string" or tabName == "" then
			error("CreateSidePanel: tabName (string) is required", 2)
		end
		if UI.SidePanel then
			pcall(function()
				UI.SidePanel.Frame:Destroy()
			end)
			UI.SidePanel = nil
			UI.SidePanelTab = nil
		end

		local PanelTitle = tostring(title or "PREVIEW")

		local Panel = Instance.new("Frame")
		Panel.Name = "SidePanel"
		Panel.Size = UDim2.new(0, 265, 1, 0)
		Panel.Position = UDim2.new(1, -265, 0, 0)
		Panel.BackgroundTransparency = 1
		Panel.BorderSizePixel = 0
		Panel.ClipsDescendants = false
		Panel.Visible = false
		Panel.Parent = BodyFrame

		local PanelDivider = Instance.new("Frame")
		PanelDivider.Size = UDim2.new(0, 1, 1, 0)
		PanelDivider.Position = UDim2.new(0, 0, 0, 0)
		PanelDivider.BackgroundColor3 = Theme.Border
		PanelDivider.BorderSizePixel = 0
		PanelDivider.Parent = Panel
		RegisterTrans(PanelDivider, "BackgroundTransparency", 0)
		RegDivider(PanelDivider)

		local Header = Instance.new("Frame")
		Header.Size = UDim2.new(1, -24, 0, 32)
		Header.Position = UDim2.new(0, 12, 0, 10)
		Header.BackgroundTransparency = 1
		Header.Active = true
		Header.Parent = Panel

		local HeaderTitle = Instance.new("TextLabel")
		HeaderTitle.Size = UDim2.new(0.62, 0, 1, 0)
		HeaderTitle.BackgroundTransparency = 1
		HeaderTitle.Font = Enum.Font.MontserratBold
		HeaderTitle.Text = PanelTitle:upper()
		HeaderTitle.TextSize = 11
		HeaderTitle.TextColor3 = Theme.TextSub
		HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
		HeaderTitle.Parent = Header

		local DragSub = Instance.new("TextLabel")
		DragSub.Size = UDim2.new(0.38, -28, 1, 0)
		DragSub.Position = UDim2.new(0.62, 0, 0, 0)
		DragSub.BackgroundTransparency = 1
		DragSub.Font = Enum.Font.Montserrat
		DragSub.Text = ""
		DragSub.TextSize = 10
		DragSub.TextColor3 = Theme.TextMuted
		DragSub.TextXAlignment = Enum.TextXAlignment.Right
		DragSub.Parent = Header

		local SwapIndicator = Instance.new("Frame")
		SwapIndicator.Size = UDim2.new(0, 22, 0, 22)
		SwapIndicator.Position = UDim2.new(1, -22, 0.5, -11)
		SwapIndicator.Visible = false
		SwapIndicator.Parent = Header
		RegisterTrans(SwapIndicator, "BackgroundTransparency", 0)
		RegisterSurface(SwapIndicator, "Card", false)

		local swapCorner = Instance.new("UICorner")
		swapCorner.CornerRadius = UDim.new(0, 5)
		swapCorner.Parent = SwapIndicator

		local swapStroke = Instance.new("UIStroke")
		swapStroke.Color = Theme.Border
		swapStroke.Thickness = 1
		swapStroke.Parent = SwapIndicator
		RegisterTrans(swapStroke, "Transparency", 0)
		RegStroke(swapStroke)

		CreateIcon(SwapIndicator, "arrow-left-right", 12, UDim2.new(0.5, -6, 0.5, -6), Theme.Accent, 4)

		local SideBody = Instance.new("Frame")
		SideBody.Name = "SidePanelBody"
		SideBody.Size = UDim2.new(1, 0, 1, -42)
		SideBody.Position = UDim2.new(0, 0, 0, 42)
		SideBody.BackgroundTransparency = 1
		SideBody.BorderSizePixel = 0
		SideBody.Parent = Panel

		UI.SidePanel = {
			Frame = Panel,
			Divider = PanelDivider,
			Header = Header,
			DragSub = DragSub,
			SwapIndicator = SwapIndicator,
			Body = SideBody
		}
		UI.SidePanelTab = tabName

		-- troca de lado arrastando (ou clique simples) com o Tab Edit ligado
		local DraggingSideSwap = false
		local SideSwapMoved = false

		Header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and State.TabEditMode and UI.ActiveTab == UI.SidePanelTab then
				DraggingSideSwap = true
				SideSwapMoved = false
			end
		end)

		Connect(UserInputService.InputChanged, function(input)
			if DraggingSideSwap and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mainCenter = MainFrame.AbsolutePosition.X + (MainFrame.AbsoluteSize.X * 0.5)
				if input.Position.X > mainCenter + 30 and State.PreviewOnLeft then
					State.PreviewOnLeft = false
					SideSwapMoved = true
					ApplyPanelSideLayout(true)
					MarkDirty()
				elseif input.Position.X < mainCenter - 30 and not State.PreviewOnLeft then
					State.PreviewOnLeft = true
					SideSwapMoved = true
					ApplyPanelSideLayout(true)
					MarkDirty()
				end
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and DraggingSideSwap then
				DraggingSideSwap = false
				if not SideSwapMoved then
					State.PreviewOnLeft = not State.PreviewOnLeft
					ApplyPanelSideLayout(true)
					MarkDirty()
				end
			end
		end)

		ApplyPanelSideLayout(false)

		-- preview lado direito por padrao; a escolha salva manda
		return UI.SidePanel
	end

	------------------------------------------------------------------
	-- TABS
	------------------------------------------------------------------
	local TabColorSwatches = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(115, 175, 255),
		Color3.fromRGB(175, 125, 255),
		Color3.fromRGB(85, 230, 155),
		Color3.fromRGB(255, 185, 75),
		Color3.fromRGB(255, 95, 110)
	}

	local function RecalculateCardLayout(tabObj, filterText, animate)
		local query = string.lower(filterText or "")
		local y = 3
		for _, item in ipairs(tabObj.Items) do
			local match = (query == "") or (string.find(string.lower(item.SearchKey), query, 1, true) ~= nil)
			item.Card.Visible = match
			if match then
				local targetPos = UDim2.new(0, 3, 0, y)
				if animate and not item.Dragging then
					Tween(item.Card, FastTween, {Position = targetPos})
				elseif not item.Dragging then
					item.Card.Position = targetPos
				end
				y = y + item.Height + 6
			end
		end
		tabObj.Scroll.CanvasSize = UDim2.new(0, 0, 0, y + 8)
	end

	-- no Tab Edit os textos dos cards ficam semi-transparentes
	local function SetItemTextDim(item, dim)
		for _, d in ipairs(item.Card:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
				Tween(d, FastTween, {TextTransparency = dim and 0.55 or 0})
			end
		end
	end

	local function SetTabEditMode(enabled)
		State.TabEditMode = enabled
		if UI.SidePanel then
			UI.SidePanel.SwapIndicator.Visible = enabled
			UI.SidePanel.DragSub.Text = enabled and "drag / click to swap side" or ""
		end
		for _, name in ipairs(UI.TabOrder) do
			local tObj = UI.Tabs[name]
			if tObj then
				tObj.CustomizerBar.Visible = enabled
				tObj.Scroll.Position = enabled and UDim2.new(0, 12, 0, 74) or UDim2.new(0, 12, 0, 42)
				tObj.Scroll.Size = enabled and UDim2.new(1, -24, 1, -84) or UDim2.new(1, -24, 1, -52)
				local col = enabled and tObj.ContentColor or Theme.TextSub
				Tween(tObj.EditLabel, FastTween, {TextColor3 = col})
				Tween(tObj.EditIcon, FastTween, {ImageColor3 = col})
				for _, item in ipairs(tObj.Items) do
					item.GripIcon.Visible = enabled
					item.FeatureIcon.Visible = not enabled
					SetItemTextDim(item, enabled)
				end
			end
		end
	end

	local function UpdateTabPositions(animate, skipBtn)
		local xOffset = 0
		for _, name in ipairs(UI.TabOrder) do
			local tObj = UI.Tabs[name]
			if tObj then
				local w = tObj.Btn.Size.X.Offset
				tObj.LocalX = xOffset
				tObj.LocalWidth = w
				local targetPos = UDim2.new(0, xOffset, 0, 0)
				if tObj.Btn ~= skipBtn then
					if animate then
						Tween(tObj.Btn, FastTween, {Position = targetPos})
					else
						tObj.Btn.Position = targetPos
					end
				end
				if UI.ActiveTab == name then
					-- a linha cobre exatamente icone + texto
					local linePos = UDim2.new(0, xOffset + TAB_PAD, 1, -2)
					local lineSize = UDim2.new(0, math.max(16, w - TAB_PAD * 2), 0, 2)
					if animate then
						Tween(UI.ActiveTabLine, SmoothTween, {Position = linePos, Size = lineSize})
					else
						UI.ActiveTabLine.Position = linePos
						UI.ActiveTabLine.Size = lineSize
					end
				end
				xOffset = xOffset + w + 6
			end
		end
	end

	local function SwitchTab(tabName)
		UI.ActiveTab = tabName
		ApplyPanelSideLayout(false)
		for name, data in pairs(UI.Tabs) do
			local isSelected = (name == tabName)
			data.Page.Visible = isSelected
			if isSelected then
				data.Page.Position = UDim2.new(0, 10, 0, 0)
				Tween(data.Page, FastTween, {Position = UDim2.new(0, 0, 0, 0)})
				Tween(data.Label, FastTween, {TextColor3 = data.TabColor})
				Tween(data.Icon, FastTween, {ImageColor3 = data.TabColor})
				Tween(UI.ActiveTabLine, SmoothTween, {
					Position = UDim2.new(0, data.LocalX + TAB_PAD, 1, -2),
					Size = UDim2.new(0, math.max(16, data.LocalWidth - TAB_PAD * 2), 0, 2),
					BackgroundColor3 = data.TabColor
				})
			else
				Tween(data.Label, FastTween, {TextColor3 = Theme.TextMuted})
				Tween(data.Icon, FastTween, {ImageColor3 = Theme.TextMuted})
			end
		end
	end

	-- ordem das tabs vinda do config (aplicada incrementalmente)
	local function ApplySavedTabOrder()
		local order = type(Saved) == "table" and Saved.TabOrder
		if type(order) ~= "table" then
			UpdateTabPositions(false, nil)
			return
		end
		local list, used = {}, {}
		for _, n in ipairs(order) do
			if UI.Tabs[n] and not used[n] then
				table.insert(list, n)
				used[n] = true
			end
		end
		for _, n in ipairs(UI.TabOrder) do
			if not used[n] then
				table.insert(list, n)
			end
		end
		UI.TabOrder = list
		UpdateTabPositions(false, nil)
	end

	-- ordem dos cards vinda do config (aplicada a cada card criado)
	local function ApplySavedItemOrder(tabObj)
		local order = type(Saved) == "table" and type(Saved.ItemOrder) == "table" and Saved.ItemOrder[tabObj.Name]
		if type(order) ~= "table" then
			RecalculateCardLayout(tabObj, tabObj.SearchBox.Text, false)
			return
		end
		local byId = {}
		for _, it in ipairs(tabObj.Items) do
			byId[it.Id] = it
		end
		local newList, used = {}, {}
		for _, id in ipairs(order) do
			local it = byId[id]
			if it and not used[it] then
				table.insert(newList, it)
				used[it] = true
			end
		end
		for _, it in ipairs(tabObj.Items) do
			if not used[it] then
				table.insert(newList, it)
			end
		end
		table.clear(tabObj.Items)
		for _, it in ipairs(newList) do
			table.insert(tabObj.Items, it)
		end
		RecalculateCardLayout(tabObj, tabObj.SearchBox.Text, false)
	end

	-- forward declarations dos builders (atribuidos na secao de CARDS)
	local CreateCard
	local AddToggle, AddSlider, AddColorSwatches, AddKeybind, AddActionButton, AddInfoCard

	-- ordem de criacao padrao (usada pelo Reset Layout)
	local CreationOrder = {}

	local UserTabCount = 0
	local InternalTabs = {} -- tabObj interno por nome (usado pelos builders embutidos)

	local function CreateTab(name, iconName, isBuiltIn)
		if type(name) ~= "string" or name == "" then
			name = "tab"
		end
		local textW = math.ceil(MeasureText(name, 12, Enum.Font.MontserratBold))
		local btnWidth = textW + TAB_PAD * 2 + 13 + 6

		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = name .. "_Tab"
		tabBtn.Size = UDim2.new(0, btnWidth, 1, 0)
		tabBtn.BackgroundTransparency = 1
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.ZIndex = 4
		tabBtn.Parent = UI.TabContainer

		local tabIcon = CreateIcon(tabBtn, iconName or "sliders", 13, UDim2.new(0, TAB_PAD, 0.5, -6), Theme.TextMuted, 5)

		local tabLabel = Instance.new("TextLabel")
		tabLabel.Size = UDim2.new(0, textW + 4, 1, 0)
		tabLabel.Position = UDim2.new(0, TAB_PAD + 19, 0, 0)
		tabLabel.BackgroundTransparency = 1
		tabLabel.Font = Enum.Font.MontserratBold
		tabLabel.Text = name
		tabLabel.TextSize = 12
		tabLabel.TextColor3 = Theme.TextMuted
		tabLabel.TextXAlignment = Enum.TextXAlignment.Left
		tabLabel.ZIndex = 5
		tabLabel.Parent = tabBtn

		local page = Instance.new("Frame")
		page.Name = name .. "_Page"
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = OptionsPanel

		local toolbar = Instance.new("Frame")
		toolbar.Size = UDim2.new(1, -24, 0, 26)
		toolbar.Position = UDim2.new(0, 12, 0, 10)
		toolbar.BackgroundTransparency = 1
		toolbar.Parent = page

		local searchFrame = Instance.new("Frame")
		searchFrame.Size = UDim2.new(1, -86, 1, 0)
		searchFrame.BorderSizePixel = 0
		searchFrame.Parent = toolbar
		RegisterTrans(searchFrame, "BackgroundTransparency", 0)
		RegisterSurface(searchFrame, "Card", false)

		local sCorner = Instance.new("UICorner")
		sCorner.CornerRadius = UDim.new(0, 5)
		sCorner.Parent = searchFrame

		local sStroke = Instance.new("UIStroke")
		sStroke.Color = Theme.Border
		sStroke.Thickness = 1
		sStroke.Parent = searchFrame
		RegisterTrans(sStroke, "Transparency", 0)
		RegStroke(sStroke)

		CreateIcon(searchFrame, "search", 12, UDim2.new(0, 9, 0.5, -6), Theme.TextMuted, 3)

		local searchBox = Instance.new("TextBox")
		searchBox.Size = UDim2.new(1, -30, 1, 0)
		searchBox.Position = UDim2.new(0, 26, 0, 0)
		searchBox.BackgroundTransparency = 1
		searchBox.Font = Enum.Font.Montserrat
		searchBox.PlaceholderText = "Filter " .. name .. " options..."
		searchBox.PlaceholderColor3 = Theme.TextMuted
		searchBox.Text = ""
		searchBox.TextSize = 11
		searchBox.TextColor3 = Theme.TextPrimary
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ClearTextOnFocus = false
		searchBox.Parent = searchFrame

		local editBtn, editLabel, editIcon = CreateIconButton(
			toolbar, "Tab Edit", "sliders-horizontal",
			UDim2.new(0, 80, 1, 0), UDim2.new(1, -80, 0, 0), 10, 2
		)
		RegisterTrans(editBtn, "BackgroundTransparency", 0)
		RegisterSurface(editBtn, "Card", false)

		local eCorner = Instance.new("UICorner")
		eCorner.CornerRadius = UDim.new(0, 5)
		eCorner.Parent = editBtn

		local eStroke = Instance.new("UIStroke")
		eStroke.Color = Theme.Border
		eStroke.Thickness = 1
		eStroke.Parent = editBtn
		RegisterTrans(eStroke, "Transparency", 0)
		RegStroke(eStroke)

		local customizerBar = Instance.new("Frame")
		customizerBar.Size = UDim2.new(1, -24, 0, 26)
		customizerBar.Position = UDim2.new(0, 12, 0, 42)
		customizerBar.BorderSizePixel = 0
		customizerBar.Visible = false
		customizerBar.Parent = page
		RegisterTrans(customizerBar, "BackgroundTransparency", 0)
		RegisterSurface(customizerBar, "Card", false)

		local cBarCorner = Instance.new("UICorner")
		cBarCorner.CornerRadius = UDim.new(0, 5)
		cBarCorner.Parent = customizerBar

		local cBarStroke = Instance.new("UIStroke")
		cBarStroke.Color = Theme.Border
		cBarStroke.Thickness = 1
		cBarStroke.Parent = customizerBar
		RegisterTrans(cBarStroke, "Transparency", 0)
		RegStroke(cBarStroke)

		local tabColLabel = Instance.new("TextLabel")
		tabColLabel.Size = UDim2.new(0, 55, 1, 0)
		tabColLabel.Position = UDim2.new(0, 8, 0, 0)
		tabColLabel.BackgroundTransparency = 1
		tabColLabel.Font = Enum.Font.MontserratBold
		tabColLabel.Text = "Tab Color"
		tabColLabel.TextSize = 10
		tabColLabel.TextColor3 = Theme.TextSub
		tabColLabel.TextXAlignment = Enum.TextXAlignment.Left
		tabColLabel.Parent = customizerBar

		local contentColLabel = Instance.new("TextLabel")
		contentColLabel.Size = UDim2.new(0, 75, 1, 0)
		contentColLabel.Position = UDim2.new(0, 185, 0, 0)
		contentColLabel.BackgroundTransparency = 1
		contentColLabel.Font = Enum.Font.MontserratBold
		contentColLabel.Text = "Content Color"
		contentColLabel.TextSize = 10
		contentColLabel.TextColor3 = Theme.TextSub
		contentColLabel.TextXAlignment = Enum.TextXAlignment.Left
		contentColLabel.Parent = customizerBar

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, -24, 1, -52)
		scroll.Position = UDim2.new(0, 12, 0, 42)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2
		scroll.ScrollBarImageColor3 = Theme.BorderFocus
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = page

		local tabObj = {
			Name = name,
			Btn = tabBtn,
			Icon = tabIcon,
			Label = tabLabel,
			Page = page,
			Scroll = scroll,
			SearchBox = searchBox,
			EditBtn = editBtn,
			EditLabel = editLabel,
			EditIcon = editIcon,
			CustomizerBar = customizerBar,
			TabColor = Theme.Accent,
			ContentColor = Theme.Accent,
			LocalX = 0,
			LocalWidth = btnWidth,
			Items = {},
			AccentTargets = {},
			Switches = {},
			DefaultOrder = {}
		}

		UI.Tabs[name] = tabObj
		InternalTabs[name] = tabObj
		tabObj.IsBuiltIn = isBuiltIn == true
		local hasSavedOrder = type(Saved) == "table" and type(Saved.TabOrder) == "table"
		if isBuiltIn then
			table.insert(UI.TabOrder, name)
			UpdateTabPositions(false, nil)
		elseif hasSavedOrder then
			table.insert(UI.TabOrder, name)
			ApplySavedTabOrder()
		else
			local insertAt = #UI.TabOrder + 1
			for i, n in ipairs(UI.TabOrder) do
				if UI.Tabs[n].IsBuiltIn then
					insertAt = i
					break
				end
			end
			table.insert(UI.TabOrder, insertAt, name)
			UpdateTabPositions(false, nil)
		end
		table.insert(CreationOrder, name)

		local function ApplyTabContentAccent(col)
			tabObj.ContentColor = col
			if State.TabEditMode then
				editLabel.TextColor3 = col
				editIcon.ImageColor3 = col
			end
			for _, target in ipairs(tabObj.AccentTargets) do
				if target.Obj and target.Obj.Parent then
					target.Obj[target.Prop] = col
				end
			end
			for _, sw in ipairs(tabObj.Switches) do
				sw.Refresh(false)
			end
		end
		tabObj.ApplyContentAccent = ApplyTabContentAccent

		for i, swCol in ipairs(TabColorSwatches) do
			local tSw = Instance.new("TextButton")
			tSw.Size = UDim2.new(0, 13, 0, 13)
			tSw.Position = UDim2.new(0, 64 + (i - 1) * 17, 0.5, -6)
			tSw.BackgroundColor3 = swCol
			tSw.Text = ""
			tSw.AutoButtonColor = false
			tSw.Parent = customizerBar
			local tc = Instance.new("UICorner")
			tc.CornerRadius = UDim.new(1, 0)
			tc.Parent = tSw
			tSw.MouseButton1Click:Connect(function()
				tabObj.TabColor = swCol
				if UI.ActiveTab == name then
					tabLabel.TextColor3 = swCol
					tabIcon.ImageColor3 = swCol
					UI.ActiveTabLine.BackgroundColor3 = swCol
				end
				MarkDirty()
			end)

			local cSw = Instance.new("TextButton")
			cSw.Size = UDim2.new(0, 13, 0, 13)
			cSw.Position = UDim2.new(0, 262 + (i - 1) * 17, 0.5, -6)
			cSw.BackgroundColor3 = swCol
			cSw.Text = ""
			cSw.AutoButtonColor = false
			cSw.Parent = customizerBar
			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(1, 0)
			cc.Parent = cSw
			cSw.MouseButton1Click:Connect(function()
				ApplyTabContentAccent(swCol)
				MarkDirty()
			end)
		end

		editBtn.MouseButton1Click:Connect(function()
			SetTabEditMode(not State.TabEditMode)
		end)

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			RecalculateCardLayout(tabObj, searchBox.Text, true)
		end)

		local draggingTab = false
		local dragStartX = 0
		local btnStartX = 0
		local movedTab = false

		tabBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingTab = true
				movedTab = false
				dragStartX = input.Position.X
				btnStartX = tabBtn.Position.X.Offset
				tabBtn.ZIndex = 10
			end
		end)

		Connect(UserInputService.InputChanged, function(input)
			if draggingTab and input.UserInputType == Enum.UserInputType.MouseMovement then
				local dx = (input.Position.X - dragStartX) / MainScale.Scale
				if math.abs(dx) > 5 then
					movedTab = true
				end
				if movedTab then
					local newX = math.clamp(btnStartX + dx, 0, math.max(0, UI.TabContainer.AbsoluteSize.X / MainScale.Scale - tabBtn.Size.X.Offset))
					tabBtn.Position = UDim2.new(0, newX, 0, 0)
					if UI.ActiveTab == name then
						UI.ActiveTabLine.Position = UDim2.new(0, newX + TAB_PAD, 1, -2)
					end
					local myCenter = newX + tabBtn.Size.X.Offset * 0.5
					local myIdx = table.find(UI.TabOrder, name)
					for idx, otherName in ipairs(UI.TabOrder) do
						if otherName ~= name then
							local otherObj = UI.Tabs[otherName]
							local otherCenter = otherObj.LocalX + otherObj.LocalWidth * 0.5
							if (myIdx < idx and myCenter > otherCenter) or (myIdx > idx and myCenter < otherCenter) then
								UI.TabOrder[myIdx], UI.TabOrder[idx] = UI.TabOrder[idx], UI.TabOrder[myIdx]
								UpdateTabPositions(true, tabBtn)
								break
							end
						end
					end
				end
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and draggingTab then
				draggingTab = false
				tabBtn.ZIndex = 4
				if not movedTab then
					SwitchTab(name)
				else
					MarkDirty()
				end
				UpdateTabPositions(true, nil)
			end
		end)

		tabBtn.MouseEnter:Connect(function()
			if UI.ActiveTab ~= name then
				Tween(tabLabel, FastTween, {TextColor3 = Theme.TextSub})
				Tween(tabIcon, FastTween, {ImageColor3 = Theme.TextSub})
			end
		end)

		tabBtn.MouseLeave:Connect(function()
			if UI.ActiveTab ~= name then
				Tween(tabLabel, FastTween, {TextColor3 = Theme.TextMuted})
				Tween(tabIcon, FastTween, {ImageColor3 = Theme.TextMuted})
			end
		end)

		-- cores salvas de tab/conteudo
		if type(Saved) == "table" then
			local tc = type(Saved.TabColors) == "table" and TableToColor(Saved.TabColors[name])
			if tc then
				tabObj.TabColor = tc
			end
			local cc = type(Saved.ContentColors) == "table" and TableToColor(Saved.ContentColors[name])
			if cc then
				tabObj.ContentColor = cc
			end
		end
		ApplyTabContentAccent(tabObj.ContentColor)

		if not isBuiltIn then
			UserTabCount = UserTabCount + 1
			if UserTabCount == 1 then
				SwitchTab(name)
			end
		end

		-- API da tab
		local tab = {}
		tab.Name = name
		function tab:AddToggle(o)
			return AddToggle(tabObj, o)
		end
		function tab:AddSlider(o)
			return AddSlider(tabObj, o)
		end
		function tab:AddColorSwatches(o)
			return AddColorSwatches(tabObj, o)
		end
		function tab:AddKeybind(o)
			return AddKeybind(tabObj, o)
		end
		function tab:AddButton(o)
			return AddActionButton(tabObj, o)
		end
		function tab:AddInfoCard(o)
			return AddInfoCard(tabObj, o)
		end
		return tab
	end

	------------------------------------------------------------------
	-- CARDS / CONTROLES
	------------------------------------------------------------------
	CreateCard = function(tabObj, height, searchKey, iconName, id)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, height)
		card.BorderSizePixel = 0
		card.Active = true
		card.Parent = tabObj.Scroll
		RegisterTrans(card, "BackgroundTransparency", 0)
		local surf = RegisterSurface(card, "Card", true)

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 6)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Theme.Border
		cStroke.Thickness = 1
		cStroke.Parent = card
		RegisterTrans(cStroke, "Transparency", 0)
		RegStroke(cStroke)

		local featIcon = CreateIcon(card, iconName or "sliders", 14, UDim2.new(0, 14, 0, 16), Theme.TextSub, 3)
		featIcon.Visible = not State.TabEditMode

		local gripIcon = CreateIcon(card, "grip-vertical", 13, UDim2.new(0, 10, 0, 17), Theme.TextMuted, 3)
		gripIcon.Visible = State.TabEditMode

		local itemData = {
			Card = card,
			Height = height,
			SearchKey = searchKey or "",
			Id = id or searchKey or tostring(#tabObj.Items + 1),
			FeatureIcon = featIcon,
			GripIcon = gripIcon,
			Dragging = false
		}
		table.insert(tabObj.Items, itemData)
		table.insert(tabObj.DefaultOrder, itemData.Id)
		ApplySavedItemOrder(tabObj)

		local dragStartY = 0
		local cardStartY = 0

		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and State.TabEditMode then
				itemData.Dragging = true
				dragStartY = input.Position.Y
				cardStartY = card.Position.Y.Offset
				card.ZIndex = 12
			end
		end)

		Connect(UserInputService.InputChanged, function(input)
			if itemData.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local dy = (input.Position.Y - dragStartY) / MainScale.Scale
				local newY = math.max(0, cardStartY + dy)
				card.Position = UDim2.new(0, 3, 0, newY)
				local myCenter = newY + height * 0.5
				local myIdx = table.find(tabObj.Items, itemData)
				local curY = 3
				for idx, otherItem in ipairs(tabObj.Items) do
					if otherItem.Card.Visible then
						local otherCenter = curY + otherItem.Height * 0.5
						if otherItem ~= itemData then
							if (myIdx < idx and myCenter > otherCenter) or (myIdx > idx and myCenter < otherCenter) then
								tabObj.Items[myIdx], tabObj.Items[idx] = tabObj.Items[idx], tabObj.Items[myIdx]
								RecalculateCardLayout(tabObj, tabObj.SearchBox.Text, true)
								break
							end
						end
						curY = curY + otherItem.Height + 6
					end
				end
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and itemData.Dragging then
				itemData.Dragging = false
				card.ZIndex = 1
				RecalculateCardLayout(tabObj, tabObj.SearchBox.Text, true)
				MarkDirty()
			end
		end)

		card.MouseEnter:Connect(function()
			surf.Hover = true
			Tween(card, FastTween, {BackgroundColor3 = SurfaceTint(surf)})
			Tween(featIcon, FastTween, {ImageColor3 = Theme.TextPrimary})
		end)
		card.MouseLeave:Connect(function()
			surf.Hover = false
			Tween(card, FastTween, {BackgroundColor3 = SurfaceTint(surf)})
			Tween(featIcon, FastTween, {ImageColor3 = Theme.TextSub})
		end)

		return card, itemData
	end

	local function RegisterControl(id, entry)
		entry.Id = id
		Controls[id] = entry
		return entry
	end

	AddToggle = function(tabObj, o)
		o = o or {}
		local id = o.Id or o.Title
		assert(id, "AddToggle: 'Id' (or 'Title') is required")
		local title = o.Title or tostring(id)
		local subtitle = o.Subtitle or ""
		local iconName = o.Icon or "sliders"
		local callback = o.Callback

		local default = (o.Default == true)
		local saved = SavedSettings[id]
		if type(saved) == "boolean" then
			default = saved
		end

		local card = CreateCard(tabObj, 46, title .. " " .. subtitle, iconName, id)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -105, 0, 18)
		titleLbl.Position = UDim2.new(0, 36, 0, 7)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = title
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, -105, 0, 14)
		subLbl.Position = UDim2.new(0, 36, 0, 24)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = Enum.Font.Montserrat
		subLbl.Text = subtitle
		subLbl.TextSize = 10
		subLbl.TextColor3 = Theme.TextSub
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.TextTruncate = Enum.TextTruncate.AtEnd
		subLbl.Parent = card

		local switchBg = Instance.new("TextButton")
		switchBg.Size = UDim2.new(0, 36, 0, 18)
		switchBg.Position = UDim2.new(1, -50, 0.5, -9)
		switchBg.Text = ""
		switchBg.AutoButtonColor = false
		switchBg.Parent = card
		RegisterTrans(switchBg, "BackgroundTransparency", 0)

		local swCorner = Instance.new("UICorner")
		swCorner.CornerRadius = UDim.new(1, 0)
		swCorner.Parent = switchBg

		local swStroke = Instance.new("UIStroke")
		swStroke.Color = Theme.Border
		swStroke.Thickness = 1
		swStroke.Parent = switchBg
		RegisterTrans(swStroke, "Transparency", 0)
		RegStroke(swStroke)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 12, 0, 12)
		knob.BorderSizePixel = 0
		knob.Parent = switchBg

		local kCorner = Instance.new("UICorner")
		kCorner.CornerRadius = UDim.new(1, 0)
		kCorner.Parent = knob

		local stateVal = default

		local sw = {}
		function sw.Refresh(animate)
			local bgCol = stateVal and tabObj.ContentColor or Theme.Control
			local knobPos = stateVal and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
			local knobCol = stateVal and Theme.Background or Theme.TextSub
			if animate then
				Tween(switchBg, FastTween, {BackgroundColor3 = bgCol})
				Tween(knob, FastTween, {Position = knobPos, BackgroundColor3 = knobCol})
			else
				switchBg.BackgroundColor3 = bgCol
				knob.Position = knobPos
				knob.BackgroundColor3 = knobCol
			end
		end
		table.insert(tabObj.Switches, sw)
		table.insert(SwitchRegistry, sw)
		sw.Refresh(false)

		local function SetValue(v, animate, fire)
			stateVal = v and true or false
			sw.Refresh(animate)
			if fire and callback then
				callback(stateVal)
			end
		end

		switchBg.MouseButton1Click:Connect(function()
			if State.TabEditMode then
				return
			end
			SetValue(not stateVal, true, true)
			MarkDirty()
		end)

		return RegisterControl(id, {
			Default = (o.Default == true),
			Get = function()
				return stateVal
			end,
			Set = function(v)
				SetValue(v, true, true)
			end,
			SetQuiet = function(v)
				SetValue(v, true, false)
			end,
			Apply = function()
				if callback then
					callback(stateVal)
				end
			end,
			Serialize = function()
				return stateVal
			end,
			Deserialize = function(v)
				return v == true
			end
		})
	end

	AddSlider = function(tabObj, o)
		o = o or {}
		local id = o.Id or o.Title
		assert(id, "AddSlider: 'Id' (or 'Title') is required")
		local title = o.Title or tostring(id)
		local minVal = tonumber(o.Min) or 0
		local maxVal = tonumber(o.Max) or 100
		local suffix = o.Suffix or ""
		local iconName = o.Icon or "sliders"
		local callback = o.Callback

		local default = tonumber(o.Default)
		if default == nil then
			default = minVal
		end
		default = math.clamp(math.floor(default + 0.5), minVal, maxVal)
		local saved = SavedSettings[id]
		if type(saved) == "number" then
			default = math.clamp(math.floor(saved + 0.5), minVal, maxVal)
		end

		local card = CreateCard(tabObj, 54, title, iconName, id)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.65, 0, 0, 18)
		titleLbl.Position = UDim2.new(0, 36, 0, 7)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = title
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0.3, -14, 0, 18)
		valLbl.Position = UDim2.new(0.7, 0, 0, 7)
		valLbl.BackgroundTransparency = 1
		valLbl.Font = Enum.Font.Montserrat
		valLbl.TextSize = 11
		valLbl.TextColor3 = Theme.TextSub
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Parent = card

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -50, 0, 5)
		track.Position = UDim2.new(0, 36, 0, 35)
		track.BorderSizePixel = 0
		track.Parent = card
		RegisterTrans(track, "BackgroundTransparency", 0)
		RegisterSurface(track, "Control", false)

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = tabObj.ContentColor
		fill.BorderSizePixel = 0
		fill.Parent = track
		table.insert(tabObj.AccentTargets, {Obj = fill, Prop = "BackgroundColor3"})

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.new(0, 8, 0, 14)
		thumb.BackgroundColor3 = Theme.TextPrimary
		thumb.BorderSizePixel = 0
		thumb.Parent = track

		local thumbStroke = Instance.new("UIStroke")
		thumbStroke.Color = Theme.Background
		thumbStroke.Thickness = 1
		thumbStroke.Parent = thumb
		RegStroke(thumbStroke, "Background")

		local value = default

		local function Visual(val)
			local ratio = math.clamp((val - minVal) / math.max(0.0001, (maxVal - minVal)), 0, 1)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			thumb.Position = UDim2.new(ratio, -4, 0.5, -7)
			valLbl.Text = tostring(val) .. suffix
		end

		local function SetValue(val, fire)
			val = math.clamp(math.floor(val + 0.5), minVal, maxVal)
			value = val
			Visual(val)
			if fire and callback then
				callback(val)
			end
		end
		Visual(value)

		local draggingSlider = false
		local function updateFromInput(input)
			local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			SetValue(minVal + (maxVal - minVal) * pos, true)
			MarkDirty()
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not State.TabEditMode then
				draggingSlider = true
				updateFromInput(input)
			end
		end)
		thumb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not State.TabEditMode then
				draggingSlider = true
				updateFromInput(input)
			end
		end)
		Connect(UserInputService.InputChanged, function(input)
			if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateFromInput(input)
			end
		end)
		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingSlider = false
			end
		end)

		return RegisterControl(id, {
			Default = math.clamp(math.floor((tonumber(o.Default) or minVal) + 0.5), minVal, maxVal),
			Get = function()
				return value
			end,
			Set = function(v)
				SetValue(v, true)
			end,
			SetQuiet = function(v)
				SetValue(v, false)
			end,
			Apply = function()
				if callback then
					callback(value)
				end
			end,
			Serialize = function()
				return value
			end,
			Deserialize = function(v)
				return math.clamp(math.floor((tonumber(v) or minVal) + 0.5), minVal, maxVal)
			end
		})
	end

	AddColorSwatches = function(tabObj, o)
		o = o or {}
		local id = o.Id -- opcional: sem Id o valor nao e persistido
		local title = o.Title or "Color"
		local swatches = o.Options or {}
		assert(type(swatches) == "table" and #swatches > 0, "AddColorSwatches: 'Options' (array of Color3) is required")
		local iconName = o.Icon or "palette"
		local callback = o.Callback

		local current = o.Default
		if typeof(current) ~= "Color3" then
			current = swatches[1]
		end
		if id then
			local savedCol = TableToColor(SavedSettings[id])
			if savedCol then
				current = savedCol
			end
		end

		local card = CreateCard(tabObj, 48, title, iconName, id)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.45, 0, 1, 0)
		titleLbl.Position = UDim2.new(0, 36, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = title
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(0, #swatches * 22, 0, 20)
		holder.Position = UDim2.new(1, -(#swatches * 22 + 12), 0.5, -10)
		holder.BackgroundTransparency = 1
		holder.Parent = card

		local entries = {}

		local function Highlight(col)
			for _, e in ipairs(entries) do
				local sel = (e.Col == col)
				e.Stroke.Color = sel and Theme.TextPrimary or Theme.Border
				e.Stroke.Thickness = sel and 1.6 or 1
			end
		end

		for i, col in ipairs(swatches) do
			if typeof(col) == "Color3" then
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(0, 16, 0, 16)
				b.Position = UDim2.new(0, (i - 1) * 22, 0.5, -8)
				b.BackgroundColor3 = col
				b.Text = ""
				b.AutoButtonColor = false
				b.Parent = holder

				local bc = Instance.new("UICorner")
				bc.CornerRadius = UDim.new(1, 0)
				bc.Parent = b

				local bs = Instance.new("UIStroke")
				bs.Color = Theme.Border
				bs.Thickness = 1
				bs.Parent = b
				table.insert(entries, {Col = col, Stroke = bs})

				b.MouseButton1Click:Connect(function()
					if State.TabEditMode then
						return
					end
					current = col
					Highlight(col)
					if callback then
						callback(col)
					end
					MarkDirty()
				end)
			end
		end
		Highlight(current)

		if not id then
			-- swatch solto (sem id): devolve um handle simples, sem persistir
			local handle = {}
			handle.Id = nil
			function handle:Set(col)
				current = col
				Highlight(col)
				if callback then
					callback(col)
				end
			end
			function handle:Get()
				return current
			end
			function handle:SetQuiet(col)
				current = col
				Highlight(col)
			end
			function handle:Apply()
				if callback then
					callback(current)
				end
			end
			return handle
		end

		local defaultCode = typeof(o.Default) == "Color3" and o.Default or swatches[1]
		return RegisterControl(id, {
			Default = defaultCode,
			Get = function()
				return current
			end,
			Set = function(col)
				current = col
				Highlight(col)
				if callback then
					callback(col)
				end
			end,
			SetQuiet = function(col)
				current = col
				Highlight(col)
			end,
			Apply = function()
				if callback then
					callback(current)
				end
			end,
			Serialize = function()
				return ColorToTable(current)
			end,
			Deserialize = function(v)
				return TableToColor(v)
			end
		})
	end

	AddKeybind = function(tabObj, o)
		o = o or {}
		local id = o.Id or o.Title
		assert(id, "AddKeybind: 'Id' (or 'Title') is required")
		local title = o.Title or tostring(id)
		local iconName = o.Icon or "sliders"
		local callback = o.Callback

		local default = typeof(o.Default) == "EnumItem" and o.Default or Enum.KeyCode.P
		local saved = SavedSettings[id]
		if type(saved) == "string" then
			local ok, kc = pcall(function()
				return Enum.KeyCode[saved]
			end)
			if ok and kc and kc ~= Enum.KeyCode.Unknown then
				default = kc
			end
		end

		local card = CreateCard(tabObj, 44, title, iconName, id)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.6, 0, 1, 0)
		titleLbl.Position = UDim2.new(0, 36, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = title
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local bindBtn = Instance.new("TextButton")
		bindBtn.Size = UDim2.new(0, 82, 0, 24)
		bindBtn.Position = UDim2.new(1, -94, 0.5, -12)
		bindBtn.Font = Enum.Font.MontserratBold
		bindBtn.Text = "[" .. default.Name .. "]"
		bindBtn.TextSize = 11
		bindBtn.TextColor3 = Theme.TextPrimary
		bindBtn.AutoButtonColor = false
		bindBtn.Parent = card
		RegisterTrans(bindBtn, "BackgroundTransparency", 0)
		RegisterSurface(bindBtn, "Control", false)

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 5)
		bCorner.Parent = bindBtn

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = Theme.Border
		bStroke.Thickness = 1
		bStroke.Parent = bindBtn
		RegisterTrans(bStroke, "Transparency", 0)
		RegStroke(bStroke)

		local value = default

		local function SetKey(kc, fire)
			value = kc
			bindBtn.Text = "[" .. kc.Name .. "]"
			bindBtn.TextColor3 = Theme.TextPrimary
			if fire and callback then
				callback(kc)
			end
		end

		bindBtn.MouseButton1Click:Connect(function()
			if State.TabEditMode then
				return
			end
			UI.BindingKey = true
			bindBtn.Text = "[ ... ]"
			bindBtn.TextColor3 = tabObj.ContentColor
		end)

		Connect(UserInputService.InputBegan, function(input)
			if UI.BindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
				-- so o botao "armado" responde: desarma comparando o texto
				if not (bindBtn.Text == "[ ... ]") then
					return
				end
				UI.BindingKey = false
				UI.JustBound = true
				task.delay(0.25, function()
					UI.JustBound = false
				end)
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Unknown then
					SetKey(value, false)
				else
					SetKey(input.KeyCode, true)
					MarkDirty()
				end
			end
		end)

		return RegisterControl(id, {
			Default = typeof(o.Default) == "EnumItem" and o.Default or Enum.KeyCode.P,
			Get = function()
				return value
			end,
			Set = function(kc)
				SetKey(kc, true)
			end,
			SetQuiet = function(kc)
				SetKey(kc, false)
			end,
			Apply = function()
				if callback then
					callback(value)
				end
			end,
			Serialize = function()
				return value.Name
			end,
			Deserialize = function(v)
				local ok, kc = pcall(function()
					return Enum.KeyCode[v]
				end)
				if ok and kc and kc ~= Enum.KeyCode.Unknown then
					return kc
				end
				return nil
			end
		})
	end

	AddActionButton = function(tabObj, o)
		o = o or {}
		local id = o.Id or o.Title
		assert(id, "AddButton: 'Id' (or 'Title') is required")
		local title = o.Title or tostring(id)
		local btnText = o.ButtonText or "Run"
		local iconName = o.Icon or "sliders"
		local callback = o.Callback

		local card = CreateCard(tabObj, 44, title .. " " .. btnText, iconName, id)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.6, 0, 1, 0)
		titleLbl.Position = UDim2.new(0, 36, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = title
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local actBtn = Instance.new("TextButton")
		actBtn.Size = UDim2.new(0, 104, 0, 24)
		actBtn.Position = UDim2.new(1, -116, 0.5, -12)
		actBtn.Font = Enum.Font.MontserratBold
		actBtn.Text = btnText
		actBtn.TextSize = 11
		actBtn.TextColor3 = Theme.TextPrimary
		actBtn.AutoButtonColor = false
		actBtn.Parent = card
		RegisterTrans(actBtn, "BackgroundTransparency", 0)
		local actSurf = RegisterSurface(actBtn, "Control", false)

		local aCorner = Instance.new("UICorner")
		aCorner.CornerRadius = UDim.new(0, 5)
		aCorner.Parent = actBtn

		local aStroke = Instance.new("UIStroke")
		aStroke.Color = Theme.Border
		aStroke.Thickness = 1
		aStroke.Parent = actBtn
		RegisterTrans(aStroke, "Transparency", 0)
		RegStroke(aStroke)

		actBtn.MouseEnter:Connect(function()
			actSurf.Hover = true
			Tween(actBtn, FastTween, {BackgroundColor3 = SurfaceTint(actSurf)})
		end)
		actBtn.MouseLeave:Connect(function()
			actSurf.Hover = false
			Tween(actBtn, FastTween, {BackgroundColor3 = SurfaceTint(actSurf)})
		end)
		actBtn.MouseButton1Click:Connect(function()
			if State.TabEditMode then
				return
			end
			if callback then
				callback(actBtn)
			end
		end)

		return {
			Id = id,
			Button = actBtn
		}
	end

	AddInfoCard = function(tabObj, o)
		o = o or {}
		local id = o.Id or o.Title
		assert(id, "AddInfoCard: 'Id' (or 'Title') is required")
		local title = o.Title or tostring(id)
		local text = o.Text or ""
		local iconName = o.Icon or "sliders"

		local card = CreateCard(tabObj, 46, title .. " " .. text, iconName, id)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -50, 0, 18)
		titleLbl.Position = UDim2.new(0, 36, 0, 7)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = title
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, -50, 0, 14)
		subLbl.Position = UDim2.new(0, 36, 0, 24)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = Enum.Font.Montserrat
		subLbl.Text = text
		subLbl.TextSize = 10
		subLbl.TextColor3 = Theme.TextSub
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.TextTruncate = Enum.TextTruncate.AtEnd
		subLbl.Parent = card

		return {
			Id = id
		}
	end

	------------------------------------------------------------------
	-- APPLY THEME
	------------------------------------------------------------------
	local function ApplyTheme(themeName, applyAccent)
		local t = Themes[themeName]
		if not t then
			return
		end
		State.ThemeName = themeName
		SyncThemeTable(themeName)

		for _, s in ipairs(Surfaces) do
			RefreshSurface(s, true)
		end
		for _, st in ipairs(ThemedStrokes) do
			if st.Obj and st.Obj.Parent then
				Tween(st.Obj, FastTween, {Color = Theme[st.Key]})
			end
		end
		for _, div in ipairs(ThemedDividers) do
			if div and div.Parent then
				Tween(div, FastTween, {BackgroundColor3 = Theme.Border})
			end
		end
		if applyAccent and ApplyGlobalAccent then
			ApplyGlobalAccent(t.Accent)
		else
			for _, sw in ipairs(SwitchRegistry) do
				sw.Refresh(true)
			end
		end
		MarkDirty()
	end

	ApplyGlobalAccent = function(col)
		Theme.Accent = col
		for _, name in ipairs(UI.TabOrder) do
			local tObj = UI.Tabs[name]
			if tObj then
				tObj.TabColor = col
				tObj.ApplyContentAccent(col)
				if UI.ActiveTab == name then
					tObj.Label.TextColor3 = col
					tObj.Icon.ImageColor3 = col
					UI.ActiveTabLine.BackgroundColor3 = col
				end
			end
		end
		for _, sw in ipairs(SwitchRegistry) do
			sw.Refresh(true)
		end
		MarkDirty()
	end

	------------------------------------------------------------------
	-- THEME STUDIO (temas customizados, obrigatorio da library)
	------------------------------------------------------------------
	do
		local ThemeStudioOverlay = Instance.new("Frame")
		ThemeStudioOverlay.Name = "ThemeStudioOverlay"
		ThemeStudioOverlay.Size = UDim2.new(1, 0, 1, 0)
		ThemeStudioOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		ThemeStudioOverlay.BackgroundTransparency = 1
		ThemeStudioOverlay.Visible = false
		ThemeStudioOverlay.ZIndex = 28
		ThemeStudioOverlay.Active = true
		ThemeStudioOverlay.Parent = MainFrame

		local ThemeStudioBox = Instance.new("Frame")
		ThemeStudioBox.Size = UDim2.new(0, 390, 0, 290)
		ThemeStudioBox.Position = UDim2.new(0.5, -195, 0.5, -145)
		ThemeStudioBox.BorderSizePixel = 0
		ThemeStudioBox.ZIndex = 29
		ThemeStudioBox.Parent = ThemeStudioOverlay
		RegisterTrans(ThemeStudioBox, "BackgroundTransparency", 0)
		RegisterSurface(ThemeStudioBox, "Bg", false)

		local tsCorner = Instance.new("UICorner")
		tsCorner.CornerRadius = UDim.new(0, 8)
		tsCorner.Parent = ThemeStudioBox

		local tsStroke = Instance.new("UIStroke")
		tsStroke.Color = Theme.BorderFocus
		tsStroke.Thickness = 1
		tsStroke.Parent = ThemeStudioBox
		RegStroke(tsStroke, "BorderFocus")

		CreateIcon(ThemeStudioBox, "palette", 15, UDim2.new(0, 14, 0, 12), Theme.TextPrimary, 30)

		local tsTitle = Instance.new("TextLabel")
		tsTitle.Size = UDim2.new(1, -70, 0, 20)
		tsTitle.Position = UDim2.new(0, 34, 0, 10)
		tsTitle.BackgroundTransparency = 1
		tsTitle.Font = Enum.Font.MontserratBold
		tsTitle.Text = "Custom Theme Studio"
		tsTitle.TextSize = 13
		tsTitle.TextColor3 = Theme.TextPrimary
		tsTitle.TextXAlignment = Enum.TextXAlignment.Left
		tsTitle.ZIndex = 30
		tsTitle.Parent = ThemeStudioBox

		local tsCloseBtn = Instance.new("TextButton")
		tsCloseBtn.Size = UDim2.new(0, 24, 0, 24)
		tsCloseBtn.Position = UDim2.new(1, -34, 0, 8)
		tsCloseBtn.Text = ""
		tsCloseBtn.AutoButtonColor = false
		tsCloseBtn.ZIndex = 30
		tsCloseBtn.Parent = ThemeStudioBox
		RegisterSurface(tsCloseBtn, "Card", false)

		local tscCorner = Instance.new("UICorner")
		tscCorner.CornerRadius = UDim.new(0, 5)
		tscCorner.Parent = tsCloseBtn

		CreateIcon(tsCloseBtn, "x", 12, UDim2.new(0.5, -6, 0.5, -6), Theme.TextSub, 31)

		local tsDiv = Instance.new("Frame")
		tsDiv.Size = UDim2.new(1, 0, 0, 1)
		tsDiv.Position = UDim2.new(0, 0, 0, 38)
		tsDiv.BackgroundColor3 = Theme.Border
		tsDiv.BorderSizePixel = 0
		tsDiv.ZIndex = 30
		tsDiv.Parent = ThemeStudioBox
		RegDivider(tsDiv)

		local nameInputFrame = Instance.new("Frame")
		nameInputFrame.Size = UDim2.new(0, 210, 0, 26)
		nameInputFrame.Position = UDim2.new(0, 14, 0, 46)
		nameInputFrame.BorderSizePixel = 0
		nameInputFrame.ZIndex = 30
		nameInputFrame.Parent = ThemeStudioBox
		RegisterSurface(nameInputFrame, "Card", false)

		local nifCorner = Instance.new("UICorner")
		nifCorner.CornerRadius = UDim.new(0, 5)
		nifCorner.Parent = nameInputFrame

		local nifStroke = Instance.new("UIStroke")
		nifStroke.Color = Theme.Border
		nifStroke.Thickness = 1
		nifStroke.Parent = nameInputFrame
		RegStroke(nifStroke)

		local ThemeNameBox = Instance.new("TextBox")
		ThemeNameBox.Size = UDim2.new(1, -16, 1, 0)
		ThemeNameBox.Position = UDim2.new(0, 8, 0, 0)
		ThemeNameBox.BackgroundTransparency = 1
		ThemeNameBox.Font = Enum.Font.Montserrat
		ThemeNameBox.PlaceholderText = "Theme name..."
		ThemeNameBox.PlaceholderColor3 = Theme.TextMuted
		ThemeNameBox.Text = "Custom 1"
		ThemeNameBox.TextSize = 11
		ThemeNameBox.TextColor3 = Theme.TextPrimary
		ThemeNameBox.TextXAlignment = Enum.TextXAlignment.Left
		ThemeNameBox.ClearTextOnFocus = false
		ThemeNameBox.ZIndex = 31
		ThemeNameBox.Parent = nameInputFrame

		local LivePreviewStrip = Instance.new("Frame")
		LivePreviewStrip.Size = UDim2.new(0, 144, 0, 26)
		LivePreviewStrip.Position = UDim2.new(1, -158, 0, 46)
		LivePreviewStrip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		LivePreviewStrip.BorderSizePixel = 0
		LivePreviewStrip.ZIndex = 30
		LivePreviewStrip.Parent = ThemeStudioBox

		local lpsCorner = Instance.new("UICorner")
		lpsCorner.CornerRadius = UDim.new(0, 5)
		lpsCorner.Parent = LivePreviewStrip

		local lpsStroke = Instance.new("UIStroke")
		lpsStroke.Color = Theme.BorderFocus
		lpsStroke.Thickness = 1
		lpsStroke.Parent = LivePreviewStrip
		RegStroke(lpsStroke, "BorderFocus")

		local LivePreviewGrad = Instance.new("UIGradient")
		LivePreviewGrad.Rotation = 25
		LivePreviewGrad.Parent = LivePreviewStrip

		local lpsLabel = Instance.new("TextLabel")
		lpsLabel.Size = UDim2.new(1, 0, 1, 0)
		lpsLabel.BackgroundTransparency = 1
		lpsLabel.Font = Enum.Font.MontserratBold
		lpsLabel.Text = "GRADIENT PREVIEW"
		lpsLabel.TextSize = 9
		lpsLabel.TextColor3 = Theme.TextPrimary
		lpsLabel.ZIndex = 31
		lpsLabel.Parent = LivePreviewStrip

		local StopColors = {
			Color3.fromRGB(22, 16, 38),
			Color3.fromRGB(12, 10, 22),
			Color3.fromRGB(6, 6, 12)
		}
		local SelectedStopIndex = 1
		local EditingCustomIndex = nil
		local StopSlotButtons = {}
		local StopSlotSwatches = {}
		local StopSlotStrokes = {}

		for i = 1, 3 do
			local slotBtn = Instance.new("TextButton")
			slotBtn.Size = UDim2.new(0, 114, 0, 28)
			slotBtn.Position = UDim2.new(0, 14 + (i - 1) * 124, 0, 80)
			slotBtn.Text = ""
			slotBtn.AutoButtonColor = false
			slotBtn.ZIndex = 30
			slotBtn.Parent = ThemeStudioBox
			RegisterSurface(slotBtn, "Card", false)

			local sbCorner = Instance.new("UICorner")
			sbCorner.CornerRadius = UDim.new(0, 5)
			sbCorner.Parent = slotBtn

			local sbStroke = Instance.new("UIStroke")
			sbStroke.Color = (i == 1) and Theme.TextPrimary or Theme.Border
			sbStroke.Thickness = (i == 1) and 1.4 or 1
			sbStroke.Parent = slotBtn
			StopSlotStrokes[i] = sbStroke

			local sw = Instance.new("Frame")
			sw.Size = UDim2.new(0, 14, 0, 14)
			sw.Position = UDim2.new(0, 8, 0.5, -7)
			sw.BackgroundColor3 = StopColors[i]
			sw.BorderSizePixel = 0
			sw.ZIndex = 31
			sw.Parent = slotBtn
			StopSlotSwatches[i] = sw

			local swC = Instance.new("UICorner")
			swC.CornerRadius = UDim.new(1, 0)
			swC.Parent = sw

			local slbl = Instance.new("TextLabel")
			slbl.Size = UDim2.new(1, -30, 1, 0)
			slbl.Position = UDim2.new(0, 28, 0, 0)
			slbl.BackgroundTransparency = 1
			slbl.Font = Enum.Font.MontserratBold
			slbl.Text = "Color " .. tostring(i)
			slbl.TextSize = 11
			slbl.TextColor3 = Theme.TextPrimary
			slbl.TextXAlignment = Enum.TextXAlignment.Left
			slbl.ZIndex = 31
			slbl.Parent = slotBtn

			StopSlotButtons[i] = slotBtn
		end

		local SVBox = Instance.new("Frame")
		SVBox.Size = UDim2.new(0, 175, 0, 122)
		SVBox.Position = UDim2.new(0, 14, 0, 116)
		SVBox.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
		SVBox.BorderSizePixel = 0
		SVBox.ZIndex = 30
		SVBox.Parent = ThemeStudioBox

		local svCorner = Instance.new("UICorner")
		svCorner.CornerRadius = UDim.new(0, 5)
		svCorner.Parent = SVBox

		local svStroke = Instance.new("UIStroke")
		svStroke.Color = Theme.Border
		svStroke.Thickness = 1
		svStroke.Parent = SVBox
		RegStroke(svStroke)

		local SatOverlay = Instance.new("Frame")
		SatOverlay.Size = UDim2.new(1, 0, 1, 0)
		SatOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SatOverlay.BorderSizePixel = 0
		SatOverlay.ZIndex = 31
		SatOverlay.Parent = SVBox

		local satCorner = Instance.new("UICorner")
		satCorner.CornerRadius = UDim.new(0, 5)
		satCorner.Parent = SatOverlay

		local satGrad = Instance.new("UIGradient")
		satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
		satGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		satGrad.Parent = SatOverlay

		local ValOverlay = Instance.new("Frame")
		ValOverlay.Size = UDim2.new(1, 0, 1, 0)
		ValOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		ValOverlay.BorderSizePixel = 0
		ValOverlay.ZIndex = 32
		ValOverlay.Parent = SVBox

		local valCorner = Instance.new("UICorner")
		valCorner.CornerRadius = UDim.new(0, 5)
		valCorner.Parent = ValOverlay

		local valGrad = Instance.new("UIGradient")
		valGrad.Rotation = 90
		valGrad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
		valGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		valGrad.Parent = ValOverlay

		local SVCursor = Instance.new("Frame")
		SVCursor.Size = UDim2.new(0, 10, 0, 10)
		SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		SVCursor.Position = UDim2.new(0.5, 0, 0.5, 0)
		SVCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SVCursor.BorderSizePixel = 0
		SVCursor.ZIndex = 33
		SVCursor.Parent = SVBox

		local svcCorner = Instance.new("UICorner")
		svcCorner.CornerRadius = UDim.new(1, 0)
		svcCorner.Parent = SVCursor

		local svcStroke = Instance.new("UIStroke")
		svcStroke.Color = Color3.fromRGB(0, 0, 0)
		svcStroke.Thickness = 1.5
		svcStroke.Parent = SVCursor

		local HueBar = Instance.new("Frame")
		HueBar.Size = UDim2.new(0, 18, 0, 122)
		HueBar.Position = UDim2.new(0, 197, 0, 116)
		HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		HueBar.BorderSizePixel = 0
		HueBar.ZIndex = 30
		HueBar.Parent = ThemeStudioBox

		local hbCorner = Instance.new("UICorner")
		hbCorner.CornerRadius = UDim.new(0, 4)
		hbCorner.Parent = HueBar

		local hbStroke = Instance.new("UIStroke")
		hbStroke.Color = Theme.Border
		hbStroke.Thickness = 1
		hbStroke.Parent = HueBar
		RegStroke(hbStroke)

		local hueGrad = Instance.new("UIGradient")
		hueGrad.Rotation = 90
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
			ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
			ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
			ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
			ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
			ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
			ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1))
		})
		hueGrad.Parent = HueBar

		local HueCursor = Instance.new("Frame")
		HueCursor.Size = UDim2.new(1, 4, 0, 5)
		HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		HueCursor.Position = UDim2.new(0.5, 0, 0, 0)
		HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		HueCursor.BorderSizePixel = 0
		HueCursor.ZIndex = 32
		HueCursor.Parent = HueBar

		local hcStroke = Instance.new("UIStroke")
		hcStroke.Color = Color3.fromRGB(0, 0, 0)
		hcStroke.Thickness = 1
		hcStroke.Parent = HueCursor

		local QuickPresetTitle = Instance.new("TextLabel")
		QuickPresetTitle.Size = UDim2.new(0, 150, 0, 14)
		QuickPresetTitle.Position = UDim2.new(0, 225, 0, 116)
		QuickPresetTitle.BackgroundTransparency = 1
		QuickPresetTitle.Font = Enum.Font.MontserratBold
		QuickPresetTitle.Text = "PRESET SWATCHES"
		QuickPresetTitle.TextSize = 10
		QuickPresetTitle.TextColor3 = Theme.TextSub
		QuickPresetTitle.TextXAlignment = Enum.TextXAlignment.Left
		QuickPresetTitle.ZIndex = 30
		QuickPresetTitle.Parent = ThemeStudioBox

		local StudioPresetSwatches = {
			Color3.fromRGB(6, 6, 8),
			Color3.fromRGB(16, 18, 28),
			Color3.fromRGB(14, 34, 48),
			Color3.fromRGB(22, 48, 36),
			Color3.fromRGB(48, 16, 24),
			Color3.fromRGB(38, 18, 56),
			Color3.fromRGB(58, 38, 16),
			Color3.fromRGB(32, 32, 40),
			Color3.fromRGB(85, 155, 255),
			Color3.fromRGB(75, 225, 150),
			Color3.fromRGB(255, 85, 115),
			Color3.fromRGB(185, 110, 255),
			Color3.fromRGB(255, 180, 65),
			Color3.fromRGB(70, 215, 245),
			Color3.fromRGB(240, 110, 195),
			Color3.fromRGB(235, 235, 245)
		}

		local CurH, CurS, CurV = 0.7, 0.6, 0.16

		local function RefreshStudioPreview()
			StopSlotSwatches[1].BackgroundColor3 = StopColors[1]
			StopSlotSwatches[2].BackgroundColor3 = StopColors[2]
			StopSlotSwatches[3].BackgroundColor3 = StopColors[3]
			LivePreviewGrad.Color = Make3ColorSequence(StopColors[1], StopColors[2], StopColors[3])
		end

		local function LoadStopIntoPicker(idx)
			SelectedStopIndex = idx
			for i = 1, 3 do
				StopSlotStrokes[i].Color = (i == idx) and Theme.TextPrimary or Theme.Border
				StopSlotStrokes[i].Thickness = (i == idx) and 1.4 or 1
			end
			local h, s, v = StopColors[idx]:ToHSV()
			CurH, CurS, CurV = h, s, v
			SVBox.BackgroundColor3 = Color3.fromHSV(CurH, 1, 1)
			SVCursor.Position = UDim2.new(CurS, 0, 1 - CurV, 0)
			HueCursor.Position = UDim2.new(0.5, 0, CurH, 0)
			RefreshStudioPreview()
		end

		for i = 1, 3 do
			StopSlotButtons[i].MouseButton1Click:Connect(function()
				LoadStopIntoPicker(i)
			end)
		end

		for i, pCol in ipairs(StudioPresetSwatches) do
			local colIdx = (i - 1) % 4
			local rowIdx = math.floor((i - 1) / 4)
			local pBtn = Instance.new("TextButton")
			pBtn.Size = UDim2.new(0, 32, 0, 20)
			pBtn.Position = UDim2.new(0, 225 + colIdx * 38, 0, 134 + rowIdx * 26)
			pBtn.BackgroundColor3 = pCol
			pBtn.Text = ""
			pBtn.AutoButtonColor = false
			pBtn.ZIndex = 30
			pBtn.Parent = ThemeStudioBox

			local pc = Instance.new("UICorner")
			pc.CornerRadius = UDim.new(0, 4)
			pc.Parent = pBtn

			local ps = Instance.new("UIStroke")
			ps.Color = Theme.Border
			ps.Thickness = 1
			ps.Parent = pBtn
			RegStroke(ps)

			pBtn.MouseButton1Click:Connect(function()
				StopColors[SelectedStopIndex] = pCol
				LoadStopIntoPicker(SelectedStopIndex)
			end)
		end

		local draggingSV = false
		local draggingHue = false

		local function UpdateSVFromInput(input)
			local sx = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
			local sy = math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
			CurS = sx
			CurV = 1 - sy
			SVCursor.Position = UDim2.new(CurS, 0, 1 - CurV, 0)
			StopColors[SelectedStopIndex] = Color3.fromHSV(CurH, CurS, CurV)
			RefreshStudioPreview()
		end

		local function UpdateHueFromInput(input)
			local hy = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
			CurH = hy
			HueCursor.Position = UDim2.new(0.5, 0, CurH, 0)
			SVBox.BackgroundColor3 = Color3.fromHSV(CurH, 1, 1)
			StopColors[SelectedStopIndex] = Color3.fromHSV(CurH, CurS, CurV)
			RefreshStudioPreview()
		end

		SVBox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingSV = true
				UpdateSVFromInput(input)
			end
		end)

		HueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingHue = true
				UpdateHueFromInput(input)
			end
		end)

		Connect(UserInputService.InputChanged, function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				if draggingSV then
					UpdateSVFromInput(input)
				elseif draggingHue then
					UpdateHueFromInput(input)
				end
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingSV = false
				draggingHue = false
			end
		end)

		local StudioCancelBtn = Instance.new("TextButton")
		StudioCancelBtn.Size = UDim2.new(0, 110, 0, 28)
		StudioCancelBtn.Position = UDim2.new(1, -242, 1, -38)
		StudioCancelBtn.Font = Enum.Font.MontserratBold
		StudioCancelBtn.Text = "Cancel"
		StudioCancelBtn.TextSize = 11
		StudioCancelBtn.TextColor3 = Theme.TextSub
		StudioCancelBtn.AutoButtonColor = false
		StudioCancelBtn.ZIndex = 30
		StudioCancelBtn.Parent = ThemeStudioBox
		RegisterSurface(StudioCancelBtn, "Card", false)

		local scCorner = Instance.new("UICorner")
		scCorner.CornerRadius = UDim.new(0, 5)
		scCorner.Parent = StudioCancelBtn

		local scStroke = Instance.new("UIStroke")
		scStroke.Color = Theme.Border
		scStroke.Thickness = 1
		scStroke.Parent = StudioCancelBtn
		RegStroke(scStroke)

		local StudioSaveBtn = Instance.new("TextButton")
		StudioSaveBtn.Size = UDim2.new(0, 116, 0, 28)
		StudioSaveBtn.Position = UDim2.new(1, -124, 1, -38)
		StudioSaveBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
		StudioSaveBtn.Font = Enum.Font.MontserratBold
		StudioSaveBtn.Text = "Save & Apply"
		StudioSaveBtn.TextSize = 11
		StudioSaveBtn.TextColor3 = Color3.fromRGB(12, 12, 14)
		StudioSaveBtn.AutoButtonColor = false
		StudioSaveBtn.ZIndex = 30
		StudioSaveBtn.Parent = ThemeStudioBox

		local ssCorner = Instance.new("UICorner")
		ssCorner.CornerRadius = UDim.new(0, 5)
		ssCorner.Parent = StudioSaveBtn

		local function CloseThemeStudio()
			Tween(ThemeStudioOverlay, FastTween, {BackgroundTransparency = 1})
			task.delay(0.15, function()
				ThemeStudioOverlay.Visible = false
			end)
		end

		tsCloseBtn.MouseButton1Click:Connect(CloseThemeStudio)
		StudioCancelBtn.MouseButton1Click:Connect(CloseThemeStudio)

		local function OpenThemeStudio(editIndex)
			EditingCustomIndex = editIndex
			if editIndex and CustomThemes[editIndex] then
				local ct = CustomThemes[editIndex]
				ThemeNameBox.Text = ct.Name
				StopColors[1] = ct.C1
				StopColors[2] = ct.C2
				StopColors[3] = ct.C3
			else
				ThemeNameBox.Text = "Custom " .. tostring(#CustomThemes + 1)
				StopColors[1] = Color3.fromRGB(24, 18, 42)
				StopColors[2] = Color3.fromRGB(14, 11, 24)
				StopColors[3] = Color3.fromRGB(7, 6, 12)
			end
			LoadStopIntoPicker(1)
			ThemeStudioOverlay.Visible = true
			Tween(ThemeStudioOverlay, FastTween, {BackgroundTransparency = 0.45})
		end
		UI.OpenThemeStudio = OpenThemeStudio

		StudioSaveBtn.MouseButton1Click:Connect(function()
			local rawName = ThemeNameBox.Text:gsub("^%s*(.-)%s*$", "%1")
			rawName = string.sub(rawName, 1, 18)
			if rawName == "" then
				rawName = "Custom " .. tostring(EditingCustomIndex or (#CustomThemes + 1))
			end
			if Themes[rawName] and (not EditingCustomIndex or CustomThemes[EditingCustomIndex].Name ~= rawName) then
				rawName = rawName .. " #" .. tostring(EditingCustomIndex or (#CustomThemes + 1))
			end

			local accentCol = LerpColor(StopColors[1], Color3.new(1, 1, 1), 0.65)
			local newThemeData = BuildDerivedTheme(rawName, StopColors[1], StopColors[2], StopColors[3], accentCol)

			if EditingCustomIndex and CustomThemes[EditingCustomIndex] then
				local oldName = CustomThemes[EditingCustomIndex].Name
				Themes[oldName] = nil
				CustomThemes[EditingCustomIndex] = newThemeData
				Themes[rawName] = newThemeData
			else
				if #CustomThemes >= MAX_CUSTOM_THEMES then
					CloseThemeStudio()
					return
				end
				table.insert(CustomThemes, newThemeData)
				Themes[rawName] = newThemeData
			end

			if Controls.UseGradient then
				Controls.UseGradient.SetQuiet(true)
			else
				State.UseGradient = true
			end
			ApplyTheme(rawName, true)
			if UI.RebuildThemeButtons then
				UI.RebuildThemeButtons()
			end
			CloseThemeStudio()
			MarkDirty()
		end)
	end

	------------------------------------------------------------------
	-- SELETOR DE TEMAS (chips com preview vivo)
	------------------------------------------------------------------
	local function AddThemeSelector(tabObj)
		local card = CreateCard(tabObj, 112, "Theme Preset Gradient Custom Pitch Black Midnight Emerald Crimson Amethyst Oceanic", "palette", "ThemeSelector")

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(0.5, 0, 0, 18)
		titleLbl.Position = UDim2.new(0, 36, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = "Theme Presets & Studio"
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local NewThemeBtn, ntLabel, ntIcon = CreateIconButton(
			card, "New Theme (0/3)", "plus",
			UDim2.new(0, 128, 0, 20), UDim2.new(1, -138, 0, 6), 10, 3
		)
		RegisterTrans(NewThemeBtn, "BackgroundTransparency", 0)
		RegisterSurface(NewThemeBtn, "Control", false)
		ntLabel.TextColor3 = Theme.TextPrimary
		ntIcon.ImageColor3 = Theme.TextPrimary

		local ntbCorner = Instance.new("UICorner")
		ntbCorner.CornerRadius = UDim.new(0, 4)
		ntbCorner.Parent = NewThemeBtn

		local ntbStroke = Instance.new("UIStroke")
		ntbStroke.Color = Theme.BorderFocus
		ntbStroke.Thickness = 1
		ntbStroke.Parent = NewThemeBtn
		RegisterTrans(ntbStroke, "Transparency", 0)
		RegStroke(ntbStroke, "BorderFocus")

		NewThemeBtn.MouseButton1Click:Connect(function()
			if State.TabEditMode then
				return
			end
			if #CustomThemes < MAX_CUSTOM_THEMES then
				UI.OpenThemeStudio(nil)
			end
		end)

		local gridHolder = Instance.new("Frame")
		gridHolder.Size = UDim2.new(1, -46, 0, 76)
		gridHolder.Position = UDim2.new(0, 36, 0, 30)
		gridHolder.BackgroundTransparency = 1
		gridHolder.Parent = card

		local function MakeChip(themeObj, x, y, hasActions)
			local selected = (State.ThemeName == themeObj.Name)

			local chip = Instance.new("Frame")
			chip.Size = UDim2.new(0.32, 0, 0, 22)
			chip.Position = UDim2.new(x, 0, 0, y)
			chip.BackgroundColor3 = Color3.new(1, 1, 1)
			chip.BorderSizePixel = 0
			chip.Parent = gridHolder

			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(0, 5)
			cc.Parent = chip

			local cg = Instance.new("UIGradient")
			cg.Color = ThemePreviewSeq(themeObj)
			cg.Rotation = 20
			cg.Parent = chip

			local cs = Instance.new("UIStroke")
			cs.Color = selected and themeObj.Accent or themeObj.BorderFocus
			cs.Thickness = selected and 1.6 or 1
			cs.Parent = chip

			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 8, 0, 8)
			dot.Position = UDim2.new(0, 7, 0.5, -4)
			dot.BackgroundColor3 = themeObj.Accent
			dot.BorderSizePixel = 0
			dot.ZIndex = 2
			dot.Parent = chip
			local dc = Instance.new("UICorner")
			dc.CornerRadius = UDim.new(1, 0)
			dc.Parent = dot

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -(20 + (hasActions and 38 or 6)), 1, 0)
			lbl.Position = UDim2.new(0, 20, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.MontserratBold
			lbl.Text = themeObj.Name
			lbl.TextSize = 10
			lbl.TextColor3 = selected and Color3.new(1, 1, 1) or Color3.fromRGB(205, 205, 212)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextTruncate = Enum.TextTruncate.AtEnd
			lbl.ZIndex = 2
			lbl.Parent = chip

			local clickBtn = Instance.new("TextButton")
			clickBtn.Size = UDim2.new(1, hasActions and -38 or 0, 1, 0)
			clickBtn.BackgroundTransparency = 1
			clickBtn.Text = ""
			clickBtn.ZIndex = 3
			clickBtn.Parent = chip

			return chip, clickBtn
		end

		local function RenderThemeButtons()
			for _, child in ipairs(gridHolder:GetChildren()) do
				child:Destroy()
			end
			ntLabel.Text = string.format("New Theme (%d/%d)", #CustomThemes, MAX_CUSTOM_THEMES)
			local full = #CustomThemes >= MAX_CUSTOM_THEMES
			ntLabel.TextColor3 = full and Theme.TextMuted or Theme.TextPrimary
			ntIcon.ImageColor3 = full and Theme.TextMuted or Theme.TextPrimary

			for i, tName in ipairs(BuiltInThemeOrder) do
				local colIdx = (i - 1) % 3
				local rowIdx = math.floor((i - 1) / 3)
				local chip, clickBtn = MakeChip(Themes[tName], colIdx * 0.34, rowIdx * 26, false)
				clickBtn.MouseButton1Click:Connect(function()
					if State.TabEditMode then
						return
					end
					ApplyTheme(tName, true)
					RenderThemeButtons()
				end)
			end

			for cIdx, cTheme in ipairs(CustomThemes) do
				local colIdx = (cIdx - 1) % 3
				local chip, clickBtn = MakeChip(cTheme, colIdx * 0.34, 52, true)

				local editCustomBtn = Instance.new("TextButton")
				editCustomBtn.Size = UDim2.new(0, 16, 0, 16)
				editCustomBtn.Position = UDim2.new(1, -36, 0.5, -8)
				editCustomBtn.BackgroundTransparency = 1
				editCustomBtn.Text = ""
				editCustomBtn.ZIndex = 4
				editCustomBtn.Parent = chip
				CreateIcon(editCustomBtn, "edit", 11, UDim2.new(0.5, -5, 0.5, -5), Color3.fromRGB(235, 235, 240), 5)

				local delCustomBtn = Instance.new("TextButton")
				delCustomBtn.Size = UDim2.new(0, 16, 0, 16)
				delCustomBtn.Position = UDim2.new(1, -19, 0.5, -8)
				delCustomBtn.BackgroundTransparency = 1
				delCustomBtn.Text = ""
				delCustomBtn.ZIndex = 4
				delCustomBtn.Parent = chip
				CreateIcon(delCustomBtn, "trash", 11, UDim2.new(0.5, -5, 0.5, -5), Theme.Danger, 5)

				clickBtn.MouseButton1Click:Connect(function()
					if State.TabEditMode then
						return
					end
					ApplyTheme(cTheme.Name, true)
					RenderThemeButtons()
				end)

				editCustomBtn.MouseButton1Click:Connect(function()
					if State.TabEditMode then
						return
					end
					UI.OpenThemeStudio(cIdx)
				end)

				delCustomBtn.MouseButton1Click:Connect(function()
					if State.TabEditMode then
						return
					end
					local removedName = cTheme.Name
					table.remove(CustomThemes, cIdx)
					Themes[removedName] = nil
					if State.ThemeName == removedName then
						ApplyTheme("Pitch Black", true)
					end
					RenderThemeButtons()
					MarkDirty()
				end)
			end
		end

		UI.RebuildThemeButtons = RenderThemeButtons
		RenderThemeButtons()
	end

	------------------------------------------------------------------
	-- PRESETS DA WATERMARK
	------------------------------------------------------------------
	local function AddWatermarkPresets(tabObj)
		local card = CreateCard(tabObj, 88, "Watermark Presets only fps name full logo", "box", "WatermarkPresets")

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -50, 0, 18)
		titleLbl.Position = UDim2.new(0, 36, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.MontserratBold
		titleLbl.Text = "Watermark Presets"
		titleLbl.TextSize = 12
		titleLbl.TextColor3 = Theme.TextPrimary
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = card

		local presets = {
			{"Only potato", {WmShowLogo = true, WmShowName = true, WmShowFps = false, WmShowPing = false, WmShowUser = false, WmShowTime = false}},
			{"potato + FPS", {WmShowLogo = true, WmShowName = true, WmShowFps = true, WmShowPing = false, WmShowUser = false, WmShowTime = false}},
			{"potato + Name", {WmShowLogo = true, WmShowName = true, WmShowFps = false, WmShowPing = false, WmShowUser = true, WmShowTime = false}},
			{"FPS + Name", {WmShowLogo = true, WmShowName = true, WmShowFps = true, WmShowPing = false, WmShowUser = true, WmShowTime = false}},
			{"Everything", {WmShowLogo = true, WmShowName = true, WmShowFps = true, WmShowPing = true, WmShowUser = true, WmShowTime = true}},
			{"Logo only", {WmShowLogo = true, WmShowName = false, WmShowFps = false, WmShowPing = false, WmShowUser = false, WmShowTime = false}}
		}

		local grid = Instance.new("Frame")
		grid.Size = UDim2.new(1, -46, 0, 52)
		grid.Position = UDim2.new(0, 36, 0, 28)
		grid.BackgroundTransparency = 1
		grid.Parent = card

		for i, preset in ipairs(presets) do
			local colIdx = (i - 1) % 3
			local rowIdx = math.floor((i - 1) / 3)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0.32, 0, 0, 22)
			b.Position = UDim2.new(colIdx * 0.34, 0, 0, rowIdx * 28)
			b.Font = Enum.Font.MontserratBold
			b.Text = preset[1]
			b.TextSize = 10
			b.TextColor3 = Theme.TextPrimary
			b.AutoButtonColor = false
			b.Parent = grid
			RegisterTrans(b, "BackgroundTransparency", 0)
			local bs = RegisterSurface(b, "Control", false)

			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 4)
			bc.Parent = b

			local bStroke = Instance.new("UIStroke")
			bStroke.Color = Theme.Border
			bStroke.Thickness = 1
			bStroke.Parent = b
			RegStroke(bStroke)

			b.MouseEnter:Connect(function()
				bs.Hover = true
				Tween(b, FastTween, {BackgroundColor3 = SurfaceTint(bs)})
			end)
			b.MouseLeave:Connect(function()
				bs.Hover = false
				Tween(b, FastTween, {BackgroundColor3 = SurfaceTint(bs)})
			end)
			b.MouseButton1Click:Connect(function()
				if State.TabEditMode then
					return
				end
				for key, val in pairs(preset[2]) do
					if Controls[key] then
						Controls[key].SetQuiet(val)
					else
						State[key] = val
					end
				end
				UpdateWatermark(true)
				MarkDirty()
			end)
		end
	end

	------------------------------------------------------------------
	-- LAYOUT SALVO (ordem das tabs / cards, cores, posicao da watermark)
	------------------------------------------------------------------
	-- (ApplySavedTabOrder / ApplySavedItemOrder ja foram definidos na secao de tabs)

	local function ApplyItemOrder(tabObj, order)
		if type(order) ~= "table" then
			return
		end
		local byId = {}
		for _, it in ipairs(tabObj.Items) do
			byId[it.Id] = it
		end
		local newList, used = {}, {}
		for _, id in ipairs(order) do
			local it = byId[id]
			if it and not used[it] then
				table.insert(newList, it)
				used[it] = true
			end
		end
		for _, it in ipairs(tabObj.Items) do
			if not used[it] then
				table.insert(newList, it)
			end
		end
		table.clear(tabObj.Items)
		for _, it in ipairs(newList) do
			table.insert(tabObj.Items, it)
		end
		RecalculateCardLayout(tabObj, tabObj.SearchBox.Text, false)
	end

	local function ApplyTabOrder(order)
		local list, used = {}, {}
		if type(order) == "table" then
			for _, n in ipairs(order) do
				if UI.Tabs[n] and not used[n] then
					table.insert(list, n)
					used[n] = true
				end
			end
		end
		for _, n in ipairs(UI.TabOrder) do
			if not used[n] then
				table.insert(list, n)
			end
		end
		UI.TabOrder = list
		UpdateTabPositions(false, nil)
	end

	local function ApplyLayoutData(data)
		if type(data) ~= "table" then
			return
		end
		ApplyTabOrder(data.TabOrder)
		for name, tObj in pairs(UI.Tabs) do
			if type(data.TabColors) == "table" then
				local tc = TableToColor(data.TabColors[name])
				if tc then
					tObj.TabColor = tc
				end
			end
			if type(data.ContentColors) == "table" then
				local cc = TableToColor(data.ContentColors[name])
				if cc then
					tObj.ContentColor = cc
				end
			end
			if type(data.ItemOrder) == "table" then
				ApplyItemOrder(tObj, data.ItemOrder[name])
			end
			tObj.ApplyContentAccent(tObj.ContentColor)
		end
		if type(data.WatermarkPos) == "table" and #data.WatermarkPos == 4 then
			local p = data.WatermarkPos
			if type(p[1]) == "number" and type(p[2]) == "number" and type(p[3]) == "number" and type(p[4]) == "number" then
				UI.Watermark.Position = UDim2.new(p[1], p[2], p[3], p[4])
			end
		end
		SwitchTab(UI.ActiveTab or UI.TabOrder[1])
	end

	local function DefaultLayoutOrder()
		local order = {}
		for _, n in ipairs(CreationOrder) do
			if UI.Tabs[n] and not UI.Tabs[n].IsBuiltIn then
				table.insert(order, n)
			end
		end
		for _, n in ipairs(CreationOrder) do
			if UI.Tabs[n] and UI.Tabs[n].IsBuiltIn then
				table.insert(order, n)
			end
		end
		return order
	end

	local function ResetLayout()
		ApplyTabOrder(DefaultLayoutOrder())
		for _, name in ipairs(DefaultLayoutOrder()) do
			local tObj = UI.Tabs[name]
			if tObj then
				ApplyItemOrder(tObj, tObj.DefaultOrder)
				tObj.TabColor = Theme.Accent
				tObj.ApplyContentAccent(Theme.Accent)
			end
		end
		State.PreviewOnLeft = LIBRARY_DEFAULTS.PreviewOnLeft
		UI.Watermark.Position = UDim2.new(1, -18, 1, -42)
		ApplyPanelSideLayout(true)
		SwitchTab(UI.ActiveTab or UI.TabOrder[1])
		MarkDirty()
	end

	local function ResetSettings()
		for _, ctl in pairs(Controls) do
			if ctl.Default ~= nil and ctl.Set then
				pcall(function()
					ctl.Set(ctl.Default)
				end)
			end
		end
		ApplyTheme(LIBRARY_DEFAULTS.ThemeName, true)
		State.PreviewOnLeft = LIBRARY_DEFAULTS.PreviewOnLeft
		ApplyPanelSideLayout(true)
		if UI.RebuildThemeButtons then
			UI.RebuildThemeButtons()
		end
		UpdateWatermark(true)
		MarkDirty()
	end

	local function LoadConfigFromDisk()
		local data = ReadConfigFile()
		if not data then
			return false
		end
		LoadCustomThemes(data, true)
		local sset = (type(data.Settings) == "table" and data.Settings)
			or (type(data.State) == "table" and data.State)
			or {}

		-- aplica configs reservadas da library
		for key, default in pairs(LIBRARY_DEFAULTS) do
			local v = sset[key]
			if v ~= nil then
				if key == "ToggleKey" then
					local ok, kc = pcall(function()
						return Enum.KeyCode[v]
					end)
					if ok and kc and kc ~= Enum.KeyCode.Unknown then
						State[key] = kc
					end
				elseif key == "ThemeName" then
					if type(v) == "string" then
						State[key] = v
					end
				elseif type(v) == type(default) then
					if type(v) == "number" and LIBRARY_RANGES[key] then
						v = math.clamp(v, LIBRARY_RANGES[key][1], LIBRARY_RANGES[key][2])
					end
					State[key] = v
				end
			end
		end
		if not Themes[State.ThemeName] then
			State.ThemeName = "Pitch Black"
		end
		for id, ctl in pairs(Controls) do
			local v = sset[id]
			if v ~= nil and ctl.Deserialize then
				local okv, dv = pcall(ctl.Deserialize, v)
				if okv and dv ~= nil then
					pcall(function()
						ctl.Set(dv)
					end)
				end
			end
		end
		State.PreviewOnLeft = (type(sset.PreviewOnLeft) == "boolean") and sset.PreviewOnLeft or LIBRARY_DEFAULTS.PreviewOnLeft
		ApplyTheme(State.ThemeName, true)
		if UI.RebuildThemeButtons then
			UI.RebuildThemeButtons()
		end
		ApplyLayoutData(data)
		ApplyPanelSideLayout(true)
		UpdateWatermark(true)
		return true
	end

	------------------------------------------------------------------
	-- TABS EMPLADILHADAS (settings / configs) — obrigatorias da library
	------------------------------------------------------------------
	local function CreateBuiltInTabs()
		if opts.ShowSettingsTab ~= false then
			local SettingsTab = CreateTab("settings", "settings", true)

			AddThemeSelector(InternalTabs.settings)
			SettingsTab:AddToggle({
				Id = "UseGradient",
				Title = "Theme Gradient",
				Subtitle = "Smooth 3-stop gradient across UI and cards",
				Icon = "layers",
				Default = LIBRARY_DEFAULTS.UseGradient,
				Callback = function(v)
					State.UseGradient = v
					ApplyTheme(State.ThemeName, false)
				end
			})
			SettingsTab:AddSlider({
				Id = "GradientAngle",
				Title = "Gradient Angle",
				Min = 0,
				Max = 360,
				Suffix = "°",
				Icon = "compass",
				Default = LIBRARY_DEFAULTS.GradientAngle,
				Callback = function(v)
					State.GradientAngle = v
					for _, s in ipairs(Surfaces) do
						if s.Grad and s.Grad.Parent then
							s.Grad.Rotation = v
						end
					end
				end
			})
			SettingsTab:AddColorSwatches({
				-- sem Id: o accent global nao persiste (igual ao original)
				Id = nil,
				Title = "Global Accent Color",
				Options = {
					Color3.fromRGB(255, 255, 255),
					Color3.fromRGB(115, 175, 255),
					Color3.fromRGB(175, 125, 255),
					Color3.fromRGB(85, 230, 155),
					Color3.fromRGB(255, 185, 75),
					Color3.fromRGB(255, 95, 110)
				},
				Icon = "palette",
				Callback = function(col)
					ApplyGlobalAccent(col)
				end
			})
			SettingsTab:AddSlider({
				Id = "UIScale",
				Title = "UI Scale",
				Min = 70,
				Max = 130,
				Suffix = "%",
				Icon = "maximize-2",
				Default = LIBRARY_DEFAULTS.UIScale,
				Callback = function(v)
					State.UIScale = v
					Tween(MainScale, FastTween, {Scale = v / 100})
				end
			})
			SettingsTab:AddSlider({
				Id = "UITransparency",
				Title = "UI Transparency",
				Min = 0,
				Max = 75,
				Suffix = "%",
				Icon = "eye",
				Default = LIBRARY_DEFAULTS.UITransparency,
				Callback = function(v)
					State.UITransparency = v
					ApplyUITransparency(v / 100)
				end
			})

			SettingsTab:AddToggle({
				Id = "Watermark",
				Title = "Show Watermark",
				Subtitle = "Floating status bar (drag it anywhere)",
				Icon = "activity",
				Default = LIBRARY_DEFAULTS.Watermark,
				Callback = function(v)
					State.Watermark = v
					UpdateWatermark(true)
				end
			})
			AddWatermarkPresets(InternalTabs.settings)
			SettingsTab:AddToggle({
				Id = "WmShowLogo",
				Title = "Watermark: Logo",
				Subtitle = "Show the potato logo",
				Icon = "sparkles",
				Default = LIBRARY_DEFAULTS.WmShowLogo,
				Callback = function(v)
					State.WmShowLogo = v
					UpdateWatermark(true)
				end
			})
			SettingsTab:AddToggle({
				Id = "WmShowName",
				Title = "Watermark: Name",
				Subtitle = "Show the \"" .. tostring(AppName) .. "\" text",
				Icon = "box",
				Default = LIBRARY_DEFAULTS.WmShowName,
				Callback = function(v)
					State.WmShowName = v
					UpdateWatermark(true)
				end
			})
			SettingsTab:AddToggle({
				Id = "WmShowFps",
				Title = "Watermark: FPS",
				Subtitle = "Show your frames per second",
				Icon = "activity",
				Default = LIBRARY_DEFAULTS.WmShowFps,
				Callback = function(v)
					State.WmShowFps = v
					UpdateWatermark(true)
				end
			})
			SettingsTab:AddToggle({
				Id = "WmShowPing",
				Title = "Watermark: Ping",
				Subtitle = "Show your ping in milliseconds",
				Icon = "zap",
				Default = LIBRARY_DEFAULTS.WmShowPing,
				Callback = function(v)
					State.WmShowPing = v
					UpdateWatermark(true)
				end
			})
			SettingsTab:AddToggle({
				Id = "WmShowUser",
				Title = "Watermark: Username",
				Subtitle = "Show your Roblox username",
				Icon = "user",
				Default = LIBRARY_DEFAULTS.WmShowUser,
				Callback = function(v)
					State.WmShowUser = v
					UpdateWatermark(true)
				end
			})
			SettingsTab:AddToggle({
				Id = "WmShowTime",
				Title = "Watermark: Clock",
				Subtitle = "Show the current local time",
				Icon = "compass",
				Default = LIBRARY_DEFAULTS.WmShowTime,
				Callback = function(v)
					State.WmShowTime = v
					UpdateWatermark(true)
				end
			})

			SettingsTab:AddKeybind({
				Id = "ToggleKey",
				Title = "UI Toggle Keybind",
				Icon = "sliders",
				Default = LIBRARY_DEFAULTS.ToggleKey,
				Callback = function(kc)
					State.ToggleKey = kc
					UI.FooterLeft.Text = FooterText()
				end
			})
		end

		if opts.ShowConfigsTab ~= false then
			local ConfigsTab = CreateTab("configs", "folder", true)

			ConfigsTab:AddInfoCard({
				Id = "StorageInfo",
				Title = "Auto Save",
				Text = HasFS and ("Saved automatically to " .. ConfigFile) or "File access unavailable: settings will not persist",
				Icon = "folder"
			})
			ConfigsTab:AddInfoCard({
				Id = "LicenseInfo",
				Title = "potato ui — license",
				Text = "Free to use. Keep the credit: potato",
				Icon = "shield"
			})

			ConfigsTab:AddButton({
				Id = "SaveConfig",
				Title = "Save Config Now",
				ButtonText = "Save",
				Icon = "check",
				Callback = function(btn)
					local ok = SaveConfig and SaveConfig()
					btn.Text = ok and "Saved!" or "No file access"
					task.delay(1, function()
						if btn and btn.Parent then
							btn.Text = "Save"
						end
					end)
				end
			})

			ConfigsTab:AddButton({
				Id = "LoadConfig",
				Title = "Load Saved Config",
				ButtonText = "Load",
				Icon = "folder",
				Callback = function(btn)
					local ok = LoadConfigFromDisk()
					btn.Text = ok and "Loaded!" or "Nothing saved"
					task.delay(1, function()
						if btn and btn.Parent then
							btn.Text = "Load"
						end
					end)
				end
			})

			ConfigsTab:AddButton({
				Id = "ResetSettings",
				Title = "Reset All Settings",
				ButtonText = "Reset",
				Icon = "rotate-ccw",
				Callback = function(btn)
					ResetSettings()
					btn.Text = "Done!"
					task.delay(1, function()
						if btn and btn.Parent then
							btn.Text = "Reset"
						end
					end)
				end
			})

			ConfigsTab:AddButton({
				Id = "ResetLayout",
				Title = "Reset Layout (tabs, cards, side)",
				ButtonText = "Reset Layout",
				Icon = "move",
				Callback = function(btn)
					ResetLayout()
					btn.Text = "Done!"
					task.delay(1, function()
						if btn and btn.Parent then
							btn.Text = "Reset Layout"
						end
					end)
				end
			})
		end
	end

	------------------------------------------------------------------
	-- MODAL DE FECHAR (obrigatorio da library)
	------------------------------------------------------------------
	do
		local ModalOverlay = Instance.new("Frame")
		ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
		ModalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		ModalOverlay.BackgroundTransparency = 1
		ModalOverlay.Visible = false
		ModalOverlay.ZIndex = 20
		ModalOverlay.Active = true
		ModalOverlay.Parent = MainFrame
		UI.ModalOverlay = ModalOverlay

		local ModalBox = Instance.new("Frame")
		ModalBox.Size = UDim2.new(0, 290, 0, 134)
		ModalBox.Position = UDim2.new(0.5, -145, 0.5, -67)
		ModalBox.BorderSizePixel = 0
		ModalBox.ZIndex = 21
		ModalBox.Parent = ModalOverlay
		RegisterTrans(ModalBox, "BackgroundTransparency", 0)
		RegisterSurface(ModalBox, "Bg", true)
		UI.ModalBox = ModalBox

		local mCorner = Instance.new("UICorner")
		mCorner.CornerRadius = UDim.new(0, 8)
		mCorner.Parent = ModalBox

		local mStroke = Instance.new("UIStroke")
		mStroke.Color = Theme.BorderFocus
		mStroke.Thickness = 1
		mStroke.Parent = ModalBox
		RegisterTrans(mStroke, "Transparency", 0)
		RegStroke(mStroke, "BorderFocus")

		local ModalTitle = Instance.new("TextLabel")
		ModalTitle.Size = UDim2.new(1, -28, 0, 22)
		ModalTitle.Position = UDim2.new(0, 14, 0, 14)
		ModalTitle.BackgroundTransparency = 1
		ModalTitle.Font = Enum.Font.MontserratBold
		ModalTitle.Text = "Close " .. tostring(AppName) .. " UI?"
		ModalTitle.TextSize = 14
		ModalTitle.TextColor3 = Theme.TextPrimary
		ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
		ModalTitle.ZIndex = 22
		ModalTitle.Parent = ModalBox

		local ModalSub = Instance.new("TextLabel")
		ModalSub.Size = UDim2.new(1, -28, 0, 34)
		ModalSub.Position = UDim2.new(0, 14, 0, 38)
		ModalSub.BackgroundTransparency = 1
		ModalSub.Font = Enum.Font.Montserrat
		ModalSub.Text = "Are you sure you want to unload and close the interface? Your settings will be saved."
		ModalSub.TextSize = 11
		ModalSub.TextWrapped = true
		ModalSub.TextColor3 = Theme.TextSub
		ModalSub.TextXAlignment = Enum.TextXAlignment.Left
		ModalSub.TextYAlignment = Enum.TextYAlignment.Top
		ModalSub.ZIndex = 22
		ModalSub.Parent = ModalBox

		local CancelBtn = Instance.new("TextButton")
		CancelBtn.Size = UDim2.new(0, 124, 0, 30)
		CancelBtn.Position = UDim2.new(0, 14, 1, -42)
		CancelBtn.Font = Enum.Font.MontserratBold
		CancelBtn.Text = "Cancel"
		CancelBtn.TextSize = 11
		CancelBtn.TextColor3 = Theme.TextPrimary
		CancelBtn.AutoButtonColor = false
		CancelBtn.ZIndex = 22
		CancelBtn.Parent = ModalBox
		RegisterTrans(CancelBtn, "BackgroundTransparency", 0)
		RegisterSurface(CancelBtn, "Card", false)

		local canCorner = Instance.new("UICorner")
		canCorner.CornerRadius = UDim.new(0, 5)
		canCorner.Parent = CancelBtn

		local canStroke = Instance.new("UIStroke")
		canStroke.Color = Theme.Border
		canStroke.Thickness = 1
		canStroke.Parent = CancelBtn
		RegisterTrans(canStroke, "Transparency", 0)
		RegStroke(canStroke)

		local ConfirmBtn = Instance.new("TextButton")
		ConfirmBtn.Size = UDim2.new(0, 124, 0, 30)
		ConfirmBtn.Position = UDim2.new(1, -138, 1, -42)
		ConfirmBtn.BackgroundColor3 = Theme.Danger
		ConfirmBtn.Font = Enum.Font.MontserratBold
		ConfirmBtn.Text = "Close UI"
		ConfirmBtn.TextSize = 11
		ConfirmBtn.TextColor3 = Theme.TextPrimary
		ConfirmBtn.AutoButtonColor = false
		ConfirmBtn.ZIndex = 22
		ConfirmBtn.Parent = ModalBox

		local confCorner = Instance.new("UICorner")
		confCorner.CornerRadius = UDim.new(0, 5)
		confCorner.Parent = ConfirmBtn

		UI.CancelBtn = CancelBtn
		UI.ConfirmBtn = ConfirmBtn
	end

	------------------------------------------------------------------
	-- CHANGELOG (abre so quando a versao salva e diferente da atual)
	------------------------------------------------------------------
	do
		local ChangelogFrame = Instance.new("Frame")
		ChangelogFrame.Name = "ChangelogFrame"
		ChangelogFrame.Size = UDim2.new(0, 420, 0, 290)
		ChangelogFrame.Position = UDim2.new(0.5, -210, 0.5, -145)
		ChangelogFrame.BorderSizePixel = 0
		ChangelogFrame.Visible = false
		ChangelogFrame.ClipsDescendants = true
		ChangelogFrame.ZIndex = 25
		ChangelogFrame.Parent = ScreenGui
		RegisterTrans(ChangelogFrame, "BackgroundTransparency", 0)
		RegisterSurface(ChangelogFrame, "Bg", true)
		UI.ChangelogFrame = ChangelogFrame

		local clScale = Instance.new("UIScale")
		clScale.Scale = 0.9
		clScale.Parent = ChangelogFrame
		UI.ChangelogScale = clScale

		local clCorner = Instance.new("UICorner")
		clCorner.CornerRadius = UDim.new(0, 8)
		clCorner.Parent = ChangelogFrame

		local clStroke = Instance.new("UIStroke")
		clStroke.Color = Theme.Border
		clStroke.Thickness = 1
		clStroke.Parent = ChangelogFrame
		RegisterTrans(clStroke, "Transparency", 0)
		RegStroke(clStroke)

		local clHeader = Instance.new("Frame")
		clHeader.Size = UDim2.new(1, 0, 0, 42)
		clHeader.BackgroundTransparency = 1
		clHeader.Parent = ChangelogFrame

		CreateIcon(clHeader, "sparkles", 15, UDim2.new(0, 14, 0.5, -7), Theme.TextPrimary, 26)

		local clTitle = Instance.new("TextLabel")
		clTitle.Size = UDim2.new(1, -80, 1, 0)
		clTitle.Position = UDim2.new(0, 36, 0, 0)
		clTitle.BackgroundTransparency = 1
		clTitle.Font = Enum.Font.MontserratBold
		clTitle.Text = tostring(AppName) .. " " .. AppVersion .. "  —  what's new"
		clTitle.TextSize = 13
		clTitle.TextColor3 = Theme.TextPrimary
		clTitle.TextXAlignment = Enum.TextXAlignment.Left
		clTitle.ZIndex = 26
		clTitle.Parent = clHeader

		local clCloseBtn = Instance.new("TextButton")
		clCloseBtn.Size = UDim2.new(0, 26, 0, 26)
		clCloseBtn.Position = UDim2.new(1, -36, 0.5, -13)
		clCloseBtn.Text = ""
		clCloseBtn.AutoButtonColor = false
		clCloseBtn.ZIndex = 26
		clCloseBtn.Parent = clHeader
		RegisterTrans(clCloseBtn, "BackgroundTransparency", 0)
		RegisterSurface(clCloseBtn, "Card", false)

		local clcCorner = Instance.new("UICorner")
		clcCorner.CornerRadius = UDim.new(0, 5)
		clcCorner.Parent = clCloseBtn

		local clcStroke = Instance.new("UIStroke")
		clcStroke.Color = Theme.Border
		clcStroke.Thickness = 1
		clcStroke.Parent = clCloseBtn
		RegisterTrans(clcStroke, "Transparency", 0)
		RegStroke(clcStroke)

		CreateIcon(clCloseBtn, "x", 12, UDim2.new(0.5, -6, 0.5, -6), Theme.TextSub, 27)

		local clDiv = Instance.new("Frame")
		clDiv.Size = UDim2.new(1, 0, 0, 1)
		clDiv.Position = UDim2.new(0, 0, 0, 42)
		clDiv.BackgroundColor3 = Theme.Border
		clDiv.BorderSizePixel = 0
		clDiv.Parent = ChangelogFrame
		RegisterTrans(clDiv, "BackgroundTransparency", 0)
		RegDivider(clDiv)

		local clScroll = Instance.new("ScrollingFrame")
		clScroll.Size = UDim2.new(1, -28, 1, -56)
		clScroll.Position = UDim2.new(0, 14, 0, 48)
		clScroll.BackgroundTransparency = 1
		clScroll.BorderSizePixel = 0
		clScroll.ScrollBarThickness = 2
		clScroll.ScrollBarImageColor3 = Theme.BorderFocus
		clScroll.CanvasSize = UDim2.new(0, 0, 0, 260)
		clScroll.Parent = ChangelogFrame

		local changelogEntries = opts.Changelog or DEFAULT_CHANGELOG

		local cy = 3
		for _, entry in ipairs(changelogEntries) do
			local headerText = tostring(entry[1] or "")
			local descText = tostring(entry[2] or "")
			local descH = 28
			local ok, sz = pcall(function()
				return TextService:GetTextSize(descText, 10, Enum.Font.Montserrat, Vector2.new(342, 1000))
			end)
			if ok and sz then
				descH = math.ceil(sz.Y)
			end
			local boxH = 28 + descH + 8

			local box = Instance.new("Frame")
			box.Size = UDim2.new(1, -10, 0, boxH)
			box.Position = UDim2.new(0, 3, 0, cy)
			box.BorderSizePixel = 0
			box.Parent = clScroll
			RegisterTrans(box, "BackgroundTransparency", 0)
			RegisterSurface(box, "Card", true)

			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 6)
			bc.Parent = box

			local bs = Instance.new("UIStroke")
			bs.Color = Theme.Border
			bs.Thickness = 1
			bs.Parent = box
			RegisterTrans(bs, "Transparency", 0)
			RegStroke(bs)

			local h = Instance.new("TextLabel")
			h.Size = UDim2.new(1, -20, 0, 18)
			h.Position = UDim2.new(0, 10, 0, 6)
			h.BackgroundTransparency = 1
			h.Font = Enum.Font.MontserratBold
			h.Text = headerText
			h.TextSize = 11
			h.TextColor3 = Theme.TextPrimary
			h.TextXAlignment = Enum.TextXAlignment.Left
			h.Parent = box

			local d = Instance.new("TextLabel")
			d.Size = UDim2.new(1, -20, 0, descH)
			d.Position = UDim2.new(0, 10, 0, 25)
			d.BackgroundTransparency = 1
			d.Font = Enum.Font.Montserrat
			d.Text = descText
			d.TextSize = 10
			d.TextWrapped = true
			d.TextColor3 = Theme.TextSub
			d.TextXAlignment = Enum.TextXAlignment.Left
			d.TextYAlignment = Enum.TextYAlignment.Top
			d.Parent = box

			cy = cy + boxH + 6
		end
		clScroll.CanvasSize = UDim2.new(0, 0, 0, cy + 6)

		function UI.ShowChangelog()
			UI.ChangelogOpen = true
			MainFrame.Visible = false
			ChangelogFrame.Visible = true
			clScale.Scale = 0.88 * (State.UIScale / 100)
			Tween(clScale, PopInTween, {Scale = State.UIScale / 100})
		end

		function UI.HideChangelog()
			UI.ChangelogOpen = false
			Tween(clScale, FastTween, {Scale = 0.88 * (State.UIScale / 100)})
			task.delay(0.15, function()
				if UI.ChangelogOpen then
					return
				end
				ChangelogFrame.Visible = false
				if not UI.IsHidden then
					MainFrame.Visible = true
					MainScale.Scale = 0.92 * (State.UIScale / 100)
					Tween(MainScale, PopInTween, {Scale = State.UIScale / 100})
				end
			end)
		end

		UI.VersionBtn.MouseButton1Click:Connect(function()
			UI.ShowChangelog()
		end)

		clCloseBtn.MouseButton1Click:Connect(function()
			UI.HideChangelog()
		end)
	end

	------------------------------------------------------------------
	-- UNLOAD
	------------------------------------------------------------------
	local Unloaded = false
	local windowRef = nil -- preenchido no final (referencia do Window)

	local function Unload()
		if Unloaded then
			return
		end
		Unloaded = true
		pcall(function()
			if SaveConfig then
				SaveConfig()
			end
		end)
		UI.Ready = false

		local onUnload = (type(opts.OnUnload) == "function" and opts.OnUnload)
			or (windowRef and type(windowRef.OnUnload) == "function" and windowRef.OnUnload)
		if onUnload then
			pcall(onUnload)
		end

		for _, c in ipairs(Connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(Connections)

		ScreenGui:Destroy()

		if Env and Env.__PotatoUnload == Unload then
			Env.__PotatoUnload = nil
		end
	end

	------------------------------------------------------------------
	-- MINIMIZAR / FECHAR / ARRASTAR / TOGGLE (obrigatorio)
	------------------------------------------------------------------
	local function SetMinimized(minimized)
		UI.IsMinimized = minimized
		if minimized then
			UI.TabContainer.Visible = false
			BodyFrame.Visible = false
			UI.FooterBar.Visible = false
			UI.TopDivider.Visible = false
			ApplyLucideIcon(UI.MinIcon, "maximize-2")
			Tween(MainFrame, SmoothTween, {
				Size = UDim2.new(0, MinimizedWidth, 0, MinimizedHeight)
			})
		else
			ApplyLucideIcon(UI.MinIcon, "minus")
			Tween(MainFrame, SmoothTween, {
				Size = UDim2.new(0, ExpandedWidth, 0, ExpandedHeight)
			})
			task.delay(0.14, function()
				if not UI.IsMinimized then
					UI.TabContainer.Visible = true
					BodyFrame.Visible = true
					UI.FooterBar.Visible = true
					UI.TopDivider.Visible = true
				end
			end)
		end
	end
	UI.SetMinimized = SetMinimized

	do
		UI.MinBtn.MouseButton1Click:Connect(function()
			SetMinimized(not UI.IsMinimized)
		end)

		UI.CloseBtn.MouseButton1Click:Connect(function()
			if UI.IsMinimized then
				SetMinimized(false)
				task.wait(0.2)
			end
			UI.ModalOverlay.Visible = true
			Tween(UI.ModalOverlay, FastTween, {BackgroundTransparency = 0.45})
		end)

		UI.CancelBtn.MouseButton1Click:Connect(function()
			Tween(UI.ModalOverlay, FastTween, {BackgroundTransparency = 1})
			task.delay(0.16, function()
				UI.ModalOverlay.Visible = false
			end)
		end)

		UI.ConfirmBtn.MouseButton1Click:Connect(function()
			Unload()
		end)
	end

	do
		local DraggingWindow = false
		local DragWindowStart = Vector2.zero
		local WindowStartPos = UDim2.new()

		UI.TopBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				DraggingWindow = true
				DragWindowStart = Vector2.new(input.Position.X, input.Position.Y)
				WindowStartPos = MainFrame.Position
			end
		end)

		Connect(UserInputService.InputChanged, function(input)
			if DraggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - DragWindowStart
				MainFrame.Position = UDim2.new(
					WindowStartPos.X.Scale,
					WindowStartPos.X.Offset + delta.X,
					WindowStartPos.Y.Scale,
					WindowStartPos.Y.Offset + delta.Y
				)
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				DraggingWindow = false
			end
		end)

		Connect(UserInputService.InputBegan, function(input, gp)
			if gp or UI.BindingKey or UI.JustBound then
				return
			end
			if input.KeyCode == State.ToggleKey then
				UI.IsHidden = not UI.IsHidden
				local target = UI.ChangelogOpen and UI.ChangelogFrame or MainFrame
				local scaleObj = UI.ChangelogOpen and UI.ChangelogScale or MainScale
				if UI.IsHidden then
					Tween(scaleObj, FastTween, {Scale = 0.88 * (State.UIScale / 100)})
					task.delay(0.15, function()
						if UI.IsHidden then
							target.Visible = false
						end
					end)
				else
					target.Visible = true
					scaleObj.Scale = 0.88 * (State.UIScale / 100)
					Tween(scaleObj, PopInTween, {Scale = State.UIScale / 100})
				end
			end
		end)
	end

	------------------------------------------------------------------
	-- LOOP PRINCIPAL (apenas contadores da watermark; ESP fica com voce)
	------------------------------------------------------------------
	do
		local FpsCounter = 0
		local LastFpsTime = tick()

		Connect(RunService.RenderStepped, function()
			if not ScreenGui.Parent then
				return
			end

			FpsCounter = FpsCounter + 1
			local now = tick()
			if now - LastFpsTime >= 1 then
				WmFps = FpsCounter
				FpsCounter = 0
				LastFpsTime = now
				if State.WmShowPing then
					pcall(function()
						WmPing = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
					end)
				end
				UpdateWatermark(false)
			end
		end)
	end

	------------------------------------------------------------------
	-- SAVE / BUILD CONFIG
	------------------------------------------------------------------
	BuildConfigData = function()
		local data = {
			Version = AppVersion,
			Settings = {},
			CustomThemes = {},
			TabOrder = {},
			TabColors = {},
			ContentColors = {},
			ItemOrder = {}
		}
		for key in pairs(LIBRARY_DEFAULTS) do
			local v = State[key]
			if key == "ToggleKey" then
				data.Settings[key] = v.Name
			else
				data.Settings[key] = v
			end
		end
		data.Settings.PreviewOnLeft = State.PreviewOnLeft
		for id, ctl in pairs(Controls) do
			if ctl.Serialize then
				data.Settings[id] = ctl.Serialize()
			end
		end
		for _, ct in ipairs(CustomThemes) do
			table.insert(data.CustomThemes, {
				Name = ct.Name,
				C1 = ColorToTable(ct.C1),
				C2 = ColorToTable(ct.C2),
				C3 = ColorToTable(ct.C3),
				Accent = ColorToTable(ct.Accent)
			})
		end
		for _, name in ipairs(UI.TabOrder) do
			table.insert(data.TabOrder, name)
			local tObj = UI.Tabs[name]
			if tObj then
				data.TabColors[name] = ColorToTable(tObj.TabColor)
				data.ContentColors[name] = ColorToTable(tObj.ContentColor)
				local ids = {}
				for _, it in ipairs(tObj.Items) do
					table.insert(ids, it.Id)
				end
				data.ItemOrder[name] = ids
			end
		end
		local wm = UI.Watermark
		if wm then
			data.WatermarkPos = {wm.Position.X.Scale, wm.Position.X.Offset, wm.Position.Y.Scale, wm.Position.Y.Offset}
		end
		return data
	end

	SaveConfig = function()
		return WriteConfigFile(BuildConfigData())
	end

	-- cria settings/configs embutidas (se BuildConfigData for chamada depois, tudo fecha)
	CreateBuiltInTabs()

	-- aba inicial: a primeira na ordem (ajustada de novo pelo defer abaixo)
	if UI.TabOrder[1] then
		SwitchTab(UI.TabOrder[1])
	end

	ApplyPanelSideLayout(false)
	UpdateWatermark(false)

	-- carrega o config salvo DEPOIS que o script do usuario roda (as tabs dele
	-- ainda nao existem dentro do CreateWindow): tema, escala, cores de tab,
	-- ordem de tabs/cards, keybind, watermark e lado do preview ficam
	-- restaurados entre execucoes
	task.defer(function()
		if not UI.Ready then
			return -- unload aconteceu antes do defer rodar
		end
		LoadConfigFromDisk()
		if UI.TabOrder[1] then
			SwitchTab(UI.TabOrder[1])
		end
	end)

	UI.Ready = true

	-- grava so a versao (merge): nao sobrescreve o layout salvo do usuario
	do
		local okBase, base = pcall(ReadConfigFile)
		if okBase and HasFS then
			base = base or {}
			base.Version = AppVersion
			pcall(WriteConfigFile, base)
		end
	end

	if ShowChangelogOnStart then
		MainScale.Scale = State.UIScale / 100
		UI.ShowChangelog()
	else
		MainScale.Scale = 0.88 * (State.UIScale / 100)
		Tween(MainScale, PopInTween, {Scale = State.UIScale / 100})
	end

	------------------------------------------------------------------
	-- WINDOW API
	------------------------------------------------------------------
	local Window = {}
	Window.Name = AppName
	Window.Version = AppVersion
	Window.OnUnload = nil

	function Window:CreateTab(name, icon)
		return CreateTab(name, icon, false)
	end

	function Window:CreateSidePanel(tabName, title)
		return CreateSidePanel(tabName, title)
	end

	function Window:ApplyTheme(themeName, applyAccent)
		ApplyTheme(themeName, applyAccent ~= false)
	end

	function Window:SetAccent(color)
		if typeof(color) == "Color3" then
			ApplyGlobalAccent(color)
		end
	end

	function Window:Save()
		return SaveConfig()
	end

	function Window:Load()
		return LoadConfigFromDisk()
	end

	function Window:ResetSettings()
		ResetSettings()
	end

	function Window:ResetLayout()
		ResetLayout()
	end

	function Window:Minimize(minimized)
		SetMinimized(minimized and true or false)
	end

	function Window:Toggle()
		UI.IsHidden = not UI.IsHidden
		local target = UI.ChangelogOpen and UI.ChangelogFrame or MainFrame
		local scaleObj = UI.ChangelogOpen and UI.ChangelogScale or MainScale
		if UI.IsHidden then
			Tween(scaleObj, FastTween, {Scale = 0.88 * (State.UIScale / 100)})
			task.delay(0.15, function()
				if UI.IsHidden then
					target.Visible = false
				end
			end)
		else
			target.Visible = true
			scaleObj.Scale = 0.88 * (State.UIScale / 100)
			Tween(scaleObj, PopInTween, {Scale = State.UIScale / 100})
		end
	end

	function Window:Unload()
		Unload()
	end

	windowRef = Window
	Window._Unload = Unload
	if Env then
		Env.__PotatoUnload = Unload
	end

	return Window
end

return Potato
