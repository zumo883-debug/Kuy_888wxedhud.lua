-- =================================================================
-- WXED HUD - Red Knife Duel (Full Clean Code - Fixed & Tested)
-- =================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- โหลด Fluent UI Library
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not success or not Fluent then return end

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- สถานะการทำงานทั้งหมด
local currentSize = 5.0
local isHeadActive = true
local isEspActive = true
local isNpcEspActive = true
local normalFarmActive = false
local boxFarmActive = false
local rapidFireActive = false
local fastReloadActive = false
local infAmmoActive = false
local noclipActive = false
local killAllActive = false

-- พิกัดจุดฟาร์มกล่อง / ส่งของ
local PICKUP_POS = Vector3.new(-294.2, 25.0, 36.6)
local WAYPOINT_POS = Vector3.new(-237.8, 25.0, 188.7)
local DROPOFF_POS = Vector3.new(456.1, 25.8, 176.4)

local lastInteractTime = 0
local blacklistedPrompts = {}

-- กันหลุด Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end)

-- หน้าต่าง Fluent UI
local Window = Fluent:CreateWindow({
    Title = "💜 WXED HUD | ดวลมีดแดง Ultimate",
    SubTitle = "by WXED",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- ปุ่มลอยบนมือถือ
local MobileGui = Instance.new("ScreenGui", PlayerGui)
MobileGui.Name = "WxedMobileToggle"
MobileGui.ResetOnSpawn = false

local ToggleBtn = Instance.new("ImageButton", MobileGui)
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 65)
ToggleBtn.Image = "rbxassetid://100536037895293"
ToggleBtn.Draggable = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local BtnStroke = Instance.new("UIStroke", ToggleBtn)
BtnStroke.Color = Color3.fromRGB(215, 65, 255)
BtnStroke.Thickness = 2

ToggleBtn.MouseButton1Click:Connect(function()
    pcall(function() Window:Minimize() end)
end)

-- แท็บเมนู
local FarmTab = Window:AddTab({ Title = "🌾 ฟาร์ม", Icon = "package" })
local CombatTab = Window:AddTab({ Title = "⚔️ ต่อสู้/ยิง", Icon = "sword" })
local VisualTab = Window:AddTab({ Title = "👁️ ESP/ตัวละคร", Icon = "eye" })
local SettingsTab = Window:AddTab({ Title = "⚙️ ตั้งค่า", Icon = "settings" })

local Options = Fluent.Options

-- ==================== แท็บฟาร์ม ====================
FarmTab:AddToggle("NormalFarmToggle", {
    Title = "📦 ฟาร์มปกติ (กดอัตโนมัติรอบตัว - กันปีน)",
    Default = false
}):OnChanged(function(Value)
    normalFarmActive = Value
    if Value then boxFarmActive = false if Options.BoxFarmToggle then Options.BoxFarmToggle:SetValue(false) end end
end)

FarmTab:AddToggle("BoxFarmToggle", {
    Title = "📦 ฟาร์มกล่องอัจฉริยะ (หยิบ ➔ ส่ง)",
    Default = false
}):OnChanged(function(Value)
    boxFarmActive = Value
    if Value then normalFarmActive = false if Options.NormalFarmToggle then Options.NormalFarmToggle:SetValue(false) end end
end)

FarmTab:AddToggle("NoclipToggle", {
    Title = "👻 เดินทะลุสิ่งกีดขวาง (Noclip)",
    Default = false
}):OnChanged(function(Value)
    noclipActive = Value
end)

-- ==================== แท็บต่อสู้/ยิง ====================
CombatTab:AddToggle("KillAllToggle", {
    Title = "💀 ฆ่าทั้งหมด (Kill All / Auto Attack)",
    Default = false
}):OnChanged(function(Value)
    killAllActive = Value
end)

CombatTab:AddToggle("RapidFireToggle", {
    Title = "🔥 ยิงรัวกระสุน (Rapid Fire)",
    Default = false
}):OnChanged(function(Value)
    rapidFireActive = Value
end)

CombatTab:AddToggle("FastReloadToggle", {
    Title = "⚡ รีโหลดไว (Fast Reload)",
    Default = false
}):OnChanged(function(Value)
    fastReloadActive = Value
end)

CombatTab:AddToggle("InfAmmoToggle", {
    Title = "♾️ กระสุนไม่จำกัด (Infinite Ammo)",
    Default = false
}):OnChanged(function(Value)
    infAmmoActive = Value
end)

-- ==================== แท็บ ESP/ตัวละคร ====================
VisualTab:AddToggle("HeadToggle", {
    Title = "🎯 ระบบหัวใหญ่ (Head Expander)",
    Default = true
}):OnChanged(function(Value)
    isHeadActive = Value
end)

VisualTab:AddInput("HeadSizeInput", {
    Title = "📏 พิมพ์ขนาดหัว (เช่น 5, 10, 20)",
    Default = "5.0",
    Numeric = true,
    Finished = true,
    Placeholder = "ใส่ตัวเลขขนาดหัว...",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            currentSize = num
            Fluent:Notify({ Title = "ปรับขนาดสำเร็จ", Content = "ขนาดหัวถูกเปลี่ยนเป็น " .. tostring(num) .. "x แล้ว", Duration = 2 })
        end
    end
})

VisualTab:AddToggle("EspToggle", {
    Title = "👁️ มองทะลุผู้เล่น (ESP สีม่วง)",
    Default = true
}):OnChanged(function(Value)
    isEspActive = Value
end)

VisualTab:AddToggle("NpcEspToggle", {
    Title = "📍 มองทะลุเฉพาะ NPC ที่กด E/ตอบโต้ได้",
    Default = true
}):OnChanged(function(Value)
    isNpcEspActive = Value
    if not Value then
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Highlight") and obj.Name == "NpcInteractiveHighlight" then
                    obj:Destroy()
                end
            end
        end)
    end
end)

-- ==================== แท็บตั้งค่า ====================
local FpsGui = Instance.new("ScreenGui", PlayerGui)
FpsGui.Name = "WxedFpsDisplay"
FpsGui.ResetOnSpawn = false

local FpsLabel = Instance.new("TextLabel", FpsGui)
FpsLabel.Size = UDim2.new(0, 160, 0, 30)
FpsLabel.Position = UDim2.new(0, 15, 0, 70)
FpsLabel.BackgroundTransparency = 0.3
FpsLabel.BackgroundColor3 = Color3.fromRGB(35, 15, 50)
FpsLabel.TextColor3 = Color3.fromRGB(225, 120, 255)
FpsLabel.TextSize = 13
FpsLabel.Font = Enum.Font.GothamBold
FpsLabel.Text = " FPS: 60 | Ping: 0ms"
Instance.new("UICorner", FpsLabel).CornerRadius = UDim.new(0, 6)
local LabelStroke = Instance.new("UIStroke", FpsLabel)
LabelStroke.Color = Color3.fromRGB(215, 65, 255)
LabelStroke.Thickness = 1

SettingsTab:AddToggle("ShowFpsToggle", {
    Title = "📊 แสดง FPS & Ping บนหน้าจอ",
    Default = true
}):OnChanged(function(Value)
    FpsGui.Enabled = Value
end)

SettingsTab:AddButton({
    Title = "🎨 โหมดภาพดินน้ำมัน (ลดแลค)",
    Callback = function()
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v:IsA("MeshPart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                end
            end
        end)
        Fluent:Notify({ Title = "สำเร็จ!", Content = "เปิดโหมดภาพดินน้ำมันเรียบร้อย", Duration = 2 })
    end
})

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("WxedHub_RedKnife")
InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

Window:SelectTab(1)

-- =================================================================
-- CORE LOOPS
-- =================================================================

-- 1. ระบบ Noclip
RunService.Stepped:Connect(function()
    pcall(function()
        if noclipActive and LocalPlayer.Character then
            local char = LocalPlayer.Character
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Name == "HumanoidRootPart" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Torso" or part.Name == "Head" then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

-- 2. ลูปจัดการ FPS, หัวใหญ่, และ ESP
local lastUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    if tick() - lastUpdate >= 0.5 then
        lastUpdate = tick()
        local currentFps = math.clamp(math.floor(1 / dt + 0.5), 1, 300)
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        FpsLabel.Text = string.format(" FPS: %d | Ping: %dms", currentFps, ping)
    end

    -- หัวใหญ่ & ESP ผู้เล่น (มองทะลุสีม่วง)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            
            if isHeadActive and head then
                head.CanCollide = false
                head.Massless = true
                for _, child in pairs(head:GetChildren()) do
                    if child:IsA("SpecialMesh") or child:IsA("CharacterMesh") then
                        child:Destroy()
                    end
                end
                head.Size = Vector3.new(currentSize, currentSize, currentSize)
            end
            
            local highlight = char:FindFirstChild("ESPHighlight")
            if not highlight then
                highlight = Instance.new("Highlight", char)
                highlight.Name = "ESPHighlight"
                highlight.Adornee = char
                highlight.FillColor = Color3.fromRGB(180, 60, 255)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0
            end
            highlight.Enabled = isEspActive
        end
    end

    -- มองทะลุเฉพาะ NPC ที่มี ProximityPrompt
    if isNpcEspActive then
        pcall(function()
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local p = prompt.Parent
                    local targetModel = nil
                    if p then
                        if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then
                            targetModel = p
                        elseif p.Parent and p.Parent:IsA("Model") and p.Parent:FindFirstChildOfClass("Humanoid") then
                            targetModel = p.Parent
                        end
                    end
                    if targetModel and targetModel ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(targetModel) then
                        local npcHi = targetModel:FindFirstChild("NpcInteractiveHighlight")
                        if not npcHi then
                            npcHi = Instance.new("Highlight", targetModel)
                            npcHi.Name = "NpcInteractiveHighlight"
                            npcHi.Adornee = targetModel
                            npcHi.FillColor = Color3.fromRGB(0, 255, 200)
                            npcHi.FillTransparency = 0.3
                            npcHi.OutlineColor = Color3.fromRGB(255, 255, 255)
                            npcHi.OutlineTransparency = 0
                        end
                        npcHi.Enabled = true
                    end
                end
            end
        end)
    end
end)

-- 3. ระบบยิงรัว, รีโหลดไว, กระสุนไม่จำกัด & ฆ่าทั้งหมด (Kill All)
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local tools = {}
        for _, v in pairs(char:GetChildren()) do if v:IsA("Tool") then table.insert(tools, v) end end
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") then table.insert(tools, v) end end end

        -- ฆ่าทั้งหมด (Kill All)
        if killAllActive and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            for _, target in pairs(Players:GetPlayers()) do
                if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = target.Character.HumanoidRootPart
                    if (root.Position - targetRoot.Position).Magnitude <= 25 then
                        local toolObj = char:FindFirstChildOfClass("Tool")
                        if toolObj then toolObj:Activate() end
                    end
                end
            end
        end

        for _, tool in pairs(tools) do
            if rapidFireActive then tool:Activate() end
            
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local name = string.lower(v.Name)
                    if rapidFireActive and (name:find("cooldown") or name:find("firerate") or name:find("delay") or name:find("fire") or name:find("wait") or name:find("speed")) then
                        v.Value = 0.001
                    end
                    if fastReloadActive and (name:find("reload") or name:find("reloadtime")) then
                        v.Value = 0.01
                    end
                    if infAmmoActive and (name:find("ammo") or name:find("clip") or name:find("bullet") or name:find("magazine") or name:find("stored")) then
                        v.Value = 9999
                    end
                end
            end
            
            if rapidFireActive then
                tool:SetAttribute("FireRate", 0.001)
                tool:SetAttribute("CoolDown", 0.001)
                tool:SetAttribute("Delay", 0.001)
            end
            if fastReloadActive then tool:SetAttribute("ReloadTime", 0.01) end
            if infAmmoActive then
                tool:SetAttribute("Ammo", 9999)
                tool:SetAttribute("MaxAmmo", 9999)
                tool:SetAttribute("StoredAmmo", 9999)
                tool:SetAttribute("Clip", 9999)
                tool:SetAttribute("Bullets", 9999)
            end
        end
    end)
end)

-- 4. ระบบฟาร์มกล่อง & ฟาร์มปกติ (คำนวณจุดยืน 3.5 studs กันปีน + กด E ชัวร์ 100%)
local function safePrompt()
    local interacted = false
    pcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Enabled and not blacklistedPrompts[v] then
                local p = v.Parent
                local pos = p:IsA("BasePart") and p.Position or (p:IsA("Model") and p:GetPivot().Position or nil)
                if pos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude <= (v.MaxActivationDistance or 14) then
                        local h = v.HoldDuration or 0
                        if v.InputHoldBegin then v:InputHoldBegin() end
                        task.wait(h + 0.2)
                        if v.InputHoldEnd then v:InputHoldEnd() end
                        if fireproximityprompt then fireproximityprompt(v) end
                        blacklistedPrompts[v] = tick() + 3
                        interacted = true
                        break
                    end
                end
            end
        end
    end)
    return interacted
end

local function hasBox()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and (string.find(string.lower(v.Name), "box") or string.find(string.lower(v.Name), "crate") or string.find(string.lower(v.Name), "กล่อง")) then
            return true
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") and (string.find(string.lower(v.Name), "box") or string.find(string.lower(v.Name), "crate") or string.find(string.lower(v.Name), "กล่อง")) then
                return true
            end
        end
    end
    return false
end

local function equipBox()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if char and bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") and (string.find(string.lower(t.Name), "box") or string.find(string.lower(t.Name), "crate") or string.find(string.lower(t.Name), "กล่อง")) then
                t.Parent = char
                break
            end
        end
    end
end

local function getStandPosition(targetPos, playerPos)
    local direction = (playerPos - targetPos).Unit
    return targetPos + (direction * 3.5)
end

local function forceTriggerPrompt(targetPrompt)
    pcall(function()
        if targetPrompt and targetPrompt.Enabled then
            local h = targetPrompt.HoldDuration or 0
            if targetPrompt.InputHoldBegin then targetPrompt:InputHoldBegin() end
            if h > 0 then task.wait(h + 0.1) else task.wait(0.1) end
            if targetPrompt.InputHoldEnd then targetPrompt:InputHoldEnd() end
            if fireproximityprompt then fireproximityprompt(targetPrompt) end
        end
    end)
end

task.spawn(function()
    while true do
        pcall(function()
            local currentTime = tick()
            for k, expire in pairs(blacklistedPrompts) do
                if currentTime > expire then blacklistedPrompts[k] = nil end
            end

            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
                local hum, root = char.Humanoid, char.HumanoidRootPart
                
                -- 1. ฟาร์มปกติ (เดินไปยืน แล้วสุ่มจังหวะกด E ค้างแบบเนียนๆ)
                if normalFarmActive then
                    local closestPrompt, closestDist, targetPos = nil, math.huge, nil
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled and not blacklistedPrompts[obj] then
                            local p = obj.Parent
                            local pos = p:IsA("BasePart") and p.Position or (p:IsA("Model") and p:GetPivot().Position or nil)
                            if pos then
                                local dist = (root.Position - pos).Magnitude
                                if dist <= 25 and dist < closestDist then
                                    closestDist = dist
                                    closestPrompt = obj
                                    targetPos = pos
                                end
                            end
                        end
                    end
                    
                    if closestPrompt and targetPos then
                        local standPos = getStandPosition(targetPos, root.Position)
                        if closestDist > 4.0 then
                            hum:MoveTo(Vector3.new(standPos.X, root.Position.Y, standPos.Z))
                        else
                            hum:MoveTo(root.Position)
                            -- สุ่มเวลาหน่วงระหว่าง 1.2 ถึง 1.8 วินาที กันตรวจจับ Bot Pattern
                            local randomDelay = 1.2 + (math.random(0, 600) / 1000)
                            if (currentTime - lastInteractTime) >= randomDelay then
                                lastInteractTime = currentTime
                                pcall(function()
                                    task.wait(math.random(10, 25) / 100) -- Humanizing delay ก่อนกด (0.1 - 0.25s)
                                    forceTriggerPrompt(closestPrompt)
                                    blacklistedPrompts[closestPrompt] = tick() + 3
                                end)
                            end
                        end
                    end

                -- 2. ฟาร์มกล่องอัจฉริยะ (หยิบ ➔ เดินไปส่ง + ระบบสุ่มหน่วงเวลา)
                elseif boxFarmActive then
                    local randomDelay = 1.2 + (math.random(0, 600) / 1000)
                    if hasBox() then
                        equipBox()
                        local distToDrop = (root.Position - DROPOFF_POS).Magnitude
                        if distToDrop > 4.0 then
                            hum:MoveTo(DROPOFF_POS)
                        else
                            hum:MoveTo(root.Position)
                            if (currentTime - lastInteractTime) >= randomDelay then
                                lastInteractTime = currentTime
                                task.wait(math.random(10, 20) / 100)
                                safePrompt()
                                task.wait(0.5)
                            end
                        end
                    else
                        local distToPick = (root.Position - PICKUP_POS).Magnitude
                        if distToPick > 4.0 then
                            hum:MoveTo(PICKUP_POS)
                        else
                            hum:MoveTo(root.Position)
                            if (currentTime - lastInteractTime) >= randomDelay then
                                lastInteractTime = currentTime
                                task.wait(math.random(10, 20) / 100)
                                safePrompt()
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.2)
    end
end)
