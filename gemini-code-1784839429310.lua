-- =====================================================
-- MOVEMENT WARE V3 + KAMIBLOX UI  (Combined)
-- KamiBlox UI Library replaces Linoria / ndere
-- =====================================================

-- =====================================================
-- KAMIBLOX UI LIBRARY
-- =====================================================

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local StarterGui       = game:GetService("StarterGui")

local Library = {}
local Utility = {}

local Theme = {
    MainBg          = Color3.fromRGB(11, 11, 11),
    TabFrameBg      = Color3.fromRGB(16, 16, 16),
    SectionBg       = Color3.fromRGB(19, 19, 19),
    TabButton       = Color3.fromRGB(30, 30, 30),
    TabButtonActive = Color3.fromRGB(44, 44, 44),
    TextMain        = Color3.fromRGB(255, 255, 255),
    TextCategory    = Color3.fromRGB(77, 77, 77),
    ToggleActive    = Color3.fromRGB(255, 127, 211),
    ToggleInactive  = Color3.fromRGB(44, 44, 44),
    ElementBg       = Color3.fromRGB(30, 30, 30),
    Font            = Enum.Font.ArialBold,
    LabelFont       = Enum.Font.Arial
}

function Utility:Create(class, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do instance[k] = v end
    return instance
end

function Utility:MakeDraggable(topbar, window)
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dragStart = input.Position
            local startPos  = window.Position
            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(mi)
                if mi.UserInputType == Enum.UserInputType.MouseMovement or mi.UserInputType == Enum.UserInputType.Touch then
                    local d = mi.Position - dragStart
                    window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if moveConn then moveConn:Disconnect() end
                    if endConn  then endConn:Disconnect()  end
                end
            end)
        end
    end)
end

function Library:CreateWindow(options)
    options = options or {}
    local windowTitle = options.Title or "Script"
    local windowSize  = options.Size  or UDim2.new(0, 836, 0, 538)
    local toggleKey   = options.ToggleKey or Enum.KeyCode.RightShift

    local ScreenGui = Utility:Create("ScreenGui", {
        Name = "KamiBloxGUI", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false
    })
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == toggleKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)
    local ok = pcall(function() ScreenGui.Parent = CoreGui end)
    if not ok then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    -- Popup system
    local PopupBg = Utility:Create("TextButton", {
        Name = "PopupBg", Parent = ScreenGui, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), ZIndex = 100, Visible = false, Text = "", AutoButtonColor = false
    })
    local PopupConnections = {}
    PopupBg.MouseButton1Click:Connect(function()
        PopupBg.Visible = false
        for _, c in ipairs(PopupConnections) do if c.Disconnect then c:Disconnect() end end
        table.clear(PopupConnections)
    end)
    local PopupFrame = Utility:Create("Frame", {
        Name = "PopupFrame", Parent = PopupBg, BackgroundColor3 = Theme.MainBg,
        BorderSizePixel = 0, Size = UDim2.new(0,220,0,280), ZIndex = 101
    })
    Utility:Create("UICorner", {Parent = PopupFrame, CornerRadius = UDim.new(0,8)})
    local PopupTitle = Utility:Create("TextLabel", {
        Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,10),
        Size = UDim2.new(1,-20,0,16), Font = Theme.Font, Text = "Settings",
        TextColor3 = Theme.TextMain, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102
    })
    local PopupContent = Utility:Create("Frame", {
        Parent = PopupFrame, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,32),
        Size = UDim2.new(1,-20,1,-42), ZIndex = 102
    })
    local PopupLayout = Utility:Create("UIListLayout", {Parent = PopupContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})
    PopupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        PopupFrame.Size = UDim2.new(0,220,0,PopupLayout.AbsoluteContentSize.Y + 42)
    end)

    local function OpenModal(title, setupFunc, sourceElement)
        PopupTitle.Text = title
        for _, c in ipairs(PopupConnections) do if c.Disconnect then c:Disconnect() end end
        table.clear(PopupConnections)
        for _, child in pairs(PopupContent:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        setupFunc(PopupContent)
        if sourceElement then
            local absPos = sourceElement.AbsolutePosition
            local absSize = sourceElement.AbsoluteSize
            local screenX = ScreenGui.AbsoluteSize.X
            local screenY = ScreenGui.AbsoluteSize.Y
            local tx = absPos.X + absSize.X + 10
            local ty = absPos.Y
            if tx + 220 > screenX then tx = absPos.X - 220 - 10 end
            if ty + PopupFrame.AbsoluteSize.Y > screenY then ty = screenY - PopupFrame.AbsoluteSize.Y - 10 end
            PopupFrame.Position = UDim2.new(0, tx, 0, ty)
        else
            PopupFrame.Position = UDim2.new(0.5,-110,0.5,-140)
        end
        PopupBg.Visible = true
    end

    local AccentUpdates = {}
    local function ApplyAccent()
        for _, fn in ipairs(AccentUpdates) do fn(Theme.ToggleActive) end
    end
    local function OpenColorPicker(title, defaultColor, defaultAlpha, callback, sourceElement)
        OpenModal(title, function(container)
            local currentColor = defaultColor or Color3.new(1,1,1)
            local currentAlpha = defaultAlpha or 1
            local colorCb = callback or function() end
            local h, s, v = currentColor:ToHSV()
            local ColorContainer = Utility:Create("Frame", {Parent=container, BackgroundTransparency=1, Size=UDim2.new(1,0,0,120), ZIndex=102})
            local SVMap = Utility:Create("TextButton", {Parent=ColorContainer, BackgroundColor3=Color3.fromHSV(h,1,1), BorderSizePixel=0, Size=UDim2.new(1,-40,1,0), Text="", AutoButtonColor=false, ClipsDescendants=true, ZIndex=102})
            Utility:Create("UICorner", {Parent=SVMap, CornerRadius=UDim.new(0,4)})
            local SatOverlay = Utility:Create("Frame", {Parent=SVMap, BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(1,0,1,0), ZIndex=103})
            Utility:Create("UIGradient", {Parent=SatOverlay, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}), Rotation=0})
            local ValOverlay = Utility:Create("Frame", {Parent=SVMap, BackgroundColor3=Color3.new(0,0,0), Size=UDim2.new(1,0,1,0), ZIndex=104})
            Utility:Create("UIGradient", {Parent=ValOverlay, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}), Rotation=90})
            local PickerRing = Utility:Create("Frame", {Parent=SVMap, BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,6,0,6), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(s,0,1-v,0), ZIndex=105})
            Utility:Create("UICorner", {Parent=PickerRing, CornerRadius=UDim.new(1,0)})
            Utility:Create("UIStroke", {Parent=PickerRing, Color=Color3.new(0,0,0), Thickness=1})
            local HueBar = Utility:Create("TextButton", {Parent=ColorContainer, Position=UDim2.new(1,-34,0,0), Size=UDim2.new(0,16,1,0), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=102})
            Utility:Create("UICorner", {Parent=HueBar, CornerRadius=UDim.new(0,4)})
            local HueGrad = Utility:Create("UIGradient", {Parent=HueBar, Rotation=90})
            HueGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.167,Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.333,Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.667,Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.833,Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})
            local HueRing = Utility:Create("Frame", {Parent=HueBar, BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(1,2,0,4), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,h,0), ZIndex=106})
            Utility:Create("UIStroke", {Parent=HueRing, Color=Color3.new(0,0,0), Thickness=1})
            local AlphaBar = Utility:Create("TextButton", {Parent=ColorContainer, Position=UDim2.new(1,-12,0,0), Size=UDim2.new(0,12,1,0), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=102})
            Utility:Create("UICorner", {Parent=AlphaBar, CornerRadius=UDim.new(0,4)})
            local AlphaGrad = Utility:Create("UIGradient", {Parent=AlphaBar, Rotation=90})
            AlphaGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,currentColor), ColorSequenceKeypoint.new(1,Theme.ElementBg)})
            local AlphaRing = Utility:Create("Frame", {Parent=AlphaBar, BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(1,2,0,4), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,1-currentAlpha,0), ZIndex=106})
            Utility:Create("UIStroke", {Parent=AlphaRing, Color=Color3.new(0,0,0), Thickness=1})
            local BottomContainer = Utility:Create("Frame", {Parent=container, BackgroundTransparency=1, Size=UDim2.new(1,0,0,28), ZIndex=102})
            local PreviewBox = Utility:Create("Frame", {Parent=BottomContainer, BackgroundColor3=currentColor, BorderSizePixel=0, Size=UDim2.new(1,0,1,0), ZIndex=102})
            Utility:Create("UICorner", {Parent=PreviewBox, CornerRadius=UDim.new(0,4)})
            local draggingSV, draggingHue, draggingAlpha = false, false, false
            local function updateColor()
                currentColor = Color3.fromHSV(h, s, v)
                PreviewBox.BackgroundColor3 = currentColor
                PreviewBox.BackgroundTransparency = 1 - currentAlpha
                AlphaGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,currentColor), ColorSequenceKeypoint.new(1,Theme.ElementBg)})
                colorCb(currentColor, currentAlpha)
            end
            local function updateSV(input)
                local x = math.clamp(input.Position.X - SVMap.AbsolutePosition.X, 0, SVMap.AbsoluteSize.X)
                local y = math.clamp(input.Position.Y - SVMap.AbsolutePosition.Y, 0, SVMap.AbsoluteSize.Y)
                s = x/SVMap.AbsoluteSize.X; v = 1-(y/SVMap.AbsoluteSize.Y)
                PickerRing.Position = UDim2.new(s,0,1-v,0); updateColor()
            end
            local function updateHue(input)
                local y = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
                h = y/HueBar.AbsoluteSize.Y
                HueRing.Position = UDim2.new(0.5,0,h,0); SVMap.BackgroundColor3 = Color3.fromHSV(h,1,1); updateColor()
            end
            local function updateAlpha(input)
                local y = math.clamp(input.Position.Y - AlphaBar.AbsolutePosition.Y, 0, AlphaBar.AbsoluteSize.Y)
                currentAlpha = 1-(y/AlphaBar.AbsoluteSize.Y)
                AlphaRing.Position = UDim2.new(0.5,0,y/AlphaBar.AbsoluteSize.Y,0); updateColor()
            end
            SVMap.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingSV=true; updateSV(i) end end)
            HueBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingHue=true; updateHue(i) end end)
            AlphaBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingAlpha=true; updateAlpha(i) end end)
            local c1 = UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingSV,draggingHue,draggingAlpha=false,false,false end end)
            local c2 = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseMovement then
                    if draggingSV then updateSV(i) end
                    if draggingHue then updateHue(i) end
                    if draggingAlpha then updateAlpha(i) end
                end
            end)
            table.insert(PopupConnections, c1); table.insert(PopupConnections, c2)
        end, sourceElement)
    end

    -- Main frame
    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame", Parent = ScreenGui, BackgroundColor3 = Theme.MainBg,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5,-windowSize.X.Offset/2, 0.5,-windowSize.Y.Offset/2),
        Size = windowSize, Active = true
    })
    Utility:Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0,8)})
    Utility:MakeDraggable(MainFrame, MainFrame)

    local TabFrame = Utility:Create("Frame", {
        Name = "tabframe", Parent = MainFrame, BackgroundColor3 = Theme.TabFrameBg,
        BorderSizePixel = 0, Size = UDim2.new(0,216,1,0)
    })
    Utility:Create("UICorner", {Parent = TabFrame, CornerRadius = UDim.new(0,8)})

    local TabButtonContainer = Utility:Create("Frame", {
        Name = "TabButtonContainer", Parent = TabFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0,10,0,10), Size = UDim2.new(1,-20,1,-50)
    })
    local AccentFrame = Utility:Create("Frame", {Parent=TabFrame, BackgroundTransparency=1, Position=UDim2.new(0,10,1,-30), Size=UDim2.new(1,-20,0,20)})
    Utility:Create("TextLabel", {Parent=AccentFrame, BackgroundTransparency=1, Position=UDim2.new(0,24,0,0), Size=UDim2.new(1,-54,1,0), Font=Theme.LabelFont, Text="Accent", TextColor3=Theme.TextCategory, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left})
    local AccentPickerBtn = Utility:Create("TextButton", {Parent=AccentFrame, BackgroundColor3=Theme.ToggleActive, BorderSizePixel=0, Position=UDim2.new(1,-20,0.5,-8), Size=UDim2.new(0,16,0,16), Text="", AutoButtonColor=false})
    Utility:Create("UICorner", {Parent=AccentPickerBtn, CornerRadius=UDim.new(0,4)})
    AccentPickerBtn.MouseButton1Click:Connect(function()
        OpenColorPicker("Accent Color", Theme.ToggleActive, 1, function(col)
            Theme.ToggleActive = col
            AccentPickerBtn.BackgroundColor3 = col
            ApplyAccent()
        end, AccentPickerBtn)
    end)

    Utility:Create("UIListLayout", {Parent=TabButtonContainer, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0)})

    local PageContainer = Utility:Create("Frame", {
        Name = "PageContainer", Parent = MainFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0,226,0,10), Size = UDim2.new(1,-236,1,-20)
    })

    local Window = {}
    local Tabs = {}
    local tabCount = 2

    function Window:CreateCategory(name)
        Utility:Create("TextLabel", {
            Parent=TabButtonContainer, BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
            Font=Theme.Font, Text="   "..name, TextColor3=Theme.TextCategory,
            TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=tabCount
        })
        tabCount = tabCount + 1
    end

    function Window:CreateTab(name, iconId)
        local TabBtn = Utility:Create("TextButton", {
            Name="TabButton_"..name, Parent=TabButtonContainer, BackgroundColor3=Theme.TabFrameBg,
            BorderSizePixel=0, Size=UDim2.new(1,0,0,32), Font=Theme.LabelFont,
            Text=(iconId and "          " or "   ")..name,
            TextColor3=Color3.fromRGB(130,130,130), TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false, LayoutOrder=tabCount
        })
        Utility:Create("UICorner", {Parent=TabBtn, CornerRadius=UDim.new(0,6)})
        tabCount = tabCount + 1

        local TabIcon
        if iconId then
            TabIcon = Utility:Create("ImageLabel", {
                Parent=TabBtn, BackgroundTransparency=1, Position=UDim2.new(0,8,0.5,-8),
                Size=UDim2.new(0,16,0,16),
                Image="rbxthumb://type=Asset&id="..iconId.."&w=150&h=150",
                ImageColor3=Color3.fromRGB(130,130,130)
            })
        end

        local Page = Utility:Create("Frame", {
            Name="Page_"..name, Parent=PageContainer, BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), Visible=false
        })

        local LeftCol = Utility:Create("ScrollingFrame", {
            Name="LeftColumn", Parent=Page, BackgroundTransparency=1, Position=UDim2.new(0,0,0,0),
            Size=UDim2.new(0.5,-5,1,0), ScrollBarThickness=2,
            ScrollBarImageColor3=Theme.TextCategory, AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.new(0,0,0,0)
        })
        local LeftLayout = Utility:Create("UIListLayout", {Parent=LeftCol, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
        local RightCol = Utility:Create("ScrollingFrame", {
            Name="RightColumn", Parent=Page, BackgroundTransparency=1, Position=UDim2.new(0.5,5,0,0),
            Size=UDim2.new(0.5,-5,1,0), ScrollBarThickness=2,
            ScrollBarImageColor3=Theme.TextCategory, AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.new(0,0,0,0)
        })
        local RightLayout = Utility:Create("UIListLayout", {Parent=RightCol, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
        LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LeftCol.CanvasSize=UDim2.new(0,0,0,LeftLayout.AbsoluteContentSize.Y+10) end)
        RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RightCol.CanvasSize=UDim2.new(0,0,0,RightLayout.AbsoluteContentSize.Y+10) end)

        local tabData = {Btn=TabBtn, Page=Page, Icon=TabIcon}
        table.insert(Tabs, tabData)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                t.Btn.BackgroundColor3 = Theme.TabFrameBg
                t.Btn.TextColor3 = Color3.fromRGB(130,130,130)
                t.Btn.Font = Theme.LabelFont
                if t.Icon then t.Icon.ImageColor3 = Color3.fromRGB(130,130,130) end
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
                Name="Child_"..secName, Parent=targetCol, BackgroundColor3=Theme.SectionBg,
                BorderSizePixel=0, Size=UDim2.new(1,0,0,40)
            })
            Utility:Create("UICorner", {Parent=SectionFrame, CornerRadius=UDim.new(0,6)})
            Utility:Create("TextLabel", {
                Parent=SectionFrame, BackgroundTransparency=1, Position=UDim2.new(0,12,0,5),
                Size=UDim2.new(1,-24,0,20), Font=Theme.LabelFont, Text=secName,
                TextColor3=Theme.TextCategory, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left
            })

            local ContentContainer = Utility:Create("Frame", {
                Parent=SectionFrame, BackgroundTransparency=1, Position=UDim2.new(0,0,0,30), Size=UDim2.new(1,0,1,-30)
            })
            local SectionLayout = Utility:Create("UIListLayout", {
                Parent=ContentContainer, SortOrder=Enum.SortOrder.LayoutOrder,
                Padding=UDim.new(0,5), HorizontalAlignment=Enum.HorizontalAlignment.Center
            })
            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1,0,0,SectionLayout.AbsoluteContentSize.Y+40)
            end)

            local Elements = {}

            function Elements:CreateToggle(opts)
                opts = opts or {}
                local togText = opts.Name or "Toggle"
                local state = opts.Default or false
                local callback = opts.Callback or function() end
                local ToggleFrame = Utility:Create("Frame", {Parent=ContentContainer, BackgroundTransparency=1, Size=UDim2.new(1,-24,0,24)})
                Utility:Create("TextLabel", {Parent=ToggleFrame, BackgroundTransparency=1, Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,-60,1,0), Font=Theme.LabelFont, Text=togText, TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
                local ToggleBox = Utility:Create("TextButton", {
                    Parent=ToggleFrame, BackgroundColor3=state and Theme.ToggleActive or Theme.ToggleInactive,
                    BorderSizePixel=0, Size=UDim2.new(0,16,0,16), AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,0,0.5,0), Text="", AutoButtonColor=false
                })
                Utility:Create("UICorner", {Parent=ToggleBox, CornerRadius=UDim.new(0,4)})
                table.insert(AccentUpdates, function(col) if state then ToggleBox.BackgroundColor3 = col end end)

                local currentBind = nil
                local bindMode = "Toggle"
                local isBinding = false
                local activeBindBtnInModal = nil

                local GearBtn = Utility:Create("ImageButton", {
                    Parent=ToggleFrame, BackgroundTransparency=1, Size=UDim2.new(0,16,0,16),
                    Position=UDim2.new(1,-26,0.5,0), AnchorPoint=Vector2.new(1,0.5),
                    Image="rbxthumb://type=Asset&id=11738672708&w=150&h=150",
                    ImageColor3=Color3.fromRGB(150,150,150), AutoButtonColor=false
                })
                GearBtn.MouseButton1Click:Connect(function()
                    if not opts.Colorpicker then return end
                    OpenColorPicker(togText.." Color", opts.ColorDefault, opts.AlphaDefault, opts.ColorCallback, GearBtn)
                end)
                GearBtn.MouseButton2Click:Connect(function()
                    OpenModal(togText.." Keybind", function(container)
                        local BindBtnInModal = Utility:Create("TextButton", {Parent=container, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Size=UDim2.new(1,0,0,28), Font=Theme.Font, Text=currentBind and "["..currentBind.Name.."]" or "[Click to Bind]", TextColor3=Theme.TextMain, TextSize=13, ZIndex=102})
                        Utility:Create("UICorner", {Parent=BindBtnInModal, CornerRadius=UDim.new(0,6)})
                        activeBindBtnInModal = BindBtnInModal
                        BindBtnInModal.MouseButton1Click:Connect(function() isBinding=true; BindBtnInModal.Text="[...]" end)
                        local ModeBtn = Utility:Create("TextButton", {Parent=container, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Size=UDim2.new(1,0,0,28), Font=Theme.Font, Text="Mode: "..bindMode, TextColor3=Theme.TextMain, TextSize=13, ZIndex=102})
                        Utility:Create("UICorner", {Parent=ModeBtn, CornerRadius=UDim.new(0,6)})
                        ModeBtn.MouseButton1Click:Connect(function()
                            bindMode = bindMode=="Toggle" and "Hold" or "Toggle"
                            ModeBtn.Text = "Mode: "..bindMode
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
                            if activeBindBtnInModal then activeBindBtnInModal.Text = "["..input.KeyCode.Name.."]" end
                        end
                        isBinding = false
                    elseif not gp and currentBind and input.KeyCode == currentBind then
                        if bindMode == "Toggle" then
                            state = not state
                            TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3=state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
                            callback(state)
                        elseif bindMode == "Hold" then
                            state = true
                            TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3=Theme.ToggleActive}):Play()
                            callback(state)
                        end
                    end
                end)
                UserInputService.InputEnded:Connect(function(input, gp)
                    if not gp and currentBind and input.KeyCode == currentBind and bindMode == "Hold" then
                        state = false
                        TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3=Theme.ToggleInactive}):Play()
                        callback(state)
                    end
                end)
                ToggleBox.MouseButton1Click:Connect(function()
                    state = not state
                    TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3=state and Theme.ToggleActive or Theme.ToggleInactive}):Play()
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
                local SliderFrame = Utility:Create("Frame", {Parent=ContentContainer, BackgroundTransparency=1, Size=UDim2.new(1,-24,0,36)})
                Utility:Create("TextLabel", {Parent=SliderFrame, BackgroundTransparency=1, Size=UDim2.new(1,-40,0,16), Font=Theme.LabelFont, Text=slName, TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
                local ValueLabel = Utility:Create("TextLabel", {Parent=SliderFrame, BackgroundTransparency=1, Position=UDim2.new(1,-40,0,0), Size=UDim2.new(0,40,0,16), Font=Theme.Font, Text=tostring(default), TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Right})
                local SliderBack = Utility:Create("Frame", {Parent=SliderFrame, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Position=UDim2.new(0,0,0,22), Size=UDim2.new(1,0,0,6)})
                Utility:Create("UICorner", {Parent=SliderBack, CornerRadius=UDim.new(0,3)})
                local fillPct = math.clamp((default-min)/(max-min),0,1)
                local SliderFill = Utility:Create("Frame", {Parent=SliderBack, BackgroundColor3=Theme.ToggleActive, BorderSizePixel=0, Size=UDim2.new(fillPct,0,1,0)})
                Utility:Create("UICorner", {Parent=SliderFill, CornerRadius=UDim.new(0,3)})
                table.insert(AccentUpdates, function(col) SliderFill.BackgroundColor3 = col end)
                local SliderBtn = Utility:Create("TextButton", {Parent=SliderBack, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text="", AutoButtonColor=false})
                local function update(input)
                    local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X,0,1)
                    SliderFill.Size = UDim2.new(pos,0,1,0)
                    local value = math.floor(min + ((max-min)*pos))
                    ValueLabel.Text = tostring(value)
                    callback(value)
                end
                SliderBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        update(input)
                        local mc, ec
                        mc = UserInputService.InputChanged:Connect(function(mi)
                            if mi.UserInputType == Enum.UserInputType.MouseMovement then update(mi) end
                        end)
                        ec = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                if mc then mc:Disconnect() end
                                if ec then ec:Disconnect() end
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
                local ButtonFrame = Utility:Create("Frame", {Parent=ContentContainer, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Size=UDim2.new(1,-24,0,24)})
                Utility:Create("UICorner", {Parent=ButtonFrame, CornerRadius=UDim.new(0,6)})
                local Button = Utility:Create("TextButton", {Parent=ButtonFrame, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Font=Theme.Font, Text=btnText, TextColor3=Theme.TextMain, TextSize=13})
                Button.MouseButton1Click:Connect(function() callback() end)
            end

            function Elements:CreateTextbox(opts)
                opts = opts or {}
                local tbText = opts.Name or "Textbox"
                local placeholder = opts.Placeholder or ""
                local callback = opts.Callback or function() end
                local TextboxFrame = Utility:Create("Frame", {Parent=ContentContainer, BackgroundTransparency=1, Size=UDim2.new(1,-24,0,40)})
                Utility:Create("TextLabel", {Parent=TextboxFrame, BackgroundTransparency=1, Size=UDim2.new(1,0,0,16), Font=Theme.LabelFont, Text=tbText, TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
                local BoxBg = Utility:Create("Frame", {Parent=TextboxFrame, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Position=UDim2.new(0,0,0,16), Size=UDim2.new(1,0,0,24)})
                Utility:Create("UICorner", {Parent=BoxBg, CornerRadius=UDim.new(0,6)})
                local TextBox = Utility:Create("TextBox", {Parent=BoxBg, BackgroundTransparency=1, Position=UDim2.new(0,8,0,0), Size=UDim2.new(1,-16,1,0), Font=Theme.Font, Text="", PlaceholderText=placeholder, TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false})
                TextBox.FocusLost:Connect(function() callback(TextBox.Text) end)
            end

            function Elements:CreateDropdown(opts)
                opts = opts or {}
                local dropText = opts.Name or "Dropdown"
                local list = opts.Options or {}
                local callback = opts.Callback or function() end
                local isOpen = false
                local selected = opts.Default or (list[1] or "")
                local DropdownFrame = Utility:Create("Frame", {Parent=ContentContainer, BackgroundTransparency=1, Size=UDim2.new(1,-24,0,40)})
                Utility:Create("TextLabel", {Parent=DropdownFrame, BackgroundTransparency=1, Size=UDim2.new(1,0,0,16), Font=Theme.LabelFont, Text=dropText, TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
                local MainBox = Utility:Create("TextButton", {Parent=DropdownFrame, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Position=UDim2.new(0,0,0,16), Size=UDim2.new(1,0,0,24), Text=""})
                Utility:Create("UICorner", {Parent=MainBox, CornerRadius=UDim.new(0,6)})
                local SelectedLabel = Utility:Create("TextLabel", {Parent=MainBox, BackgroundTransparency=1, Position=UDim2.new(0,8,0,0), Size=UDim2.new(1,-25,1,0), Font=Theme.Font, Text=selected, TextColor3=Theme.TextMain, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
                local Arrow = Utility:Create("TextLabel", {Parent=MainBox, BackgroundTransparency=1, Position=UDim2.new(1,-20,0,0), Size=UDim2.new(0,20,1,0), Font=Theme.Font, Text="v", TextColor3=Theme.TextMain, TextSize=13})
                local DropContainer = Utility:Create("Frame", {Parent=DropdownFrame, BackgroundColor3=Theme.ElementBg, BorderSizePixel=0, Position=UDim2.new(0,0,0,44), Size=UDim2.new(1,0,0,0), Visible=false, ClipsDescendants=true})
                Utility:Create("UICorner", {Parent=DropContainer, CornerRadius=UDim.new(0,6)})
                Utility:Create("UIListLayout", {Parent=DropContainer, SortOrder=Enum.SortOrder.LayoutOrder})
                local function createList()
                    for _, v in pairs(DropContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    local h = 0
                    for _, option in pairs(list) do
                        local OptBtn = Utility:Create("TextButton", {Parent=DropContainer, BackgroundTransparency=1, Size=UDim2.new(1,0,0,25), Font=Enum.Font.Gotham, Text="  "..option, TextColor3=Theme.TextMain, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left})
                        h = h + 25
                        OptBtn.MouseButton1Click:Connect(function()
                            selected = option
                            SelectedLabel.Text = selected
                            isOpen = false
                            DropContainer.Visible = false
                            Arrow.Text = "v"
                            DropdownFrame.Size = UDim2.new(1,-24,0,50)
                            for _, btn in pairs(DropContainer:GetChildren()) do
                                if btn:IsA("TextButton") then
                                    local optName = btn.Text:sub(3)
                                    btn.TextColor3 = (optName==selected) and Theme.ToggleActive or Theme.TextMain
                                    btn.Font = (optName==selected) and Theme.Font or Enum.Font.Gotham
                                end
                            end
                            callback(selected)
                        end)
                    end
                    DropContainer.Size = UDim2.new(1,0,0,h)
                    for _, btn in pairs(DropContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            local optName = btn.Text:sub(3)
                            btn.TextColor3 = (optName==selected) and Theme.ToggleActive or Theme.TextMain
                            btn.Font = (optName==selected) and Theme.Font or Enum.Font.Gotham
                        end
                    end
                end
                createList()
                MainBox.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    DropContainer.Visible = isOpen
                    Arrow.Text = isOpen and "^" or "v"
                    DropdownFrame.Size = UDim2.new(1,-24,0,isOpen and 55+DropContainer.Size.Y.Offset or 50)
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
-- NOTIFICATION HELPER
-- =====================================================

local notificationsEnabled = true
local function notify(text, duration)
    if not notificationsEnabled then return end
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Movement Ware",
            Text = tostring(text),
            Duration = duration
        })
    end)
end

-- =====================================================
-- MOVEMENT WARE V3 - BACKEND
-- =====================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local SoundService     = game:GetService("SoundService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer
local camera           = Workspace.CurrentCamera

_G.vfxAttachments = _G.vfxAttachments or {}
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = Workspace.CurrentCamera
end)

local function stripAssetPrefix(id)
    return tostring(id or ""):gsub("rbxassetid://", "")
end
local function asAssetId(id)
    id = tostring(id or "")
    if id == "" then return "" end
    if id:find("rbxassetid://",1,true) then return id end
    return "rbxassetid://"..id
end

-- Settings table
local Settings = {
    FOV=93, FOVEnabled=false, EdgeEnabled=false, EdgePower=150,
    TrimpEnabled=false, SpinEnabled=false, TurnEnabled=false, TurnSpeed=0.05,
    FFlagEnabled=false, KorbloxEnabled=false, HeadlessEnabled=false,
    PCFlyEnabled=false, MobileFlyEnabled=false, InvisWallEnabled=false,
    VFXEnabled=false, AutoApplyCosmetic=false, AutoApplyGlobalColor=false,
    AutoApplySkyColor=false, AutoApplyPerfectFog=false,
    MobileEdgeEnabled=false, MapScale=1.0, SpawnHeight=1500,
    mommyAsmrEnabled=false, keyboardSoundEnabled=false, NotificationsEnabled=true
}

local WINE_CONFIG = {TrueWine=Color3.fromRGB(80,0,25), BlackWine=Color3.fromRGB(30,0,10), Material=Enum.Material.SmoothPlastic}
local deepWineSequence = nil
local function rebuildDeepWineSequence()
    deepWineSequence = ColorSequence.new({ColorSequenceKeypoint.new(0,WINE_CONFIG.BlackWine), ColorSequenceKeypoint.new(0.2,WINE_CONFIG.TrueWine), ColorSequenceKeypoint.new(1,WINE_CONFIG.BlackWine)})
end
rebuildDeepWineSequence()

-- =====================================================
-- COSMETIC & EMOTE SWAPPER (CONFIG-BASED)
-- =====================================================
-- Edit these tables to configure your swaps.
-- Format: ["TargetToReplace"] = "SourceToCopyFrom"
-- Items are searched recursively inside ReplicatedStorage.

local EMOTE_SWAP_CONFIG = {
    -- ["BoldMarch"] = "Broom",
}

local COSMETIC_SWAP_CONFIG = {
    -- ["PureLove"] = "ToxicInferno",
}

-- Internal backup storage so originals can be restored
local EmoteSwapBackups    = {}
local CosmeticSwapBackups = {}

local function findItemInRS(name)
    return ReplicatedStorage:FindFirstChild(name, true)
end

local function backupContents(item, backupTable, key)
    if backupTable[key] then return end   -- already backed up
    local saved = {}
    for _, child in ipairs(item:GetChildren()) do
        saved[#saved + 1] = child:Clone()
    end
    backupTable[key] = saved
end

local function replaceContents(target, source)
    for _, child in ipairs(target:GetChildren()) do child:Destroy() end
    local sourceChildren = source:GetChildren()
    if #sourceChildren > 0 then
        for _, child in ipairs(sourceChildren) do child:Clone().Parent = target end
    else
        source:Clone().Parent = target
    end
end

local function restoreContents(item, backupTable, key)
    local saved = backupTable[key]
    if not saved then return false end
    for _, child in ipairs(item:GetChildren()) do child:Destroy() end
    for _, clone in ipairs(saved) do clone:Clone().Parent = item end
    backupTable[key] = nil
    return true
end

local function applyConfigSwaps(config, backupTable)
    local swapped, failed = 0, 0
    for targetName, sourceName in pairs(config) do
        local ok, err = pcall(function()
            local target = findItemInRS(targetName)
            local source  = findItemInRS(sourceName)
            if not target then
                warn("[Swap Failed] Target '" .. targetName .. "' not found in ReplicatedStorage.")
                failed = failed + 1; return
            end
            if not source then
                warn("[Swap Failed] Source '" .. sourceName .. "' not found in ReplicatedStorage.")
                failed = failed + 1; return
            end
            backupContents(target, backupTable, targetName)
            replaceContents(target, source)
            swapped = swapped + 1
        end)
        if not ok then
            warn("[Swap Error] " .. tostring(err))
            failed = failed + 1
        end
    end
    return swapped, failed
end

local function restoreAllFromBackup(config, backupTable)
    local restored, failed = 0, 0
    for targetName in pairs(config) do
        local ok = pcall(function()
            local target = findItemInRS(targetName)
            if target and restoreContents(target, backupTable, targetName) then
                restored = restored + 1
            else
                failed = failed + 1
            end
        end)
        if not ok then failed = failed + 1 end
    end
    return restored, failed
end

-- =====================================================
-- TURNBIND
-- =====================================================

local TurnbindSettings = {Enabled=false, TurnSpeed=0.3, LeftKey=Enum.KeyCode.A, RightKey=Enum.KeyCode.D}
local turnbindConns = {}
local function stopTurnbind()
    if turnbindConns.Began then turnbindConns.Began:Disconnect() end
    if turnbindConns.Ended then turnbindConns.Ended:Disconnect() end
    turnbindConns = {}
end
local function startTurnbind()
    stopTurnbind()
    local VIM = game:GetService("VirtualInputManager")
    turnbindConns.Began = UserInputService.InputBegan:Connect(function(input, gpe)
        pcall(function()
            if gpe or not TurnbindSettings.Enabled then return end
            if input.KeyCode==TurnbindSettings.LeftKey then VIM:SendKeyEvent(true,Enum.KeyCode.Left,false,game)
            elseif input.KeyCode==TurnbindSettings.RightKey then VIM:SendKeyEvent(true,Enum.KeyCode.Right,false,game) end
        end)
    end)
    turnbindConns.Ended = UserInputService.InputEnded:Connect(function(input)
        pcall(function()
            if input.KeyCode==TurnbindSettings.LeftKey then VIM:SendKeyEvent(false,Enum.KeyCode.Left,false,game)
            elseif input.KeyCode==TurnbindSettings.RightKey then VIM:SendKeyEvent(false,Enum.KeyCode.Right,false,game) end
        end)
    end)
end

-- =====================================================
-- GLOBAL COLOR / WORLD VISUALS
-- =====================================================

local globalColorEnabled = false
local globalColor = Color3.fromRGB(255,255,255)
local originalColors = {}
local function isCharacterPart(obj)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and (obj:IsDescendantOf(plr.Character) or obj.Parent==plr.Character) then return true end
    end
    return false
end
local function storeOriginalColors() originalColors={}; for _,obj in pairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then originalColors[obj]=obj.Color end end end
local function applyGlobalColor() if not globalColorEnabled then return end; for _,obj in pairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then pcall(function() obj.Color=globalColor end) end end end
local function restoreOriginalColors() for part,color in pairs(originalColors) do if part and part.Parent then pcall(function() part.Color=color end) end end; originalColors={} end

local skyColorEnabled = false
local skyColor = Color3.fromRGB(135,206,235)
local originalAmbient, originalOutdoorAmbient = nil, nil
local function applySkyColor()
    if not originalAmbient then originalAmbient=Lighting.Ambient; originalOutdoorAmbient=Lighting.OutdoorAmbient end
    if skyColorEnabled then
        Lighting.Ambient=skyColor; Lighting.OutdoorAmbient=skyColor
        local atm=Lighting:FindFirstChild("Atmosphere"); if atm then atm.Color=skyColor end
    else
        Lighting.Ambient=originalAmbient or Color3.fromRGB(128,128,128)
        Lighting.OutdoorAmbient=originalOutdoorAmbient or Color3.fromRGB(128,128,128)
    end
end

local perfectFogEnabled = false
local perfectFogColor = Color3.fromRGB(180,190,200)
local originalFogSettings = nil
local function saveOriginalFogSettings()
    if originalFogSettings then return end
    originalFogSettings={FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,ColorShift_Top=Lighting.ColorShift_Top,ColorShift_Bottom=Lighting.ColorShift_Bottom,GlobalShadows=Lighting.GlobalShadows,ShadowSoftness=Lighting.ShadowSoftness,EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale,EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale}
end
local function removePerfectFogObjects()
    for _,obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj.Name=="PerfectFogSky" then obj:Destroy()
        elseif obj:IsA("Atmosphere") and (obj.Name=="PerfectFogAtmosphere" or obj.Name=="PerfectFogAtm") then obj:Destroy() end
    end
end
local function applyPerfectFog()
    saveOriginalFogSettings()
    if not perfectFogEnabled then
        for prop,val in pairs(originalFogSettings) do pcall(function() Lighting[prop]=val end) end
        removePerfectFogObjects(); return
    end
    Lighting.FogStart=10; Lighting.FogEnd=math.max(300/(0.9*0.8+0.2),50); Lighting.FogColor=Color3.fromRGB(210,220,240)
    Lighting.Ambient=Color3.fromRGB(111,111,111); Lighting.OutdoorAmbient=Color3.fromRGB(111,111,111)
    Lighting.ColorShift_Top=Color3.fromRGB(111,111,111); Lighting.ColorShift_Bottom=Color3.fromRGB(111,111,111)
    Lighting.GlobalShadows=true; Lighting.ShadowSoftness=0.3; Lighting.EnvironmentDiffuseScale=1; Lighting.EnvironmentSpecularScale=1
    removePerfectFogObjects()
    local sky=Instance.new("Sky",Lighting); sky.Name="PerfectFogSky"
    sky.SkyboxBk="rbxassetid://252760981"; sky.SkyboxDn="rbxassetid://252763921"
    sky.SkyboxFt="rbxassetid://252761439"; sky.SkyboxLf="rbxassetid://252761439"
    sky.SkyboxRt="rbxassetid://252761439"; sky.SkyboxUp="rbxassetid://252762708"
    local atm=Instance.new("Atmosphere",Lighting); atm.Name="PerfectFogAtmosphere"
    atm.Color=perfectFogColor; atm.Decay=Color3.fromRGB(90,100,110); atm.Density=0.6; atm.Offset=0.25; atm.Haze=0.6
end

local sunsetShaderEnabled = false
local sunsetShaderOriginalLighting = nil
local SUNSET_PREFIX = "MWSunsetShader"
local function saveSunsetShaderLighting()
    if sunsetShaderOriginalLighting then return end
    sunsetShaderOriginalLighting={Ambient=Lighting.Ambient,Brightness=Lighting.Brightness,ColorShift_Bottom=Lighting.ColorShift_Bottom,ColorShift_Top=Lighting.ColorShift_Top,EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale,EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale,GlobalShadows=Lighting.GlobalShadows,OutdoorAmbient=Lighting.OutdoorAmbient,ShadowSoftness=Lighting.ShadowSoftness,ExposureCompensation=Lighting.ExposureCompensation,ClockTime=Lighting.ClockTime,GeographicLatitude=Lighting.GeographicLatitude}
end
local function removeSunsetShaderObjects()
    for _,obj in ipairs(Lighting:GetChildren()) do if obj.Name:sub(1,#SUNSET_PREFIX)==SUNSET_PREFIX then obj:Destroy() end end
    local pg=LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local ov=pg and pg:FindFirstChild("MWSunsetShaderOverlay"); if ov then ov:Destroy() end
end
local function restoreSunsetShaderLighting()
    if not sunsetShaderOriginalLighting then return end
    for prop,value in pairs(sunsetShaderOriginalLighting) do pcall(function() Lighting[prop]=value end) end
    sunsetShaderOriginalLighting=nil
end
local function applySunsetShader()
    if not sunsetShaderEnabled then removeSunsetShaderObjects(); restoreSunsetShaderLighting(); return end
    saveSunsetShaderLighting(); removeSunsetShaderObjects()
    local bloom=Instance.new("BloomEffect"); bloom.Name="MWSunsetShaderBloom"; bloom.Intensity=0.15; bloom.Size=5; bloom.Threshold=0.85; bloom.Parent=Lighting
    local blur=Instance.new("BlurEffect"); blur.Name="MWSunsetShaderBlur"; blur.Size=5; blur.Parent=Lighting
    local cc=Instance.new("ColorCorrectionEffect"); cc.Name="MWSunsetShaderColorCorrection"; cc.Brightness=0.1; cc.Contrast=0.2; cc.Saturation=-0.3; cc.TintColor=Color3.fromRGB(255,235,203); cc.Parent=Lighting
    local sr=Instance.new("SunRaysEffect"); sr.Name="MWSunsetShaderSunRays"; sr.Intensity=0.1; sr.Spread=0.727; sr.Parent=Lighting
    local sky=Instance.new("Sky"); sky.Name="MWSunsetShaderSky"
    sky.SkyboxBk="http://www.roblox.com/asset/?id=151165214"; sky.SkyboxDn="http://www.roblox.com/asset/?id=151165197"
    sky.SkyboxFt="http://www.roblox.com/asset/?id=151165224"; sky.SkyboxLf="http://www.roblox.com/asset/?id=151165191"
    sky.SkyboxRt="http://www.roblox.com/asset/?id=151165206"; sky.SkyboxUp="http://www.roblox.com/asset/?id=151165227"
    sky.SunAngularSize=10; sky.Parent=Lighting
    local atm=Instance.new("Atmosphere"); atm.Name="MWSunsetShaderAtmosphere"; atm.Density=0.364; atm.Offset=0.556
    atm.Color=Color3.fromRGB(199,175,166); atm.Decay=Color3.fromRGB(44,39,33); atm.Glare=0.2; atm.Haze=1.3; atm.Parent=Lighting
    Lighting.Ambient=Color3.fromRGB(2,2,2); Lighting.Brightness=2.0; Lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0)
    Lighting.ColorShift_Top=Color3.fromRGB(0,0,0); Lighting.EnvironmentDiffuseScale=0.2; Lighting.EnvironmentSpecularScale=0.2
    Lighting.GlobalShadows=false; Lighting.OutdoorAmbient=Color3.fromRGB(0,0,0); Lighting.ShadowSoftness=3
    Lighting.ExposureCompensation=0.4; Lighting.ClockTime=17; Lighting.GeographicLatitude=45
    local pg=LocalPlayer:WaitForChild("PlayerGui")
    local sg=Instance.new("ScreenGui"); sg.Name="MWSunsetShaderOverlay"; sg.IgnoreGuiInset=true; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=pg
    local il=Instance.new("ImageLabel"); il.Name="SunsetOverlay"; il.AnchorPoint=Vector2.new(0.5,1); il.Position=UDim2.new(0.5,0,1,0); il.Size=UDim2.new(1,0,1.05,0); il.BackgroundTransparency=1; il.Image="rbxassetid://4576475446"; il.ImageTransparency=0.3; il.ZIndex=10; il.Parent=sg
end

-- =====================================================
-- VIRTUAL STRAFE
-- =====================================================

local VirtualStrafeEnabled = false
local VirtualStrafeIntensity = 500
local currentSpeed = 0
local lastCameraYaw = 0
local moveDir = Vector3.new(0,0,0)
local MAX_SPEED_CAP = 500000
local ACCEL_RATE = 75
local STRAFE_ADD_AMOUNT = 5
local TURN_DECEL_FACTOR = 0.85
local LERP_SPEED = 0.15
local BRAKE_FACTOR = 0.85
local IDLE_PERCENT_DECAY = 0.992
local IDLE_LINEAR_DECAY = 35

local function updateVirtualStrafe(dt)
    if not VirtualStrafeEnabled then return end
    local char=LocalPlayer.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid=char:FindFirstChildOfClass("Humanoid"); if humanoid and humanoid.Health<=0 then VirtualStrafeEnabled=false; currentSpeed=0; return end
    local root=char.HumanoidRootPart
    local isW=UserInputService:IsKeyDown(Enum.KeyCode.W); local isA=UserInputService:IsKeyDown(Enum.KeyCode.A)
    local isD=UserInputService:IsKeyDown(Enum.KeyCode.D); local isS=UserInputService:IsKeyDown(Enum.KeyCode.S)
    local camForward=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
    if camForward.Magnitude<=0 then return end; camForward=camForward.Unit
    if moveDir:Dot(camForward)<0.2 and currentSpeed>100 then currentSpeed=currentSpeed*TURN_DECEL_FACTOR end
    moveDir=moveDir:Lerp(camForward,LERP_SPEED); if moveDir.Magnitude>0 then moveDir=moveDir.Unit else moveDir=camForward end
    local _,camYaw,_=camera.CFrame:ToEulerAnglesYXZ()
    local yawDelta=camYaw-lastCameraYaw
    if yawDelta>math.pi then yawDelta=yawDelta-(math.pi*2) end
    if yawDelta<-math.pi then yawDelta=yawDelta+(math.pi*2) end
    lastCameraYaw=camYaw
    local canStrafe=(isA and yawDelta>0.0001) or (isD and yawDelta<-0.0001)
    if isS then currentSpeed=currentSpeed*BRAKE_FACTOR
    elseif isW or isA or isD then
        if currentSpeed<VirtualStrafeIntensity then currentSpeed=currentSpeed+(ACCEL_RATE*3*dt) end
        if canStrafe and currentSpeed>50 then currentSpeed=math.min(currentSpeed+STRAFE_ADD_AMOUNT,MAX_SPEED_CAP) else currentSpeed=currentSpeed*0.999 end
    else currentSpeed=(currentSpeed*IDLE_PERCENT_DECAY)-(IDLE_LINEAR_DECAY*dt) end
    if currentSpeed<1 then currentSpeed=0 end
    if currentSpeed>0 then
        local tv=moveDir*(currentSpeed/45)
        root.AssemblyLinearVelocity=Vector3.new(tv.X,root.AssemblyLinearVelocity.Y,tv.Z)
    end
end
RunService.Heartbeat:Connect(updateVirtualStrafe)
local function resetVirtualStrafe() VirtualStrafeEnabled=false; currentSpeed=0; moveDir=Vector3.new(0,0,0) end

-- =====================================================
-- AUTO TRIMP
-- =====================================================

local AutoTrimpEnabled = false
local TrimpPower = 100
local MinSpeed = 30
local lastTrimp = 0
local trimpCooldown = 0.2

local function DoTrimp()
    if not AutoTrimpEnabled then return end
    local now=tick(); if now-lastTrimp<trimpCooldown then return end
    local char=LocalPlayer.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local vel=hrp.AssemblyLinearVelocity; local speed=Vector3.new(vel.X,0,vel.Z).Magnitude
    if speed<MinSpeed then return end
    if vel.Y>0 then return end
    local result=workspace:Raycast(hrp.Position,Vector3.new(0,-3,0)); if not result then return end
    lastTrimp=now
    hrp.AssemblyLinearVelocity=Vector3.new(vel.X*0.8,TrimpPower,vel.Z*0.8)
end
RunService.Heartbeat:Connect(function() DoTrimp() end)

-- =====================================================
-- EASY BOUNCE
-- =====================================================

local EasyBounceEnabled = false
local EASY_BOUNCE_MAX_HISTORY = 1000
local EASY_BOUNCE_STEP = 1/55
local EASY_BOUNCE_SPEED_MULT = 1.6
local easyBounceLastTime = tick()
local easyBounceHistory = {}
local easyBounceCharacter, easyBounceHrp, easyBounceHumanoid = nil, nil, nil

local function refreshEasyBounceCharacter(char)
    easyBounceCharacter=char or LocalPlayer.Character; easyBounceHrp=nil; easyBounceHumanoid=nil
    if not easyBounceCharacter then return end
    easyBounceHrp=easyBounceCharacter:FindFirstChild("HumanoidRootPart")
    easyBounceHumanoid=easyBounceCharacter:FindFirstChildOfClass("Humanoid")
    easyBounceLastTime=tick()
end

local function simulateEasyBounceStep(dt)
    if not EasyBounceEnabled or not easyBounceHrp or not easyBounceHumanoid then return end
    if easyBounceHumanoid:GetState()~=Enum.HumanoidStateType.Jumping then return end
    local vel=easyBounceHrp.AssemblyLinearVelocity*EASY_BOUNCE_SPEED_MULT
    easyBounceHrp.CFrame=easyBounceHrp.CFrame+vel*dt
end

RunService.Stepped:Connect(function()
    if not EasyBounceEnabled then return end
    if not easyBounceHrp or not easyBounceHrp.Parent or not easyBounceHumanoid or not easyBounceHumanoid.Parent then
        refreshEasyBounceCharacter(LocalPlayer.Character); return
    end
    local now=tick(); local dt=now-easyBounceLastTime; easyBounceLastTime=now
    table.insert(easyBounceHistory,dt); if #easyBounceHistory>EASY_BOUNCE_MAX_HISTORY then table.remove(easyBounceHistory,1) end
    if easyBounceHumanoid:GetState()~=Enum.HumanoidStateType.Jumping then return end
    while dt>EASY_BOUNCE_STEP do simulateEasyBounceStep(EASY_BOUNCE_STEP); dt=dt-EASY_BOUNCE_STEP end
    if dt>0 then simulateEasyBounceStep(dt) end
    local targetPos=easyBounceHrp.Position
    local finalPos=easyBounceHrp.Position+(targetPos-easyBounceHrp.Position)*0.5
    easyBounceHrp.CFrame=CFrame.new(finalPos,easyBounceHrp.CFrame.LookVector+finalPos)
end)

-- =====================================================
-- AIR STRAFE SPEED
-- =====================================================

local AirStrafeSpeedEnabled = false
local AirStrafeSpeedValue = 1500
local AirStrafeAcceleration = 182
local AirStrafeJumpHeight = 3
local AirStrafeOriginals = {Tables={}, Humanoids={}}
local AirStrafeScanned = false
local AirStrafeApplyDebounce = false

local speedProps={"Speed","speed","WalkSpeed","walkSpeed","MoveSpeed","moveSpeed"}
local strafeProps={"AirStrafeAcceleration","airStrafeAcceleration","StrafeAcceleration","strafeAcceleration","AirAcceleration","airAcceleration","StrafeAccel","strafeAccel","AirStrafe","airStrafe","StrafeForce","strafeForce","AirControl","airControl","StrafeControl","strafeControl"}
local jumpProps={"JumpHeight","jumpHeight","JumpPower","jumpPower","JumpForce","jumpForce","JumpVelocity","jumpVelocity"}

local function rememberAirStrafeTableValue(tbl,prop)
    local saved=AirStrafeOriginals.Tables[tbl]
    if not saved then saved={}; AirStrafeOriginals.Tables[tbl]=saved end
    if saved[prop]==nil then saved[prop]=rawget(tbl,prop) end
end

local function applyToKnownTables()
    for tbl,props in pairs(AirStrafeOriginals.Tables) do
        if type(tbl)=="table" then
            pcall(function()
                for prop,_ in pairs(props) do
                    local current=rawget(tbl,prop)
                    if current~=nil and type(current)=="number" then
                        local isSpeed,isStrafe,isJump=false,false,false
                        for _,sp in ipairs(speedProps) do if sp==prop then isSpeed=true; break end end
                        if not isSpeed then for _,sp in ipairs(strafeProps) do if sp==prop then isStrafe=true; break end end end
                        if not isSpeed and not isStrafe then for _,sp in ipairs(jumpProps) do if sp==prop then isJump=true; break end end end
                        if isSpeed then rawset(tbl,prop,AirStrafeSpeedValue)
                        elseif isStrafe then rawset(tbl,prop,AirStrafeAcceleration)
                        elseif isJump then rawset(tbl,prop,AirStrafeJumpHeight) end
                    end
                end
            end)
        end
    end
end

local function applyMovementTableValues(tbl)
    local cnt=0
    local function tryProps(list, val)
        for _,prop in pairs(list) do
            local v=rawget(tbl,prop)
            if v~=nil and type(v)=="number" then rememberAirStrafeTableValue(tbl,prop); rawset(tbl,prop,val); cnt=cnt+1 end
        end
    end
    tryProps(speedProps,AirStrafeSpeedValue); tryProps(strafeProps,AirStrafeAcceleration); tryProps(jumpProps,AirStrafeJumpHeight)
    return cnt
end

local function applyAirStrafeToHumanoid(humanoid)
    if not AirStrafeOriginals.Humanoids[humanoid] then
        AirStrafeOriginals.Humanoids[humanoid]={WalkSpeed=humanoid.WalkSpeed,JumpPower=humanoid.JumpPower,JumpHeight=humanoid.JumpHeight}
    end
    humanoid.WalkSpeed=AirStrafeSpeedValue/50; humanoid.JumpPower=AirStrafeJumpHeight*30
end

local function updateAirStrafeValues()
    if not AirStrafeSpeedEnabled then return end
    if AirStrafeApplyDebounce then return end
    AirStrafeApplyDebounce=true
    task.defer(function()
        AirStrafeApplyDebounce=false
        if not AirStrafeSpeedEnabled then return end
        applyToKnownTables()
        pcall(function()
            local character=LocalPlayer.Character
            if character then
                local humanoid=character:FindFirstChildOfClass("Humanoid")
                if humanoid then applyAirStrafeToHumanoid(humanoid) end
            end
        end)
    end)
end

local function applyAirStrafeModifications()
    local cnt=0
    if not AirStrafeScanned then
        AirStrafeScanned=true
        pcall(function()
            if type(getgc)~="function" then return end
            local gcObjects=getgc(true); if not gcObjects then return end
            for i=1,#gcObjects do
                local obj=gcObjects[i]
                if type(obj)=="table" then cnt=cnt+applyMovementTableValues(obj) end
            end
        end)
        pcall(function()
            for _,obj in pairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("ModuleScript") then
                    pcall(function()
                        local module=require(obj)
                        if type(module)=="table" then cnt=cnt+applyMovementTableValues(module) end
                    end)
                end
            end
        end)
    else
        applyToKnownTables()
    end
    pcall(function()
        local character=LocalPlayer.Character
        if character then
            local humanoid=character:FindFirstChildOfClass("Humanoid")
            if humanoid then applyAirStrafeToHumanoid(humanoid); cnt=cnt+2 end
        end
    end)
    return cnt
end

local function restoreAirStrafeModifications()
    for tbl,props in pairs(AirStrafeOriginals.Tables) do
        if type(tbl)=="table" then for prop,orig in pairs(props) do pcall(function() rawset(tbl,prop,orig) end) end end
    end
    for humanoid,saved in pairs(AirStrafeOriginals.Humanoids) do
        if humanoid and humanoid.Parent then
            pcall(function() humanoid.WalkSpeed=saved.WalkSpeed or 16; humanoid.JumpPower=saved.JumpPower or 50 end)
        end
    end
    AirStrafeOriginals.Tables={}; AirStrafeOriginals.Humanoids={}; AirStrafeScanned=false
    notify("Air Strafe Speed disabled",3)
end

-- =====================================================
-- Y-LOCK SURF
-- =====================================================

local YLockSurfEnabled = false
local YLockSurfMode = "Toggle"
local YLockSurfKey = Enum.KeyCode.X
local isYLocked = false
local lockedY = nil
local originalHipHeight = nil

local function LockYPosition()
    local char=LocalPlayer.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    lockedY=hrp.Position.Y
    local hum=char:FindFirstChildOfClass("Humanoid"); if hum then originalHipHeight=hum.HipHeight end
    isYLocked=true
end
local function UnlockYPosition()
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum and originalHipHeight then hum.HipHeight=originalHipHeight end
    isYLocked=false; lockedY=nil; originalHipHeight=nil
end
local function MaintainYLock()
    if not isYLocked then return end
    local char=LocalPlayer.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp or not lockedY then return end
    local cp=hrp.Position; local cv=hrp.AssemblyLinearVelocity
    if math.abs(cp.Y-lockedY)>0.1 then hrp.Position=Vector3.new(cp.X,lockedY,cp.Z); hrp.AssemblyLinearVelocity=Vector3.new(cv.X,0,cv.Z)
    else hrp.AssemblyLinearVelocity=Vector3.new(cv.X,0,cv.Z) end
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
    local character=LocalPlayer.Character; if not character then return nil end
    local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local rp=RaycastParams.new(); rp.FilterDescendantsInstances={character}; rp.FilterType=Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(hrp.Position,direcao*(distancia+2.5),rp)
end

local function updateFlyVelocity()
    local character=LocalPlayer.Character; if not character then return end
    local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local bv=hrp:FindFirstChild("FlyVelocity")
    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        if not bv then bv=Instance.new("BodyVelocity"); bv.Name="FlyVelocity"; bv.MaxForce=Vector3.new(0,0,0); bv.Velocity=Vector3.new(0,0,0); bv.Parent=hrp end
        executando=true
    else
        if bv then bv:Destroy() end
        executando=false; subindoQ=false; descendoCTRL=false; vAtualSubida=0; vAtualDescida=0; vFinal=0
    end
end

local crouchConnections = {}
local function clearCrouchConnections()
    for _,conn in ipairs(crouchConnections) do pcall(function() conn:Disconnect() end) end
    crouchConnections={}
end
local function startCrouchDetect()
    clearCrouchConnections()
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local baseHipHeight=hum.HipHeight; local baseWalkSpeed=hum.WalkSpeed
    table.insert(crouchConnections, hum:GetPropertyChangedSignal("HipHeight"):Connect(function()
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end
        if hum.HipHeight<baseHipHeight-0.05 then descendoCTRL=true; vAtualDescida=0 else descendoCTRL=false; vAtualDescida=0; emEstadoDeBounce=false end
    end))
    table.insert(crouchConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end
        if hum.WalkSpeed<baseWalkSpeed*0.6 then descendoCTRL=true; vAtualDescida=0 else descendoCTRL=false; vAtualDescida=0; emEstadoDeBounce=false end
    end))
    table.insert(crouchConnections, hum.StateChanged:Connect(function(_,newState)
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end
        if newState==Enum.HumanoidStateType.Seated then descendoCTRL=true; vAtualDescida=0
        elseif newState==Enum.HumanoidStateType.Running or newState==Enum.HumanoidStateType.Jumping or newState==Enum.HumanoidStateType.Freefall then descendoCTRL=false; vAtualDescida=0; emEstadoDeBounce=false end
    end))
end

-- =====================================================
-- KEYBOARD SOUND
-- =====================================================

local baseSound=Instance.new("Sound",SoundService); baseSound.SoundId="rbxassetid://4724428597"; baseSound.Volume=1; baseSound.PlaybackSpeed=0.95
local baseSound2=Instance.new("Sound",SoundService); baseSound2.SoundId="rbxassetid://125027148509088"; baseSound2.Volume=1; baseSound2.PlaybackSpeed=0.95

local function playKeyboardSound()
    if not Settings.keyboardSoundEnabled then return end
    local s=(math.random(1,100)<=50 and baseSound2 or baseSound):Clone()
    s.Parent=SoundService; s.PlaybackSpeed=0.9+(math.random()*0.2); s.Volume=0.9+(math.random()*0.3)
    s:Play(); s.Ended:Connect(function() s:Destroy() end)
end

-- =====================================================
-- AVATAR COSMETICS
-- =====================================================

local K_MESH_ID=101851696; local K_OVERLAY_ID=101851254; local K_COLOR=Color3.fromRGB(38,65,68)
local KORBLOX_COLOR_ATTR="MWOriginalKorbloxLegColor"; local KORBLOX_MATERIAL_ATTR="MWOriginalKorbloxLegMaterial"; local KORBLOX_TRANSPARENCY_ATTR="MWOriginalKorbloxLegTransparency"; local HEADLESS_TRANSPARENCY_ATTR="MWOriginalHeadlessTransparency"
local avatarCosmeticRetryToken = 0

local function applyDeepWineLogic(target, customColor)
    if not target then return end
    local mainCol=customColor or WINE_CONFIG.TrueWine
    local skinParts={Head=true,Torso=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,LeftUpperArm=true,RightUpperArm=true,LeftLowerArm=true,RightLowerArm=true,LeftHand=true,RightHand=true,LeftUpperLeg=true,RightUpperLeg=true,LeftLowerLeg=true,RightLowerLeg=true,LeftFoot=true,RightFoot=true,UpperTorso=true,LowerTorso=true}
    for _,obj in pairs(target:GetDescendants()) do
        if obj:IsA("BasePart") and (skinParts[obj.Name] or obj.Name=="HumanoidRootPart") then continue end
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            obj.Color=mainCol; obj.Material=WINE_CONFIG.Material
            if obj:IsA("MeshPart") then obj.TextureID="" end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,mainCol),ColorSequenceKeypoint.new(1,WINE_CONFIG.BlackWine)})
        end
    end
end

local function getKorbloxRightLeg(char)
    if not char then return nil end
    return char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("RightUpperLeg")
end

local function saveKorbloxLegOriginals(char,rLeg)
    if not char or not rLeg then return end
    if rLeg:GetAttribute(KORBLOX_COLOR_ATTR)==nil then local sc=char:GetAttribute("OriginalLegColor") or rLeg.Color; rLeg:SetAttribute(KORBLOX_COLOR_ATTR,sc); char:SetAttribute("OriginalLegColor",sc) end
    if rLeg:GetAttribute(KORBLOX_MATERIAL_ATTR)==nil then rLeg:SetAttribute(KORBLOX_MATERIAL_ATTR,rLeg.Material.Name) end
    if rLeg:GetAttribute(KORBLOX_TRANSPARENCY_ATTR)==nil then rLeg:SetAttribute(KORBLOX_TRANSPARENCY_ATTR,rLeg.Transparency) end
end

local function applyKorblox(char)
    if not char or not Settings.KorbloxEnabled then return false end
    local rLeg=getKorbloxRightLeg(char); if not rLeg then return false end
    saveKorbloxLegOriginals(char,rLeg)
    local rLegMesh=char:FindFirstChild("KorbloxMesh") or Instance.new("CharacterMesh")
    rLegMesh.Name="KorbloxMesh"; rLegMesh.BodyPart=Enum.BodyPart.RightLeg; rLegMesh.MeshId=K_MESH_ID; rLegMesh.BaseTextureId=0; rLegMesh.OverlayTextureId=K_OVERLAY_ID; rLegMesh.Parent=char
    for _,v in ipairs(rLeg:GetChildren()) do if v:IsA("SpecialMesh") then v:Destroy() end end
    rLeg.Color=K_COLOR; rLeg.Transparency=0; rLeg.Material=Enum.Material.Plastic
    return true
end

local function removeKorblox(char)
    if not char then return false end
    local mesh=char:FindFirstChild("KorbloxMesh"); if mesh then mesh:Destroy() end
    local rLeg=getKorbloxRightLeg(char)
    if rLeg then
        local oc=rLeg:GetAttribute(KORBLOX_COLOR_ATTR) or char:GetAttribute("OriginalLegColor")
        if oc then rLeg.Color=oc else rLeg.Color=Color3.fromRGB(163,162,165) end
        local om=rLeg:GetAttribute(KORBLOX_MATERIAL_ATTR); if om and Enum.Material[om] then rLeg.Material=Enum.Material[om] else rLeg.Material=Enum.Material.Plastic end
        local ot=rLeg:GetAttribute(KORBLOX_TRANSPARENCY_ATTR); rLeg.Transparency=type(ot)=="number" and ot or 0
        rLeg:SetAttribute(KORBLOX_COLOR_ATTR,nil); rLeg:SetAttribute(KORBLOX_MATERIAL_ATTR,nil); rLeg:SetAttribute(KORBLOX_TRANSPARENCY_ATTR,nil)
    end
    char:SetAttribute("OriginalLegColor",nil); return true
end

local function saveOriginalTransparency(obj)
    if obj and obj:GetAttribute(HEADLESS_TRANSPARENCY_ATTR)==nil then obj:SetAttribute(HEADLESS_TRANSPARENCY_ATTR,obj.Transparency) end
end
local function applyHeadless(char)
    if not char or not Settings.HeadlessEnabled then return false end
    local head=char:FindFirstChild("Head"); if not head then return false end
    saveOriginalTransparency(head); head.Transparency=1
    for _,obj in ipairs(head:GetDescendants()) do if obj:IsA("Decal") or obj:IsA("Texture") then saveOriginalTransparency(obj); obj.Transparency=1 end end
    return true
end
local function removeHeadless(char)
    if not char then return false end
    local head=char:FindFirstChild("Head"); if not head then return false end
    local ot=head:GetAttribute(HEADLESS_TRANSPARENCY_ATTR); head.Transparency=type(ot)=="number" and ot or 0; head:SetAttribute(HEADLESS_TRANSPARENCY_ATTR,nil)
    for _,obj in ipairs(head:GetDescendants()) do if obj:IsA("Decal") or obj:IsA("Texture") then local od=obj:GetAttribute(HEADLESS_TRANSPARENCY_ATTR); obj.Transparency=type(od)=="number" and od or 0; obj:SetAttribute(HEADLESS_TRANSPARENCY_ATTR,nil) end end
    return true
end

local function applyAvatarCosmeticsWithRetries(char)
    avatarCosmeticRetryToken=avatarCosmeticRetryToken+1; local token=avatarCosmeticRetryToken
    task.spawn(function()
        for _=1,16 do
            if token~=avatarCosmeticRetryToken then return end
            if not char or char~=LocalPlayer.Character then return end
            if Settings.HeadlessEnabled then applyHeadless(char) end
            if Settings.KorbloxEnabled then applyKorblox(char) end
            task.wait(0.35)
        end
    end)
end

local NonMovableEmoteHopEnabled = false
local NonMovableEmoteOriginals = {}
local function applyNonMovableEmoteHop()
    local EmotesFolder=ReplicatedStorage:WaitForChild("Items"):WaitForChild("Emotes"); local fixedCount=0
    for _,module in pairs(EmotesFolder:GetDescendants()) do
        if module:IsA("ModuleScript") then
            local success,emoteData=pcall(require,module)
            if success and type(emoteData)=="table" and emoteData["EmoteInfo"] then
                local emoteInfo=emoteData["EmoteInfo"]
                if type(emoteInfo)=="table" and emoteInfo["SpeedMult"]==0 then
                    if NonMovableEmoteOriginals[emoteInfo]==nil then NonMovableEmoteOriginals[emoteInfo]=emoteInfo["SpeedMult"] end
                    emoteInfo["SpeedMult"]=1; fixedCount=fixedCount+1
                end
            end
        end
    end
    return fixedCount
end
local function restoreNonMovableEmoteHop()
    for emoteInfo,speedMult in pairs(NonMovableEmoteOriginals) do if type(emoteInfo)=="table" then pcall(function() emoteInfo["SpeedMult"]=speedMult end) end end
    NonMovableEmoteOriginals={}
end

local function loadVFX() end
local lastFP = nil
local function updateVFXFirstPerson(char)
    if not char then return end
    local head=char:FindFirstChild("Head"); if not head or not camera then return end
    local dist=(camera.CFrame.Position-head.Position).Magnitude
    local isFP=(dist<0.8) or (LocalPlayer.CameraMode==Enum.CameraMode.LockFirstPerson)
    if isFP~=lastFP then
        lastFP=isFP
        for _,fx in ipairs(_G.vfxAttachments) do if fx and fx.Parent and fx.Enabled~=nil then fx.Enabled=not isFP end end
    end
end

-- =====================================================
-- INVIS WALL
-- =====================================================

local originalState = {}
local function updateInvisWall(v)
    Settings.InvisWallEnabled=v
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency>=0.5 and obj.Size.Magnitude>=12 then
            if v then if originalState[obj]==nil then originalState[obj]=obj.CanCollide end; obj.CanCollide=false
            else if originalState[obj]~=nil then obj.CanCollide=originalState[obj] end end
        end
    end
end

-- =====================================================
-- MOBILE EDGE
-- =====================================================

local setupMobileEdge
;(function()
local mobileEdgeTouchConn = nil
setupMobileEdge = function(char)
    if mobileEdgeTouchConn then mobileEdgeTouchConn:Disconnect(); mobileEdgeTouchConn=nil end
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart",5)
    if not hrp then return end
    mobileEdgeTouchConn=hrp.Touched:Connect(function(hit)
        if not Settings.MobileEdgeEnabled then return end
        if not hit or not hit:IsA("BasePart") then return end
        local currentChar=LocalPlayer.Character; local currentRoot=currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if currentRoot and currentRoot.AssemblyLinearVelocity.Y<-1.0 then
            local name=hit.Name:lower()
            if name:find("bounce") or name:find("boost") then return end
            currentRoot.AssemblyLinearVelocity=Vector3.new(currentRoot.AssemblyLinearVelocity.X,Settings.EdgePower,currentRoot.AssemblyLinearVelocity.Z)
        end
    end)
end
end)()

-- =====================================================
-- FOV
-- =====================================================

local fovSignalConn = nil
local originalFOV = nil
local function enforceFOV()
    camera=Workspace.CurrentCamera
    if camera then
        if Settings.FOVEnabled then
            if originalFOV==nil then originalFOV=camera.FieldOfView end
            if camera.FieldOfView~=Settings.FOV then camera.FieldOfView=Settings.FOV end
        else
            if originalFOV and camera.FieldOfView~=originalFOV then camera.FieldOfView=originalFOV end
        end
    end
end
local function hookCameraFOVSignal(cam)
    if fovSignalConn then fovSignalConn:Disconnect(); fovSignalConn=nil end
    if cam then fovSignalConn=cam:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFOV) end
end
hookCameraFOVSignal(camera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() hookCameraFOVSignal(Workspace.CurrentCamera) end)

-- =====================================================
-- SPEED CHANGERS
-- =====================================================

local LegacySpeedEnabled = false
local RealSpeedOverride = 1500
local legacySpeedConns = {}
local function stopLegacySpeed()
    LegacySpeedEnabled=false
    if legacySpeedConns.CharAdded then legacySpeedConns.CharAdded:Disconnect() end
    if legacySpeedConns.Loop then legacySpeedConns.Loop:Disconnect() end
    legacySpeedConns={}
end
local function applyLegacySpeedToCharacter(char)
    local hum=char and char:FindFirstChildOfClass("Humanoid") or (char and char:WaitForChild("Humanoid",5))
    if not hum then return end
    hum:SetAttribute("RealSpeed",RealSpeedOverride)
    hum:GetAttributeChangedSignal("RealSpeed"):Connect(function() if LegacySpeedEnabled and hum:GetAttribute("RealSpeed")~=RealSpeedOverride then hum:SetAttribute("RealSpeed",RealSpeedOverride) end end)
end
local function startLegacySpeed()
    if legacySpeedConns.CharAdded then legacySpeedConns.CharAdded:Disconnect() end
    legacySpeedConns.CharAdded=LocalPlayer.CharacterAdded:Connect(function(char) applyLegacySpeedToCharacter(char) end)
    if LocalPlayer.Character then applyLegacySpeedToCharacter(LocalPlayer.Character) end
    if legacySpeedConns.Loop then legacySpeedConns.Loop:Disconnect() end
    legacySpeedConns.Loop=RunService.Heartbeat:Connect(function()
        if not LegacySpeedEnabled then return end
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetAttribute("RealSpeed")~=RealSpeedOverride then hum:SetAttribute("RealSpeed",RealSpeedOverride) end
    end)
end

local OverhaulSpeedBoosterEnabled = false
local OverhaulSpeedValue = 2000
local OverhaulSpeedOriginals = setmetatable({},{__mode="k"})
local overhaulSpeedCharConn = nil
local function getOverhaulMovementInstances()
    local movementInstances={}
    if type(getgc)~="function" then return movementInstances end
    local success,gcObjects=pcall(function() return getgc(true) end)
    if not success or type(gcObjects)~="table" then return movementInstances end
    for _,obj in pairs(gcObjects) do if type(obj)=="table" and rawget(obj,"defaultMovementStats") then table.insert(movementInstances,obj) end end
    return movementInstances
end
local function rememberOverhaulSpeed(stats)
    if OverhaulSpeedOriginals[stats]~=nil then return end
    OverhaulSpeedOriginals[stats]={HadValue=rawget(stats,"Speed")~=nil, Value=rawget(stats,"Speed")}
end
local function applyOverhaulSpeedBooster()
    if not OverhaulSpeedBoosterEnabled then return 0 end
    local cnt=0
    for _,instance in ipairs(getOverhaulMovementInstances()) do
        local stats=rawget(instance,"overrideMovementStats") or instance.overrideMovementStats
        if type(stats)=="table" then rememberOverhaulSpeed(stats); rawset(stats,"Speed",OverhaulSpeedValue); cnt=cnt+1 end
    end
    return cnt
end
local function startOverhaulSpeedRespawnHook()
    if overhaulSpeedCharConn then overhaulSpeedCharConn:Disconnect() end
    overhaulSpeedCharConn=LocalPlayer.CharacterAdded:Connect(function() task.wait(1.5); applyOverhaulSpeedBooster() end)
end
local function restoreOverhaulSpeedBooster()
    if overhaulSpeedCharConn then overhaulSpeedCharConn:Disconnect(); overhaulSpeedCharConn=nil end
    for stats,saved in pairs(OverhaulSpeedOriginals) do
        if type(stats)=="table" then pcall(function() if saved.HadValue then rawset(stats,"Speed",saved.Value) else rawset(stats,"Speed",nil) end end) end
    end
    OverhaulSpeedOriginals=setmetatable({},{__mode="k"})
end

-- =====================================================
-- HITBOX CREATOR
-- =====================================================

local hitboxCreatorEnabled=false; local hitboxSizeX=5; local hitboxSizeY=5; local hitboxSizeZ=5
local hitboxTransparency=0.9; local hitboxCanCollide=true; local hitboxMouseConnection=nil
local activeHitboxes={}; local selectedHitbox=nil; local hitboxMoveStep=1

local function hitboxIsActive(hb) return hb and hb.Parent~=nil end
local function updateHitboxSelectionVisuals()
    for _,hb in ipairs(activeHitboxes) do if hitboxIsActive(hb) then hb.Color=hb==selectedHitbox and Color3.fromRGB(255,220,70) or Color3.fromRGB(0,255,0) end end
end
local function selectHitbox(hb)
    if not hitboxIsActive(hb) then selectedHitbox=nil; updateHitboxSelectionVisuals(); return nil end
    local known=false; for _,a in ipairs(activeHitboxes) do if a==hb then known=true; break end end
    if not known then table.insert(activeHitboxes,hb) end
    selectedHitbox=hb; updateHitboxSelectionVisuals(); return selectedHitbox
end
local function getSelectedHitbox()
    if hitboxIsActive(selectedHitbox) then return selectedHitbox end
    selectedHitbox=nil; for i=#activeHitboxes,1,-1 do if hitboxIsActive(activeHitboxes[i]) then return selectHitbox(activeHitboxes[i]) end end
    return nil
end
local function selectLastHitbox() selectedHitbox=nil; for i=#activeHitboxes,1,-1 do if hitboxIsActive(activeHitboxes[i]) then return selectHitbox(activeHitboxes[i]) end end; updateHitboxSelectionVisuals(); return nil end
local function applyHitboxPropertiesToSelected(silent)
    local hb=getSelectedHitbox(); if not hb then if not silent then notify("No hitbox selected.",2) end; return false end
    hb.Size=Vector3.new(math.max(hitboxSizeX,0.1),math.max(hitboxSizeY,0.1),math.max(hitboxSizeZ,0.1)); hb.Transparency=hitboxTransparency; hb.CanCollide=hitboxCanCollide; return true
end
local function moveSelectedHitbox(offset)
    local hb=getSelectedHitbox(); if not hb then notify("No hitbox selected.",2); return false end; hb.CFrame=hb.CFrame+offset; return true
end
local function createHitboxAtPosition(position)
    local hb=Instance.new("Part"); hb.Name="CustomHitbox"; hb.Size=Vector3.new(hitboxSizeX,hitboxSizeY,hitboxSizeZ); hb.Transparency=hitboxTransparency; hb.CanCollide=hitboxCanCollide; hb.Anchored=true; hb.Material=Enum.Material.SmoothPlastic; hb.Color=Color3.fromRGB(0,255,0); hb.Position=position; hb.Parent=Workspace
    table.insert(activeHitboxes,hb); selectHitbox(hb); return hb
end
local function removeAllHitboxes() for _,hb in ipairs(activeHitboxes) do if hb and hb.Parent then hb:Destroy() end end; activeHitboxes={}; selectedHitbox=nil end
local function removeSelectedHitbox() local hb=getSelectedHitbox(); if not hb then notify("No hitbox selected.",2); return end; hb:Destroy(); selectedHitbox=nil; getSelectedHitbox() end
local function enableHitboxSelection()
    if hitboxMouseConnection then hitboxMouseConnection:Disconnect() end
    hitboxMouseConnection=LocalPlayer:GetMouse().Button1Down:Connect(function()
        if hitboxCreatorEnabled then
            local mouse=LocalPlayer:GetMouse()
            if mouse.Target then
                if mouse.Target.Name=="CustomHitbox" then selectHitbox(mouse.Target); notify("Selected hitbox.",2)
                else createHitboxAtPosition(mouse.Hit.Position); notify("Created hitbox.",2) end
            end
        end
    end)
end
local function disableHitboxSelection() if hitboxMouseConnection then hitboxMouseConnection:Disconnect(); hitboxMouseConnection=nil end end

-- =====================================================
-- TAS
-- =====================================================

local TAS_Running=false; local TAS_Frames={}; local TAS_TimeStart=tick(); local TAS_IsRecording=false; local TAS_IsPlaying=false
local TAS_Keybinds={StartRecord="F1",StopRecord="F2",PlayTAS="F3",ClearFrames="F4"}

local function TAS_getChar() local c=LocalPlayer.Character; if c then return c end; LocalPlayer.CharacterAdded:Wait(); return TAS_getChar() end

local function TAS_StartRecord()
    if TAS_IsRecording or TAS_IsPlaying then return end
    TAS_Frames={}; TAS_Running=true; TAS_IsRecording=true; TAS_TimeStart=tick()
    notify("TAS Recording started...",2)
    task.spawn(function()
        while TAS_Running do
            RunService.Heartbeat:Wait()
            local c=TAS_getChar()
            if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then
                table.insert(TAS_Frames,{c.HumanoidRootPart.CFrame, c.Humanoid:GetState().Value, tick()-TAS_TimeStart})
            end
        end
        TAS_IsRecording=false; notify("TAS Recording stopped. Frames: "..#TAS_Frames,3)
    end)
end
local function TAS_StopRecord() TAS_Running=false; TAS_IsRecording=false; notify("TAS Recording stopped. Frames: "..#TAS_Frames,3) end
local function TAS_PlayTAS()
    if TAS_IsPlaying or TAS_IsRecording then return end
    if #TAS_Frames==0 then notify("No frames to play!",3); return end
    TAS_IsPlaying=true; local c=TAS_getChar(); local TimePlay=tick(); local FrameCount=#TAS_Frames; local OldFrame=1; local TASLoop
    notify("Playing TAS...",2)
    TASLoop=RunService.Heartbeat:Connect(function()
        local CT=tick()
        if (CT-TimePlay)>=TAS_Frames[FrameCount][3] then TASLoop:Disconnect(); TAS_IsPlaying=false; notify("TAS Playback complete!",3); return end
        local NF=math.min(OldFrame+60,FrameCount)
        for i=OldFrame,NF do
            local f=TAS_Frames[i]
            if f and f[3]<=CT-TimePlay then OldFrame=i; if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then c.HumanoidRootPart.CFrame=f[1]; c.Humanoid:ChangeState(f[2]) end end
        end
    end)
end
local function TAS_ClearFrames() if TAS_IsRecording or TAS_IsPlaying then return end; TAS_Frames={}; notify("TAS Frames cleared!",2) end

UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode.Name==TAS_Keybinds.StartRecord then TAS_StartRecord()
    elseif input.KeyCode.Name==TAS_Keybinds.StopRecord then TAS_StopRecord()
    elseif input.KeyCode.Name==TAS_Keybinds.PlayTAS then TAS_PlayTAS()
    elseif input.KeyCode.Name==TAS_Keybinds.ClearFrames then TAS_ClearFrames() end
end)

-- =====================================================
-- MAP LOADER
-- =====================================================

local function setSunriseSky()
    for _,obj in pairs(Lighting:GetChildren()) do if obj:IsA("Sky") or obj:IsA("Atmosphere") then obj:Destroy() end end
    local sky=Instance.new("Sky",Lighting); sky.SkyboxBk="rbxassetid://252760981"; sky.SkyboxDn="rbxassetid://252763921"; sky.SkyboxFt="rbxassetid://252761439"; sky.SkyboxLf="rbxassetid://252761439"; sky.SkyboxRt="rbxassetid://252761439"; sky.SkyboxUp="rbxassetid://252762708"; sky.SunAngularSize=25
    Lighting.ClockTime=6.3; Lighting.Brightness=2.5; Lighting.OutdoorAmbient=Color3.fromRGB(160,120,100); Lighting.ExposureCompensation=0.5
    local atm=Instance.new("Atmosphere",Lighting); atm.Density=0.25; atm.Color=Color3.fromRGB(255,200,160); atm.Glare=0.4
end

local function loadMapByAssetId(mapAssetID)
    local character=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart=character:WaitForChild("HumanoidRootPart")
    local assetID=stripAssetPrefix(mapAssetID)
    local ScaleFactor=Settings.MapScale; local SpawnHeight=Settings.SpawnHeight
    for _,old in pairs(Workspace:GetChildren()) do if old.Name=="Injected_System" then old:Destroy() end end
    setSunriseSky()
    local success,err=pcall(function()
        local objects=game:GetObjects(string.format("rbxassetid://%s",assetID))
        local mapModel=objects[1]; if not mapModel then return end
        if not mapModel:IsA("Model") then local folder=Instance.new("Model",Workspace); mapModel.Parent=folder; mapModel=folder end
        mapModel.Name="Injected_System"; mapModel.Parent=Workspace; mapModel:ScaleTo(mapModel:GetScale()*ScaleFactor)
        for _,part in pairs(mapModel:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Transparency>=1 and part.CanCollide then part.CanCollide=false end
                if part.CanCollide then part.CustomPhysicalProperties=PhysicalProperties.new(0.7,0,1,0.5,1) end
            end
        end
        local targetPos=Vector3.new(rootPart.Position.X,SpawnHeight,rootPart.Position.Z)
        mapModel:MoveTo(targetPos); task.wait(0.6); rootPart.CFrame=mapModel:GetPivot()+Vector3.new(0,20,0)
        notify(string.format("Map loaded. Scale: %s",tostring(ScaleFactor)),3)
    end)
    if not success then warn(err); notify("Map load failed: "..tostring(err),4) end
end

local CustomMaps = {
    {Name="NN_Russia",URL="https://pastebin.com/raw/rSHkiSEn",Loaded=false},{Name="NN_Outpost",URL="https://pastebin.com/raw/HyKrhP2q",Loaded=false},
    {Name="NN_Shibuya",URL="https://pastebin.com/raw/AXrhwppi",Loaded=false},{Name="NN_Mall",URL="https://pastebin.com/raw/R7A87x4X",Loaded=false},
    {Name="NN_Crossroads",URL="https://pastebin.com/raw/uyM0bSWA",Loaded=false},{Name="NN_BigMaze",URL="https://pastebin.com/raw/dfKM1K6a",Loaded=false},
    {Name="NN_LostRuins",URL="https://pastebin.com/raw/j6a5Jvng",Loaded=false},{Name="NN_HappyHome",URL="https://pastebin.com/raw/vbqhXNmc",Loaded=false},
    {Name="FrostYear Peaks",URL="https://pastebin.com/raw/XGUte0ZP",Loaded=false},{Name="Plague Square",URL="https://pastebin.com/raw/8MTaq8KW",Loaded=false}
}
local function loadCustomMap(mapData)
    if mapData.Loaded then notify(mapData.Name.." already loaded.",2); return end
    notify("Loading "..mapData.Name.."...",2)
    local success,err=pcall(function() loadstring(game:HttpGet(mapData.URL))() end)
    if success then mapData.Loaded=true; notify(mapData.Name.." loaded.",3) else notify("Failed: "..mapData.Name,4) end
end

-- =====================================================
-- INPUT & RENDER LOOPS
-- =====================================================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    pcall(function()
        if YLockSurfEnabled and (input.KeyCode==YLockSurfKey) then
            if YLockSurfMode=="Toggle" then if isYLocked then UnlockYPosition() else LockYPosition() end
            else LockYPosition() end
        end
    end)
    if executando then
        pcall(function()
            if input.KeyCode==Enum.KeyCode.Q then subindoQ=not subindoQ
            elseif input.KeyCode==Enum.KeyCode.LeftControl then descendoCTRL=true; vAtualDescida=0 end
        end)
    end
    pcall(function()
        if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Space then playKeyboardSound() end
    end)
end)

UserInputService.InputEnded:Connect(function(input)
    pcall(function()
        if YLockSurfEnabled and YLockSurfMode=="Hold" and input.KeyCode==YLockSurfKey then UnlockYPosition() end
    end)
    if not executando then return end
    pcall(function()
        if input.KeyCode==Enum.KeyCode.LeftControl then descendoCTRL=false; vAtualDescida=0; emEstadoDeBounce=false end
    end)
end)

RunService.RenderStepped:Connect(function(dt)
    local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    enforceFOV(); updateVFXFirstPerson(char)
    if Settings.KorbloxEnabled then local rLeg=getKorbloxRightLeg(char); if rLeg and rLeg.Color~=K_COLOR then rLeg.Color=K_COLOR end end
    if Settings.SpinEnabled then hrp.CFrame=hrp.CFrame*CFrame.Angles(0,(2*math.pi/0.3)*dt,0) end
    if Settings.TurnEnabled then hrp.CFrame=hrp.CFrame*CFrame.Angles(0,(20*math.pi/math.max(Settings.TurnSpeed,0.001))*dt,0) end
    if Settings.TrimpEnabled and hrp.AssemblyLinearVelocity.Y<-1.0 then if #hrp:GetTouchingParts()>0 then hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,95,hrp.AssemblyLinearVelocity.Z) end end
    if YLockSurfEnabled then MaintainYLock() end
    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        local bv=hrp:FindFirstChild("FlyVelocity")
        if bv then
            if not executando then bv.MaxForce=Vector3.new(0,0,0)
            else
                if subindoQ or descendoCTRL or math.abs(vFinal)>0.1 then bv.MaxForce=Vector3.new(0,9e6,0) else bv.MaxForce=Vector3.new(0,0,0) end
                if descendoCTRL then
                    if vAtualSubida>0 then vAtualSubida=vAtualSubida-(aceleracaoSubida*1.5*dt); if vAtualSubida<0 then vAtualSubida=0 end; vFinal=vAtualSubida
                    else
                        local chao=detectaObjeto(Vector3.new(0,-1,0),distanciaChaoBounce)
                        if chao and not emEstadoDeBounce then emEstadoDeBounce=true; vAtualDescida=-forcaBounce end
                        if emEstadoDeBounce then vAtualDescida=vAtualDescida+(Workspace.Gravity*dt); if vAtualDescida>=0 then emEstadoDeBounce=false end
                        else if vAtualDescida<velocidadeDescidaMax then vAtualDescida=vAtualDescida+(aceleracaoDescida*dt) end end
                        vFinal=-vAtualDescida
                    end
                elseif subindoQ then
                    local teto=detectaObjeto(Vector3.new(0,1,0),distanciaTeto)
                    if teto then vAtualSubida=0 else if vAtualSubida<velocidadeSubidaAlvo then vAtualSubida=vAtualSubida+(aceleracaoSubida*dt) end end
                    vFinal=vAtualSubida
                else
                    vAtualSubida=math.max(0,vAtualSubida-(aceleracaoSubida*dt)); vAtualDescida=math.max(0,vAtualDescida-(aceleracaoDescida*dt))
                    vFinal=vAtualSubida-vAtualDescida
                end
                local jitterY=(subindoQ and not descendoCTRL) and (math.random()-0.5)*jitterVelocidade or 0
                bv.Velocity=Vector3.new(0,vFinal+jitterY,0)
                if subindoQ and not descendoCTRL and vFinal>0 then hrp.CFrame=hrp.CFrame*CFrame.new(Vector3.new((math.random()-0.5)*intensidadeTremor,(math.random()-0.5)*intensidadeTremor,(math.random()-0.5)*intensidadeTremor)) end
            end
        end
    end
end)

task.spawn(function()
    while true do
        if Settings.FFlagEnabled then pcall(function() setfflag("MaxMissedWorldStepsRemembered","1000") end) end
        task.wait(1)
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    isYLocked=false; lockedY=nil; originalHipHeight=nil; resetVirtualStrafe()
    if EasyBounceEnabled then refreshEasyBounceCharacter(char) end
    setupMobileEdge(char)
    if Settings.HeadlessEnabled or Settings.KorbloxEnabled then applyAvatarCosmeticsWithRetries(char) end
    if Settings.VFXEnabled then _G.vfxAttachments={}; loadVFX() end
    if Settings.AutoApplyCosmetic then applyDeepWineLogic(char) end
    if Settings.AutoApplyGlobalColor and globalColorEnabled then task.wait(0.5); applyGlobalColor() end
    if Settings.AutoApplySkyColor and skyColorEnabled then applySkyColor() end
    if Settings.AutoApplyPerfectFog and perfectFogEnabled then applyPerfectFog() end
    if AirStrafeSpeedEnabled then task.wait(1); applyAirStrafeModifications() end
    if NonMovableEmoteHopEnabled then pcall(applyNonMovableEmoteHop) end
    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then task.wait(0.2); updateFlyVelocity(); startCrouchDetect() end
end)

if LocalPlayer.Character then setupMobileEdge(LocalPlayer.Character) end

-- =====================================================
-- BUILD UI
-- =====================================================

local Win = Library:CreateWindow({Title="Movement Ware V3", Size=UDim2.new(0,836,0,538), ToggleKey=Enum.KeyCode.RightShift})

-- Categories & Tabs
Win:CreateCategory("Movement")
local MainTab = Win:CreateTab("Main", "8673852020")
Win:CreateCategory("Visuals")
local VisualsTab = Win:CreateTab("Visuals", "100065143108986")
Win:CreateCategory("Extra")
local MapsTab  = Win:CreateTab("Maps",  "8673852020")
local TASTab   = Win:CreateTab("TAS",   "11802342133")
local MiscTab  = Win:CreateTab("Misc",  "14219516560")

-- =====================================================
-- MAIN TAB
-- =====================================================

-- LEFT: Movement features
local MovLeft = MainTab:CreateSection({Name="Movement", Side="Left"})

MovLeft:CreateToggle({Name="Air Strafe Speed", Default=false, Callback=function(v)
    AirStrafeSpeedEnabled=v
    if v then applyAirStrafeModifications(); notify("Air Strafe Speed enabled.",2) else restoreAirStrafeModifications() end
end})
MovLeft:CreateSlider({Name="ASS Speed Value", Min=100, Max=5000, Default=1500, Callback=function(v) AirStrafeSpeedValue=v; updateAirStrafeValues() end})
MovLeft:CreateSlider({Name="ASS Jump Height", Min=1, Max=10, Default=3, Callback=function(v) AirStrafeJumpHeight=v; updateAirStrafeValues() end})

MovLeft:CreateToggle({Name="Virtual Strafe", Default=false, Callback=function(v)
    VirtualStrafeEnabled=v
    if not v then currentSpeed=0; moveDir=Vector3.new(0,0,0) end
    notify(v and "Virtual Strafe enabled." or "Virtual Strafe disabled.",2)
end})
MovLeft:CreateSlider({Name="Strafe Intensity", Min=100, Max=2000, Default=500, Callback=function(v) VirtualStrafeIntensity=v end})

MovLeft:CreateToggle({Name="Fly Glitch [Q=Up / Ctrl=Down]", Default=false, Callback=function(v)
    Settings.PCFlyEnabled=v; updateFlyVelocity()
    if v then startCrouchDetect() else clearCrouchConnections() end
    notify(v and "Fly enabled." or "Fly disabled.",2)
end})

MovLeft:CreateToggle({Name="Invis Wall Remover", Default=false, Callback=function(v) updateInvisWall(v); notify(v and "Invis Walls removed." or "Invis Walls restored.",2) end})

MovLeft:CreateToggle({Name="Easy Edge Trimp", Default=false, Callback=function(v) Settings.TrimpEnabled=v; notify(v and "Edge Trimp enabled." or "Edge Trimp disabled.",2) end})

MovLeft:CreateToggle({Name="Easy Bounce", Default=false, Callback=function(v)
    EasyBounceEnabled=v
    if v then easyBounceHistory={}; refreshEasyBounceCharacter(LocalPlayer.Character) end
    notify(v and "Easy Bounce enabled." or "Easy Bounce disabled.",2)
end})

MovLeft:CreateToggle({Name="Auto Trimp", Default=false, Callback=function(v) AutoTrimpEnabled=v; notify(v and "Auto Trimp enabled." or "Auto Trimp disabled.",2) end})
MovLeft:CreateSlider({Name="Trimp Power", Min=50, Max=300, Default=100, Callback=function(v) TrimpPower=v end})
MovLeft:CreateSlider({Name="Trimp Min Speed", Min=10, Max=100, Default=30, Callback=function(v) MinSpeed=v end})

MovLeft:CreateToggle({Name="Y Lock Surf (X to toggle)", Default=false, Callback=function(v)
    YLockSurfEnabled=v; if not v then UnlockYPosition() end
    notify(v and "Y Lock Surf enabled." or "Y Lock Surf disabled.",2)
end})

MovLeft:CreateToggle({Name="Turnbind (A=Left / D=Right)", Default=false, Callback=function(v)
    TurnbindSettings.Enabled=v
    if v then startTurnbind(); notify("Turnbind enabled.",2) else stopTurnbind(); notify("Turnbind disabled.",2) end
end})

-- RIGHT: Speed & Emote
local MovRight = MainTab:CreateSection({Name="Speed Changer", Side="Right"})

MovRight:CreateToggle({Name="Legacy Speed", Default=false, Callback=function(v)
    LegacySpeedEnabled=v
    if v then startLegacySpeed(); notify("Legacy Speed enabled. Speed: "..RealSpeedOverride,2) else stopLegacySpeed(); notify("Legacy Speed disabled.",2) end
end})
MovRight:CreateSlider({Name="Legacy Speed Value", Min=100, Max=3000, Default=1500, Callback=function(v)
    RealSpeedOverride=v
    if LegacySpeedEnabled and LocalPlayer.Character then
        local hum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetAttribute("RealSpeed",RealSpeedOverride) end
    end
end})

MovRight:CreateToggle({Name="Overhaul Speed", Default=false, Callback=function(v)
    OverhaulSpeedBoosterEnabled=v
    if v then startOverhaulSpeedRespawnHook(); applyOverhaulSpeedBooster(); notify("Overhaul Speed enabled. Speed: "..OverhaulSpeedValue,2)
    else restoreOverhaulSpeedBooster(); notify("Overhaul Speed disabled.",2) end
end})
MovRight:CreateSlider({Name="Overhaul Speed Value", Min=100, Max=5000, Default=2000, Callback=function(v) OverhaulSpeedValue=v; if OverhaulSpeedBoosterEnabled then applyOverhaulSpeedBooster() end end})

local EmoteSection = MainTab:CreateSection({Name="Emote Actions", Side="Right"})
EmoteSection:CreateToggle({Name="360 Emote Hop (A + D)", Default=false, Callback=function(v) Settings.SpinEnabled=v end})
EmoteSection:CreateToggle({Name="Emote Spin", Default=false, Callback=function(v) Settings.TurnEnabled=v end})
EmoteSection:CreateSlider({Name="Turn Speed (/100)", Min=1, Max=30, Default=5, Callback=function(v) Settings.TurnSpeed=math.max(v/100,0.001) end})
EmoteSection:CreateToggle({Name="Nonmovable Emote Hop", Default=false, Callback=function(v)
    NonMovableEmoteHopEnabled=v
    if v then local cnt=0; pcall(function() cnt=applyNonMovableEmoteHop() end); notify("Nonmovable Emote Hop enabled. Fixed: "..cnt,3)
    else pcall(restoreNonMovableEmoteHop); notify("Nonmovable Emote Hop disabled.",2) end
end})

local HBSection = MainTab:CreateSection({Name="Hitbox Creator", Side="Right"})
HBSection:CreateToggle({Name="Enable Hitbox Creator", Default=false, Callback=function(v)
    hitboxCreatorEnabled=v
    if v then enableHitboxSelection(); notify("Click in-world to create hitboxes.",2) else disableHitboxSelection() end
end})
HBSection:CreateSlider({Name="Size X", Min=1, Max=50, Default=5, Callback=function(v) hitboxSizeX=v; applyHitboxPropertiesToSelected(true) end})
HBSection:CreateSlider({Name="Size Y", Min=1, Max=50, Default=5, Callback=function(v) hitboxSizeY=v; applyHitboxPropertiesToSelected(true) end})
HBSection:CreateSlider({Name="Size Z", Min=1, Max=50, Default=5, Callback=function(v) hitboxSizeZ=v; applyHitboxPropertiesToSelected(true) end})
HBSection:CreateSlider({Name="Transparency (/10)", Min=0, Max=10, Default=9, Callback=function(v) hitboxTransparency=v/10; applyHitboxPropertiesToSelected(true) end})
HBSection:CreateSlider({Name="Move Step", Min=1, Max=50, Default=1, Callback=function(v) hitboxMoveStep=v end})
HBSection:CreateButton({Name="Select Last Hitbox", Callback=function() if selectLastHitbox() then notify("Selected latest hitbox.",2) else notify("No hitbox available.",2) end end})
HBSection:CreateButton({Name="Move +X", Callback=function() moveSelectedHitbox(Vector3.new(hitboxMoveStep,0,0)) end})
HBSection:CreateButton({Name="Move -X", Callback=function() moveSelectedHitbox(Vector3.new(-hitboxMoveStep,0,0)) end})
HBSection:CreateButton({Name="Move +Y", Callback=function() moveSelectedHitbox(Vector3.new(0,hitboxMoveStep,0)) end})
HBSection:CreateButton({Name="Move -Y", Callback=function() moveSelectedHitbox(Vector3.new(0,-hitboxMoveStep,0)) end})
HBSection:CreateButton({Name="Move +Z", Callback=function() moveSelectedHitbox(Vector3.new(0,0,hitboxMoveStep)) end})
HBSection:CreateButton({Name="Move -Z", Callback=function() moveSelectedHitbox(Vector3.new(0,0,-hitboxMoveStep)) end})
HBSection:CreateButton({Name="Delete Selected Hitbox", Callback=function() removeSelectedHitbox() end})
HBSection:CreateButton({Name="Remove All Hitboxes", Callback=function() removeAllHitboxes(); notify("All hitboxes removed.",2) end})

local AdvSection = MainTab:CreateSection({Name="Advanced", Side="Left"})
AdvSection:CreateToggle({Name="FFlag MaxMissedWorldSteps", Default=false, Callback=function(v) Settings.FFlagEnabled=v end})
AdvSection:CreateToggle({Name="Keyboard Sound Effect", Default=false, Callback=function(v) Settings.keyboardSoundEnabled=v end})

local CustomScriptsSection = MainTab:CreateSection({Name="Custom Scripts", Side="Left"})
local GistList = {
    {"Downed Surf - Hold Ctrl","https://gist.githubusercontent.com/sn3514ube16-droid/a80d60ccfc849dfdd05b85825efaa5f1/raw/c1a55d272aa6d35f47bee585a9fc67891a0351a0/DownedSurfV2.lua"},
    {"Any Emote Move - Press Q while using emote","https://gist.githubusercontent.com/sn3514ube16-droid/b3e5989392ba9a5b6cc1c3b5d81018e1/raw/move%2520with%2520any%2520emote.lua"},
    {"Cactus Hitbox+ - 1 Round","https://gist.githubusercontent.com/sn3514ube16-droid/890c588202cb02654578315837b63249/raw/CactuseSize.lua"},
    {"Faster Emote Turn","https://gist.githubusercontent.com/sn3514ube16-droid/5937f4dd8f5050a2d6952f42da7b91af/raw/947a15624feab4e75e3e66aba2c501e55229581d/emoteturnspeedFIXED.lua"},
}
for _, entry in ipairs(GistList) do
    CustomScriptsSection:CreateButton({Name=entry[1], Callback=function()
        pcall(function() loadstring(game:HttpGet(entry[2]))() end)
        notify(entry[1].." loaded.",3)
    end})
end

-- =====================================================
-- VISUALS TAB
-- =====================================================

local CamSection = VisualsTab:CreateSection({Name="Camera", Side="Left"})
CamSection:CreateToggle({Name="Enable FOV Lock", Default=false, Callback=function(v) Settings.FOVEnabled=v; enforceFOV() end})
CamSection:CreateSlider({Name="FOV Value", Min=70, Max=120, Default=93, Callback=function(v) Settings.FOV=v; enforceFOV() end})

local AvatarSection = VisualsTab:CreateSection({Name="Avatar", Side="Left"})
AvatarSection:CreateToggle({Name="Headless", Default=false, Callback=function(v)
    Settings.HeadlessEnabled=v
    if LocalPlayer.Character then if v then applyAvatarCosmeticsWithRetries(LocalPlayer.Character) else pcall(function() removeHeadless(LocalPlayer.Character) end) end end
end})
AvatarSection:CreateToggle({Name="Korblox Right Leg", Default=false, Callback=function(v)
    Settings.KorbloxEnabled=v
    if LocalPlayer.Character then if v then applyAvatarCosmeticsWithRetries(LocalPlayer.Character) else pcall(function() removeKorblox(LocalPlayer.Character) end) end end
end})

local CosSection = VisualsTab:CreateSection({Name="Cosmetic Customizer", Side="Left"})
CosSection:CreateToggle({Name="Auto-Apply Cosmetic Style on Respawn", Default=false, Callback=function(v) Settings.AutoApplyCosmetic=v end})
CosSection:CreateButton({Name="Apply Cosmetic Style Now", Callback=function()
    pcall(function() if LocalPlayer.Character then applyDeepWineLogic(LocalPlayer.Character) end end)
    notify("Cosmetic style applied.",3)
end})

local CosSwapSection = VisualsTab:CreateSection({Name="Cosmetic Swapper", Side="Left"})
CosSwapSection:CreateButton({Name="Apply Cosmetic Swaps", Callback=function()
    local ok, swapped, failed = pcall(applyConfigSwaps, COSMETIC_SWAP_CONFIG, CosmeticSwapBackups)
    if not ok then notify("Cosmetic swap error.",3); return end
    if swapped == 0 and failed == 0 then notify("No cosmetics set in COSMETIC_SWAP_CONFIG.",3)
    elseif swapped > 0 then notify("Swapped "..swapped.." cosmetic(s)"..(failed>0 and " | "..failed.." failed" or "")..".",4)
    else notify(failed.." cosmetic(s) failed to swap.",4) end
end})
CosSwapSection:CreateButton({Name="Restore Original Cosmetic", Callback=function()
    local ok, restored, failed = pcall(restoreAllFromBackup, COSMETIC_SWAP_CONFIG, CosmeticSwapBackups)
    if not ok then notify("Restore error.",3); return end
    if restored > 0 then notify("Restored "..restored.." cosmetic(s).",3)
    else notify("Nothing to restore (apply swaps first).",3) end
end})

local EmoteSwapSection = VisualsTab:CreateSection({Name="Emote Swapper", Side="Right"})
EmoteSwapSection:CreateButton({Name="Apply Emote Swaps", Callback=function()
    local ok, swapped, failed = pcall(applyConfigSwaps, EMOTE_SWAP_CONFIG, EmoteSwapBackups)
    if not ok then notify("Emote swap error.",3); return end
    if swapped == 0 and failed == 0 then notify("No emotes set in EMOTE_SWAP_CONFIG.",3)
    elseif swapped > 0 then notify("Swapped "..swapped.." emote(s)"..(failed>0 and " | "..failed.." failed" or "")..".",4)
    else notify(failed.." emote(s) failed to swap.",4) end
end})
EmoteSwapSection:CreateButton({Name="Restore Original Emotes", Callback=function()
    local ok, restored, failed = pcall(restoreAllFromBackup, EMOTE_SWAP_CONFIG, EmoteSwapBackups)
    if not ok then notify("Restore error.",3); return end
    if restored > 0 then notify("Restored "..restored.." emote(s).",3)
    else notify("Nothing to restore (apply swaps first).",3) end
end})

local WorldSection = VisualsTab:CreateSection({Name="World Visuals", Side="Right"})
WorldSection:CreateToggle({
    Name="Global Color",
    Default=false,
    Colorpicker=true,
    ColorDefault=globalColor,
    ColorCallback=function(col) globalColor=col; if globalColorEnabled then applyGlobalColor() end end,
    Callback=function(v)
        globalColorEnabled=v
        if v then storeOriginalColors(); applyGlobalColor() else restoreOriginalColors() end
    end
})
WorldSection:CreateToggle({Name="Auto-Apply Global Color on Respawn", Default=false, Callback=function(v) Settings.AutoApplyGlobalColor=v end})

WorldSection:CreateToggle({
    Name="Sky Color",
    Default=false,
    Colorpicker=true,
    ColorDefault=skyColor,
    ColorCallback=function(col) skyColor=col; if skyColorEnabled then applySkyColor() end end,
    Callback=function(v) skyColorEnabled=v; applySkyColor() end
})
WorldSection:CreateToggle({Name="Auto-Apply Sky Color on Respawn", Default=false, Callback=function(v) Settings.AutoApplySkyColor=v end})

WorldSection:CreateToggle({
    Name="Perfect Fog",
    Default=false,
    Colorpicker=true,
    ColorDefault=perfectFogColor,
    ColorCallback=function(col) perfectFogColor=col; if perfectFogEnabled then applyPerfectFog() end end,
    Callback=function(v) perfectFogEnabled=v; applyPerfectFog() end
})
WorldSection:CreateToggle({Name="Auto-Apply Perfect Fog on Respawn", Default=false, Callback=function(v) Settings.AutoApplyPerfectFog=v end})

WorldSection:CreateToggle({Name="Sunset Shader", Default=false, Callback=function(v) sunsetShaderEnabled=v; applySunsetShader() end})

-- =====================================================
-- MAPS TAB
-- =====================================================

local MapLoaderSection = MapsTab:CreateSection({Name="Map Loader", Side="Left"})
local mapIdInput = ""
MapLoaderSection:CreateTextbox({Name="Map Asset ID", Placeholder="Enter Roblox Asset ID", Callback=function(txt) mapIdInput=txt end})
MapLoaderSection:CreateButton({Name="Load Map", Callback=function()
    if mapIdInput ~= "" then loadMapByAssetId(mapIdInput) else notify("Please enter a valid Map Asset ID.",2) end
end})
MapLoaderSection:CreateSlider({Name="Map Scale", Min=1, Max=10, Default=1, Callback=function(v) Settings.MapScale=v end})
MapLoaderSection:CreateSlider({Name="Spawn Height", Min=100, Max=5000, Default=1500, Callback=function(v) Settings.SpawnHeight=v end})

local CustomMapSection = MapsTab:CreateSection({Name="Custom Maps", Side="Right"})
for _, map in ipairs(CustomMaps) do
    CustomMapSection:CreateButton({Name=map.Name, Callback=function() loadCustomMap(map) end})
end

-- =====================================================
-- TAS TAB
-- =====================================================

local TASSection = TASTab:CreateSection({Name="TAS Recording", Side="Left"})
TASSection:CreateButton({Name="Start Recording (F1)", Callback=function() TAS_StartRecord() end})
TASSection:CreateButton({Name="Stop Recording (F2)", Callback=function() TAS_StopRecord() end})
TASSection:CreateButton({Name="Play TAS (F3)", Callback=function() TAS_PlayTAS() end})
TASSection:CreateButton({Name="Clear Frames (F4)", Callback=function() TAS_ClearFrames() end})

-- =====================================================
-- MISC TAB
-- =====================================================

local MiscSection = MiscTab:CreateSection({Name="Settings & Misc", Side="Left"})
MiscSection:CreateToggle({Name="Enable Notifications", Default=true, Callback=function(v) notificationsEnabled=v end})
MiscSection:CreateToggle({Name="Mommy ASMR (Sound)", Default=false, Callback=function(v) Settings.mommyAsmrEnabled=v end})