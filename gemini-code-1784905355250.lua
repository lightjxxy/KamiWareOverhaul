-- =====================================================
-- MOVEMENT WARE V3 - NEBULA UI EDITION
-- =====================================================

local Nebula = loadstring(game:HttpGet("https://github.com/lzhenweiDev/Nebula-UI/raw/refs/heads/main/V3.lua"))()

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

-- Nebula UI Window Setup
local Window = Nebula:CreateWindow({
    Name = "Movement Ware V3",
    SubTitle = "Nebula Edition",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark"
})

local function notify(text, duration)
    if not notificationsEnabled then
        return
    end

    duration = duration or 3
    local ok = pcall(function()
        Nebula:Notify({
            Title = "Movement Ware",
            Content = tostring(text),
            Duration = duration
        })
    end)
    if not ok then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Movement Ware",
                Text = tostring(text),
                Duration = duration
            })
        end)
    end
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

-- =====================================================
-- NEBULA UI TABS SETUP
-- =====================================================

local Tabs = {
    Main = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://4483345998" }),
    Visuals = Window:CreateTab({ Name = "Visuals", Icon = "rbxassetid://4483345998" }),
    Maps = Window:CreateTab({ Name = "Maps", Icon = "rbxassetid://4483345998" }),
    TAS = Window:CreateTab({ Name = "TAS", Icon = "rbxassetid://4483345998" }),
    Config = Window:CreateTab({ Name = "Config", Icon = "rbxassetid://4483345998" })
}

-- =====================================================
-- DRACONIC EMOTE SWAPPER BACKEND
-- =====================================================

local DraconicSwapper = {
    SwappedPairs = {},
    OriginalPairs = {},
    IsProcessing = false,
    RoundActive = true
}

local EmoteSwapper = {
    CurrentEmotes = {},
    SelectedEmotes = {}
}

for i = 1, 12 do
    EmoteSwapper.CurrentEmotes[i] = ""
    EmoteSwapper.SelectedEmotes[i] = ""
end

local function normalizeString(str)
    return string.gsub(tostring(str or ""), "%s+", ""):lower()
end

local function getExactEmoteName(inputName)
    local emotesFolder = ReplicatedStorage:FindFirstChild("Items")
        and ReplicatedStorage.Items:FindFirstChild("Emotes")
    if not emotesFolder then
        return nil
    end

    local normalizedInput = normalizeString(inputName)
    for _, emote in ipairs(emotesFolder:GetChildren()) do
        if normalizeString(emote.Name) == normalizedInput then
            return emote.Name
        end
    end
    return nil
end

local function isValidEmote(name)
    local exactName = getExactEmoteName(name)
    return exactName ~= nil, exactName
end

local function draconicSwapEmote(targetEmote, replacementEmote)
    if DraconicSwapper.IsProcessing then return false end
    DraconicSwapper.IsProcessing = true

    local success, result = pcall(function()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then return false end

        local emotesFolder = items:FindFirstChild("Emotes")
        if not emotesFolder then return false end

        local targetObj = emotesFolder:FindFirstChild(targetEmote)
        local replacementObj = emotesFolder:FindFirstChild(replacementEmote)
        if not targetObj or not replacementObj then return false end

        DraconicSwapper.OriginalPairs[targetEmote] = replacementEmote
        DraconicSwapper.SwappedPairs[targetEmote] = replacementEmote

        local tempSuffix = "_DraconicTemp_" .. tostring(tick()):gsub("%.", "_")
        local tempName = replacementEmote .. tempSuffix
        while emotesFolder:FindFirstChild(tempName) do
            tempName = tempName .. "_"
        end

        targetObj.Name = tempName
        replacementObj.Name = targetEmote
        targetObj.Name = replacementEmote

        return true
    end)

    DraconicSwapper.IsProcessing = false
    return success and result or false
end

local function draconicRestoreEmote(targetEmote, replacementEmote)
    if DraconicSwapper.IsProcessing then return false end
    DraconicSwapper.IsProcessing = true

    local success, result = pcall(function()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then return false end

        local emotesFolder = items:FindFirstChild("Emotes")
        if not emotesFolder then return false end

        local targetObj = emotesFolder:FindFirstChild(replacementEmote)
        local replacementObj = emotesFolder:FindFirstChild(targetEmote)
        if not targetObj or not replacementObj then return false end

        local tempSuffix = "_DraconicRestore_" .. tostring(tick()):gsub("%.", "_")
        local tempName = targetEmote .. tempSuffix
        while emotesFolder:FindFirstChild(tempName) do
            tempName = tempName .. "_"
        end

        targetObj.Name = tempName
        replacementObj.Name = replacementEmote
        targetObj.Name = targetEmote

        return true
    end)

    DraconicSwapper.IsProcessing = false
    return success and result or false
end

local function draconicRestoreAllEmotes(keepOriginalPairs)
    if not next(DraconicSwapper.SwappedPairs) then return true end

    local savedOriginals = {}
    if keepOriginalPairs then
        for targetEmote, replacementEmote in pairs(DraconicSwapper.OriginalPairs) do
            savedOriginals[targetEmote] = replacementEmote
        end
    end

    local restoredCount = 0
    for targetEmote, replacementEmote in pairs(DraconicSwapper.SwappedPairs) do
        if draconicRestoreEmote(targetEmote, replacementEmote) then
            restoredCount = restoredCount + 1
        end
    end

    DraconicSwapper.SwappedPairs = {}
    DraconicSwapper.OriginalPairs = keepOriginalPairs and savedOriginals or {}
    return restoredCount > 0
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

local function stopTurnbind()
    if turnbindConns.Began then turnbindConns.Began:Disconnect() end
    if turnbindConns.Ended then turnbindConns.Ended:Disconnect() end
    turnbindConns = {}
end

local function startTurnbind()
    stopTurnbind()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    turnbindConns.Began = UserInputService.InputBegan:Connect(function(input, gpe)
        pcall(function()
            if gpe or not TurnbindSettings.Enabled then return end
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

local function applyGlobalColor()
    if not globalColorEnabled then return end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") and not isCharacterPart(obj) then
            pcall(function()
                obj.Color = globalColor
            end)
        end
    end
end

local sunsetShaderEnabled = false
local sunsetShaderOriginalLighting = nil
local SUNSET_SHADER_PREFIX = "MWSunsetShader"

local function saveSunsetShaderLighting()
    if sunsetShaderOriginalLighting then return end
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
    if overlay then overlay:Destroy() end
end

local function restoreSunsetShaderLighting()
    if not sunsetShaderOriginalLighting then return end
    for prop, value in pairs(sunsetShaderOriginalLighting) do
        pcall(function() Lighting[prop] = value end)
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

    local bloomEffect = Instance.new("BloomEffect", Lighting)
    bloomEffect.Name = "MWSunsetShaderBloom"
    bloomEffect.Intensity = 0.15
    bloomEffect.Size = 5
    bloomEffect.Threshold = 0.85

    local colorCorrectionEffect = Instance.new("ColorCorrectionEffect", Lighting)
    colorCorrectionEffect.Name = "MWSunsetShaderColorCorrection"
    colorCorrectionEffect.Brightness = 0.1
    colorCorrectionEffect.Contrast = 0.2
    colorCorrectionEffect.Saturation = -0.3
    colorCorrectionEffect.TintColor = Color3.fromRGB(255, 235, 203)

    Lighting.ClockTime = 17
end

-- =====================================================
-- VIRTUAL STRAFE
-- =====================================================

local VirtualStrafeEnabled = false
local VirtualStrafeIntensity = 500
local currentSpeed = 0
local lastCameraYaw = 0
local moveDir = Vector3.new(0, 0, 0)

local function updateVirtualStrafe(dt)
    if not VirtualStrafeEnabled then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local root = char.HumanoidRootPart
    local isW = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local isA = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local isD = UserInputService:IsKeyDown(Enum.KeyCode.D)
    local isS = UserInputService:IsKeyDown(Enum.KeyCode.S)

    local camForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if camForward.Magnitude <= 0 then return end
    camForward = camForward.Unit

    moveDir = moveDir:Lerp(camForward, 0.15)

    if isW or isA or isD then
        if currentSpeed < VirtualStrafeIntensity then
            currentSpeed = currentSpeed + (225 * dt)
        end
    elseif isS then
        currentSpeed = currentSpeed * 0.85
    else
        currentSpeed = currentSpeed * 0.99
    end

    if currentSpeed > 0 then
        local targetVelocity = moveDir * (currentSpeed / 45)
        root.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, root.AssemblyLinearVelocity.Y, targetVelocity.Z)
    end
end

RunService.Heartbeat:Connect(updateVirtualStrafe)

-- =====================================================
-- AUTO TRIMP
-- =====================================================

local AutoTrimpEnabled = false
local TrimpPower = 100
local MinSpeed = 30
local lastTrimp = 0

local function DoTrimp()
    if not AutoTrimpEnabled then return end
    local now = tick()
    if now - lastTrimp < 0.2 then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vel = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    if speed < MinSpeed or vel.Y > 0 then return end

    local raycastResult = workspace:Raycast(hrp.Position, Vector3.new(0, -3, 0))
    if not raycastResult then return end

    lastTrimp = now
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.8, TrimpPower, vel.Z * 0.8)
end

RunService.Heartbeat:Connect(DoTrimp)

-- =====================================================
-- AIR STRAFE SPEED
-- =====================================================

local AirStrafeSpeedEnabled = false
local AirStrafeSpeedValue = 1500
local AirStrafeJumpHeight = 3

local function applyAirStrafeToHumanoid(humanoid)
    if humanoid then
        humanoid.WalkSpeed = AirStrafeSpeedValue / 50
        humanoid.JumpPower = AirStrafeJumpHeight * 30
    end
end

local function applyAirStrafeModifications()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then applyAirStrafeToHumanoid(humanoid) end
    end
end

-- =====================================================
-- Y LOCK SURF
-- =====================================================

local YLockSurfEnabled = false
local YLockSurfMode = "Toggle"
local YLockSurfKey = Enum.KeyCode.X
local isYLocked = false
local lockedY = nil

local function LockYPosition()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        lockedY = hrp.Position.Y
        isYLocked = true
    end
end

local function UnlockYPosition()
    isYLocked = false
    lockedY = nil
end

local function MaintainYLock()
    if not isYLocked then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and lockedY then
        local pos = hrp.Position
        local vel = hrp.AssemblyLinearVelocity
        hrp.Position = Vector3.new(pos.X, lockedY, pos.Z)
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
    end
end

-- =====================================================
-- FLY GLITCH
-- =====================================================

local subindoQ = false
local descendoCTRL = false
local executando = false

local function updateFlyVelocity()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

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
        if bv then bv:Destroy() end
        executando = false
    end
end

-- =====================================================
-- KEYBOARD SOUND
-- =====================================================

local BASE_SOUND_ID = "rbxassetid://4724428597"
local baseSound = Instance.new("Sound", SoundService)
baseSound.SoundId = BASE_SOUND_ID
baseSound.Volume = 1

local function playKeyboardSound()
    if not Settings.keyboardSoundEnabled then return end
    local s = baseSound:Clone()
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- =====================================================
-- KORBLOX & HEADLESS
-- =====================================================

local K_MESH_ID = 101851696
local K_OVERLAY_ID = 101851254

local function applyKorblox(char)
    if not char or not Settings.KorbloxEnabled then return end
    local rLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg")
    if not rLeg then return end

    local rLegMesh = char:FindFirstChild("KorbloxMesh") or Instance.new("CharacterMesh", char)
    rLegMesh.Name = "KorbloxMesh"
    rLegMesh.BodyPart = Enum.BodyPart.RightLeg
    rLegMesh.MeshId = K_MESH_ID
    rLegMesh.OverlayTextureId = K_OVERLAY_ID
    rLeg.Color = Color3.fromRGB(38, 65, 68)
end

local function removeKorblox(char)
    if not char then return end
    local mesh = char:FindFirstChild("KorbloxMesh")
    if mesh then mesh:Destroy() end
end

local function applyHeadless(char)
    if not char or not Settings.HeadlessEnabled then return end
    local head = char:FindFirstChild("Head")
    if head then head.Transparency = 1 end
end

local function removeHeadless(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then head.Transparency = 0 end
end

-- =====================================================
-- INVIS WALL REMOVER
-- =====================================================

local originalState = {}
local function updateInvisWall(v)
    Settings.InvisWallEnabled = v
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency >= 0.5 and obj.Size.Magnitude >= 12 then
            if v then
                if originalState[obj] == nil then originalState[obj] = obj.CanCollide end
                obj.CanCollide = false
            else
                if originalState[obj] ~= nil then obj.CanCollide = originalState[obj] end
            end
        end
    end
end

-- =====================================================
-- INPUT CONNECTION
-- =====================================================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if YLockSurfEnabled and input.KeyCode == YLockSurfKey then
        if YLockSurfMode == "Toggle" then
            if isYLocked then UnlockYPosition() else LockYPosition() end
        else
            LockYPosition()
        end
    end

    if executando then
        if input.KeyCode == Enum.KeyCode.Q then subindoQ = not subindoQ
        elseif input.KeyCode == Enum.KeyCode.LeftControl then descendoCTRL = true end
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then playKeyboardSound() end
end)

UserInputService.InputEnded:Connect(function(input)
    if YLockSurfEnabled and YLockSurfMode == "Hold" and input.KeyCode == YLockSurfKey then
        UnlockYPosition()
    end
    if executando and input.KeyCode == Enum.KeyCode.LeftControl then
        descendoCTRL = false
    end
end)

-- =====================================================
-- FOV / RENDER LOOPS
-- =====================================================

local function enforceFOV()
    if camera and Settings.FOVEnabled then
        camera.FieldOfView = Settings.FOV
    end
end

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

    if YLockSurfEnabled then MaintainYLock() end

    if executando then
        local bv = hrp:FindFirstChild("FlyVelocity")
        if bv then
            if subindoQ then
                bv.MaxForce = Vector3.new(0, 9e6, 0)
                bv.Velocity = Vector3.new(0, 45, 0)
            elseif descendoCTRL then
                bv.MaxForce = Vector3.new(0, 9e6, 0)
                bv.Velocity = Vector3.new(0, -45, 0)
            else
                bv.MaxForce = Vector3.new(0, 0, 0)
            end
        end
    end
end)

-- =====================================================
-- NEBULA UI COMPONENTS INTEGRATION
-- =====================================================

-- MAIN TAB
local MovementSection = Tabs.Main:CreateSection({ Name = "Movement Mechanics" })

MovementSection:CreateToggle({
    Name = "Air Strafe Speed",
    Value = false,
    Callback = function(val)
        AirStrafeSpeedEnabled = val
        if AirStrafeSpeedEnabled then applyAirStrafeModifications() end
        notify(AirStrafeSpeedEnabled and "Air Strafe Speed enabled." or "Air Strafe Speed disabled.", 2)
    end
})

MovementSection:CreateSlider({
    Name = "Strafe Speed Value",
    Min = 100,
    Max = 5000,
    Default = 1500,
    Callback = function(val)
        AirStrafeSpeedValue = val
        applyAirStrafeModifications()
    end
})

MovementSection:CreateSlider({
    Name = "Jump Height",
    Min = 1,
    Max = 10,
    Default = 3,
    Callback = function(val)
        AirStrafeJumpHeight = val
        applyAirStrafeModifications()
    end
})

MovementSection:CreateToggle({
    Name = "Virtual Strafe",
    Value = false,
    Callback = function(val)
        VirtualStrafeEnabled = val
        notify(VirtualStrafeEnabled and "Virtual Strafe enabled." or "Virtual Strafe disabled.", 2)
    end
})

MovementSection:CreateSlider({
    Name = "Strafe Intensity",
    Min = 100,
    Max = 2000,
    Default = 500,
    Callback = function(val)
        VirtualStrafeIntensity = val
    end
})

MovementSection:CreateToggle({
    Name = "Fly Glitch [Q=Up / Ctrl=Down]",
    Value = false,
    Callback = function(val)
        Settings.PCFlyEnabled = val
        updateFlyVelocity()
    end
})

MovementSection:CreateToggle({
    Name = "Invis Wall Remover",
    Value = false,
    Callback = function(val)
        updateInvisWall(val)
    end
})

MovementSection:CreateToggle({
    Name = "Easy Bounce",
    Value = false,
    Callback = function(val)
        notify(val and "Easy Bounce enabled." or "Easy Bounce disabled.", 2)
    end
})

MovementSection:CreateToggle({
    Name = "Auto Trimp",
    Value = false,
    Callback = function(val)
        AutoTrimpEnabled = val
        notify(AutoTrimpEnabled and "Auto Trimp enabled." or "Auto Trimp disabled.", 2)
    end
})

MovementSection:CreateSlider({
    Name = "Trimp Power",
    Min = 50,
    Max = 300,
    Default = 100,
    Callback = function(val)
        TrimpPower = val
    end
})

MovementSection:CreateToggle({
    Name = "Y Lock Surf",
    Value = false,
    Callback = function(val)
        YLockSurfEnabled = val
        if not YLockSurfEnabled then UnlockYPosition() end
        notify(YLockSurfEnabled and "Y Lock Surf enabled." or "Y Lock Surf disabled.", 2)
    end
})

MovementSection:CreateDropdown({
    Name = "Y Lock Mode",
    Options = {"Toggle", "Hold"},
    CurrentOption = "Toggle",
    Callback = function(val)
        YLockSurfMode = val
        if YLockSurfMode == "Hold" then UnlockYPosition() end
    end
})

MovementSection:CreateToggle({
    Name = "Turnbind (A -> Left / D -> Right)",
    Value = false,
    Callback = function(val)
        TurnbindSettings.Enabled = val
        if TurnbindSettings.Enabled then startTurnbind() else stopTurnbind() end
        notify(TurnbindSettings.Enabled and "Turnbind enabled." or "Turnbind disabled.", 2)
    end
})

local ActionsSection = Tabs.Main:CreateSection({ Name = "Emote Actions & Scripts" })

ActionsSection:CreateToggle({
    Name = "360 Emote Hop (A + D)",
    Value = false,
    Callback = function(val)
        Settings.SpinEnabled = val
    end
})

ActionsSection:CreateToggle({
    Name = "Emote Spin",
    Value = false,
    Callback = function(val)
        Settings.TurnEnabled = val
    end
})

ActionsSection:CreateSlider({
    Name = "Emote Turn Speed",
    Min = 1,
    Max = 30,
    Default = 5,
    Callback = function(val)
        Settings.TurnSpeed = math.max(val / 100, 0.001)
    end
})

ActionsSection:CreateToggle({
    Name = "Keyboard Sound Effect",
    Value = false,
    Callback = function(val)
        Settings.keyboardSoundEnabled = val
    end
})

local GistList = {
    {"Downed Surf", "https://gist.githubusercontent.com/sn3514ube16-droid/a80d60ccfc849dfdd05b85825efaa5f1/raw/c1a55d272aa6d35f47bee585a9fc67891a0351a0/DownedSurfV2.lua"},
    {"Any Emote Move", "https://gist.githubusercontent.com/sn3514ube16-droid/b3e5989392ba9a5b6cc1c3b5d81018e1/raw/move%2520with%2520any%2520emote.lua"},
    {"Cactus Hitbox+", "https://gist.githubusercontent.com/sn3514ube16-droid/890c588202cb02654578315837b63249/raw/CactuseSize.lua"},
    {"Faster Emote Turn", "https://gist.githubusercontent.com/sn3514ube16-droid/5937f4dd8f5050a2d6952f42da7b91af/raw/947a15624feab4e75e3e66aba2c501e55229581d/emoteturnspeedFIXED.lua"}
}

for _, entry in ipairs(GistList) do
    ActionsSection:CreateButton({
        Name = "Load " .. entry[1],
        Callback = function()
            pcall(function() loadstring(game:HttpGet(entry[2]))() end)
            notify(entry[1] .. " loaded.", 3)
        end
    })
end

-- VISUALS TAB
local AvatarSection = Tabs.Visuals:CreateSection({ Name = "Avatar & Visuals" })

AvatarSection:CreateToggle({
    Name = "Headless",
    Value = false,
    Callback = function(val)
        Settings.HeadlessEnabled = val
        if LocalPlayer.Character then
            if Settings.HeadlessEnabled then applyHeadless(LocalPlayer.Character) else removeHeadless(LocalPlayer.Character) end
        end
    end
})

AvatarSection:CreateToggle({
    Name = "Korblox Right Leg",
    Value = false,
    Callback = function(val)
        Settings.KorbloxEnabled = val
        if LocalPlayer.Character then
            if Settings.KorbloxEnabled then applyKorblox(LocalPlayer.Character) else removeKorblox(LocalPlayer.Character) end
        end
    end
})

AvatarSection:CreateToggle({
    Name = "Enable FOV Lock",
    Value = false,
    Callback = function(val)
        Settings.FOVEnabled = val
        enforceFOV()
    end
})

AvatarSection:CreateSlider({
    Name = "FOV Value",
    Min = 70,
    Max = 120,
    Default = 93,
    Callback = function(val)
        Settings.FOV = val
        enforceFOV()
    end
})

AvatarSection:CreateToggle({
    Name = "Sunset Shader",
    Value = false,
    Callback = function(val)
        sunsetShaderEnabled = val
        applySunsetShader()
        notify(sunsetShaderEnabled and "Sunset Shader enabled." or "Sunset Shader disabled.", 2)
    end
})

AvatarSection:CreateColorpicker({
    Name = "Global World Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(val)
        globalColor = val
        if globalColorEnabled then applyGlobalColor() end
    end
})

local EmoteSwapperSection = Tabs.Visuals:CreateSection({ Name = "Emote Swapper Setup" })

for i = 1, 6 do
    local idx = i
    EmoteSwapperSection:CreateInput({
        Name = "Owned Emote " .. idx,
        PlaceholderText = "Name",
        Callback = function(txt)
            EmoteSwapper.CurrentEmotes[idx] = txt:gsub("%s+", "")
        end
    })

    EmoteSwapperSection:CreateInput({
        Name = "Wanted Emote " .. idx,
        PlaceholderText = "Name",
        Callback = function(txt)
            EmoteSwapper.SelectedEmotes[idx] = txt:gsub("%s+", "")
        end
    })
end

EmoteSwapperSection:CreateButton({
    Name = "Apply Emote Swapper",
    Callback = function()
        local swappedCount = 0
        for i = 1, 6 do
            local currentEmote = EmoteSwapper.CurrentEmotes[i]
            local selectedEmote = EmoteSwapper.SelectedEmotes[i]
            if currentEmote ~= "" and selectedEmote ~= "" then
                local currentValid, currentActual = isValidEmote(currentEmote)
                local selectedValid, selectedActual = isValidEmote(selectedEmote)
                if currentValid and selectedValid and currentActual ~= selectedActual then
                    if draconicSwapEmote(currentActual, selectedActual) then
                        swappedCount = swappedCount + 1
                    end
                end
            end
        end
        notify("Swapped " .. swappedCount .. " emote(s).", 3)
    end
})

EmoteSwapperSection:CreateButton({
    Name = "Restore Emotes",
    Callback = function()
        if draconicRestoreAllEmotes(false) then
            notify("All emotes restored.", 3)
        end
    end
})

notify("Movement Ware V3 loaded (Nebula UI Edition)!", 4)