-- =====================================================
-- COMBINED KAMBILOX UI & MOVEMENT WARE V3
-- =====================================================

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
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

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = Workspace.CurrentCamera
end)

-- =====================================================
-- MOVEMENT WARE CONFIGURATION & STATE
-- =====================================================
local WINE_CONFIG = {
    TrueWine = Color3.fromRGB(80, 0, 25),
    BlackWine = Color3.fromRGB(30, 0, 10),
    Material = Enum.Material.SmoothPlastic
}

local Settings = {
    NotificationsEnabled = true,
    
    -- Movement
    VirtualStrafeEnabled = false,
    AirStrafeSpeedEnabled = false,
    EasyBounceEnabled = false,
    AutoTrimpEnabled = false,
    YLockSurfEnabled = false,
    TurnbindEnabled = false,
    LegacySpeedEnabled = false,
    OverhaulSpeedEnabled = false,
    PCFlyEnabled = false,
    
    -- Visuals / World
    FOVEnabled = false,
    FOV = 93,
    InvisWallEnabled = false,
    HeadlessEnabled = false,
    KorbloxEnabled = false,
    AutoApplyCosmetic = false,
    AutoApplyGlobalColor = false,
    AutoApplySkyColor = false,
    AutoApplyPerfectFog = false,
    keyboardSoundEnabled = false,
    
    -- Emotes / Actions
    SpinEnabled = false,
    TurnEnabled = false,
    TurnSpeed = 0.05,
    NonMovableEmoteHopEnabled = false,
    AutoApplyDraconicEmoteSwapper = false,
    
    -- Hitbox
    HitboxCreatorEnabled = false,
    HitboxSize = Vector3.new(5, 5, 5),
    HitboxTransparency = 0.9,
    HitboxCanCollide = true,
    
    -- Advanced
    FFlagEnabled = false
}

-- =====================================================
-- MOVEMENT WARE CORE LOGIC & FUNCTIONS
-- =====================================================
local function notify(text, duration)
    if not Settings.NotificationsEnabled then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Movement Ware",
            Text = tostring(text),
            Duration = duration or 3
        })
    end)
end

-- [Air Strafe]
local AirStrafeSpeedValue, AirStrafeAcceleration, AirStrafeJumpHeight = 1500, 182, 3

-- [Virtual Strafe]
local VirtualStrafeIntensity = 500
local currentSpeed = 0
local moveDir = Vector3.new(0, 0, 0)

local function resetVirtualStrafe()
    Settings.VirtualStrafeEnabled = false
    currentSpeed = 0
    moveDir = Vector3.new(0, 0, 0)
end

-- [Auto Trimp]
local TrimpPower, MinSpeed = 100, 30
local lastTrimp = 0

-- [Y-Lock Surf]
local YLockSurfMode, YLockSurfKey = "Toggle", Enum.KeyCode.X
local isYLocked, lockedY, originalHipHeight = false, nil, nil

local function LockYPosition()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        lockedY = char.HumanoidRootPart.Position.Y
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then originalHipHeight = hum.HipHeight end
        isYLocked = true
    end
end

local function UnlockYPosition()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and originalHipHeight then hum.HipHeight = originalHipHeight end
    end
    isYLocked = false
    lockedY = nil
end

local function MaintainYLock()
    if isYLocked and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and lockedY then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local currentVel = hrp.AssemblyLinearVelocity
        if math.abs(hrp.Position.Y - lockedY) > 0.1 then
            hrp.Position = Vector3.new(hrp.Position.X, lockedY, hrp.Position.Z)
        end
        hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
    end
end

-- [Legacy Speed]
local RealSpeedOverride = 1500

-- [Fly Glitch]
local executando, subindoQ, descendoCTRL = false, false, false

local function updateFlyVelocity()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local bv = char.HumanoidRootPart:FindFirstChild("FlyVelocity")
        if Settings.PCFlyEnabled then
            if not bv then
                bv = Instance.new("BodyVelocity", char.HumanoidRootPart)
                bv.Name = "FlyVelocity"
                bv.MaxForce = Vector3.new(0, 0, 0)
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            executando = true
        else
            if bv then bv:Destroy() end
            executando = false
        end
    end
end

-- [Cosmetics & World]
local function enforceFOV()
    if camera then
        if Settings.FOVEnabled then
            camera.FieldOfView = Settings.FOV
        else
            camera.FieldOfView = 70
        end
    end
end

local function updateInvisWall(v)
    Settings.InvisWallEnabled = v
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency >= 0.5 and obj.Size.Magnitude >= 12 then
            obj.CanCollide = not v
        end
    end
end

-- =====================================================
-- MOVEMENT WARE INPUT & RENDER LOOPS
-- =====================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if Settings.YLockSurfEnabled and (input.KeyCode == YLockSurfKey or input.UserInputType == YLockSurfKey) then
        if YLockSurfMode == "Toggle" then
            if isYLocked then UnlockYPosition() else LockYPosition() end
        else
            LockYPosition()
        end
    end

    if executando then
        if input.KeyCode == Enum.KeyCode.Q then subindoQ = not subindoQ end
        if input.KeyCode == Enum.KeyCode.LeftControl then descendoCTRL = true end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if Settings.YLockSurfEnabled and YLockSurfMode == "Hold" and (input.KeyCode == YLockSurfKey or input.UserInputType == YLockSurfKey) then
        UnlockYPosition()
    end
    if executando and input.KeyCode == Enum.KeyCode.LeftControl then
        descendoCTRL = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    enforceFOV()

    if Settings.SpinEnabled then
        hrp.CFrame *= CFrame.Angles(0, (2 * math.pi / 0.3) * dt, 0)
    end
    if Settings.TurnEnabled then
        hrp.CFrame *= CFrame.Angles(0, (20 * math.pi / math.max(Settings.TurnSpeed, 0.001)) * dt, 0)
    end
    if Settings.YLockSurfEnabled then
        MaintainYLock()
    end
end)

-- =====================================================
-- MW API EXPORT
-- =====================================================
_G.MW_API = {
    ToggleAirStrafe = function(state) Settings.AirStrafeSpeedEnabled = state end,
    SetAirStrafeSpeed = function(val) AirStrafeSpeedValue = val end,
    
    ToggleVirtualStrafe = function(state) Settings.VirtualStrafeEnabled = state; if not state then resetVirtualStrafe() end end,
    SetVSIntensity = function(val) VirtualStrafeIntensity = val end,

    ToggleFly = function(state) Settings.PCFlyEnabled = state; updateFlyVelocity() end,
    ToggleInvisWall = function(state) updateInvisWall(state) end,
    
    ToggleEasyBounce = function(state) Settings.EasyBounceEnabled = state end,
    ToggleAutoTrimp = function(state) Settings.AutoTrimpEnabled = state end,
    SetTrimpPower = function(val) TrimpPower = val end,
    
    ToggleYLockSurf = function(state) Settings.YLockSurfEnabled = state; if not state then UnlockYPosition() end end,
    SetYLockKey = function(keyEnum) YLockSurfKey = keyEnum end,
    
    ToggleLegacySpeed = function(state) Settings.LegacySpeedEnabled = state end,
    SetLegacySpeedVal = function(val) RealSpeedOverride = val end,
    
    ToggleFOV = function(state) Settings.FOVEnabled = state; enforceFOV() end,
    SetFOV = function(val) Settings.FOV = val; enforceFOV() end,
    
    ToggleHeadless = function(state) Settings.HeadlessEnabled = state end,
    ToggleKorblox = function(state) Settings.KorbloxEnabled = state end,
    
    ToggleEmoteSpin = function(state) Settings.SpinEnabled = state end,
    ToggleEmoteTurn = function(state) Settings.TurnEnabled = state end,
    SetEmoteTurnSpeed = function(val) Settings.TurnSpeed = math.max(val / 100, 0.001) end,
}

-- =====================================================
-- KAMBILOX UI LIBRARY
-- =====================================================
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
    if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local PopupBg = Utility:Create("TextButton", {
        Name = "PopupBg", Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 100, Visible = false, Text = "", AutoButtonColor = false
    })
    local PopupConnections = {}
    PopupBg.MouseButton1Click:Connect(function() 
        PopupBg.Visible = false
        for _, conn in ipairs(PopupConnections) do if conn.Disconnect then conn:Disconnect() end end
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
            local PreviewBox = Utility:Create("Frame", { Parent = BottomContainer, BackgroundColor3 = currentColor, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 102 })
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

    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame", Parent = ScreenGui, BackgroundColor3 = Theme.MainBg, BorderSizePixel = 0,
        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2), Size = windowSize, Active = true
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

    local TabListLayout = Utility:Create("UIListLayout", { Parent = TabButtonContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) })

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
            Name = "TabButton_" .. name, Parent = TabButtonContainer, BackgroundColor3 = Theme.TabFrameBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32),
            Font = Theme.LabelFont, Text = (iconId and "          " or "   ") .. name, TextColor3 = Color3.fromRGB(130, 130, 130), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = tabCount
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
            local side = options.Side or "Left"
            local targetCol = (side:lower() == "left") and LeftCol or RightCol

            local SectionFrame = Utility:Create("Frame", {
                Name = "Child_" .. secName, Parent = targetCol, BackgroundColor3 = Theme.SectionBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40)
            })
            Utility:Create("UICorner", { Parent = SectionFrame, CornerRadius = UDim.new(0, 6) })

            local SectionTitle = Utility:Create("TextLabel", {
                Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 5), Size = UDim2.new(1, -24, 0, 20),
                Font = Theme.LabelFont, Text = secName, TextColor3 = Theme.TextCategory, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
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

                local ToggleFrame = Utility:Create("Frame", { Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 24) })
                local ToggleLabel = Utility:Create("TextLabel", { Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Font = Theme.LabelFont, Text = togText, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local ToggleBox = Utility:Create("TextButton", { Parent = ToggleFrame, BackgroundColor3 = state and Theme.ToggleActive or Theme.ToggleInactive, BorderSizePixel = 0, Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Text = "", AutoButtonColor = false })
                Utility:Create("UICorner", { Parent = ToggleBox, CornerRadius = UDim.new(0, 4) })
                
                table.insert(AccentUpdates, function(col) if state then ToggleBox.BackgroundColor3 = col end end)

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

                local SliderFrame = Utility:Create("Frame", { Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 36) })
                local SliderLabel = Utility:Create("TextLabel", { Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 16), Font = Theme.LabelFont, Text = slName, TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local ValueLabel = Utility:Create("TextLabel", { Parent = SliderFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 40, 0, 16), Font = Theme.Font, Text = tostring(default), TextColor3 = Theme.TextMain, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })

                local SliderBack = Utility:Create("Frame", { Parent = SliderFrame, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 6) })
                Utility:Create("UICorner", { Parent = SliderBack, CornerRadius = UDim.new(0, 3) })

                local fillPct = math.clamp((default - min) / (max - min), 0, 1)
                local SliderFill = Utility:Create("Frame", { Parent = SliderBack, BackgroundColor3 = Theme.ToggleActive, BorderSizePixel = 0, Size = UDim2.new(fillPct, 0, 1, 0) })
                Utility:Create("UICorner", { Parent = SliderFill, CornerRadius = UDim.new(0, 3) })
                
                table.insert(AccentUpdates, function(col) SliderFill.BackgroundColor3 = col end)

                local SliderBtn = Utility:Create("TextButton", { Parent = SliderBack, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false })

                local function update(input)
                    local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                    local value = math.floor(min + ((max - min) * pos))
                    ValueLabel.Text = tostring(value)
                    callback(value)
                end

                SliderBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        update(input)
                        local moveConn, endConn
                        moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                            if moveInput.UserInputType == Enum.UserInputType.MouseMovement then update(moveInput) end
                        end)
                        endConn = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
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

                local ButtonFrame = Utility:Create("Frame", { Parent = ContentContainer, BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 24) })
                Utility:Create("UICorner", { Parent = ButtonFrame, CornerRadius = UDim.new(0, 6) })

                local Button = Utility:Create("TextButton", { Parent = ButtonFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Theme.Font, Text = btnText, TextColor3 = Theme.TextMain, TextSize = 13 })
                Button.MouseButton1Click:Connect(function() callback() end)
            end

            return Elements
        end
        return TabObj
    end
    return Window
end

-- =====================================================
-- BUILD UI & CONNECT TO MOVEMENT WARE API
-- =====================================================

local Window = Library:CreateWindow({
    Title = "Movement Ware V3",
    Size = UDim2.new(0, 836, 0, 538)
})

-- Movement Category
Window:CreateCategory("Movement")
local MovementTab = Window:CreateTab("Movement", "8673852020")

local StrafeSection = MovementTab:CreateSection({ Name = "Air & Strafe", Side = "Left" })
StrafeSection:CreateToggle({
    Name = "Air Strafe",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleAirStrafe(state) end
})
StrafeSection:CreateSlider({
    Name = "Air Strafe Speed",
    Min = 100, Max = 5000, Default = 1500,
    Callback = function(val) _G.MW_API.SetAirStrafeSpeed(val) end
})
StrafeSection:CreateToggle({
    Name = "Virtual Strafe",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleVirtualStrafe(state) end
})
StrafeSection:CreateSlider({
    Name = "Virtual Strafe Intensity",
    Min = 50, Max = 2000, Default = 500,
    Callback = function(val) _G.MW_API.SetVSIntensity(val) end
})

local PhysicsSection = MovementTab:CreateSection({ Name = "Physics & Speed", Side = "Right" })
PhysicsSection:CreateToggle({
    Name = "Easy Bounce",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleEasyBounce(state) end
})
PhysicsSection:CreateToggle({
    Name = "Auto Trimp",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleAutoTrimp(state) end
})
PhysicsSection:CreateSlider({
    Name = "Trimp Power",
    Min = 10, Max = 500, Default = 100,
    Callback = function(val) _G.MW_API.SetTrimpPower(val) end
})
PhysicsSection:CreateToggle({
    Name = "Y-Lock Surf",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleYLockSurf(state) end
})
PhysicsSection:CreateToggle({
    Name = "Legacy Speed Override",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleLegacySpeed(state) end
})
PhysicsSection:CreateSlider({
    Name = "Legacy Speed",
    Min = 16, Max = 3000, Default = 1500,
    Callback = function(val) _G.MW_API.SetLegacySpeedVal(val) end
})
PhysicsSection:CreateToggle({
    Name = "PC Fly Glitch",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleFly(state) end
})

-- Visuals Category
Window:CreateCategory("Visuals")
local VisualsTab = Window:CreateTab("Visuals", "137182874573549")

local CameraSection = VisualsTab:CreateSection({ Name = "Camera & Environment", Side = "Left" })
CameraSection:CreateToggle({
    Name = "FOV Modifier",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleFOV(state) end
})
CameraSection:CreateSlider({
    Name = "Field View (FOV)",
    Min = 30, Max = 120, Default = 93,
    Callback = function(val) _G.MW_API.SetFOV(val) end
})
CameraSection:CreateToggle({
    Name = "Disable Invisible Walls",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleInvisWall(state) end
})

local CharacterSection = VisualsTab:CreateSection({ Name = "Character Cosmetics", Side = "Right" })
CharacterSection:CreateToggle({
    Name = "Headless",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleHeadless(state) end
})
CharacterSection:CreateToggle({
    Name = "Korblox",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleKorblox(state) end
})

-- Emotes / Actions Category
Window:CreateCategory("Actions")
local EmotesTab = Window:CreateTab("Emotes", "14219516560")

local SpinSection = EmotesTab:CreateSection({ Name = "Spinbot & Rotations", Side = "Left" })
SpinSection:CreateToggle({
    Name = "Spin Bot",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleEmoteSpin(state) end
})
SpinSection:CreateToggle({
    Name = "Smooth Turn",
    Default = false,
    Callback = function(state) _G.MW_API.ToggleEmoteTurn(state) end
})
SpinSection:CreateSlider({
    Name = "Turn Speed",
    Min = 1, Max = 100, Default = 5,
    Callback = function(val) _G.MW_API.SetEmoteTurnSpeed(val) end
})

return Library