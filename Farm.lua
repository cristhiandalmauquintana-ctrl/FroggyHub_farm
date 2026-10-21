--// Farm.lua - Froggy Hub AutoFarm | Auto Level (Primer Mar)
local env = (getgenv and getgenv()) or _G
if env.__BF_FARM_CLEANUP then pcall(env.__BF_FARM_CLEANUP) end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = false,
    AutoQuest = true,
    AutoEquip = true,
    Weapon = "Melee",      -- Melee / Sword / Blox Fruit / Gun
    HoverHeight = 10,      -- studs por encima del enemigo
    TweenSpeed = 300,      -- studs por segundo al viajar
    -- Estado (lo lee el panel)
    Status = "Apagado",
    Mob = "-",
    Quest = "-",
}

--// Misiones del Primer Mar. VERIFICAR posiciones y nombres dentro del juego.
-- min = nivel mínimo, quest = nombre interno, idx = 1/2, mob = nombre del enemigo en workspace.Enemies
local Q = {
    { min = 1,   quest = "BanditQuest1",  idx = 1, mob = "Bandit",             pos = Vector3.new(1059, 16, 1549) },
    { min = 15,  quest = "JungleQuest",   idx = 1, mob = "Monkey",             pos = Vector3.new(-1598, 36, 153) },
    { min = 20,  quest = "JungleQuest",   idx = 2, mob = "Gorilla",            pos = Vector3.new(-1598, 36, 153) },
    { min = 30,  quest = "BuggyQuest1",   idx = 1, mob = "Pirate",             pos = Vector3.new(-1141, 4, 3831) },
    { min = 40,  quest = "BuggyQuest1",   idx = 2, mob = "Brute",              pos = Vector3.new(-1141, 4, 3831) },
    { min = 60,  quest = "DesertQuest",   idx = 1, mob = "Desert Bandit",      pos = Vector3.new(894, 6, 4390) },
    { min = 75,  quest = "DesertQuest",   idx = 2, mob = "Desert Officer",     pos = Vector3.new(894, 6, 4390) },
    { min = 90,  quest = "SnowQuest",     idx = 1, mob = "Snow Bandit",        pos = Vector3.new(1389, 87, -1298) },
    { min = 100, quest = "SnowQuest",     idx = 2, mob = "Snowman",            pos = Vector3.new(1389, 87, -1298) },
    { min = 120, quest = "MarineQuest2",  idx = 1, mob = "Chief Petty Officer",pos = Vector3.new(-5039, 29, 4325) },
    { min = 150, quest = "SkyQuest",      idx = 1, mob = "Sky Bandit",         pos = Vector3.new(-4839, 717, -2619) },
    { min = 175, quest = "SkyQuest",      idx = 2, mob = "Dark Master",        pos = Vector3.new(-4839, 717, -2619) },
    { min = 190, quest = "PrisonerQuest", idx = 1, mob = "Prisoner",           pos = Vector3.new(5308, 1, 475) },
    { min = 210, quest = "PrisonerQuest", idx = 2, mob = "Dangerous Prisoner", pos = Vector3.new(5308, 1, 475) },
    { min = 225, quest = "ColosseumQuest",idx = 1, mob = "Toga Warrior",       pos = Vector3.new(-1580, 6, -2986) },
    { min = 275, quest = "ColosseumQuest",idx = 2, mob = "Gladiator",          pos = Vector3.new(-1580, 6, -2986) },
    { min = 300, quest = "MagmaQuest",    idx = 1, mob = "Military Soldier",   pos = Vector3.new(-5313, 12, 8515) },
    { min = 330, quest = "MagmaQuest",    idx = 2, mob = "Military Spy",       pos = Vector3.new(-5313, 12, 8515) },
    { min = 375, quest = "FishmanQuest",  idx = 1, mob = "Fishman Warrior",    pos = Vector3.new(61123, 19, 1569) },
    { min = 400, quest = "FishmanQuest",  idx = 2, mob = "Fishman Commando",   pos = Vector3.new(61123, 19, 1569) },
    { min = 450, quest = "SkyExp1Quest",  idx = 1, mob = "God's Guard",        pos = Vector3.new(-4721, 845, -1953) },
    { min = 475, quest = "SkyExp1Quest",  idx = 2, mob = "Shanda",             pos = Vector3.new(-4721, 845, -1953) },
    { min = 525, quest = "SkyExp2Quest",  idx = 1, mob = "Royal Squad",        pos = Vector3.new(-7906, 5545, -380) },
    { min = 550, quest = "SkyExp2Quest",  idx = 2, mob = "Royal Soldier",      pos = Vector3.new(-7906, 5545, -380) },
    { min = 625, quest = "FountainQuest", idx = 1, mob = "Galley Pirate",      pos = Vector3.new(5259, 37, 4050) },
    { min = 650, quest = "FountainQuest", idx = 2, mob = "Galley Captain",     pos = Vector3.new(5259, 37, 4050) },
}

local SEA2, SEA3 = 4442272183, 7449423635
local running = true
local connections = {}

local function getChar() return LocalPlayer.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getLevel()
    local ok, v = pcall(function() return LocalPlayer.Data.Level.Value end)
    return ok and v or 1
end

local function pickQuest(level)
    local best
    for _, q in ipairs(Q) do
        if level >= q.min then best = q end
    end
    return best
end

local function commF()
    local r = RS:FindFirstChild("Remotes")
    return r and r:FindFirstChild("CommF_")
end

local function questTitle()
    local ok, t = pcall(function()
        local q = LocalPlayer.PlayerGui.Main.Quest
        if not q.Visible then return nil end
        return q.Container.QuestTitle.Title.Text
    end)
    return ok and t or nil
end

local function goTo(cf)
    local hrp = getHRP()
    if not hrp then return end
    local d = (hrp.Position - cf.Position).Magnitude
    if d < 4 then hrp.CFrame = cf return end
    local dur = d / math.max(50, Config.TweenSpeed)
    local tw = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = cf })
    tw:Play()
    local t0 = os.clock()
    while running and Config.Enabled and tw.PlaybackState == Enum.PlaybackState.Playing
        and os.clock() - t0 < dur + 1 do
        task.wait()
    end
    tw:Cancel()
end

local function equipWeapon()
    local char, hum = getChar(), getHum()
    if not char or not hum then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == Config.Weapon then return end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == Config.Weapon then
            hum:EquipTool(tool)
            return
        end
    end
end

local function findMob(name)
    local folder = workspace:FindFirstChild("Enemies")
    if not folder then return nil end
    local hrp = getHRP()
    local best, bestD
    for _, e in ipairs(folder:GetChildren()) do
        if e.Name == name then
            local h = e:FindFirstChildOfClass("Humanoid")
            local r = e:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                local d = hrp and (hrp.Position - r.Position).Magnitude or 0
                if not bestD or d < bestD then best, bestD = e, d end
            end
        end
    end
    return best
end

local function findSpawn(name)
    local origin = workspace:FindFirstChild("_WorldOrigin")
    local spawns = origin and origin:FindFirstChild("EnemySpawns")
    if not spawns then return nil end
    for _, s in ipairs(spawns:GetChildren()) do
        if s.Name:find(name, 1, true) then
            return s:IsA("BasePart") and s.Position or (s.PrimaryPart and s.PrimaryPart.Position)
        end
    end
end

local function ensureQuest(q)
    local title = questTitle()
    if title and title:find(q.mob, 1, true) then return true end
    local remote = commF()
    if not remote then return false end
    Config.Status = "Yendo a la misión"
    goTo(CFrame.new(q.pos + Vector3.new(0, 4, 0)))
    if not Config.Enabled then return false end
    if title then
        pcall(function() remote:InvokeServer("AbandonQuest") end)
        task.wait(0.3)
    end
    pcall(function() remote:InvokeServer("StartQuest", q.quest, q.idx) end)
    task.wait(0.5)
    local t = questTitle()
    return t ~= nil and t:find(q.mob, 1, true) ~= nil
end

local function attack(mob)
    local r = mob:FindFirstChild("HumanoidRootPart")
    local h = mob:FindFirstChildOfClass("Humanoid")
    local hrp = getHRP()
    if not (r and h and hrp) then return end
    if Config.AutoEquip then equipWeapon() end
    while running and Config.Enabled and h.Health > 0 and mob.Parent and r.Parent do
        hrp = getHRP()
        if not hrp then break end
        local above = r.Position + Vector3.new(0, Config.HoverHeight, 0)
        hrp.CFrame = CFrame.lookAt(above, r.Position)
        hrp.AssemblyLinearVelocity = Vector3.zero
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(900, 500))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(900, 500))
        end)
        task.wait(0.1)
    end
end

--// Noclip mientras se farmea (evita atascos al flotar sobre el enemigo)
table.insert(connections, RunService.Stepped:Connect(function()
    if not Config.Enabled then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

--// Anti-AFK
table.insert(connections, LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

task.spawn(function()
    while running do
        if not Config.Enabled then
            Config.Status = "Apagado"
            task.wait(0.3)
        elseif game.PlaceId == SEA2 or game.PlaceId == SEA3 then
            Config.Status = "Mar no soportado todavía"
            task.wait(1)
        else
            local ok, err = pcall(function()
                local level = getLevel()
                local q = pickQuest(level)
                if not q then Config.Status = "Sin misión para tu nivel" task.wait(1) return end
                Config.Mob = q.mob
                Config.Quest = q.quest .. " #" .. q.idx
                if not getHRP() then Config.Status = "Esperando personaje" task.wait(1) return end

                if Config.AutoQuest and not ensureQuest(q) then
                    if Config.Enabled then Config.Status = "No se pudo aceptar la misión" task.wait(1) end
                    return
                end

                local mob = findMob(q.mob)
                if mob then
                    Config.Status = "Atacando: " .. q.mob
                    attack(mob)
                else
                    Config.Status = "Buscando " .. q.mob
                    local sp = findSpawn(q.mob) or q.pos
                    goTo(CFrame.new(sp + Vector3.new(0, Config.HoverHeight, 0)))
                    task.wait(0.4)
                end
            end)
            if not ok then
                warn("Froggy AutoFarm: " .. tostring(err))
                task.wait(1)
            end
            task.wait()
        end
    end
end)

function Config.Set(v)
    Config.Enabled = v and true or false
end

env.BF_FARM_CONFIG = Config
env.__BF_FARM_CLEANUP = function()
    running = false
    Config.Enabled = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    env.BF_FARM_CONFIG = nil
    env.__BF_FARM_CLEANUP = nil
end
