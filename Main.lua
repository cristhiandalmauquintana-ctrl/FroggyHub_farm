--// Main.lua - Froggy Hub AutoFarm (loader + panel grande con barra lateral)

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "FroggyHub-AutoFarm" -- cambia esto por el nombre real de tu repo
local BRANCH = "main"
local FARM_FILES = { "Farm.lua", "farm.lua" }
local LOGO_FILES = { "logo.png", "Logo.png" }
local HUB_NAME = "Froggy Hub AutoFarm"

local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if env.__BF_FARMUI_CLEANUP then pcall(env.__BF_FARMUI_CLEANUP) end

local C = {
    Bg = Color3.fromRGB(16, 16, 22), Header = Color3.fromRGB(22, 22, 30), Side = Color3.fromRGB(20, 20, 28),
    Row = Color3.fromRGB(27, 27, 36), Stroke = Color3.fromRGB(52, 52, 66), Text = Color3.fromRGB(240, 240, 245),
    Dim = Color3.fromRGB(135, 135, 150), Accent = Color3.fromRGB(110, 220, 90), AccentText = Color3.fromRGB(14, 24, 12),
    On = Color3.fromRGB(110, 220, 90), Off = Color3.fromRGB(58, 58, 72), Danger = Color3.fromRGB(210, 70, 70),
}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o return c end
local function stroke(o, color, th)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Stroke s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o
    return s
end
local function tween(o, t, props)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function getParent()
    if gethui then local ok, ui = pcall(gethui) if ok and ui then return ui end end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", { Name = "FroggyHubAutoFarm", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100 }, getParent())
local connections, tweens = {}, {}
local alive = true

local function cleanup()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
    if env.__BF_FARM_CLEANUP then pcall(env.__BF_FARM_CLEANUP) end
    gui:Destroy()
    env.__BF_FARMUI_CLEANUP = nil
end
env.__BF_FARMUI_CLEANUP = cleanup

--==================== CARGA ====================
local loading = new("Frame", {
    Size = UDim2.fromOffset(260, 200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = C.Bg, BorderSizePixel = 0,
}, gui)
corner(loading, 14) stroke(loading)
local loadScale = Instance.new("UIScale", loading)
local loadLogo = new("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(84, 84),
    BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1,
}, loading)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 0, 24),
    Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.Accent, Text = string.upper(HUB_NAME),
}, loading)
local loadStatus = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 140), Size = UDim2.new(1, -20, 0, 18),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.Dim, Text = "Iniciando...",
}, loading)
local barTrack = new("Frame", {
    Position = UDim2.new(0, 20, 1, -26), Size = UDim2.new(1, -40, 0, 6), BackgroundColor3 = C.Off, BorderSizePixel = 0,
}, loading)
corner(barTrack, 99)
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, barTrack)
corner(barFill, 99)

local function setProgress(f, text)
    tween(barFill, 0.35, { Size = UDim2.fromScale(f, 1) })
    if text then loadStatus.Text = text end
end
local function fail(msg)
    loadStatus.Text = msg loadStatus.TextColor3 = C.Danger
    warn("Froggy AutoFarm: " .. msg)
    task.delay(5, cleanup)
end

local function fetch(names)
    for _, name in ipairs(names) do
        local ok, res = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then return res end
    end
end

local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return nil end
    for _, name in ipairs(LOGO_FILES) do
        local ok, data = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            if pcall(writefile, "FroggyHub_logo.png", data) then
                local okA, asset = pcall(getAsset, "FroggyHub_logo.png")
                if okA and asset and asset ~= "" then return asset end
            end
        end
    end
end

setProgress(0.15, "Cargando logo...")
local logoAsset = fetchLogo()
if logoAsset then
    loadLogo.Image = logoAsset
    tween(loadLogo, 0.3, { ImageTransparency = 0 })
    local pulse = TweenService:Create(loadLogo, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(98, 98) })
    table.insert(tweens, pulse) pulse:Play()
end

setProgress(0.4, "Descargando Auto Farm...")
local src = fetch(FARM_FILES)
if not src then fail("No se pudo descargar Farm.lua.") return end
local chunk, cErr = loadstring(src)
if type(chunk) ~= "function" then fail("Error de sintaxis en Farm.lua: " .. tostring(cErr)) return end
setProgress(0.7, "Iniciando Auto Farm...")
local okRun, rErr = pcall(chunk)
if not okRun then fail("Error al iniciar Farm: " .. tostring(rErr)) return end
local Farm = env.BF_FARM_CONFIG
if type(Farm) ~= "table" then fail("No se encontró la configuración del farm.") return end
setProgress(1, "Listo")
task.wait(0.4)

--==================== PANEL ====================
local function screenSize()
    local sz = gui.AbsoluteSize
    if sz.X < 50 or sz.Y < 50 then
        local cam = workspace.CurrentCamera
        sz = cam and cam.ViewportSize or Vector2.new(800, 600)
    end
    return sz
end

local S0 = screenSize()
local WIDTH = math.min(560, S0.X - 24)
local HEIGHT = math.min(380, S0.Y - 20)
local HEADER_H, SIDE_W = 46, 118

local frame = new("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    Position = UDim2.fromOffset(math.floor((S0.X - WIDTH) / 2), math.floor((S0.Y - HEIGHT) / 2)),
    BackgroundColor3 = C.Bg, BorderSizePixel = 0, ClipsDescendants = true, Active = true, Visible = false,
}, gui)
corner(frame, 14) stroke(frame)
local panelScale = Instance.new("UIScale", frame)
panelScale.Scale = 0.8

local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C.Header, BorderSizePixel = 0, Active = true }, frame)
local titleX = 14
if logoAsset then
    new("ImageLabel", { Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset }, header)
    titleX = 50
end
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 5), Size = UDim2.new(1, -(titleX + 90), 0, 22),
    Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Text, Text = HUB_NAME,
}, header)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 26), Size = UDim2.new(1, -(titleX + 90), 0, 14),
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Accent, Text = "Blox Fruits - Auto Level",
}, header)

local function headerButton(text, x)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, x, 0.5, -15), BackgroundColor3 = C.Row, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.Text, Text = text, AutoButtonColor = false,
    }, header)
    corner(b, 8)
    return b
end
local closeBtn = headerButton("X", -40)
local minBtn = headerButton("-", -76)

--// Barra lateral
local side = new("Frame", {
    Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(0, SIDE_W, 1, -HEADER_H), BackgroundColor3 = C.Side, BorderSizePixel = 0,
}, frame)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 10) }, side)
new("Frame", { Position = UDim2.fromOffset(SIDE_W, HEADER_H), Size = UDim2.new(0, 1, 1, -HEADER_H), BackgroundColor3 = C.Stroke, BorderSizePixel = 0 }, frame)

local pages, tabButtons, order = {}, {}, 0
local function nextOrder() order = order + 1 return order end
local refreshers = {}

local function selectTab(name)
    for n, page in pairs(pages) do
        page.Visible = (n == name)
        tween(tabButtons[n], 0.15, {
            BackgroundColor3 = (n == name) and C.Accent or C.Row,
            TextColor3 = (n == name) and C.AccentText or C.Dim,
        })
    end
end

local function createPage(name, index)
    local page = new("ScrollingFrame", {
        Position = UDim2.fromOffset(SIDE_W + 10, HEADER_H + 8), Size = UDim2.new(1, -(SIDE_W + 18), 1, -(HEADER_H + 14)),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Stroke,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, page)
    pages[name] = page
    local b = new("TextButton", {
        LayoutOrder = index, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Row, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.Dim, Text = name, AutoButtonColor = false,
    }, side)
    corner(b, 8)
    b.Activated:Connect(function() selectTab(name) end)
    tabButtons[name] = b
    return page
end

local pFarm = createPage("Auto Farm", 1)
local pSet = createPage("Ajustes", 2)
local pInfo = createPage("Info", 3)

--==================== COMPONENTES ====================
local function cardFrame(page)
    local c = new("Frame", {
        LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.Row, BorderSizePixel = 0,
    }, page)
    corner(c, 10) stroke(c)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, c)
    new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, c)
    return c
end

local function card(page, title)
    local c = cardFrame(page)
    new("TextLabel", {
        LayoutOrder = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Accent, Text = string.upper(title),
    }, c)
    return c
end

local function switchRow(parent, text, get, set, onChange, bold)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -54, 1, 0), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = bold and 14 or 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = bold and C.Text or Color3.fromRGB(205, 205, 215), Text = text, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 22), BackgroundColor3 = C.Off, BorderSizePixel = 0 }, row)
    corner(track, 99)
    local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
    corner(knob, 99)
    local click = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, row)
    local function refresh()
        local on = get() and true or false
        tween(track, 0.15, { BackgroundColor3 = on and C.On or C.Off })
        tween(knob, 0.15, { Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
        if onChange then onChange(on) end
    end
    click.Activated:Connect(function() set(not get()) refresh() end)
    refresh()
    table.insert(refreshers, refresh)
    return row
end

local function slider(parent, text, get, set, minV, maxV, stepV)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 18), Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = text, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local valueLabel = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(56, 18),
        Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.Accent,
    }, row)
    local hit = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 24), Active = true }, row)
    local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.Off, BorderSizePixel = 0 }, hit)
    corner(track, 99)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, track)
    corner(fill, 99)
    local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
    corner(knob, 99) stroke(knob, C.Accent, 2)

    local function refresh()
        local v = get()
        local rel = math.clamp((v - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valueLabel.Text = tostring(v)
    end
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        local v = minV + rel * (maxV - minV)
        v = math.floor(v / stepV + 0.5) * stepV
        set(math.clamp(math.floor(v * 100 + 0.5) / 100, minV, maxV))
        refresh()
    end

    local activeInput
    table.insert(connections, hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
            setFromX(input.Position.X)
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if activeInput == input then activeInput = nil end
                    conn:Disconnect()
                end
            end)
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not activeInput then return end
        if activeInput.UserInputType == Enum.UserInputType.Touch then
            if input ~= activeInput then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        setFromX(input.Position.X)
    end))
    refresh()
    table.insert(refreshers, refresh)
end

local function infoRow(parent, label)
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, parent)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(0, 80, 1, 0), Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = label,
    }, row)
    return new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 0), Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Text,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = "-",
    }, row)
end

--==================== CONTENIDO ====================
local lblStatus, lblLevel, lblQuest, lblMob
do
    local st = card(pFarm, "Estado")
    lblStatus = infoRow(st, "Estado")
    lblLevel = infoRow(st, "Nivel")
    lblQuest = infoRow(st, "Misión")
    lblMob = infoRow(st, "Enemigo")

    local main = cardFrame(pFarm)
    switchRow(main, "Auto Level", function() return Farm.Enabled end, function(v) Farm.Set(v) end, nil, true)
    switchRow(main, "Aceptar misión automáticamente", function() return Farm.AutoQuest end, function(v) Farm.AutoQuest = v end)
    switchRow(main, "Equipar arma automáticamente", function() return Farm.AutoEquip end, function(v) Farm.AutoEquip = v end)
end

do
    local wc = card(pSet, "Arma")
    local row = new("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, wc)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
    local btns = {}
    local function refreshWeapons()
        for w, b in pairs(btns) do
            local sel = (Farm.Weapon == w)
            tween(b, 0.12, { BackgroundColor3 = sel and C.Accent or C.Bg, TextColor3 = sel and C.AccentText or C.Dim })
        end
    end
    for i, w in ipairs({ "Melee", "Sword", "Blox Fruit", "Gun" }) do
        local b = new("TextButton", {
            LayoutOrder = i, Size = UDim2.new(0.25, -5, 1, 0), BackgroundColor3 = C.Bg, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Dim, Text = w, AutoButtonColor = false,
        }, row)
        corner(b, 8)
        b.Activated:Connect(function() Farm.Weapon = w refreshWeapons() end)
        btns[w] = b
    end
    refreshWeapons()

    local mv = card(pSet, "Movimiento")
    slider(mv, "Altura sobre el enemigo (studs)", function() return Farm.HoverHeight end, function(v) Farm.HoverHeight = v end, 5, 25, 1)
    slider(mv, "Velocidad de viaje (studs/seg)", function() return Farm.TweenSpeed end, function(v) Farm.TweenSpeed = v end, 100, 400, 25)
end

do
    local hc = card(pInfo, "Controles")
    new("TextLabel", {
        LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = C.Dim,
        Text = "RightControl: abrir o minimizar\nArrastra la barra superior para mover el panel.\nSoporta el Primer Mar (Segundo y Tercer Mar próximamente).",
    }, hc)
    local nc = card(pInfo, "Próximamente")
    for _, n in ipairs({ "Segundo Mar", "Tercer Mar", "Auto Raid", "Auto Boss" }) do
        new("TextLabel", {
            LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Gotham,
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Dim, Text = n,
        }, nc)
    end
end

selectTab("Auto Farm")

--// Actualizar estado en vivo
task.spawn(function()
    while alive do
        local lvl = "-"
        pcall(function() lvl = tostring(LocalPlayer.Data.Level.Value) end)
        lblStatus.Text = tostring(Farm.Status)
        lblLevel.Text = lvl
        lblQuest.Text = tostring(Farm.Quest)
        lblMob.Text = tostring(Farm.Mob)
        lblStatus.TextColor3 = Farm.Enabled and C.Accent or C.Text
        task.wait(0.5)
    end
end)

--==================== POSICIÓN, ARRASTRE Y BURBUJA ====================
local function setPanelPos(x, y)
    local sz = screenSize()
    frame.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, sz.X - WIDTH)), math.clamp(y, 0, math.max(0, sz.Y - HEIGHT)))
end

local function makeDraggable(handle, getPos, setPos, onTap)
    local active, startMouse, startPos, moved
    table.insert(connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active, startMouse, startPos, moved = input, input.Position, getPos(), false
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if active == input then
                        active = nil
                        if not moved and onTap then onTap() end
                    end
                    conn:Disconnect()
                end
            end)
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not active then return end
        if active.UserInputType == Enum.UserInputType.Touch then
            if input ~= active then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local d = input.Position - startMouse
        if d.Magnitude > 8 then moved = true end
        if moved then setPos(startPos.X + d.X, startPos.Y + d.Y) end
    end))
end

makeDraggable(header, function() return Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset) end, setPanelPos)

local BUBBLE = 52
local bubble = new("TextButton", {
    Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.Header, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = false,
}, gui)
corner(bubble, 99) stroke(bubble, C.Accent, 2)
if logoAsset then
    new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -14, 1, -14), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset, Active = false }, bubble)
else
    new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.Accent, Text = "F", Active = false }, bubble)
end

local function setBubblePos(x, y)
    local sz = screenSize()
    bubble.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, sz.X - BUBBLE)), math.clamp(y, 0, math.max(0, sz.Y - BUBBLE)))
end
local function restorePanel()
    bubble.Visible = false
    frame.Visible = true
    setPanelPos(bubble.Position.X.Offset - 8, bubble.Position.Y.Offset - 8)
end
local function minimizePanel()
    setBubblePos(frame.Position.X.Offset + 8, frame.Position.Y.Offset + 8)
    frame.Visible = false
    bubble.Visible = true
end
makeDraggable(bubble, function() return Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset) end, setBubblePos, restorePanel)
minBtn.Activated:Connect(minimizePanel)

table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local sz = screenSize()
    WIDTH, HEIGHT = math.min(560, sz.X - 24), math.min(380, sz.Y - 20)
    frame.Size = UDim2.fromOffset(WIDTH, HEIGHT)
    setPanelPos(frame.Position.X.Offset, frame.Position.Y.Offset)
    setBubblePos(bubble.Position.X.Offset, bubble.Position.Y.Offset)
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if frame.Visible then minimizePanel() else restorePanel() end
    end
end))

closeBtn.Activated:Connect(cleanup)

--// Transición
for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
local hide = TweenService:Create(loadScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
hide:Play()
task.wait(0.3)
loading:Destroy()
frame.Visible = true
tween(panelScale, 0.3, { Scale = 1 })
