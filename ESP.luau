--[[
    ESP.luau
    Handles all Highlight instances: banana peel highlight, anti banana peel,
    CaseChar highlight, and player highlights.

    Bugfix: highlights are watched via a periodic watchdog (every 0.5s).
    If a highlight instance disappears (destroyed/replaced by the game or
    another script), it is recreated. The watchdog does NOT rapidly
    recreate on every heartbeat - it only checks on its own interval,
    and only touches highlights whose feature is still toggled on.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ESP = {}

local WATCHDOG_INTERVAL = 0.5

----------------------------------------------------------------
-- Dependencies (injected by Loader)
----------------------------------------------------------------

local Names = nil
local dbg = function(msg) print(tostring(msg)) end

function ESP.Init(deps)
    deps = deps or {}
    Names = deps.Names or { NameTargets = {}, PathTargets = {}, References = {}, PlayerHighlight = { color = Color3.fromRGB(0,255,0) } }
    if deps.dbg then dbg = deps.dbg end
end

----------------------------------------------------------------
-- Internal state
----------------------------------------------------------------

local State = {
    BananaHighlight = false,
    AntiBanana = false,
    CaseCharHighlight = false,
    HighlightPlayers = false,
}

-- tracked[instance] = { highlight = Highlight, color = Color3 }
local trackedBanana = {}
local trackedCaseChar = nil -- { instance = ..., highlight = ..., color = ... }
local trackedPlayers = {} -- [player] = { instance = char, highlight = Highlight, color = Color3 }

local bananaAddedConn, bananaRemovedConn = nil, nil
local antiBananaAddedConn = nil
local playerAddedConn, playerRemovingConn = nil, nil
local charAddedConns = {}

local watchdogConnection = nil
local watchdogAccum = 0

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function resolvePath(pathTable)
    local current = game
    for _, segment in ipairs(pathTable) do
        if not current then return nil end
        current = current:FindFirstChild(segment)
    end
    return current
end

local function applyHighlight(instance, color, fillTransparency)
    local existing = instance:FindFirstChildOfClass("Highlight")
    if existing then
        existing:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = fillTransparency or 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = instance
    highlight.Parent = instance
    return highlight
end

local function isHighlightAlive(entry)
    if not entry then return false end
    local h = entry.highlight
    if not h or not h.Parent then return false end
    if h.Adornee ~= entry.instance then return false end
    return true
end

local function getAllBananaPeels()
    local targetDef = Names.NameTargets and Names.NameTargets.bananaPeel
    local peels = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "bananaPeel" then
            table.insert(peels, obj)
        end
    end
    return peels
end

local function getBananaColor()
    local def = Names.NameTargets and Names.NameTargets.bananaPeel
    return (def and def.color) or Color3.fromRGB(255, 255, 0)
end

local function getCaseCharDef()
    local def = Names.PathTargets and Names.PathTargets.CaseChar
    if def and def.path then
        return def
    end
    -- fallback if Names failed to load / no path given
    return { path = {"Workspace", "CaseChar"}, color = Color3.fromRGB(255, 0, 0) }
end

local function getPlayerHighlightColor()
    local def = Names.PlayerHighlight
    return (def and def.color) or Color3.fromRGB(0, 255, 0)
end

----------------------------------------------------------------
-- Banana peel highlight
----------------------------------------------------------------

local function highlightBananaPeel(peel)
    if trackedBanana[peel] and isHighlightAlive(trackedBanana[peel]) then return end
    local color = getBananaColor()
    local h = applyHighlight(peel, color)
    trackedBanana[peel] = { instance = peel, highlight = h, color = color }
end

function ESP.EnableBananaHighlight()
    State.BananaHighlight = true
    for _, peel in ipairs(getAllBananaPeels()) do
        highlightBananaPeel(peel)
    end

    bananaAddedConn = Workspace.ChildAdded:Connect(function(child)
        if not State.BananaHighlight then return end
        if child.Name == "bananaPeel" then
            highlightBananaPeel(child)
        end
    end)

    bananaRemovedConn = Workspace.ChildRemoved:Connect(function(child)
        if trackedBanana[child] then
            trackedBanana[child] = nil
        end
    end)

end

function ESP.DisableBananaHighlight()
    State.BananaHighlight = false
    if bananaAddedConn then bananaAddedConn:Disconnect(); bananaAddedConn = nil end
    if bananaRemovedConn then bananaRemovedConn:Disconnect(); bananaRemovedConn = nil end

    for peel, entry in pairs(trackedBanana) do
        if entry.highlight then entry.highlight:Destroy() end
    end
    trackedBanana = {}
end

----------------------------------------------------------------
-- Anti banana peel
----------------------------------------------------------------

function ESP.EnableAntiBanana()
    State.AntiBanana = true
    for _, peel in ipairs(getAllBananaPeels()) do
        peel:Destroy()
    end

    antiBananaAddedConn = Workspace.ChildAdded:Connect(function(child)
        if not State.AntiBanana then return end
        if child.Name == "bananaPeel" then
            child:Destroy()
        end
    end)
end

function ESP.DisableAntiBanana()
    State.AntiBanana = false
    if antiBananaAddedConn then antiBananaAddedConn:Disconnect(); antiBananaAddedConn = nil end
end

----------------------------------------------------------------
-- CaseChar highlight
----------------------------------------------------------------

function ESP.EnableCaseCharHighlight()
    State.CaseCharHighlight = true
    local def = getCaseCharDef()
    local caseChar = resolvePath(def.path)
    if not caseChar then
        dbg("WARN: CaseChar path did not resolve")
        return
    end
    local h = applyHighlight(caseChar, def.color)
    trackedCaseChar = { instance = caseChar, highlight = h, color = def.color, path = def.path }
end

function ESP.DisableCaseCharHighlight()
    State.CaseCharHighlight = false
    if trackedCaseChar and trackedCaseChar.highlight then
        trackedCaseChar.highlight:Destroy()
    end
    trackedCaseChar = nil
end

----------------------------------------------------------------
-- Player highlight
----------------------------------------------------------------

local function isCaseCharInstance(char)
    if not char then return false end
    local def = getCaseCharDef()
    local caseChar = resolvePath(def.path)
    if not caseChar then return false end
    return char == caseChar or char:IsDescendantOf(caseChar) or caseChar:IsDescendantOf(char)
end

local function highlightPlayer(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if isCaseCharInstance(char) then return end

    if trackedPlayers[player] and isHighlightAlive(trackedPlayers[player]) and trackedPlayers[player].instance == char then
        return
    end

    local color = getPlayerHighlightColor()
    local h = applyHighlight(char, color)
    trackedPlayers[player] = { instance = char, highlight = h, color = color }
end

local function unhighlightPlayer(player)
    local entry = trackedPlayers[player]
    if entry and entry.highlight then
        entry.highlight:Destroy()
    end
    trackedPlayers[player] = nil
end

function ESP.EnableHighlightPlayers()
    State.HighlightPlayers = true

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            highlightPlayer(player)
            local conn = player.CharacterAdded:Connect(function()
                if State.HighlightPlayers and player ~= LocalPlayer then
                    task.wait(0.1)
                    highlightPlayer(player)
                end
            end)
            charAddedConns[player] = conn
        end
    end

    playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if not State.HighlightPlayers or player == LocalPlayer then return end
        local conn = player.CharacterAdded:Connect(function()
            if State.HighlightPlayers and player ~= LocalPlayer then
                task.wait(0.1)
                highlightPlayer(player)
            end
        end)
        charAddedConns[player] = conn
    end)

    playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        unhighlightPlayer(player)
        if charAddedConns[player] then
            charAddedConns[player]:Disconnect()
            charAddedConns[player] = nil
        end
    end)

end

function ESP.DisableHighlightPlayers()
    State.HighlightPlayers = false
    if playerAddedConn then playerAddedConn:Disconnect(); playerAddedConn = nil end
    if playerRemovingConn then playerRemovingConn:Disconnect(); playerRemovingConn = nil end
    for player, conn in pairs(charAddedConns) do
        if conn then conn:Disconnect() end
    end
    charAddedConns = {}
    for player, entry in pairs(trackedPlayers) do
        if entry.highlight then entry.highlight:Destroy() end
    end
    trackedPlayers = {}
end

----------------------------------------------------------------
-- Watchdog: re-applies highlights that got silently destroyed/replaced.
-- Runs on a fixed interval (not every frame) and only touches entries
-- whose feature toggle is currently ON.
----------------------------------------------------------------

local function watchdogTick()
    if State.BananaHighlight then
        for peel, entry in pairs(trackedBanana) do
            if not peel.Parent then
                trackedBanana[peel] = nil
            elseif not isHighlightAlive(entry) then
                local h = applyHighlight(peel, entry.color)
                trackedBanana[peel] = { instance = peel, highlight = h, color = entry.color }
            end
        end
    end

    if State.CaseCharHighlight and trackedCaseChar then
        if not trackedCaseChar.instance.Parent then
            -- instance itself gone, try to re-resolve from path
            local reResolved = resolvePath(trackedCaseChar.path)
            if reResolved then
                local h = applyHighlight(reResolved, trackedCaseChar.color)
                trackedCaseChar = { instance = reResolved, highlight = h, color = trackedCaseChar.color, path = trackedCaseChar.path }
            end
        elseif not isHighlightAlive(trackedCaseChar) then
            local h = applyHighlight(trackedCaseChar.instance, trackedCaseChar.color)
            trackedCaseChar.highlight = h
        end
    end

    if State.HighlightPlayers then
        for player, entry in pairs(trackedPlayers) do
            local char = player.Character
            if not char then
                -- character gone, leave entry, CharacterAdded will refresh it
            elseif isCaseCharInstance(char) then
                unhighlightPlayer(player)
            elseif entry.instance ~= char then
                -- character respawned, refresh
                highlightPlayer(player)
            elseif not isHighlightAlive(entry) then
                local h = applyHighlight(entry.instance, entry.color)
                entry.highlight = h
            end
        end
    end
end

function ESP.StartWatchdog()
    if watchdogConnection then return end
    watchdogAccum = 0
    watchdogConnection = RunService.Heartbeat:Connect(function(dt)
        watchdogAccum = watchdogAccum + dt
        if watchdogAccum >= WATCHDOG_INTERVAL then
            watchdogAccum = 0
            watchdogTick()
        end
    end)
end

function ESP.StopWatchdog()
    if watchdogConnection then
        watchdogConnection:Disconnect()
        watchdogConnection = nil
    end
end

return ESP
