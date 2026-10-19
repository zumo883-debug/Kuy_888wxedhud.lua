-- =================================================================
-- WXED HUD - Red Knife Duel (Full Details & Fixed Head Expander)
-- =================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- โหลด Fluent UI Library และ Addons แบบครบถ้วน
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not success or not Fluent then
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("SendNotification", {
        Title = "WXED HUD Error",
        Text = "ไม่สามารถโหลด Fluent UI ได้!",
        Duration = 5
    })
    return
end

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- สถานะการทำงานของฟังก์ชันต่างๆ
local currentSize = 5.0
local isHeadActive = false
local isEspActive = true
local isNpcEspActive = true
local normalFarmActive = false
local boxFarmActive = false
local rapidFireActive = false
local fastReloadActive = false

-- พิกัดจุดฟาร์มกล่อง / ส่งของ
local PICKUP_POS = Vector3.new(-294.2, 25.0, 36.6)
local WAYPOINT_POS = Vector3.new(-237.8, 25.0, 188.7)
local DROPOFF_POS = Vector3.new(456.1, 25.8, 176.4)

local lastInteractTime = 0
local blacklistedPrompts = {}

-- ระบบกันหลุด Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end)

-- สร้างหน้าต่างเมนูหลัก
local Window = Fluent:CreateWindow({
    Title = "💜 WXED HUD | ดวลมีดแดง",
    SubTitle = "by WXED",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- ปุ่มลอยวงกลมเปิด/ปิดเมนูบนมือถือ (ใส่โลโก้ WXED HUD)
local MobileGui = Instance.new("ScreenGui", PlayerGui)
MobileGui.Name = "WxedMobileToggle"
MobileGui.ResetOnSpawn = false

local ToggleBtn = Instance.new("ImageButton", MobileGui)
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 65)
ToggleBtn.Image = "rbxassetid://100536037895293"
ToggleBtn.Draggable = true

local BtnCorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(1, 0)

local BtnStroke = Instance.new("UIStroke", ToggleBtn)
BtnStroke.Color = Color3.fromRGB(215, 65, 255)
BtnStroke.Thickness = 2

ToggleBtn.MouseButton1Click:Connect(function()
    pcall(function()
        Window:Minimize()
    end)
end)

-- สร้างแท็บเมนูแยกบรรทัดชัดเจน
local FarmTab = Window:AddTab({ Title = "🌾 ฟาร์ม", Icon = "package" })
local CombatTab = Window:AddTab({ Title = "⚔️ ต่อสู้/ESP", Icon = "sword" })
local SettingsTab = Window:AddTab({ Title = "⚙️ ตั้งค่า", Icon = "settings" })

local Options = Fluent.Options

-- =================================================================
-- TAB 1: ระบบฟาร์ม & ร้านค้า
-- =================================================================

FarmTab:AddParagraph({
    Title = "🌾 ระบบฟาร์ม & ร้านค้า",
    Content = "ฟาร์มกล่องอัจฉริยะ & วาร์ป NPC ขายปืน"
})

local NormalToggle = FarmTab:AddToggle("NormalFarmToggle", {
    Title = "📦 ฟาร์มปกติ (กดอัตโนมัติรอบตัว)",
    Default = false
})

NormalToggle:OnChanged(function()
    normalFarmActive = NormalToggle.Value
    if normalFarmActive then
        boxFarmActive = false
        if Options.BoxFarmToggle then Options.BoxFarmToggle:SetValue(false) end
    end
end)

local BoxToggle = FarmTab:AddToggle("BoxFarmToggle", {
    Title = "📦 ฟาร์มกล่องอัจฉริยะ (หยิบ ➔ อ้อม ➔ ส่ง)",
    Default = false
})

BoxToggle:OnChanged(function()
    boxFarmActive = BoxToggle.Value
    if boxFarmActive then
        normalFarmActive = false
        if Options.NormalFarmToggle then Options.NormalFarmToggle:SetValue(false) end
    end
end)

FarmTab:AddButton({
    Title = "🔫 วาร์ปไปหา NPC ขายปืน",
    Callback = function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= char then
                    local name = string.lower(obj.Name)
                    if name:find("gun") or name:find("shop") or name:find("dealer") or name:find("npc") then
                        char.HumanoidRootPart.CFrame = obj:GetPivot() + Vector3.new(0, 3, 3)
                        Fluent:Notify({ Title = "สำเร็จ!", Content = "วาร์ปไปหา NPC แล้ว", Duration = 2 })
                        return
                    end
                end
            end
            
            Fluent:Notify({ Title = "แจ้งเตือน", Content = "ไม่พบ NPC ร้านค้าในแมพนี้", Duration = 2 })
        end)
    end
})

-- =================================================================
-- TAB 2: ระบบต่อสู้ & ESP
-- =================================================================

local HeadToggle = CombatTab:AddToggle("HeadToggle", {
    Title = "🎯 ระบบหัวใหญ่ (Head Expander)",
    Default = false
})
HeadToggle:OnChanged(function() isHeadActive = HeadToggle.Value end)

CombatTab:AddInput("HeadInput", {
    Title = "📝 พิมพ์ขนาดหัว (1 - 35)",
    Default = "5.0",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        currentSize = tonumber(val) or 5.0
        Fluent:Notify({ Title = "อัปเดตขนาดหัว", Content = "ตั้งค่าขนาดหัวเป็น: " .. tostring(currentSize), Duration = 1.5 })
    end
})

CombatTab:AddButton({
    Title = "➕ เพิ่มขนาดหัว (+2.5)",
    Callback = function()
        currentSize = math.min(currentSize + 2.5, 35)
        Fluent:Notify({ Title = "อัปเดตขนาดหัว", Content = "ขนาดหัวปัจจุบัน: " .. tostring(currentSize), Duration = 1.5 })
    end
})

CombatTab:AddButton({
    Title = "➖ ลดขนาดหัว (-2.5)",
    Callback = function()
        currentSize = math.max(currentSize - 2.5, 1)
        Fluent:Notify({ Title = "อัปเดตขนาดหัว", Content = "ขนาดหัวปัจจุบัน: " .. tostring(currentSize), Duration = 1.5 })
    end
})

local RapidToggle = CombatTab:AddToggle("RapidFireToggle", {
    Title = "🔥 ยิงรัวกระสุน (ซุปเปอร์เร่งความเร็ว)",
    Default = false
})
RapidToggle:OnChanged(function() rapidFireActive = RapidToggle.Value end)

local ReloadToggle = CombatTab:AddToggle("FastReloadToggle", {
    Title = "⚡ รีโหลดไว",
    Default = false
})
ReloadToggle:OnChanged(function() fastReloadActive = ReloadToggle.Value end)

local EspToggle = CombatTab:AddToggle("EspToggle", {
    Title = "👁️ มองทะลุผู้เล่น (Player ESP)",
    Default = true
})
EspToggle:OnChanged(function() isEspActive = EspToggle.Value end)

local NpcEspToggle = CombatTab:AddToggle("NpcEspToggle", {
    Title = "📍 มองทะลุ NPC / ร้านค้า (NPC ESP)",
    Default = true
})
NpcEspToggle:OnChanged(function()
    isNpcEspActive = NpcEspToggle.Value
    if not isNpcEspActive then
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    local hl = obj:FindFirstChild("WxNpcHl")
                    if hl then hl:Destroy() end
                end
            end
        end)
    end
end)

-- =================================================================
-- TAB 3: ตั้งค่าความลื่น & FPS
-- =================================================================

SettingsTab:AddParagraph({
    Title = "⚙️ ตั้งค่าความลื่น & UI",
    Content = "แสดงค่า FPS/Ping สวยๆ บนหน้าจอ และโหมดภาพดินน้ำมัน"
})

-- สร้าง UI แสดง FPS & Ping สุดสวย
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

local LabelCorner = Instance.new("UICorner", FpsLabel)
LabelCorner.CornerRadius = UDim.new(0, 6)

local LabelStroke = Instance.new("UIStroke", FpsLabel)
LabelStroke.Color = Color3.fromRGB(215, 65, 255)
LabelStroke.Thickness = 1

local ShowFpsToggle = SettingsTab:AddToggle("ShowFpsToggle", {
    Title = "📊 แสดง FPS & Ping บนหน้าจอ",
    Default = true
})
ShowFpsToggle:OnChanged(function()
    FpsGui.Enabled = ShowFpsToggle.Value
end)

SettingsTab:AddButton({
    Title = "🎨 โหมดภาพดินน้ำมัน (ลดอาการแลค)",
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
        Fluent:Notify({ Title = "สำเร็จ!", Content = "เปิดโหมดภาพดินน้ำมันเรียบร้อยแล้ว", Duration = 2 })
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
-- CORE LOOPS (ระบบการทำงานหลักหลังบ้าน)
-- =================================================================

-- 1. ลูปจัดการ FPS, ESP ผู้เล่น และระบบหัวใหญ่ (ปรับปรุงใหม่บังคับขยายหัวทุกโครงสร้าง)
RunService.RenderStepped:Connect(function()
    pcall(function()
        local currentFps = math.floor(1 / task.wait())
        local ping = 0
        pcall(function()
            ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        end)
        FpsLabel.Text = string.format(" FPS: %d | Ping: %dms", (currentFps > 0 and currentFps or 60), ping)

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local head = char:FindFirstChild("Head")
                
                if isHeadActive and head then
                    pcall(function()
                        -- บังคับเปลี่ยนขนาดและปิดการชนเพื่อให้หัวใหญ่ทำงานได้ผล 100%
                        head.Size = Vector3.new(currentSize, currentSize, currentSize)
                        head.Transparency = 0.4
                        head.CanCollide = false
                        -- ป้องกันสคริปต์เกมรีเซ็ต Mesh ขนาดหัว
                        for _, desc in pairs(head:GetDescendants()) do
                            if desc:IsA("SpecialMesh") or desc:IsA("BlockMesh") then
                                desc.Scale = Vector3.new(1, 1, 1)
                            end
                        end
                    end)
                end
                
                local highlight = char:FindFirstChild("WxHl")
                if not highlight then
                    highlight = Instance.new("Highlight", char)
                    highlight.Name = "WxHl"
                    highlight.Adornee = char
                    highlight.FillColor = Color3.fromRGB(200, 60, 255)
                end
                highlight.Enabled = isEspActive
            end
        end
    end)
end)

-- 2. ลูปจัดการ ESP NPC ร้านค้า
task.spawn(function()
    while true do
        pcall(function()
            if isNpcEspActive then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
                        local name = string.lower(obj.Name)
                        if name:find("gun") or name:find("shop") or name:find("dealer") or name:find("npc") then
                            local npcHl = obj:FindFirstChild("WxNpcHl")
                            if not npcHl then
                                npcHl = Instance.new("Highlight", obj)
                                npcHl.Name = "WxNpcHl"
                                npcHl.Adornee = obj
                                npcHl.FillColor = Color3.fromRGB(255, 165, 0)
                            end
                            npcHl.Enabled = true
                        end
                    end
                end
            end
        end)
        task.wait(2)
    end
end)

-- 3. ลูปยิงรัว & รีโหลดไว (เจาะลึกทุกค่าโมดูลปืน)
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local items = {}
        for _, v in pairs(char:GetChildren()) do if v:IsA("Tool") then table.insert(items, v) end end
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") then table.insert(items, v) end end
        end

        for _, tool in pairs(items) do
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local name = string.lower(v.Name)
                    if rapidFireActive then
                        if name:find("cooldown") or name:find("firerate") or name:find("delay") or name:find("fire") or name:find("speed") or name:find("rate") then
                            if v.Value > 0.001 then v.Value = 0.001 end
                        end
                    end
                    if fastReloadActive and name:find("reload") then
                        if v.Value > 0.05 then v.Value = 0.05 end
                    end
                end
            end
        end
    end)
end)

-- 4. ฟังก์ชันช่วยเหลือสำหรับระบบฟาร์ม
local function safePrompt()
    pcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Enabled and not blacklistedPrompts[v] then
                local p = v.Parent
                local pos = p:IsA("BasePart") and p.Position or (p:IsA("Model") and p:GetPivot().Position or nil)
                if pos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude <= (v.MaxActivationDistance or 12) then
                        local h = v.HoldDuration or 0
                        if v.InputHoldBegin then v:InputHoldBegin() end
                        task.wait(h + 0.15)
                        if v.InputHoldEnd then v:InputHoldEnd() end
                        if fireproximityprompt and h == 0 then fireproximityprompt(v) end
                        blacklistedPrompts[v] = tick() + 5
                        break
                    end
                end
            end
        end
    end)
end

local function hasBox()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and (string.find(string.lower(v.Name), "box") or string.find(string.lower(v.Name), "crate") or string.find(string.lower(v.Name), "ปูน")) then
            return true
        end
    end
    return false
end

local function smartMoveTo(targetPos)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoid, rootPart = char.Humanoid, char.HumanoidRootPart

    local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
    if pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end) and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not boxFarmActive and not normalFarmActive then break end
            humanoid:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            local reached, conn = false, nil
            conn = humanoid.MoveToFinished:Connect(function() reached = true conn:Disconnect() end)
            local timeout = tick() + 1.5
            while not reached and tick() < timeout do task.wait(0.1) end
            if conn then conn:Disconnect() end
        end
    else
        humanoid:MoveTo(targetPos)
    end
end

-- 5. ลูปคำสั่งเดินฟาร์ม
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
                
                if normalFarmActive then
                    local closestPrompt, closestDist, targetPos = nil, math.huge, nil
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled and not blacklistedPrompts[obj] then
                            local p = obj.Parent
                            local pos = p:IsA("BasePart") and p.Position or (p:IsA("Model") and p:GetPivot().Position or nil)
                            if pos then
                                local dist = (root.Position - pos).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestPrompt = obj
                                    targetPos = pos
                                end
                            end
                        end
                    end
                    if closestPrompt and targetPos then
                        if closestDist > 5.5 then
                            smartMoveTo(targetPos)
                        else
                            hum:MoveTo(root.Position)
                            if (currentTime - lastInteractTime) >= 1.3 then
                                lastInteractTime = currentTime
                                safePrompt()
                            end
                        end
                    end

                elseif boxFarmActive then
                    if hasBox() then
                        if (root.Position - DROPOFF_POS).Magnitude > 3.5 then
                            smartMoveTo(DROPOFF_POS)
                        else
                            hum:MoveTo(root.Position)
                            if (currentTime - lastInteractTime) >= 1.3 then
                                lastInteractTime = currentTime
                                safePrompt()
                            end
                        end
                    else
                        if (root.Position - PICKUP_POS).Magnitude > 4.0 then
                            smartMoveTo(PICKUP_POS)
                        elseif (root.Position - WAYPOINT_POS).Magnitude > 8.0 and root.Position.Z < (WAYPOINT_POS.Z - 20) then
                                    smartMoveTo(WAYPOINT_POS)
                        else
                            hum:MoveTo(root.Position)
                            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                            if bp then
                                for _, t in pairs(bp:GetChildren()) do
                                    if t:IsA("Tool") and (string.find(string.lower(t.Name), "box") or string.find(string.lower(t.Name), "crate") or string.find(string.lower(t.Name), "ปูน")) then
                                        t.Parent = char
                                        break
                                    end
                                end
                            end
                            if (currentTime - lastInteractTime) >= 1.3 then
                                lastInteractTime = currentTime
                                safePrompt()
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.25)
    end
end)

Fluent:Notify({ Title = "WXED HUD", Content = "อัปเดตระบบหัวใหญ่และฟังก์ชันครบถ้วนสำเร็จแล้วครับพี่ชาย!", Duration = 5 })
