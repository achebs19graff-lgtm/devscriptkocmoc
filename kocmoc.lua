--═════════════════════════════════════════════════════════════════════════════
--  K O C M O C   C L I E N T  ·  glass edition  v1.0
--  LocalScript → StarterGui
--  Меню: ЛЕВЫЙ CTRL  ·  ПКМ по функции — настройки  ·  колесо — бинд (DEL — удалить)
--  Custom Model: скины встроены в код, без папок и ID
--═════════════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local StatsService     = game:GetService("Stats")
local VirtualUser      = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

--────────────────────────────────────────────────────────────── ТЕМА / СОСТОЯНИЕ
local Theme = {
    Accent  = Color3.fromRGB(141, 126, 255),
    Bg      = Color3.fromRGB(13, 14, 20),
    Bg2     = Color3.fromRGB(22, 23, 32),
    Bg3     = Color3.fromRGB(32, 33, 45),
    Text    = Color3.fromRGB(236, 237, 245),
    TextDim = Color3.fromRGB(142, 146, 163),
}

local State = { Open = false, OpenKey = Enum.KeyCode.LeftControl, UnlockHUD = false, MenuBlur = true, MenuScale = 1 }

local AccentCallbacks = {}
local function bindAccent(cb) table.insert(AccentCallbacks, cb) cb() end
local function SetAccent(color)
    Theme.Accent = color
    for _, cb in ipairs(AccentCallbacks) do pcall(cb) end
end
local function rainbow(seed) return Color3.fromHSV((os.clock() * 0.35 + (seed or 0)) % 1, 0.65, 1) end
local function resolveColor(mode, custom, pl, seed)
    if mode == "Радуга" then return rainbow(seed or 0)
    elseif mode == "Команда" then return (pl and pl.Team) and pl.TeamColor.Color or Theme.Accent
    else return custom end
end

local function mousePos() local m = UserInputService:GetMouseLocation() return Vector2.new(m.X, m.Y) end

--────────────────────────────────────────────────────────────── УТИЛИТЫ GUI
local function Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end
local function Corner(r, parent) return Create("UICorner", { CornerRadius = UDim.new(0, r) }, parent) end
local function Stroke(parent, color, transparency, thickness)
    return Create("UIStroke", { Color = color or Color3.new(1,1,1), Transparency = transparency or 0.9, Thickness = thickness or 1 }, parent)
end
local function Tween(obj, props, time)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    tw:Play() return tw
end
local function Label(parent, props)
    local d = { BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Text, TextSize = 13, Text = "", BorderSizePixel = 0 }
    for k, v in pairs(props) do d[k] = v end
    return Create("TextLabel", d, parent)
end
local function keyName(k)
    if not k then return "" end
    if k == Enum.UserInputType.MouseButton1 then return "MB1" end
    if k == Enum.UserInputType.MouseButton2 then return "MB2" end
    if k == Enum.UserInputType.MouseButton3 then return "MB3" end
    local s = UserInputService:GetStringForKeyCode(k)
    if s and #s > 0 and #s <= 4 then return string.upper(s) end
    return k.Name
end

--────────────────────────────────────────────────────────────── ВЕКТОРНЫЕ ИКОНКИ
local function iconLine(parent, x1, y1, x2, y2, th)
    local dx, dy = x2 - x1, y2 - y1
    return Create("Frame", {
        BackgroundColor3 = Theme.Text, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, (x1 + x2) * 0.5, 0.5, (y1 + y2) * 0.5),
        Size = UDim2.fromOffset(math.max(math.sqrt(dx * dx + dy * dy), 1), th or 2),
        Rotation = math.deg(math.atan2(dy, dx)),
    }, parent)
end
local function iconDot(parent, x, y, d, filled)
    local f = Create("Frame", {
        BackgroundColor3 = Theme.Text, BackgroundTransparency = filled and 0 or 1,
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, x, 0.5, y), Size = UDim2.fromOffset(d, d),
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
    if not filled then Stroke(f, Theme.Text, 0, 1.7) end
    return f
end
local ICON_BUILDERS = {
    combat = function(f)
        iconDot(f, 0, 0, 19, false)
        iconLine(f, 0, -13.5, 0, -7, 2)   iconLine(f, 0, 7, 0, 13.5, 2)
        iconLine(f, -13.5, 0, -7, 0, 2)   iconLine(f, 7, 0, 13.5, 0, 2)
        iconDot(f, 0, 0, 3.6, true)
    end,
    movement = function(f)
        iconLine(f, -7, 3, -0.5, -4.5, 2.2)  iconLine(f, -0.5, -4.5, 6, 3, 2.2)
        iconLine(f, -7, 11, -0.5, 3.5, 2.2)  iconLine(f, -0.5, 3.5, 6, 11, 2.2)
    end,
    visual = function(f)
        local eye = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(24, 15) }, f)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, eye)
        Stroke(eye, Theme.Text, 0, 1.8)
        iconDot(f, 0, 0, 7, true)
    end,
    hud = function(f)
        iconLine(f, -12, 3, -5, 3, 2.2)  iconLine(f, -5, 3, -2.5, -5, 2.2)
        iconLine(f, -2.5, -5, 0.5, 8, 2.2) iconLine(f, 0.5, 8, 3.5, -2, 2.2)
        iconLine(f, 3.5, -2, 12, -2, 2.2)
    end,
    settings = function(f)
        iconLine(f, -11, -8, 11, -8, 2) iconLine(f, -11, 0, 11, 0, 2) iconLine(f, -11, 8, 11, 8, 2)
        for _, p in ipairs({ { 5, -8 }, { -6, 0 }, { 2, 8 } }) do
            local d = iconDot(f, p[1], p[2], 7, true)
            d:SetAttribute("KeepBg", true)
            local s = Stroke(d, Theme.Bg, 0, 2.6)
            s:SetAttribute("KeepBg", true)
        end
    end,
}
local function paintIcon(icon, color)
    for _, d in ipairs(icon:GetDescendants()) do
        if d:IsA("Frame") and not d:GetAttribute("KeepBg") then d.BackgroundColor3 = color end
        if d:IsA("UIStroke") and not d:GetAttribute("KeepBg") then d.Color = color end
    end
end
local function buildIcon(kind, parent)
    local f = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0) }, parent)
    ICON_BUILDERS[kind](f)
    return f
end

--────────────────────────────────────────────────────────────── GUI-КАРКАС
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MenuGui = Create("ScreenGui", { Name = "KOCMOC_Menu", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50 }, PlayerGui)
local HudGui  = Create("ScreenGui", { Name = "KOCMOC_HUD",  ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20 }, PlayerGui)
local menuBlur = Create("BlurEffect", { Name = "KOCMOC_MenuBlur", Size = 0 }, Lighting)
local hudScale = Create("UIScale", { Scale = 1 }, HudGui)

local Root = Create("CanvasGroup", {
    BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.14, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(780, 500), Visible = false, GroupTransparency = 1, Active = true,
}, MenuGui)
Corner(16, Root)
Stroke(Root, Color3.new(1, 1, 1), 0.9, 1.3)
local RootScale = Create("UIScale", { Scale = 0.96 }, Root)
local gloss = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 150), BorderSizePixel = 0 }, Root)
Create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
    Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.94), NumberSequenceKeypoint.new(1, 1) }) }, gloss)

local TopBar = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48) }, Root)
Create("Frame", { Position = UDim2.new(0, 18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, TopBar)
    .Name = "LogoDot"
bindAccent(function()
    local d = TopBar:FindFirstChild("LogoDot") if d then d.BackgroundColor3 = Theme.Accent end
end)
Label(TopBar, { Text = "KOCMOC", Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(0, 76, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
Label(TopBar, { Text = ".CLIENT", Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.new(0, 110, 0, 0), Size = UDim2.new(0, 84, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    .Name = "LogoAccent"
bindAccent(function() local l = TopBar:FindFirstChild("LogoAccent") if l then l.TextColor3 = Theme.Accent end end)
Label(TopBar, { Text = "v1.0 · glass", TextSize = 11, TextColor3 = Theme.TextDim, Position = UDim2.new(0, 196, 0, 0), Size = UDim2.new(0, 90, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
Label(TopBar, { Text = "ЛКМ — вкл/выкл   ·   ПКМ — настройки   ·   колесо — бинд", TextSize = 11, TextColor3 = Theme.TextDim, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 340, 0, 14), TextXAlignment = Enum.TextXAlignment.Right })
Create("Frame", { Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94, BorderSizePixel = 0 }, Root)

local TabsBar = Create("Frame", { Position = UDim2.new(0, 14, 0, 60), Size = UDim2.new(0, 56, 1, -74), BackgroundColor3 = Theme.Bg2, BackgroundTransparency = 0.45, BorderSizePixel = 0 }, Root)
Corner(14, TabsBar)
Stroke(TabsBar, Color3.new(1, 1, 1), 0.93, 1)
Create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }, TabsBar)
Create("UIPadding", { PaddingTop = UDim.new(0, 10) }, TabsBar)

local Tip = Create("TextLabel", { BackgroundColor3 = Theme.Bg3, BackgroundTransparency = 0.05, Visible = false, TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Text, Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, ZIndex = 60 }, Root)
Corner(6, Tip)
Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, Tip)
local function showTip(btn, text)
    Tip.Text = text; Tip.Visible = true
    Tip.Position = UDim2.fromOffset(btn.AbsolutePosition.X - Root.AbsolutePosition.X + btn.AbsoluteSize.X + 8, btn.AbsolutePosition.Y - Root.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2)
    Tip.AnchorPoint = Vector2.new(0, 0.5)
end
local function hideTip() Tip.Visible = false end

local TAB_DEFS = {
    { id = "combat",   icon = "combat" },   { id = "movement", icon = "movement" },
    { id = "visual",   icon = "visual" },   { id = "hud",      icon = "hud" },
    { id = "settings", icon = "settings" },
}
local TAB_NAMES = { combat = "Combat", movement = "Movement", visual = "Visual", hud = "HUD", settings = "Settings" }
local Tabs, ActiveTab = {}, nil

local PagesRoot = Create("Frame", { Position = UDim2.new(0, 82, 0, 60), Size = UDim2.new(1, -96, 1, -74), BackgroundTransparency = 1 }, Root)
local PageTitle = Label(PagesRoot, { Text = "", Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.2 })
PageTitle.Name = "PageAccentWord"
local Pages = {}
for _, def in ipairs(TAB_DEFS) do
    local page = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -30), Position = UDim2.new(0, 0, 0, 30), Visible = false }, PagesRoot)
    local cols = {}
    for i, side in ipairs({ "Left", "Right" }) do
        local scroll = Create("ScrollingFrame", {
            Position = UDim2.new((i - 1) * 0.5, i == 1 and 0 or 5, 0, 0), Size = UDim2.new(0.5, -5, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.7, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, page)
        Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
        Create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }, scroll)
        cols[side] = scroll
    end
    Pages[def.id] = { Frame = page, Left = cols.Left, Right = cols.Right }
end

local function SwitchTab(id)
    ActiveTab = id
    for _, d in ipairs(TAB_DEFS) do
        local t, active = Tabs[d.id], d.id == id
        Pages[d.id].Frame.Visible = active
        Tween(t.Btn, { BackgroundTransparency = active and 0.84 or 1, BackgroundColor3 = active and Theme.Accent or Theme.Bg2 }, 0.25)
        t.BtnStroke.Color = active and Theme.Accent or Color3.new(1, 1, 1)
        t.BtnStroke.Transparency = active and 0.45 or 0.93
        paintIcon(t.Icon, active and Theme.Accent or Theme.Text)
    end
    PageTitle.Text = TAB_NAMES[id]
end

for _, def in ipairs(TAB_DEFS) do
    local btn = Create("TextButton", { Text = "", BackgroundColor3 = Theme.Bg2, BackgroundTransparency = 1, Size = UDim2.fromOffset(42, 42), AutoButtonColor = false, BorderSizePixel = 0 }, TabsBar)
    Corner(12, btn)
    local st = Stroke(btn, Color3.new(1, 1, 1), 0.93, 1)
    local icon = buildIcon(def.icon, btn)
    Tabs[def.id] = { Btn = btn, BtnStroke = st, Icon = icon }
    btn.MouseEnter:Connect(function() if ActiveTab ~= def.id then Tween(btn, { BackgroundTransparency = 0.55 }, 0.15) end; showTip(btn, TAB_NAMES[def.id]) end)
    btn.MouseLeave:Connect(function() if ActiveTab ~= def.id then Tween(btn, { BackgroundTransparency = 1 }, 0.2) end; hideTip() end)
    btn.MouseButton1Click:Connect(function() SwitchTab(def.id) end)
end

-- оверлей назначения бинда
local BindOverlay = Create("TextButton", { Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.new(1, 0, 1, 0), Visible = false, AutoButtonColor = false }, MenuGui)
local BindLabel = Label(BindOverlay, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 700, 0, 30), Text = "", TextSize = 15, Font = Enum.Font.GothamBold })

local Binding = nil
local function StartBindCapture(target)
    Binding = target
    BindOverlay.Visible = true
    BindLabel.Text = 'Нажми клавишу для «' .. target.Name .. '»   ·   DELETE — удалить бинд   ·   ESC — отмена'
end
-- клик по оверлею = отмена (бинд не трогаем)
BindOverlay.MouseButton1Click:Connect(function()
    Binding = nil; BindOverlay.Visible = false
end)

--────────────────────────────────────────────────────────────── КОНТРОЛЫ НАСТРОЕК
local function ctrlHolder(parent, h)
    return Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h or 26), BorderSizePixel = 0 }, parent)
end

local function MakeToggle(parent, def, F)
    local h = ctrlHolder(parent, 24)
    Label(h, { Text = def.Name, TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local sw = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(30, 16), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, h)
    Corner(8, sw)
    local knob = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0 }, sw)
    Corner(6, knob)
    local state = def.Default and true or false
    F.S[def.Name] = state
    local function draw()
        Tween(sw, { BackgroundColor3 = state and Theme.Accent or Theme.Bg3 }, 0.15)
        Tween(knob, { Position = state and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.TextDim }, 0.15)
    end
    bindAccent(draw)
    F._toggles = F._toggles or {}
    F._toggles[def.Name] = function(v)
        state = v and true or false
        F.S[def.Name] = state
        draw()
        if def.Callback then pcall(def.Callback, state, F) end
    end
    if def.Callback then pcall(def.Callback, state, F) end
    local btn = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, h)
    btn.MouseButton1Click:Connect(function()
        state = not state; F.S[def.Name] = state; draw()
        if def.Callback then pcall(def.Callback, state, F) end
    end)
end

local function MakeSlider(parent, def, F)
    local h = ctrlHolder(parent, 36)
    Label(h, { Text = def.Name, TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(1, -60, 0, 14), TextXAlignment = Enum.TextXAlignment.Left })
    local valLabel = Label(h, { Text = "", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 70, 0, 14), TextXAlignment = Enum.TextXAlignment.Right })
    local bar = Create("Frame", { Position = UDim2.new(0, 0, 0, 21), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, h)
    Corner(2, bar)
    local fill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, bar)
    Corner(2, fill)
    local knob = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
    Corner(5, knob)
    local min, max = def.Min, def.Max
    F.S[def.Name] = def.Default
    local function set(v, noFire)
        v = math.clamp(v, min, max)
        F.S[def.Name] = def.Int and math.floor(v + 0.5) or math.floor(v * 10 + 0.5) / 10
        local p = (v - min) / (max - min)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valLabel.Text = tostring(F.S[def.Name]) .. (def.Suffix and (" " .. def.Suffix) or "")
        if not noFire and def.Callback then pcall(def.Callback, F.S[def.Name], F) end
    end
    set(def.Default, true)
    F._sliders = F._sliders or {}
    F._sliders[def.Name] = function(v) set(v) end
    bindAccent(function() fill.BackgroundColor3 = Theme.Accent end)
    local dragging = false
    local function fromMouse()
        local p = math.clamp((mousePos().X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        set(min + (max - min) * p)
    end
    bar.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromMouse() end end)
    UserInputService.InputChanged:Connect(function(io) if dragging and io.UserInputType == Enum.UserInputType.MouseMovement then fromMouse() end end)
    UserInputService.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function MakeDropdown(parent, def, F)
    local h = ctrlHolder(parent, 26)
    Label(h, { Text = def.Name, TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(1, -146, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local current = def.Default or def.Options[1]
    F.S[def.Name] = current
    local btn = Create("TextButton", { Text = current, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(136, 22), BackgroundColor3 = Theme.Bg3, TextSize = 11, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Text, AutoButtonColor = false, BorderSizePixel = 0, TextTruncate = Enum.TextTruncate.AtEnd }, h)
    Corner(6, btn)
    local list = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, Visible = false }, parent)
    Create("UIListLayout", { Padding = UDim.new(0, 2) }, list)
    Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, list)
    for _, opt in ipairs(def.Options) do
        local ob = Create("TextButton", { Text = opt, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.GothamMedium, TextColor3 = Theme.TextDim, AutoButtonColor = false, BorderSizePixel = 0 }, list)
        Corner(4, ob)
        ob.MouseEnter:Connect(function() ob.BackgroundColor3 = Theme.Bg3; ob.BackgroundTransparency = 0.2; ob.TextColor3 = Theme.Text end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1; ob.TextColor3 = Theme.TextDim end)
        ob.MouseButton1Click:Connect(function()
            current = opt; F.S[def.Name] = opt; btn.Text = opt; list.Visible = false
            if def.Callback then pcall(def.Callback, opt, F) end
        end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    if def.Callback then pcall(def.Callback, current, F) end
end

local COLOR_PRESETS = {
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 150, 160), Color3.fromRGB(25, 25, 32),
    Color3.fromRGB(255, 80, 80),  Color3.fromRGB(255, 160, 60),  Color3.fromRGB(255, 225, 90),
    Color3.fromRGB(90, 220, 110), Color3.fromRGB(70, 200, 255),  Color3.fromRGB(141, 126, 255),
    Color3.fromRGB(255, 110, 200),
}
local function MakeColor(parent, def, F)
    local h = ctrlHolder(parent, 22)
    Label(h, { Text = def.Name, TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(1, -50, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local cur = def.Default or Color3.fromRGB(255, 60, 60)
    F.S[def.Name] = cur
    local preview = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 14), BackgroundColor3 = cur, BorderSizePixel = 0 }, h)
    Corner(4, preview)
    Stroke(preview, Color3.new(1, 1, 1), 0.85, 1)
    local sw = Create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right }, sw)
    for _, c in ipairs(COLOR_PRESETS) do
        local b = Create("TextButton", { Text = "", Size = UDim2.fromOffset(16, 16), BackgroundColor3 = c, BorderSizePixel = 0, AutoButtonColor = false }, sw)
        Corner(4, b)
        Stroke(b, Color3.new(1, 1, 1), 0.85, 1)
        b.MouseButton1Click:Connect(function()
            cur = c; F.S[def.Name] = c; preview.BackgroundColor3 = c
            if def.Callback then pcall(def.Callback, c, F) end
        end)
    end
    local hueH = ctrlHolder(parent, 20)
    local bar = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, -48, 0, 8), BorderSizePixel = 0 }, hueH)
    Corner(4, bar)
    Create("UIGradient", { Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),   ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }) }, bar)
    Label(hueH, { Text = "оттенок", TextSize = 10, TextColor3 = Theme.TextDim, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 44, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
    local hh, hs = cur:ToHSV()
    local dragging = false
    local function setHue(v)
        hh = v
        local c = Color3.fromHSV(hh, math.max(hs, 0.15), 1)
        preview.BackgroundColor3 = c; F.S[def.Name] = c
        if def.Callback then pcall(def.Callback, c, F) end
    end
    bar.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setHue(math.clamp((mousePos().X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)) end end)
    UserInputService.InputChanged:Connect(function(io) if dragging and io.UserInputType == Enum.UserInputType.MouseMovement then setHue(math.clamp((mousePos().X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)) end end)
    UserInputService.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function MakeButton(parent, def, F)
    local btn = Create("TextButton", { Text = def.Name, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Bg3, BackgroundTransparency = 0.3, TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Text, AutoButtonColor = false, BorderSizePixel = 0 }, parent)
    Corner(6, btn)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.Accent; btn.BackgroundTransparency = 0.75; btn.TextColor3 = Theme.Accent end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.Bg3; btn.BackgroundTransparency = 0.3; btn.TextColor3 = Theme.Text end)
    btn.MouseButton1Click:Connect(function() if def.Callback then pcall(def.Callback, F) end end)
end

local function AddSection(tab, col, title)
    local f = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, BorderSizePixel = 0 }, Pages[tab][col])
    local dot = Create("Frame", { Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, f)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
    bindAccent(function() dot.BackgroundColor3 = Theme.Accent end)
    Label(f, { Text = title, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = Theme.TextDim, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    Create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94, BorderSizePixel = 0 }, f)
end

--────────────────────────────────────────────────────────────── ФАБРИКА ФУНКЦИЙ
local Functions, HeldKeys = {}, {}

local function AddFunction(tab, col, def)
    local scroll = Pages[tab][col]
    local F = {
        Name = def.Name, Hold = def.Hold or false, Bind = def.Bind or nil,
        Enabled = false, S = {}, OnEnable = def.OnEnable, OnDisable = def.OnDisable,
    }
    Functions[#Functions + 1] = F

    local Row = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Bg2, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, scroll)
    Corner(10, Row)
    local RowStroke = Stroke(Row, Color3.new(1, 1, 1), 0.93, 1)
    Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, Row)

    local Head = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), AutoButtonColor = false, LayoutOrder = 1 }, Row)
    Label(Head, { Text = def.Name, TextSize = 13, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -120, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })

    -- чип бинда: поверх тумблера (ZIndex 5), не перекрывается
    local Chip = Create("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0), Size = UDim2.fromOffset(26, 18), BackgroundColor3 = Theme.Bg3, BackgroundTransparency = 0.2, TextSize = 10, Font = Enum.Font.GothamBold, TextColor3 = Theme.TextDim, Text = "", Visible = false, BorderSizePixel = 0, ZIndex = 5 }, Head)
    Corner(5, Chip)

    local Tg = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(32, 18), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, Head)
    Corner(9, Tg)
    local Knob = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0 }, Tg)
    Corner(6, Knob)

    local Panel = Create("Frame", { Visible = false, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = 2 }, Row)
    Corner(8, Panel)
    Create("UIListLayout", { Padding = UDim.new(0, 6) }, Panel)
    Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10) }, Panel)

    local function drawChip() if F.Bind then Chip.Text = keyName(F.Bind); Chip.Visible = true else Chip.Visible = false end end
    F._drawChip = drawChip
    drawChip()

    local expanded = false
    local function drawState()
        Tween(Tg, { BackgroundColor3 = F.Enabled and Theme.Accent or Theme.Bg3 }, 0.18)
        Tween(Knob, { Position = F.Enabled and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = F.Enabled and Color3.new(1, 1, 1) or Theme.TextDim }, 0.18)
        RowStroke.Color = (F.Enabled or expanded) and Theme.Accent or Color3.new(1, 1, 1)
        RowStroke.Transparency = F.Enabled and 0.55 or (expanded and 0.75 or 0.93)
    end
    local function setExpanded(v) expanded = v; Panel.Visible = v; drawState() end

    F.SetState = function(on)
        if F.Enabled == on then return end
        F.Enabled = on
        if on and F.OnEnable then pcall(F.OnEnable, F) end
        if not on and F.OnDisable then pcall(F.OnDisable, F) end
        drawState()
    end

    Head.MouseButton1Click:Connect(function() F.SetState(not F.Enabled) end)
    local function rowInput(io)
        if io.UserInputType == Enum.UserInputType.MouseButton2 then setExpanded(not expanded) end
        if io.UserInputType == Enum.UserInputType.MouseButton3 then StartBindCapture(F) end
    end
    Head.InputBegan:Connect(rowInput)
    Row.InputBegan:Connect(rowInput)
    Row.MouseEnter:Connect(function() if not expanded then Tween(Row, { BackgroundTransparency = 0.18 }, 0.12) end end)
    Row.MouseLeave:Connect(function() Tween(Row, { BackgroundTransparency = 0.35 }, 0.2) end)

    for _, s in ipairs(def.Settings or {}) do
        pcall(function()
            if s.Type == "Toggle" then MakeToggle(Panel, s, F)
            elseif s.Type == "Slider" then MakeSlider(Panel, s, F)
            elseif s.Type == "Dropdown" then MakeDropdown(Panel, s, F)
            elseif s.Type == "Color" then MakeColor(Panel, s, F)
            elseif s.Type == "Button" then MakeButton(Panel, s, F)
            end
        end)
    end
    bindAccent(drawState)
    if def.Default then F.SetState(true) end
    return F
end

--────────────────────────────────────────────────────────────── ИГРОВЫЕ УТИЛИТЫ
local function getCharacter(pl)
    local c = pl.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if c and hum and hum.Health > 0 and c:FindFirstChild("HumanoidRootPart") then return c end
    return nil
end
local function getHRP(pl) local c = pl.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function isEnemy(pl, teamCheck)
    if pl == LocalPlayer then return false end
    if teamCheck and pl.Team and pl.Team == LocalPlayer.Team then return false end
    return true
end
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
local function canSee(targetChar, pos)
    local f = { LocalPlayer.Character, targetChar, Camera }
    local clean = {}
    for _, v in ipairs(f) do if v then table.insert(clean, v) end end
    wallParams.FilterDescendantsInstances = clean
    return workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, wallParams) == nil
end
local hoverParams = RaycastParams.new()
hoverParams.FilterType = Enum.RaycastFilterType.Exclude
local function getMouseTarget(enemyOnly)
    local f = {}
    if LocalPlayer.Character then table.insert(f, LocalPlayer.Character) end
    hoverParams.FilterDescendantsInstances = f
    local m = mousePos()
    local ray = Camera:ViewportPointToRay(m.X, m.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, hoverParams)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        while model do
            local pl = Players:GetPlayerFromCharacter(model)
            if pl and (not enemyOnly or isEnemy(pl, true)) then return pl end
            model = model:FindFirstAncestorOfClass("Model")
        end
    end
    return nil
end

local AIM_NAME_MAP = {
    ["Голова"]          = { "Head", "HeadPart", "Hitbox_Head" },
    ["Торс"]            = { "UpperTorso", "Torso", "Chest", "Body" },
    ["Корневая часть"]  = { "HumanoidRootPart", "RootPart", "HumanoidRoot" },
    ["Случайно"]        = { "Head", "HumanoidRootPart" },
    ["Авто"]            = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
}
local function findAimParts(c, mode)
    local names = AIM_NAME_MAP[mode] or AIM_NAME_MAP["Авто"]
    local list, seen = {}, {}
    local function try(p)
        if p and p:IsA("BasePart") and not seen[p] then
            seen[p] = true
            table.insert(list, p)
        end
    end
    for _, n in ipairs(names) do try(c:FindFirstChild(n)) end
    if #list == 0 then
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                for _, n in ipairs(names) do
                    if d.Name == n then try(d) break end
                end
            end
        end
    end
    if #list == 0 then
        try(c.PrimaryPart)
        try(c:FindFirstChildWhichIsA("BasePart"))
    end
    if #list == 0 then
        local best, bestV
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                local v = d.Size.X * d.Size.Y * d.Size.Z
                if not best or v > bestV then best, bestV = d, v end
            end
        end
        try(best)
    end
    return list
end

local function aimCharAlive(pl, universal, ignoreFF)
    local c = pl.Character
    if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return nil end
    if not ignoreFF and c:FindFirstChildOfClass("ForceField") then return nil end
    if not universal then
        if not (hum and hum.Health > 0 and c:FindFirstChild("HumanoidRootPart")) then return nil end
    else
        local ok = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
        if not ok then return nil end
    end
    return c
end

--────────────────────────────────────────────────────────────── HUD-ЭЛЕМЕНТЫ
local HUD_ELEMENTS, hudDefaults = {}, {}
local function hudFrame(name, size, pos, anchor, transparency)
    local f = Create("Frame", { Size = size, Position = pos, AnchorPoint = anchor or Vector2.new(), BackgroundColor3 = Theme.Bg, BackgroundTransparency = transparency or 0.25, BorderSizePixel = 0 }, HudGui)
    Corner(10, f)
    Stroke(f, Color3.new(1, 1, 1), 0.9, 1)
    HUD_ELEMENTS[#HUD_ELEMENTS + 1] = f
    hudDefaults[f] = { anchor or Vector2.new(), pos }
    return f
end
local POSITIONS = {
    ["Слева сверху"]  = { Vector2.new(0, 0),   UDim2.new(0, 12, 0, 10) },
    ["Центр сверху"]  = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 10) },
    ["Справа сверху"] = { Vector2.new(1, 0),   UDim2.new(1, -12, 0, 10) },
    ["Слева снизу"]   = { Vector2.new(0, 1),   UDim2.new(0, 12, 1, -10) },
    ["Центр снизу"]   = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -10) },
    ["Справа снизу"]  = { Vector2.new(1, 1),   UDim2.new(1, -12, 1, -10) },
}
local function applyPos(f, name)
    local p = POSITIONS[name]
    if p then f.AnchorPoint = p[1]; f.Position = p[2] end
end
local function attachDrag(f)
    f.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 and State.UnlockHUD then
            local last = mousePos()
            local conn = UserInputService.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement then
                    local mp = mousePos()
                    local d = mp - last; last = mp
                    f.Position = UDim2.new(f.Position.X.Scale, f.Position.X.Offset + d.X, f.Position.Y.Scale, f.Position.Y.Offset + d.Y)
                end
            end)
            UserInputService.InputEnded:Wait()
            conn:Disconnect()
        end
    end)
end

local BarLeft  = Create("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), Visible = false }, HudGui)
local BarRight = Create("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Visible = false }, HudGui)
local FovCircle = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false }, HudGui)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, FovCircle)
local FovCircleStroke = Stroke(FovCircle, Theme.Accent, 0.35, 1.6)
local ArrowRoot = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false }, HudGui)
local arrows = {}
for i = 1, 10 do
    local a = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Visible = false }, ArrowRoot)
    local l1 = iconLine(a, -4, 3, 0, -4, 3)
    local l2 = iconLine(a, 0, -4, 4, 3, 3)
    local dist = Label(a, { Text = "", TextSize = 10, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.fromOffset(70, 12) })
    arrows[i] = { Holder = a, Lines = { l1, l2 }, Dist = dist }
end

local TESP = Create("CanvasGroup", { BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5) }, HudGui)
local TESP_LINES = {}
do
    local function line(z)
        local f = Create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z }, TESP)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        return f
    end
    for i = 1, 8 do TESP_LINES[i] = { G2 = line(1) } end
    for i = 1, 8 do
        TESP_LINES[i].G1 = line(2)
        TESP_LINES[i].G1.BackgroundTransparency = 0.55
        TESP_LINES[i].G2.BackgroundTransparency = 0.8
    end
    for i = 1, 8 do TESP_LINES[i].Core = line(3) end
end
local TESPDist = Create("TextLabel", { BackgroundTransparency = 1, Text = "", TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(80, 14), Visible = false }, HudGui)

local CrosshairF_ = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Visible = false }, HudGui)
local chParts = {}
local function buildCrosshair(style, size, th, color)
    for _, p in ipairs(chParts) do p:Destroy() end
    chParts = {}
    local gap = 3
    local function line(x1, y1, x2, y2) table.insert(chParts, iconLine(CrosshairF_, x1, y1, x2, y2, th)) end
    if style == "Крест" or style == "Круг" then
        line(-gap - size, 0, -gap, 0) line(gap, 0, gap + size, 0)
        line(0, -gap - size, 0, -gap) line(0, gap, 0, gap + size)
    end
    if style == "Точка" or style == "Круг" then table.insert(chParts, iconDot(CrosshairF_, 0, 0, math.max(th + 1, 3), true)) end
    if style == "Круг" then table.insert(chParts, iconDot(CrosshairF_, 0, 0, (size + gap) * 2, false)) end
    local c = color or Theme.Accent
    for _, p in ipairs(chParts) do
        if p:IsA("Frame") then p.BackgroundColor3 = c end
        if p:IsA("UIStroke") then p.Color = c end
    end
end
local PHud = Create("CanvasGroup", { BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.22, BorderSizePixel = 0, Size = UDim2.fromOffset(232, 84), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 60), GroupTransparency = 1, Visible = false }, HudGui)
Corner(12, PHud)
Stroke(PHud, Color3.new(1, 1, 1), 0.88, 1)
local pHudAvatar = Create("ImageLabel", { Position = UDim2.new(0, 12, 0, 12), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, PHud)
Corner(10, pHudAvatar)
Stroke(pHudAvatar, Color3.new(1, 1, 1), 0.9, 1)
local pHudName = Label(PHud, { Text = "—", TextSize = 14, Font = Enum.Font.GothamBold, Position = UDim2.new(0, 82, 0, 13), Size = UDim2.new(1, -94, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
local pHudHpBg = Create("Frame", { Position = UDim2.new(0, 82, 0, 37), Size = UDim2.new(1, -94, 0, 6), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, PHud)
Corner(3, pHudHpBg)
local pHudHp = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 220, 120), BorderSizePixel = 0 }, pHudHpBg)
Corner(3, pHudHp)
local pHudInfo = Label(PHud, { Text = "", TextSize = 11, TextColor3 = Theme.TextDim, Position = UDim2.new(0, 82, 0, 50), Size = UDim2.new(1, -94, 0, 14), TextXAlignment = Enum.TextXAlignment.Left })

local TSInfo = Create("CanvasGroup", { BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.22, BorderSizePixel = 0, Size = UDim2.fromOffset(232, 92), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), GroupTransparency = 1, Visible = false }, HudGui)
Corner(12, TSInfo)
Stroke(TSInfo, Color3.new(1, 1, 1), 0.88, 1)
attachDrag(TSInfo)
local tsAvatar = Create("ImageLabel", { Position = UDim2.new(0, 12, 0, 12), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, TSInfo)
Corner(10, tsAvatar)
Stroke(tsAvatar, Color3.new(1, 1, 1), 0.9, 1)
local tsName = Label(TSInfo, { Text = "— нет цели —", TextSize = 14, Font = Enum.Font.GothamBold, Position = UDim2.new(0, 74, 0, 11), Size = UDim2.new(1, -86, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
local tsDot = Create("Frame", { Position = UDim2.new(0, 74, 0, 32), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0 }, TSInfo)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, tsDot)
local tsStatus = Label(TSInfo, { Text = "", TextSize = 10, Font = Enum.Font.GothamBold, Position = UDim2.new(0, 86, 0, 28), Size = UDim2.new(1, -98, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
local tsHpBg = Create("Frame", { Position = UDim2.new(0, 74, 0, 46), Size = UDim2.new(1, -86, 0, 5), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, TSInfo)
Corner(3, tsHpBg)
local tsHp = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 220, 120), BorderSizePixel = 0 }, tsHpBg)
Corner(3, tsHp)
local tsInfoLbl = Label(TSInfo, { Text = "", TextSize = 11, TextColor3 = Theme.TextDim, Position = UDim2.new(0, 74, 0, 55), Size = UDim2.new(1, -86, 0, 14), TextXAlignment = Enum.TextXAlignment.Left })
local tsAimBg = Create("Frame", { Position = UDim2.new(0, 12, 1, -14), Size = UDim2.new(1, -24, 0, 4), BackgroundColor3 = Theme.Bg3, BorderSizePixel = 0 }, TSInfo)
Corner(2, tsAimBg)
local tsAim = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, tsAimBg)
Corner(2, tsAim)
bindAccent(function() tsAim.BackgroundColor3 = Theme.Accent end)

local Watermark = hudFrame("Watermark", UDim2.fromOffset(150, 30), UDim2.new(0, 12, 0, 10))
Watermark.AutomaticSize = Enum.AutomaticSize.X
local wmDot = Create("Frame", { Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, Watermark)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, wmDot)
local wmText = Label(Watermark, { Text = "KOCMOC.CLIENT", TextSize = 12, Font = Enum.Font.GothamBold, Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Left })
Create("UIPadding", { PaddingRight = UDim.new(0, 14) }, Watermark)
attachDrag(Watermark)
local Radar = hudFrame("Radar", UDim2.fromOffset(160, 160), UDim2.new(1, -12, 1, -12), Vector2.new(1, 1), 0.32)
attachDrag(Radar)
for _, r in ipairs({ 0.33, 0.66 }) do
    local ring = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(r, 0, r, 0), BackgroundTransparency = 1, ZIndex = 1 }, Radar)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
    Stroke(ring, Color3.new(1, 1, 1), 0.9, 1)
end
Create("Frame", { Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0, 1, 1, -16), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.93, BorderSizePixel = 0 }, Radar)
Create("Frame", { Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.new(1, -16, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.93, BorderSizePixel = 0 }, Radar)
local meDot = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(5, 5), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 2 }, Radar)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, meDot)
local radarDots = {}
for i = 1, 12 do
    local d = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.fromRGB(255, 90, 90), BorderSizePixel = 0, Visible = false, ZIndex = 2 }, Radar)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
    radarDots[i] = d
end
local Keystrokes = hudFrame("Keystrokes", UDim2.fromOffset(46, 74), UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))
attachDrag(Keystrokes)
local keyButtons = {}
local function keyBtn(x, y, w, h, label)
    local b = Create("TextLabel", { Position = UDim2.new(0, x, 0, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = Theme.Bg3, BackgroundTransparency = 0.1, Text = label, TextSize = 10, Font = Enum.Font.GothamBold, TextColor3 = Theme.TextDim, BorderSizePixel = 0 }, Keystrokes)
    Corner(4, b)
    return b
end
keyButtons.W = keyBtn(16, 5, 14, 14, "W")
keyButtons.A = keyBtn(2, 21, 14, 14, "A")
keyButtons.S = keyBtn(16, 21, 14, 14, "S")
keyButtons.D = keyBtn(30, 21, 14, 14, "D")
keyButtons.Space = keyBtn(2, 37, 42, 10, "")
keyButtons.MB1 = keyBtn(2, 49, 20, 14, "L")
keyButtons.MB2 = keyBtn(24, 49, 20, 14, "R")
local Speedo = hudFrame("Speedometer", UDim2.fromOffset(110, 44), UDim2.new(0.5, 0, 1, -20), Vector2.new(0.5, 1))
attachDrag(Speedo)
local speedLabel = Label(Speedo, { Text = "0.0", TextSize = 20, Font = Enum.Font.GothamBold, Size = UDim2.new(1, 0, 1, 0) })
Label(Speedo, { Text = "st/s", TextSize = 10, TextColor3 = Theme.TextDim, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -4), Size = UDim2.fromOffset(30, 12) })
local LogsFrame = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 1, -12), AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(260, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, HudGui)
Create("UIListLayout", { Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Bottom }, LogsFrame)
attachDrag(LogsFrame)

local FPS = 0
do
    local frames, acc = 0, 0
    RunService.RenderStepped:Connect(function(dt)
        frames += 1; acc += dt
        if acc >= 0.5 then FPS = math.floor(frames / acc + 0.5); frames = 0; acc = 0 end
    end)
end
local function getPing()
    local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return ok and math.floor(v) or 0
end
local avatarCache = {}
local function getAvatar(pl)
    if avatarCache[pl] then return avatarCache[pl] end
    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok then avatarCache[pl] = content end
    end)
    return ""
end

--────────────────────────────────────────────────────────────── СОСТОЯНИЯ ЧИТОВ
local noclipParts = {}
local function setNoclip(pl, on)
    local c = pl.Character
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then
            if on then
                if d.CanCollide then noclipParts[d] = true; d.CanCollide = false end
            elseif noclipParts[d] then
                d.CanCollide = true; noclipParts[d] = nil
            end
        end
    end
end

local UserGameSettings = nil
pcall(function() UserGameSettings = UserSettings():GetService("UserGameSettings") end)
local function applyShiftLock(on)
    pcall(function()
        if UserGameSettings then
            UserGameSettings.RotationType = on and Enum.RotationType.CameraRelative or Enum.RotationType.MovementRelative
        end
    end)
    if on then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

local savedLighting = {
    ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient, Ambient = Lighting.Ambient,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor, ExposureCompensation = Lighting.ExposureCompensation,
}
local SKY_PRESETS = {
    ["Стандарт"]  = savedLighting,
    ["Полночь"]   = { ClockTime = 0, Brightness = 1.2, OutdoorAmbient = Color3.fromRGB(20, 25, 45), Ambient = Color3.fromRGB(15, 15, 30), FogEnd = 900, FogStart = 0, FogColor = Color3.fromRGB(20, 24, 40), ExposureCompensation = 0 },
    ["Закат"]     = { ClockTime = 17.4, Brightness = 2.2, OutdoorAmbient = Color3.fromRGB(255, 160, 95), Ambient = Color3.fromRGB(120, 80, 60), FogEnd = 1400, FogStart = 0, FogColor = Color3.fromRGB(255, 190, 130), ExposureCompensation = 0 },
    ["Vaporwave"] = { ClockTime = 13.8, Brightness = 2.4, OutdoorAmbient = Color3.fromRGB(225, 130, 255), Ambient = Color3.fromRGB(150, 90, 220), FogEnd = 2500, FogStart = 0, FogColor = Color3.fromRGB(230, 160, 255), ExposureCompensation = 0.1 },
    ["Бездна"]    = { ClockTime = 0, Brightness = 0.4, OutdoorAmbient = Color3.fromRGB(8, 10, 16), Ambient = Color3.fromRGB(5, 6, 10), FogEnd = 260, FogStart = 0, FogColor = Color3.fromRGB(5, 7, 12), ExposureCompensation = -0.4 },
    ["Неон"]      = { ClockTime = 12, Brightness = 3, OutdoorAmbient = Color3.fromRGB(240, 245, 255), Ambient = Color3.fromRGB(200, 210, 255), FogEnd = 5000, FogStart = 0, FogColor = Color3.fromRGB(220, 230, 255), ExposureCompensation = 0.2 },
}
local function applySky(name)
    local p = SKY_PRESETS[name]
    if not p then return end
    for k, v in pairs(p) do Lighting[k] = v end
end

local ccPlus   = Create("ColorCorrectionEffect", { Name = "KOCMOC_ColorPlus" }, Lighting)
local fogBlur  = Create("BlurEffect", { Name = "KOCMOC_FogBlur", Size = 0 }, Lighting)

--────────────────────────────────────────────────────────────── COMBAT
AddSection("combat", "Left", "Основное")
AddSection("combat", "Right", "Прочее")

local AimbotF = AddFunction("combat", "Left", {
    Name = "Aim Bot",
    Settings = {
        { Type = "Dropdown", Name = "Режим",         Options = { "Всегда", "Удержание", "Свободный курсор" }, Default = "Всегда" },
        { Type = "Slider",   Name = "Радиус FOV",    Min = 20, Max = 800, Default = 250, Int = true, Suffix = "px" },
        { Type = "Slider",   Name = "Скорость",      Min = 1, Max = 100, Default = 35, Int = true, Suffix = "%" },
        { Type = "Slider",   Name = "Предсказание",  Min = 0, Max = 100, Default = 40, Int = true, Suffix = "%" },
        { Type = "Dropdown", Name = "Цель",          Options = { "Авто", "Голова", "Торс", "Корневая часть", "Случайно" }, Default = "Авто" },
        { Type = "Dropdown", Name = "Приоритет",     Options = { "К прицелу", "По дистанции", "По HP" }, Default = "К прицелу" },
        { Type = "Toggle",   Name = "Мгновенный снап", Default = true },
        { Type = "Toggle",   Name = "Автовыстрел",   Default = false },
        { Type = "Slider",   Name = "Радиус выстрела", Min = 5, Max = 100, Default = 25, Int = true, Suffix = "px" },
        { Type = "Slider",   Name = "Пауза выстрела",  Min = 0.05, Max = 1, Default = 0.15, Suffix = "с" },
        { Type = "Toggle",   Name = "Универсальный режим", Default = true },
        { Type = "Toggle",   Name = "Форсировать камеру",  Default = true },
        { Type = "Toggle",   Name = "Игнор ForceField",    Default = true },
        { Type = "Toggle",   Name = "Team Check",    Default = true },
        { Type = "Toggle",   Name = "Проверка стен", Default = true },
        { Type = "Toggle",   Name = "Рисовать FOV",  Default = true },
        { Type = "Color",    Name = "Цвет FOV",      Default = Color3.fromRGB(141, 126, 255) },
        { Type = "Button",   Name = "ПРЕСЕТ: РЕЙДЖ (HVH)", Callback = function(F)
            if F._sliders then
                if F._sliders["Скорость"] then F._sliders["Скорость"](100) end
                if F._sliders["Предсказание"] then F._sliders["Предсказание"](60) end
                if F._sliders["Радиус FOV"] then F._sliders["Радиус FOV"](500) end
                if F._sliders["Радиус выстрела"] then F._sliders["Радиус выстрела"](45) end
                if F._sliders["Пауза выстрела"] then F._sliders["Пауза выстрела"](0.08) end
            end
            if F._toggles then
                if F._toggles["Мгновенный снап"] then F._toggles["Мгновенный снап"](true) end
                if F._toggles["Автовыстрел"] then F._toggles["Автовыстрел"](true) end
            end
        end },
        { Type = "Button",   Name = "ПРЕСЕТ: ЛЕГИТ", Callback = function(F)
            if F._sliders then
                if F._sliders["Скорость"] then F._sliders["Скорость"](12) end
                if F._sliders["Предсказание"] then F._sliders["Предсказание"](0) end
                if F._sliders["Радиус FOV"] then F._sliders["Радиус FOV"](120) end
                if F._sliders["Пауза выстрела"] then F._sliders["Пауза выстрела"](0.15) end
            end
            if F._toggles then
                if F._toggles["Автовыстрел"] then F._toggles["Автовыстрел"](false) end
            end
        end },
    },
})

local strafeState = { engaged = false, angle = 0, phase = "fly", target = nil, holdT = 0, flyT = 0 }

local StrafeF = AddFunction("combat", "Right", {
    Name = "Target Strafe", Hold = true, Bind = Enum.KeyCode.Q,
    Settings = {
        { Type = "Slider",   Name = "Задержка",        Min = 0.5, Max = 4, Default = 2, Suffix = "с" },
        { Type = "Toggle",   Name = "Мгновенный захват", Default = false },
        { Type = "Toggle",   Name = "Камера на цель",  Default = false },
        { Type = "Slider",   Name = "Радиус",          Min = 3, Max = 20, Default = 8, Int = true, Suffix = "st" },
        { Type = "Slider",   Name = "Скорость",        Min = 90, Max = 1440, Default = 540, Int = true, Suffix = "°/с" },
        { Type = "Slider",   Name = "Высота",          Min = 0, Max = 12, Default = 4, Int = true, Suffix = "st" },
        { Type = "Slider",   Name = "Скорость полёта", Min = 60, Max = 400, Default = 260, Int = true },
        { Type = "Toggle",   Name = "Ноклип в полёте", Default = true },
    },
})

--────────────────────────────────────────────────────────────── MOVEMENT
AddSection("movement", "Left", "Передвижение")
AddSection("movement", "Right", "Прочее")

local NoclipF = AddFunction("movement", "Left", {
    Name = "Noclip", Bind = Enum.KeyCode.N,
    Settings = {
        { Type = "Toggle", Name = "Постоянно", Default = true },
        { Type = "Toggle", Name = "Возвращать коллизии", Default = true },
    },
    OnDisable = function() setNoclip(LocalPlayer, false) end,
})

local SpeedGlitchF = AddFunction("movement", "Left", {
    Name = "Speed Glitch",
    Settings = {
        { Type = "Slider",   Name = "Ускорение", Min = 10, Max = 150, Default = 60, Int = true, Suffix = "st/s" },
        { Type = "Dropdown", Name = "Направление", Options = { "Взгляд", "По движению" }, Default = "Взгляд" },
        { Type = "Toggle",   Name = "Только в воздухе", Default = true },
    },
})

local BhopF = AddFunction("movement", "Right", {
    Name = "Bunny Hop", Bind = Enum.KeyCode.B,
    Settings = {
        { Type = "Slider", Name = "Сила прыжка", Min = 30, Max = 120, Default = 50, Int = true },
        { Type = "Toggle", Name = "Только в движении", Default = false },
    },
    OnEnable = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.UseJumpPower = true end
    end,
    OnDisable = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = 50 end
    end,
})

local SpinF = AddFunction("movement", "Right", {
    Name = "Spin", Bind = Enum.KeyCode.T,
    Settings = {
        { Type = "Slider",   Name = "Скорость", Min = 90, Max = 1440, Default = 360, Int = true, Suffix = "°/с" },
        { Type = "Dropdown", Name = "Направление", Options = { "Вправо", "Влево" }, Default = "Вправо" },
        { Type = "Toggle",   Name = "Только стоя", Default = false },
    },
    OnEnable = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
    end,
    OnDisable = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end,
})

--────────────────────────────────────────────────────────────── VISUAL
AddSection("visual", "Left", "Мир")
AddSection("visual", "Right", "Игроки и экран")

local SkyF = AddFunction("visual", "Left", {
    Name = "Skybox Changer",
    Settings = {
        { Type = "Dropdown", Name = "Пресет", Options = { "Стандарт", "Полночь", "Закат", "Vaporwave", "Бездна", "Неон" }, Default = "Стандарт",
            Callback = function(v) applySky(v) end },
        { Type = "Toggle", Name = "Убрать облака", Default = false, Callback = function(v)
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            local clouds = terrain and terrain:FindFirstChildOfClass("Clouds")
            if clouds then clouds.Enabled = not v end
        end },
    },
    OnDisable = function() applySky("Стандарт") end,
})

local chamsStore = {}
local ChamsF = AddFunction("visual", "Left", {
    Name = "Chams",
    Settings = {
        { Type = "Dropdown", Name = "Режим",        Options = { "Команда", "Свой цвет", "Радуга" }, Default = "Команда" },
        { Type = "Color",    Name = "Цвет заливки", Default = Color3.fromRGB(255, 80, 80) },
        { Type = "Slider",   Name = "Прозрачность", Min = 0, Max = 1, Default = 0.65 },
        { Type = "Toggle",   Name = "Контур",       Default = true },
        { Type = "Color",    Name = "Цвет контура", Default = Color3.new(1, 1, 1) },
        { Type = "Toggle",   Name = "Через стены",  Default = true },
        { Type = "Toggle",   Name = "Только враги", Default = true },
    },
    OnDisable = function()
        for _, hl in pairs(chamsStore) do if hl then hl:Destroy() end end
        table.clear(chamsStore)
    end,
})

local OovF = AddFunction("visual", "Right", {
    Name = "Out of View Arrows",
    Settings = {
        { Type = "Dropdown", Name = "Режим",    Options = { "Свой цвет", "Команда", "Радуга" }, Default = "Свой цвет" },
        { Type = "Color",    Name = "Цвет",     Default = Color3.fromRGB(255, 90, 90) },
        { Type = "Slider",   Name = "Размер",   Min = 14, Max = 40, Default = 24, Int = true, Suffix = "px" },
        { Type = "Slider",   Name = "Отступ",   Min = 30, Max = 160, Default = 70, Int = true, Suffix = "px" },
        { Type = "Toggle",   Name = "Дистанция", Default = true },
    },
})

local TespF = AddFunction("visual", "Right", {
    Name = "Target ESP",
    Settings = {
        { Type = "Dropdown", Name = "Режим цели",     Options = { "Под курсором", "Ближайший к прицелу" }, Default = "Под курсором" },
        { Type = "Slider",   Name = "Радиус поиска",  Min = 50, Max = 600, Default = 250, Int = true, Suffix = "px" },
        { Type = "Slider",   Name = "Макс. дистанция", Min = 0, Max = 500, Default = 0, Int = true, Suffix = "st" },
        { Type = "Slider",   Name = "Размер",         Min = 40, Max = 220, Default = 90, Int = true, Suffix = "px" },
        { Type = "Toggle",   Name = "Масштаб по дистанции", Default = true },
        { Type = "Color",    Name = "Цвет",           Default = Color3.fromRGB(255, 70, 255) },
        { Type = "Toggle",   Name = "Радуга",         Default = false },
        { Type = "Slider",   Name = "Толщина",        Min = 1, Max = 6, Default = 3, Int = true },
        { Type = "Slider",   Name = "Длина углов",    Min = 10, Max = 50, Default = 25, Int = true, Suffix = "%" },
        { Type = "Toggle",   Name = "Свечение",       Default = true },
        { Type = "Dropdown", Name = "Вращение",       Options = { "По часовой", "Против часовой" }, Default = "По часовой" },
        { Type = "Slider",   Name = "Скорость вращения", Min = 20, Max = 720, Default = 140, Int = true, Suffix = "°/с" },
        { Type = "Toggle",   Name = "Team Check",     Default = true },
        { Type = "Toggle",   Name = "Дистанция",      Default = true },
    },
})

local ColorPlusF = AddFunction("visual", "Right", {
    Name = "Color Plus",
    Settings = {
        { Type = "Slider", Name = "Контраст",     Min = -0.5, Max = 0.5, Default = 0.15 },
        { Type = "Slider", Name = "Насыщенность", Min = -1, Max = 1, Default = 0.2 },
        { Type = "Slider", Name = "Яркость",       Min = -0.3, Max = 0.3, Default = 0 },
        { Type = "Color",  Name = "Оттенок",       Default = Color3.new(1, 1, 1) },
    },
})

local FogF = AddFunction("visual", "Right", {
    Name = "Fog Blur",
    Settings = {
        { Type = "Slider", Name = "Туман", Min = 0, Max = 1, Default = 0.4 },
        { Type = "Slider", Name = "Блюр",  Min = 0, Max = 24, Default = 6, Int = true },
        { Type = "Color",  Name = "Цвет тумана", Default = Color3.fromRGB(160, 175, 200) },
    },
})

local FovF = AddFunction("visual", "Right", {
    Name = "FOV Changer",
    Settings = {
        { Type = "Slider", Name = "Значение", Min = 40, Max = 120, Default = 70, Int = true, Suffix = "°" },
    },
})

local StretchF = AddFunction("visual", "Right", {
    Name = "Растяжение экрана",
    Settings = {
        { Type = "Dropdown", Name = "Формат",  Options = { "4:3", "5:4", "16:10" }, Default = "4:3" },
        { Type = "Toggle",   Name = "Полосы (letterbox)", Default = false },
    },
})

local tpSaved = nil
local TPF = AddFunction("visual", "Right", {
    Name = "Third Person",
    Settings = {
        { Type = "Slider", Name = "Дистанция",   Min = 2, Max = 40, Default = 10, Int = true, Suffix = "st" },
        { Type = "Slider", Name = "Высота",      Min = -5, Max = 10, Default = 0, Int = true, Suffix = "st" },
        { Type = "Slider", Name = "Сдвиг вбок",  Min = -5, Max = 5, Default = 0, Int = true, Suffix = "st" },
        { Type = "Toggle", Name = "Принудительно", Default = true },
        { Type = "Toggle", Name = "Шифт Лок", Default = false, Callback = function(v)
            if not v and TPF.Enabled then applyShiftLock(false) end
        end },
    },
    OnDisable = function()
        if tpSaved then
            LocalPlayer.CameraMode = tpSaved.Mode
            LocalPlayer.CameraMinZoomDistance = tpSaved.Min
            LocalPlayer.CameraMaxZoomDistance = tpSaved.Max
            tpSaved = nil
        end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.zero end
        applyShiftLock(false)
    end,
})

--────────────────────────────────────────────────────────────── CUSTOM MODEL
-- Скины встроены в код: строим модель из деталей, без папок и ID с маркетплейса
local cmActive, cmSaved, cmLast, cmConn = nil, nil, nil, nil

local function newPart(shape, size, color, material)
    local p = Instance.new("Part")
    p.Shape = shape
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.CanCollide = false
    p.Massless = true
    p.CastShadow = false
    p.Anchored = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local function stdHumanoid(colors, eyeColor, scale, bodyMat)
    scale = scale or 1
    return {
        { Enum.PartType.Block, Vector3.new(2, 2, 1) * scale,       colors.Torso, CFrame.new(0, 0, 0), bodyMat },
        { Enum.PartType.Block, Vector3.new(1.2, 1.2, 1.2) * scale, colors.Head,  CFrame.new(0, 1.6 * scale, 0), bodyMat },
        { Enum.PartType.Block, Vector3.new(1, 2, 1) * scale,       colors.Arm,   CFrame.new(-1.5 * scale, 0, 0), bodyMat },
        { Enum.PartType.Block, Vector3.new(1, 2, 1) * scale,       colors.Arm,   CFrame.new(1.5 * scale, 0, 0), bodyMat },
        { Enum.PartType.Block, Vector3.new(1, 2, 1) * scale,       colors.Leg,   CFrame.new(-0.5 * scale, -2 * scale, 0), bodyMat },
        { Enum.PartType.Block, Vector3.new(1, 2, 1) * scale,       colors.Leg,   CFrame.new(0.5 * scale, -2 * scale, 0), bodyMat },
        { Enum.PartType.Ball,  Vector3.new(0.24, 0.24, 0.24) * scale, eyeColor,  CFrame.new(-0.3 * scale, 1.72 * scale, 0.62 * scale), Enum.Material.Neon },
        { Enum.PartType.Ball,  Vector3.new(0.24, 0.24, 0.24) * scale, eyeColor,  CFrame.new(0.3 * scale, 1.72 * scale, 0.62 * scale), Enum.Material.Neon },
        { Enum.PartType.Block, Vector3.new(0.55, 0.12, 0.12) * scale, Color3.new(0, 0, 0), CFrame.new(0, 1.25 * scale, 0.62 * scale) },
    }
end

local function buildFromList(list)
    local m = Instance.new("Model")
    for _, d in ipairs(list) do
        local p = newPart(d[1], d[2], d[3], d[5])
        p.CFrame = d[4]
        p.Parent = m
    end
    return m
end

local SKIN_BUILDERS = {
    ["TUNG SAGUR"] = function()
        local wood, dark = Color3.fromRGB(105, 72, 45), Color3.fromRGB(78, 52, 32)
        return buildFromList({
            { Enum.PartType.Cylinder, Vector3.new(4.2, 2.1, 2.1), wood, CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.WoodPlanks },
            { Enum.PartType.Cylinder, Vector3.new(0.2, 2.12, 2.12), dark, CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.WoodPlanks },
            { Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), Color3.new(0, 0, 0), CFrame.new(-0.45, 1.2, 0.95) },
            { Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), Color3.new(0, 0, 0), CFrame.new(0.45, 1.2, 0.95) },
            { Enum.PartType.Block, Vector3.new(0.7, 0.14, 0.14), Color3.new(0, 0, 0), CFrame.new(0, 0.55, 0.98) },
            { Enum.PartType.Block, Vector3.new(0.45, 0.9, 0.45), dark, CFrame.new(-0.55, -2.15, 0), Enum.Material.WoodPlanks },
            { Enum.PartType.Block, Vector3.new(0.45, 0.9, 0.45), dark, CFrame.new(0.55, -2.15, 0), Enum.Material.WoodPlanks },
            { Enum.PartType.Cylinder, Vector3.new(2.6, 0.35, 0.35), dark, CFrame.new(1.7, -0.3, 0) * CFrame.Angles(0, 0, math.rad(35)), Enum.Material.Wood },
        })
    end,
    ["BIG NOOB"] = function()
        return buildFromList(stdHumanoid({
            Torso = Color3.fromRGB(13, 105, 172),
            Head  = Color3.fromRGB(245, 205, 48),
            Arm   = Color3.fromRGB(245, 205, 48),
            Leg   = Color3.fromRGB(75, 151, 75),
        }, Color3.new(0, 0, 0), 1.3, Enum.Material.SmoothPlastic))
    end,
    ["LAVA ZOMBI"] = function()
        local list = stdHumanoid({
            Torso = Color3.fromRGB(35, 32, 38),
            Head  = Color3.fromRGB(45, 40, 48),
            Arm   = Color3.fromRGB(30, 27, 33),
            Leg   = Color3.fromRGB(25, 22, 28),
        }, Color3.fromRGB(255, 110, 10), 1, Enum.Material.Slate)
        table.insert(list, { Enum.PartType.Block, Vector3.new(1.1, 1.1, 0.18), Color3.fromRGB(255, 100, 0), CFrame.new(0, 0.2, 0.55), Enum.Material.Neon })
        table.insert(list, { Enum.PartType.Block, Vector3.new(0.28, 1.3, 0.18), Color3.fromRGB(255, 80, 0), CFrame.new(-1.5, 0, 0), Enum.Material.Neon })
        table.insert(list, { Enum.PartType.Block, Vector3.new(0.28, 1.3, 0.18), Color3.fromRGB(255, 80, 0), CFrame.new(1.5, 0, 0), Enum.Material.Neon })
        return buildFromList(list)
    end,
    ["NUKE ZOMBI"] = function()
        local list = stdHumanoid({
            Torso = Color3.fromRGB(70, 160, 50),
            Head  = Color3.fromRGB(90, 200, 60),
            Arm   = Color3.fromRGB(55, 130, 40),
            Leg   = Color3.fromRGB(45, 110, 35),
        }, Color3.fromRGB(190, 255, 90), 1, Enum.Material.Slate)
        table.insert(list, { Enum.PartType.Block, Vector3.new(0.3, 0.9, 0.18), Color3.fromRGB(200, 255, 100), CFrame.new(0, 0.1, 0.55), Enum.Material.Neon })
        return buildFromList(list)
    end,
    ["RICK PRIME"] = function()
        local skin   = Color3.fromRGB(226, 199, 168)
        local hair   = Color3.fromRGB(183, 214, 232)
        local jacket = Color3.fromRGB(33, 33, 44)
        local red    = Color3.fromRGB(168, 34, 42)
        local pants  = Color3.fromRGB(42, 44, 56)
        local grey   = Color3.fromRGB(148, 152, 162)
        local boots  = Color3.fromRGB(26, 26, 30)
        local L = {
            { Enum.PartType.Block, Vector3.new(2, 2.1, 1.05), jacket, CFrame.new(0, 0, 0) },
            { Enum.PartType.Block, Vector3.new(1.5, 0.35, 1.1), jacket, CFrame.new(0, 1.1, 0) },
            { Enum.PartType.Block, Vector3.new(0.95, 0.16, 0.06), red, CFrame.new(-0.45, 0.3, 0.54) * CFrame.Angles(0, 0, math.rad(-35)) },
            { Enum.PartType.Block, Vector3.new(0.95, 0.16, 0.06), red, CFrame.new(0.45, 0.3, 0.54) * CFrame.Angles(0, 0, math.rad(35)) },
            { Enum.PartType.Block, Vector3.new(2.02, 0.22, 1.07), Color3.fromRGB(20, 20, 26), CFrame.new(0, -0.95, 0) },
            { Enum.PartType.Block, Vector3.new(0.85, 0.45, 0.95), grey, CFrame.new(-1.05, 0.95, 0) * CFrame.Angles(0, 0, math.rad(12)) },
            { Enum.PartType.Block, Vector3.new(0.5, 2.3, 0.5), jacket, CFrame.new(-1.25, -0.15, 0) },
            { Enum.PartType.Block, Vector3.new(0.5, 2.3, 0.5), jacket, CFrame.new(1.25, -0.15, 0) },
            { Enum.PartType.Block, Vector3.new(0.54, 0.18, 0.54), grey, CFrame.new(-1.25, -1.15, 0) },
            { Enum.PartType.Block, Vector3.new(0.54, 0.18, 0.54), grey, CFrame.new(1.25, -1.15, 0) },
            { Enum.PartType.Block, Vector3.new(0.44, 0.5, 0.44), skin, CFrame.new(-1.25, -1.5, 0) },
            { Enum.PartType.Block, Vector3.new(0.44, 0.5, 0.44), skin, CFrame.new(1.25, -1.5, 0) },
            { Enum.PartType.Block, Vector3.new(0.55, 1.85, 0.55), pants, CFrame.new(-0.5, -1.925, 0) },
            { Enum.PartType.Block, Vector3.new(0.55, 1.85, 0.55), pants, CFrame.new(0.5, -1.925, 0) },
            { Enum.PartType.Block, Vector3.new(0.72, 0.55, 0.78), boots, CFrame.new(-0.5, -3.1, 0.02) },
            { Enum.PartType.Block, Vector3.new(0.72, 0.55, 0.78), boots, CFrame.new(0.5, -3.1, 0.02) },
            { Enum.PartType.Block, Vector3.new(0.74, 0.14, 0.92), boots, CFrame.new(-0.5, -3.36, 0.06) },
            { Enum.PartType.Block, Vector3.new(0.74, 0.14, 0.92), boots, CFrame.new(0.5, -3.36, 0.06) },
            { Enum.PartType.Block, Vector3.new(1.45, 1.25, 1.3), skin, CFrame.new(0, 1.95, 0) },
            { Enum.PartType.Block, Vector3.new(0.26, 0.36, 0.44), skin, CFrame.new(0, 1.9, 0.75) },
            { Enum.PartType.Block, Vector3.new(1.05, 0.13, 0.1), Color3.fromRGB(155, 170, 185), CFrame.new(0, 2.3, 0.6) },
            { Enum.PartType.Ball, Vector3.new(0.46, 0.54, 0.3), Color3.new(1, 1, 1), CFrame.new(-0.34, 2.0, 0.58) },
            { Enum.PartType.Ball, Vector3.new(0.46, 0.54, 0.3), Color3.new(1, 1, 1), CFrame.new(0.34, 2.0, 0.58) },
            { Enum.PartType.Ball, Vector3.new(0.12, 0.12, 0.12), Color3.new(0, 0, 0), CFrame.new(-0.34, 2.0, 0.7) },
            { Enum.PartType.Ball, Vector3.new(0.12, 0.12, 0.12), Color3.new(0, 0, 0), CFrame.new(0.34, 2.0, 0.7) },
            { Enum.PartType.Block, Vector3.new(0.8, 0.16, 0.1), Color3.fromRGB(72, 42, 42), CFrame.new(0, 1.55, 0.6) },
            { Enum.PartType.Block, Vector3.new(0.66, 0.07, 0.1), Color3.new(1, 1, 1), CFrame.new(0, 1.6, 0.61) },
            { Enum.PartType.Block, Vector3.new(1.5, 0.65, 1.35), hair, CFrame.new(0, 2.5, -0.05) },
        }
        for _, s in ipairs({
            CFrame.new(0, 2.85, -0.1) * CFrame.Angles(math.rad(8), 0, 0),
            CFrame.new(-0.5, 2.65, 0.15) * CFrame.Angles(math.rad(20), 0, math.rad(-42)),
            CFrame.new(0.5, 2.65, 0.15) * CFrame.Angles(math.rad(20), 0, math.rad(42)),
            CFrame.new(-0.55, 2.4, -0.3) * CFrame.Angles(math.rad(-22), 0, math.rad(-58)),
            CFrame.new(0.55, 2.4, -0.3) * CFrame.Angles(math.rad(-22), 0, math.rad(58)),
            CFrame.new(0, 2.55, -0.6) * CFrame.Angles(math.rad(-50), 0, 0),
            CFrame.new(0, 2.6, 0.4) * CFrame.Angles(math.rad(45), 0, 0),
        }) do
            table.insert(L, { Enum.PartType.Block, Vector3.new(0.32, 1.05, 0.32), hair, s })
        end
        return buildFromList(L)
    end,
    ["MAFALDA"] = function()
        local skin  = Color3.fromRGB(240, 214, 189)
        local hair  = Color3.fromRGB(28, 28, 32)
        local dress = Color3.fromRGB(205, 45, 45)
        local white = Color3.new(1, 1, 1)
        local shoes = Color3.fromRGB(25, 25, 28)
        local L = {
            { Enum.PartType.Block, Vector3.new(2, 2.1, 1.1), dress, CFrame.new(0, 0, 0) },
            { Enum.PartType.Cylinder, Vector3.new(0.3, 1.9, 1.9), white, CFrame.new(0, 1.0, 0) * CFrame.Angles(0, 0, math.rad(90)) },
            { Enum.PartType.Block, Vector3.new(2.04, 0.22, 1.14), white, CFrame.new(0, -0.99, 0) },
            { Enum.PartType.Block, Vector3.new(0.66, 0.55, 0.66), dress, CFrame.new(-1.25, 0.8, 0) },
            { Enum.PartType.Block, Vector3.new(0.66, 0.55, 0.66), dress, CFrame.new(1.25, 0.8, 0) },
            { Enum.PartType.Block, Vector3.new(0.52, 1.7, 0.52), skin, CFrame.new(-1.25, -0.35, 0) },
            { Enum.PartType.Block, Vector3.new(0.52, 1.7, 0.52), skin, CFrame.new(1.25, -0.35, 0) },
            { Enum.PartType.Block, Vector3.new(0.5, 1.85, 0.5), skin, CFrame.new(-0.45, -2.0, 0) },
            { Enum.PartType.Block, Vector3.new(0.5, 1.85, 0.5), skin, CFrame.new(0.45, -2.0, 0) },
            { Enum.PartType.Block, Vector3.new(0.54, 0.28, 0.54), white, CFrame.new(-0.45, -2.85, 0) },
            { Enum.PartType.Block, Vector3.new(0.54, 0.28, 0.54), white, CFrame.new(0.45, -2.85, 0) },
            { Enum.PartType.Block, Vector3.new(0.58, 0.3, 0.82), shoes, CFrame.new(-0.45, -3.1, 0.08) },
            { Enum.PartType.Block, Vector3.new(0.58, 0.3, 0.82), shoes, CFrame.new(0.45, -3.1, 0.08) },
            { Enum.PartType.Block, Vector3.new(1.7, 1.5, 1.55), skin, CFrame.new(0, 2.05, 0) },
            { Enum.PartType.Block, Vector3.new(1.78, 1.5, 0.55), hair, CFrame.new(0, 2.1, -0.55) },
            { Enum.PartType.Block, Vector3.new(1.78, 0.55, 1.6), hair, CFrame.new(0, 2.8, -0.05) },
            { Enum.PartType.Block, Vector3.new(0.38, 1.35, 1.5), hair, CFrame.new(-0.88, 2.0, -0.1) },
            { Enum.PartType.Block, Vector3.new(0.38, 1.35, 1.5), hair, CFrame.new(0.88, 2.0, -0.1) },
            { Enum.PartType.Block, Vector3.new(1.78, 0.5, 0.35), hair, CFrame.new(0, 2.6, 0.62) },
            { Enum.PartType.Ball, Vector3.new(0.5, 0.56, 0.3), white, CFrame.new(-0.38, 2.05, 0.68) },
            { Enum.PartType.Ball, Vector3.new(0.5, 0.56, 0.3), white, CFrame.new(0.38, 2.05, 0.68) },
            { Enum.PartType.Ball, Vector3.new(0.14, 0.14, 0.14), Color3.new(0, 0, 0), CFrame.new(-0.38, 2.05, 0.8) },
            { Enum.PartType.Ball, Vector3.new(0.14, 0.14, 0.14), Color3.new(0, 0, 0), CFrame.new(0.38, 2.05, 0.8) },
            { Enum.PartType.Ball, Vector3.new(0.14, 0.14, 0.14), Color3.fromRGB(214, 170, 140), CFrame.new(0, 1.8, 0.8) },
            { Enum.PartType.Block, Vector3.new(0.4, 0.08, 0.08), Color3.fromRGB(120, 60, 60), CFrame.new(0, 1.6, 0.78) },
        }
        return buildFromList(L)
    end,
}

local function cmClear()
    if cmConn then cmConn:Disconnect(); cmConn = nil end
    if cmActive and cmActive.Parent then cmActive:Destroy() end
    cmActive = nil
    if cmSaved then
        for _, e in ipairs(cmSaved) do
            if e[1] and e[1].Parent then e[1].Transparency = e[2] end
        end
    end
    cmSaved = nil
end

local function cmApply(F)
    cmClear()
    local builder = SKIN_BUILDERS[F.S["Скин"]]
    if not builder then return end
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local list = {}
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            table.insert(list, { d, d.Transparency })
            d.Transparency = 1
        elseif d:IsA("Decal") then
            table.insert(list, { d, d.Transparency })
            d.Transparency = 1
        end
    end
    cmSaved = list
    local model = builder()
    model.Name = "KOCMOC_Custom"
    model.Parent = c
    pcall(function()
        local sc = F.S["Размер"] or 1
        if sc ~= 1 and model.ScaleTo then model:ScaleTo(sc) end
    end)
    model:PivotTo(hrp.CFrame * CFrame.Angles(0, math.rad(F.S["Поворот"] or 0), 0) + Vector3.new(0, F.S["Сдвиг вверх"] or 0, 0))
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            local w = Instance.new("WeldConstraint")
            w.Part0 = hrp
            w.Part1 = d
            w.Parent = d
        end
    end
    cmActive = model
    cmLast = F
    cmConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.8)
        if cmLast and cmLast.Enabled then cmApply(cmLast) end
    end)
end

local CustomModelF = AddFunction("visual", "Right", {
    Name = "Custom Model",
    Settings = {
        { Type = "Dropdown", Name = "Скин", Options = { "TUNG SAGUR", "BIG NOOB", "LAVA ZOMBI", "NUKE ZOMBI", "RICK PRIME", "MAFALDA" }, Default = "TUNG SAGUR",
            Callback = function(_, F) if F.Enabled then cmApply(F) end end },
        { Type = "Slider", Name = "Размер",      Min = 0.2, Max = 4, Default = 1, Suffix = "x",
            Callback = function(_, F) if F.Enabled then cmApply(F) end end },
        { Type = "Slider", Name = "Сдвиг вверх", Min = -3, Max = 3, Default = 0, Suffix = "st",
            Callback = function(_, F) if F.Enabled then cmApply(F) end end },
        { Type = "Slider", Name = "Поворот",     Min = -180, Max = 180, Default = 0, Suffix = "°",
            Callback = function(_, F) if F.Enabled then cmApply(F) end end },
        { Type = "Button", Name = "ПЕРЕОДЕТЬ", Callback = function(F) cmApply(F) end },
        { Type = "Button", Name = "СНЯТЬ СКИН", Callback = function() cmClear() end },
    },
    OnEnable = function(F) cmApply(F) end,
    OnDisable = function() cmClear() end,
})

-- Авто-скрытие скина в первом лице
RunService.RenderStepped:Connect(function()
    if cmActive and cmActive.Parent then
        local hrp = getHRP(LocalPlayer)
        local hide = hrp and (Camera.CFrame.Position - hrp.Position).Magnitude < 2
        for _, d in ipairs(cmActive:GetDescendants()) do
            if d:IsA("BasePart") then
                d.LocalTransparencyModifier = hide and 1 or 0
            end
        end
    end
end)

--────────────────────────────────────────────────────────────── HUD
AddSection("hud", "Left", "Информация")
AddSection("hud", "Right", "Экран")

local PlayerHudF = AddFunction("hud", "Left", {
    Name = "Player HUD",
    Settings = {
        { Type = "Slider", Name = "Радиус",          Min = 5, Max = 50, Default = 15, Int = true, Suffix = "st" },
        { Type = "Toggle", Name = "При наведении",   Default = true },
        { Type = "Toggle", Name = "Аватар",          Default = true },
        { Type = "Toggle", Name = "Дистанция",       Default = true },
    },
})

local TSInfoF = AddFunction("hud", "Left", {
    Name = "Target Strafe Info",
    Settings = {
        { Type = "Dropdown", Name = "Позиция", Options = { "Слева сверху", "Центр сверху", "Справа сверху", "Слева снизу", "Центр снизу", "Справа снизу" }, Default = "Справа сверху",
            Callback = function(v) applyPos(TSInfo, v) end },
        { Type = "Toggle", Name = "Полоса наведения", Default = true },
        { Type = "Toggle", Name = "Аватар цели",      Default = true },
        { Type = "Toggle", Name = "HP цели",          Default = true },
        { Type = "Toggle", Name = "Дистанция",        Default = true },
    },
})

local WatermarkF = AddFunction("hud", "Left", {
    Name = "Watermark", Default = true,
    Settings = {
        { Type = "Dropdown", Name = "Позиция", Options = { "Слева сверху", "Центр сверху", "Справа сверху", "Слева снизу", "Центр снизу", "Справа снизу" }, Default = "Слева сверху",
            Callback = function(v) applyPos(Watermark, v) end },
        { Type = "Toggle", Name = "Часы", Default = true },
        { Type = "Toggle", Name = "FPS",  Default = true },
        { Type = "Toggle", Name = "Пинг", Default = true },
    },
})

local KeysF = AddFunction("hud", "Left", {
    Name = "Keystrokes",
    Settings = {
        { Type = "Dropdown", Name = "Позиция", Options = { "Слева сверху", "Слева снизу", "Справа снизу", "Справа сверху" }, Default = "Слева снизу",
            Callback = function(v) applyPos(Keystrokes, v) end },
        { Type = "Toggle", Name = "Кнопки мыши", Default = true },
        { Type = "Slider", Name = "Прозрачность", Min = 0, Max = 0.8, Default = 0.25 },
    },
})

local CrosshairF = AddFunction("hud", "Right", {
    Name = "Crosshair",
    Settings = {
        { Type = "Dropdown", Name = "Режим",  Options = { "Центр", "Мышь" }, Default = "Центр" },
        { Type = "Dropdown", Name = "Стиль",  Options = { "Крест", "Точка", "Круг" }, Default = "Крест",
            Callback = function(v, F) buildCrosshair(v, (F.S["Размер"] or 10), (F.S["Толщина"] or 2), F.S["Цвет"]) end },
        { Type = "Slider", Name = "Размер",  Min = 4, Max = 30, Default = 10, Int = true,
            Callback = function(_, F) buildCrosshair(F.S["Стиль"] or "Крест", F.S["Размер"] or 10, F.S["Толщина"] or 2, F.S["Цвет"]) end },
        { Type = "Slider", Name = "Толщина", Min = 1, Max = 4, Default = 2, Int = true,
            Callback = function(_, F) buildCrosshair(F.S["Стиль"] or "Крест", F.S["Размер"] or 10, F.S["Толщина"] or 2, F.S["Цвет"]) end },
        { Type = "Color",  Name = "Цвет",    Default = Color3.fromRGB(141, 126, 255),
            Callback = function(c, F) buildCrosshair(F.S["Стиль"] or "Крест", F.S["Размер"] or 10, F.S["Толщина"] or 2, c) end },
        { Type = "Toggle", Name = "Радуга",  Default = false },
        { Type = "Toggle", Name = "Только при шифт локе", Default = false },
    },
})

local SpeedoF = AddFunction("hud", "Right", {
    Name = "Speedometer",
    Settings = {
        { Type = "Dropdown", Name = "Позиция", Options = { "Центр снизу", "Слева снизу", "Справа снизу" }, Default = "Центр снизу",
            Callback = function(v) applyPos(Speedo, v) end },
        { Type = "Toggle", Name = "Сглаживание", Default = true },
        { Type = "Slider", Name = "Точность", Min = 0, Max = 2, Default = 1, Int = true },
    },
})

local LogsF = AddFunction("hud", "Right", {
    Name = "Hit Logs",
    Settings = {
        { Type = "Slider", Name = "Строк",        Min = 3, Max = 10, Default = 5, Int = true },
        { Type = "Slider", Name = "Время жизни",  Min = 2, Max = 15, Default = 6, Int = true, Suffix = "с" },
        { Type = "Toggle", Name = "Дистанция",    Default = true },
    },
})

local RadarF = AddFunction("hud", "Right", {
    Name = "Radar",
    Settings = {
        { Type = "Slider", Name = "Размер",         Min = 120, Max = 220, Default = 160, Int = true, Suffix = "px",
            Callback = function(v) Radar.Size = UDim2.fromOffset(v, v) end },
        { Type = "Slider", Name = "Дистанция",      Min = 50, Max = 400, Default = 150, Int = true, Suffix = "st" },
        { Type = "Toggle", Name = "Поворот по камере", Default = true },
        { Type = "Toggle", Name = "Точки у края",   Default = true },
        { Type = "Toggle", Name = "Только враги",   Default = true },
    },
})

--────────────────────────────────────────────────────────────── SETTINGS
AddSection("settings", "Left", "HUD и меню")
AddSection("settings", "Right", "Прочее")

AddFunction("settings", "Left", {
    Name = "Перемещать HUD",
    Settings = {
        { Type = "Button", Name = "Сбросить позиции", Callback = function()
            for f, d in pairs(hudDefaults) do f.AnchorPoint = d[1]; f.Position = d[2] end
        end },
    },
    OnEnable = function() State.UnlockHUD = true end,
    OnDisable = function() State.UnlockHUD = false end,
})

local fakeF = { S = {} }
MakeColor(Pages.settings.Left, { Name = "Цвет меню", Default = Theme.Accent, Callback = function(c) SetAccent(c) end }, fakeF)
MakeToggle(Pages.settings.Left, { Name = "Размытие фона", Default = true, Callback = function(v)
    State.MenuBlur = v
    if State.Open then Tween(menuBlur, { Size = v and 18 or 0 }, 0.3) end
end }, fakeF)
MakeSlider(Pages.settings.Left, { Name = "Прозрачность стекла", Min = 0, Max = 0.6, Default = 0.14, Callback = function(v)
    Root.BackgroundTransparency = v
end }, fakeF)
MakeSlider(Pages.settings.Left, { Name = "Масштаб меню", Min = 0.8, Max = 1.25, Default = 1, Callback = function(v)
    State.MenuScale = v
    if State.Open then Tween(RootScale, { Scale = v }, 0.25) end
end }, fakeF)
MakeSlider(Pages.settings.Left, { Name = "Масштаб HUD", Min = 0.75, Max = 1.35, Default = 1, Callback = function(v)
    hudScale.Scale = v
end }, fakeF)

do
    local h = ctrlHolder(Pages.settings.Left, 26)
    Label(h, { Text = "Клавиша меню", TextSize = 12, TextColor3 = Theme.TextDim, Size = UDim2.new(1, -146, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local btn = Create("TextButton", { Text = keyName(State.OpenKey), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(136, 22), BackgroundColor3 = Theme.Bg3, TextSize = 11, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Text, AutoButtonColor = false, BorderSizePixel = 0 }, h)
    Corner(6, btn)
    btn.MouseButton1Click:Connect(function()
        StartBindCapture({ Name = "Клавиша меню", SetBind = function(k)
            if k then State.OpenKey = k; btn.Text = keyName(k) end
        end })
    end)
end

MakeButton(Pages.settings.Right, { Name = "Выключить все функции", Callback = function()
    for _, F in ipairs(Functions) do if F.Enabled then F.SetState(false) end end
end })
MakeButton(Pages.settings.Right, { Name = "Сбросить освещение", Callback = function()
    applySky("Стандарт")
    fogBlur.Size = 0
    ccPlus.Contrast = 0; ccPlus.Saturation = 0; ccPlus.Brightness = 0; ccPlus.TintColor = Color3.new(1, 1, 1)
end })

--────────────────────────────────────────────────────────────── ОТКРЫТИЕ МЕНЮ / DRAG
local function SetMenu(open)
    State.Open = open
    Root.Visible = true
    if open then
        Root.GroupTransparency = 1
        RootScale.Scale = 0.95
        Tween(Root, { GroupTransparency = 0 }, 0.28)
        Tween(RootScale, { Scale = State.MenuScale }, 0.35)
        Tween(menuBlur, { Size = State.MenuBlur and 18 or 0 }, 0.3)
        if TPF.Enabled and TPF.S["Шифт Лок"] then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    else
        Tween(Root, { GroupTransparency = 1 }, 0.22)
        Tween(RootScale, { Scale = 0.96 }, 0.25)
        Tween(menuBlur, { Size = 0 }, 0.25)
        task.delay(0.26, function() if not State.Open then Root.Visible = false end end)
    end
end

do
    local dragging, last = false, nil
    TopBar.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; last = mousePos() end
    end)
    UserInputService.InputChanged:Connect(function(io)
        if dragging and io.UserInputType == Enum.UserInputType.MouseMovement then
            local m = mousePos()
            local d = m - last; last = m
            Root.Position = UDim2.new(0.5, Root.Position.X.Offset + d.X, 0.5, Root.Position.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

--────────────────────────────────────────────────────────────── ВВОД: МЕНЮ + БИНДЫ
UserInputService.InputBegan:Connect(function(input, processed)
    if Binding then
        if input.KeyCode == Enum.KeyCode.Escape then
            -- отмена: бинд не трогаем
            Binding = nil; BindOverlay.Visible = false
            return
        end
        if input.KeyCode == Enum.KeyCode.Delete then
            -- удалить бинд
            if Binding.SetBind then Binding.SetBind(nil) end
            if Binding._drawChip then Binding._drawChip() end
            Binding = nil; BindOverlay.Visible = false
            return
        end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            if Binding.SetBind then Binding.SetBind(input.KeyCode) end
            if Binding._drawChip then Binding._drawChip() end
            Binding = nil; BindOverlay.Visible = false
        end
        return
    end
    if input.KeyCode == State.OpenKey then
        SetMenu(not State.Open)
        return
    end
    for _, F in ipairs(Functions) do
        if F.Bind and input.KeyCode == F.Bind then
            HeldKeys[F] = true
            if not F.Hold then F.SetState(not F.Enabled) end
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode ~= Enum.KeyCode.Unknown then
        for _, F in ipairs(Functions) do
            if F.Bind == input.KeyCode then HeldKeys[F] = nil end
        end
    end
end)

--────────────────────────────────────────────────────────────── HIT LOGS
local function watchHumanoid(pl, hum)
    local last = hum.Health
    hum.HealthChanged:Connect(function(hp)
        local old = last; last = hp
        if LogsF.Enabled and hp < old then
            local myhrp = getHRP(LocalPlayer)
            local thrp = getHRP(pl)
            local dist = (myhrp and thrp) and math.floor((thrp.Position - myhrp.Position).Magnitude + 0.5) or 0
            local row = Create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.3, BorderSizePixel = 0 }, LogsFrame)
            Corner(6, row)
            local lbl = Label(row, { Text = string.format("%s  ·  -%d hp%s", pl.DisplayName, math.floor(old - hp + 0.5), LogsF.S["Дистанция"] and ("  ·  " .. dist .. "m") or ""), TextSize = 11, TextColor3 = Color3.fromRGB(255, 130, 130), Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -12, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
            local kids = {}
            for _, c in ipairs(LogsFrame:GetChildren()) do if c:IsA("Frame") then table.insert(kids, c) end end
            while #kids > (LogsF.S["Строк"] or 5) do kids[1]:Destroy() end
            task.delay(LogsF.S["Время жизни"] or 6, function()
                if row.Parent then
                    Tween(row, { BackgroundTransparency = 1 }, 0.4)
                    Tween(lbl, { TextTransparency = 1 }, 0.4)
                    task.delay(0.4, function() row:Destroy() end)
                end
            end)
        end
    end)
end
local function hookCharacter(pl)
    pl.CharacterAdded:Connect(function(c)
        local hum = c:WaitForChild("Humanoid", 5)
        if hum then
            task.wait(0.1)
            watchHumanoid(pl, hum)
            if pl == LocalPlayer then
                if SpinF.Enabled then hum.AutoRotate = false end
                if BhopF.Enabled then hum.UseJumpPower = true end
            end
        end
    end)
    if pl.Character then
        local hum = pl.Character:FindFirstChildOfClass("Humanoid")
        if hum then watchHumanoid(pl, hum) end
    end
end
for _, pl in ipairs(Players:GetPlayers()) do hookCharacter(pl) end
Players.PlayerAdded:Connect(hookCharacter)

--────────────────────────────────────────────────────────────── ГЛАВНЫЕ ЦИКЛЫ
local wasAir = false
local spinAngle = 0
local speedSmooth = 0
local phudShown = false
local tsShown = false
local tesShown = false
local tesSpin = 0
local lastAimTarget = nil
local lastShot = 0
local originalFov = Camera.FieldOfView

RunService.Heartbeat:Connect(function(dt)
    -- Third Person
    if TPF.Enabled then
        if not tpSaved then
            tpSaved = {
                Mode = LocalPlayer.CameraMode,
                Min = LocalPlayer.CameraMinZoomDistance,
                Max = LocalPlayer.CameraMaxZoomDistance,
            }
        end
        local dist = TPF.S["Дистанция"] or 10
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        if TPF.S["Принудительно"] ~= false then
            if Camera.CameraType ~= Enum.CameraType.Custom then Camera.CameraType = Enum.CameraType.Custom end
        end
        LocalPlayer.CameraMinZoomDistance = dist
        LocalPlayer.CameraMaxZoomDistance = math.max(dist + 1, tpSaved.Max or dist + 1)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.CameraOffset = Vector3.new(TPF.S["Сдвиг вбок"] or 0, TPF.S["Высота"] or 0, 0)
        end
        if TPF.S["Шифт Лок"] then
            pcall(function()
                if UserGameSettings then
                    UserGameSettings.RotationType = Enum.RotationType.CameraRelative
                end
            end)
            if State.Open or Binding then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            else
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                UserInputService.MouseIconEnabled = false
            end
        end
    end
    -- Noclip
    if NoclipF.Enabled and (NoclipF.S["Постоянно"] or HeldKeys[NoclipF]) then
        local c = LocalPlayer.Character
        if c then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") and d.CanCollide then
                    d.CanCollide = false; noclipParts[d] = true
                end
            end
        end
    end
    -- Bunny Hop
    if BhopF.Enabled then
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then
            local jp = BhopF.S["Сила прыжка"] or 50
            hum.UseJumpPower = true
            if hum.JumpPower ~= jp then hum.JumpPower = jp end
            local moving = hum.MoveDirection.Magnitude > 0.05
            if (not BhopF.S["Только в движении"]) or moving then
                if hum.FloorMaterial ~= Enum.Material.Air then
                    hum.Jump = true
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                else
                    hum.Jump = false
                end
            end
        end
    end
    -- Speed Glitch
    if SpeedGlitchF.Enabled then
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = getHRP(LocalPlayer)
        if hum and hrp then
            local airborne = hum.FloorMaterial == Enum.Material.Air
            if (not wasAir) and airborne and (SpeedGlitchF.S["Только в воздухе"] ~= false or hum.Jump) then
                local boost = SpeedGlitchF.S["Ускорение"] or 60
                local dir
                if SpeedGlitchF.S["Направление"] == "По движению" and hum.MoveDirection.Magnitude > 0 then
                    dir = hum.MoveDirection
                else
                    local lv = Camera.CFrame.LookVector
                    dir = Vector3.new(lv.X, 0, lv.Z)
                    dir = (dir.Magnitude > 0.01) and dir.Unit or hrp.CFrame.LookVector
                end
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = dir * boost + Vector3.new(0, v.Y, 0)
            end
            wasAir = airborne
        end
    end
    -- Spin
    if SpinF.Enabled then
        local hrp = getHRP(LocalPlayer)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            if (not SpinF.S["Только стоя"]) or hum.MoveDirection.Magnitude <= 0.1 then
                spinAngle += (SpinF.S["Скорость"] or 360) * (SpinF.S["Направление"] == "Влево" and -1 or 1) * dt
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    -- AIM BOT PRO (3 режима: Всегда / Удержание / Свободный курсор)
    if AimbotF.Enabled then
        local aimMode = AimbotF.S["Режим"] or "Всегда"
        local active = aimMode ~= "Удержание" or HeldKeys[AimbotF]
        local freeCursor = aimMode == "Свободный курсор"
        FovCircle.Visible = AimbotF.S["Рисовать FOV"] and active or false
        if FovCircle.Visible then
            local r = AimbotF.S["Радиус FOV"] or 250
            FovCircle.Size = UDim2.fromOffset(r * 2, r * 2)
            local m = mousePos()
            FovCircle.Position = UDim2.fromOffset(m.X, m.Y)
            FovCircleStroke.Color = AimbotF.S["Цвет FOV"] or Theme.Accent
        end
        if active then
            if AimbotF.S["Форсировать камеру"] ~= false and Camera.CameraType ~= Enum.CameraType.Custom then
                Camera.CameraType = Enum.CameraType.Custom
            end
            local universal = AimbotF.S["Универсальный режим"] ~= false
            local ignoreFF = AimbotF.S["Игнор ForceField"] ~= false
            local m = mousePos()
            local fovR = AimbotF.S["Радиус FOV"] or 250
            local prio = AimbotF.S["Приоритет"] or "К прицелу"
            local pred = AimbotF.S["Предсказание"] or 0
            local mode = AimbotF.S["Цель"] or "Авто"
            local myhrp = getHRP(LocalPlayer)
            local best, bestScore, bestScreen, bestPos = nil, math.huge, nil, nil
            for _, pl in ipairs(Players:GetPlayers()) do
                if isEnemy(pl, AimbotF.S["Team Check"]) then
                    local c = aimCharAlive(pl, universal, ignoreFF)
                    if c then
                        local candList = findAimParts(c, mode)
                        if mode == "Случайно" and #candList > 1 then
                            candList = { candList[math.random(#candList)] }
                        end
                        for _, part in ipairs(candList) do
                            local aimPos = part.Position
                            if pred > 0 then
                                local vel = part.AssemblyLinearVelocity
                                if vel.Magnitude > 0.1 then
                                    aimPos = aimPos + vel * (pred / 100 * 0.5)
                                end
                            end
                            local v, onScreen = Camera:WorldToViewportPoint(aimPos)
                            if onScreen and v.Z > 0 then
                                local sd = (Vector2.new(v.X, v.Y) - m).Magnitude
                                if sd < fovR and ((not AimbotF.S["Проверка стен"]) or canSee(c, aimPos)) then
                                    local score = sd
                                    if prio == "По дистанции" then
                                        score = myhrp and (part.Position - myhrp.Position).Magnitude or sd
                                    elseif prio == "По HP" then
                                        local h = c:FindFirstChildOfClass("Humanoid")
                                        score = (h and h.Health) or sd
                                    end
                                    if score < bestScore then
                                        best, bestScore = part, score
                                        bestScreen, bestPos = Vector2.new(v.X, v.Y), aimPos
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if best and bestPos then
                -- камера крутится ТОЛЬКО не в режиме свободного курсора
                if not freeCursor then
                    if best ~= lastAimTarget and AimbotF.S["Мгновенный снап"] ~= false then
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, bestPos)
                    else
                        local goal = CFrame.lookAt(Camera.CFrame.Position, bestPos)
                        local spd = math.clamp(AimbotF.S["Скорость"] or 35, 1, 100)
                        if spd >= 99 then
                            Camera.CFrame = goal
                        else
                            Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(dt * spd * 0.35, 0, 1))
                        end
                    end
                end
                lastAimTarget = best
                if AimbotF.S["Автовыстрел"] and bestScreen then
                    local rS = AimbotF.S["Радиус выстрела"] or 25
                    if (bestScreen - m).Magnitude <= rS and os.clock() - lastShot >= (AimbotF.S["Пауза выстрела"] or 0.15) then
                        lastShot = os.clock()
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new())
                        end)
                    end
                end
            else
                lastAimTarget = nil
            end
        else
            FovCircle.Visible = false
            lastAimTarget = nil
        end
    else
        FovCircle.Visible = false
        lastAimTarget = nil
    end

    -- Target Strafe
    if StrafeF.Enabled and HeldKeys[StrafeF] then
        local hrp = getHRP(LocalPlayer)
        if not strafeState.engaged then
            local t = getMouseTarget(true)
            if t then
                strafeState.holdT += dt
                local req = StrafeF.S["Мгновенный захват"] and 0 or (StrafeF.S["Задержка"] or 2)
                if strafeState.holdT >= req then
                    strafeState.engaged, strafeState.target = true, t
                    strafeState.phase, strafeState.angle = "fly", 0
                    strafeState.flyT, strafeState.holdT = 0, 0
                    if StrafeF.S["Ноклип в полёте"] then setNoclip(LocalPlayer, true) end
                end
            else
                strafeState.holdT = 0
            end
        elseif hrp then
            local thrp = getHRP(strafeState.target)
            if thrp and strafeState.target.Character then
                local tpos = thrp.Position
                local radius = StrafeF.S["Радиус"] or 8
                local height = StrafeF.S["Высота"] or 4
                hrp.AssemblyLinearVelocity = Vector3.zero
                if strafeState.phase == "fly" then
                    strafeState.flyT += dt
                    local spd = (StrafeF.S["Скорость полёта"] or 260) * math.min(1, 0.45 + strafeState.flyT * 2.5)
                    local flat = (hrp.Position - tpos) * Vector3.new(1, 0, 1)
                    local dir = (flat.Magnitude > 0.01) and flat.Unit * radius or Vector3.new(radius, 0, 0)
                    local goal = tpos + dir + Vector3.new(0, height, 0)
                    local delta = goal - hrp.Position
                    if delta.Magnitude < 1.5 then
                        strafeState.phase = "orbit"
                    else
                        local step = math.min(delta.Magnitude, spd * dt)
                        hrp.CFrame = CFrame.lookAt(hrp.Position + delta.Unit * step, tpos)
                    end
                end
                if strafeState.phase == "orbit" then
                    strafeState.angle += math.rad(StrafeF.S["Скорость"] or 540) * dt
                    local pos = tpos + Vector3.new(math.cos(strafeState.angle) * radius, height, math.sin(strafeState.angle) * radius)
                    hrp.CFrame = CFrame.lookAt(pos, Vector3.new(tpos.X, pos.Y, tpos.Z))
                end
                if StrafeF.S["Камера на цель"] then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, tpos)
                end
            else
                strafeState.engaged = false
                setNoclip(LocalPlayer, false)
            end
        end
    else
        strafeState.holdT, strafeState.flyT = 0, 0
        if strafeState.engaged then
            strafeState.engaged = false
            setNoclip(LocalPlayer, false)
        end
    end

    -- FOV + растяжение (пластилин: без срезания, letterbox выкл по умолчанию)
    local baseFov = FovF.Enabled and (FovF.S["Значение"] or 70) or 70
    local finalFov, barW = baseFov, 0
    if StretchF.Enabled then
        local t = StretchF.S["Формат"]
        local ta = (t == "5:4" and 5 / 4) or (t == "16:10" and 16 / 10) or 4 / 3
        local vw, vh = Camera.ViewportSize.X, Camera.ViewportSize.Y
        local aspect = vw / math.max(vh, 1)
        if aspect > ta then
            finalFov = math.deg(2 * math.atan(math.tan(math.rad(baseFov) / 2) * (ta / aspect)))
            barW = math.max(0, (vw - vh * ta) / 2)
        end
    end
    if FovF.Enabled or StretchF.Enabled then
        Camera.FieldOfView = finalFov
    elseif Camera.FieldOfView ~= originalFov then
        Camera.FieldOfView = originalFov
    end
    local showBars = StretchF.Enabled and StretchF.S["Полосы (letterbox)"] and barW > 2
    BarLeft.Visible, BarRight.Visible = showBars or false, showBars or false
    if showBars then
        BarLeft.Size = UDim2.fromOffset(barW, Camera.ViewportSize.Y)
        BarRight.Size = UDim2.fromOffset(barW, Camera.ViewportSize.Y)
    end

    -- Chams
    if ChamsF.Enabled then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and ((not ChamsF.S["Только враги"]) or isEnemy(pl, true)) then
                local c = pl.Character
                if c then
                    local hl = chamsStore[pl]
                    if not hl or hl.Parent ~= c then
                        hl = Create("Highlight", { Name = "KOCMOC_Cham" }, c)
                        chamsStore[pl] = hl
                    end
                    hl.FillColor = resolveColor(ChamsF.S["Режим"], ChamsF.S["Цвет заливки"], pl, pl.UserId % 10 / 10)
                    hl.FillTransparency = ChamsF.S["Прозрачность"] or 0.65
                    hl.OutlineColor = ChamsF.S["Цвет контура"] or Color3.new(1, 1, 1)
                    hl.OutlineTransparency = ChamsF.S["Контур"] and 0.15 or 1
                    hl.DepthMode = ChamsF.S["Через стены"] and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.OccludedOnly
                end
            end
        end
    end

    -- Стрелки за экраном
    if OovF.Enabled then
        ArrowRoot.Visible = true
        local cxy = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local R = math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) / 2 - (OovF.S["Отступ"] or 70)
        local myhrp = getHRP(LocalPlayer)
        local i = 0
        local scaleFactor = (OovF.S["Размер"] or 24) / 24
        for _, pl in ipairs(Players:GetPlayers()) do
            if isEnemy(pl, false) and i < #arrows then
                local hrp = getHRP(pl)
                if hrp then
                    local v, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    local behind = v.Z <= 0
                    if (not onScreen or behind) and myhrp then
                        local dir = Vector2.new(v.X, v.Y) - cxy
                        if behind then dir = -dir end
                        if dir.Magnitude < 0.01 then dir = Vector2.new(0, 1) end
                        i += 1
                        local a = arrows[i]
                        a.Holder.Visible = true
                        local u = dir.Unit
                        a.Holder.Position = UDim2.fromOffset(cxy.X + u.X * R, cxy.Y + u.Y * R)
                        a.Holder.Rotation = math.deg(math.atan2(u.Y, u.X)) + 90
                        a.Holder.Size = UDim2.fromOffset(28, 28)
                        for _, l in ipairs(a.Lines) do
                            l.BackgroundColor3 = resolveColor(OovF.S["Режим"], OovF.S["Цвет"], pl, pl.UserId % 10 / 10)
                            l.Size = UDim2.fromOffset(math.max(math.sqrt(16 + 49), 1) * scaleFactor, 3 * scaleFactor)
                        end
                        a.Lines[1].Position = UDim2.new(0.5, -4 * scaleFactor, 0.5, 3 * scaleFactor)
                        a.Lines[1].Rotation = -60.3
                        a.Lines[2].Position = UDim2.new(0.5, 4 * scaleFactor, 0.5, 3 * scaleFactor)
                        a.Lines[2].Rotation = 60.3
                        if OovF.S["Дистанция"] then
                            a.Dist.Visible = true
                            a.Dist.Text = math.floor((hrp.Position - myhrp.Position).Magnitude + 0.5) .. "m"
                            a.Dist.TextColor3 = resolveColor(OovF.S["Режим"], OovF.S["Цвет"], pl, pl.UserId % 10 / 10)
                        else
                            a.Dist.Visible = false
                        end
                    end
                end
            end
        end
        for j = i + 1, #arrows do arrows[j].Holder.Visible = false end
    else
        ArrowRoot.Visible = false
    end

    -- Target ESP
    if TespF.Enabled then
        local teamChk = TespF.S["Team Check"] ~= false
        local target = nil
        if TespF.S["Режим цели"] == "Под курсором" then
            target = getMouseTarget(teamChk)
        else
            local m = mousePos()
            local bd = TespF.S["Радиус поиска"] or 250
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and isEnemy(pl, teamChk) then
                    local hrp = getHRP(pl)
                    if hrp then
                        local v = Camera:WorldToViewportPoint(hrp.Position)
                        if v.Z > 0 then
                            local d = (Vector2.new(v.X, v.Y) - m).Magnitude
                            if d < bd then bd, target = d, pl end
                        end
                    end
                end
            end
        end
        if target then
            local maxd = TespF.S["Макс. дистанция"] or 0
            if maxd > 0 then
                local my, th = getHRP(LocalPlayer), getHRP(target)
                if not (my and th) or (th.Position - my.Position).Magnitude > maxd then target = nil end
            end
        end
        if target and getCharacter(target) then
            local c = target.Character
            local center = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") or getHRP(target)
            if center then
                local v = Camera:WorldToViewportPoint(center.Position)
                if v.Z > 0 then
                    local sx, sy = v.X, v.Y
                    local S = TespF.S["Размер"] or 90
                    if TespF.S["Масштаб по дистанции"] then
                        local myhrp, thrp = getHRP(LocalPlayer), getHRP(target)
                        local dist = (myhrp and thrp) and (thrp.Position - myhrp.Position).Magnitude or 0
                        S = S * math.clamp(60 / (dist + 40), 0.35, 1.3)
                    end
                    S = math.max(S, 30)
                    local th = TespF.S["Толщина"] or 3
                    local glowOn = TespF.S["Свечение"] ~= false
                    local g1th, g2th = th * 2.4, th * 4.6
                    local gp = glowOn and math.ceil(g2th / 2) or 0
                    local F = math.ceil(S * 1.4143) + gp * 2 + 6
                    local off = math.floor((F - S) / 2)
                    if not tesShown then
                        tesShown = true
                        TESP.Visible = true
                        Tween(TESP, { GroupTransparency = 0 }, 0.12)
                    end
                    TESP.Position = UDim2.fromOffset(sx, sy)
                    TESP.Size = UDim2.fromOffset(F, F)
                    local dir = TespF.S["Вращение"] == "Против часовой" and -1 or 1
                    tesSpin = (tesSpin + dir * (TespF.S["Скорость вращения"] or 140) * dt) % 360
                    TESP.Rotation = tesSpin
                    local col = TespF.S["Радуга"] and rainbow(0) or (TespF.S["Цвет"] or Color3.fromRGB(255, 70, 255))
                    local L = math.max(8, S * ((TespF.S["Длина углов"] or 25) / 100))
                    L = math.min(L, S / 2)
                    local x0, y0 = off, off
                    local x1, y1 = off + S, off + S
                    local rects = {
                        { x0, y0, L, th, "h" },     { x0, y0, th, L, "v" },
                        { x1 - L, y0, L, th, "h" }, { x1 - th, y0, th, L, "v" },
                        { x0, y1 - th, L, th, "h" }, { x0, y1 - L, th, L, "v" },
                        { x1 - L, y1 - th, L, th, "h" }, { x1 - th, y1 - L, th, L, "v" },
                    }
                    for i, r in ipairs(rects) do
                        local x, y, lw, lh, o = r[1], r[2], r[3], r[4], r[5]
                        local line = TESP_LINES[i]
                        line.Core.Position = UDim2.fromOffset(x, y)
                        line.Core.Size = UDim2.fromOffset(math.max(lw, 1), math.max(lh, 1))
                        line.Core.BackgroundColor3 = col
                        line.G1.Visible, line.G2.Visible = glowOn, glowOn
                        if glowOn then
                            local function glow(gth)
                                if o == "h" then
                                    local yc = y + th / 2
                                    return x - gth / 2, yc - gth / 2, lw + gth, gth
                                else
                                    local xc = x + th / 2
                                    return xc - gth / 2, y - gth / 2, gth, lh + gth
                                end
                            end
                            local gx1, gy1, gw1, gh1 = glow(g1th)
                            line.G1.Position = UDim2.fromOffset(gx1, gy1)
                            line.G1.Size = UDim2.fromOffset(gw1, gh1)
                            line.G1.BackgroundColor3 = col
                            local gx2, gy2, gw2, gh2 = glow(g2th)
                            line.G2.Position = UDim2.fromOffset(gx2, gy2)
                            line.G2.Size = UDim2.fromOffset(gw2, gh2)
                            line.G2.BackgroundColor3 = col
                        end
                    end
                    local myhrp, thrp = getHRP(LocalPlayer), getHRP(target)
                    TESPDist.Visible = TespF.S["Дистанция"] ~= false and myhrp ~= nil and thrp ~= nil
                    if TESPDist.Visible then
                        TESPDist.Position = UDim2.fromOffset(sx, sy + F / 2 + 6)
                        TESPDist.Text = math.floor((thrp.Position - myhrp.Position).Magnitude + 0.5) .. "m"
                        TESPDist.TextColor3 = col
                    end
                else
                    if tesShown then
                        tesShown = false
                        Tween(TESP, { GroupTransparency = 1 }, 0.15)
                        TESPDist.Visible = false
                        task.delay(0.16, function() if not tesShown then TESP.Visible = false end end)
                    end
                end
            end
        elseif tesShown then
            tesShown = false
            Tween(TESP, { GroupTransparency = 1 }, 0.15)
            TESPDist.Visible = false
            task.delay(0.16, function() if not tesShown then TESP.Visible = false end end)
        end
    elseif tesShown then
        tesShown = false
        Tween(TESP, { GroupTransparency = 1 }, 0.15)
        TESPDist.Visible = false
        task.delay(0.16, function() if not tesShown then TESP.Visible = false end end)
    end

    -- Player HUD
    if PlayerHudF.Enabled then
        local target = nil
        if PlayerHudF.S["При наведении"] then target = getMouseTarget(false) end
        if not target then
            local range = PlayerHudF.S["Радиус"] or 15
            local myhrp = getHRP(LocalPlayer)
            if myhrp then
                local bd = range
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer then
                        local h = getHRP(pl)
                        if h then
                            local d = (h.Position - myhrp.Position).Magnitude
                            if d < bd then bd, target = d, pl end
                        end
                    end
                end
            end
        end
        if target and getCharacter(target) then
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if not phudShown then
                phudShown = true
                PHud.Visible = true
                Tween(PHud, { GroupTransparency = 0 }, 0.15)
            end
            pHudName.Text = target.DisplayName .. " (@" .. target.Name .. ")"
            pHudAvatar.Visible = PlayerHudF.S["Аватар"] ~= false
            pHudAvatar.Image = avatarCache[target] or getAvatar(target)
            local hp, mhp = hum and hum.Health or 0, hum and hum.MaxHealth or 100
            local pct = math.clamp(hp / math.max(mhp, 1), 0, 1)
            pHudHp.Size = UDim2.new(pct, 0, 1, 0)
            pHudHp.BackgroundColor3 = Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(90, 220, 120), pct)
            local dtext = ""
            local myhrp, thrp = getHRP(LocalPlayer), getHRP(target)
            if PlayerHudF.S["Дистанция"] and myhrp and thrp then
                dtext = "  ·  " .. math.floor((thrp.Position - myhrp.Position).Magnitude + 0.5) .. "m"
            end
            pHudInfo.Text = math.floor(hp) .. " / " .. math.floor(mhp) .. " HP" .. dtext
        elseif phudShown then
            phudShown = false
            Tween(PHud, { GroupTransparency = 1 }, 0.2)
            task.delay(0.2, function() if not phudShown then PHud.Visible = false end end)
        end
    elseif PHud.Visible then
        phudShown = false
        PHud.Visible = false
    end

    -- Target Strafe Info
    if TSInfoF.Enabled and StrafeF.Enabled then
        if not tsShown then
            tsShown = true
            TSInfo.Visible = true
            Tween(TSInfo, { GroupTransparency = 0 }, 0.15)
        end
        local held = HeldKeys[StrafeF] == true
        local st = strafeState
        local displayPl = st.engaged and st.target or getMouseTarget(true)
        local delay = StrafeF.S["Задержка"] or 2
        local instant = StrafeF.S["Мгновенный захват"] == true
        local aimPct, statusText, statusColor = 0, "", Theme.TextDim
        if st.engaged then
            aimPct = 1
            if st.phase == "fly" then
                statusText, statusColor = "ПОЛЁТ К ЦЕЛИ", Theme.Accent
            else
                statusText = "СТРЕЙФ · " .. tostring(StrafeF.S["Скорость"] or 540) .. "°/с"
                statusColor = Color3.fromRGB(90, 220, 120)
            end
        elseif held then
            if displayPl then
                if instant then
                    aimPct = 1
                    statusText = "МГНОВЕННЫЙ ЗАХВАТ"
                    statusColor = Theme.Accent
                else
                    aimPct = math.clamp(st.holdT / delay, 0, 1)
                    statusText = "НАВЕДЕНИЕ · " .. string.format("%.1f", math.max(delay - st.holdT, 0)) .. "с"
                    statusColor = Color3.fromRGB(255, 200, 90)
                end
            else
                statusText = "НАВЕДИ КУРСОР НА ВРАГА"
                statusColor = Theme.TextDim
            end
        else
            local bk = StrafeF.Bind and keyName(StrafeF.Bind)
            statusText = bk and ("ЗАЖМИ [" .. bk .. "]") or "НАЗНАЧЬ БИНД · КОЛЕСО ПО ФУНКЦИИ"
            statusColor = Theme.TextDim
        end
        tsDot.BackgroundColor3 = statusColor
        tsStatus.Text = statusText
        tsStatus.TextColor3 = statusColor
        tsAimBg.Visible = TSInfoF.S["Полоса наведения"] ~= false
        tsAim.Size = UDim2.new(aimPct, 0, 1, 0)
        if displayPl and getCharacter(displayPl) then
            tsName.Text = displayPl.DisplayName .. " (@" .. displayPl.Name .. ")"
            tsAvatar.Visible = TSInfoF.S["Аватар цели"] ~= false
            tsAvatar.Image = avatarCache[displayPl] or getAvatar(displayPl)
            local hum = displayPl.Character:FindFirstChildOfClass("Humanoid")
            local hp, mhp = hum and hum.Health or 0, hum and hum.MaxHealth or 100
            local pct = math.clamp(hp / math.max(mhp, 1), 0, 1)
            tsHpBg.Visible = TSInfoF.S["HP цели"] ~= false
            tsHp.Size = UDim2.new(pct, 0, 1, 0)
            tsHp.BackgroundColor3 = Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(90, 220, 120), pct)
            local dtext = ""
            local myhrp, thrp = getHRP(LocalPlayer), getHRP(displayPl)
            if TSInfoF.S["Дистанция"] ~= false and myhrp and thrp then
                dtext = "  ·  " .. math.floor((thrp.Position - myhrp.Position).Magnitude + 0.5) .. "m"
            end
            tsInfoLbl.Text = math.floor(hp) .. " / " .. math.floor(mhp) .. " HP" .. dtext
        else
            tsName.Text = "— нет цели —"
            tsAvatar.Image = ""
            tsHp.Size = UDim2.new(0, 0, 1, 0)
            tsInfoLbl.Text = ""
        end
    elseif TSInfo.Visible then
        tsShown = false
        Tween(TSInfo, { GroupTransparency = 1 }, 0.2)
        task.delay(0.2, function() if not tsShown then TSInfo.Visible = false end end)
    end

    -- Radar
    if RadarF.Enabled then
        Radar.Visible = true
        local my = getHRP(LocalPlayer)
        if my then
            local yaw = 0
            if RadarF.S["Поворот по камере"] then
                local lv = Camera.CFrame.LookVector
                yaw = math.atan2(-lv.X, -lv.Z)
            end
            local cy, sy = math.cos(yaw), math.sin(yaw)
            local range = RadarF.S["Дистанция"] or 150
            local R = Radar.AbsoluteSize.X * 0.5
            local i = 0
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and i < #radarDots then
                    if (not RadarF.S["Только враги"]) or isEnemy(pl, true) then
                        local hrp = getHRP(pl)
                        if hrp then
                            local d = hrp.Position - my.Position
                            local rx = d.X * cy - d.Z * sy
                            local ry = d.X * sy + d.Z * cy
                            local sx = rx / range * (R - 10)
                            local sz = ry / range * (R - 10)
                            local dist = math.sqrt(sx * sx + sz * sz)
                            local show = true
                            if dist > R - 10 then
                                if RadarF.S["Точки у края"] then
                                    sx, sz = sx / dist * (R - 10), sz / dist * (R - 10)
                                else
                                    show = false
                                end
                            end
                            if show then
                                i += 1
                                local dot = radarDots[i]
                                dot.Visible = true
                                dot.Position = UDim2.new(0.5, sx, 0.5, sz)
                                dot.BackgroundColor3 = (pl.Team and pl.Team == LocalPlayer.Team) and Color3.fromRGB(90, 200, 255) or Color3.fromRGB(255, 90, 90)
                            end
                        end
                    end
                end
            end
            for j = i + 1, #radarDots do radarDots[j].Visible = false end
        end
    else
        Radar.Visible = false
    end

    -- Crosshair (+ режим «Только при шифт локе»)
    if CrosshairF.Enabled then
        local slOnly = CrosshairF.S["Только при шифт локе"] == true
        local slActive = false
        if slOnly then
            if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                slActive = true
            else
                -- запасная проверка: курсор почти в центре (стандартный шифт-лок Roblox)
                local m = mousePos()
                local cxy = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                slActive = (m - cxy).Magnitude < 6
            end
        end
        CrosshairF_.Visible = (not slOnly) or slActive
        if CrosshairF.S["Радуга"] then
            local c = rainbow(0)
            for _, p in ipairs(chParts) do
                if p:IsA("Frame") then p.BackgroundColor3 = c end
                if p:IsA("UIStroke") then p.Color = c end
            end
        end
        if CrosshairF.S["Режим"] == "Мышь" then
            local m = mousePos()
            CrosshairF_.Position = UDim2.fromOffset(m.X, m.Y)
        else
            CrosshairF_.Position = UDim2.fromOffset(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    else
        CrosshairF_.Visible = false
    end

    -- Keystrokes
    if KeysF.Enabled then
        Keystrokes.Visible = true
        Keystrokes.BackgroundTransparency = KeysF.S["Прозрачность"] or 0.25
        local function lit(b, on)
            b.BackgroundColor3 = on and Theme.Accent or Theme.Bg3
            b.TextColor3 = on and Color3.new(1, 1, 1) or Theme.TextDim
        end
        lit(keyButtons.W, UserInputService:IsKeyDown(Enum.KeyCode.W))
        lit(keyButtons.A, UserInputService:IsKeyDown(Enum.KeyCode.A))
        lit(keyButtons.S, UserInputService:IsKeyDown(Enum.KeyCode.S))
        lit(keyButtons.D, UserInputService:IsKeyDown(Enum.KeyCode.D))
        lit(keyButtons.Space, UserInputService:IsKeyDown(Enum.KeyCode.Space))
        local mouseOn = KeysF.S["Кнопки мыши"] ~= false
        keyButtons.MB1.Visible, keyButtons.MB2.Visible = mouseOn, mouseOn
        if mouseOn then
            lit(keyButtons.MB1, UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
            lit(keyButtons.MB2, UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        end
    else
        Keystrokes.Visible = false
    end

    -- Speedometer
    if SpeedoF.Enabled then
        Speedo.Visible = true
        local hrp = getHRP(LocalPlayer)
        local v = hrp and (hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude or 0
        speedSmooth = SpeedoF.S["Сглаживание"] and (speedSmooth + (v - speedSmooth) * math.clamp(dt * 8, 0, 1)) or v
        local fmt = "%." .. (SpeedoF.S["Точность"] or 1) .. "f"
        speedLabel.Text = string.format(fmt, speedSmooth)
    else
        Speedo.Visible = false
    end

    -- Fog Blur
    fogBlur.Size = FogF.Enabled and (FogF.S["Блюр"] or 0) or 0
    if FogF.Enabled and (FogF.S["Туман"] or 0) > 0 then
        local amt = FogF.S["Туман"]
        Lighting.FogEnd = 50 + (1 - amt) * (1 - amt) * 2000
        Lighting.FogStart = 0
        Lighting.FogColor = FogF.S["Цвет тумана"] or Color3.fromRGB(160, 175, 200)
    end

    -- Color Plus
    ccPlus.Contrast   = ColorPlusF.Enabled and (ColorPlusF.S["Контраст"] or 0) or 0
    ccPlus.Saturation = ColorPlusF.Enabled and (ColorPlusF.S["Насыщенность"] or 0) or 0
    ccPlus.Brightness = ColorPlusF.Enabled and (ColorPlusF.S["Яркость"] or 0) or 0
    ccPlus.TintColor  = ColorPlusF.Enabled and ColorPlusF.S["Оттенок"] or Color3.new(1, 1, 1)
end)

-- Watermark
task.spawn(function()
    while true do
        local on = WatermarkF.Enabled
        Watermark.Visible = on
        if on then
            local s = "KOCMOC.CLIENT"
            if WatermarkF.S["Часы"] then s = s .. "   ·   " .. os.date("%H:%M") end
            if WatermarkF.S["FPS"] then s = s .. "   ·   " .. FPS .. " fps" end
            if WatermarkF.S["Пинг"] then s = s .. "   ·   " .. getPing() .. " ms" end
            wmText.Text = s
        end
        task.wait(0.25)
    end
end)

--────────────────────────────────────────────────────────────── СТАРТ
SwitchTab("combat")
local logoConn
logoConn = RunService.RenderStepped:Connect(function()
    if Camera then originalFov = Camera.FieldOfView; logoConn:Disconnect() end
end)
