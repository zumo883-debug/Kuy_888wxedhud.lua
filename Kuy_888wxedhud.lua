-- =================================================================
-- WXED HUD - Red Knife Duel (Ultimate Full Package)
-- =================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- สถานะการทำงานของฟังก์ชันต่างๆ
local currentSize = 5.0
local isHeadActive = true
local isEspActive = true
local isNpcEspActive = true
local normalFarmActive = false
local boxFarmActive = false
local rapidFireActive = false
local fastReloadActive = false
local isMinimized = false

-- พิกัดจุดฟาร์มกล่อง / ส่งของ
local PICKUP_POS = Vector3.new(-294.2, 25.0, 36.6)
local WAYPOINT_POS = Vector3.new(-237.8, 25.0, 188.7)
local DROPOFF_POS = Vector3.new(456.1, 25.8, 176.4)

local lastInteractTime = 0
local blacklistedPrompts = {}

-- ทำความสะอาด UI เก่าก่อนสร้างใหม่
if CoreGui:FindFirstChild("WxedUltimateHub") then CoreGui.WxedUltimateHub:Destroy() end
if CoreGui:FindFirstChild("WxedFpsDisplay") then CoreGui.WxedFpsDisplay:Destroy() end
if PlayerGui:FindFirstChild("WxedMobileToggle") then PlayerGui.WxedMobileToggle:Destroy() end

-- =================================================================
-- ปุ่มลอยวงกลมเปิด/ปิดเมนูบนมือถือ (โลโก้ WXED HUD)
-- =================================================================
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

-- =================================================================
-- ระบบแสดง FPS & Ping บนจอแบบนิ่งๆ สมูทๆ
-- =================================================================
local FpsGui = Instance.new("ScreenGui")
FpsGui.Name = "WxedFpsDisplay"
FpsGui.Parent = CoreGui
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

-- =================================================================
-- หน้าต่างเมนูหลัก (Main Frame)
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WxedUltimateHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 420)
MainFrame.Position = UDim2.new(0.5, -170, 0.3, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(130, 80, 255)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- หัวข้อเมนู
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "💜 WXED HUD | ดวลมีดแดง (ตัวเต็ม)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- ปุ่มพับหน้าต่าง (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 5)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = MainFrame

-- กดปุ่มลอยวงกลมเพื่อเปิด/ปิดเมนูหลัก
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Container ใส่ปุ่มฟังก์ชันต่างๆ
local ScrollingContainer = Instance.new("ScrollingFrame")
ScrollingContainer.Name = "ScrollingContainer"
ScrollingContainer.Size = UDim2.new(1, 0, 1, -45)
ScrollingContainer.Position = UDim2.new(0, 0, 0, 45)
ScrollingContainer.BackgroundTransparency = 1
ScrollingContainer.CanvasSize = UDim2.new(0, 0, 0, 580)
ScrollingContainer.ScrollBarThickness = 4
ScrollingContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ScrollingContainer

-- ฟังก์ชันสร้างปุ่มเปิด/ปิด (Toggle Button)
local function CreateToggleButton(name, defaultText, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(130, 80, 255) or Color3.fromRGB(50, 50, 60)
    btn.Text = defaultText .. (defaultState and ": เปิด" or ": ปิด")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ScrollingContainer
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    
    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(130, 80, 255) or Color3.fromRGB(50, 50, 60)
        btn.Text = defaultText .. (state and ": เปิด" or ": ปิด")
        callback(state)
    end)
    return btn
end

-- =================================================================
-- สร้างปุ่มฟังก์ชันต่างๆ ในเมนู
-- =================================================================

CreateToggleButton("NormalFarm", "🌾 ออโต้ฟาร์มทั่วไป", false, function(v)
    normalFarmActive = v
    if v then boxFarmActive = false end
end)

CreateToggleButton("BoxFarm", "📦 ฟาร์มกล่องอัจฉริยะ (หยิบ➔ส่ง)", false, function(v)
    boxFarmActive = v
    if v then normalFarmActive = false end
end)

CreateToggleButton("HeadToggle", "🎯 ระบบหัวใหญ่ (Head Expander)", true, function(v)
    isHeadActive = v
end)

CreateToggleButton("RapidFire", "🔥 ยิงรัวกระสุน", false, function(v)
    rapidFireActive = v
end)

CreateToggleButton("FastReload", "⚡ รีโหลดไว", false, function(v)
    fastReloadActive = v
end)

CreateToggleButton("EspToggle", "👁️ มองทะลุผู้เล่น (สีม่วง)", true, function(v)
    isEspActive = v
end)

CreateToggleButton("NpcEspToggle", "📍 มองทะลุ NPC ที่กดตอบโต้ได้", true, function(v)
    isNpcEspActive = v
    if not v then
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Highlight") and obj.Name == "NpcInteractiveHighlight" then
                    obj:Destroy()
                end
            end
        end)
    end
end)

CreateToggleButton("FpsToggle", "📊 แสดง FPS & Ping บนจอ", true, function(v)
    FpsGui.Enabled = v
end)

-- Minimize Logic (ปุ่มพับจอ)
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        ScrollingContainer.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 340, 0, 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
        MinimizeBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 340, 0, 420), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true, function()
            ScrollingContainer.Visible = true
        end)
        MinimizeBtn.Text = "—"
    end
end)

-- =================================================================
-- Anti-AFK (กันหลุด)
-- =================================================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end)

-- =================================================================
-- CORE LOOPS (ระบบทำงานหลังบ้านทั้งหมด)
-- =================================================================

local lastUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    -- อัปเดต FPS & Ping แบบนิ่งๆ สมูทๆ
    if tick() - lastUpdate >= 0.5 then
        lastUpdate = tick()
        local currentFps = math.clamp(math.floor(1 / dt + 0.5), 1, 300)
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        FpsLabel.Text = string.format(" FPS: %d | Ping: %dms", currentFps, ping)
    end

    -- ระบบหัวใหญ่ & ESP ผู้เล่นสีม่วง
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            
            if isHeadActive and head then
                head.CanCollide = false
                head.Massless = true
                for _, child in pairs(head:GetChildren()) do
                    if child:IsA("SpecialMesh") or child:IsA("CharacterMesh") then child:Destroy() end
                end
                head.Size = Vector3.new(currentSize, currentSize, currentSize)
            end
            
            local highlight = char:FindFirstChild("ESPHighlight")
            if not highlight then
                highlight = Instance.new("Highlight", char)
                highlight.Name = "ESPHighlight"
                highlight.Adornee = char
                highlight.FillColor = Color3.fromRGB(180, 60, 255) -- สีม่วงเท่ๆ
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0
            end
            highlight.Enabled = isEspActive
        end
    end

    -- ระบบมองทะลุเฉพาะ NPC ที่มี ProximityPrompt (กดตอบโต้ได้) เท่านั้น
    if isNpcEspActive then
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local targetModel = obj.Parent
                    while targetModel and not targetModel:IsA("Model") and targetModel ~= Workspace do
                        targetModel = targetModel.Parent
                    end
                    
                    if targetModel and targetModel:IsA("Model") and targetModel ~= LocalPlayer.Character then
                        local npcHi = targetModel:FindFirstChild("NpcInteractiveHighlight")
                        if not npcHi then
                            npcHi = Instance.new("Highlight", targetModel)
                            npcHi.Name = "NpcInteractiveHighlight"
                            npcHi.Adornee = targetModel
                            npcHi.FillColor = Color3.fromRGB(0, 255, 200) -- สีฟ้าอมเขียวแยกจากผู้เล่น
                            npcHi.FillTransparency = 0.4
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

-- ระบบยิงรัว & รีโหลดไว
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local items = {}
        for _, v in pairs(char:GetChildren()) do if v:IsA("Tool") then table.insert(items, v) end end
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") then table.insert(items, v) end end end

        for _, tool in pairs(items) do
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local name = string.lower(v.Name)
                    if rapidFireActive and (name:find("cooldown") or name:find("firerate") or name:find("delay") or name:find("fire") or name:find("speed")) then
                        if v.Value > 0.001 then v.Value = 0.001 end
                    end
                    if fastReloadActive and name:find("reload") then
                        if v.Value > 0.05 then v.Value = 0.05 end
                    end
                end
            end
        end
    end)
end)

-- ฟังก์ชันฟาร์มกล่อง & ฟาร์มทั่วไป
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

-- ลูปเดินฟาร์มหลัก
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
                        if closestDist > 5.5 then smartMoveTo(targetPos)
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
                        if (root.Position - DROPOFF_POS).Magnitude > 3.5 then smartMoveTo(DROPOFF_POS)
                        else
                            hum:MoveTo(root.Position)
                            if (currentTime - lastInteractTime) >= 1.3 then
                                lastInteractTime = currentTime
                                safePrompt()
                            end
                        end
                    else
                        if (root.Position - PICKUP_POS).Magnitude > 4.0 then smartMoveTo(PICKUP_POS)
                        elseif (root.Position - WAYPOINT_POS).Magnitude > 8.0 and root.Position.Z < (WAYPOINT_POS.Z - 20) then smartMoveTo(WAYPOINT_POS)
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
