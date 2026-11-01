--[[
    Keyless Hub Blox Fruits  |  Single LocalScript
    Place in: StarterPlayer > StarterPlayerScripts
    The whole GUI is built from code inside this one script.
    Default toggle key: RightShift (can be rebound in Settings)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Remove an older copy if the script is re-run
local old = playerGui:FindFirstChild("KeylessHubGUI")
if old then old:Destroy() end

---------------------------------------------------------------------
-- Theme / data
---------------------------------------------------------------------
local THEME = {
    bg = Color3.fromRGB(18, 18, 26),
    panel = Color3.fromRGB(26, 26, 38),
    item = Color3.fromRGB(34, 34, 50),
    accent = Color3.fromRGB(124, 92, 255),
    text = Color3.fromRGB(235, 235, 245),
    sub = Color3.fromRGB(150, 150, 175),
    good = Color3.fromRGB(80, 220, 140),
    bad = Color3.fromRGB(255, 90, 110),
    font = Enum.Font.GothamMedium,
    bold = Enum.Font.GothamBold,
}

local ACCENTS = {
    { "Purple", Color3.fromRGB(124, 92, 255) },
    { "Blue", Color3.fromRGB(70, 140, 255) },
    { "Green", Color3.fromRGB(60, 200, 130) },
    { "Red", Color3.fromRGB(255, 90, 110) },
    { "Orange", Color3.fromRGB(255, 160, 60) },
}

local WEAPONS = {
    { name = "Sword", damage = 15, cooldown = 0.8, range = 4 },
    { name = "Bow", damage = 10, cooldown = 1.2, range = 30 },
    { name = "Staff", damage = 25, cooldown = 2.5, range = 15 },
}

local settings = { notifications = true, damageNumbers = true }
local toggleKey = Enum.KeyCode.RightShift
local selectedWeapon = 1

-- Optional server remotes (the Weapons tab only works if these exist)
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local damageEvent = remotes and remotes:FindFirstChild("DamageEvent")
local damageEffect = remotes and remotes:FindFirstChild("DamageEffect")

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local accentPainters = {}
local function onAccent(fn)
    table.insert(accentPainters, fn)
    fn()
end
local function setAccent(color)
    THEME.accent = color
    for _, fn in ipairs(accentPainters) do fn() end
end

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function round(inst, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
end

local function tween(inst, props, t)
    TweenService:Create(inst, TweenInfo.new(t or 0.15), props):Play()
end

local function label(parent, text, pos, size, color, align, font, textSize)
    return new("TextLabel", {
        Text = text, Size = size, Position = pos, BackgroundTransparency = 1,
        TextColor3 = color or THEME.text, Font = font or THEME.font, TextSize = textSize or 14,
        TextXAlignment = align or Enum.TextXAlignment.Left,
    }, parent)
end

---------------------------------------------------------------------
-- Root GUI + window
---------------------------------------------------------------------
local gui = new("ScreenGui", {
    Name = "KeylessHubGUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = new("Frame", {
    Size = UDim2.fromOffset(560, 380), Position = UDim2.new(0.5, -280, 0.5, -190),
    BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
}, gui)
round(main, 12)
local stroke = new("UIStroke", { Transparency = 0.6, Thickness = 1.5 }, main)
onAccent(function() stroke.Color = THEME.accent end)

local titleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = THEME.panel, BorderSizePixel = 0 }, main)
round(titleBar, 12)
new("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = THEME.panel, BorderSizePixel = 0 }, titleBar)
label(titleBar, "KEYLESS HUB  |  Blox Fruits", UDim2.fromOffset(14, 0), UDim2.new(1, -90, 1, 0), THEME.text, nil, THEME.bold, 15)

local function titleButton(text, offset, hoverColor)
    local b = new("TextButton", {
        Text = text, Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, offset, 0, 6),
        BackgroundColor3 = THEME.item, TextColor3 = THEME.text, Font = THEME.bold, TextSize = 13, AutoButtonColor = false,
    }, titleBar)
    round(b, 6)
    b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = hoverColor }) end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = THEME.item }) end)
    return b
end

local closeBtn = titleButton("X", -34, THEME.bad)
local minBtn = titleButton("-", -64, THEME.sub)

-- Dragging
do
    local dragging, dragStart, startPos
    connect(titleBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, main.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local sidebar = new("Frame", { Size = UDim2.new(0, 130, 1, -50), Position = UDim2.fromOffset(8, 44), BackgroundColor3 = THEME.panel, BorderSizePixel = 0 }, main)
round(sidebar, 10)
new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }, sidebar)
new("UIPadding", { PaddingTop = UDim.new(0, 8) }, sidebar)

local content = new("Frame", { Size = UDim2.new(1, -154, 1, -50), Position = UDim2.fromOffset(146, 44), BackgroundColor3 = THEME.panel, BorderSizePixel = 0 }, main)
round(content, 10)

-- Minimize
local minimized = false
local fullSize = main.Size
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    sidebar.Visible, content.Visible = not minimized, not minimized
    tween(main, { Size = minimized and UDim2.fromOffset(fullSize.X.Offset, 38) or fullSize }, 0.2)
end)

---------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------
local toastHolder = new("Frame", {
    Size = UDim2.fromOffset(260, 300), Position = UDim2.new(1, -276, 1, -316),
    BackgroundTransparency = 1,
}, gui)
new("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom }, toastHolder)

local function notify(text)
    if not settings.notifications then return end
    local toast = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = THEME.panel, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, toastHolder)
    round(toast, 8)
    local bar = new("Frame", { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.fromOffset(6, 6), BorderSizePixel = 0, BackgroundTransparency = 1 }, toast)
    round(bar, 2)
    bar.BackgroundColor3 = THEME.accent
    local txt = label(toast, text, UDim2.fromOffset(18, 0), UDim2.new(1, -24, 1, 0), THEME.text, nil, THEME.font, 13)
    txt.TextTransparency = 1
    tween(toast, { BackgroundTransparency = 0.05 }, 0.2)
    tween(bar, { BackgroundTransparency = 0 }, 0.2)
    tween(txt, { TextTransparency = 0 }, 0.2)
    task.delay(2.5, function()
        tween(toast, { BackgroundTransparency = 1 }, 0.3)
        tween(bar, { BackgroundTransparency = 1 }, 0.3)
        tween(txt, { TextTransparency = 1 }, 0.3)
        task.wait(0.35)
        toast:Destroy()
    end)
end

---------------------------------------------------------------------
-- Page / component builders
---------------------------------------------------------------------
local pages, tabButtons, currentPage = {}, {}, nil

local function paintTabs()
    for name, b in pairs(tabButtons) do
        tween(b, { BackgroundColor3 = (name == currentPage) and THEME.accent or THEME.item })
    end
end
onAccent(paintTabs)

local function showPage(name)
    currentPage = name
    for n, p in pairs(pages) do p.Visible = (n == name) end
    paintTabs()
end

local function makeTab(name)
    local b = new("TextButton", {
        Text = name, Size = UDim2.new(1, -16, 0, 34), BackgroundColor3 = THEME.item,
        TextColor3 = THEME.text, Font = THEME.font, TextSize = 14, AutoButtonColor = false,
    }, sidebar)
    round(b, 8)
    b.MouseButton1Click:Connect(function() showPage(name) end)
    tabButtons[name] = b

    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, content)
    onAccent(function() page.ScrollBarImageColor3 = THEME.accent end)
    new("UIListLayout", { Padding = UDim.new(0, 6) }, page)
    pages[name] = page
    return page
end

local function row(page, height)
    local r = new("Frame", { Size = UDim2.new(1, -6, 0, height or 40), BackgroundColor3 = THEME.item, BorderSizePixel = 0 }, page)
    round(r, 8)
    return r
end

local function section(page, text)
    label(page, text:upper(), UDim2.new(), UDim2.new(1, -6, 0, 18), THEME.sub, nil, THEME.bold, 11)
end

local function button(page, text, callback)
    local r = row(page, 40)
    local b = new("TextButton", {
        Text = text, Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 6),
        TextColor3 = THEME.text, Font = THEME.bold, TextSize = 13, AutoButtonColor = false,
    }, r)
    round(b, 6)
    onAccent(function() b.BackgroundColor3 = THEME.accent end)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function toggle(page, text, default, callback)
    local state = default
    local r = row(page, 40)
    label(r, text, UDim2.fromOffset(12, 0), UDim2.new(0.65, 0, 1, 0))
    local track = new("TextButton", {
        Text = "", Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -56, 0.5, -11), AutoButtonColor = false,
    }, r)
    round(track, 11)
    local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundColor3 = THEME.text, BorderSizePixel = 0 }, track)
    round(knob, 8)
    local function paint()
        track.BackgroundColor3 = state and THEME.accent or THEME.panel
        tween(knob, { Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
    end
    onAccent(paint)
    track.MouseButton1Click:Connect(function()
        state = not state
        paint()
        callback(state)
    end)
end

local function slider(page, text, min, max, default, callback)
    local r = row(page, 54)
    label(r, text, UDim2.fromOffset(12, 4), UDim2.new(0.6, 0, 0, 20))
    local valueLbl = label(r, tostring(default), UDim2.new(0.5, 0, 0, 4), UDim2.new(0.5, -12, 0, 20), THEME.sub, Enum.TextXAlignment.Right, THEME.bold)

    local hit = new("Frame", { Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 12, 1, -28), BackgroundTransparency = 1 }, r)
    local track = new("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = THEME.panel, BorderSizePixel = 0 }, hit)
    round(track, 3)
    local fill = new("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BorderSizePixel = 0 }, track)
    round(fill, 3)
    onAccent(function() fill.BackgroundColor3 = THEME.accent end)

    local dragging = false
    local function setFromX(x)
        local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + pct * (max - min) + 0.5)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLbl.Text = tostring(v)
        callback(v)
    end
    connect(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

---------------------------------------------------------------------
-- Tab: Home
---------------------------------------------------------------------
local home = makeTab("Home")
section(home, "Session")

local function infoRow(page, name, value)
    local r = row(page, 36)
    label(r, name, UDim2.fromOffset(12, 0), UDim2.new(0.5, 0, 1, 0), THEME.sub)
    return label(r, value, UDim2.new(0.4, 0, 0, 0), UDim2.new(0.6, -12, 1, 0), THEME.good, Enum.TextXAlignment.Right, THEME.bold)
end

infoRow(home, "Player", player.DisplayName)
local fpsLbl = infoRow(home, "FPS", "--")
local pingLbl = infoRow(home, "Ping", "--")
local playersLbl = infoRow(home, "Players in server", tostring(#Players:GetPlayers()))

do
    local frames, elapsed = 0, 0
    connect(RunService.RenderStepped, function(dt)
        frames += 1
        elapsed += dt
        if elapsed >= 0.5 then
            fpsLbl.Text = tostring(math.floor(frames / elapsed))
            local ok, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            pingLbl.Text = ok and (ping .. " ms") or "n/a"
            playersLbl.Text = tostring(#Players:GetPlayers())
            frames, elapsed = 0, 0
        end
    end)
end

---------------------------------------------------------------------
-- Tab: Weapons (needs the server script's remotes)
---------------------------------------------------------------------
local weaponsPage = makeTab("Weapons")
section(weaponsPage, "Loadout")

local weaponBtns = {}
for i, w in ipairs(WEAPONS) do
    local r = row(weaponsPage, 54)
    label(r, w.name, UDim2.fromOffset(12, 6), UDim2.new(0.5, 0, 0, 20), THEME.text, nil, THEME.bold)
    label(r, ("DMG %d  |  CD %.1fs  |  Range %d"):format(w.damage, w.cooldown, w.range),
        UDim2.fromOffset(12, 28), UDim2.new(0.8, 0, 0, 18), THEME.sub)
    local pick = new("TextButton", {
        Size = UDim2.fromOffset(78, 28), Position = UDim2.new(1, -90, 0.5, -14),
        TextColor3 = THEME.text, Font = THEME.font, TextSize = 13, AutoButtonColor = false,
    }, r)
    round(pick, 6)
    weaponBtns[i] = pick
    pick.MouseButton1Click:Connect(function()
        selectedWeapon = i
        for j, btn in ipairs(weaponBtns) do
            btn.Text = (j == i) and "Selected" or "Select"
            btn.BackgroundColor3 = (j == i) and THEME.accent or THEME.panel
        end
        notify("Selected " .. w.name)
    end)
end
onAccent(function()
    for j, btn in ipairs(weaponBtns) do
        btn.Text = (j == selectedWeapon) and "Selected" or "Select"
        btn.BackgroundColor3 = (j == selectedWeapon) and THEME.accent or THEME.panel
    end
end)

section(weaponsPage, "Combat")
button(weaponsPage, damageEvent and "Attack Nearest Player" or "Server remotes not found", function()
    if not damageEvent then
        notify("Add the server script + Remotes folder first")
        return
    end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local weapon = WEAPONS[selectedWeapon]
    local best, bestDist = nil, weapon.range
    for _, other in ipairs(Players:GetPlayers()) do
        local root = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local d = (root.Position - myRoot.Position).Magnitude
            if d <= bestDist then best, bestDist = other, d end
        end
    end
    if best then
        damageEvent:FireServer(best, selectedWeapon)
    else
        notify("No player in range")
    end
end)

---------------------------------------------------------------------
-- Tab: Player
---------------------------------------------------------------------
local playerPage = makeTab("Player")
local custom = {} -- values the user changed; re-applied on respawn
local DEFAULTS = { walkSpeed = 16, jumpPower = 50, gravity = workspace.Gravity }

local function applyHumanoid()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if custom.walkSpeed then hum.WalkSpeed = custom.walkSpeed end
    if custom.jumpPower then
        hum.UseJumpPower = true
        hum.JumpPower = custom.jumpPower
    end
end
connect(player.CharacterAdded, function()
    task.wait(0.2)
    applyHumanoid()
end)

section(playerPage, "Movement")
slider(playerPage, "Walk Speed", 8, 100, DEFAULTS.walkSpeed, function(v) custom.walkSpeed = v; applyHumanoid() end)
slider(playerPage, "Jump Power", 20, 150, DEFAULTS.jumpPower, function(v) custom.jumpPower = v; applyHumanoid() end)
slider(playerPage, "Gravity", 50, 300, math.floor(DEFAULTS.gravity), function(v) workspace.Gravity = v end)

section(playerPage, "Actions")
button(playerPage, "Reset Movement Values", function()
    custom.walkSpeed, custom.jumpPower = DEFAULTS.walkSpeed, DEFAULTS.jumpPower
    applyHumanoid()
    workspace.Gravity = DEFAULTS.gravity
    notify("Movement reset (reopen tab to refresh sliders)")
end)
button(playerPage, "Reset Character", function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

---------------------------------------------------------------------
-- Tab: Visuals
---------------------------------------------------------------------
local visuals = makeTab("Visuals")
local lightingBackup

section(visuals, "Camera")
slider(visuals, "Field of View", 40, 120, math.floor(camera.FieldOfView), function(v) camera.FieldOfView = v end)

section(visuals, "Lighting")
slider(visuals, "Time of Day", 0, 24, math.floor(Lighting.ClockTime), function(v) Lighting.ClockTime = v end)
toggle(visuals, "Fullbright", false, function(on)
    if on then
        lightingBackup = {
            Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
        }
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.GlobalShadows = false
    elseif lightingBackup then
        for k, v in pairs(lightingBackup) do Lighting[k] = v end
    end
end)

---------------------------------------------------------------------
-- Tab: Auto Farm
-- Uses only the Tool already equipped by the player; never changes hotbar slots.
-- Works with NPC Models in Workspace that have a Humanoid and root part.
-- NPC damage, death, drops, and respawning are handled by the game's
-- normal server-side combat scripts.
---------------------------------------------------------------------
local autoFarmPage = makeTab("Auto Farm")

local farmEnabled = false
local farmToggleKey = Enum.KeyCode.Two -- Default hotkey: 2
local selectedNpcName = "Royal Soilder" -- Default target
local attackSpeedSetting = 3 -- 1..5; higher means faster activation attempts
local farmRadius = 2000
local tweenSpeed = 120 -- studs per second; CFrame tween, not velocity
local activeFarmTween = nil
local currentFarmTarget = nil
local npcCount = 0
local farmStatusLabel
local farmTargetLabel
local farmCountLabel
local selectedNpcLabel
local farmToggleButton
local npcDropdown
local npcDropdownOpen = false

local function getCharacterParts()
    local character = player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return nil, nil, nil end
    return character, humanoid, root
end

local function getNpcRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
end

local function isNpcModel(model, requireAlive)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(workspace) then
        return false
    end
    if Players:GetPlayerFromCharacter(model) then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = getNpcRoot(model)
    if not humanoid or not root then return false end
    return not requireAlive or humanoid.Health > 0
end

-- Returns every NPC model name currently present in Workspace. Dead NPC
-- models are included in the selector so their names remain selectable
-- while waiting for the next spawn.
local function getAllNpcNames()
    local nameSet = {}
    local aliveCount = 0

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") and isNpcModel(descendant, false) then
            nameSet[descendant.Name] = true
            local hum = descendant:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                aliveCount += 1
            end
        end
    end

    local names = {}
    for name in pairs(nameSet) do
        table.insert(names, name)
    end
    table.sort(names)
    npcCount = aliveCount

    if farmCountLabel then
        farmCountLabel.Text = ("Living NPCs: %d"):format(aliveCount)
    end
    return names
end

local function npcMatchesSelection(model)
    return selectedNpcName == "* All NPCs *" or model.Name == selectedNpcName
end

local function scanMatchingNpcs()
    local found = {}
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model")
            and isNpcModel(descendant, true)
            and npcMatchesSelection(descendant) then
            table.insert(found, descendant)
        end
    end

    npcCount = #found
    if farmCountLabel then
        farmCountLabel.Text = ("Matching living NPCs: %d"):format(npcCount)
    end
    return found
end

local function findNearestNpc()
    local _, _, myRoot = getCharacterParts()
    if not myRoot then return nil end

    local best, bestDistance = nil, farmRadius
    for _, npc in ipairs(scanMatchingNpcs()) do
        local root = getNpcRoot(npc)
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            local distance = (root.Position - myRoot.Position).Magnitude
            if distance < bestDistance then
                best, bestDistance = npc, distance
            end
        end
    end
    return best, bestDistance
end

-- Auto Farm never changes the player's hotbar or equipped item.
-- It only returns a Tool that is ALREADY parented to the character.
local function getCurrentlyEquippedTool()
    local character = player.Character
    if not character then return nil end

    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end

    return nil
end

-- Smoothly tween the character root toward a point beside the NPC.
-- This changes CFrame with TweenService; it does not use BodyVelocity,
-- LinearVelocity, AssemblyLinearVelocity, or Humanoid:MoveTo.
local function tweenToNpc(npc)
    local character, humanoid, myRoot = getCharacterParts()
    local npcRoot = getNpcRoot(npc)
    if not character or not humanoid or not myRoot or not npcRoot then
        return false
    end

    local offset = myRoot.Position - npcRoot.Position
    local flatOffset = Vector3.new(offset.X, 0, offset.Z)
    if flatOffset.Magnitude < 0.1 then
        flatOffset = Vector3.new(0, 0, 1)
    else
        flatOffset = flatOffset.Unit
    end

    -- Stop a few studs away so melee weapons can hit without entering the NPC.
    local destination = npcRoot.Position + flatOffset * 6
    destination = Vector3.new(destination.X, npcRoot.Position.Y, destination.Z)
    local destinationCFrame = CFrame.lookAt(destination, npcRoot.Position)

    if activeFarmTween then
        activeFarmTween:Cancel()
        activeFarmTween = nil
    end

    local distance = (myRoot.Position - destination).Magnitude
    local duration = math.max(0.12, distance / math.max(1, tweenSpeed))
    activeFarmTween = TweenService:Create(
        myRoot,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = destinationCFrame }
    )

    local thisTween = activeFarmTween
    thisTween:Play()
    local playbackState = thisTween.Completed:Wait()
    if activeFarmTween == thisTween then
        activeFarmTween = nil
    end

    return playbackState == Enum.PlaybackState.Completed and farmEnabled
end

local function setFarmStatus(text, color)
    if farmStatusLabel then
        farmStatusLabel.Text = "Status: " .. text
        farmStatusLabel.TextColor3 = color or THEME.sub
    end
end

local function refreshNpcSelector()
    if not npcDropdown then return end

    for _, child in ipairs(npcDropdown:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local names = getAllNpcNames()
    table.insert(names, 1, "* All NPCs *")

    for index, npcName in ipairs(names) do
        local choice = new("TextButton", {
            Name = "NPCChoice_" .. tostring(index),
            Text = npcName,
            Size = UDim2.new(1, -8, 0, 28),
            BackgroundColor3 = npcName == selectedNpcName and THEME.accent or THEME.item,
            TextColor3 = THEME.text,
            Font = npcName == selectedNpcName and THEME.bold or THEME.font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
        }, npcDropdown)
        round(choice, 6)

        new("UIPadding", {
            PaddingLeft = UDim.new(0, 9),
        }, choice)

        choice.MouseButton1Click:Connect(function()
            selectedNpcName = npcName
            selectedNpcLabel.Text = "Target NPC: " .. selectedNpcName
            currentFarmTarget = nil
            npcDropdown.Visible = false
            npcDropdownOpen = false
            notify("Selected NPC: " .. selectedNpcName)
            refreshNpcSelector()
        end)
    end

    npcDropdown.CanvasSize = UDim2.fromOffset(0, #names * 32)
end

farmTargetLabel = infoRow(autoFarmPage, "Current target", "None")
farmCountLabel = infoRow(autoFarmPage, "Living NPCs", "0")
farmStatusLabel = infoRow(autoFarmPage, "Status", "Stopped")
farmStatusLabel.TextColor3 = THEME.sub

section(autoFarmPage, "NPC selection")
do
    local selectorRow = row(autoFarmPage, 42)
    selectedNpcLabel = label(
        selectorRow,
        "Target NPC: " .. selectedNpcName,
        UDim2.fromOffset(10, 0),
        UDim2.new(1, -112, 1, 0),
        THEME.text,
        nil,
        THEME.bold,
        12
    )

    local openSelector = new("TextButton", {
        Text = "Select",
        Size = UDim2.fromOffset(82, 28),
        Position = UDim2.new(1, -90, 0.5, -14),
        BackgroundColor3 = THEME.accent,
        TextColor3 = THEME.text,
        Font = THEME.bold,
        TextSize = 12,
        AutoButtonColor = false,
    }, selectorRow)
    round(openSelector, 6)

    npcDropdown = new("ScrollingFrame", {
        Name = "NPCSelectorDropdown",
        Size = UDim2.new(1, -6, 0, 150),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        Visible = false,
        ZIndex = 20,
    }, autoFarmPage)
    round(npcDropdown, 8)
    new("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, npcDropdown)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    }, npcDropdown)

    openSelector.MouseButton1Click:Connect(function()
        npcDropdownOpen = not npcDropdownOpen
        npcDropdown.Visible = npcDropdownOpen
        if npcDropdownOpen then refreshNpcSelector() end
    end)

    local refreshButton = button(autoFarmPage, "Refresh NPC list", function()
        refreshNpcSelector()
        notify("NPC list refreshed")
    end)
end

section(autoFarmPage, "Configuration")
infoRow(autoFarmPage, "Weapon", "Uses currently equipped Tool")
slider(autoFarmPage, "Attack speed", 1, 5, attackSpeedSetting, function(v)
    attackSpeedSetting = v
end)
slider(autoFarmPage, "Tween speed", 20, 250, tweenSpeed, function(v)
    tweenSpeed = v
end)
slider(autoFarmPage, "NPC search radius", 50, 2000, farmRadius, function(v)
    farmRadius = v
end)

local function setFarmEnabled(on)
    if farmEnabled == on then return end
    farmEnabled = on

    if farmToggleButton then
        farmToggleButton.Text = farmEnabled and "Stop Auto Farm  [2]" or "Start Auto Farm  [2]"
        farmToggleButton.BackgroundColor3 = farmEnabled and THEME.bad or THEME.accent
    end

    if not on then
        if activeFarmTween then
            activeFarmTween:Cancel()
            activeFarmTween = nil
        end
        currentFarmTarget = nil
        if farmTargetLabel then farmTargetLabel.Text = "None" end
        setFarmStatus("Stopped", THEME.sub)
        local _, humanoid = getCharacterParts()
        if humanoid then humanoid:Move(Vector3.zero, false) end
        notify("Auto Farm stopped")
        return
    end

    notify("Auto Farm enabled")
    setFarmStatus("Searching for " .. selectedNpcName, THEME.good)

    task.spawn(function()
        local lastAttack = 0

        while farmEnabled and gui.Parent do
            local character, humanoid, myRoot = getCharacterParts()
            if not character or not humanoid or not myRoot then
                setFarmStatus("Waiting for character", THEME.sub)
                task.wait(0.5)
                continue
            end

            -- A target is complete only when its Humanoid dies or its model
            -- is removed. Then the loop finds the next spawn of the selection.
            if currentFarmTarget then
                local oldHumanoid = currentFarmTarget:FindFirstChildOfClass("Humanoid")
                if not isNpcModel(currentFarmTarget, true)
                    or not npcMatchesSelection(currentFarmTarget)
                    or not oldHumanoid
                    or oldHumanoid.Health <= 0 then
                    currentFarmTarget = nil
                end
            end

            if not currentFarmTarget then
                currentFarmTarget = findNearestNpc()
            end

            local target = currentFarmTarget
            local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
            local targetRoot = target and getNpcRoot(target)

            if not target or not targetHumanoid or not targetRoot or targetHumanoid.Health <= 0 then
                currentFarmTarget = nil
                if farmTargetLabel then
                    farmTargetLabel.Text = "Waiting for " .. selectedNpcName
                end
                setFarmStatus("Waiting for selected NPC to spawn", THEME.sub)
                task.wait(0.75)
            else
                farmTargetLabel.Text = target.Name
                local distance = (targetRoot.Position - myRoot.Position).Magnitude
                local tool = getCurrentlyEquippedTool()

                if distance > 9 then
                    setFarmStatus(("Tweening silently to %s (%.0f studs)"):format(target.Name, distance), THEME.good)
                    local tweenFinished = tweenToNpc(target)
                    if not tweenFinished and farmEnabled then
                        task.wait(0.1)
                    end
                else
                    setFarmStatus("Attacking with currently equipped weapon: " .. target.Name, THEME.good)

                    -- Never equip, unequip, select a hotbar slot, or open Backpack.
                    -- Only activate the Tool that is already equipped right now.
                    -- If the player changes their held Tool manually, the next
                    -- iteration uses that newly equipped Tool automatically.
                    if not tool then
                        setFarmStatus("Hold a weapon first (Auto Farm will not equip one)", THEME.bad)
                        task.wait(0.2)
                    else
                        local attackInterval = math.max(0.12, 1.15 - attackSpeedSetting * 0.17)
                        if os.clock() - lastAttack >= attackInterval then
                            if tool.Parent == character then
                                pcall(function()
                                    tool:Activate()
                                end)
                            end
                            lastAttack = os.clock()
                        end
                        task.wait(0.08)
                    end
                end
            end
        end

        if activeFarmTween then
            activeFarmTween:Cancel()
            activeFarmTween = nil
        end
        setFarmStatus("Stopped", THEME.sub)
    end)
end

farmToggleButton = button(autoFarmPage, "Start Auto Farm  [2]", function()
    setFarmEnabled(not farmEnabled)
end)

local farmKeyInfo = infoRow(autoFarmPage, "Auto Farm hotkey", "2")
---------------------------------------------------------------------
-- Tab: Settings
---------------------------------------------------------------------
local settingsPage = makeTab("Settings")

section(settingsPage, "Interface")
toggle(settingsPage, "Notifications", settings.notifications, function(v) settings.notifications = v end)
toggle(settingsPage, "Show damage numbers", settings.damageNumbers, function(v) settings.damageNumbers = v end)

-- Accent presets
do
    local r = row(settingsPage, 48)
    label(r, "Accent color", UDim2.fromOffset(12, 0), UDim2.new(0.4, 0, 1, 0))
    for i, a in ipairs(ACCENTS) do
        local swatch = new("TextButton", {
            Text = "", Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -(12 + (#ACCENTS - i + 1) * 28), 0.5, -11),
            BackgroundColor3 = a[2], AutoButtonColor = false,
        }, r)
        round(swatch, 11)
        swatch.MouseButton1Click:Connect(function()
            setAccent(a[2])
            notify("Accent: " .. a[1])
        end)
    end
end

-- Keybind
local rebinding = false
local keyBtn
keyBtn = button(settingsPage, "Toggle Key: " .. toggleKey.Name, function()
    rebinding = true
    keyBtn.Text = "Press any key..."
end)

section(settingsPage, "Script")
button(settingsPage, "Unload GUI", function()
    farmEnabled = false
    for _, c in ipairs(connections) do c:Disconnect() end
    if lightingBackup then
        for k, v in pairs(lightingBackup) do Lighting[k] = v end
    end
    workspace.Gravity = DEFAULTS.gravity
    gui:Destroy()
end)

---------------------------------------------------------------------
-- Global input + events
---------------------------------------------------------------------
connect(UserInputService.InputBegan, function(input, processed)
    if rebinding and input.UserInputType == Enum.UserInputType.Keyboard then
        rebinding = false
        toggleKey = input.KeyCode
        keyBtn.Text = "Toggle Key: " .. toggleKey.Name
        notify("Toggle key set to " .. toggleKey.Name)
        return
    end
    if input.KeyCode == farmToggleKey and not rebinding then
        setFarmEnabled(not farmEnabled)
        return
    end

    if not processed and input.KeyCode == toggleKey then
        main.Visible = not main.Visible
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    notify("Hidden - press " .. toggleKey.Name .. " to reopen")
end)

if damageEffect then
    connect(damageEffect.OnClientEvent, function(amount)
        if not settings.damageNumbers then return end
        local pop = new("TextLabel", {
            Text = "-" .. tostring(amount), Size = UDim2.fromOffset(120, 40),
            Position = UDim2.new(0.5, -60, 0.6, 0), BackgroundTransparency = 1,
            TextColor3 = THEME.bad, Font = THEME.bold, TextSize = 28,
        }, gui)
        tween(pop, { Position = UDim2.new(0.5, -60, 0.5, 0), TextTransparency = 1 }, 0.8)
        task.delay(0.9, function() pop:Destroy() end)
    end)
end

showPage("Home")
notify("Keyless Hub loaded - " .. toggleKey.Name .. " toggles the menu")
