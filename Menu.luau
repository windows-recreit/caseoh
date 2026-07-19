--[[
    rip.hub - Menu Frame Custom Layout
    Minimalist horror adaptation: near-black canvases, razor sharp red accents,
    flickering low-level string title rendering, custom visual diagnostic panels.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Menu = {}
local dbg = function(msg) print(tostring(msg)) end
function Menu.SetDebug(fn) if fn then dbg = fn end end

local Theme = {
    Background = Color3.fromRGB(10, 10, 12),
    Sidebar = Color3.fromRGB(6, 6, 8),
    Accent = Color3.fromRGB(180, 0, 0),
    AccentDim = Color3.fromRGB(80, 0, 0),
    TextPrimary = Color3.fromRGB(210, 210, 215),
    TextSecondary = Color3.fromRGB(110, 110, 115),
    ToggleOff = Color3.fromRGB(24, 16, 16),
    ToggleOn = Color3.fromRGB(180, 0, 0),
    ButtonBg = Color3.fromRGB(16, 16, 20),
    ButtonHover = Color3.fromRGB(26, 16, 16),
    Stroke = Color3.fromRGB(40, 15, 15),
}
Menu.Theme = Theme

local function corner(inst, radius)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, radius or 4) c.Parent = inst
    return c
end

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke") s.Color = color or Theme.Stroke s.Thickness = thickness or 1 s.Parent = inst
    return s
end

function Menu.CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "rip.hub"

    local existing = PlayerGui:FindFirstChild(windowName .. "_UI")
    if existing then existing:Destroy() end

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
    corner(MainFrame, 4)
    local mainFrameStroke = stroke(MainFrame, Theme.Stroke, 1)

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 42)
    TitleBar.BackgroundColor3 = Theme.Sidebar
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    corner(TitleBar, 4)

    -- Near-name branding decal addition
    local TitleDecal = Instance.new("ImageLabel")
    TitleDecal.Size = UDim2.new(0, 24, 0, 24)
    TitleDecal.Position = UDim2.new(0, 12, 0.5, -12)
    TitleDecal.BackgroundTransparency = 1
    TitleDecal.Image = "http://www.roblox.com/asset/?id=280284240"
    TitleDecal.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -60, 1, 0)
    TitleText.Position = UDim2.new(0, 44, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = windowName
    TitleText.Font = Enum.Font.SpecialElite
    TitleText.TextSize = 16
    TitleText.TextColor3 = Theme.TextPrimary
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- Glitchy Text Flicker Script Engine Execution Loop
    task.spawn(function()
        local rawText = windowName
        local glyphs = {"†", "‡", "§", "", "X", "R", "I", "P"}
        while MainFrame.Parent do
            task.wait(math.random(2, 7))
            for i = 1, math.random(2, 4) do
                local len = string.len(rawText)
                local rPos = math.random(1, len)
                local rGlyph = glyphs[math.random(1, #glyphs)]
                TitleText.Text = string.sub(rawText, 1, rPos - 1) .. rGlyph .. string.sub(rawText, rPos + 1)
                TitleText.TextColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(math.random(0.05, 0.15))
                TitleText.Text = rawText
                TitleText.TextColor3 = Theme.TextPrimary
            end
        end
    end)

    -- Drag Execution
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 130, 1, -42)
    Sidebar.Position = UDim2.new(0, 0, 0, 42)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarList = Instance.new("UIListLayout") SidebarList.Padding = UDim.new(0, 4) SidebarList.SortOrder = Enum.SortOrder.LayoutOrder SidebarList.Parent = Sidebar
    local SidebarPad = Instance.new("UIPadding") SidebarPad.PaddingTop = UDim.new(0, 10) SidebarPad.PaddingLeft = UDim.new(0, 8) SidebarPad.PaddingRight = UDim.new(0, 8) SidebarPad.Parent = Sidebar

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -130, 1, -42)
    ContentArea.Position = UDim2.new(0, 130, 0, 42)
    ContentArea.BackgroundColor3 = Theme.Background
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = MainFrame

    -- Overlay Module Display Environment Box for "Get Info" output
    local OverlayPanel = Instance.new("Frame")
    OverlayPanel.Size = UDim2.new(1, -20, 1, -20)
    OverlayPanel.Position = UDim2.new(0, 10, 0, 10)
    OverlayPanel.BackgroundColor3 = Color3.fromRGB(5, 5, 7)
    OverlayPanel.Visible = false
    OverlayPanel.ZIndex = 10
    OverlayPanel.Parent = ContentArea
    corner(OverlayPanel, 4)
    stroke(OverlayPanel, Color3.fromRGB(120, 0, 0), 1)

    local OverlayText = Instance.new("TextLabel")
    OverlayText.Size = UDim2.new(1, -20, 1, -40)
    OverlayText.Position = UDim2.new(0, 10, 0, 10)
    OverlayText.BackgroundTransparency = 1
    OverlayText.Font = Enum.Font.Code
    OverlayText.TextSize = 11
    OverlayText.TextColor3 = Color3.fromRGB(180, 150, 150)
    OverlayText.TextXAlignment = Enum.TextXAlignment.Left
    OverlayText.TextYAlignment = Enum.TextYAlignment.Top
    OverlayText.Parent = OverlayPanel

    local OverlayClose = Instance.new("TextButton")
    OverlayClose.Size = UDim2.new(0, 60, 0, 22)
    OverlayClose.Position = UDim2.new(1, -70, 1, -28)
    OverlayClose.BackgroundColor3 = Theme.ButtonBg
    OverlayClose.Text = "Close"
    OverlayClose.Font = Enum.Font.Code
    OverlayClose.TextSize = 12
    OverlayClose.TextColor3 = Theme.TextPrimary
    OverlayClose.Parent = OverlayPanel
    corner(OverlayClose, 4)
    stroke(OverlayClose, Theme.Stroke, 1)
    OverlayClose.MouseButton1Click:Connect(function() OverlayPanel.Visible = false end)

    local WindowObj = { ScreenGui = ScreenGui, MainFrame = MainFrame, Stroke = mainFrameStroke }
    local Tabs, TabButtons, currentTab, tabOrder, elementOrder = {}, {}, nil, 0, {}

    local function nextOrder(page)
        elementOrder[page] = (elementOrder[page] or 0) + 1
        return elementOrder[page]
    end

    local function selectTab(tabName)
        for name, page in pairs(Tabs) do page.Visible = (name == tabName) end
        for name, btn in pairs(TabButtons) do
            if name == tabName then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.AccentDim}):Play()
                btn.TextLabel.TextColor3 = Theme.TextPrimary
            else
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Sidebar}):Play()
                btn.TextLabel.TextColor3 = Theme.TextSecondary
            end
        end
        currentTab = tabName
    end

    function WindowObj:DisplayInfoOverlay(text)
        OverlayText.Text = text
        OverlayPanel.Visible = true
    end

    function WindowObj:CreateTab(name)
        tabOrder = tabOrder + 1

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea

        local PagePad = Instance.new("UIPadding") PagePad.PaddingTop = UDim.new(0, 12) PagePad.PaddingLeft = UDim.new(0, 12) PagePad.PaddingRight = UDim.new(0, 12) PagePad.PaddingBottom = UDim.new(0, 12) PagePad.Parent = Page
        local PageList = Instance.new("UIListLayout") PageList.Padding = UDim.new(0, 6) PageList.SortOrder = Enum.SortOrder.LayoutOrder PageList.Parent = Page

        Tabs[name] = Page

        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundColor3 = Theme.Sidebar
        TabButton.AutoButtonColor = false
        TabButton.Text = ""
        TabButton.LayoutOrder = tabOrder
        TabButton.Parent = Sidebar
        corner(TabButton, 4)

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TextLabel"
        TabLabel.Size = UDim2.new(1, -10, 1, 0)
        TabLabel.Position = UDim2.new(0, 10, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = name
        TabLabel.Font = Enum.Font.Code
        TabLabel.TextSize = 13
        TabLabel.TextColor3 = Theme.TextSecondary
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabButton

        TabButton.MouseButton1Click:Connect(function() selectTab(name) end)
        TabButtons[name] = TabButton

        if not currentTab then selectTab(name) end

        local PageObj = { ScrollingFrame = Page }

        function PageObj:CreateSectionLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 18)
            Label.BackgroundTransparency = 1
            Label.Text = "// " .. string.upper(text)
            Label.Font = Enum.Font.Code
            Label.TextSize = 11
            Label.TextColor3 = Theme.TextSecondary
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.LayoutOrder = nextOrder(Page)
            Label.Parent = Page
            return Label
        end

        function PageObj:CreateInfoLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 22)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.Font = Enum.Font.Code
            Label.TextSize = 12
            Label.TextColor3 = Theme.TextPrimary
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            Label.LayoutOrder = nextOrder(Page)
            Label.Parent = Page
            return Label
        end

        function PageObj:CreateToggle(name2, default, callback)
            default = default or false
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 34)
            Holder.BackgroundColor3 = Theme.ButtonBg
            Holder.BorderSizePixel = 0
            Holder.LayoutOrder = nextOrder(Page)
            Holder.Parent = Page
            corner(Holder, 4)
            stroke(Holder, Theme.Stroke, 1)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name2
            Label.Font = Enum.Font.Code
            Label.TextSize = 12
            Label.TextColor3 = Theme.TextPrimary
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Holder

            local SwitchBg = Instance.new("Frame")
            SwitchBg.Size = UDim2.new(0, 32, 0, 16)
            SwitchBg.Position = UDim2.new(1, -42, 0.5, -8)
            SwitchBg.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
            SwitchBg.Parent = Holder
            corner(SwitchBg, 2)
            stroke(SwitchBg, Color3.fromRGB(60, 0, 0), 1)

            local ClickCatcher = Instance.new("TextButton")
            ClickCatcher.Size = UDim2.new(1, 0, 1, 0)
            ClickCatcher.BackgroundTransparency = 1
            ClickCatcher.Text = ""
            ClickCatcher.Parent = Holder

            local state = default
            ClickCatcher.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(SwitchBg, TweenInfo.new(0.1), {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff}):Play()
                pcall(callback, state)
            end)
            return Holder
        end

        function PageObj:CreateButton(name2, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 34)
            Btn.BackgroundColor3 = Theme.ButtonBg
            Btn.AutoButtonColor = false
            Btn.Text = name2
            Btn.Font = Enum.Font.Code
            Btn.TextSize = 12
            Btn.TextColor3 = Theme.TextPrimary
            Btn.LayoutOrder = nextOrder(Page)
            Btn.Parent = Page
            corner(Btn, 4)
            local s = stroke(Btn, Theme.Stroke, 1)

            Btn.MouseEnter:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ButtonHover}):Play()
                s.Color = Color3.fromRGB(150, 0, 0)
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ButtonBg}):Play()
                s.Color = Theme.Stroke
            end)
            Btn.MouseButton1Click:Connect(function() pcall(callback) end)
            return Btn
        end

        return PageObj
    end

    return WindowObj
end

return Menu
