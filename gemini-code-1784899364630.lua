-- =====================================================
-- MOVEMENT WARE V3 - KAMIBLOX MIGRATED VERSION
-- =====================================================

local Kamiblox = loadstring(game:HttpGet("https://raw.githubusercontent.com/kamiblox/UI/main/Library.lua"))()

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
    local ok = pcall(function()
        Kamiblox:Notify({
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
-- KAMIBLOX WINDOW & TABS SETUP
-- =====================================================

local Window = Kamiblox:CreateWindow({
    Title = "Movement Ware V3",
    SubTitle = "Kamiblox Edition",
    Size = UDim2.fromOffset(580, 460)
})

local Tabs = {
    Main = Window:CreateTab("Main"),
    Visuals = Window:CreateTab("Visuals"),
    Maps = Window:CreateTab("Maps"),
    TAS = Window:CreateTab("TAS"),
    Config = Window:CreateTab("Config")
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
    if DraconicSwapper.IsProcessing then
        return false
    end
    DraconicSwapper.IsProcessing = true

    local success, result = pcall(function()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then
            return false
        end

        local emotesFolder = items:FindFirstChild("Emotes")
        if not emotesFolder then
            return false
        end

        local targetObj = emotesFolder:FindFirstChild(targetEmote)
        local replacementObj = emotesFolder:FindFirstChild(replacementEmote)
        if not targetObj or not replacementObj then
            warn("Draconic Swapper: Missing emotes - Target:", targetEmote, "Replacement:", replacementEmote)
            return false
        end

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

        print("Draconic Swapper: Successfully swapped", targetEmote, "<->", replacementEmote)
        return true
    end)

    DraconicSwapper.IsProcessing = false
    return success and result or false
end

local function draconicRestoreEmote(targetEmote, replacementEmote)
    if DraconicSwapper.IsProcessing then
        return false
    end
    DraconicSwapper.IsProcessing = true

    local success, result = pcall(function()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then
            return false
        end

        local emotesFolder = items:FindFirstChild("Emotes")
        if not emotesFolder then
            return false
        end

        local targetObj = emotesFolder:FindFirstChild(replacementEmote)
        local replacementObj = emotesFolder:FindFirstChild(targetEmote)
        if not targetObj or not replacementObj then
            warn("Draconic Swapper: Cannot restore - missing emotes for", targetEmote)
            return false
        end

        local tempSuffix = "_DraconicRestore_" .. tostring(tick()):gsub("%.", "_")
        local tempName = targetEmote .. tempSuffix
        while emotesFolder:FindFirstChild(tempName) do
            tempName = tempName .. "_"
        end

        targetObj.Name = tempName
        replacementObj.Name = replacementEmote
        targetObj.Name = targetEmote

        print("Draconic Swapper: Successfully restored", targetEmote, "to original")
        return true
    end)

    DraconicSwapper.IsProcessing = false
    return success and result or false
end

local function draconicRestoreAllEmotes(keepOriginalPairs)
    if not next(DraconicSwapper.SwappedPairs) then
        return true
    end

    local savedOriginals = {}
    if keepOriginalPairs then
        for targetEmote, replacementEmote in pairs(DraconicSwapper.OriginalPairs) do
            savedOriginals[targetEmote] = replacementEmote
        end
    end

    local restoredCount = 0
    local failedCount = 0
    for targetEmote, replacementEmote in pairs(DraconicSwapper.SwappedPairs) do
        if draconicRestoreEmote(targetEmote, replacementEmote) then
            restoredCount = restoredCount + 1
        else
            failedCount = failedCount + 1
        end
    end

    DraconicSwapper.SwappedPairs = {}
    DraconicSwapper.OriginalPairs = keepOriginalPairs and savedOriginals or {}

    print("Draconic Swapper: Restoration complete - Restored:", restoredCount, "Failed:", failedCount)
    return restoredCount > 0
end

local function detectRoundEnd()
    local aliveCount = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        local character = plr.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            aliveCount = aliveCount + 1
        end
    end
    return aliveCount <= 1
end

task.spawn(function()
    local lastCheck = false
    local roundEndCooldown = false

    while true do
        task.wait(2)

        if roundEndCooldown then
            task.wait(8)
            roundEndCooldown = false
            continue
        end

        local currentCheck = detectRoundEnd()
        if DraconicSwapper.RoundActive and currentCheck and not lastCheck then
            DraconicSwapper.RoundActive = false
            if next(DraconicSwapper.SwappedPairs) then
                print("Draconic Swapper: Round ended - Auto-restoring emotes...")
                draconicRestoreAllEmotes(false)
                roundEndCooldown = true
            end
        elseif not DraconicSwapper.RoundActive and not currentCheck then
            DraconicSwapper.RoundActive = true
            print("Draconic Swapper: New round detected")
        end

        lastCheck = currentCheck
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if next(DraconicSwapper.SwappedPairs) then
        print("Draconic Swapper: Character removing - Auto-restoring emotes...")
        draconicRestoreAllEmotes(Settings.AutoApplyDraconicEmoteSwapper)
    end
end)

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
-- AUTO TRIMP
-- =====================================================

local AutoTrimpEnabled = false
local TrimpPower = 100
local MinSpeed = 30

local lastTrimp = 0
local cooldown = 0.2

local function DoTrimp()
    if not AutoTrimpEnabled then return end

    local now = tick()
    if now - lastTrimp < cooldown then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local vel = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    if speed < MinSpeed then return end
    if vel.Y > 0 then return end

    local rayOrigin = hrp.Position
    local rayDirection = Vector3.new(0, -3, 0)
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection)
    
    if not raycastResult then return end

    lastTrimp = now
    local newVel = Vector3.new(vel.X * 0.8, TrimpPower, vel.Z * 0.8)
    hrp.AssemblyLinearVelocity = newVel
end

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
local AirStrafeOriginals = {
    Tables = {},
    Humanoids = {}
}

local AirStrafeScanned = false
local AirStrafeApplyDebounce = false

local speedProps = {"Speed", "speed", "WalkSpeed", "walkSpeed", "MoveSpeed", "moveSpeed"}
local strafeProps = {
    "AirStrafeAcceleration", "airStrafeAcceleration", "StrafeAcceleration", "strafeAcceleration",
    "AirAcceleration", "airAcceleration", "StrafeAccel", "strafeAccel",
    "AirStrafe", "airStrafe", "StrafeForce", "strafeForce",
    "AirControl", "airControl", "StrafeControl", "strafeControl"
}
local jumpProps = {
    "JumpHeight", "jumpHeight", "JumpPower", "jumpPower",
    "JumpForce", "jumpForce", "JumpVelocity", "jumpVelocity"
}

local function rememberAirStrafeTableValue(tbl, prop)
    local saved = AirStrafeOriginals.Tables[tbl]
    if not saved then
        saved = {}
        AirStrafeOriginals.Tables[tbl] = saved
    end
    if saved[prop] == nil then
        saved[prop] = rawget(tbl, prop)
    end
end

local function applyToKnownTables()
    for tbl, props in pairs(AirStrafeOriginals.Tables) do
        if type(tbl) == "table" then
            pcall(function()
                for prop, _ in pairs(props) do
                    local current = rawget(tbl, prop)
                    if current ~= nil and type(current) == "number" then
                        local isSpeed, isStrafe, isJump = false, false, false
                        for _, sp in ipairs(speedProps) do if sp == prop then isSpeed = true break end end
                        if not isSpeed then
                            for _, sp in ipairs(strafeProps) do if sp == prop then isStrafe = true break end end
                        end
                        if not isSpeed and not isStrafe then
                            for _, sp in ipairs(jumpProps) do if sp == prop then isJump = true break end end
                        end
                        if isSpeed then rawset(tbl, prop, AirStrafeSpeedValue)
                        elseif isStrafe then rawset(tbl, prop, AirStrafeAcceleration)
                        elseif isJump then rawset(tbl, prop, AirStrafeJumpHeight)
                        end
                    end
                end
            end)
        end
    end
end

local function applyMovementTableValues(tbl)
    local successCount = 0
    for _, prop in pairs(speedProps) do
        local v = rawget(tbl, prop)
        if v ~= nil and type(v) == "number" then
            rememberAirStrafeTableValue(tbl, prop)
            rawset(tbl, prop, AirStrafeSpeedValue)
            successCount = successCount + 1
        end
    end
    for _, prop in pairs(strafeProps) do
        local v = rawget(tbl, prop)
        if v ~= nil and type(v) == "number" then
            rememberAirStrafeTableValue(tbl, prop)
            rawset(tbl, prop, AirStrafeAcceleration)
            successCount = successCount + 1
        end
    end
    for _, prop in pairs(jumpProps) do
        local v = rawget(tbl, prop)
        if v ~= nil and type(v) == "number" then
            rememberAirStrafeTableValue(tbl, prop)
            rawset(tbl, prop, AirStrafeJumpHeight)
            successCount = successCount + 1
        end
    end
    return successCount
end

local function applyAirStrafeToHumanoid(humanoid)
    if not AirStrafeOriginals.Humanoids[humanoid] then
        AirStrafeOriginals.Humanoids[humanoid] = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight
        }
    end
    humanoid.WalkSpeed = AirStrafeSpeedValue / 50
    humanoid.JumpPower = AirStrafeJumpHeight * 30
end

local function updateAirStrafeValues()
    if not AirStrafeSpeedEnabled then return end
    if AirStrafeApplyDebounce then return end
    AirStrafeApplyDebounce = true
    task.defer(function()
        AirStrafeApplyDebounce = false
        if not AirStrafeSpeedEnabled then return end
        applyToKnownTables()
        pcall(function()
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    applyAirStrafeToHumanoid(humanoid)
                end
            end
        end)
    end)
end

local function applyAirStrafeModifications()
    local successCount = 0

    if not AirStrafeScanned then
        AirStrafeScanned = true
        pcall(function()
            if type(getgc) ~= "function" then return end
            local gcObjects = getgc(true)
            if not gcObjects then return end
            for i = 1, #gcObjects do
                local obj = gcObjects[i]
                if type(obj) == "table" then
                    successCount = successCount + applyMovementTableValues(obj)
                end
            end
        end)

        pcall(function()
            for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("ModuleScript") then
                    pcall(function()
                        local module = require(obj)
                        if type(module) == "table" then
                            successCount = successCount + applyMovementTableValues(module)
                        end
                    end)
                end
            end
        end)
    else
        applyToKnownTables()
    end

    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                applyAirStrafeToHumanoid(humanoid)
                successCount = successCount + 2
            end
        end
    end)

    return successCount
end

local function restoreAirStrafeModifications()
    for tbl, props in pairs(AirStrafeOriginals.Tables) do
        if type(tbl) == "table" then
            for prop, originalValue in pairs(props) do
                pcall(function()
                    rawset(tbl, prop, originalValue)
                end)
            end
        end
    end

    for humanoid, saved in pairs(AirStrafeOriginals.Humanoids) do
        if humanoid and humanoid.Parent then
            pcall(function()
                humanoid.WalkSpeed = saved.WalkSpeed or 16
                humanoid.JumpPower = saved.JumpPower or 50
            end)
        end
    end

    AirStrafeOriginals.Tables = {}
    AirStrafeOriginals.Humanoids = {}
    AirStrafeScanned = false
    notify("Air Strafe Speed disabled", 3)
end

local YLockSurfEnabled = false
local YLockSurfMode = "Toggle"
local YLockSurfKey = Enum.KeyCode.X
local isYLocked = false
local lockedY = nil
local originalHipHeight = nil

local function LockYPosition()
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    lockedY = hrp.Position.Y
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        originalHipHeight = hum.HipHeight
    end
    isYLocked = true
end

local function UnlockYPosition()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and originalHipHeight then
        hum.HipHeight = originalHipHeight
    end

    isYLocked = false
    lockedY = nil
    originalHipHeight = nil
end

local function MaintainYLock()
    if not isYLocked then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not lockedY then return end

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
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(hrp.Position, direcao * (distancia + 2.5), raycastParams)
end

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
        pcall(function() conn:Disconnect() end)
    end
    crouchConnections = {}
end

local function startCrouchDetect()
    clearCrouchConnections()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local baseHipHeight = hum.HipHeight
    local baseWalkSpeed = hum.WalkSpeed

    table.insert(crouchConnections, hum:GetPropertyChangedSignal("HipHeight"):Connect(function()
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end
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
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end
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
        if not (Settings.PCFlyEnabled or Settings.MobileFlyEnabled) then return end
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
    if not Settings.keyboardSoundEnabled then return end
    local useSound2 = math.random(1, 100) <= 50
    local s = useSound2 and baseSound2:Clone() or baseSound:Clone()
    s.Parent = SoundService
    s.PlaybackSpeed = 0.9 + (math.random() * 0.2)
    s.Volume = 0.9 + (math.random() * 0.3)
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
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
    if not target then return end

    local mainCol = customColor or WINE_CONFIG.TrueWine
    local skinParts = {
        ["Head"] = true, ["Torso"] = true, ["Left Arm"] = true, ["Right Arm"] = true,
        ["Left Leg"] = true, ["Right Leg"] = true, ["LeftUpperArm"] = true, ["RightUpperArm"] = true,
        ["LeftLowerArm"] = true, ["RightLowerArm"] = true, ["LeftHand"] = true, ["RightHand"] = true,
        ["LeftUpperLeg"] = true, ["RightUpperLeg"] = true, ["LeftLowerLeg"] = true, ["RightLowerLeg"] = true,
        ["LeftFoot"] = true, ["RightFoot"] = true, ["UpperTorso"] = true, ["LowerTorso"] = true
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

local function getKorbloxRightLeg(char)
    if not char then return nil end
    return char:FindFirstChild("Right Leg")
        or char:FindFirstChild("RightLowerLeg")
        or char:FindFirstChild("RightUpperLeg")
end

local function saveKorbloxLegOriginals(char, rLeg)
    if not char or not rLeg then return end

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
    if not char or not Settings.KorbloxEnabled then return false end
    local rLeg = getKorbloxRightLeg(char)
    if not rLeg then return false end

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
    if not char then return false end

    local mesh = char:FindFirstChild("KorbloxMesh")
    if mesh then mesh:Destroy() end

    local rLeg = getKorbloxRightLeg(char)
    if rLeg then
        local originalColor = rLeg:GetAttribute(KORBLOX_COLOR_ATTR) or char:GetAttribute("OriginalLegColor")
        rLeg.Color = originalColor or Color3.fromRGB(163, 162, 165)

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
    if not char or not Settings.HeadlessEnabled then return false end

    local head = char:FindFirstChild("Head")
    if not head then return false end

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
    if not char then return false end

    local head = char:FindFirstChild("Head")
    if not head then return false end

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
            if token ~= avatarCosmeticRetryToken then return end
            if not char or char ~= LocalPlayer.Character then return end

            if Settings.HeadlessEnabled then applyHeadless(char) end
            if Settings.KorbloxEnabled then applyKorblox(char) end

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
            pcall(function() emoteInfo["SpeedMult"] = speedMult end)
        end
    end
    NonMovableEmoteOriginals = {}
end

local lastFP = nil
local function updateVFXFirstPerson(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or not camera then return end

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
-- INPUT CONNECTION / SHORTCUTS
-- =====================================================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    pcall(function()
        if YLockSurfEnabled and input.KeyCode == YLockSurfKey then
            if YLockSurfMode == "Toggle" then
                if isYLocked then UnlockYPosition() else LockYPosition() end
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
        if YLockSurfEnabled and YLockSurfMode == "Hold" and input.KeyCode == YLockSurfKey then
            UnlockYPosition()
        end
    end)

    if not executando then return end

    pcall(function()
        if input.KeyCode == Enum.KeyCode.LeftControl then
            descendoCTRL = false
            vAtualDescida = 0
            emEstadoDeBounce = false
        end
    end)
end)

-- =====================================================
-- FOV / RENDER LOOPS
-- =====================================================

local fovSignalConn = nil
local originalFOV = nil

local function enforceFOV()
    camera = Workspace.CurrentCamera
    if camera then
        if Settings.FOVEnabled then
            if originalFOV == nil then originalFOV = camera.FieldOfView end
            if camera.FieldOfView ~= Settings.FOV then
                camera.FieldOfView = Settings.FOV
            end
        else
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
    if not hrp then return end

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

    if YLockSurfEnabled then MaintainYLock() end

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
                        if vAtualSubida < 0 then vAtualSubida = 0 end
                        vFinal = vAtualSubida
                    else
                        local chao = detectaObjeto(Vector3.new(0, -1, 0), distanciaChaoBounce)
                        if chao and not emEstadoDeBounce then
                            emEstadoDeBounce = true
                            vAtualDescida = -forcaBounce
                        end

                        if emEstadoDeBounce then
                            vAtualDescida = vAtualDescida + (Workspace.Gravity * dt)
                            if vAtualDescida >= 0 then emEstadoDeBounce = false end
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

-- =====================================================
-- CHARACTER RESPAWN HANDLER
-- =====================================================

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)

    isYLocked = false
    lockedY = nil
    originalHipHeight = nil
    resetVirtualStrafe()
    if EasyBounceEnabled then refreshEasyBounceCharacter(char) end

    if Settings.HeadlessEnabled or Settings.KorbloxEnabled then
        applyAvatarCosmeticsWithRetries(char)
    end

    if Settings.AutoApplyCosmetic then applyDeepWineLogic(char) end

    if Settings.AutoApplyGlobalColor and globalColorEnabled then
        task.wait(0.5)
        applyGlobalColor()
    end

    if Settings.AutoApplySkyColor and skyColorEnabled then applySkyColor() end
    if Settings.AutoApplyPerfectFog and perfectFogEnabled then applyPerfectFog() end

    if AirStrafeSpeedEnabled then
        task.wait(1)
        applyAirStrafeModifications()
    end

    if NonMovableEmoteHopEnabled then pcall(applyNonMovableEmoteHop) end

    if Settings.PCFlyEnabled or Settings.MobileFlyEnabled then
        task.wait(0.2)
        updateFlyVelocity()
        startCrouchDetect()
    end
end)

-- =====================================================
-- UI INTEGRATION - KAMIBLOX
-- =====================================================

-- MAIN TAB
local MovementSection = Tabs.Main:CreateSection("Movement Mechanics")

MovementSection:CreateToggle({
    Name = "Air Strafe Speed",
    Value = false,
    Callback = function(val)
        AirStrafeSpeedEnabled = val
        if AirStrafeSpeedEnabled then
            applyAirStrafeModifications()
            notify("Air Strafe Speed enabled.", 2)
        else
            restoreAirStrafeModifications()
            notify("Air Strafe Speed disabled.", 2)
        end
    end
})

MovementSection:CreateSlider({
    Name = "Strafe Speed Value",
    Min = 100,
    Max = 5000,
    Default = 1500,
    Callback = function(val)
        AirStrafeSpeedValue = val
        updateAirStrafeValues()
    end
})

MovementSection:CreateSlider({
    Name = "Jump Height",
    Min = 1,
    Max = 10,
    Default = 3,
    Callback = function(val)
        AirStrafeJumpHeight = val
        updateAirStrafeValues()
    end
})

MovementSection:CreateToggle({
    Name = "Virtual Strafe",
    Value = false,
    Callback = function(val)
        VirtualStrafeEnabled = val
        if not VirtualStrafeEnabled then
            currentSpeed = 0
            moveDir = Vector3.new(0, 0, 0)
        end
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
        if Settings.PCFlyEnabled then startCrouchDetect() else clearCrouchConnections() end
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
    Name = "Easy Edge Trimp",
    Value = false,
    Callback = function(val)
        Settings.TrimpEnabled = val
    end
})

MovementSection:CreateToggle({
    Name = "Easy Bounce",
    Value = false,
    Callback = function(val)
        EasyBounceEnabled = val
        if EasyBounceEnabled then
            easyBounceHistory = {}
            refreshEasyBounceCharacter(LocalPlayer.Character)
        end
        notify(EasyBounceEnabled and "Easy Bounce enabled." or "Easy Bounce disabled.", 2)
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
    Default = "Toggle",
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
        if TurnbindSettings.Enabled then
            startTurnbind()
            notify("Turnbind enabled.", 2)
        else
            stopTurnbind()
            notify("Turnbind disabled.", 2)
        end
    end
})

local ActionsSection = Tabs.Main:CreateSection("Emote Actions & Scripts")

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
    Name = "Nonmovable Emote Hop",
    Value = false,
    Callback = function(val)
        NonMovableEmoteHopEnabled = val
        if NonMovableEmoteHopEnabled then
            local fixedCount = 0
            pcall(function() fixedCount = applyNonMovableEmoteHop() end)
            notify("Nonmovable Emote Hop enabled. Fixed: " .. tostring(fixedCount), 3)
        else
            pcall(restoreNonMovableEmoteHop)
            notify("Nonmovable Emote Hop disabled.", 2)
        end
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
local AvatarSection = Tabs.Visuals:CreateSection("Avatar & Visuals")

AvatarSection:CreateToggle({
    Name = "Headless",
    Value = false,
    Callback = function(val)
        Settings.HeadlessEnabled = val
        if LocalPlayer.Character then
            if Settings.HeadlessEnabled then
                applyAvatarCosmeticsWithRetries(LocalPlayer.Character)
            else
                pcall(function() removeHeadless(LocalPlayer.Character) end)
            end
        end
    end
})

AvatarSection:CreateToggle({
    Name = "Korblox Right Leg",
    Value = false,
    Callback = function(val)
        Settings.KorbloxEnabled = val
        if LocalPlayer.Character then
            if Settings.KorbloxEnabled then
                applyAvatarCosmeticsWithRetries(LocalPlayer.Character)
            else
                pcall(function() removeKorblox(LocalPlayer.Character) end)
            end
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

AvatarSection:CreateColorPicker({
    Name = "Global World Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(val)
        globalColor = val
        if globalColorEnabled then applyGlobalColor() end
    end
})

local EmoteSwapperSection = Tabs.Visuals:CreateSection("Emote Swapper Setup")

for i = 1, 6 do
    local idx = i
    EmoteSwapperSection:CreateInput({
        Name = "Owned Emote " .. idx,
        Placeholder = "Name",
        Callback = function(txt)
            EmoteSwapper.CurrentEmotes[idx] = txt:gsub("%s+", "")
        end
    })
    EmoteSwapperSection:CreateInput({
        Name = "Wanted Emote " .. idx,
        Placeholder = "Name",
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

notify("Movement Ware V3 loaded cleanly!", 4)