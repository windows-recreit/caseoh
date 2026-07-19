--[[
    Menu.luau
    Custom Rayfield-style dark UI with creepy rip theme. No external dependencies.
    Exposes CreateWindow-ish API consumed by Loader to build tabs/toggles/buttons.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Menu = {}

local dbg = function(msg) print(tostring(msg)) end
function Menu.SetDebug(fn)
    if fn then dbg = fn end
end

local Theme = {
    Background = Color3.fromRGB(8, 8, 12),
    Sidebar = Color3.fromRGB(4, 4, 8),
    Accent = Color3.fromRGB(180, 30, 30),
    AccentDim = Color3.fromRGB(120, 20, 20),
    TextPrimary = Color3.fromRGB(220, 220, 225),
    TextSecondary = Color3.fromRGB(140, 140, 145),
    ToggleOff = Color3.fromRGB(40, 40, 45),
    ToggleOn = Color3.fromRGB(180, 30, 30),
    ButtonBg = Color3.fromRGB(20, 20, 25),
    ButtonHover = Color3.fromRGB(35, 25, 25),
    Stroke = Color3.fromRGB(180, 30, 30),
    Glow = Color3.fromRGB(200, 20, 20),
}
Menu.Theme = Theme

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Parent = inst
    return s
end

-- Better glitch text effect - subtle character swaps instead of color flicker
local function createGlitchText(parent, text, fontSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = fontSize or 16
    label.TextColor3 = Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    
    local originalText = text
    local glitchChars = {"░", "▒", "▓", "█", "▄", "▀", "■", "□", "▪", "▫"}
    
    -- Subtle glitch effect - occasional character swaps
    local glitchConnection = nil
    local function startGlitch()
        if glitchConnection then return end
        glitchConnection = RunService.Heartbeat:Connect(function()
            if math.random() < 0.008 then -- 0.8% chance per frame
                local chars = {}
                for i = 1, #originalText do
                    if math.random() < 0.15 then -- 15% chance to glitch each character
                        chars[i] = glitchChars[math.random(#glitchChars)]
                    else
                        chars[i] = originalText:sub(i, i)
                    end
                end
                label.Text = table.concat(chars)
                
                -- Reset after a short time
                task.wait(0.05 + math.random() * 0.1)
                label.Text = originalText
            end
        end)
    end
    startGlitch()
    
    return label
end

-- Decal at top
local function addDecal(parent, assetId)
    local image = Instance.new("ImageLabel")
    image.Size = UDim2.new(0, 30, 0, 30)
    image.Position = UDim2.new(0, 5, 0.5, -15)
    image.BackgroundTransparency = 1
    image.Image = assetId
    image.Parent = parent
    return image
end

----------------------------------------------------------------
-- Window creation
----------------------------------------------------------------

function Menu.CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "rip.hub"

    local existing = PlayerGui:FindFirstChild(windowName .. "_UI")
    if existing then
        existing:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = windowName .. "_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    -- No rounded corners
    local mainFrameStroke = stroke(MainFrame, Theme.Stroke, 2)

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Theme.Sidebar
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    -- No rounded corners
    stroke(TitleBar, Theme.Stroke, 1)

    -- Decal in title bar
    addDecal(TitleBar, "http://www.roblox.com/asset/?id=280284240")

    -- Glitch title with better effect
    local TitleText = createGlitchText(TitleBar, "rip.hub", 16)
    TitleText.Position = UDim2.new(0, 40, 0, 0)
    TitleText.Size = UDim2.new(1, -50, 1, 0)

    -- Drag logic
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    -- Outline on sidebar
    stroke(Sidebar, Theme.Stroke, 1)

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Padding = UDim.new(0, 4)
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Parent = Sidebar

    local SidebarPad = Instance.new("UIPadding")
    SidebarPad.PaddingTop = UDim.new(0, 10)
    SidebarPad.PaddingLeft = UDim.new(0, 8)
    SidebarPad.PaddingRight = UDim.new(0, 8)
    SidebarPad.Parent = Sidebar

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -130, 1, -40)
    ContentArea.Position = UDim2.new(0, 130, 0, 40)
    ContentArea.BackgroundColor3 = Theme.Background
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = MainFrame
    -- Outline on content area
    stroke(ContentArea, Theme.Stroke, 1)


    ----------------------------------------------------------------
    -- Window object
    ----------------------------------------------------------------

    local WindowObj = {}
    WindowObj.ScreenGui = ScreenGui
    WindowObj.MainFrame = MainFrame
    WindowObj.Stroke = mainFrameStroke

    local Tabs = {}
    local TabButtons = {}
    local currentTab = nil
    local tabOrder = 0
    local elementOrder = {}

    local function nextOrder(page)
        elementOrder[page] = (elementOrder[page] or 0) + 1
        return elementOrder[page]
    end

    local function selectTab(tabName)
        for name, page in pairs(Tabs) do
            page.Visible = (name == tabName)
        end
        for name, btn in pairs(TabButtons) do
            if name == tabName then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.AccentDim}):Play()
                btn.TextLabel.TextColor3 = Theme.TextPrimary
                -- Outline on active tab - find the UIStroke
                local tabStroke = btn:FindFirstChildOfClass("UIStroke")
                if tabStroke then
                    tabStroke.Color = Theme.Accent
                    tabStroke.Thickness = 2
                end
            else
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Sidebar}):Play()
                btn.TextLabel.TextColor3 = Theme.TextSecondary
                local tabStroke = btn:FindFirstChildOfClass("UIStroke")
                if tabStroke then
                    tabStroke.Color = Theme.Stroke
                    tabStroke.Thickness = 1
                end
            end
        end
        currentTab = tabName
    end

    function WindowObj:CreateTab(name)
        tabOrder = tabOrder + 1

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea

        local PagePad = Instance.new("UIPadding")
        PagePad.PaddingTop = UDim.new(0, 12)
        PagePad.PaddingLeft = UDim.new(0, 12)
        PagePad.PaddingRight = UDim.new(0, 12)
        PagePad.PaddingBottom = UDim.new(0, 12)
        PagePad.Parent = Page

        local PageList = Instance.new("UIListLayout")
        PageList.Padding = UDim.new(0, 8)
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Parent = Page

        Tabs[name] = Page

        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "TabButton"
        TabButton.Size = UDim2.new(1, 0, 0, 32)
        TabButton.BackgroundColor3 = Theme.Sidebar
        TabButton.AutoButtonColor = false
        TabButton.Text = ""
        TabButton.LayoutOrder = tabOrder
        TabButton.Parent = Sidebar
        -- No rounded corners on tabs
        stroke(TabButton, Theme.Stroke, 1)

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TextLabel"
        TabLabel.Size = UDim2.new(1, -10, 1, 0)
        TabLabel.Position = UDim2.new(0, 10, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = name
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextSize = 14
        TabLabel.TextColor3 = Theme.TextSecondary
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabButton

        TabButton.MouseButton1Click:Connect(function()
            selectTab(name)
        end)

        TabButtons[name] = TabButton

        if not currentTab then
            selectTab(name)
        end

        ------------------------------------------------------------
        -- Page object (element factories)
        ------------------------------------------------------------

        local PageObj = {}

        function PageObj:CreateSectionLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.Font = Enum.Font.GothamBold
            Label.TextSize = 13
            Label.TextColor3 = Theme.TextSecondary
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.LayoutOrder = nextOrder(Page)
            Label.Parent = Page
            return Label
        end

        function PageObj:CreateInfoLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 24)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextColor3 = Theme.TextSecondary
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            Label.LayoutOrder = nextOrder(Page)
            Label.Parent = Page
            return Label
        end

        function PageObj:CreateToggle(name2, default, callback)
            default = default or false

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 38)
            Holder.BackgroundColor3 = Theme.ButtonBg
            Holder.BorderSizePixel = 0
            Holder.LayoutOrder = nextOrder(Page)
            Holder.Parent = Page
            -- No rounded corners on toggles
            stroke(Holder, Theme.Stroke, 1)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name2
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextColor3 = Theme.TextPrimary
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Holder

            local SwitchBg = Instance.new("Frame")
            SwitchBg.Size = UDim2.new(0, 38, 0, 20)
            SwitchBg.Position = UDim2.new(1, -50, 0.5, -10)
            SwitchBg.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
            SwitchBg.BorderSizePixel = 0
            SwitchBg.Parent = Holder
            -- No rounded corners on toggle background
            stroke(SwitchBg, Theme.Stroke, 1)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 16, 0, 16)
            Knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            Knob.Parent = SwitchBg

            local ClickCatcher = Instance.new("TextButton")
            ClickCatcher.Size = UDim2.new(1, 0, 1, 0)
            ClickCatcher.BackgroundTransparency = 1
            ClickCatcher.Text = ""
            ClickCatcher.Parent = Holder

            local state = default

            local function updateVisual()
                local targetColor = state and Theme.ToggleOn or Theme.ToggleOff
                local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                TweenService:Create(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
                TweenService:Create(Knob, TweenInfo.new(0.15), {Position = targetPos}):Play()
            end

            ClickCatcher.MouseButton1Click:Connect(function()
                state = not state
                updateVisual()
                local ok, err = pcall(callback, state)
                if not ok then
                    dbg("callback error on '" .. name2 .. "': " .. tostring(err))
                end
            end)

            return Holder
        end

        function PageObj:CreateButton(name2, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 38)
            Btn.BackgroundColor3 = Theme.ButtonBg
            Btn.AutoButtonColor = false
            Btn.Text = name2
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 13
            Btn.TextColor3 = Theme.TextPrimary
            Btn.LayoutOrder = nextOrder(Page)
            Btn.Parent = Page
            -- No rounded corners on buttons
            local btnStroke = stroke(Btn, Theme.Stroke, 1)

            Btn.MouseEnter:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ButtonHover}):Play()
                btnStroke.Color = Theme.Accent
                btnStroke.Thickness = 2
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ButtonBg}):Play()
                btnStroke.Color = Theme.Stroke
                btnStroke.Thickness = 1
            end)

            Btn.MouseButton1Click:Connect(function()
                local ok, err = pcall(callback)
                if not ok then
                    dbg("callback error on '" .. name2 .. "': " .. tostring(err))
                end
            end)

            return Btn
        end

        return PageObj
    end

    ------------------------------------------------------------
    -- Rainbow corners (operates on the main frame's UIStroke)
    ------------------------------------------------------------

    local rainbowConnection = nil

    function WindowObj:EnableRainbowCorners()
        if rainbowConnection then return end
        mainFrameStroke.Thickness = 2
        local hue = 0
        rainbowConnection = RunService.Heartbeat:Connect(function(dt)
            hue = (hue + dt * 0.15) % 1
            mainFrameStroke.Color = Color3.fromHSV(hue, 1, 1)
        end)
    end

    function WindowObj:DisableRainbowCorners()
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
        mainFrameStroke.Color = Theme.Stroke
        mainFrameStroke.Thickness = 2
    end

    return WindowObj
end

return Menu
