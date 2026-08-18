local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Library = {}
local Utility = {}

-- Новые цвета (LocalMaze Design)
local Theme = {
    MainBg = Color3.fromRGB(11, 11, 11),
    TabFrameBg = Color3.fromRGB(16, 16, 16),
    SectionBg = Color3.fromRGB(19, 19, 19),
    TabButton = Color3.fromRGB(30, 30, 30),
    TabButtonActive = Color3.fromRGB(44, 44, 44),
    TextMain = Color3.fromRGB(255, 255, 255),
    TextCategory = Color3.fromRGB(77, 77, 77),
    ToggleActive = Color3.fromRGB(255, 127, 211), -- Розовый тоггл
    ToggleInactive = Color3.fromRGB(44, 44, 44),
    ElementBg = Color3.fromRGB(30, 30, 30),
    Font = Enum.Font.ArialBold,
    LabelFont = Enum.Font.Arial
}

function Utility:Create(class, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

function Utility:MakeDraggable(topbar, window)
    local dragging
    local dragInput
    local dragStart
    local startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            
            local moveConn, endConn
            
            moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                    local delta = moveInput.Position - dragStart
                    window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)
end

function Library:CreateWindow(options)
    options = options or {}
    local windowTitle = options.Title or "Evade Script"
    local windowSize = options.Size or UDim2.new(0, 836, 0, 538)

    local ScreenGui = Utility:Create("ScreenGui", {
        Name = "LocalMazeGUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    local toggleKeyState = { key = options.ToggleKey or Enum.KeyCode.RightAlt }
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKeyState.key then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    local success = pcall(function() ScreenGui.Parent = CoreGui end)
    if not success then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    -- ==========================================
    -- Contextual Popup System
    -- ==========================================
    local PopupBg = Utility:Create("TextButton", {
        Name = "PopupBg",
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100,
        Visible = false,
        Text = "",
        AutoButtonColor = false
    })
    local PopupConnections = {}
    PopupBg.MouseButton1Click:Connect(function() 
        PopupBg.Visible = false
        for _, conn in ipairs(PopupConnections) do
            if conn.Disconnect then conn:Disconnect() end
        end
        table.clear(PopupConnections)
    end)

    local PopupFrame = Utility:Create("Frame", {
        Name = "PopupFrame",
        Parent = PopupBg,
        BackgroundColor3 = Theme.MainBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 0, 280),
        ZIndex = 101
    })
    Utility:Create("UICorner", { Parent = PopupFrame, CornerRadius = UDim.new(0, 8) })

    local PopupTitle = Utility:Create("TextLabel", {
        Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 16),
        Font = Theme.Font, Text = "Settings", TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
    })

    local PopupContent = Utility:Create("Frame", {
        Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -20, 1, -42),
        ZIndex = 102
    })
    local PopupLayout = Utility:Create("UIListLayout", { Parent = PopupContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
    PopupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
        PopupFrame.Size = UDim2.new(0, 220, 0, PopupLayout.AbsoluteContentSize.Y + 42)
    end)

    local function OpenModal(title, setupFunc, sourceElement)
        PopupTitle.Text = title
        
        for _, conn in ipairs(PopupConnections) do
            if conn.Disconnect then conn:Disconnect() end
        end
        table.clear(PopupConnections)

        for _, child in pairs(PopupContent:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        setupFunc(PopupContent)
        
        -- Positioning logic
        if sourceElement then
            local absPos = sourceElement.AbsolutePosition
            local absSize = sourceElement.AbsoluteSize
            local screenX = ScreenGui.AbsoluteSize.X
            local screenY = ScreenGui.AbsoluteSize.Y
            
            local targetX = absPos.X + absSize.X + 10
            local targetY = absPos.Y
            
            if targetX + 220 > screenX then
                targetX = absPos.X - 220 - 10
            end
            if targetY + PopupFrame.AbsoluteSize.Y > screenY then
                targetY = screenY - PopupFrame.AbsoluteSize.Y - 10
            end
            
            PopupFrame.Position = UDim2.new(0, targetX, 0, targetY)
        else
            PopupFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
        end
        PopupBg.Visible = true
    end

    local AccentUpdates = {}
    local function ApplyAccent()
        for _, func in ipairs(AccentUpdates) do
            func(Theme.ToggleActive)
        end
    end
    local function OpenColorPicker(title, defaultColor, defaultAlpha, callback, sourceElement)
        OpenModal(title, function(container)
            local currentColor = defaultColor or Color3.new(1, 1, 1)
            local currentAlpha = defaultAlpha or 1
            local colorCb = callback or function() end
            local h, s, v = currentColor:ToHSV()

            local ColorContainer = Utility:Create("Frame", { Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), ZIndex = 102 })
            
            local SVMap = Utility:Create("TextButton", { Parent = ColorContainer, BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 0, 0, 0), Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 102 })
            Utility:Create("UICorner", { Parent = SVMap, CornerRadius = UDim.new(0, 4) })
            local SatOverlay = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 0, 1, 0), ZIndex = 103 })
            Utility:Create("UIGradient", { Parent = SatOverlay, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0 })
            local ValOverlay = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 104 })
            Utility:Create("UIGradient", { Parent = ValOverlay, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90 })
            local PickerRing = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0, 6, 0, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1-v, 0), ZIndex = 105 })
            Utility:Create("UICorner", { Parent = PickerRing, CornerRadius = UDim.new(1, 0) })
            Utility:Create("UIStroke", { Parent = PickerRing, Color = Color3.new(0,0,0), Thickness = 1 })

            local HueBar = Utility:Create("TextButton", { Parent = ColorContainer, Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0, 16, 1, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 102 })
            Utility:Create("UICorner", { Parent = HueBar, CornerRadius = UDim.new(0, 4) })
            local HueGradient = Utility:Create("UIGradient", { Parent = HueBar, Rotation = 90 })
            HueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
            local HueRing = Utility:Create("Frame", { Parent = HueBar, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 2, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, h, 0), ZIndex = 106 })
            Utility:Create("UIStroke", { Parent = HueRing, Color = Color3.new(0,0,0), Thickness = 1 })

            local AlphaBar = Utility:Create("TextButton", { Parent = ColorContainer, Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 12, 1, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 102 })
            Utility:Create("UICorner", { Parent = AlphaBar, CornerRadius = UDim.new(0, 4) })
            local AlphaGradient = Utility:Create("UIGradient", { Parent = AlphaBar, Rotation = 90 })
            AlphaGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, currentColor), ColorSequenceKeypoint.new(1, Theme.ElementBg) })
            local AlphaRing = Utility:Create("Frame", { Parent = AlphaBar, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 2, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1-currentAlpha, 0), ZIndex = 106 })
            Utility:Create("UIStroke", { Parent = AlphaRing, Color = Color3.new(0,0,0), Thickness = 1 })

            local BottomContainer = Utility:Create("Frame", { Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 102 })
            local PreviewBox = Utility:Create("Frame", { Parent = BottomContainer, BackgroundColor3 = currentColor, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 102 })
            Utility:Create("UICorner", { Parent = PreviewBox, CornerRadius = UDim.new(0, 4) })

            local draggingSV, draggingHue, draggingAlpha = false, false, false

            local function updateColor()
                currentColor = Color3.fromHSV(h, s, v)
                PreviewBox.BackgroundColor3 = currentColor
                PreviewBox.BackgroundTransparency = 1 - currentAlpha
                AlphaGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, currentColor), ColorSequenceKeypoint.new(1, Theme.ElementBg) })
                colorCb(currentColor, currentAlpha)
            end

            local function updateSV(input)
                local x = math.clamp(input.Position.X - SVMap.AbsolutePosition.X, 0, SVMap.AbsoluteSize.X)
                local y = math.clamp(input.Position.Y - SVMap.AbsolutePosition.Y, 0, SVMap.AbsoluteSize.Y)
                s = x / SVMap.AbsoluteSize.X; v = 1 - (y / SVMap.AbsoluteSize.Y)
                PickerRing.Position = UDim2.new(s, 0, 1-v, 0); updateColor()
            end
            local function updateHue(input)
                local y = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
                h = y / HueBar.AbsoluteSize.Y
                HueRing.Position = UDim2.new(0.5, 0, h, 0); SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1); updateColor()
            end
            local function updateAlpha(input)
                local y = math.clamp(input.Position.Y - AlphaBar.AbsolutePosition.Y, 0, AlphaBar.AbsoluteSize.Y)
                currentAlpha = 1 - (y / AlphaBar.AbsoluteSize.Y)
                AlphaRing.Position = UDim2.new(0.5, 0, y / AlphaBar.AbsoluteSize.Y, 0); updateColor()
            end

            SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true; updateSV(input) end end)
            HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true; updateHue(input) end end)
            AlphaBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingAlpha = true; updateAlpha(input) end end)
            
            local c1 = UserInputService.InputEnded:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV, draggingHue, draggingAlpha = false, false, false end 
            end)
            local c2 = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if draggingSV then updateSV(input) end
                    if draggingHue then updateHue(input) end
                    if draggingAlpha then updateAlpha(input) end
                end
            end)
            table.insert(PopupConnections, c1); table.insert(PopupConnections, c2)
        end, sourceElement)
    end

    -- ==========================================

    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Theme.MainBg,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
        Size = windowSize,
        Active = true
    })
    Utility:Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 8) })
    Utility:MakeDraggable(MainFrame, MainFrame)

    local TabFrame = Utility:Create("Frame", {
        Name = "tabframe",
        Parent = MainFrame,
        BackgroundColor3 = Theme.TabFrameBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 216, 1, 0)
    })
    Utility:Create("UICorner", { Parent = TabFrame, CornerRadius = UDim.new(0, 8) })

    local TabButtonContainer = Utility:Create("Frame", {
        Name = "TabButtonContainer",
        Parent = TabFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 1, -50)
    })

    local AccentFrame = Utility:Create("Frame", {
        Name = "AccentFrame", Parent = TabFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 1, -30), Size = UDim2.new(1, -20, 0, 20)
    })
    local AccentIcon = Utility:Create("ImageLabel", {
        Parent = AccentFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Image = "rbxthumb://type=Asset&id=105197993761390&w=150&h=150", ImageColor3 = Theme.TextCategory
    })
    Utility:Create("TextLabel", {
        Parent = AccentFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -54, 1, 0), Font = Theme.LabelFont, Text = "Accent", TextColor3 = Theme.TextCategory, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
    })
    local AccentPickerBtn = Utility:Create("TextButton", {
        Parent = AccentFrame, BackgroundColor3 = Theme.ToggleActive, BorderSizePixel = 0, Position = UDim2.new(1, -20, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Text = "", AutoButtonColor = false
    })
    Utility:Create("UICorner", { Parent = AccentPickerBtn, CornerRadius = UDim.new(0, 4) })
    
    AccentPickerBtn.MouseButton1Click:Connect(function()
        OpenColorPicker("Accent Color", Theme.ToggleActive, 1, function(col)
            Theme.ToggleActive = col
            AccentPickerBtn.BackgroundColor3 = col
            ApplyAccent()
        end, AccentPickerBtn)
    end)
    local TabListLayout = Utility:Create("UIListLayout", {
        Parent = TabButtonContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0)
    })

    -- Убираем TitleLabel, так как он не нужен

    local PageContainer = Utility:Create("Frame", {
        Name = "PageContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 226, 0, 10),
        Size = UDim2.new(1, -236, 1, -20)
    })

    local Window = { toggleKeyState = toggleKeyState }
    local Tabs = {}
    local tabCount = 2

    function Window:CreateCategory(name)
        Utility:Create("TextLabel", {
            Parent = TabButtonContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            Font = Theme.Font,
            Text = "   " .. name,
            TextColor3 = Theme.TextCategory,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = tabCount
        })
        tabCount = tabCount + 1
    end

    function Window:CreateTab(name, iconId)
        local TabBtn = Utility:Create("TextButton", {
            Name = "TabButton_" .. name,
            Parent = TabButtonContainer,
            BackgroundColor3 = Theme.TabFrameBg,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
            Font = Theme.LabelFont, -- Inactive is NOT bold
            Text = (iconId and "          " or "   ") .. name,
            TextColor3 = Color3.fromRGB(130, 130, 130), -- Inactive is grey
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = tabCount
        })
        Utility:Create("UICorner", { Parent = TabBtn, CornerRadius = UDim.new(0, 6) })
        tabCount = tabCount + 1

        local TabIcon
        if iconId then
            TabIcon = Utility:Create("ImageLabel", {
                Parent = TabBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxthumb://type=Asset&id=" .. iconId .. "&w=150&h=150", ImageColor3 = Color3.fromRGB(130, 130, 130)
            })
        end

        local Page = Utility:Create("Frame", {
            Name = "Page_" .. name,
            Parent = PageContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false
        })

        local LeftCol = Utility:Create("ScrollingFrame", {
            Name = "LeftColumn", Parent = Page, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextCategory, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        local LeftLayout = Utility:Create("UIListLayout", { Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })
        
        local RightCol = Utility:Create("ScrollingFrame", {
            Name = "RightColumn", Parent = Page, BackgroundTransparency = 1, Position = UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextCategory, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        local RightLayout = Utility:Create("UIListLayout", { Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })

        LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LeftCol.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y + 10) end)
        RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RightCol.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 10) end)

        local tabData = {Btn = TabBtn, Page = Page, Icon = TabIcon}
        table.insert(Tabs, tabData)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                t.Btn.BackgroundColor3 = Theme.TabFrameBg
                t.Btn.TextColor3 = Color3.fromRGB(130, 130, 130)
                t.Btn.Font = Theme.LabelFont
                if t.Icon then t.Icon.ImageColor3 = Color3.fromRGB(130, 130, 130) end
            end
            Page.Visible = true
            TabBtn.BackgroundColor3 = Theme.TabButton
            TabBtn.TextColor3 = Theme.TextMain
            TabBtn.Font = Theme.Font
            if TabIcon then TabIcon.ImageColor3 = Theme.TextMain end
        end)

        if #Tabs == 1 then
            Page.Visible = true
            TabBtn.BackgroundColor3 = Theme.TabButton
            TabBtn.TextColor3 = Theme.TextMain
            TabBtn.Font = Theme.Font
            if TabIcon then TabIcon.ImageColor3 = Theme.TextMain end
        end

        local TabObj = {}

        function TabObj:CreateSection(options)
            options = options or {}
            local secName = options.Name or "Section"
            local side = options.Side or "Left"

            local targetCol = (side:lower() == "left") and LeftCol or RightCol

            local SectionFrame = Utility:Create("Frame", {
                Name = "Child_" .. secName,
                Parent = targetCol,
                BackgroundColor3 = Theme.SectionBg,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40)
            })
            Utility:Create("UICorner", { Parent = SectionFrame, CornerRadius = UDim.new(0, 6) })

            local SectionTitle = Utility:Create("TextLabel", {
                Parent = SectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 5),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Theme.LabelFont,
                Text = secName,
                TextColor3 = Theme.TextCategory,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ContentContainer = Utility:Create("Frame", {
                Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30)
            })

            local SectionLayout = Utility:Create("UIListLayout", {
                Parent = ContentContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center
            })

            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 40)
            end)

            local Elements = {}

            function Elements:CreateToggle(opts)
                opts = opts or {}
                local togText = opts.Name or "Toggle"
                local state = opts.Default or false
                local callback = opts.Callback or function() end

                local ToggleFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 24)
                })

                local ToggleLabel = Utility:Create("TextLabel", {
                    Parent = ToggleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                    Font = Theme.LabelFont, Text = togText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local ToggleBox = Utility:Create("TextButton", {
                    Parent = ToggleFrame, BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive, BorderSizePixel = 0,
                    Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Text = "", AutoButtonColor = false
                })
                Utility:Create("UICorner", { Parent = ToggleBox, CornerRadius = UDim.new(0, 4) })
                
                table.insert(AccentUpdates, function(col)
                    if state then ToggleBox.BackgroundColor3 = col end
                end)

                local currentBind = nil
                local bindMode = "Toggle"
                local isBinding = false
                local activeBindBtnInModal = nil

                local GearBtn = Utility:Create("ImageButton", {
                    Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -26, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                    Image = "rbxthumb://type=Asset&id=11738672708&w=150&h=150", ImageColor3 = Color3.fromRGB(150, 150, 150), AutoButtonColor = false
                })

                GearBtn.MouseButton1Click:Connect(function()
                    if not opts.Colorpicker then return end
                    OpenColorPicker(togText .. " Color", opts.ColorDefault, opts.AlphaDefault, opts.ColorCallback, GearBtn)
                end)

                GearBtn.MouseButton2Click:Connect(function()
                    OpenModal(togText .. " Keybind", function(container)
                        local BindBtnInModal = Utility:Create("TextButton", { Parent = container, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28), Font = Theme.Font, Text = currentBind and "[" .. currentBind.Name .. "]" or "[Click to Bind]", TextColor3 = Theme.TextMain, TextSize = 13, ZIndex = 102 })
                        Utility:Create("UICorner", { Parent = BindBtnInModal, CornerRadius = UDim.new(0, 6) })
                        activeBindBtnInModal = BindBtnInModal

                        BindBtnInModal.MouseButton1Click:Connect(function()
                            isBinding = true
                            BindBtnInModal.Text = "[...]"
                        end)

                        local ModeBtn = Utility:Create("TextButton", { Parent = container, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28), Font = Theme.Font, Text = "Mode: " .. bindMode, TextColor3 = Theme.TextMain, TextSize = 13, ZIndex = 102 })
                        Utility:Create("UICorner", { Parent = ModeBtn, CornerRadius = UDim.new(0, 6) })
                        ModeBtn.MouseButton1Click:Connect(function()
                            bindMode = bindMode == "Toggle" and "Hold" or "Toggle"
                            ModeBtn.Text = "Mode: " .. bindMode
                        end)
                    end, GearBtn)
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if isBinding then
                        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                            currentBind = nil
                            if activeBindBtnInModal then activeBindBtnInModal.Text = "[Click to Bind]" end
                        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                            currentBind = input.KeyCode
                            if activeBindBtnInModal then activeBindBtnInModal.Text = "[" .. input.KeyCode.Name .. "]" end
                        end
                        isBinding = false
                    elseif not gp and currentBind and input.KeyCode == currentBind then
                        if bindMode == "Toggle" then
                            state = not state
                            TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
                            callback(state)
                        elseif bindMode == "Hold" then
                            state = true
                            TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleActive}):Play()
                            callback(state)
                        end
                    end
                end)

                UserInputService.InputEnded:Connect(function(input, gp)
                    if not gp and currentBind and input.KeyCode == currentBind and bindMode == "Hold" then
                        state = false
                        TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleInactive}):Play()
                        callback(state)
                    end
                end)

                ToggleBox.MouseButton1Click:Connect(function()
                    state = not state
                    TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
                    callback(state)
                end)
                task.spawn(function() callback(state) end)
            end

            function Elements:CreateSlider(opts)
                opts = opts or {}
                local slName = opts.Name or "Slider"
                local min = opts.Min or 0
                local max = opts.Max or 100
                local default = opts.Default or min
                local callback = opts.Callback or function() end

                local SliderFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 36)
                })

                local SliderLabel = Utility:Create("TextLabel", {
                    Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 16), Font = Theme.LabelFont, Text = slName, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local ValueLabel = Utility:Create("TextLabel", {
                    Parent = SliderFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 40, 0, 16), Font = Theme.Font, Text = tostring(default), TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right
                })

                local SliderBack = Utility:Create("Frame", {
                    Parent = SliderFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 6)
                })
                Utility:Create("UICorner", { Parent = SliderBack, CornerRadius = UDim.new(0, 3) })

                local fillPct = math.clamp((default - min) / (max - min), 0, 1)
                local SliderFill = Utility:Create("Frame", {
                    Parent = SliderBack, BackgroundColor3 = Theme.ToggleActive, BorderSizePixel = 0, Size = UDim2.new(fillPct, 0, 1, 0)
                })
                Utility:Create("UICorner", { Parent = SliderFill, CornerRadius = UDim.new(0, 3) })
                
                table.insert(AccentUpdates, function(col)
                    SliderFill.BackgroundColor3 = col
                end)

                local SliderBtn = Utility:Create("TextButton", {
                    Parent = SliderBack, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false
                })

                local dragging = false
                local function update(input)
                    local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                    local value = math.floor(min + ((max - min) * pos))
                    ValueLabel.Text = tostring(value)
                    callback(value)
                end

                SliderBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        update(input)
                        
                        local moveConn, endConn
                        moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                            if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                                update(moveInput)
                            end
                        end)
                        
                        endConn = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                                if moveConn then moveConn:Disconnect() end
                                if endConn then endConn:Disconnect() end
                            end
                        end)
                    end
                end)
                
                task.spawn(function() callback(default) end)
            end

            function Elements:CreateButton(opts)
                opts = opts or {}
                local btnText = opts.Name or "Button"
                local callback = opts.Callback or function() end

                local ButtonFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 24)
                })
                Utility:Create("UICorner", { Parent = ButtonFrame, CornerRadius = UDim.new(0, 6) })

                local Button = Utility:Create("TextButton", {
                    Parent = ButtonFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Theme.Font, Text = btnText, TextColor3 = Theme.TextMain, TextSize = 13
                })

                Button.MouseButton1Click:Connect(function()
                    callback()
                end)
            end

            function Elements:CreateTextbox(opts)
                opts = opts or {}
                local tbText = opts.Name or "Textbox"
                local placeholder = opts.Placeholder or ""
                local callback = opts.Callback or function() end

                local TextboxFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                })

                Utility:Create("TextLabel", {
                    Parent = TextboxFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.LabelFont, Text = tbText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local BoxBg = Utility:Create("Frame", {
                    Parent = TextboxFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24)
                })
                Utility:Create("UICorner", { Parent = BoxBg, CornerRadius = UDim.new(0, 6) })

                local TextBox = Utility:Create("TextBox", {
                    Parent = BoxBg, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0), Font = Theme.Font, Text = "", PlaceholderText = placeholder, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
                })

                TextBox.FocusLost:Connect(function()
                    callback(TextBox.Text)
                end)
            end

            function Elements:CreateKeybind(opts)
                opts = opts or {}
                local kbText      = opts.Name or "Keybind"
                local default     = opts.Default or "None"
                local callback    = opts.Callback or function() end
                local isListening = false
                local currentKey  = default

                local KbFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                })

                Utility:Create("TextLabel", {
                    Parent = KbFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
                    Font = Theme.LabelFont, Text = kbText, TextColor3 = Theme.TextMain,
                    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local BtnBg = Utility:Create("Frame", {
                    Parent = KbFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24)
                })
                Utility:Create("UICorner", { Parent = BtnBg, CornerRadius = UDim.new(0, 6) })

                local KbBtn = Utility:Create("TextButton", {
                    Parent = BtnBg, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                    Font = Theme.Font, Text = "[" .. currentKey .. "]",
                    TextColor3 = Theme.TextMain, TextSize = 13
                })

                KbBtn.MouseButton1Click:Connect(function()
                    if isListening then return end
                    isListening = true
                    KbBtn.Text = "[...]"
                end)

                game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
                    if not isListening then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    isListening = false
                    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                        currentKey = "None"
                    else
                        currentKey = input.KeyCode.Name
                    end
                    KbBtn.Text = "[" .. currentKey .. "]"
                    callback(currentKey)
                end)
            end

            function Elements:CreateDropdown(opts)
                opts = opts or {}
                local dropText = opts.Name or "Dropdown"
                local list = opts.Options or {}
                local callback = opts.Callback or function() end
                
                local isOpen = false
                local selected = opts.Default or (list[1] or "")

                local DropdownFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                })

                Utility:Create("TextLabel", {
                    Parent = DropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.LabelFont, Text = dropText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local MainBox = Utility:Create("TextButton", {
                    Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24), Text = ""
                })
                Utility:Create("UICorner", { Parent = MainBox, CornerRadius = UDim.new(0, 6) })

                local SelectedLabel = Utility:Create("TextLabel", {
                    Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -25, 1, 0), Font = Theme.Font, Text = selected, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local Arrow = Utility:Create("TextLabel", {
                    Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Theme.Font, Text = "v", TextColor3 = Theme.TextMain, TextSize = 13
                })

                local DropContainer = Utility:Create("Frame", {
                    Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 0), Visible = false, ClipsDescendants = true
                })
                Utility:Create("UICorner", { Parent = DropContainer, CornerRadius = UDim.new(0, 6) })

                local DropLayout = Utility:Create("UIListLayout", { Parent = DropContainer, SortOrder = Enum.SortOrder.LayoutOrder })

                local function createList()
                    for _, v in pairs(DropContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    local h = 0
                    for _, option in pairs(list) do
                        local OptBtn = Utility:Create("TextButton", {
                            Parent = DropContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), Font = Enum.Font.Gotham, Text = "  " .. option, TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
                        })
                        h = h + 25

                        OptBtn.MouseButton1Click:Connect(function()
                            selected = option
                            SelectedLabel.Text = selected
                            isOpen = false
                            DropContainer.Visible = false
                            Arrow.Text = "v"
                            DropdownFrame.Size = UDim2.new(1, -24, 0, 50)
                            
                            for _, btn in pairs(DropContainer:GetChildren()) do
                                if btn:IsA("TextButton") then
                                    local optName = btn.Text:sub(3)
                                    btn.TextColor3 = (optName == selected) and Theme.ToggleActive or Theme.TextMain
                                    btn.Font = (optName == selected) and Theme.Font or Enum.Font.Gotham
                                end
                            end
                            
                            callback(selected)
                        end)
                    end
                    DropContainer.Size = UDim2.new(1, 0, 0, h)
                    
                    for _, btn in pairs(DropContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            local optName = btn.Text:sub(3)
                            btn.TextColor3 = (optName == selected) and Theme.ToggleActive or Theme.TextMain
                            btn.Font = (optName == selected) and Theme.Font or Enum.Font.Gotham
                        end
                    end
                end

                createList()

                table.insert(AccentUpdates, function(col)
                    for _, btn in pairs(DropContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            local optName = btn.Text:sub(3)
                            if optName == selected then
                                btn.TextColor3 = col
                            end
                        end
                    end
                end)

                MainBox.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    DropContainer.Visible = isOpen
                    Arrow.Text = isOpen and "^" or "v"
                    if isOpen then
                        DropdownFrame.Size = UDim2.new(1, -24, 0, 55 + DropContainer.Size.Y.Offset)
                    else
                        DropdownFrame.Size = UDim2.new(1, -24, 0, 50)
                    end
                end)
                
                task.spawn(function() callback(selected) end)
            end
            function Elements:CreateMultiDropdown(opts)
                opts = opts or {}
                local dropText = opts.Name or "Multi Dropdown"
                local list = opts.Options or {}
                local callback = opts.Callback or function() end
                
                local isOpen = false
                local selected = {}
                if opts.Default then
                    for _, v in ipairs(opts.Default) do
                        table.insert(selected, v)
                    end
                end

                local DropdownFrame = Utility:Create("Frame", {
                    Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 40)
                })

                Utility:Create("TextLabel", {
                    Parent = DropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.LabelFont, Text = dropText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
                })

                local MainBox = Utility:Create("TextButton", {
                    Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24), Text = ""
                })
                Utility:Create("UICorner", { Parent = MainBox, CornerRadius = UDim.new(0, 6) })

                local function getSelectedText()
                    if #selected == 0 then return "None" end
                    return table.concat(selected, ", ")
                end

                local SelectedLabel = Utility:Create("TextLabel", {
                    Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -25, 1, 0), Font = Theme.Font, Text = getSelectedText(), TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
                })

                local Arrow = Utility:Create("TextLabel", {
                    Parent = MainBox, BackgroundTransparency = 1, Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Theme.Font, Text = "v", TextColor3 = Theme.TextMain, TextSize = 13
                })

                local DropContainer = Utility:Create("Frame", {
                    Parent = DropdownFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 0), Visible = false, ClipsDescendants = true
                })
                Utility:Create("UICorner", { Parent = DropContainer, CornerRadius = UDim.new(0, 6) })

                local DropLayout = Utility:Create("UIListLayout", { Parent = DropContainer, SortOrder = Enum.SortOrder.LayoutOrder })

                local function createList()
                    for _, v in pairs(DropContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    local h = 0
                    for _, option in ipairs(list) do
                        local OptBtn = Utility:Create("TextButton", {
                            Parent = DropContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), Font = Enum.Font.Gotham, Text = "  " .. option, TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
                        })
                        h = h + 25

                        OptBtn.MouseButton1Click:Connect(function()
                            local isSel = false
                            for _, v in ipairs(selected) do if v == option then isSel = true break end end

                            if isSel then
                                for i, v in ipairs(selected) do
                                    if v == option then table.remove(selected, i) break end
                                end
                            else
                                table.insert(selected, option)
                            end
                            SelectedLabel.Text = getSelectedText()
                            callback(selected)
                            
                            -- Update all colors
                            for _, btn in pairs(DropContainer:GetChildren()) do
                                if btn:IsA("TextButton") then
                                    local optName = btn.Text:sub(3) -- remove "  " prefix
                                    local sel = false
                                    for _, v in ipairs(selected) do if v == optName then sel = true break end end
                                    btn.TextColor3 = sel and Theme.ToggleActive or Theme.TextMain
                                    btn.Font = sel and Theme.Font or Enum.Font.Gotham
                                end
                            end
                        end)
                    end
                    DropContainer.Size = UDim2.new(1, 0, 0, h)
                    
                    -- Initial color setup
                    for _, btn in pairs(DropContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            local optName = btn.Text:sub(3)
                            local sel = false
                            for _, v in ipairs(selected) do if v == optName then sel = true break end end
                            btn.TextColor3 = sel and Theme.ToggleActive or Theme.TextMain
                            btn.Font = sel and Theme.Font or Enum.Font.Gotham
                        end
                    end
                end

                createList()

                table.insert(AccentUpdates, function(col)
                    for _, btn in pairs(DropContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            local optName = btn.Text:sub(3)
                            local sel = false
                            for _, v in ipairs(selected) do if v == optName then sel = true break end end
                            if sel then
                                btn.TextColor3 = col
                            end
                        end
                    end
                end)

                MainBox.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    DropContainer.Visible = isOpen
                    Arrow.Text = isOpen and "^" or "v"
                    if isOpen then
                        DropdownFrame.Size = UDim2.new(1, -24, 0, 55 + DropContainer.Size.Y.Offset)
                    else
                        DropdownFrame.Size = UDim2.new(1, -24, 0, 50)
                    end
                end)
                
                task.spawn(function() callback(selected) end)
            end

            return Elements
        end

        return TabObj
    end

    return Window
end

-- =====================================================
-- KAMIWARE V3 - LINORIA MIGRATED VERSION
-- Rayfield -> onerarter08-sudo/ndere Library
-- =====================================================

local repo = 'https://raw.githubusercontent.com/onerarter08-sudo/ndere/main/'
local nocache = "?v=" .. tostring(tick())


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

_G.vfxAttachments = _G.vfxAttachments or {}

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = Workspace.CurrentCamera
end)

local notificationsEnabled = true

local function notify(text, duration)
    if not notificationsEnabled then
        return
    end

    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Kamiware",
            Text = tostring(text),
            Duration = duration
        })
    end)
end

local function stripAssetPrefix(id)
    return tostring(id or ""):gsub("rbxassetid://", "")
end

local function asAssetId(id)
    id = tostring(id or "")
    if id == "" then
        return ""
    end
    if id:find("rbxassetid://", 1, true) then
        return id
    end
    return "rbxassetid://" .. id
end

-- =====================================================
-- WINE CONFIG / SETTINGS
-- =====================================================

local WINE_CONFIG = {
    TrueWine = Color3.fromRGB(80, 0, 25),
    BlackWine = Color3.fromRGB(30, 0, 10),
    Material = Enum.Material.SmoothPlastic
}

local Settings = {
    FOV = 93,
    FOVEnabled = false,
    EdgeEnabled = false,
    EdgePower = 150,
    TrimpEnabled = false,
    SpinEnabled = false,
    TurnEnabled = false,
    TurnSpeed = 0.05,
    FFlagEnabled = false,
    KorbloxEnabled = false,
    HeadlessEnabled = false,
    PCFlyEnabled = false,
    MobileFlyEnabled = false,
    InvisWallEnabled = false,
    CustomSkyID = "rbxassetid://133527242242149",
    VFXEnabled = false,
    AutoApplyCosmetic = false,
    AutoApplyGlobalColor = false,
    AutoApplySkyColor = false,
    AutoApplyPerfectFog = false,
    AutoApplyDraconicEmoteSwapper = false,
    MobileEdgeEnabled = false,
    MapScale = 1.0,
    SpawnHeight = 1500,
    mommyAsmrEnabled = false,
    keyboardSoundEnabled = false,
    NotificationsEnabled = true
}

local deepWineSequence = nil
local function rebuildDeepWineSequence()
    deepWineSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, WINE_CONFIG.BlackWine),
        ColorSequenceKeypoint.new(0.2, WINE_CONFIG.TrueWine),
        ColorSequenceKeypoint.new(1, WINE_CONFIG.BlackWine)
    })
end
rebuildDeepWineSequence()

-- =====================================================
-- WINDOW / TABS
-- =====================================================


-- =====================================================
-- EMOTE SWAPPER BACKEND
-- =====================================================

-- Format: ["OwnedEmote"] = "WantedEmote"
local EMOTE_CONFIG = {
    ["BoldMarch"] = "RockinStride",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}

local EmoteSwapper = {
    CurrentEmotes = {},
    SelectedEmotes = {},
    InputFields = {}
}

local originalEmoteContents = {}

for i = 1, 12 do
    EmoteSwapper.CurrentEmotes[i] = ""
    EmoteSwapper.SelectedEmotes[i] = ""
end

local function findItemByName(name)
    return ReplicatedStorage:FindFirstChild(name, true)
end

local function cloneChildren(parent)
    local children = {}
    for _, child in ipairs(parent:GetChildren()) do
        local clone = child:Clone()
        if clone then
            table.insert(children, clone)
        end
    end
    return children
end

local function clearChildren(parent)
    for _, child in ipairs(parent:GetChildren()) do
        child:Destroy()
    end
end

local function restoreChildren(parent, children)
    clearChildren(parent)
    for _, child in ipairs(children) do
        child:Clone().Parent = parent
    end
end

local function replaceEmoteContents(targetName, sourceName)
    local target = findItemByName(targetName)
    local source = findItemByName(sourceName)

    if not target then
        warn("[Emote Swap Failed] Target item '" .. targetName .. "' was not found in ReplicatedStorage.")
        return false
    end

    if not source then
        warn("[Emote Swap Failed] Source item '" .. sourceName .. "' was not found in ReplicatedStorage.")
        return false
    end

    if originalEmoteContents[target] == nil then
        originalEmoteContents[target] = cloneChildren(target)
    end

    clearChildren(target)
    local sourceChildren = source:GetChildren()

    if #sourceChildren > 0 then
        for _, child in ipairs(sourceChildren) do
            local clone = child:Clone()
            clone.Parent = target
        end
        print("[Emote Swap Success] Loaded '" .. sourceName .. "' contents into '" .. targetName .. "'.")
    else
        local clone = source:Clone()
        clone.Parent = target
        print("[Emote Swap Success] Cloned standalone '" .. sourceName .. "' directly into '" .. targetName .. "'.")
    end

    return true
end

local function revertEmoteContents(targetName)
    local target = findItemByName(targetName)
    if not target then
        warn("[Emote Revert Failed] Target item '" .. targetName .. "' was not found in ReplicatedStorage.")
        return false
    end

    local originalContents = originalEmoteContents[target]
    if originalContents == nil then
        return false
    end

    restoreChildren(target, originalContents)
    originalEmoteContents[target] = nil
    print("[Emote Revert Success] Restored original contents of '" .. targetName .. "'.")
    return true
end

-- =====================================================
-- TURNBIND
-- =====================================================

local TurnbindSettings = {
    Enabled = false,
    TurnSpeed = 0.3,
    LeftKey = Enum.KeyCode.A,
    RightKey = Enum.KeyCode.D
}

local turnbindConns = {}
local TurnbindActivateKey = "R"

local function stopTurnbind()
    if turnbindConns.Began then
        turnbindConns.Began:Disconnect()
    end
    if turnbindConns.Ended then
        turnbindConns.Ended:Disconnect()
    end
    turnbindConns = {}
end

local function startTurnbind()
    stopTurnbind()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    turnbindConns.Began = UserInputService.InputBegan:Connect(function(input, gpe)
        pcall(function()
            if gpe or not TurnbindSettings.Enabled then
                return
            end
            if input.KeyCode == TurnbindSettings.LeftKey then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Left, false, game)
            elseif input.KeyCode == TurnbindSettings.RightKey then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Right, false, game)
            end
        end)
    end)
    turnbindConns.Ended = UserInputService.InputEnded:Connect(function(input)
        pcall(function()
            if input.KeyCode == TurnbindSettings.LeftKey then
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Left, false, game)
            elseif input.KeyCode == TurnbindSettings.RightKey then
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Right, false, game)
            end
        end)
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode.Name ~= TurnbindActivateKey then return end
    TurnbindSettings.Enabled = not TurnbindSettings.Enabled
    if TurnbindSettings.Enabled then
        startTurnbind(); notify("Turnbind enabled.", 2)
    else
        stopTurnbind(); notify("Turnbind disabled.", 2)
    end
end)

-- =====================================================
-- GLOBAL COLOR / WORLD VISUALS
-- =====================================================

local globalColorEnabled = false
local globalColor = Color3.fromRGB(255, 255, 255)
local originalColors = {}

local function isCharacterPart(obj)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and (obj:IsDescendantOf(plr.Character) or obj.Parent == plr.Character) then
            return true
        end
    end
    return false
end

local function storeOriginalColors()
    originalColors = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then
            originalColors[obj] = obj.Color
        end
    end
end

local function applyGlobalColor()
    if not globalColorEnabled then
        return
    end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then
            pcall(function()
                obj.Color = globalColor
            end)
        end
    end
end

local function restoreOriginalColors()
    for part, color in pairs(originalColors) do
        if part and part.Parent then
            pcall(function()
                part.Color = color
            end)
        end
    end
    originalColors = {}
end

local skyColorEnabled = false
local skyColor = Color3.fromRGB(135, 206, 235)
local originalAmbient = nil
local originalOutdoorAmbient = nil

local function applySkyColor()
    if not originalAmbient then
        originalAmbient = Lighting.Ambient
        originalOutdoorAmbient = Lighting.OutdoorAmbient
    end

    if skyColorEnabled then
        Lighting.Ambient = skyColor
        Lighting.OutdoorAmbient = skyColor
        local atmosphere = Lighting:FindFirstChild("Atmosphere")
        if atmosphere then
            atmosphere.Color = skyColor
        end
    else
        Lighting.Ambient = originalAmbient or Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = originalOutdoorAmbient or Color3.fromRGB(128, 128, 128)
    end
end

local perfectFogEnabled = false
local perfectFogColor = Color3.fromRGB(180, 190, 200)
local originalFogSettings = nil

local function saveOriginalFogSettings()
    if originalFogSettings then
        return
    end

    originalFogSettings = {
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        FogColor = Lighting.FogColor,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        GlobalShadows = Lighting.GlobalShadows,
        ShadowSoftness = Lighting.ShadowSoftness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end

local function removePerfectFogObjects()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj.Name == "PerfectFogSky" then
            obj:Destroy()
        elseif obj:IsA("Atmosphere") and (obj.Name == "PerfectFogAtmosphere" or obj.Name == "PerfectFogAtm") then
            obj:Destroy()
        end
    end
end

local function applyPerfectFog()
    saveOriginalFogSettings()

    if not perfectFogEnabled then
        Lighting.FogStart = originalFogSettings.FogStart
        Lighting.FogEnd = originalFogSettings.FogEnd
        Lighting.FogColor = originalFogSettings.FogColor
        Lighting.Ambient = originalFogSettings.Ambient
        Lighting.OutdoorAmbient = originalFogSettings.OutdoorAmbient
        Lighting.ColorShift_Top = originalFogSettings.ColorShift_Top
        Lighting.ColorShift_Bottom = originalFogSettings.ColorShift_Bottom
        Lighting.GlobalShadows = originalFogSettings.GlobalShadows
        Lighting.ShadowSoftness = originalFogSettings.ShadowSoftness
        Lighting.EnvironmentDiffuseScale = originalFogSettings.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = originalFogSettings.EnvironmentSpecularScale
        removePerfectFogObjects()
        return
    end

    Lighting.FogStart = 10
    Lighting.FogEnd = math.max(300 / (0.9 * 0.8 + 0.2), 50)
    Lighting.FogColor = Color3.fromRGB(210, 220, 240)
    Lighting.Ambient = Color3.fromRGB(111, 111, 111)
    Lighting.OutdoorAmbient = Color3.fromRGB(111, 111, 111)
    Lighting.ColorShift_Top = Color3.fromRGB(111, 111, 111)
    Lighting.ColorShift_Bottom = Color3.fromRGB(111, 111, 111)
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.3
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1

    removePerfectFogObjects()

    local sky = Instance.new("Sky", Lighting)
    sky.Name = "PerfectFogSky"
    sky.SkyboxBk = "rbxassetid://252760981"
    sky.SkyboxDn = "rbxassetid://252763921"
    sky.SkyboxFt = "rbxassetid://252761439"
    sky.SkyboxLf = "rbxassetid://252761439"
    sky.SkyboxRt = "rbxassetid://252761439"
    sky.SkyboxUp = "rbxassetid://252762708"

    local atmosphere = Instance.new("Atmosphere", Lighting)
    atmosphere.Name = "PerfectFogAtmosphere"
    atmosphere.Color = perfectFogColor
    atmosphere.Decay = Color3.fromRGB(90, 100, 110)
    atmosphere.Density = 0.6
    atmosphere.Offset = 0.25
    atmosphere.Haze = 0.6
end

local sunsetShaderEnabled = false
local sunsetShaderOriginalLighting = nil
local SUNSET_SHADER_PREFIX = "MWSunsetShader"

local function saveSunsetShaderLighting()
    if sunsetShaderOriginalLighting then
        return
    end

    sunsetShaderOriginalLighting = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ShadowSoftness = Lighting.ShadowSoftness,
        ExposureCompensation = Lighting.ExposureCompensation,
        ClockTime = Lighting.ClockTime,
        GeographicLatitude = Lighting.GeographicLatitude
    }
end

local function removeSunsetShaderObjects()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj.Name:sub(1, #SUNSET_SHADER_PREFIX) == SUNSET_SHADER_PREFIX then
            obj:Destroy()
        end
    end

    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local overlay = playerGui and playerGui:FindFirstChild("MWSunsetShaderOverlay")
    if overlay then
        overlay:Destroy()
    end
end

local function restoreSunsetShaderLighting()
    if not sunsetShaderOriginalLighting then
        return
    end

    for prop, value in pairs(sunsetShaderOriginalLighting) do
        pcall(function()
            Lighting[prop] = value
        end)
    end

    sunsetShaderOriginalLighting = nil
end

local function applySunsetShader()
    if not sunsetShaderEnabled then
        removeSunsetShaderObjects()
        restoreSunsetShaderLighting()
        return
    end

    saveSunsetShaderLighting()
    removeSunsetShaderObjects()

    local bloomEffect = Instance.new("BloomEffect")
    bloomEffect.Name = "MWSunsetShaderBloom"
    bloomEffect.Intensity = 0.15
    bloomEffect.Size = 5
    bloomEffect.Threshold = 0.85
    bloomEffect.Parent = Lighting

    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "MWSunsetShaderBlur"
    blurEffect.Size = 5
    blurEffect.Parent = Lighting

    local colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
    colorCorrectionEffect.Name = "MWSunsetShaderColorCorrection"
    colorCorrectionEffect.Brightness = 0.1
    colorCorrectionEffect.Contrast = 0.2
    colorCorrectionEffect.Saturation = -0.3
    colorCorrectionEffect.TintColor = Color3.fromRGB(255, 235, 203)
    colorCorrectionEffect.Parent = Lighting

    local sunRaysEffect = Instance.new("SunRaysEffect")
    sunRaysEffect.Name = "MWSunsetShaderSunRays"
    sunRaysEffect.Intensity = 0.1
    sunRaysEffect.Spread = 0.727
    sunRaysEffect.Parent = Lighting

    local sky = Instance.new("Sky")
    sky.Name = "MWSunsetShaderSky"
    sky.SkyboxBk = "http://www.roblox.com/asset/?id=151165214"
    sky.SkyboxDn = "http://www.roblox.com/asset/?id=151165197"
    sky.SkyboxFt = "http://www.roblox.com/asset/?id=151165224"
    sky.SkyboxLf = "http://www.roblox.com/asset/?id=151165191"
    sky.SkyboxRt = "http://www.roblox.com/asset/?id=151165206"
    sky.SkyboxUp = "http://www.roblox.com/asset/?id=151165227"
    sky.SunAngularSize = 10
    sky.Parent = Lighting

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "MWSunsetShaderAtmosphere"
    atmosphere.Density = 0.364
    atmosphere.Offset = 0.556
    atmosphere.Color = Color3.fromRGB(199, 175, 166)
    atmosphere.Decay = Color3.fromRGB(44, 39, 33)
    atmosphere.Glare = 0.2
    atmosphere.Haze = 1.3
    atmosphere.Parent = Lighting

    Lighting.Ambient = Color3.fromRGB(2, 2, 2)
    Lighting.Brightness = 2.0
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.EnvironmentDiffuseScale = 0.2
    Lighting.EnvironmentSpecularScale = 0.2
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.ShadowSoftness = 3
    Lighting.ExposureCompensation = 0.4
    Lighting.ClockTime = 17
    Lighting.GeographicLatitude = 45

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MWSunsetShaderOverlay"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "SunsetOverlay"
    imageLabel.AnchorPoint = Vector2.new(0.5, 1)
    imageLabel.Position = UDim2.new(0.5, 0, 1, 0)
    imageLabel.Size = UDim2.new(1, 0, 1.05, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = "rbxassetid://4576475446"
    imageLabel.ImageTransparency = 0.3
    imageLabel.ZIndex = 10
    imageLabel.Parent = screenGui
end

-- =====================================================
-- VIRTUAL STRAFE
-- =====================================================

local VirtualStrafeEnabled = false
local VirtualStrafeIntensity = 500
local currentSpeed = 0
local lastCameraYaw = 0
local moveDir = Vector3.new(0, 0, 0)

local MAX_SPEED_CAP = 500000
local ACCEL_RATE = 75
local STRAFE_ADD_AMOUNT = 5
local TURN_DECEL_FACTOR = 0.85
local LERP_SPEED = 0.15
local BRAKE_FACTOR = 0.85
local IDLE_PERCENT_DECAY = 0.992
local IDLE_LINEAR_DECAY = 35

local function updateVirtualStrafe(dt)
    if not VirtualStrafeEnabled then
        return
    end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        VirtualStrafeEnabled = false
        currentSpeed = 0
        return
    end

    local root = char.HumanoidRootPart
    local isW = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local isA = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local isD = UserInputService:IsKeyDown(Enum.KeyCode.D)
    local isS = UserInputService:IsKeyDown(Enum.KeyCode.S)

    local camForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if camForward.Magnitude <= 0 then
        return
    end
    camForward = camForward.Unit

    local directionMatch = moveDir:Dot(camForward)
    if directionMatch < 0.2 and currentSpeed > 100 then
        currentSpeed = currentSpeed * TURN_DECEL_FACTOR
    end
    moveDir = moveDir:Lerp(camForward, LERP_SPEED)
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
    else
        moveDir = camForward
    end

    local _, camYaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    local yawDelta = camYaw - lastCameraYaw
    if yawDelta > math.pi then
        yawDelta = yawDelta - (math.pi * 2)
    end
    if yawDelta < -math.pi then
        yawDelta = yawDelta + (math.pi * 2)
    end
    lastCameraYaw = camYaw

    local canStrafe = (isA and yawDelta > 0.0001) or (isD and yawDelta < -0.0001)
    if isS then
        currentSpeed = currentSpeed * BRAKE_FACTOR
    elseif isW or isA or isD then
        if currentSpeed < VirtualStrafeIntensity then
            currentSpeed = currentSpeed + (ACCEL_RATE * 3 * dt)
        end

        if canStrafe and currentSpeed > 50 then
            currentSpeed = math.min(currentSpeed + STRAFE_ADD_AMOUNT, MAX_SPEED_CAP)
        else
            currentSpeed = currentSpeed * 0.999
        end
    else
        currentSpeed = (currentSpeed * IDLE_PERCENT_DECAY) - (IDLE_LINEAR_DECAY * dt)
    end

    if currentSpeed < 1 then
        currentSpeed = 0
    end

    if currentSpeed > 0 then
        local targetVelocity = moveDir * (currentSpeed / 45)
        root.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, root.AssemblyLinearVelocity.Y, targetVelocity.Z)
    end
end

RunService.Heartbeat:Connect(updateVirtualStrafe)

local function resetVirtualStrafe()
    VirtualStrafeEnabled = false
    currentSpeed = 0
    moveDir = Vector3.new(0, 0, 0)
end

-- =====================================================
-- AUTO TRIMP - IMPROVED VERSION
-- =====================================================

-- (see debug print below)
local AutoTrimpEnabled = false
local TrimpPower = 100  -- (see debug print below)
local MinSpeed = 30     -- (see debug print below)

local lastTrimp = 0
local cooldown = 0.2  -- (see debug print below)

-- (see debug print below)
local function DoTrimp()
    if not AutoTrimpEnabled then return end

    local now = tick()
    if now - lastTrimp < cooldown then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- (see debug print below)
    local vel = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    if speed < MinSpeed then 
        print("[Trimp Debug] ?? ?????:", math.floor(speed), "<", MinSpeed)
        return 
    end
    
    -- (see debug print below)
    if vel.Y > 0 then 
        print("[Trimp Debug] ?? ?? ????:", vel.Y)
        return 
    end

    -- (see debug print below)
    local rayOrigin = hrp.Position
    local rayDirection = Vector3.new(0, -3, 0)
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection)
    
    if not raycastResult then 
        print("[Trimp Debug] ?? ????")
        return 
    end

    -- (see debug print below)
    lastTrimp = now
    local newVel = Vector3.new(vel.X * 0.8, TrimpPower, vel.Z * 0.8)  -- (see debug print below)
    hrp.AssemblyLinearVelocity = newVel

    print("[Trimp] ??! ??:", math.floor(speed), "???:", raycastResult.Instance.Name)
end

-- Main loop
RunService.Heartbeat:Connect(function()
    DoTrimp()
end)

-- =====================================================
-- EASY BOUNCE
-- =====================================================

local EasyBounceEnabled = false
local EASY_BOUNCE_MAX_HISTORY = 1000
local EASY_BOUNCE_STEP = 1 / 55
local EASY_BOUNCE_SPEED_MULT = 1.6
local easyBounceLastTime = tick()
local easyBounceHistory = {}
local easyBounceCharacter = nil
local easyBounceHrp = nil
local easyBounceHumanoid = nil

local function refreshEasyBounceCharacter(char)
    easyBounceCharacter = char or LocalPlayer.Character
    easyBounceHrp = nil
    easyBounceHumanoid = nil

    if not easyBounceCharacter then
        return
    end

    easyBounceHrp = easyBounceCharacter:FindFirstChild("HumanoidRootPart")
    easyBounceHumanoid = easyBounceCharacter:FindFirstChildOfClass("Humanoid")
    easyBounceLastTime = tick()
end

local function simulateEasyBounceStep(dt)
    if not EasyBounceEnabled or not easyBounceHrp or not easyBounceHumanoid then
        return
    end
    if easyBounceHumanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        return
    end

    local vel = easyBounceHrp.AssemblyLinearVelocity * EASY_BOUNCE_SPEED_MULT
    easyBounceHrp.CFrame = easyBounceHrp.CFrame + vel * dt
end

local function smoothEasyBounce(a, b, t)
    return a + (b - a) * t
end

RunService.Stepped:Connect(function()
    if not EasyBounceEnabled then
        return
    end

    if not easyBounceHrp or not easyBounceHrp.Parent or not easyBounceHumanoid or not easyBounceHumanoid.Parent then
        refreshEasyBounceCharacter(LocalPlayer.Character)
        return
    end

    local now = tick()
    local dt = now - easyBounceLastTime
    easyBounceLastTime = now

    table.insert(easyBounceHistory, dt)
    if #easyBounceHistory > EASY_BOUNCE_MAX_HISTORY then
        table.remove(easyBounceHistory, 1)
    end

    if easyBounceHumanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        return
    end

    while dt > EASY_BOUNCE_STEP do
        simulateEasyBounceStep(EASY_BOUNCE_STEP)
        dt = dt - EASY_BOUNCE_STEP
    end

    if dt > 0 then
        simulateEasyBounceStep(dt)
    end

    local targetPos = easyBounceHrp.Position
    local finalPos = smoothEasyBounce(easyBounceHrp.Position, targetPos, 0.5)
    easyBounceHrp.CFrame = CFrame.new(finalPos, easyBounceHrp.CFrame.LookVector + finalPos)
end)

local AirStrafeSpeedEnabled = false
local AirStrafeSpeedValue = 1500
local AirStrafeAcceleration = 182
local AirStrafeJumpHeight = 3

-- BaseStats module reference and original value for restoration
local airStrafeBaseStats = nil
local airStrafeOriginalAccel = nil

local function getAirStrafeBaseStats()
    if airStrafeBaseStats then return airStrafeBaseStats end
    pcall(function()
        local path = ReplicatedStorage.Objects.Game.Character.Client.Movement.MoveStats.BaseStats
        airStrafeBaseStats = require(path)
    end)
    return airStrafeBaseStats
end

local function applyAirStrafeModifications()
    pcall(function()
        local stats = getAirStrafeBaseStats()
        if stats then
            if airStrafeOriginalAccel == nil then
                airStrafeOriginalAccel = stats["AirStrafeAcceleration"]
            end
            stats["AirStrafeAcceleration"] = AirStrafeAcceleration
            print("AirStrafeAcceleration successfully changed to: " .. tostring(stats["AirStrafeAcceleration"]))
        end
    end)
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = AirStrafeSpeedValue / 50
                humanoid.JumpPower = AirStrafeJumpHeight * 30
            end
        end
    end)
end

local function restoreAirStrafeModifications()
    pcall(function()
        local stats = getAirStrafeBaseStats()
        if stats and airStrafeOriginalAccel ~= nil then
            stats["AirStrafeAcceleration"] = airStrafeOriginalAccel
            airStrafeOriginalAccel = nil
        end
    end)
    notify("Air Strafe Speed disabled", 3)
end

local function updateAirStrafeValues()
    if not AirStrafeSpeedEnabled then return end
    pcall(function()
        local stats = getAirStrafeBaseStats()
        if stats then
            stats["AirStrafeAcceleration"] = AirStrafeAcceleration
        end
    end)
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = AirStrafeSpeedValue / 50
                humanoid.JumpPower = AirStrafeJumpHeight * 30
            end
        end
    end)
end

local YLockSurfEnabled = false
local YLockSurfMode = "Toggle"
local YLockSurfKey = Enum.KeyCode.X
local isYLocked = false
local lockedY = nil
local originalHipHeight = nil

local function LockYPosition()
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    lockedY = hrp.Position.Y
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        originalHipHeight = hum.HipHeight
    end
    isYLocked = true
end

local function UnlockYPosition()
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and originalHipHeight then
        hum.HipHeight = originalHipHeight
    end

    isYLocked = false
    lockedY = nil
    originalHipHeight = nil
end

local function MaintainYLock()
    if not isYLocked then
        return
    end

    local char = LocalPlayer.Character
    if not char then
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not lockedY then
        return
    end

    local currentPos = hrp.Position
    local currentVel = hrp.AssemblyLinearVelocity
    if math.abs(currentPos.Y - lockedY) > 0.1 then
        hrp.Position = Vector3.new(currentPos.X, lockedY, currentPos.Z)
        hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
    else
        hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
    end
end

-- =====================================================
-- FLY GLITCH
-- =====================================================

local velocidadeSubidaAlvo = 45
local aceleracaoSubida = 90
local velocidadeDescidaMax = 50
local aceleracaoDescida = 35
local forcaBounce = 25
local distanciaChaoBounce = 5.0
local distanciaTeto = 0.1
local intensidadeTremor = 0.08
local jitterVelocidade = 1
local subindoQ = false
local descendoCTRL = false
local emEstadoDeBounce = false
local executando = true
local vFinal = 0
local vAtualSubida = 0
local vAtualDescida = 0

local function detectaObjeto(direcao, distancia)
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(hrp.Position, direcao * (distancia + 2.5), raycastParams)
end

local function updateFlyVelocity()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local bv = hrp:FindFirstChild("FlyVelocity")
    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "FlyVelocity"
            bv.MaxForce = Vector3.new(0, 0, 0)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
        end
        executando = true
    else
        if bv then
            bv:Destroy()
        end
        executando = false
        subindoQ = false
        descendoCTRL = false
        vAtualSubida = 0
        vAtualDescida = 0
        vFinal = 0
    end
end

local crouchConnections = {}
local function clearCrouchConnections()
    for _, conn in ipairs(crouchConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    crouchConnections = {}
end

local function startCrouchDetect()
    clearCrouchConnections()
    local char = LocalPlayer.Character
    if not char then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local baseHipHeight = hum.HipHeight
    local baseWalkSpeed = hum.WalkSpeed

    table.insert(crouchConnections, hum:GetPropertyChangedSignal("HipHeight"):Connect(function()
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then
            return
        end
        if hum.HipHeight < baseHipHeight - 0.05 then
            descendoCTRL = true
            vAtualDescida = 0
        else
            descendoCTRL = false
            vAtualDescida = 0
            emEstadoDeBounce = false
        end
    end))

    table.insert(crouchConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then
            return
        end
        if hum.WalkSpeed < baseWalkSpeed * 0.6 then
            descendoCTRL = true
            vAtualDescida = 0
        else
            descendoCTRL = false
            vAtualDescida = 0
            emEstadoDeBounce = false
        end
    end))

    table.insert(crouchConnections, hum.StateChanged:Connect(function(_, newState)
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then
            return
        end
        if newState == Enum.HumanoidStateType.Seated then
            descendoCTRL = true
            vAtualDescida = 0
        elseif newState == Enum.HumanoidStateType.Running
            or newState == Enum.HumanoidStateType.Jumping
            or newState == Enum.HumanoidStateType.Freefall then
            descendoCTRL = false
            vAtualDescida = 0
            emEstadoDeBounce = false
        end
    end))
end

-- =====================================================
-- KEYBOARD SOUND
-- =====================================================

local BASE_SOUND_ID = "rbxassetid://4724428597"
local BASE_SOUND_ID_2 = "rbxassetid://125027148509088"
local baseSound = Instance.new("Sound", SoundService)
baseSound.SoundId = BASE_SOUND_ID
baseSound.Volume = 1
baseSound.PlaybackSpeed = 0.95
baseSound.RollOffMaxDistance = 50
baseSound.RollOffMode = Enum.RollOffMode.Linear

local baseSound2 = Instance.new("Sound", SoundService)
baseSound2.SoundId = BASE_SOUND_ID_2
baseSound2.Volume = 1
baseSound2.PlaybackSpeed = 0.95
baseSound2.RollOffMaxDistance = 50
baseSound2.RollOffMode = Enum.RollOffMode.Linear

local function playKeyboardSound()
    if not Settings.keyboardSoundEnabled then
        return
    end
    local useSound2 = math.random(1, 100) <= 50
    local s = useSound2 and baseSound2:Clone() or baseSound:Clone()
    s.Parent = SoundService
    s.PlaybackSpeed = 0.9 + (math.random() * 0.2)
    s.Volume = 0.9 + (math.random() * 0.3)
    s:Play()
    s.Ended:Connect(function()
        s:Destroy()
    end)
end

-- =====================================================
-- COSMETIC / AVATAR / VFX
-- =====================================================

local K_MESH_ID = 101851696
local K_OVERLAY_ID = 101851254
local K_COLOR = Color3.fromRGB(38, 65, 68)
local KORBLOX_COLOR_ATTR = "MWOriginalKorbloxLegColor"
local KORBLOX_MATERIAL_ATTR = "MWOriginalKorbloxLegMaterial"
local KORBLOX_TRANSPARENCY_ATTR = "MWOriginalKorbloxLegTransparency"
local HEADLESS_TRANSPARENCY_ATTR = "MWOriginalHeadlessTransparency"
local avatarCosmeticRetryToken = 0

local function applyDeepWineLogic(target, customColor)
    if not target then
        return
    end

    local mainCol = customColor or WINE_CONFIG.TrueWine
    local skinParts = {
        ["Head"] = true,
        ["Torso"] = true,
        ["Left Arm"] = true,
        ["Right Arm"] = true,
        ["Left Leg"] = true,
        ["Right Leg"] = true,
        ["LeftUpperArm"] = true,
        ["RightUpperArm"] = true,
        ["LeftLowerArm"] = true,
        ["RightLowerArm"] = true,
        ["LeftHand"] = true,
        ["RightHand"] = true,
        ["LeftUpperLeg"] = true,
        ["RightUpperLeg"] = true,
        ["LeftLowerLeg"] = true,
        ["RightLowerLeg"] = true,
        ["LeftFoot"] = true,
        ["RightFoot"] = true,
        ["UpperTorso"] = true,
        ["LowerTorso"] = true
    }

    for _, obj in pairs(target:GetDescendants()) do
        if obj:IsA("BasePart") and (skinParts[obj.Name] or obj.Name == "HumanoidRootPart") then
            continue
        end
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            obj.Color = mainCol
            obj.Material = WINE_CONFIG.Material
            if obj:IsA("MeshPart") then
                obj.TextureID = ""
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, mainCol),
                ColorSequenceKeypoint.new(1, WINE_CONFIG.BlackWine)
            })
        end
    end
end

local function applyCustomStyle(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = WINE_CONFIG.Material
            v.Color = WINE_CONFIG.TrueWine
        end
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
            v.Color = deepWineSequence
            v.LightEmission = 0
            v.LightInfluence = 0.8
        end
    end
end

local function getKorbloxRightLeg(char)
    if not char then
        return nil
    end

    return char:FindFirstChild("Right Leg")
        or char:FindFirstChild("RightLowerLeg")
        or char:FindFirstChild("RightUpperLeg")
end

local function saveKorbloxLegOriginals(char, rLeg)
    if not char or not rLeg then
        return
    end

    if rLeg:GetAttribute(KORBLOX_COLOR_ATTR) == nil then
        local savedColor = char:GetAttribute("OriginalLegColor") or rLeg.Color
        rLeg:SetAttribute(KORBLOX_COLOR_ATTR, savedColor)
        char:SetAttribute("OriginalLegColor", savedColor)
    end
    if rLeg:GetAttribute(KORBLOX_MATERIAL_ATTR) == nil then
        rLeg:SetAttribute(KORBLOX_MATERIAL_ATTR, rLeg.Material.Name)
    end
    if rLeg:GetAttribute(KORBLOX_TRANSPARENCY_ATTR) == nil then
        rLeg:SetAttribute(KORBLOX_TRANSPARENCY_ATTR, rLeg.Transparency)
    end
end

local function applyKorblox(char)
    if not char or not Settings.KorbloxEnabled then
        return false
    end
    local rLeg = getKorbloxRightLeg(char)
    if not rLeg then
        return false
    end

    saveKorbloxLegOriginals(char, rLeg)

    local rLegMesh = char:FindFirstChild("KorbloxMesh") or Instance.new("CharacterMesh")
    rLegMesh.Name = "KorbloxMesh"
    rLegMesh.BodyPart = Enum.BodyPart.RightLeg
    rLegMesh.MeshId = K_MESH_ID
    rLegMesh.BaseTextureId = 0
    rLegMesh.OverlayTextureId = K_OVERLAY_ID
    rLegMesh.Parent = char

    for _, v in ipairs(rLeg:GetChildren()) do
        if v:IsA("SpecialMesh") then
            v:Destroy()
        end
    end

    rLeg.Color = K_COLOR
    rLeg.Transparency = 0
    rLeg.Material = Enum.Material.Plastic
    return true
end

local function removeKorblox(char)
    if not char then
        return false
    end

    local mesh = char:FindFirstChild("KorbloxMesh")
    if mesh then
        mesh:Destroy()
    end

    local rLeg = getKorbloxRightLeg(char)
    if rLeg then
        local originalColor = rLeg:GetAttribute(KORBLOX_COLOR_ATTR) or char:GetAttribute("OriginalLegColor")
        if originalColor then
            rLeg.Color = originalColor
        else
            rLeg.Color = Color3.fromRGB(163, 162, 165)
        end

        local originalMaterial = rLeg:GetAttribute(KORBLOX_MATERIAL_ATTR)
        if originalMaterial and Enum.Material[originalMaterial] then
            rLeg.Material = Enum.Material[originalMaterial]
        else
            rLeg.Material = Enum.Material.Plastic
        end

        local originalTransparency = rLeg:GetAttribute(KORBLOX_TRANSPARENCY_ATTR)
        rLeg.Transparency = type(originalTransparency) == "number" and originalTransparency or 0

        rLeg:SetAttribute(KORBLOX_COLOR_ATTR, nil)
        rLeg:SetAttribute(KORBLOX_MATERIAL_ATTR, nil)
        rLeg:SetAttribute(KORBLOX_TRANSPARENCY_ATTR, nil)
    end

    char:SetAttribute("OriginalLegColor", nil)
    return true
end

local function saveOriginalTransparency(obj)
    if obj and obj:GetAttribute(HEADLESS_TRANSPARENCY_ATTR) == nil then
        obj:SetAttribute(HEADLESS_TRANSPARENCY_ATTR, obj.Transparency)
    end
end

local function applyHeadless(char)
    if not char or not Settings.HeadlessEnabled then
        return false
    end

    local head = char:FindFirstChild("Head")
    if not head then
        return false
    end

    saveOriginalTransparency(head)
    head.Transparency = 1

    for _, obj in ipairs(head:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            saveOriginalTransparency(obj)
            obj.Transparency = 1
        end
    end

    return true
end

local function removeHeadless(char)
    if not char then
        return false
    end

    local head = char:FindFirstChild("Head")
    if not head then
        return false
    end

    local originalTransparency = head:GetAttribute(HEADLESS_TRANSPARENCY_ATTR)
    head.Transparency = type(originalTransparency) == "number" and originalTransparency or 0
    head:SetAttribute(HEADLESS_TRANSPARENCY_ATTR, nil)

    for _, obj in ipairs(head:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            local originalDecalTransparency = obj:GetAttribute(HEADLESS_TRANSPARENCY_ATTR)
            obj.Transparency = type(originalDecalTransparency) == "number" and originalDecalTransparency or 0
            obj:SetAttribute(HEADLESS_TRANSPARENCY_ATTR, nil)
        end
    end

    return true
end

local function applyAvatarCosmeticsWithRetries(char)
    avatarCosmeticRetryToken = avatarCosmeticRetryToken + 1
    local token = avatarCosmeticRetryToken

    task.spawn(function()
        for _ = 1, 16 do
            if token ~= avatarCosmeticRetryToken then
                return
            end
            if not char or char ~= LocalPlayer.Character then
                return
            end

            if Settings.HeadlessEnabled then
                applyHeadless(char)
            end
            if Settings.KorbloxEnabled then
                applyKorblox(char)
            end

            task.wait(0.35)
        end
    end)
end

local NonMovableEmoteHopEnabled = false
local NonMovableEmoteOriginals = {}

local function applyNonMovableEmoteHop()
    local EmotesFolder = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Emotes")
    local fixedCount = 0

    for _, module in pairs(EmotesFolder:GetDescendants()) do
        if module:IsA("ModuleScript") then
            local success, emoteData = pcall(require, module)
            if success and type(emoteData) == "table" and emoteData["EmoteInfo"] then
                local emoteInfo = emoteData["EmoteInfo"]
                if type(emoteInfo) == "table" and emoteInfo["SpeedMult"] == 0 then
                    if NonMovableEmoteOriginals[emoteInfo] == nil then
                        NonMovableEmoteOriginals[emoteInfo] = emoteInfo["SpeedMult"]
                    end
                    emoteInfo["SpeedMult"] = 1
                    fixedCount = fixedCount + 1
                end
            end
        end
    end

    return fixedCount
end

local function restoreNonMovableEmoteHop()
    for emoteInfo, speedMult in pairs(NonMovableEmoteOriginals) do
        if type(emoteInfo) == "table" then
            pcall(function()
                emoteInfo["SpeedMult"] = speedMult
            end)
        end
    end

    NonMovableEmoteOriginals = {}
end

local function loadVFX()
    -- Original script kept this as a hook. Add VFX emitters to _G.vfxAttachments here.
end

local lastFP = nil
local function updateVFXFirstPerson(char)
    if not char then
        return
    end
    local head = char:FindFirstChild("Head")
    if not head or not camera then
        return
    end

    local dist = (camera.CFrame.Position - head.Position).Magnitude
    local isFP = (dist < 0.8) or (LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson)
    if isFP ~= lastFP then
        lastFP = isFP
        for _, fx in ipairs(_G.vfxAttachments) do
            if fx and fx.Parent and fx.Enabled ~= nil then
                fx.Enabled = not isFP
            end
        end
    end
end

-- =====================================================
-- INVIS WALL / HITBOX CREATOR
-- =====================================================

local originalState = {}
local function updateInvisWall(v)
    Settings.InvisWallEnabled = v
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency >= 0.5 and obj.Size.Magnitude >= 12 then
            if v then
                if originalState[obj] == nil then
                    originalState[obj] = obj.CanCollide
                end
                obj.CanCollide = false
            else
                if originalState[obj] ~= nil then
                    obj.CanCollide = originalState[obj]
                end
            end
        end
    end
end

-- =====================================================
-- MOBILE BUTTONS / MOBILE EDGE
-- =====================================================

local setupMobileEdge


-- =====================================================
-- MOBILE EDGE (touch connection only, no GUI)
-- =====================================================

local mobileEdgeTouchConn = nil

setupMobileEdge = function(char)
    if mobileEdgeTouchConn then
        mobileEdgeTouchConn:Disconnect()
        mobileEdgeTouchConn = nil
    end
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    mobileEdgeTouchConn = hrp.Touched:Connect(function(hit)
        if not Settings.MobileEdgeEnabled then return end
        if not hit or not hit:IsA("BasePart") then return end
        local currentChar = LocalPlayer.Character
        local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if currentRoot and currentRoot.AssemblyLinearVelocity.Y < -1.0 then
            local name = hit.Name:lower()
            if name:find("bounce") or name:find("boost") then return end
            currentRoot.AssemblyLinearVelocity = Vector3.new(
                currentRoot.AssemblyLinearVelocity.X,
                Settings.EdgePower,
                currentRoot.AssemblyLinearVelocity.Z
            )
        end
    end)
end

-- =====================================================
-- KEY MATCH HELPERS / INPUT
-- =====================================================


local function inputMatchesYLockKey(input)
    return input.KeyCode == YLockSurfKey
end
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end

    pcall(function()
        if YLockSurfEnabled and inputMatchesYLockKey(input) then
            if YLockSurfMode == "Toggle" then
                if isYLocked then
                    UnlockYPosition()
                else
                    LockYPosition()
                end
            else
                LockYPosition()
            end
        end
    end)

    if executando then
        pcall(function()
            if input.KeyCode == Enum.KeyCode.Q then
                subindoQ = not subindoQ
            elseif input.KeyCode == Enum.KeyCode.LeftControl then
                descendoCTRL = true
                vAtualDescida = 0
            end
        end)
    end

    pcall(function()
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Space then
            playKeyboardSound()
        end
    end)
end)

UserInputService.InputEnded:Connect(function(input)
    pcall(function()
        if YLockSurfEnabled
            and YLockSurfMode == "Hold"
            and inputMatchesYLockKey(input) then
            UnlockYPosition()
        end
    end)

    if not executando then
        return
    end

    pcall(function()
        if input.KeyCode == Enum.KeyCode.LeftControl then
            descendoCTRL = false
            vAtualDescida = 0
            emEstadoDeBounce = false
        end
    end)
end)

-- =====================================================
-- FOV / RENDER LOOPS / FFLAG
-- =====================================================

local fovSignalConn = nil
local originalFOV = nil  -- Store original FOV
local function enforceFOV()
    camera = Workspace.CurrentCamera
    if camera then
        if Settings.FOVEnabled then
            -- Store original FOV when first enabling
            if originalFOV == nil then
                originalFOV = camera.FieldOfView
            end
            if camera.FieldOfView ~= Settings.FOV then
                camera.FieldOfView = Settings.FOV
            end
        else
            -- Restore original FOV when disabled
            if originalFOV and camera.FieldOfView ~= originalFOV then
                camera.FieldOfView = originalFOV
            end
        end
    end
end

local function hookCameraFOVSignal(cam)
    if fovSignalConn then
        fovSignalConn:Disconnect()
        fovSignalConn = nil
    end
    if cam then
        fovSignalConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFOV)
    end
end
hookCameraFOVSignal(camera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    hookCameraFOVSignal(Workspace.CurrentCamera)
end)

RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    enforceFOV()
    updateVFXFirstPerson(char)

    if Settings.KorbloxEnabled then
        local rLeg = getKorbloxRightLeg(char)
        if rLeg and rLeg.Color ~= K_COLOR then
            rLeg.Color = K_COLOR
        end
    end

    if Settings.SpinEnabled then
        hrp.CFrame *= CFrame.Angles(0, (2 * math.pi / 0.3) * dt, 0)
    end

    if Settings.TurnEnabled then
        hrp.CFrame *= CFrame.Angles(0, (20 * math.pi / math.max(Settings.TurnSpeed, 0.001)) * dt, 0)
    end

    if Settings.TrimpEnabled and hrp.AssemblyLinearVelocity.Y < -1.0 then
        if #hrp:GetTouchingParts() > 0 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 95, hrp.AssemblyLinearVelocity.Z)
        end
    end

    if YLockSurfEnabled then
        MaintainYLock()
    end

    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        local bv = hrp:FindFirstChild("FlyVelocity")
        if bv then
            if not executando then
                bv.MaxForce = Vector3.new(0, 0, 0)
            else
                if subindoQ or descendoCTRL or math.abs(vFinal) > 0.1 then
                    bv.MaxForce = Vector3.new(0, 9e6, 0)
                else
                    bv.MaxForce = Vector3.new(0, 0, 0)
                end

                if descendoCTRL then
                    if vAtualSubida > 0 then
                        vAtualSubida = vAtualSubida - (aceleracaoSubida * 1.5 * dt)
                        if vAtualSubida < 0 then
                            vAtualSubida = 0
                        end
                        vFinal = vAtualSubida
                    else
                        local chao = detectaObjeto(Vector3.new(0, -1, 0), distanciaChaoBounce)
                        if chao and not emEstadoDeBounce then
                            emEstadoDeBounce = true
                            vAtualDescida = -forcaBounce
                        end

                        if emEstadoDeBounce then
                            vAtualDescida = vAtualDescida + (Workspace.Gravity * dt)
                            if vAtualDescida >= 0 then
                                emEstadoDeBounce = false
                            end
                        else
                            if vAtualDescida < velocidadeDescidaMax then
                                vAtualDescida = vAtualDescida + (aceleracaoDescida * dt)
                            end
                        end
                        vFinal = -vAtualDescida
                    end
                elseif subindoQ then
                    local teto = detectaObjeto(Vector3.new(0, 1, 0), distanciaTeto)
                    if teto then
                        vAtualSubida = 0
                    else
                        if vAtualSubida < velocidadeSubidaAlvo then
                            vAtualSubida = vAtualSubida + (aceleracaoSubida * dt)
                        end
                    end
                    vFinal = vAtualSubida
                else
                    vAtualSubida = math.max(0, vAtualSubida - (aceleracaoSubida * dt))
                    vAtualDescida = math.max(0, vAtualDescida - (aceleracaoDescida * dt))
                    vFinal = vAtualSubida - vAtualDescida
                end

                local jitterY = (subindoQ and not descendoCTRL) and (math.random() - 0.5) * jitterVelocidade or 0
                bv.Velocity = Vector3.new(0, vFinal + jitterY, 0)

                if subindoQ and not descendoCTRL and vFinal > 0 then
                    local offsetPos = Vector3.new(
                        (math.random() - 0.5) * intensidadeTremor,
                        (math.random() - 0.5) * intensidadeTremor,
                        (math.random() - 0.5) * intensidadeTremor
                    )
                    hrp.CFrame = hrp.CFrame * CFrame.new(offsetPos)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        if Settings.FFlagEnabled then
            pcall(function()
                setfflag("MaxMissedWorldStepsRemembered", "1000")
            end)
        end
        task.wait(1)
    end
end)

-- =====================================================
-- CHARACTER RESPAWN HANDLER
-- =====================================================

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)

    isYLocked = false
    lockedY = nil
    originalHipHeight = nil
    resetVirtualStrafe()
    if EasyBounceEnabled then
        refreshEasyBounceCharacter(char)
    end

    setupMobileEdge(char)

    if Settings.HeadlessEnabled or Settings.KorbloxEnabled then
        applyAvatarCosmeticsWithRetries(char)
    end

    if Settings.VFXEnabled then
        _G.vfxAttachments = {}
        loadVFX()
    end

    if Settings.AutoApplyCosmetic then
        applyDeepWineLogic(char)
    end

    if Settings.AutoApplyGlobalColor and globalColorEnabled then
        task.wait(0.5)
        applyGlobalColor()
    end

    if Settings.AutoApplySkyColor and skyColorEnabled then
        applySkyColor()
    end

    if Settings.AutoApplyPerfectFog and perfectFogEnabled then
        applyPerfectFog()
    end

    if AirStrafeSpeedEnabled then
        task.wait(1)
        applyAirStrafeModifications()
    end

    if NonMovableEmoteHopEnabled then
        pcall(applyNonMovableEmoteHop)
    end

    if SpeedFixEnabled then
        pcall(applySpeedFix)
    end

    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        task.wait(0.2)
        updateFlyVelocity()
        startCrouchDetect()
    end

    if Settings.AutoApplyDraconicEmoteSwapper then
        task.wait(1)
        local swappedCount = 0
        for i = 1, 6 do
            local currentEmote = EmoteSwapper.CurrentEmotes[i]
            local selectedEmote = EmoteSwapper.SelectedEmotes[i]
            if currentEmote ~= "" and selectedEmote ~= "" then
                if replaceEmoteContents(currentEmote, selectedEmote) then
                    swappedCount = swappedCount + 1
                end
            end
        end
        if swappedCount > 0 then
            notify("Auto-applied " .. swappedCount .. " emote swap(s) on respawn.", 3)
        end
    end
end)

if LocalPlayer.Character then
    setupMobileEdge(LocalPlayer.Character)
end

if LocalPlayer.Character and Settings.VFXEnabled then
    task.spawn(function()
        task.wait(2)
        _G.vfxAttachments = {}
        loadVFX()
    end)
end




-- =====================================================
-- TAS SYSTEM
-- =====================================================

-- TAS System Variables
local Running = false
local Frames = {}
local TimeStart = tick()
local IsRecording = false
local IsPlaying = false
local Keybinds = {
    StartRecord = "F1",
    StopRecord = "F2", 
    PlayTAS = "F3",
    ClearFrames = "F4"
}
local IsSettingKeybind = nil

local getChar = function()
    local Character = LocalPlayer.Character
    if Character then
        return Character
    else
        LocalPlayer.CharacterAdded:Wait()
        return getChar()
    end
end

local StartRecord = function()
    if IsRecording then return end
    if IsPlaying then return end
    
    Frames = {}
    Running = true
    IsRecording = true
    TimeStart = tick()
    
    notify("TAS Recording started...", 2)
    
    while Running == true do
        game:GetService("RunService").Heartbeat:wait()
        local Character = getChar()
        if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") then
            table.insert(Frames, {
                Character.HumanoidRootPart.CFrame,
                Character.Humanoid:GetState().Value,
                tick() - TimeStart
            })
        end
    end
    
    IsRecording = false
    notify("TAS Recording stopped. Frames: " .. #Frames, 3)
end

local StopRecord = function()
    Running = false
    IsRecording = false
    notify("TAS Recording stopped. Frames: " .. #Frames, 3)
end

local PlayTAS = function()
    if IsPlaying then return end
    if IsRecording then return end
    if #Frames == 0 then 
        notify("No frames to play!", 3)
        return 
    end
    
    IsPlaying = true
    local Character = getChar()
    local TimePlay = tick()
    local FrameCount = #Frames
    local OldFrame = 1
    local TASLoop
    
    notify("Playing TAS...", 2)
    
    TASLoop = game:GetService("RunService").Heartbeat:Connect(function()
        local CurrentTime = tick()
        if (CurrentTime - TimePlay) >= Frames[FrameCount][3] then
            TASLoop:Disconnect()
            IsPlaying = false
            notify("TAS Playback complete!", 3)
            return
        end
        
        local NewFrames = math.min(OldFrame + 60, FrameCount)
        for i = OldFrame, NewFrames do
            local Frame = Frames[i]
            if Frame and Frame[3] <= CurrentTime - TimePlay then
                OldFrame = i
                if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") then
                    Character.HumanoidRootPart.CFrame = Frame[1]
                    Character.Humanoid:ChangeState(Frame[2])
                end
            end
        end
    end)
end

local ClearFrames = function()
    if IsRecording or IsPlaying then return end
    Frames = {}
    notify("TAS Frames cleared!", 2)
end

-- Setup keybind input handling
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if IsSettingKeybind then
        -- Don't allow mouse buttons as keybinds
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        
        -- Update the keybind
        local keyCode = input.KeyCode.Name
        Keybinds[IsSettingKeybind] = keyCode
        notify("Keybind updated: " .. IsSettingKeybind .. " = " .. keyCode, 2)
        -- (kamiblox UI: textboxes updated directly by user)
        
        IsSettingKeybind = nil
        return
    end
    
    -- Handle keybind actions
    if input.KeyCode.Name == Keybinds.StartRecord then
        StartRecord()
    elseif input.KeyCode.Name == Keybinds.StopRecord then
        StopRecord()
    elseif input.KeyCode.Name == Keybinds.PlayTAS then
        PlayTAS()
    elseif input.KeyCode.Name == Keybinds.ClearFrames then
        ClearFrames()
    end
end)


-- =====================================================
-- MAPS SYSTEM
-- =====================================================

local function setSunriseSky()
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            obj:Destroy()
        end
    end

    local sky = Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://252760981"
    sky.SkyboxDn = "rbxassetid://252763921"
    sky.SkyboxFt = "rbxassetid://252761439"
    sky.SkyboxLf = "rbxassetid://252761439"
    sky.SkyboxRt = "rbxassetid://252761439"
    sky.SkyboxUp = "rbxassetid://252762708"
    sky.SunAngularSize = 25

    Lighting.ClockTime = 6.3
    Lighting.Brightness = 2.5
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 120, 100)
    Lighting.ExposureCompensation = 0.5

    local atmosphere = Instance.new("Atmosphere", Lighting)
    atmosphere.Density = 0.25
    atmosphere.Color = Color3.fromRGB(255, 200, 160)
    atmosphere.Glare = 0.4
end

local function loadMapByAssetId(mapAssetID)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local assetID = stripAssetPrefix(mapAssetID)
    local ScaleFactor = Settings.MapScale
    local SpawnHeight = Settings.SpawnHeight

    for _, old in pairs(Workspace:GetChildren()) do
        if old.Name == "Injected_System" then
            old:Destroy()
        end
    end

    setSunriseSky()

    local success, err = pcall(function()
        local objects = game:GetObjects(string.format("rbxassetid://%s", assetID))
        local mapModel = objects[1]
        if not mapModel then
            return
        end

        if not mapModel:IsA("Model") then
            local folder = Instance.new("Model", Workspace)
            mapModel.Parent = folder
            mapModel = folder
        end

        mapModel.Name = "Injected_System"
        mapModel.Parent = Workspace
        mapModel:ScaleTo(mapModel:GetScale() * ScaleFactor)

        for _, part in pairs(mapModel:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Transparency >= 1 and part.CanCollide then
                    part.CanCollide = false
                end
                if part.CanCollide then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 1, 0.5, 1)
                end
            end
        end

        local targetPos = Vector3.new(rootPart.Position.X, SpawnHeight, rootPart.Position.Z)
        mapModel:MoveTo(targetPos)

        task.wait(0.6)
        rootPart.CFrame = mapModel:GetPivot() + Vector3.new(0, 20, 0)
        notify(string.format("Map loaded. Scale: %s", tostring(ScaleFactor)), 3)
    end)

    if not success then
        warn(err)
        notify("Map load failed: " .. tostring(err), 4)
    end
end
local CustomMaps = {
    {Name = "NN_Russia", URL = "https://pastebin.com/raw/rSHkiSEn", Loaded = false},
    {Name = "NN_Outpost", URL = "https://pastebin.com/raw/HyKrhP2q", Loaded = false},
    {Name = "NN_Shibuya", URL = "https://pastebin.com/raw/AXrhwppi", Loaded = false},
    {Name = "NN_Mall", URL = "https://pastebin.com/raw/R7A87x4X", Loaded = false},
    {Name = "NN_Crossroads", URL = "https://pastebin.com/raw/uyM0bSWA", Loaded = false},
    {Name = "NN_BigMaze", URL = "https://pastebin.com/raw/dfKM1K6a", Loaded = false},
    {Name = "NN_Outpost V2", URL = "https://pastebin.com/raw/HyKrhP2q", Loaded = false},
    {Name = "NN_LostRuins", URL = "https://pastebin.com/raw/j6a5Jvng", Loaded = false},
    {Name = "NN_HappyHome", URL = "https://pastebin.com/raw/vbqhXNmc", Loaded = false},
    {Name = "FrostYear Peaks", URL = "https://pastebin.com/raw/XGUte0ZP", Loaded = false},
    {Name = "Plague Square", URL = "https://pastebin.com/raw/8MTaq8KW", Loaded = false}
}

local function loadCustomMap(mapData)
    if mapData.Loaded then
        notify(mapData.Name .. " is already loaded.", 2)
        return
    end

    notify("Loading " .. mapData.Name .. "...", 2)
    local success, err = pcall(function()
        loadstring(game:HttpGet(mapData.URL))()
    end)

    if success then
        mapData.Loaded = true
        notify(mapData.Name .. " loaded successfully.", 3)
    else
        notify("Failed to load " .. mapData.Name .. ": " .. tostring(err), 4)
        warn("Custom Maps Loader: Failed to load " .. mapData.Name .. " - " .. tostring(err))
    end
end

-- =====================================================



-- =====================================================
-- SATURATION CONTROLLER
-- =====================================================

local saturationValue = 0
local saturationEnabled = false

local function getRobloxSaturation(uiValue)
    return uiValue / 100
end

local function getColorCorrection()
    local effect = Lighting:FindFirstChild("SaturationController")
    if not effect then
        effect = Instance.new("ColorCorrectionEffect")
        effect.Name = "SaturationController"
        effect.Parent = Lighting
    end
    effect.Saturation = saturationEnabled and getRobloxSaturation(saturationValue) or 0
    return effect
end

Lighting.ChildAdded:Connect(function(child)
    if child.Name == "SaturationController" and child:IsA("ColorCorrectionEffect") then
        child.Saturation = saturationEnabled and getRobloxSaturation(saturationValue) or 0
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    getColorCorrection()
end)

-- =====================================================
-- AUTO BENCH SYSTEM
-- =====================================================

local autoBenchEnabled = false
local autoBenchConnections = {}
local autoBenchDebounce = {}
local autoBenchHeights = {100, 70, 80, 90}

local function autoBenchOnTouch(hit)
    if not autoBenchEnabled then return end
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoid and rootPart then
        if autoBenchDebounce[character] then return end
        autoBenchDebounce[character] = true
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        local selectedHeight = autoBenchHeights[math.random(1, #autoBenchHeights)]
        rootPart.AssemblyLinearVelocity = Vector3.new(
            rootPart.AssemblyLinearVelocity.X,
            selectedHeight,
            rootPart.AssemblyLinearVelocity.Z
        )
        task.delay(0.5, function()
            autoBenchDebounce[character] = nil
        end)
    end
end

local function applyToBenchModel(model)
    if model:IsA("Model") or model:IsA("Folder") then
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                local conn = descendant.Touched:Connect(autoBenchOnTouch)
                table.insert(autoBenchConnections, conn)
            end
        end
        local conn = model.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("BasePart") then
                local c = descendant.Touched:Connect(autoBenchOnTouch)
                table.insert(autoBenchConnections, c)
            end
        end)
        table.insert(autoBenchConnections, conn)
    end
end

local function enableAutoBench()
    -- Disconnect any old connections first
    for _, conn in ipairs(autoBenchConnections) do conn:Disconnect() end
    table.clear(autoBenchConnections)
    table.clear(autoBenchDebounce)

    local workspaceMap = workspace:FindFirstChild("Map")
    if not workspaceMap then notify("Auto Bench: Map not found.", 3) return end
    local parts = workspaceMap:FindFirstChild("Parts")
    if not parts then notify("Auto Bench: Parts not found.", 3) return end

    local immovableProps = parts:FindFirstChild("ImmovableProps")
    if immovableProps then
        -- Apply to all existing Bench models
        for _, descendant in ipairs(immovableProps:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == "Bench" then
                applyToBenchModel(descendant)
            end
        end
        -- Auto-apply bounce to NEW benches as they are added
        local conn = immovableProps.DescendantAdded:Connect(function(descendant)
            if not autoBenchEnabled then return end
            if descendant:IsA("Model") and descendant.Name == "Bench" then
                applyToBenchModel(descendant)
            end
        end)
        table.insert(autoBenchConnections, conn)
    end

    local mapFolder = parts:FindFirstChild("Map")
    if mapFolder then
        local bench = mapFolder:FindFirstChild("Bench")
        if bench then applyToBenchModel(bench) end
        -- Watch for new Bench added inside mapFolder
        local conn2 = mapFolder.ChildAdded:Connect(function(child)
            if not autoBenchEnabled then return end
            if child:IsA("Model") and child.Name == "Bench" then
                applyToBenchModel(child)
            end
        end)
        table.insert(autoBenchConnections, conn2)
    end

    -- Also watch workspace-level map changes (round restarts create new Maps)
    local conn3 = workspace.ChildAdded:Connect(function(child)
        if not autoBenchEnabled then return end
        if child.Name == "Map" then
            task.wait(0.5) -- let Map fully load
            enableAutoBench()
        end
    end)
    table.insert(autoBenchConnections, conn3)
end

local function disableAutoBench()
    for _, conn in ipairs(autoBenchConnections) do conn:Disconnect() end
    table.clear(autoBenchConnections)
    table.clear(autoBenchDebounce)
end

-- =====================================================
-- KAMIWARE V3 - KAMIBLOX UI SETUP
-- =====================================================

-- Keep UI locals in their own scope so the main chunk stays below Luau's
-- register limit. Callbacks retain anything they need through closures.
local function buildUI()

local Window = Library:CreateWindow({
    Title = "Kamiware V3",
    Size = UDim2.new(0, 836, 0, 538)
})

-- Movement Category
Window:CreateCategory("Movement")
local MovTab = Window:CreateTab("Movement", "8673852020")

-- Visuals Category
Window:CreateCategory("Visuals")
local VisTab  = Window:CreateTab("Visuals", "100065143108986")
local WorldTab = Window:CreateTab("World", "137182874573549")

-- Other Category
Window:CreateCategory("Other")
local TASTab  = Window:CreateTab("TAS", "11802342133")
local MapsTab = Window:CreateTab("Maps", "8673852020")
local MiscTab = Window:CreateTab("Misc", "14219516560")

-- =====================================================
-- MOVEMENT TAB
-- =====================================================

local MovLeft = MovTab:CreateSection({ Name = "Movement", Side = "Left" })

MovLeft:CreateToggle({
    Name = "Air Strafe Speed",
    Default = false,
    Callback = function(v)
        AirStrafeSpeedEnabled = v
        if v then
            applyAirStrafeModifications()
            notify("Air Strafe Speed enabled.", 2)
        else
            restoreAirStrafeModifications()
        end
    end
})
MovLeft:CreateTextbox({ Name = "Strafe Acceleration", Placeholder = "182",
    Callback = function(v)
        local n = tonumber(v)
        if n then AirStrafeAcceleration = n; updateAirStrafeValues() end
    end })

local OverhaulSpeedBoosterEnabled = false
local OverhaulSpeedValue = 1500
local overhaulSpeedOriginal = nil

local function applyOverhaulSpeedBooster()
    local BaseStats = require(game:GetService("ReplicatedStorage").Objects.Game.Character.Client.Movement.MoveStats.BaseStats)
    if overhaulSpeedOriginal == nil then
        overhaulSpeedOriginal = BaseStats.Speed
    end
    BaseStats.Speed = OverhaulSpeedValue
end

local function restoreOverhaulSpeedBooster()
    if overhaulSpeedOriginal == nil then
        return
    end

    local BaseStats = require(game:GetService("ReplicatedStorage").Objects.Game.Character.Client.Movement.MoveStats.BaseStats)
    BaseStats.Speed = overhaulSpeedOriginal
    overhaulSpeedOriginal = nil
end

local JumpCap = { Value = 1 }

function JumpCap.Apply()
    local ok, err = pcall(function()
        local BaseStats = require(game:GetService("ReplicatedStorage").Objects.Game.Character.Client.Movement.MoveStats.BaseStats)
        BaseStats.JumpCap = JumpCap.Value
    end)

    if not ok then
        notify("Unable to change JumpCap: " .. tostring(err), 3)
    end
end

-- Apply the requested default immediately, then expose the value in the Movement tab.
JumpCap.Apply()

MovLeft:CreateToggle({
    Name = "Overhaul Speed", Default = false,
    Callback = function(v)
        OverhaulSpeedBoosterEnabled = v
        if v then
            applyOverhaulSpeedBooster()
            notify("Overhaul Speed enabled. Speed: "..tostring(OverhaulSpeedValue), 2)
        else
            restoreOverhaulSpeedBooster(); notify("Overhaul Speed disabled.", 2)
        end
    end
})
MovLeft:CreateTextbox({ Name = "Overhaul Speed Value", Placeholder = "1500",
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 0 then
            OverhaulSpeedValue = n
            if OverhaulSpeedBoosterEnabled then
                applyOverhaulSpeedBooster()
                notify("Overhaul Speed changed to: "..tostring(OverhaulSpeedValue), 2)
            end
        else
            notify("Enter a valid non-negative speed.", 3)
        end
    end
})
MovLeft:CreateTextbox({ Name = "Jump Cap", Placeholder = "1",
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 1 then
            JumpCap.Value = n
            JumpCap.Apply()
            notify("JumpCap changed to: " .. tostring(JumpCap.Value), 2)
        else
            notify("Enter a number greater than or equal to 1.", 3)
        end
    end
})


MovLeft:CreateToggle({
    Name = "Fly Glitch [Q=Up / Ctrl=Down]",
    Default = false,
    Callback = function(v)
        Settings.PCFlyEnabled = v
        updateFlyVelocity()
        if v then startCrouchDetect() else clearCrouchConnections() end
    end
})

MovLeft:CreateToggle({ Name = "Invis Wall Remover", Default = false,
    Callback = function(v) updateInvisWall(v) end })

MovLeft:CreateToggle({ Name = "Easy Edge Trimp", Default = false,
    Callback = function(v) Settings.TrimpEnabled = v end })

MovLeft:CreateToggle({
    Name = "Easy Bounce", Default = false,
    Callback = function(v)
        EasyBounceEnabled = v
        if v then easyBounceHistory = {}; refreshEasyBounceCharacter(LocalPlayer.Character) end
        notify(v and "Easy Bounce enabled." or "Easy Bounce disabled.", 2)
    end
})

MovLeft:CreateToggle({
    Name = "Emote Speed Fix",
    Default = false,
    Callback = function(v)
        SpeedFixEnabled = v
        if v then
            local n = 0
            pcall(function() n = applySpeedFix() end)
            notify("Emote Speed Fix enabled. Patched: " .. n, 2)
        else
            pcall(revertSpeedFix)
            notify("Emote Speed Fix disabled.", 2)
        end
    end
})

MovLeft:CreateToggle({
    Name = "Auto Trimp", Default = false,
    Callback = function(v)
        AutoTrimpEnabled = v
        notify(v and "Auto Trimp enabled." or "Auto Trimp disabled.", 2)
    end
})
MovLeft:CreateSlider({ Name = "Trimp Power", Min = 50, Max = 300, Default = 100,
    Callback = function(v) TrimpPower = v end })
MovLeft:CreateSlider({ Name = "Trimp Min Speed", Min = 10, Max = 100, Default = 30,
    Callback = function(v) MinSpeed = v end })

-- =====================================================
-- SPEED FIX (Emote SpeedMult patcher)
-- Uses the same approach as the original provided script:
-- hooks require() globally + scans all ReplicatedStorage descendants.
-- =====================================================

local SpeedFixEnabled = false
local SpeedFixOriginals = {}
local speedFixHookInstalled = false
local oldRequireSpeedFix = nil

local function applySpeedFixToTable(tbl)
    if type(tbl) ~= "table" then return end
    if type(tbl.EmoteInfo) == "table" and tbl.EmoteInfo.SpeedMult ~= nil then
        if SpeedFixOriginals[tbl.EmoteInfo] == nil then
            SpeedFixOriginals[tbl.EmoteInfo] = tbl.EmoteInfo.SpeedMult
        end
        tbl.EmoteInfo.SpeedMult = 2
    end
end

local function scanAndPatchSpeedFix()
    local patched = 0
    -- Scan every ModuleScript anywhere in ReplicatedStorage
    for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("ModuleScript") then
            local ok, data = pcall(require, descendant)
            if ok and type(data) == "table" then
                local before = data.EmoteInfo and data.EmoteInfo.SpeedMult
                applySpeedFixToTable(data)
                local after = data.EmoteInfo and data.EmoteInfo.SpeedMult
                if before ~= after then patched = patched + 1 end
            end
        end
    end
    return patched
end

local function installSpeedFixHook()
    if speedFixHookInstalled then return end
    speedFixHookInstalled = true
    pcall(function()
        oldRequireSpeedFix = hookfunction(require, function(module)
            local result = oldRequireSpeedFix(module)
            if SpeedFixEnabled then
                pcall(applySpeedFixToTable, result)
            end
            return result
        end)
    end)
end

local function applySpeedFix()
    installSpeedFixHook()
    local patched = scanAndPatchSpeedFix()
    return patched
end

local function revertSpeedFix()
    for emoteInfo, original in pairs(SpeedFixOriginals) do
        if type(emoteInfo) == "table" then
            pcall(function() emoteInfo["SpeedMult"] = original end)
        end
    end
    SpeedFixOriginals = {}
end

-- =====================================================
-- FFLAG LAGSWITCH
-- =====================================================

local FFlagLagswitchEnabled  = false   -- must be toggled on in hub first
local FFlagLagswitchActive   = false   -- currently frozen
local FFlagLagswitchKey      = Enum.KeyCode.E
local FFlagFreezeDuration    = 3       -- seconds
local fflagLagswitchListening = false

local function activateFFlagLagswitch()
    if FFlagLagswitchActive then return end
    FFlagLagswitchActive = true
    notify("FFlag Lagswitch: FREEZE for " .. tostring(FFlagFreezeDuration) .. "s", 2)
    pcall(function()
        setfflag("MaxMissedWorldStepsRemembered", "999999")
        setfflag("DFIntNetworkStepsThreshold", "999999")
        setfflag("DFIntS2PhysicsSenderRate", "1")
    end)
    task.delay(FFlagFreezeDuration, function()
        FFlagLagswitchActive = false
        pcall(function()
            setfflag("MaxMissedWorldStepsRemembered", "1000")
            setfflag("DFIntNetworkStepsThreshold", "16")
            setfflag("DFIntS2PhysicsSenderRate", "30")
        end)
        notify("FFlag Lagswitch: RESUMED", 2)
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not FFlagLagswitchEnabled then return end
    if fflagLagswitchListening then return end
    if input.KeyCode == FFlagLagswitchKey then
        activateFFlagLagswitch()
    end
end)

-- =====================================================
-- LAGSWITCH (physics freeze via BodyVelocity zeroing)
-- =====================================================

local LagswitchEnabled   = false   -- must be toggled on in hub first
local LagswitchActive    = false   -- currently frozen
local LagswitchKey       = Enum.KeyCode.E
local LagswitchFreezeDuration = 3  -- seconds
local lagswitchListening  = false
local lagswitchConn       = nil

local function activateLagswitch()
    if LagswitchActive then return end
    LagswitchActive = true
    notify("Lagswitch: FREEZE for " .. tostring(LagswitchFreezeDuration) .. "s", 2)

    -- Zero all outgoing velocity by locking HRP in place
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local frozenCF = hrp and hrp.CFrame
    local bv, ba
    if hrp then
        bv = Instance.new("BodyVelocity")
        bv.Velocity   = Vector3.new(0, 0, 0)
        bv.MaxForce   = Vector3.new(math.huge, math.huge, math.huge)
        bv.P          = math.huge
        bv.Parent     = hrp

        ba = Instance.new("BodyAngularVelocity")
        ba.AngularVelocity = Vector3.new(0, 0, 0)
        ba.MaxTorque       = Vector3.new(math.huge, math.huge, math.huge)
        ba.P               = math.huge
        ba.Parent          = hrp

        lagswitchConn = RunService.Heartbeat:Connect(function()
            if hrp and hrp.Parent and frozenCF then
                hrp.CFrame = frozenCF
            end
        end)
    end

    task.delay(LagswitchFreezeDuration, function()
        LagswitchActive = false
        if bv and bv.Parent then bv:Destroy() end
        if ba and ba.Parent then ba:Destroy() end
        if lagswitchConn then lagswitchConn:Disconnect(); lagswitchConn = nil end
        notify("Lagswitch: RESUMED", 2)
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not LagswitchEnabled then return end
    if lagswitchListening then return end
    if input.KeyCode == LagswitchKey then
        activateLagswitch()
    end
end)

local MovRight = MovTab:CreateSection({ Name = "Y Lock & Misc", Side = "Right" })

MovRight:CreateToggle({
    Name = "Y Lock Surf", Default = false,
    Callback = function(v)
        YLockSurfEnabled = v
        if not v then UnlockYPosition() end
        notify(v and "Y Lock Surf enabled." or "Y Lock Surf disabled.", 2)
    end
})
MovRight:CreateDropdown({ Name = "Y Lock Mode", Options = {"Toggle", "Hold"}, Default = "Toggle",
    Callback = function(v)
        YLockSurfMode = v
        if v == "Hold" then UnlockYPosition() end
    end
})
MovRight:CreateKeybind({ Name = "Y Lock Key", Default = "X",
    Callback = function(v)
        local key = Enum.KeyCode[v]
        if key then YLockSurfKey = key end
    end })

MovRight:CreateToggle({
    Name = "Turnbind (A→Left / D→Right)", Default = false,
    Callback = function(v)
        TurnbindSettings.Enabled = v
        if v then startTurnbind(); notify("Turnbind enabled.", 2)
        else stopTurnbind(); notify("Turnbind disabled.", 2) end
    end
})
MovRight:CreateKeybind({ Name = "Turnbind Key", Default = "R",
    Callback = function(v) TurnbindActivateKey = v end })

MovRight:CreateToggle({ Name = "Notifications", Default = true,
    Callback = function(v) notificationsEnabled = v; Settings.NotificationsEnabled = v end })

-- =====================================================
-- FFLAG LAGSWITCH SECTION (Movement Tab - Right)
-- =====================================================
local MovFFlagLS = MovTab:CreateSection({ Name = "FFlag Lagswitch", Side = "Right" })

MovFFlagLS:CreateToggle({
    Name = "Enable FFlag Lagswitch",
    Default = false,
    Callback = function(v)
        FFlagLagswitchEnabled = v
        if v then
            notify("FFlag Lagswitch enabled. Press [" .. FFlagLagswitchKey.Name .. "] to freeze.", 3)
        else
            notify("FFlag Lagswitch disabled.", 2)
        end
    end
})
MovFFlagLS:CreateTextbox({
    Name = "Freeze Duration (seconds)",
    Placeholder = "3",
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            FFlagFreezeDuration = n
            notify("FFlag freeze duration set to: " .. tostring(n) .. "s", 2)
        else
            notify("Enter a valid positive number.", 3)
        end
    end
})
MovFFlagLS:CreateKeybind({
    Name = "Activate Keybind",
    Default = "E",
    Callback = function(v)
        fflagLagswitchListening = false
        local key = Enum.KeyCode[v]
        if key then
            FFlagLagswitchKey = key
            notify("FFlag Lagswitch key set to: " .. v, 2)
        else
            notify("Invalid key: " .. tostring(v), 3)
        end
    end
})

-- =====================================================
-- LAGSWITCH SECTION (Movement Tab - Right)
-- =====================================================
local MovLS = MovTab:CreateSection({ Name = "Lagswitch", Side = "Right" })

MovLS:CreateToggle({
    Name = "Enable Lagswitch",
    Default = false,
    Callback = function(v)
        LagswitchEnabled = v
        if v then
            notify("Lagswitch enabled. Press [" .. LagswitchKey.Name .. "] to freeze.", 3)
        else
            notify("Lagswitch disabled.", 2)
        end
    end
})
MovLS:CreateTextbox({
    Name = "Freeze Duration (seconds)",
    Placeholder = "3",
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            LagswitchFreezeDuration = n
            notify("Lagswitch freeze duration set to: " .. tostring(n) .. "s", 2)
        else
            notify("Enter a valid positive number.", 3)
        end
    end
})
MovLS:CreateKeybind({
    Name = "Activate Keybind",
    Default = "E",
    Callback = function(v)
        lagswitchListening = false
        local key = Enum.KeyCode[v]
        if key then
            LagswitchKey = key
            notify("Lagswitch key set to: " .. v, 2)
        else
            notify("Invalid key: " .. tostring(v), 3)
        end
    end
})

-- Auto Bench Section (Movement Tab - Right)
local MovBench = MovTab:CreateSection({ Name = "Auto Bench", Side = "Right" })

MovBench:CreateToggle({
    Name = "Enable Auto Bench",
    Default = false,
    Callback = function(v)
        autoBenchEnabled = v
        if v then
            enableAutoBench()
            notify("Auto Bench enabled.", 2)
        else
            disableAutoBench()
            notify("Auto Bench disabled.", 2)
        end
    end
})
MovBench:CreateTextbox({
    Name = "Bounce Height 1",
    Placeholder = "100",
    Callback = function(v)
        local n = tonumber(v)
        if n then autoBenchHeights[1] = n; notify("Bounce Height 1 set to: "..tostring(n), 2)
        else notify("Enter a valid number.", 3) end
    end
})
MovBench:CreateTextbox({
    Name = "Bounce Height 2",
    Placeholder = "70",
    Callback = function(v)
        local n = tonumber(v)
        if n then autoBenchHeights[2] = n; notify("Bounce Height 2 set to: "..tostring(n), 2)
        else notify("Enter a valid number.", 3) end
    end
})
MovBench:CreateTextbox({
    Name = "Bounce Height 3",
    Placeholder = "80",
    Callback = function(v)
        local n = tonumber(v)
        if n then autoBenchHeights[3] = n; notify("Bounce Height 3 set to: "..tostring(n), 2)
        else notify("Enter a valid number.", 3) end
    end
})
MovBench:CreateTextbox({
    Name = "Bounce Height 4",
    Placeholder = "90",
    Callback = function(v)
        local n = tonumber(v)
        if n then autoBenchHeights[4] = n; notify("Bounce Height 4 set to: "..tostring(n), 2)
        else notify("Enter a valid number.", 3) end
    end
})

-- =====================================================
-- VISUALS TAB
-- =====================================================

-- =====================================================

local FOVBodyVisibility = {
    Enabled = false,
    Connection = nil,
    ArmParts = {
        ["Left Arm"] = true,
        ["Right Arm"] = true,
        ["LeftUpperArm"] = true,
        ["LeftLowerArm"] = true,
        ["LeftHand"] = true,
        ["RightUpperArm"] = true,
        ["RightLowerArm"] = true,
        ["RightHand"] = true
    },
    LowerBodyParts = {
        ["Left Leg"] = true,
        ["Right Leg"] = true,
        ["LeftUpperLeg"] = true,
        ["LeftLowerLeg"] = true,
        ["LeftFoot"] = true,
        ["RightUpperLeg"] = true,
        ["RightLowerLeg"] = true,
        ["RightFoot"] = true,
        ["Torso"] = true,
        ["LowerTorso"] = true
    }
}

-- Keywords that identify the sprint-forward or jump animations
local SPRINT_ANIM_KEYWORDS = {"sprint", "run", "forward", "sprintforward"}
local JUMP_ANIM_KEYWORDS   = {"jump", "leap", "aerial"}

local function animNameMatches(animTrack, keywords)
    local name = animTrack.Name and animTrack.Name:lower() or ""
    local animId = ""
    pcall(function()
        animId = animTrack.Animation and animTrack.Animation.AnimationId:lower() or ""
    end)
    for _, kw in ipairs(keywords) do
        if name:find(kw, 1, true) or animId:find(kw, 1, true) then
            return true
        end
    end
    return false
end

-- Also check exact animation names the game uses (case-insensitive)
local EXACT_HIDE_ANIM_NAMES = {
    ["sprintforward"] = true,
    ["sprint_forward"] = true,
    ["sprint"] = true,
    ["jump"] = true,
    ["jumpforward"] = true,
}

local function isSprintOrJumpAnimPlaying()
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end

    -- Humanoid state fallback for jump/freefall
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall then
        return true
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.IsPlaying then
            -- Exact name match (covers SprintForward, Jump, etc.)
            local lowerName = track.Name and track.Name:lower() or ""
            if EXACT_HIDE_ANIM_NAMES[lowerName] then return true end
            -- Keyword match as fallback
            if animNameMatches(track, SPRINT_ANIM_KEYWORDS) then return true end
            if animNameMatches(track, JUMP_ANIM_KEYWORDS)   then return true end
        end
    end
    return false
end

function FOVBodyVisibility.GetRig()
    local rigsFolder = Workspace:FindFirstChild("Rigs")
    if not rigsFolder then return nil end
    return rigsFolder:FindFirstChild(LocalPlayer.Name)
        or rigsFolder:FindFirstChild("hfurhutu")
end

function FOVBodyVisibility.Restore()
    local myRig = FOVBodyVisibility.GetRig()
    if not myRig then return end
    for _, part in ipairs(myRig:GetChildren()) do
        if part:IsA("BasePart") and (FOVBodyVisibility.ArmParts[part.Name] or FOVBodyVisibility.LowerBodyParts[part.Name]) then
            part.LocalTransparencyModifier = 0
        end
    end
end

function FOVBodyVisibility.Enable()
    FOVBodyVisibility.Disable()
    FOVBodyVisibility.Enabled = true
    FOVBodyVisibility.Connection = RunService.RenderStepped:Connect(function()
        if not FOVBodyVisibility.Enabled then return end

        local currentCamera = Workspace.CurrentCamera or camera
        if not currentCamera then return end
        local myRig = FOVBodyVisibility.GetRig()
        if not myRig then return end

        -- Only activate when in first-person (FOV > 90 or camera locked)
        local isFirstPerson = currentCamera.FieldOfView > 90
            or LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson
        if not isFirstPerson then
            -- Restore if we left first-person
            for _, part in ipairs(myRig:GetChildren()) do
                if part:IsA("BasePart") and (FOVBodyVisibility.ArmParts[part.Name] or FOVBodyVisibility.LowerBodyParts[part.Name]) then
                    part.LocalTransparencyModifier = 0
                end
            end
            return
        end

        local hideArms = isSprintOrJumpAnimPlaying()

        for _, part in ipairs(myRig:GetChildren()) do
            if part:IsA("BasePart") then
                if FOVBodyVisibility.ArmParts[part.Name] then
                    -- Hide arms during sprint-forward or jump animations
                    part.LocalTransparencyModifier = hideArms and 1 or part.Transparency
                elseif FOVBodyVisibility.LowerBodyParts[part.Name] then
                    part.LocalTransparencyModifier = part.Transparency
                end
            end
        end
    end)
end

function FOVBodyVisibility.Disable()
    FOVBodyVisibility.Enabled = false
    if FOVBodyVisibility.Connection then
        FOVBodyVisibility.Connection:Disconnect()
        FOVBodyVisibility.Connection = nil
    end
    FOVBodyVisibility.Restore()
end

VisTab:CreateSection({ Name = "First-Person Body", Side = "Left" }):CreateToggle({
    Name = "FOV Body Visibility",
    Default = false,
    Callback = function(v)
        FOVBodyVisibility.Enabled = v
        if v then
            FOVBodyVisibility.Enable()
            notify("FOV Body Visibility enabled.", 2)
        else
            FOVBodyVisibility.Disable()
            notify("FOV Body Visibility disabled.", 2)
        end
    end
})

local VisLeft = VisTab:CreateSection({ Name = "Avatar", Side = "Left" })

VisLeft:CreateToggle({ Name = "Headless", Default = false,
    Callback = function(v)
        Settings.HeadlessEnabled = v
        if LocalPlayer.Character then
            if v then applyAvatarCosmeticsWithRetries(LocalPlayer.Character)
            else pcall(function() removeHeadless(LocalPlayer.Character) end) end
        end
    end
})
VisLeft:CreateToggle({ Name = "Korblox Right Leg", Default = false,
    Callback = function(v)
        Settings.KorbloxEnabled = v
        if LocalPlayer.Character then
            if v then applyAvatarCosmeticsWithRetries(LocalPlayer.Character)
            else pcall(function() removeKorblox(LocalPlayer.Character) end) end
        end
    end
})

local VisCosmetics = VisTab:CreateSection({ Name = "Cosmetics", Side = "Left" })

VisCosmetics:CreateToggle({
    Name = "Auto-Apply Cosmetic Style", Default = false,
    Colorpicker = true, ColorDefault = WINE_CONFIG.TrueWine, AlphaDefault = 1,
    ColorCallback = function(c) WINE_CONFIG.TrueWine = c; rebuildDeepWineSequence() end,
    Callback = function(v) Settings.AutoApplyCosmetic = v end
})
VisCosmetics:CreateButton({ Name = "Apply Cosmetic Style Now",
    Callback = function()
        pcall(function() if LocalPlayer.Character then applyDeepWineLogic(LocalPlayer.Character) end end)
        notify("Cosmetic style applied.", 3)
    end
})

-- Format: ["OwnedCosmetic"] = "WantedCosmetic"
local COSMETIC_CONFIG = {
    ["PureLove"] = "ToxicInferno",
}

local originalCosmeticContents = {}

local function replaceCosmeticContents(targetName, sourceName)
    local target = ReplicatedStorage:FindFirstChild(targetName, true)
    local source = ReplicatedStorage:FindFirstChild(sourceName, true)

    if not target then
        warn("[Cosmetic Swap Failed] Target item '" .. targetName .. "' was not found in ReplicatedStorage.")
        return false
    end

    if not source then
        warn("[Cosmetic Swap Failed] Source item '" .. sourceName .. "' was not found in ReplicatedStorage.")
        return false
    end

    if originalCosmeticContents[target] == nil then
        originalCosmeticContents[target] = cloneChildren(target)
    end

    clearChildren(target)
    local sourceChildren = source:GetChildren()

    if #sourceChildren > 0 then
        for _, child in ipairs(sourceChildren) do
            local clone = child:Clone()
            clone.Parent = target
        end
        print("[Cosmetic Swap Success] Loaded '" .. sourceName .. "' contents into '" .. targetName .. "'.")
    else
        local clone = source:Clone()
        clone.Parent = target
        print("[Cosmetic Swap Success] Cloned standalone '" .. sourceName .. "' directly into '" .. targetName .. "'.")
    end

    return true
end

local function revertCosmeticContents(targetName)
    local target = ReplicatedStorage:FindFirstChild(targetName, true)
    if not target then
        warn("[Cosmetic Revert Failed] Target item '" .. targetName .. "' was not found in ReplicatedStorage.")
        return false
    end

    local originalContents = originalCosmeticContents[target]
    if originalContents == nil then
        return false
    end

    restoreChildren(target, originalContents)
    originalCosmeticContents[target] = nil
    print("[Cosmetic Revert Success] Restored original contents of '" .. targetName .. "'.")
    return true
end

local cosSwapOwned = ""
local cosSwapWanted = ""
VisCosmetics:CreateTextbox({ Name = "Owned Cosmetic", Placeholder = "PureLove",
    Callback = function(v) cosSwapOwned = v end })
VisCosmetics:CreateTextbox({ Name = "Wanted Cosmetic", Placeholder = "ToxicInferno",
    Callback = function(v) cosSwapWanted = v end })
VisCosmetics:CreateButton({ Name = "Apply Cosmetic Swap",
    Callback = function()
        if cosSwapOwned ~= "" and cosSwapWanted ~= "" then
            if replaceCosmeticContents(cosSwapOwned, cosSwapWanted) then
                notify("Cosmetic swap applied.", 3)
            else
                notify("Cosmetic not found.", 3)
            end
        else
            notify("Enter both cosmetic names.", 3)
        end
    end
})
VisCosmetics:CreateButton({ Name = "Revert to Original",
    Callback = function()
        if cosSwapOwned ~= "" then
            if revertCosmeticContents(cosSwapOwned) then
                notify("Cosmetic swap reverted.", 3)
            else
                notify("Nothing to revert for this cosmetic.", 3)
            end
        else
            notify("Enter the owned cosmetic name.", 3)
        end
    end
})

local VisLeft2 = VisTab:CreateSection({ Name = "Camera", Side = "Left" })

-- =====================================================
-- VISUALS TAB
-- =====================================================

VisLeft2:CreateToggle({ Name = "FOV Lock", Default = false,
    Callback = function(v) Settings.FOVEnabled = v; enforceFOV() end })
VisLeft2:CreateSlider({ Name = "FOV Value", Min = 70, Max = 120, Default = 93,
    Callback = function(v) Settings.FOV = v; enforceFOV() end })

-- Saturation Section (Visuals Tab - Left)
local VisSaturation = VisTab:CreateSection({ Name = "Saturation", Side = "Left" })

VisSaturation:CreateToggle({
    Name = "Enable Saturation",
    Default = false,
    Callback = function(v)
        saturationEnabled = v
        getColorCorrection()
        notify(v and "Saturation enabled." or "Saturation disabled.", 2)
    end
})
VisSaturation:CreateTextbox({
    Name = "Saturation Value",
    Placeholder = "-100 to 100 (default 0)",
    Callback = function(v)
        local n = tonumber(v)
        if n then
            saturationValue = math.clamp(n, -100, 100)
            if saturationEnabled then getColorCorrection() end
            notify("Saturation set to: " .. tostring(saturationValue), 2)
        else
            notify("Enter a valid number (-100 to 100).", 3)
        end
    end
})

local VisRight = VisTab:CreateSection({ Name = "Emote Swapper", Side = "Right" })

for i = 1, 6 do
    local idx = i
    VisRight:CreateTextbox({ Name = "Owned Emote "..idx, Placeholder = "Owned emote name",
        Callback = function(v) EmoteSwapper.CurrentEmotes[idx] = v:gsub("%s+","") end })
    VisRight:CreateTextbox({ Name = "Wanted Emote "..idx, Placeholder = "Wanted emote name",
        Callback = function(v) EmoteSwapper.SelectedEmotes[idx] = v:gsub("%s+","") end })
end

VisRight:CreateButton({
    Name = "Apply Emote Swapper",
    Callback = function()
        local swapped, failed = 0, 0
        for i = 1, 6 do
            local cur = EmoteSwapper.CurrentEmotes[i]
            local sel = EmoteSwapper.SelectedEmotes[i]
            if cur ~= "" and sel ~= "" then
                if replaceEmoteContents(cur, sel) then
                    swapped = swapped + 1
                else
                    failed = failed + 1
                end
            end
        end
        local msg = ""
        if swapped == 0 and failed == 0 then msg = "No emotes specified" end
        if failed > 0 then msg = msg..(msg~="" and " | " or "").."Failed: "..failed end
        if swapped > 0 then msg = msg..(msg~="" and " | " or "").."Swapped: "..swapped end
        notify(msg, 5)
    end
})
VisRight:CreateButton({
    Name = "Revert to Original",
    Callback = function()
        local reverted, failed = 0, 0
        local processedTargets = {}
        for i = 1, 6 do
            local cur = EmoteSwapper.CurrentEmotes[i]
            if cur ~= "" and not processedTargets[cur] then
                processedTargets[cur] = true
                if revertEmoteContents(cur) then
                    reverted = reverted + 1
                else
                    failed = failed + 1
                end
            end
        end
        local msg = ""
        if reverted == 0 and failed == 0 then msg = "No emotes specified" end
        if failed > 0 then msg = msg..(msg~="" and " | " or "").."Nothing to revert: "..failed end
        if reverted > 0 then msg = msg..(msg~="" and " | " or "").."Reverted: "..reverted end
        notify(msg, 5)
    end
})
VisRight:CreateToggle({ Name = "Auto-Apply on Respawn", Default = false,
    Callback = function(v) Settings.AutoApplyDraconicEmoteSwapper = v end })

-- =====================================================
-- WORLD TAB
-- =====================================================

local WorldLeft = WorldTab:CreateSection({ Name = "World Visuals", Side = "Left" })

WorldLeft:CreateToggle({ Name = "Sunset Shader", Default = false,
    Callback = function(v)
        sunsetShaderEnabled = v; applySunsetShader()
        notify(v and "Sunset Shader enabled." or "Sunset Shader disabled.", 2)
    end
})

WorldLeft:CreateToggle({
    Name = "Global Color", Default = false,
    Colorpicker = true, ColorDefault = globalColor, AlphaDefault = 1,
    ColorCallback = function(c)
        globalColor = c
        if globalColorEnabled then applyGlobalColor() end
    end,
    Callback = function(v)
        globalColorEnabled = v
        if v then
            if next(originalColors) == nil then storeOriginalColors() end
            applyGlobalColor(); notify("Global Color applied.", 2)
        else
            restoreOriginalColors(); notify("Global Color restored.", 2)
        end
    end
})
WorldLeft:CreateToggle({ Name = "Auto-Apply Global Color", Default = false,
    Callback = function(v) Settings.AutoApplyGlobalColor = v end })

WorldLeft:CreateToggle({
    Name = "Sky Color", Default = false,
    Colorpicker = true, ColorDefault = skyColor, AlphaDefault = 1,
    ColorCallback = function(c) skyColor = c; if skyColorEnabled then applySkyColor() end end,
    Callback = function(v)
        skyColorEnabled = v; applySkyColor()
        notify(v and "Sky Color enabled." or "Sky Color disabled.", 2)
    end
})
WorldLeft:CreateToggle({ Name = "Auto-Apply Sky Color", Default = false,
    Callback = function(v) Settings.AutoApplySkyColor = v end })

WorldLeft:CreateToggle({
    Name = "Perfect Fog", Default = false,
    Colorpicker = true, ColorDefault = perfectFogColor, AlphaDefault = 1,
    ColorCallback = function(c) perfectFogColor = c; if perfectFogEnabled then applyPerfectFog() end end,
    Callback = function(v)
        perfectFogEnabled = v; applyPerfectFog()
        notify(v and "Perfect Fog enabled." or "Perfect Fog disabled.", 2)
    end
})
WorldLeft:CreateToggle({ Name = "Auto-Apply Perfect Fog", Default = false,
    Callback = function(v) Settings.AutoApplyPerfectFog = v end })

local WorldRight = WorldTab:CreateSection({ Name = "Hitbox Creator", Side = "Right" })

WorldRight:CreateToggle({
    Name = "Enable Hitbox Creator", Default = false,
    Callback = function(v)
        hitboxCreatorEnabled = v
        if v then enableHitboxSelection(); notify("Hitbox Creator enabled. Click to place.", 2)
        else disableHitboxSelection(); notify("Hitbox Creator disabled.", 2) end
    end
})
WorldRight:CreateSlider({ Name = "Size X", Min = 1, Max = 50, Default = 5,
    Callback = function(v) hitboxSizeX = v; applyHitboxPropertiesToSelected(true) end })
WorldRight:CreateSlider({ Name = "Size Y", Min = 1, Max = 50, Default = 5,
    Callback = function(v) hitboxSizeY = v; applyHitboxPropertiesToSelected(true) end })
WorldRight:CreateSlider({ Name = "Size Z", Min = 1, Max = 50, Default = 5,
    Callback = function(v) hitboxSizeZ = v; applyHitboxPropertiesToSelected(true) end })
WorldRight:CreateSlider({ Name = "Transparency (x10)", Min = 0, Max = 10, Default = 9,
    Callback = function(v) hitboxTransparency = v / 10; applyHitboxPropertiesToSelected(true) end })
WorldRight:CreateToggle({ Name = "CanCollide", Default = true,
    Callback = function(v) hitboxCanCollide = v; applyHitboxPropertiesToSelected(true) end })
WorldRight:CreateButton({ Name = "Select Last Hitbox",
    Callback = function()
        if selectLastHitbox() then notify("Selected hitbox.", 2)
        else notify("No hitbox available.", 2) end
    end
})
WorldRight:CreateButton({ Name = "Delete Selected Hitbox",
    Callback = function() removeSelectedHitbox() end })
WorldRight:CreateButton({ Name = "Remove All Hitboxes",
    Callback = function() removeAllHitboxes(); notify("All hitboxes removed.", 2) end })

local skyboxAssetID = ""
WorldRight:CreateTextbox({ Name = "Asset ID (Skybox/Model)", Placeholder = "Asset ID...",
    Callback = function(v) skyboxAssetID = v end })
WorldRight:CreateButton({ Name = "Apply Asset",
    Callback = function()
        local assetId = stripAssetPrefix(skyboxAssetID)
        if assetId == "" then assetId = "116402178504134" end
        local lighting = game:GetService("Lighting")
        for _, obj in ipairs(lighting:GetChildren()) do if obj:IsA("Sky") then obj:Destroy() end end
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://"..assetId) end)
        if ok and objs and objs[1] then objs[1].Parent = lighting; notify("Asset applied!", 3)
        else notify("Failed to load asset.", 3) end
    end
})

-- =====================================================
-- TAS TAB
-- =====================================================

local TASLeft = TASTab:CreateSection({ Name = "TAS Controls", Side = "Left" })

TASLeft:CreateButton({ Name = "Start Recording [F1]", Callback = function() task.spawn(StartRecord) end })
TASLeft:CreateButton({ Name = "Stop Recording [F2]",  Callback = function() StopRecord() end })
TASLeft:CreateButton({ Name = "Play TAS [F3]",        Callback = function() task.spawn(PlayTAS) end })
TASLeft:CreateButton({ Name = "Clear Frames [F4]",    Callback = function() ClearFrames() end })

local TASRight = TASTab:CreateSection({ Name = "Keybinds", Side = "Right" })
TASRight:CreateKeybind({ Name = "Start Record Key", Default = "F1",
    Callback = function(v) Keybinds.StartRecord = v end })
TASRight:CreateKeybind({ Name = "Stop Record Key",  Default = "F2",
    Callback = function(v) Keybinds.StopRecord  = v end })
TASRight:CreateKeybind({ Name = "Play TAS Key",     Default = "F3",
    Callback = function(v) Keybinds.PlayTAS     = v end })
TASRight:CreateKeybind({ Name = "Clear Frames Key", Default = "F4",
    Callback = function(v) Keybinds.ClearFrames = v end })

-- =====================================================
-- MAPS TAB
-- =====================================================

local MapsLeft = MapsTab:CreateSection({ Name = "Map Loader", Side = "Left" })

local mapAssetIDValue = "140292990874803"
MapsLeft:CreateTextbox({ Name = "Map Asset ID", Placeholder = "140292990874803",
    Callback = function(v) if v ~= "" then mapAssetIDValue = v end end })
MapsLeft:CreateSlider({ Name = "Scale Factor (/10)", Min = 5, Max = 20, Default = 10,
    Callback = function(v) Settings.MapScale = v / 10 end })
MapsLeft:CreateSlider({ Name = "Spawn Height (/100)", Min = 5, Max = 30, Default = 15,
    Callback = function(v) Settings.SpawnHeight = v * 100 end })
MapsLeft:CreateButton({ Name = "Load Map",
    Callback = function() loadMapByAssetId(mapAssetIDValue) end })

local MapsRight = MapsTab:CreateSection({ Name = "Custom Maps", Side = "Right" })
for _, mapData in ipairs(CustomMaps) do
    local md = mapData
    MapsRight:CreateButton({ Name = "Load "..md.Name,
        Callback = function() loadCustomMap(md) end })
end

-- =====================================================
-- MISC TAB
-- =====================================================

local MiscLeft = MiscTab:CreateSection({ Name = "Emote Actions", Side = "Left" })

MiscLeft:CreateToggle({ Name = "360 Emote Hop (A + D)", Default = false,
    Callback = function(v) Settings.SpinEnabled = v end })
MiscLeft:CreateToggle({ Name = "Emote Spin", Default = false,
    Callback = function(v) Settings.TurnEnabled = v end })
MiscLeft:CreateSlider({ Name = "Turn Speed (/100)", Min = 1, Max = 30, Default = 5,
    Callback = function(v) Settings.TurnSpeed = math.max(v / 100, 0.001) end })
MiscLeft:CreateToggle({
    Name = "Nonmovable Emote Hop", Default = false,
    Callback = function(v)
        NonMovableEmoteHopEnabled = v
        if v then
            local n = 0; pcall(function() n = applyNonMovableEmoteHop() end)
            notify("Nonmovable Emote Hop enabled. Fixed: "..n, 3)
        else
            pcall(restoreNonMovableEmoteHop)
            notify("Nonmovable Emote Hop disabled.", 2)
        end
    end
})
MiscLeft:CreateToggle({ Name = "Keyboard Sound Effect", Default = false,
    Callback = function(v) Settings.keyboardSoundEnabled = v end })

local MiscRight = MiscTab:CreateSection({ Name = "Advanced", Side = "Right" })

MiscRight:CreateToggle({ Name = "FFlag MaxMissedWorldSteps", Default = false,
    Callback = function(v) Settings.FFlagEnabled = v end })
MiscRight:CreateButton({ Name = "Death Aura",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet('https://gist.githubusercontent.com/sn3514ube16-droid/b5442e8370075defde08c398da3f571d/raw/c6b0a3d8a6ff2a26ee76eeb2fbab58c8684e3d1b/DeathAuraNeon.lua'))()
        end)
        notify("Death Aura executed.", 3)
    end
})

-- =====================================================
-- SETTINGS TAB
-- =====================================================

Window:CreateCategory("Settings")
local SettingsTab = Window:CreateTab("Settings", "14219516560")
local SettingsLeft = SettingsTab:CreateSection({ Name = "Interface", Side = "Left" })

SettingsLeft:CreateTextbox({
    Name = "UI Toggle Key",
    Placeholder = "RightAlt",
    Callback = function(v)
        v = v:gsub("%s+", "")
        if v == "" then return end
        local key = Enum.KeyCode[v]
        if key then
            Window.toggleKeyState.key = key
            notify("UI toggle key set to: " .. v, 3)
        else
            notify("Invalid key name: " .. v, 3)
        end
    end
})

SettingsLeft:CreateButton({
    Name = "Reset to Default (RightAlt)",
    Callback = function()
        Window.toggleKeyState.key = Enum.KeyCode.RightAlt
        notify("UI toggle key reset to RightAlt.", 3)
    end
})

notify('Kamiware V3 loaded successfully.', 4)

end

buildUI()
