-- =====================================================
-- KAMIBLOX / LOCALMAZE UI LIBRARY
-- =====================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Library = {}
local Utility = {}

local Theme = {
    MainBg = Color3.fromRGB(11, 11, 11),
    TabFrameBg = Color3.fromRGB(16, 16, 16),
    SectionBg = Color3.fromRGB(19, 19, 19),
    TabButton = Color3.fromRGB(30, 30, 30),
    TabButtonActive = Color3.fromRGB(44, 44, 44),
    TextMain = Color3.fromRGB(255, 255, 255),
    TextCategory = Color3.fromRGB(77, 77, 77),
    ToggleActive = Color3.fromRGB(255, 127, 211),
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
    local dragging, dragStart, startPos

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

    local toggleKey = options.ToggleKey or Enum.KeyCode.Equals
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    local success = pcall(function() ScreenGui.Parent = CoreGui end)
    if not success then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    -- Popup System
    local PopupBg = Utility:Create("TextButton", {
        Name = "PopupBg", Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 100, Visible = false, Text = "", AutoButtonColor = false
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
        Name = "PopupFrame", Parent = PopupBg, BackgroundColor3 = Theme.MainBg, BorderSizePixel = 0, Size = UDim2.new(0, 220, 0, 280), ZIndex = 101
    })
    Utility:Create("UICorner", { Parent = PopupFrame, CornerRadius = UDim.new(0, 8) })

    local PopupTitle = Utility:Create("TextLabel", {
        Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 16),
        Font = Theme.Font, Text = "Settings", TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
    })

    local PopupContent = Utility:Create("Frame", {
        Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -20, 1, -42), ZIndex = 102
    })
    local PopupLayout = Utility:Create("UIListLayout", { Parent = PopupContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
    PopupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
        PopupFrame.Size = UDim2.new(0, 220, 0, PopupLayout.AbsoluteContentSize.Y + 42)
    end)

    local function OpenModal(title, setupFunc, sourceElement)
        PopupTitle.Text = title
        for _, conn in ipairs(PopupConnections) do if conn.Disconnect then conn:Disconnect() end end
        table.clear(PopupConnections)

        for _, child in pairs(PopupContent:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        setupFunc(PopupContent)
        
        if sourceElement then
            local absPos, absSize = sourceElement.AbsolutePosition, sourceElement.AbsoluteSize
            local screenX, screenY = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
            local targetX, targetY = absPos.X + absSize.X + 10, absPos.Y
            
            if targetX + 220 > screenX then targetX = absPos.X - 220 - 10 end
            if targetY + PopupFrame.AbsoluteSize.Y > screenY then targetY = screenY - PopupFrame.AbsoluteSize.Y - 10 end
            
            PopupFrame.Position = UDim2.new(0, targetX, 0, targetY)
        else
            PopupFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
        end
        PopupBg.Visible = true
    end

    local AccentUpdates = {}
    local function ApplyAccent()
        for _, func in ipairs(AccentUpdates) do func(Theme.ToggleActive) end
    end
    
    local function OpenColorPicker(title, defaultColor, defaultAlpha, callback, sourceElement)
        OpenModal(title, function(container)
            local currentColor = defaultColor or Color3.new(1, 1, 1)
            local currentAlpha = defaultAlpha or 1
            local colorCb = callback or function() end
            local h, s, v = currentColor:ToHSV()

            local ColorContainer = Utility:Create("Frame", { Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 120), ZIndex = 102 })
            
            local SVMap = Utility:Create("TextButton", { Parent = ColorContainer, BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, -40, 1, 0), Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 102 })
            Utility:Create("UICorner", { Parent = SVMap, CornerRadius = UDim.new(0, 4) })
            local SatOverlay = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 0, 1, 0), ZIndex = 103 })
            Utility:Create("UIGradient", { Parent = SatOverlay, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}) })
            local ValOverlay = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1, 0, 1, 0), ZIndex = 104 })
            Utility:Create("UIGradient", { Parent = ValOverlay, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90 })
            local PickerRing = Utility:Create("Frame", { Parent = SVMap, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0, 6, 0, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1-v, 0), ZIndex = 105 })
            Utility:Create("UICorner", { Parent = PickerRing, CornerRadius = UDim.new(1, 0) })
            Utility:Create("UIStroke", { Parent = PickerRing, Color = Color3.new(0,0,0) })

            local HueBar = Utility:Create("TextButton", { Parent = ColorContainer, Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0, 16, 1, 0), BackgroundColor3 = Color3.new(1,1,1), Text = "", AutoButtonColor = false, ZIndex = 102 })
            Utility:Create("UICorner", { Parent = HueBar, CornerRadius = UDim.new(0, 4) })
            local HueGradient = Utility:Create("UIGradient", { Parent = HueBar, Rotation = 90 })
            HueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
            local HueRing = Utility:Create("Frame", { Parent = HueBar, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 2, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, h, 0), ZIndex = 106 })
            Utility:Create("UIStroke", { Parent = HueRing, Color = Color3.new(0,0,0) })

            local BottomContainer = Utility:Create("Frame", { Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 102 })
            local PreviewBox = Utility:Create("Frame", { Parent = BottomContainer, BackgroundColor3 = currentColor, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 102 })
            Utility:Create("UICorner", { Parent = PreviewBox, CornerRadius = UDim.new(0, 4) })

            local draggingSV, draggingHue = false, false
            local function updateColor()
                currentColor = Color3.fromHSV(h, s, v)
                PreviewBox.BackgroundColor3 = currentColor
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

            SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true; updateSV(input) end end)
            HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true; updateHue(input) end end)
            
            local c1 = UserInputService.InputEnded:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV, draggingHue = false, false end 
            end)
            local c2 = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if draggingSV then updateSV(input) end
                    if draggingHue then updateHue(input) end
                end
            end)
            table.insert(PopupConnections, c1); table.insert(PopupConnections, c2)
        end, sourceElement)
    end

    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame", Parent = ScreenGui, BackgroundColor3 = Theme.MainBg, BorderSizePixel = 0, Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2), Size = windowSize, Active = true
    })
    Utility:Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 8) })
    Utility:MakeDraggable(MainFrame, MainFrame)

    local TabFrame = Utility:Create("Frame", {
        Name = "tabframe", Parent = MainFrame, BackgroundColor3 = Theme.TabFrameBg, BorderSizePixel = 0, Size = UDim2.new(0, 216, 1, 0)
    })
    Utility:Create("UICorner", { Parent = TabFrame, CornerRadius = UDim.new(0, 8) })

    local TabButtonContainer = Utility:Create("Frame", {
        Name = "TabButtonContainer", Parent = TabFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 1, -50)
    })

    local AccentFrame = Utility:Create("Frame", {
        Name = "AccentFrame", Parent = TabFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 1, -30), Size = UDim2.new(1, -20, 0, 20)
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
            Theme.ToggleActive = col; AccentPickerBtn.BackgroundColor3 = col; ApplyAccent()
        end, AccentPickerBtn)
    end)
    Utility:Create("UIListLayout", {
        Parent = TabButtonContainer, SortOrder = Enum.SortOrder.LayoutOrder
    })

    local PageContainer = Utility:Create("Frame", {
        Name = "PageContainer", Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 226, 0, 10), Size = UDim2.new(1, -236, 1, -20)
    })

    local Window = {}
    local Tabs = {}
    local tabCount = 2

    function Window:CreateCategory(name)
        Utility:Create("TextLabel", {
            Parent = TabButtonContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Theme.Font, Text = "   " .. name, TextColor3 = Theme.TextCategory, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = tabCount
        })
        tabCount = tabCount + 1
    end

    function Window:CreateTab(name, iconId)
        local TabBtn = Utility:Create("TextButton", {
            Name = "TabButton_" .. name, Parent = TabButtonContainer, BackgroundColor3 = Theme.TabFrameBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32), Font = Theme.LabelFont, Text = (iconId and "          " or "   ") .. name, TextColor3 = Color3.fromRGB(130, 130, 130), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = tabCount
        })
        Utility:Create("UICorner", { Parent = TabBtn, CornerRadius = UDim.new(0, 6) })
        tabCount = tabCount + 1

        local TabIcon
        if iconId then
            TabIcon = Utility:Create("ImageLabel", {
                Parent = TabBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Image = "rbxthumb://type=Asset&id=" .. iconId .. "&w=150&h=150", ImageColor3 = Color3.fromRGB(130, 130, 130)
            })
        end

        local Page = Utility:Create("Frame", {
            Name = "Page_" .. name, Parent = PageContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false
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
            local targetCol = (options.Side and options.Side:lower() == "left") and LeftCol or RightCol

            local SectionFrame = Utility:Create("Frame", {
                Name = "Child_" .. secName, Parent = targetCol, BackgroundColor3 = Theme.SectionBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40)
            })
            Utility:Create("UICorner", { Parent = SectionFrame, CornerRadius = UDim.new(0, 6) })

            Utility:Create("TextLabel", {
                Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 5), Size = UDim2.new(1, -24, 0, 20), Font = Theme.LabelFont, Text = secName, TextColor3 = Theme.TextCategory, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
            })

            local ContentContainer = Utility:Create("Frame", { Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30) })
            local SectionLayout = Utility:Create("UIListLayout", { Parent = ContentContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center })
            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SectionFrame.Size = UDim2.new(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 40) end)

            local Elements = {}
            function Elements:CreateToggle(opts)
                opts = opts or {}
                local togText = opts.Name or "Toggle"
                local state = opts.Default or false
                local callback = opts.Callback or function() end

                local ToggleFrame = Utility:Create("Frame", { Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 24) })
                Utility:Create("TextLabel", { Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Font = Theme.LabelFont, Text = togText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local ToggleBox = Utility:Create("TextButton", { Parent = ToggleFrame, BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive, BorderSizePixel = 0, Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Text = "", AutoButtonColor = false })
                Utility:Create("UICorner", { Parent = ToggleBox, CornerRadius = UDim.new(0, 4) })
                
                table.insert(AccentUpdates, function(col) if state then ToggleBox.BackgroundColor3 = col end end)

                local GearBtn = Utility:Create("ImageButton", {
                    Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -26, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Image = "rbxthumb://type=Asset&id=11738672708&w=150&h=150", ImageColor3 = Color3.fromRGB(150, 150, 150), AutoButtonColor = false, Visible = opts.Colorpicker or false
                })
                GearBtn.MouseButton1Click:Connect(function()
                    if opts.Colorpicker then OpenColorPicker(togText .. " Color", opts.ColorDefault, opts.AlphaDefault, opts.ColorCallback, GearBtn) end
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
                local min, max, default = opts.Min or 0, opts.Max or 100, opts.Default or 0
                local callback = opts.Callback or function() end

                local SliderFrame = Utility:Create("Frame", { Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 36) })
                Utility:Create("TextLabel", { Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 16), Font = Theme.LabelFont, Text = slName, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local ValueLabel = Utility:Create("TextLabel", { Parent = SliderFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 40, 0, 16), Font = Theme.Font, Text = tostring(default), TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
                local SliderBack = Utility:Create("Frame", { Parent = SliderFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 6) })
                Utility:Create("UICorner", { Parent = SliderBack, CornerRadius = UDim.new(0, 3) })

                local fillPct = math.clamp((default - min) / (max - min), 0, 1)
                local SliderFill = Utility:Create("Frame", { Parent = SliderBack, BackgroundColor3 = Theme.ToggleActive, BorderSizePixel = 0, Size = UDim2.new(fillPct, 0, 1, 0) })
                Utility:Create("UICorner", { Parent = SliderFill, CornerRadius = UDim.new(0, 3) })
                
                table.insert(AccentUpdates, function(col) SliderFill.BackgroundColor3 = col end)
                local SliderBtn = Utility:Create("TextButton", { Parent = SliderBack, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false })

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
                        moveConn = UserInputService.InputChanged:Connect(function(moveInput) if moveInput.UserInputType == Enum.UserInputType.MouseMovement then update(moveInput) end end)
                        endConn = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false; if moveConn then moveConn:Disconnect() end; if endConn then endConn:Disconnect() end
                            end
                        end)
                    end
                end)
                task.spawn(function() callback(default) end)
            end
            
            function Elements:CreateButton(opts)
                local btnText = opts.Name or "Button"
                local callback = opts.Callback or function() end
                local ButtonFrame = Utility:Create("Frame", { Parent = ContentContainer, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 24) })
                Utility:Create("UICorner", { Parent = ButtonFrame, CornerRadius = UDim.new(0, 6) })
                local Button = Utility:Create("TextButton", { Parent = ButtonFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Theme.Font, Text = btnText, TextColor3 = Theme.TextMain, TextSize = 13 })
                Button.MouseButton1Click:Connect(callback)
            end

            return Elements
        end
        return TabObj
    end
    return Window
end


-- =====================================================
-- MOVEMENT WARE V3 BACKEND SYSTEM (NO UI)
-- =====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

_G.vfxAttachments = _G.vfxAttachments or {}
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() camera = Workspace.CurrentCamera end)

local notificationsEnabled = true
local function notify(text, duration)
    if not notificationsEnabled then return end
    pcall(function() StarterGui:SetCore("SendNotification", {Title = "Movement Ware", Text = tostring(text), Duration = duration or 3}) end)
end

local WINE_CONFIG = {
    TrueWine = Color3.fromRGB(80, 0, 25),
    BlackWine = Color3.fromRGB(30, 0, 10),
    Material = Enum.Material.SmoothPlastic
}

local Settings = {
    FOV = 93, FOVEnabled = false, EdgeEnabled = false, EdgePower = 150, TrimpEnabled = false,
    SpinEnabled = false, TurnEnabled = false, TurnSpeed = 0.05, FFlagEnabled = false,
    KorbloxEnabled = false, HeadlessEnabled = false, PCFlyEnabled = false, MobileFlyEnabled = false,
    InvisWallEnabled = false, CustomSkyID = "rbxassetid://133527242242149", VFXEnabled = false,
    AutoApplyCosmetic = false, AutoApplyGlobalColor = false, AutoApplySkyColor = false, AutoApplyPerfectFog = false,
    AutoApplyDraconicEmoteSwapper = false, MobileEdgeEnabled = false, MapScale = 1.0, SpawnHeight = 1500,
    mommyAsmrEnabled = false, keyboardSoundEnabled = false, NotificationsEnabled = true
}

local deepWineSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, WINE_CONFIG.BlackWine),
    ColorSequenceKeypoint.new(0.2, WINE_CONFIG.TrueWine),
    ColorSequenceKeypoint.new(1, WINE_CONFIG.BlackWine)
})

-- Turnbind System
local TurnbindSettings = {Enabled = false, TurnSpeed = 0.3, LeftKey = Enum.KeyCode.A, RightKey = Enum.KeyCode.D}
local turnbindConns = {}
local function stopTurnbind()
    if turnbindConns.Began then turnbindConns.Began:Disconnect() end
    if turnbindConns.Ended then turnbindConns.Ended:Disconnect() end
    turnbindConns = {}
end
local function startTurnbind()
    stopTurnbind()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    turnbindConns.Began = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not TurnbindSettings.Enabled then return end
        if input.KeyCode == TurnbindSettings.LeftKey then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Left, false, game)
        elseif input.KeyCode == TurnbindSettings.RightKey then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Right, false, game) end
    end)
    turnbindConns.Ended = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == TurnbindSettings.LeftKey then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Left, false, game)
        elseif input.KeyCode == TurnbindSettings.RightKey then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Right, false, game) end
    end)
end

-- Global Color & World
local globalColorEnabled, globalColor, originalColors = false, Color3.fromRGB(255, 255, 255), {}
local function isCharacterPart(obj)
    for _, plr in pairs(Players:GetPlayers()) do if plr.Character and (obj:IsDescendantOf(plr.Character) or obj.Parent == plr.Character) then return true end end
    return false
end
local function storeOriginalColors()
    originalColors = {}
    for _, obj in pairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then originalColors[obj] = obj.Color end end
end
local function applyGlobalColor()
    if not globalColorEnabled then return end
    for _, obj in pairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then pcall(function() obj.Color = globalColor end) end end
end
local function restoreOriginalColors()
    for part, color in pairs(originalColors) do if part and part.Parent then pcall(function() part.Color = color end) end end
    originalColors = {}
end

-- Sky Color
local skyColorEnabled, skyColor, originalAmbient, originalOutdoorAmbient = false, Color3.fromRGB(135, 206, 235), nil, nil
local function applySkyColor()
    if not originalAmbient then originalAmbient = Lighting.Ambient originalOutdoorAmbient = Lighting.OutdoorAmbient end
    if skyColorEnabled then
        Lighting.Ambient = skyColor; Lighting.OutdoorAmbient = skyColor
        local atmosphere = Lighting:FindFirstChild("Atmosphere")
        if atmosphere then atmosphere.Color = skyColor end
    else
        Lighting.Ambient = originalAmbient or Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = originalOutdoorAmbient or Color3.fromRGB(128, 128, 128)
    end
end

-- Perfect Fog
local perfectFogEnabled, perfectFogColor, originalFogSettings = false, Color3.fromRGB(180, 190, 200), nil
local function saveOriginalFogSettings()
    if originalFogSettings then return end
    originalFogSettings = {FogStart=Lighting.FogStart, FogEnd=Lighting.FogEnd, FogColor=Lighting.FogColor, Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, ColorShift_Top=Lighting.ColorShift_Top, ColorShift_Bottom=Lighting.ColorShift_Bottom, GlobalShadows=Lighting.GlobalShadows, ShadowSoftness=Lighting.ShadowSoftness, EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale, EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale}
end
local function removePerfectFogObjects()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj.Name == "PerfectFogSky" then obj:Destroy()
        elseif obj:IsA("Atmosphere") and (obj.Name == "PerfectFogAtmosphere" or obj.Name == "PerfectFogAtm") then obj:Destroy() end
    end
end
local function applyPerfectFog()
    saveOriginalFogSettings()
    if not perfectFogEnabled then
        for k, v in pairs(originalFogSettings) do Lighting[k] = v end
        removePerfectFogObjects()
        return
    end
    Lighting.FogStart = 10; Lighting.FogEnd = math.max(300 / (0.9 * 0.8 + 0.2), 50); Lighting.FogColor = Color3.fromRGB(210, 220, 240); Lighting.Ambient = Color3.fromRGB(111, 111, 111); Lighting.OutdoorAmbient = Color3.fromRGB(111, 111, 111); Lighting.ColorShift_Top = Color3.fromRGB(111, 111, 111); Lighting.ColorShift_Bottom = Color3.fromRGB(111, 111, 111); Lighting.GlobalShadows = true; Lighting.ShadowSoftness = 0.3; Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
    removePerfectFogObjects()
    local sky = Instance.new("Sky", Lighting); sky.Name = "PerfectFogSky"; sky.SkyboxBk = "rbxassetid://252760981"; sky.SkyboxDn = "rbxassetid://252763921"; sky.SkyboxFt = "rbxassetid://252761439"; sky.SkyboxLf = "rbxassetid://252761439"; sky.SkyboxRt = "rbxassetid://252761439"; sky.SkyboxUp = "rbxassetid://252762708"
    local atmosphere = Instance.new("Atmosphere", Lighting); atmosphere.Name = "PerfectFogAtmosphere"; atmosphere.Color = perfectFogColor; atmosphere.Decay = Color3.fromRGB(90, 100, 110); atmosphere.Density = 0.6; atmosphere.Offset = 0.25; atmosphere.Haze = 0.6
end

-- Virtual Strafe
local VirtualStrafeEnabled, VirtualStrafeIntensity, currentSpeed, lastCameraYaw, moveDir = false, 500, 0, 0, Vector3.new(0, 0, 0)
local MAX_SPEED_CAP, ACCEL_RATE, STRAFE_ADD_AMOUNT, TURN_DECEL_FACTOR, LERP_SPEED, BRAKE_FACTOR, IDLE_PERCENT_DECAY, IDLE_LINEAR_DECAY = 500000, 75, 5, 0.85, 0.15, 0.85, 0.992, 35
RunService.Heartbeat:Connect(function(dt)
    if not VirtualStrafeEnabled then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then VirtualStrafeEnabled = false; currentSpeed = 0; return end

    local root = char.HumanoidRootPart
    local isW, isA, isD, isS = UserInputService:IsKeyDown(Enum.KeyCode.W), UserInputService:IsKeyDown(Enum.KeyCode.A), UserInputService:IsKeyDown(Enum.KeyCode.D), UserInputService:IsKeyDown(Enum.KeyCode.S)
    local camForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if camForward.Magnitude <= 0 then return end
    camForward = camForward.Unit

    local directionMatch = moveDir:Dot(camForward)
    if directionMatch < 0.2 and currentSpeed > 100 then currentSpeed = currentSpeed * TURN_DECEL_FACTOR end
    moveDir = moveDir:Lerp(camForward, LERP_SPEED)
    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit else moveDir = camForward end

    local _, camYaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    local yawDelta = camYaw - lastCameraYaw
    if yawDelta > math.pi then yawDelta = yawDelta - (math.pi * 2) end
    if yawDelta < -math.pi then yawDelta = yawDelta + (math.pi * 2) end
    lastCameraYaw = camYaw

    local canStrafe = (isA and yawDelta > 0.0001) or (isD and yawDelta < -0.0001)
    if isS then currentSpeed = currentSpeed * BRAKE_FACTOR
    elseif isW or isA or isD then
        if currentSpeed < VirtualStrafeIntensity then currentSpeed = currentSpeed + (ACCEL_RATE * 3 * dt) end
        if canStrafe and currentSpeed > 50 then currentSpeed = math.min(currentSpeed + STRAFE_ADD_AMOUNT, MAX_SPEED_CAP) else currentSpeed = currentSpeed * 0.999 end
    else
        currentSpeed = (currentSpeed * IDLE_PERCENT_DECAY) - (IDLE_LINEAR_DECAY * dt)
    end
    if currentSpeed < 1 then currentSpeed = 0 end
    if currentSpeed > 0 then
        local targetVelocity = moveDir * (currentSpeed / 45)
        root.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, root.AssemblyLinearVelocity.Y, targetVelocity.Z)
    end
end)
local function resetVirtualStrafe() VirtualStrafeEnabled = false; currentSpeed = 0; moveDir = Vector3.new(0, 0, 0) end

-- Auto Trimp
local AutoTrimpEnabled, TrimpPower, MinSpeed, lastTrimp, cooldown = false, 100, 30, 0, 0.2
RunService.Heartbeat:Connect(function()
    if not AutoTrimpEnabled then return end
    local now = tick()
    if now - lastTrimp < cooldown then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local vel = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    if speed < MinSpeed or vel.Y > 0 then return end
    local raycastResult = workspace:Raycast(hrp.Position, Vector3.new(0, -3, 0))
    if not raycastResult then return end
    lastTrimp = now
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.8, TrimpPower, vel.Z * 0.8)
end)

-- Easy Bounce
local EasyBounceEnabled, EASY_BOUNCE_MAX_HISTORY, EASY_BOUNCE_STEP, EASY_BOUNCE_SPEED_MULT = false, 1000, 1/55, 1.6
local easyBounceLastTime, easyBounceHistory, easyBounceCharacter, easyBounceHrp, easyBounceHumanoid = tick(), {}, nil, nil, nil
local function refreshEasyBounceCharacter(char)
    easyBounceCharacter = char or LocalPlayer.Character; easyBounceHrp = nil; easyBounceHumanoid = nil
    if not easyBounceCharacter then return end
    easyBounceHrp = easyBounceCharacter:FindFirstChild("HumanoidRootPart")
    easyBounceHumanoid = easyBounceCharacter:FindFirstChildOfClass("Humanoid")
    easyBounceLastTime = tick()
end
RunService.Stepped:Connect(function()
    if not EasyBounceEnabled then return end
    if not easyBounceHrp or not easyBounceHrp.Parent or not easyBounceHumanoid or not easyBounceHumanoid.Parent then refreshEasyBounceCharacter(LocalPlayer.Character) return end
    local now = tick()
    local dt = now - easyBounceLastTime; easyBounceLastTime = now
    table.insert(easyBounceHistory, dt)
    if #easyBounceHistory > EASY_BOUNCE_MAX_HISTORY then table.remove(easyBounceHistory, 1) end
    if easyBounceHumanoid:GetState() ~= Enum.HumanoidStateType.Jumping then return end
    local vel = easyBounceHrp.AssemblyLinearVelocity * EASY_BOUNCE_SPEED_MULT
    easyBounceHrp.CFrame = easyBounceHrp.CFrame + vel * dt
end)

-- Air Strafe Extractor
local AirStrafeSpeedEnabled, AirStrafeSpeedValue, AirStrafeAcceleration, AirStrafeJumpHeight = false, 1500, 182, 3
local AirStrafeOriginals = {Tables = {}, Humanoids = {}}
local AirStrafeScanned, AirStrafeApplyDebounce = false, false
local speedProps = {"Speed", "speed", "WalkSpeed", "walkSpeed", "MoveSpeed", "moveSpeed"}
local strafeProps = {"AirStrafeAcceleration", "airStrafeAcceleration", "StrafeAcceleration", "strafeAcceleration", "AirAcceleration", "airAcceleration", "StrafeAccel", "strafeAccel", "AirStrafe", "airStrafe", "StrafeForce", "strafeForce", "AirControl", "airControl", "StrafeControl", "strafeControl"}
local jumpProps = {"JumpHeight", "jumpHeight", "JumpPower", "jumpPower", "JumpForce", "jumpForce", "JumpVelocity", "jumpVelocity"}

local function rememberAirStrafeTableValue(tbl, prop)
    if not AirStrafeOriginals.Tables[tbl] then AirStrafeOriginals.Tables[tbl] = {} end
    if AirStrafeOriginals.Tables[tbl][prop] == nil then AirStrafeOriginals.Tables[tbl][prop] = rawget(tbl, prop) end
end
local function applyToKnownTables()
    for tbl, props in pairs(AirStrafeOriginals.Tables) do
        if type(tbl) == "table" then pcall(function()
            for prop, _ in pairs(props) do
                local isSpeed, isStrafe, isJump = false, false, false
                for _, sp in ipairs(speedProps) do if sp == prop then isSpeed = true break end end
                if not isSpeed then for _, sp in ipairs(strafeProps) do if sp == prop then isStrafe = true break end end end
                if not isSpeed and not isStrafe then for _, sp in ipairs(jumpProps) do if sp == prop then isJump = true break end end end
                if isSpeed then rawset(tbl, prop, AirStrafeSpeedValue) elseif isStrafe then rawset(tbl, prop, AirStrafeAcceleration) elseif isJump then rawset(tbl, prop, AirStrafeJumpHeight) end
            end
        end) end
    end
end
local function applyAirStrafeToHumanoid(humanoid)
    if not AirStrafeOriginals.Humanoids[humanoid] then AirStrafeOriginals.Humanoids[humanoid] = {WalkSpeed = humanoid.WalkSpeed, JumpPower = humanoid.JumpPower, JumpHeight = humanoid.JumpHeight} end
    humanoid.WalkSpeed = AirStrafeSpeedValue / 50
    humanoid.JumpPower = AirStrafeJumpHeight * 30
end
local function updateAirStrafeValues()
    if not AirStrafeSpeedEnabled or AirStrafeApplyDebounce then return end
    AirStrafeApplyDebounce = true
    task.defer(function()
        AirStrafeApplyDebounce = false; if not AirStrafeSpeedEnabled then return end
        applyToKnownTables()
        pcall(function() local char = LocalPlayer.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then applyAirStrafeToHumanoid(hum) end end end)
    end)
end
local function applyAirStrafeModifications()
    if not AirStrafeScanned then
        AirStrafeScanned = true
        pcall(function()
            if type(getgc) ~= "function" then return end
            for _, obj in pairs(getgc(true)) do
                if type(obj) == "table" then
                    for _, prop in pairs(speedProps) do if type(rawget(obj, prop)) == "number" then rememberAirStrafeTableValue(obj, prop) rawset(obj, prop, AirStrafeSpeedValue) end end
                    for _, prop in pairs(strafeProps) do if type(rawget(obj, prop)) == "number" then rememberAirStrafeTableValue(obj, prop) rawset(obj, prop, AirStrafeAcceleration) end end
                end
            end
        end)
    else applyToKnownTables() end
    pcall(function() local char = LocalPlayer.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then applyAirStrafeToHumanoid(hum) end end end)
end
local function restoreAirStrafeModifications()
    for tbl, props in pairs(AirStrafeOriginals.Tables) do if type(tbl) == "table" then for prop, originalValue in pairs(props) do pcall(function() rawset(tbl, prop, originalValue) end) end end end
    for humanoid, saved in pairs(AirStrafeOriginals.Humanoids) do if humanoid and humanoid.Parent then pcall(function() humanoid.WalkSpeed = saved.WalkSpeed or 16; humanoid.JumpPower = saved.JumpPower or 50 end) end end
    AirStrafeOriginals.Tables = {}; AirStrafeOriginals.Humanoids = {}; AirStrafeScanned = false; notify("Air Strafe Speed disabled", 3)
end

-- Fly Glitch
local subindoQ, descendoCTRL, executando = false, false, true
local function updateFlyVelocity()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = hrp:FindFirstChild("FlyVelocity")
    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        if not bv then bv = Instance.new("BodyVelocity"); bv.Name = "FlyVelocity"; bv.MaxForce = Vector3.new(0,0,0); bv.Velocity = Vector3.new(0,0,0); bv.Parent = hrp end
        executando = true
    else
        if bv then bv:Destroy() end
        executando = false; subindoQ = false; descendoCTRL = false
    end
end
local crouchConnections = {}
local function clearCrouchConnections() for _, conn in ipairs(crouchConnections) do pcall(function() conn:Disconnect() end) end crouchConnections = {} end
local function startCrouchDetect()
    clearCrouchConnections()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local baseHipHeight, baseWalkSpeed = hum.HipHeight, hum.WalkSpeed
    table.insert(crouchConnections, hum:GetPropertyChangedSignal("HipHeight"):Connect(function() if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end if hum.HipHeight < baseHipHeight - 0.05 then descendoCTRL = true else descendoCTRL = false end end))
    table.insert(crouchConnections, hum.StateChanged:Connect(function(_, newState) if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end if newState == Enum.HumanoidStateType.Seated then descendoCTRL = true elseif newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then descendoCTRL = false end end))
end

-- Korblox & Headless
local K_MESH_ID, K_OVERLAY_ID, K_COLOR = 101851696, 101851254, Color3.fromRGB(38, 65, 68)
local function applyKorblox(char)
    if not char or not Settings.KorbloxEnabled then return end
    local rLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("RightUpperLeg")
    if not rLeg then return end
    local rLegMesh = char:FindFirstChild("KorbloxMesh") or Instance.new("CharacterMesh")
    rLegMesh.Name = "KorbloxMesh"; rLegMesh.BodyPart = Enum.BodyPart.RightLeg; rLegMesh.MeshId = K_MESH_ID; rLegMesh.BaseTextureId = 0; rLegMesh.OverlayTextureId = K_OVERLAY_ID; rLegMesh.Parent = char
    for _, v in ipairs(rLeg:GetChildren()) do if v:IsA("SpecialMesh") then v:Destroy() end end
    rLeg.Color = K_COLOR; rLeg.Transparency = 0; rLeg.Material = Enum.Material.Plastic
end
local function removeKorblox(char)
    if not char then return end
    local mesh = char:FindFirstChild("KorbloxMesh")
    if mesh then mesh:Destroy() end
    local rLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("RightUpperLeg")
    if rLeg then rLeg.Color = Color3.fromRGB(163, 162, 165); rLeg.Material = Enum.Material.Plastic; rLeg.Transparency = 0 end
end

local function applyHeadless(char)
    if not char or not Settings.HeadlessEnabled then return end
    local head = char:FindFirstChild("Head")
    if head then head.Transparency = 1 for _, obj in ipairs(head:GetDescendants()) do if obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency = 1 end end end
end
local function removeHeadless(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then head.Transparency = 0 for _, obj in ipairs(head:GetDescendants()) do if obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency = 0 end end end
end

-- Keyboard Sound
local kbSound1, kbSound2 = Instance.new("Sound"), Instance.new("Sound")
kbSound1.SoundId = "rbxassetid://4724428597"; kbSound2.SoundId = "rbxassetid://125027148509088"
local function playKeyboardSound()
    if not Settings.keyboardSoundEnabled then return end
    local s = (math.random(1, 100) <= 50) and kbSound2:Clone() or kbSound1:Clone()
    s.Parent = SoundService; s.PlaybackSpeed = 0.9 + (math.random() * 0.2); s.Volume = 0.9 + (math.random() * 0.3)
    s:Play(); s.Ended:Connect(function() s:Destroy() end)
end
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.UserInputType == Enum.UserInputType.Keyboard then playKeyboardSound() end end)


-- =====================================================
-- UI CREATION & HOOKUPS
-- =====================================================
local MWWindow = Library:CreateWindow({
    Title = "Movement Ware V3",
    Size = UDim2.new(0, 836, 0, 538)
})

-- CATEGORIES
MWWindow:CreateCategory("Movement Ware")
local MainTab = MWWindow:CreateTab("Main", "112728826405675")
local VisualsTab = MWWindow:CreateTab("Visuals", "100065143108986")
local MapsTab = MWWindow:CreateTab("Maps", "8673852020")
local TASTab = MWWindow:CreateTab("TAS", "11802342133")

MWWindow:CreateCategory("Settings")
local ConfigTab = MWWindow:CreateTab("Config", "137254287379933")

-- MAIN TAB (Left)
local MainMovement = MainTab:CreateSection({Name = "Core Movement", Side = "Left"})
MainMovement:CreateToggle({
    Name = "Auto Trimp", Default = Settings.TrimpEnabled,
    Callback = function(v) AutoTrimpEnabled = v end
})
MainMovement:CreateSlider({
    Name = "Trimp Power", Min = 10, Max = 500, Default = 100,
    Callback = function(v) TrimpPower = v end
})
MainMovement:CreateToggle({
    Name = "Easy Bounce", Default = false,
    Callback = function(v) EasyBounceEnabled = v end
})
MainMovement:CreateToggle({
    Name = "Virtual Strafe", Default = false,
    Callback = function(v) VirtualStrafeEnabled = v; if not v then resetVirtualStrafe() end end
})
MainMovement:CreateSlider({
    Name = "Strafe Intensity", Min = 100, Max = 1000, Default = 500,
    Callback = function(v) VirtualStrafeIntensity = v end
})
MainMovement:CreateToggle({
    Name = "Turnbind", Default = TurnbindSettings.Enabled,
    Callback = function(v) TurnbindSettings.Enabled = v; if v then startTurnbind() else stopTurnbind() end end
})

-- MAIN TAB (Right)
local MainExploits = MainTab:CreateSection({Name = "Exploits", Side = "Right"})
MainExploits:CreateToggle({
    Name = "PC Fly Glitch", Default = Settings.PCFlyEnabled,
    Callback = function(v) Settings.PCFlyEnabled = v; updateFlyVelocity(); if v then startCrouchDetect() else clearCrouchConnections() end end
})
MainExploits:CreateToggle({
    Name = "Air Strafe Modification", Default = false,
    Callback = function(v) AirStrafeSpeedEnabled = v; if v then applyAirStrafeModifications() else restoreAirStrafeModifications() end end
})
MainExploits:CreateSlider({
    Name = "Air Strafe Speed Value", Min = 16, Max = 3000, Default = 1500,
    Callback = function(v) AirStrafeSpeedValue = v; updateAirStrafeValues() end
})
MainExploits:CreateSlider({
    Name = "Air Strafe Accel", Min = 50, Max = 500, Default = 182,
    Callback = function(v) AirStrafeAcceleration = v; updateAirStrafeValues() end
})

-- VISUALS TAB (Left)
local VisualsWorld = VisualsTab:CreateSection({Name = "World Editing", Side = "Left"})
VisualsWorld:CreateToggle({
    Name = "Global Color", Default = false, Colorpicker = true, ColorDefault = Color3.fromRGB(255,255,255),
    ColorCallback = function(c) globalColor = c; if globalColorEnabled then applyGlobalColor() end end,
    Callback = function(v) globalColorEnabled = v; if v then storeOriginalColors(); applyGlobalColor() else restoreOriginalColors() end end
})
VisualsWorld:CreateToggle({
    Name = "Sky Color", Default = false, Colorpicker = true, ColorDefault = Color3.fromRGB(135, 206, 235),
    ColorCallback = function(c) skyColor = c; if skyColorEnabled then applySkyColor() end end,
    Callback = function(v) skyColorEnabled = v; applySkyColor() end
})
VisualsWorld:CreateToggle({
    Name = "Perfect Fog", Default = false,
    Callback = function(v) perfectFogEnabled = v; applyPerfectFog() end
})

-- VISUALS TAB (Right)
local VisualsAvatar = VisualsTab:CreateSection({Name = "Avatar", Side = "Right"})
VisualsAvatar:CreateToggle({
    Name = "Korblox", Default = false,
    Callback = function(v) Settings.KorbloxEnabled = v; if v then applyKorblox(LocalPlayer.Character) else removeKorblox(LocalPlayer.Character) end end
})
VisualsAvatar:CreateToggle({
    Name = "Headless", Default = false,
    Callback = function(v) Settings.HeadlessEnabled = v; if v then applyHeadless(LocalPlayer.Character) else removeHeadless(LocalPlayer.Character) end end
})

-- CONFIG TAB
local MiscConfig = ConfigTab:CreateSection({Name = "Miscellaneous", Side = "Left"})
MiscConfig:CreateToggle({
    Name = "Enable Notifications", Default = notificationsEnabled,
    Callback = function(v) notificationsEnabled = v end
})
MiscConfig:CreateToggle({
    Name = "Keyboard Typing Sounds", Default = false,
    Callback = function(v) Settings.keyboardSoundEnabled = v end
})
MiscConfig:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        if #Players:GetPlayers() <= 1 then
            Players.LocalPlayer:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
        end
    end
})