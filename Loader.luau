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

local DEBUG_PREFIX = "[ScaseOhrip:Loader]"

local function fakeAddr()
    local hex = "0x"
    for i = 1, 14 do
        hex = hex .. string.format("%x", math.random(0, 15))
    end
    return hex
end

local function dbg(msg)
    print(string.format("%s %s | ref:%s | tick:%.3f", DEBUG_PREFIX, msg, fakeAddr(), tick()))
end

dbg("loader starting")

----------------------------------------------------------------
-- Module fetch helper
----------------------------------------------------------------

local function fetchModule(moduleName, url)
    dbg("fetching module: " .. moduleName)
    local ok, result = pcall(function()
        local src = game:HttpGet(url)
        local chunk, compileErr = loadstring(src)
        if not chunk then
            error("compile error: " .. tostring(compileErr))
        end
        return chunk()
    end)

    if ok then
        dbg("module loaded successfully: " .. moduleName)
        return result
    else
        dbg("WARN: failed to load module '" .. moduleName .. "': " .. tostring(result))
        return nil
    end
end

----------------------------------------------------------------
-- Load modules in priority order
----------------------------------------------------------------

-- 1. Names (priority - other modules depend on this, but survive its absence)
local Names = fetchModule("Names", MODULE_URLS.Names)
if not Names then
    dbg("Names module unavailable, using built-in fallback defaults")
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
local ESP = fetchModule("ESP", MODULE_URLS.ESP)
if not ESP then
    dbg("FATAL: ESP module failed to load, ESP features will be unavailable")
end

-- 3. Menu
local Menu = fetchModule("Menu", MODULE_URLS.Menu)
if not Menu then
    dbg("FATAL: Menu module failed to load, cannot continue")
    return
end

----------------------------------------------------------------
-- Init ESP with dependencies
----------------------------------------------------------------

if ESP then
    ESP.Init({ Names = Names, dbg = function(msg) dbg("[ESP] " .. msg) end })
    ESP.StartWatchdog()
end

Menu.SetDebug(function(msg) dbg("[Menu] " .. msg) end)

----------------------------------------------------------------
-- Non-ESP feature state/logic (evade fight, density, TP)
-- Kept in Loader since these don't involve highlights.
----------------------------------------------------------------

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

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
    dbg("evade routine executed, offset=" .. offset)
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
    dbg("evade routine reverted")
end

local EvadeFightEnabled = false

local function setupEvadeFight()
    local fightMusic = getFightMusic()
    if not fightMusic then
        dbg("WARN: FightMusic instance not resolved")
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
    dbg("evade fight watcher attached")
end

local function teardownEvadeFight()
    if evadeConnection then
        evadeConnection:Disconnect()
        evadeConnection = nil
    end
    if hasEvaded then
        doEvadeBack()
    end
    dbg("evade fight watcher detached")
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
    if ok then
        dbg("atmosphere density set to 0")
    else
        dbg("WARN: could not set atmosphere density: " .. tostring(err))
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
    if ok then
        dbg("atmosphere density restored")
    else
        dbg("WARN: could not restore atmosphere density: " .. tostring(err))
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
        dbg("WARN: character not resolved for TP")
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
            dbg("WARN: CaseChar path did not resolve")
            return
        end

        local targetCFrame
        if caseChar:IsA("Model") then
            local primaryPart = caseChar.PrimaryPart or caseChar:FindFirstChildWhichIsA("BasePart")
            if not primaryPart then
                dbg("WARN: CaseChar model has no usable part")
                return
            end
            targetCFrame = primaryPart.CFrame
        elseif caseChar:IsA("BasePart") then
            targetCFrame = caseChar.CFrame
        else
            dbg("WARN: CaseChar is not Model or BasePart")
            return
        end

        preTPPosition = hrp.CFrame
        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        isAtCaseChar = true
        dbg("teleported to CaseChar")
    else
        if preTPPosition then
            hrp.CFrame = preTPPosition
        end
        isAtCaseChar = false
        preTPPosition = nil
        dbg("teleported back to origin")
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    hasEvaded = false
    originalPositionCFrame = nil
    isAtCaseChar = false
    preTPPosition = nil
    dbg("character respawn detected, session flags reset")
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

dbg("all modules wired, ui finalized")
dbg("ScaseOhrip fully loaded and operational")
print(DEBUG_PREFIX .. " ready.")
