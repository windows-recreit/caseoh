--[[
    rip.hub - Loader
    Entry point. Fetches Names, ESP, and Menu modules via loadstring + HttpGet.
    Redesigned aesthetic layout with completion animation sequence.
]]

local MODULE_URLS = {
    Names = "https://raw.githubusercontent.com/windows-recreit/caseoh/refs/heads/main/Names.luau",
    ESP   = "https://raw.githubusercontent.com/windows-recreit/caseoh/refs/heads/main/ESP.luau",
    Menu  = "https://raw.githubusercontent.com/windows-recreit/caseoh/refs/heads/main/Menu.luau",
}

local START_TIME = os.time()
local LAST_WATCHDOG_CHECK = "Never"

local function dbg(msg)
    print("[rip.hub] " .. tostring(msg))
end

----------------------------------------------------------------
-- Loading Screen Structure
----------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "riphub_Loading"
LoadingGui.ResetOnSpawn = false
LoadingGui.DisplayOrder = 1000
LoadingGui.Parent = PlayerGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(0, 260, 0, 90)
LoadingFrame.Position = UDim2.new(0.5, -130, 0.5, -45)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = LoadingGui

local LoadingCorner = Instance.new("UICorner")
LoadingCorner.CornerRadius = UDim.new(0, 4)
LoadingCorner.Parent = LoadingFrame

local LoadingStroke = Instance.new("UIStroke")
LoadingStroke.Color = Color3.fromRGB(180, 0, 0)
LoadingStroke.Thickness = 1
LoadingStroke.Parent = LoadingFrame

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Size = UDim2.new(1, -20, 0, 24)
LoadingTitle.Position = UDim2.new(0, 10, 0, 14)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "rip.hub"
LoadingTitle.Font = Enum.Font.SpecialElite
LoadingTitle.TextSize = 18
LoadingTitle.TextColor3 = Color3.fromRGB(200, 200, 205)
LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left
LoadingTitle.Parent = LoadingFrame

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Size = UDim2.new(1, -20, 0, 16)
LoadingStatus.Position = UDim2.new(0, 10, 0, 40)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "summoning..."
LoadingStatus.Font = Enum.Font.Code
LoadingStatus.TextSize = 11
LoadingStatus.TextColor3 = Color3.fromRGB(120, 30, 30)
LoadingStatus.TextXAlignment = Enum.TextXAlignment.Left
LoadingStatus.Parent = LoadingFrame

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, -20, 0, 4)
BarBg.Position = UDim2.new(0, 10, 0, 64)
BarBg.BackgroundColor3 = Color3.fromRGB(25, 15, 15)
BarBg.BorderSizePixel = 0
BarBg.Parent = LoadingFrame

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBg

local function setLoadingProgress(fraction, statusText)
    fraction = math.clamp(fraction, 0, 1)
    LoadingStatus.Text = statusText or LoadingStatus.Text
    TweenService:Create(BarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(fraction, 0, 1, 0)
    }):Play()
end

-- Decal Completion Animation Sequence
local function playCompletionDecal()
    local DecalGui = Instance.new("ScreenGui")
    DecalGui.Name = "riphub_DecalAnim"
    DecalGui.DisplayOrder = 1001
    DecalGui.Parent = PlayerGui

    local ImageLabel = Instance.new("ImageLabel")
    ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    ImageLabel.Size = UDim2.new(0, 10, 0, 10)
    ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImageLabel.BackgroundTransparency = 1
    ImageLabel.Image = "http://www.roblox.com/asset/?id=280284240"
    ImageLabel.ImageTransparency = 1
    ImageLabel.Parent = DecalGui

    -- Sequence Step: Fade in + Scale rapidly with deceleration drag spacing
    local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local anim = TweenService:Create(ImageLabel, info, {
        Size = UDim2.new(0, 550, 0, 550),
        ImageTransparency = 0
    })
    anim:Play()
    anim.Completed:Wait()
    task.wait(0.2)

    -- Sequence Step: Rapidly fade out
    local fadeOut = TweenService:Create(ImageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
        ImageTransparency = 1
    })
    fadeOut:Play()
    fadeOut.Completed:Wait()
    DecalGui:Destroy()
end

local function closeLoadingScreen()
    TweenService:Create(LoadingFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadingStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
    TweenService:Create(LoadingTitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    TweenService:Create(LoadingStatus, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    TweenService:Create(BarBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(BarFill, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.2)
    LoadingGui:Destroy()
end

setLoadingProgress(0.05, "Awakening...")

local function fetchModule(moduleName, url)
    local ok, result = pcall(function()
        local src = game:HttpGet(url)
        local chunk, compileErr = loadstring(src)
        if not chunk then error("compile error: " .. tostring(compileErr)) end
        return chunk()
    end)
    if ok then return result else dbg("Failed to load " .. moduleName .. ": " .. tostring(result)) return nil end
end

----------------------------------------------------------------
-- Module Resolution Order
----------------------------------------------------------------

setLoadingProgress(0.2, "Ingesting Names...")
local Names = fetchModule("Names", MODULE_URLS.Names) or {
    NameTargets = { bananaPeel = { color = Color3.fromRGB(255, 255, 0), multiple = true } },
    PathTargets = { CaseChar = { path = {"Workspace", "CaseChar"}, color = Color3.fromRGB(255, 0, 0) } },
    References = { FightMusic = {"Workspace", "Sounds", "FightMusic"}, Atmosphere = {"Lighting", "Atmosphere"}, StinkPartName = "Stink" },
    PlayerHighlight = { color = Color3.fromRGB(0, 255, 0) },
}

setLoadingProgress(0.5, "Ingesting ESP...")
local ESP = fetchModule("ESP", MODULE_URLS.ESP)

setLoadingProgress(0.8, "Ingesting Menu Layout...")
local Menu = fetchModule("Menu", MODULE_URLS.Menu)
if not Menu then closeLoadingScreen() return end

setLoadingProgress(1.0, "Ready")
closeLoadingScreen()
task.spawn(playCompletionDecal)

----------------------------------------------------------------
-- Runtime State Monitoring
----------------------------------------------------------------

if ESP then
    ESP.Init({ Names = Names, dbg = dbg })
    ESP.StartWatchdog()
    local oldTick = ESP.WatchdogTick
    if oldTick then
        ESP.WatchdogTick = function(...)
            LAST_WATCHDOG_CHECK = os.date("%H:%M:%S")
            return oldTick(...)
        end
    else
        task.spawn(function()
            while task.wait(0.5) do LAST_WATCHDOG_CHECK = os.date("%H:%M:%S") end
        end)
    end
end
Menu.SetDebug(dbg)

----------------------------------------------------------------
-- Handle Asynchronous Target Identity Validation
----------------------------------------------------------------

local isBetaUser = false
local ok, targetId = pcall(function()
    return Players:GetUserIdFromNameAsync("plechonasnimke")
end)
if ok and LocalPlayer.UserId == targetId then
    isBetaUser = true
end

----------------------------------------------------------------
-- Interface Build Core
----------------------------------------------------------------

local Window = Menu.CreateWindow({ Name = "rip.hub" })

-- 1. Home Panel Setup
local HomePage = Window:CreateTab("Home")
HomePage:CreateSectionLabel("USER METRICS")
HomePage:CreateInfoLabel("Executor Identity: " .. tostring(LocalPlayer.Name))

local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size100x100
local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, thumbSize)

if isReady then
    local pfpFrame = Instance.new("Frame")
    pfpFrame.Size = UDim2.new(0, 60, 0, 60)
    pfpFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    pfpFrame.LayoutOrder = 2
    pfpFrame.Parent = HomePage.ScrollingFrame
    
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = pfpFrame
    local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(100, 0, 0) s.Thickness = 1 s.Parent = pfpFrame

    local pfpImage = Instance.new("ImageLabel")
    pfpImage.Size = UDim2.new(1, -4, 1, -4)
    pfpImage.Position = UDim2.new(0, 2, 0, 2)
    pfpImage.BackgroundTransparency = 1
    pfpImage.Image = content
    pfpImage.Parent = pfpFrame
    
    local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(0, 4) ic.Parent = pfpImage
end

HomePage:CreateSectionLabel("EXECUTION")
HomePage:CreateInfoLabel("Status: Root Modules Injected Successfully")

-- Standard Configuration Content 
local StablePage = Window:CreateTab("Stable")

StablePage:CreateSectionLabel("COMBAT")

StablePage:CreateToggle("Evade Fight on start", false, function(value)
    EvadeFightEnabled = value
    if value then setupEvadeFight() else teardownEvadeFight() end
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

-- 2. Secret Beta Generation Guard
if isBetaUser then
    local BetaPage = Window:CreateTab("Beta")
    BetaPage:CreateSectionLabel("RESTRICTED SUB-MODULES")
    
    BetaPage:CreateButton("Run DexPlusPlus", function()
        loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
    end)
    
    BetaPage:CreateButton("Get Info", function()
        local upTime = os.time() - START_TIME
        local formattedText = string.format(
            "==== rip.hub Diagnostic Node ====\nTimestamp: %s\nUptime Count: %ds\nWatchdog Tick Latency: %s\nSystem Integrity: Operational\n=================================",
            os.date("%Y-%m-%d %H:%M:%S"),
            upTime,
            LAST_WATCHDOG_CHECK
        )
        -- Output configuration to diagnostic logs
        print(formattedText)
        -- Instantiation layout inside interface environment panel
        Window:DisplayInfoOverlay(formattedText)
    end)
end

dbg("Initialization Chain Terminated")
