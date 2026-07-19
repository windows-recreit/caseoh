--[[
    Loader.luau
    Entry point. Fetches Names, ESP, and Menu modules via loadstring + HttpGet,
    then wires them together into the full ScaseOhrip script.

    LOAD ORDER / PRIORITY:
      1. Names  - loaded first. If it fails, ESP/Menu still load but fall back
                  to built-in defaults (with a console warning) instead of
                  erroring out entirely.
      2. ESP    - highlight/watchdog logic, depends on Names.
      3. Menu   - UI construction, no dependency on Names.

    >>> REPLACE THE URLS BELOW WITH YOUR OWN RAW GITHUB LINKS <<<
    Example raw URL format:
    https://raw.githubusercontent.com/<user>/<repo>/<branch>/Names.luau
]]

local MODULE_URLS = {
    Names = "https://raw.githubusercontent.com/windows-recreit/caseoh/refs/heads/main/Names.luau",
    ESP   = "https://raw.githubusercontent.com/windows-recreit/caseoh/refs/heads/main/ESP.luau",
    Menu  = "https://raw.githubusercontent.com/windows-recreit/caseoh/refs/heads/main/Menu.luau",
}

----------------------------------------------------------------
-- Debug logging
----------------------------------------------------------------

local function dbg(msg)
    print(tostring(msg))
end

----------------------------------------------------------------
-- Loading screen (shown while modules are fetched)
----------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "ScaseOhrip_Loading"
LoadingGui.ResetOnSpawn = false
LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoadingGui.DisplayOrder = 1000
LoadingGui.Parent = PlayerGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(0, 260, 0, 90)
LoadingFrame.Position = UDim2.new(0.5, -130, 0.5, -45)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = LoadingGui

local LoadingCorner = Instance.new("UICorner")
LoadingCorner.CornerRadius = UDim.new(0, 10)
LoadingCorner.Parent = LoadingFrame

local LoadingStroke = Instance.new("UIStroke")
LoadingStroke.Color = Color3.fromRGB(45, 45, 52)
LoadingStroke.Thickness = 1
LoadingStroke.Parent = LoadingFrame

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Size = UDim2.new(1, -20, 0, 24)
LoadingTitle.Position = UDim2.new(0, 10, 0, 14)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "ScaseOhrip"
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.TextSize = 16
LoadingTitle.TextColor3 = Color3.fromRGB(235, 235, 240)
LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left
LoadingTitle.Parent = LoadingFrame

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Size = UDim2.new(1, -20, 0, 16)
LoadingStatus.Position = UDim2.new(0, 10, 0, 40)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "Starting..."
LoadingStatus.Font = Enum.Font.Gotham
LoadingStatus.TextSize = 12
LoadingStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
LoadingStatus.TextXAlignment = Enum.TextXAlignment.Left
LoadingStatus.Parent = LoadingFrame

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, -20, 0, 6)
BarBg.Position = UDim2.new(0, 10, 0, 64)
BarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
BarBg.BorderSizePixel = 0
BarBg.Parent = LoadingFrame

local BarBgCorner = Instance.new("UICorner")
BarBgCorner.CornerRadius = UDim.new(0, 3)
BarBgCorner.Parent = BarBg

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(90, 120, 255)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBg

local BarFillCorner = Instance.new("UICorner")
BarFillCorner.CornerRadius = UDim.new(0, 3)
BarFillCorner.Parent = BarFill

local function setLoadingProgress(fraction, statusText)
    fraction = math.clamp(fraction, 0, 1)
    LoadingStatus.Text = statusText or LoadingStatus.Text
    TweenService:Create(BarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(fraction, 0, 1, 0)
    }):Play()
end

local function closeLoadingScreen()
    TweenService:Create(LoadingFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadingStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
    TweenService:Create(LoadingTitle, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
    TweenService:Create(LoadingStatus, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
    TweenService:Create(BarBg, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    TweenService:Create(BarFill, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    task.wait(0.3)
    LoadingGui:Destroy()
end

setLoadingProgress(0.05, "Starting...")

local function fetchModule(moduleName, url)
    local ok, result = pcall(function()
        local src = game:HttpGet(url)
        local chunk, compileErr = loadstring(src)
        if not chunk then
            error("compile error: " .. tostring(compileErr))
        end
        return chunk()
    end)

    if ok then
        return result
    else
        dbg("Failed to load " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

----------------------------------------------------------------
-- Load modules in priority order
----------------------------------------------------------------

-- 1. Names (priority - other modules depend on this, but survive its absence)
setLoadingProgress(0.2, "Loading Names...")
local Names = fetchModule("Names", MODULE_URLS.Names)
if not Names then
    dbg("Names unavailable, using fallback defaults")
    Names = {
        NameTargets = {
            bananaPeel = { color = Color3.fromRGB(255, 255, 0), multiple = true },
        },
        PathTargets = {
            CaseChar = { path = {"Workspace", "CaseChar"}, color = Color3.fromRGB(255, 0, 0) },
        },
        References = {
            FightMusic = {"Workspace", "Sounds", "FightMusic"},
            Atmosphere = {"Lighting", "Atmosphere"},
            StinkPartName = "Stink",
        },
        PlayerHighlight = { color = Color3.fromRGB(0, 255, 0) },
    }
end

-- 2. ESP
setLoadingProgress(0.5, "Loading ESP...")
local ESP = fetchModule("ESP", MODULE_URLS.ESP)
if not ESP then
    dbg("ESP unavailable, ESP features disabled")
end

-- 3. Menu
setLoadingProgress(0.8, "Loading Menu...")
local Menu = fetchModule("Menu", MODULE_URLS.Menu)
if not Menu then
    dbg("Menu failed to load, cannot continue")
    closeLoadingScreen()
    return
end

setLoadingProgress(1, "Ready")

----------------------------------------------------------------
-- Init ESP with dependencies
----------------------------------------------------------------

if ESP then
    ESP.Init({ Names = Names, dbg = dbg })
    ESP.StartWatchdog()
end

Menu.SetDebug(dbg)

----------------------------------------------------------------
-- Non-ESP feature state/logic (evade fight, density, TP)
-- Kept in Loader since these don't involve highlights.
----------------------------------------------------------------

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local DEFAULT_DENSITY = 0.9

local evadeConnection = nil
local originalPositionCFrame = nil
local hasEvaded = false

local isAtCaseChar = false
local preTPPosition = nil

local function resolvePath(pathTable)
    local current = game
    for _, segment in ipairs(pathTable) do
        if not current then return nil end
        current = current:FindFirstChild(segment)
    end
    return current
end

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return char, hrp
end

local function getFightMusic()
    local pathDef = Names.References and Names.References.FightMusic
    if pathDef then
        return resolvePath(pathDef)
    end
    local soundsFolder = Workspace:FindFirstChild("Sounds")
    if not soundsFolder then return nil end
    return soundsFolder:FindFirstChild("FightMusic")
end

local function doEvadeUp()
    local char, hrp = getCharacter()
    if not char or not hrp then return end
    if hasEvaded then return end
    originalPositionCFrame = hrp.CFrame
    local offset = math.random(40, 50)
    hrp.CFrame = hrp.CFrame + Vector3.new(0, offset, 0)
    hasEvaded = true
end

local function doEvadeBack()
    local char, hrp = getCharacter()
    if not char or not hrp then return end
    if not hasEvaded then return end
    if originalPositionCFrame then
        hrp.CFrame = originalPositionCFrame
    end
    hasEvaded = false
    originalPositionCFrame = nil
end

local EvadeFightEnabled = false

local function setupEvadeFight()
    local fightMusic = getFightMusic()
    if not fightMusic then
        dbg("FightMusic instance not resolved")
        return
    end
    if fightMusic.Playing then
        doEvadeUp()
    end
    evadeConnection = fightMusic:GetPropertyChangedSignal("Playing"):Connect(function()
        if not EvadeFightEnabled then return end
        if fightMusic.Playing then
            doEvadeUp()
        else
            doEvadeBack()
        end
    end)
end

local function teardownEvadeFight()
    if evadeConnection then
        evadeConnection:Disconnect()
        evadeConnection = nil
    end
    if hasEvaded then
        doEvadeBack()
    end
end

local function setupNoDensity()
    local pathDef = Names.References and Names.References.Atmosphere
    local atmosphere = pathDef and resolvePath(pathDef)
    local ok, err = pcall(function()
        if atmosphere then
            atmosphere.Density = 0
        else
            Lighting.Atmosphere.Density = 0
        end
    end)
    if not ok then
        dbg("could not set atmosphere density: " .. tostring(err))
    end
end

local function teardownNoDensity()
    local pathDef = Names.References and Names.References.Atmosphere
    local atmosphere = pathDef and resolvePath(pathDef)
    local ok, err = pcall(function()
        if atmosphere then
            atmosphere.Density = DEFAULT_DENSITY
        else
            Lighting.Atmosphere.Density = DEFAULT_DENSITY
        end
    end)
    if not ok then
        dbg("could not restore atmosphere density: " .. tostring(err))
    end
end

local function hasStink()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local stinkName = (Names.References and Names.References.StinkPartName) or "Stink"
    return hrp:FindFirstChild(stinkName) ~= nil
end

local function tpToCaseCharAndBack()
    local char, hrp = getCharacter()
    if not char or not hrp then
        dbg("character not resolved for TP")
        return
    end

    if not isAtCaseChar then
        if not hasStink() then
            dbg("stink flag not present, aborting TP")
            return
        end

        local def = Names.PathTargets and Names.PathTargets.CaseChar
        local path = (def and def.path) or {"Workspace", "CaseChar"}
        local caseChar = resolvePath(path)
        if not caseChar then
            dbg("CaseChar path did not resolve")
            return
        end

        local targetCFrame
        if caseChar:IsA("Model") then
            local primaryPart = caseChar.PrimaryPart or caseChar:FindFirstChildWhichIsA("BasePart")
            if not primaryPart then
                dbg("CaseChar model has no usable part")
                return
            end
            targetCFrame = primaryPart.CFrame
        elseif caseChar:IsA("BasePart") then
            targetCFrame = caseChar.CFrame
        else
            dbg("CaseChar is not Model or BasePart")
            return
        end

        preTPPosition = hrp.CFrame
        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        isAtCaseChar = true
    else
        if preTPPosition then
            hrp.CFrame = preTPPosition
        end
        isAtCaseChar = false
        preTPPosition = nil
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    hasEvaded = false
    originalPositionCFrame = nil
    isAtCaseChar = false
    preTPPosition = nil
end)

----------------------------------------------------------------
-- Better UI joke button
----------------------------------------------------------------

local betterUiJokeIndex = 0
local betterUiJokes = {
    "Optimizing pixels... found none to optimize.",
    "Contacting UI department... they hung up.",
    "Applying 'better' patch... patch was empty.",
    "Recalculating aesthetics... aesthetics unchanged.",
    "Asking the intern to redesign it... intern left.",
    "Better UI installed. Please imagine improvements.",
    "Nothing happened. That was intentional. Mostly.",
}

local function pressBetterUiButton()
    betterUiJokeIndex = (betterUiJokeIndex % #betterUiJokes) + 1
    dbg("BETTER UI: " .. betterUiJokes[betterUiJokeIndex])
end

----------------------------------------------------------------
-- Build the window
----------------------------------------------------------------

closeLoadingScreen()

local Window = Menu.CreateWindow({ Name = "ScaseOhrip" })

local StablePage = Window:CreateTab("Stable")
local DevelopmentPage = Window:CreateTab("Development")

StablePage:CreateSectionLabel("COMBAT")

StablePage:CreateToggle("Evade Fight on start", false, function(value)
    EvadeFightEnabled = value
    if value then
        setupEvadeFight()
    else
        teardownEvadeFight()
    end
end)

StablePage:CreateSectionLabel("VISUALS")

StablePage:CreateToggle("Banana peel highlight", false, function(value)
    if not ESP then dbg("ESP unavailable"); return end
    if value then ESP.EnableBananaHighlight() else ESP.DisableBananaHighlight() end
end)

StablePage:CreateToggle("Anti banana peel", false, function(value)
    if not ESP then dbg("ESP unavailable"); return end
    if value then ESP.EnableAntiBanana() else ESP.DisableAntiBanana() end
end)

StablePage:CreateToggle("CaseChar highlight", false, function(value)
    if not ESP then dbg("ESP unavailable"); return end
    if value then ESP.EnableCaseCharHighlight() else ESP.DisableCaseCharHighlight() end
end)

StablePage:CreateToggle("No density", false, function(value)
    if value then setupNoDensity() else teardownNoDensity() end
end)

StablePage:CreateToggle("Highlight players", false, function(value)
    if not ESP then dbg("ESP unavailable"); return end
    if value then ESP.EnableHighlightPlayers() else ESP.DisableHighlightPlayers() end
end)

StablePage:CreateSectionLabel("UTILITY")

StablePage:CreateButton("TP to CaseChar and back", function()
    tpToCaseCharAndBack()
end)

DevelopmentPage:CreateSectionLabel("EXPERIMENTAL")

DevelopmentPage:CreateToggle("Rainbow corners", false, function(value)
    if value then Window:EnableRainbowCorners() else Window:DisableRainbowCorners() end
end)

DevelopmentPage:CreateButton("Better UI", function()
    pressBetterUiButton()
end)

DevelopmentPage:CreateSectionLabel("WORK IN PROGRESS")
DevelopmentPage:CreateInfoLabel("No other features here yet.")

dbg("ScaseOhrip ready")
