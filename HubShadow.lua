-- Delay auto-execution so the game can finish loading.
task.wait(8)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ========================================================
-- 1. CONFIG SYSTEM & ANTI-DC RESET
-- ========================================================
local ConfigFolderName = "ShadowHub_Configs"
local ConfigFileName = ConfigFolderName .. "/ShadowHub_Config.json"
local UI_Updaters = {}

local DefaultConfig = {
    AutoTP = false,
    AutoArcadia = false, 
    AutoPellet = false,
    AutoLifeMachine = false,
    LifeMachineCooldownUntil = 0,
    LifeMachineLastTimerText = "",
    AutoFishingToggle = false,
    SelectedFarmingMode = "Map 1 (Throne Room)",
    AutoRotate = false,
    AutoMap2 = false,
    AutoDualMap = false,
    AutoTripleMap = false,
    FPSBooster = false,
    ClayPotato = false,
    Disable3D = false,
    ClearWater = false,
    Limit30FPS = false,
    AutoRAM = false,
    AntiAFK = true,
    WebhookURL = "",
    WebhookPlayer = false,
    WebhookJoinLeave = false,
    UISizeX = 520,
    UISizeY = 320,
    AutoTeleportSpawn = false,
    
    FarmMapCurrent = "Canyon",
    DualMapTimer = 0,
    DualMapSubTimer = 0,
    DualMapPoolIndex = 1,
    
    StaffDetector = false,
    AutoReconnect = false,
    Freecam = false,
    UnlimitedZoom = true,
    
    SprintToggle = false,
    SprintSpeed = 16,
    FlyMode = false,
    FlySpeed = 50,
    InfiniteJump = false,
    NoClip = false,
    Invisible = false,
    LavaImmunity = false,
    
    HideStats = false,
    CustomName = "HiddenShadow",
    CustomLevel = "999",
    RobloxPlusBadge = false,
    
    SelectedTheme = "Default"
}

if makefolder and not isfolder(ConfigFolderName) then
    makefolder(ConfigFolderName)
end

local ConfigData = {}
for k, v in pairs(DefaultConfig) do ConfigData[k] = v end

local function SaveConfig()
    if writefile then
        pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(ConfigData)) end)
    end
end

local function LoadConfig()
    if isfile and isfile(ConfigFileName) and readfile then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            for k, v in pairs(decoded) do ConfigData[k] = v end
            
            if ConfigData.SelectedFarmingMode == "Map 1 (Rotate)" then
                ConfigData.SelectedFarmingMode = "Map 1 (Throne Room)"
            elseif ConfigData.SelectedFarmingMode == "Dual Map (Switch)" then
                ConfigData.SelectedFarmingMode = "Dual Map (Canyon, Throne)"
            end
        end)
    end
end

-- ========================================================
-- PERSISTENT CUSTOM SAVED LOCATION
-- ========================================================
local function SerializeCFrame(cf)
    if not cf then return nil end
    local components = {cf:GetComponents()}
    return components
end

local function DeserializeCFrame(data)
    if type(data) ~= "table" or #data ~= 12 then return nil end
    local ok, result = pcall(function()
        return CFrame.new(table.unpack(data))
    end)
    return ok and result or nil
end

local forceFarmTP = false

local function ResetConfig()
    for k, v in pairs(DefaultConfig) do 
        ConfigData[k] = v 
        if UI_Updaters[k] then UI_Updaters[k](v) end
    end
    ConfigData.DualMapTimer = 0
    ConfigData.DualMapSubTimer = 0
    ConfigData.DualMapPoolIndex = 1
    ConfigData.FarmMapCurrent = "Canyon"
    ConfigData.SavedCustomLocation = nil
    forceFarmTP = true
    SaveConfig()
end

LoadConfig()

ConfigData.AutoRotate = false
ConfigData.AutoMap2 = false
ConfigData.AutoDualMap = false
ConfigData.AutoTripleMap = false

-- ========================================================
-- THEME MANAGER SYSTEM
-- ========================================================
local Themes = {
    ["Default"] = {
        bg = Color3.fromRGB(15, 15, 18), sidebar = Color3.fromRGB(20, 20, 24), content = Color3.fromRGB(25, 25, 30),
        accent = Color3.fromRGB(140, 60, 255), text = Color3.fromRGB(240, 240, 240), subtext = Color3.fromRGB(170, 170, 170), stroke = Color3.fromRGB(40, 40, 50)
    },
    ["Elegant Gold"] = {
        bg = Color3.fromRGB(20, 18, 15), sidebar = Color3.fromRGB(26, 23, 20), content = Color3.fromRGB(36, 30, 25),
        accent = Color3.fromRGB(212, 175, 55), text = Color3.fromRGB(250, 245, 235), subtext = Color3.fromRGB(180, 170, 150), stroke = Color3.fromRGB(50, 45, 30)
    },
    ["Crimson Blood"] = {
        bg = Color3.fromRGB(18, 10, 10), sidebar = Color3.fromRGB(24, 15, 15), content = Color3.fromRGB(30, 20, 20),
        accent = Color3.fromRGB(220, 20, 60), text = Color3.fromRGB(240, 230, 230), subtext = Color3.fromRGB(170, 150, 150), stroke = Color3.fromRGB(50, 30, 30)
    },
    ["Ocean Blue"] = {
        bg = Color3.fromRGB(10, 15, 20), sidebar = Color3.fromRGB(15, 22, 30), content = Color3.fromRGB(20, 30, 40),
        accent = Color3.fromRGB(0, 150, 255), text = Color3.fromRGB(230, 240, 250), subtext = Color3.fromRGB(150, 170, 190), stroke = Color3.fromRGB(30, 40, 50)
    },
    ["Neon Cyber"] = {
        bg = Color3.fromRGB(10, 10, 15), sidebar = Color3.fromRGB(15, 15, 25), content = Color3.fromRGB(20, 20, 35),
        accent = Color3.fromRGB(0, 255, 255), text = Color3.fromRGB(240, 255, 255), subtext = Color3.fromRGB(150, 180, 200), stroke = Color3.fromRGB(30, 30, 50)
    }
}

local currentTheme = Themes[ConfigData.SelectedTheme] or Themes["Default"]
local c_bg, c_sidebar, c_content, c_accent, c_text, c_subtext = currentTheme.bg, currentTheme.sidebar, currentTheme.content, currentTheme.accent, currentTheme.text, currentTheme.subtext
local RefreshAllToastThemes

local function ApplyTheme()
    local t = Themes[ConfigData.SelectedTheme] or Themes["Default"]
    c_bg, c_sidebar, c_content, c_accent, c_text, c_subtext = t.bg, t.sidebar, t.content, t.accent, t.text, t.subtext
    
    local gui = CoreGui:FindFirstChild("Shadow_Panel_V8")
    if not gui then return end
    
    for _, obj in ipairs(gui:GetDescendants()) do
        local role = obj:GetAttribute("ThemeRole")
        if not role then continue end
        
        if role == "bg" then pcall(function() obj.BackgroundColor3 = c_bg end)
        elseif role == "sidebar" then pcall(function() obj.BackgroundColor3 = c_sidebar end)
        elseif role == "content" then pcall(function() obj.BackgroundColor3 = c_content end)
        elseif role == "accent_bg" then pcall(function() obj.BackgroundColor3 = c_accent end)
        elseif role == "text" then 
            pcall(function() 
                obj.TextColor3 = c_text 
                if obj:IsA("TextButton") then obj.BackgroundColor3 = c_content end
            end)
        elseif role == "subtext" then pcall(function() obj.TextColor3 = c_subtext end)
        elseif role == "accent_text" then pcall(function() obj.TextColor3 = c_accent end)
        elseif role == "stroke" then pcall(function() obj.Color = t.stroke end)
        elseif role == "scroll" then pcall(function() obj.ScrollBarImageColor3 = c_accent end)
        elseif role == "none" then pcall(function() obj.BackgroundColor3 = Color3.fromRGB(60, 60, 70) end)
        end
    end
end

-- ========================================================
-- 2. DATA KOORDINAT, DETEKSI MAP & HELPERS
-- ========================================================
local spotKordinat = {
    Board = CFrame.lookAt(Vector3.new(-855.63, 44.43, 5187.01), Vector3.new(-855.63, 44.43, 5187.01) + Vector3.new(0, 0, 1)),
    Volcano = CFrame.lookAt(Vector3.new(-813.46, 59.37, 5271.69), Vector3.new(-813.46, 59.37, 5271.69) + Vector3.new(1, 0, 1)),
    Storm = CFrame.lookAt(Vector3.new(-864.27, 56.06, 5309.37), Vector3.new(-864.27, 56.06, 5309.37) + Vector3.new(-1, 0, 1)),
    Blizzard = CFrame.lookAt(Vector3.new(-968.19, 45.83, 5345.58), Vector3.new(-968.19, 45.83, 5345.58) + Vector3.new(-1, 0, -1)),
    Arcadia = CFrame.new(Vector3.new(1338.43, 14.29, 3004.07)) * CFrame.Angles(0, math.rad(-0), 75),
    PelletMachine = CFrame.new(1323.34, 13.34, 2968.82)
}
local DatabaseIconCuaca = {["118379404229807"] = "Blizzard", ["105076841543450"] = "Storm", ["76632496002371"] = "Volcano"}
local posisiSimpanan = nil
local posisiSimpananArcadia = nil

local isWeatherTPBusy = false
local isArcadiaTPBusy = false
local isPelletExecuting = false
local isLifeMachineExecuting = false
-- Teleport priority lock: Pellet owns teleport control during its 4-cycle batch.
local teleportLockOwner = nil
local ExecutePelletCycle -- forward declaration for the manual trigger
local pelletAutoInsideInvader = false
local pelletAutoStartAt = 0
-- Shared priority flag: dideklarasikan sebelum semua thread agar weather/farm/machine
-- dapat menghormati event Kraken sebagai prioritas tertinggi.
local arcadiaEventActive = false
local lifeExtraLifeUIArmed = true

-- Farming Maps Position
local standPositionRot = Vector3.new(-1290.24, -855.68, 5596.16)
local poolAngles = {-103.43, 135.57, 15.08}
local currentPoolIndex = 1

local map2Pos = Vector3.new(-4014.58, -543.00, 564.95)
local map2Degree = 46.85
local map2CFrame = CFrame.new(map2Pos) * CFrame.Angles(0, math.rad(map2Degree), 0)

-- UPDATE KOORDINAT INVADER TERBARU
local invaderPos = Vector3.new(1360.69, -960.90, 2977.51)
local invaderDegree = 158.26
local invaderCFrame = CFrame.new(invaderPos) * CFrame.Angles(0, math.rad(invaderDegree), 0)

-- LIFE MACHINE TRIGGER V5: EXACT COORDINATE + CAMERA-INDEPENDENT PROMPT
local lifeMachineCFrame = CFrame.new(1266.16, -963.12, 3009.05) * CFrame.Angles(0, math.rad(-32.5), 0)

local rotateInterval = 1160
local dualMapInterval = 3480

-- ====== FUNGSI KHUSUS LIFE MACHINE ======
-- Sumber status cooldown HANYA boleh berasal dari UI/GUI yang menempel
-- pada objek di sekitar koordinat Life Machine. Timer dari UI lain di map
-- tidak boleh ikut terbaca.
local function ParseLifeMachineTimer(text)
    if type(text) ~= "string" then return nil end

    -- Mendukung HH:MM:SS maupun MM:SS.
    local h, m, sec = text:match("(%d+):(%d%d):(%d%d)")
    if h and m and sec then
        return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(sec)
    end

    m, sec = text:match("(%d+):(%d%d)")
    if m and sec then
        return (tonumber(m) * 60) + tonumber(sec)
    end

    return nil
end

local function GetLifeMachineWorldStatus()
    -- Scan hanya di sekitar titik interaksi Life Machine. Timer diprioritaskan
    -- daripada teks READY agar label READY dari GUI lain tidak menimpa timer.
    local radius = 12
    local parts = workspace:GetPartBoundsInRadius(lifeMachineCFrame.Position, radius)
    local nearestTimerDistance = math.huge
    local nearestTimerText, nearestTimerSeconds = nil, nil
    local nearestReadyDistance = math.huge
    local foundReady = false
    local seenGui = {}

    local function resolveGuiPart(gui, fallbackPart)
        local adornee = gui.Adornee
        if adornee and adornee:IsA("BasePart") then return adornee end
        local parent = gui.Parent
        while parent and parent ~= workspace do
            if parent:IsA("BasePart") then return parent end
            parent = parent.Parent
        end
        if fallbackPart and fallbackPart:IsA("BasePart") then return fallbackPart end
        return nil
    end

    local function inspectGui(gui, fallbackPart)
        if seenGui[gui] then return end
        seenGui[gui] = true
        local guiPart = resolveGuiPart(gui, fallbackPart)
        if not guiPart then return end
        local distance = (guiPart.Position - lifeMachineCFrame.Position).Magnitude
        if distance > radius then return end

        for _, label in ipairs(gui:GetDescendants()) do
            if (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) and label.Visible then
                local value = tostring(label.Text or "")
                local seconds = ParseLifeMachineTimer(value)
                if seconds ~= nil and distance < nearestTimerDistance then
                    nearestTimerDistance = distance
                    nearestTimerText = value
                    nearestTimerSeconds = seconds
                elseif string.find(string.lower(value), "ready", 1, true) and distance < nearestReadyDistance then
                    nearestReadyDistance = distance
                    foundReady = true
                end
            end
        end
    end

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            for _, obj in ipairs(part:GetChildren()) do
                if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                    inspectGui(obj, part)
                end
            end
            for _, obj in ipairs(part:GetDescendants()) do
                if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                    inspectGui(obj, part)
                end
            end
        end
    end

    -- Fallback untuk GUI yang parent/Adornee-nya berada dalam model mesin.
    -- Hanya model dari part terdekat ke koordinat Life Machine yang diperiksa.
    local nearestPart, nearestPartDistance = nil, math.huge
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local d = (part.Position - lifeMachineCFrame.Position).Magnitude
            if d < nearestPartDistance then
                nearestPart, nearestPartDistance = part, d
            end
        end
    end
    local machineModel = nearestPart and nearestPart:FindFirstAncestorOfClass("Model")
    if machineModel then
        for _, obj in ipairs(machineModel:GetDescendants()) do
            if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                inspectGui(obj, nearestPart)
            end
        end
    end

    -- Cari GUI mesin berdasarkan judul "8-Bit Boost". GUI bisa berupa
    -- BillboardGui/SurfaceGui di Workspace atau ScreenGui di PlayerGui;
    -- jangan batasi pencarian pada jarak karakter dari mesin.
    local guiRoots = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") or obj:IsA("ScreenGui") then
            table.insert(guiRoots, obj)
        end
    end
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if obj:IsA("ScreenGui") or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                table.insert(guiRoots, obj)
            end
        end
    end

    local bestMachineTimer, bestMachineSeconds = nil, nil
    for _, guiRoot in ipairs(guiRoots) do
        local labels = {}
        local hasBoostTitle = false
        for _, label in ipairs(guiRoot:GetDescendants()) do
            if label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox") then
                table.insert(labels, label)
                local titleText = string.lower(tostring(label.Text or "")):gsub("%s+", " ")
                if string.find(titleText, "8-bit boost", 1, true)
                    or string.find(titleText, "8 bit boost", 1, true) then
                    hasBoostTitle = true
                end
            end
        end

        if hasBoostTitle then
            -- Timer harus berada dalam GUI yang sama dengan judul 8-Bit Boost.
            -- Abaikan angka waktu nol/teks lain yang bukan countdown aktif.
            for _, label in ipairs(labels) do
                local value = tostring(label.Text or "")
                local seconds = ParseLifeMachineTimer(value)
                if seconds ~= nil and seconds > 0 then
                    bestMachineTimer = value
                    bestMachineSeconds = seconds
                    break
                end
            end
        end
        if bestMachineSeconds ~= nil then break end
    end

    if bestMachineSeconds ~= nil then
        return "COOLDOWN", bestMachineTimer, bestMachineSeconds
    end

    -- Timer menang atas label READY; READY hanya dikembalikan bila tidak ada timer.
    if nearestTimerSeconds ~= nil then
        return "COOLDOWN", nearestTimerText, nearestTimerSeconds
    elseif foundReady then
        return "READY", "READY", 0
    end
    return nil, nil, nil
end

local lifeMachineLastPersistedUntil = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
local lifeMachineLastPersistedState = (lifeMachineLastPersistedUntil > os.time()) and "COOLDOWN" or "READY"
local lifeMachineLastSaveClock = 0

local function PersistLifeMachineCooldown(untilTime, timerText, state)
    local oldUntil = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
    local oldText = tostring(ConfigData.LifeMachineLastTimerText or "")
    ConfigData.LifeMachineCooldownUntil = tonumber(untilTime) or 0
    ConfigData.LifeMachineLastTimerText = tostring(timerText or "")

    -- Simpan saat transisi, perubahan deadline bermakna, atau maksimal tiap 5 detik.
    -- Deadline = waktu sekarang + sisa timer mesin; tidak mengandalkan teks lama.
    local nowClock = os.clock()
    local shouldSave = (state ~= lifeMachineLastPersistedState)
        or (math.abs((tonumber(untilTime) or 0) - oldUntil) >= 2)
        or (state == "COOLDOWN" and nowClock - lifeMachineLastSaveClock >= 5)
        or (state == "READY" and oldText ~= "")

    if shouldSave then
        lifeMachineLastPersistedUntil = ConfigData.LifeMachineCooldownUntil
        lifeMachineLastPersistedState = state or "READY"
        lifeMachineLastSaveClock = nowClock
        SaveConfig()
    end
end

local function GetLifeMachineCooldownRemaining()
    local now = os.time()
    local state, machineText, machineSeconds = GetLifeMachineWorldStatus()

    -- Pembacaan timer GUI Life Machine selalu menang bila tersedia.
    if state == "COOLDOWN" and machineSeconds ~= nil then
        local deadline = now + math.max(0, math.floor(machineSeconds))
        PersistLifeMachineCooldown(deadline, machineText or "", "COOLDOWN")
        return math.max(0, math.floor(machineSeconds)), machineText, "MACHINE"
    end

    -- READY hanya diterima dari label READY yang benar-benar terdeteksi dekat mesin.
    if state == "READY" then
        PersistLifeMachineCooldown(0, "", "READY")
        return 0, "READY", "MACHINE"
    end

    -- Saat GUI belum termuat / pemain jauh / baru rejoin, gunakan deadline
    -- persisten. Jangan menghapus deadline hanya karena scanner belum menemukan GUI.
    local deadline = tonumber(ConfigData.LifeMachineCooldownUntil) or 0
    local remaining = math.max(0, deadline - now)
    if remaining > 0 then
        return remaining, ConfigData.LifeMachineLastTimerText, "SAVED"
    end

    -- Jika belum pernah mendapat pembacaan valid dari mesin dan belum ada
    -- deadline tersimpan, jangan mengarang status READY. Tunggu sinkronisasi UI.
    if deadline > 0 then
        return 0, "READY", "SAVED"
    end
    return 0, "SYNCING", "UNKNOWN"
end

local function GetMachineTimerText()
    local remaining, text = GetLifeMachineCooldownRemaining()

    if remaining > 0 then
        return text or formatSecondsToText(remaining), remaining
    end

    return "READY", 0
end

local NotifyToast

local function ExecuteLifeMachine(UIStatus_LifeMachine, isManual)
    if isLifeMachineExecuting then return false end
    -- Pellet has priority while a cycle/batch is actively controlling teleport.
    if teleportLockOwner == "PELLET" then return false end
    local acquiredLifeTeleportLock = false

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not hrp then return false end

    -- Auto mode tetap khusus Invader's Reach.
    if not isManual then
        local distToInvaderMap = (hrp.Position - invaderPos).Magnitude
        if distToInvaderMap > 350 then
            return false
        end
    end

    if not teleportLockOwner then
        teleportLockOwner = "LIFE"
        acquiredLifeTeleportLock = true
    end
    isLifeMachineExecuting = true

    if UIStatus_LifeMachine then
        UIStatus_LifeMachine.Text = "⚡ MENUJU LIFE MACHINE..."
        UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(100, 255, 255)
    end

    -- Simpan posisi idle sebelum berangkat.
    local originalCFrame = hrp.CFrame
    local originalVelocity = hrp.AssemblyLinearVelocity

    -- ====================================================
    -- EXACT TARGET: posisi + heading dari Pencatat Koordinat.
    -- Tidak menghitung FrontDistance lagi.
    -- Tidak ada teleport kedua.
    -- ====================================================
    hrp.CFrame = lifeMachineCFrame
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    NotifyToast("Life Machine", "berhasil TP ke Life Machine", "success")

    -- Pendek saja: beri client/game waktu memperbarui posisi setelah TP.
    task.wait(0.25)

    -- LOCK hanya selama proses trigger.
    local oldAnchored = hrp.Anchored
    local oldAutoRotate = humanoid and humanoid.AutoRotate
    hrp.Anchored = true
    if humanoid then
        humanoid.AutoRotate = false
    end

    local firedMachine = false
    local machinePrompt = nil

    local function getPromptPart(prompt)
        local parent = prompt and prompt.Parent
        if not parent then return nil end

        if parent:IsA("BasePart") then
            return parent
        elseif parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
            return parent.Parent
        end

        return nil
    end

    -- HANYA mencari prompt di sekitar koordinat Life Machine.
    -- Tidak scan seluruh Workspace untuk menghindari salah target.
    local function findLifeMachinePrompt()
        local parts = workspace:GetPartBoundsInRadius(
            lifeMachineCFrame.Position,
            18,
            nil
        )

        local checkedModels = {}
        local fallbackPrompt = nil
        local nearestDistance = math.huge

        for _, part in ipairs(parts) do
            local model = part:FindFirstAncestorOfClass("Model")

            local function inspectContainer(container)
                if not container then return end

                for _, obj in ipairs(container:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local promptPart = getPromptPart(obj)
                        if promptPart then
                            local d = (promptPart.Position - lifeMachineCFrame.Position).Magnitude
                            if d <= 18 and d < nearestDistance then
                                nearestDistance = d
                                fallbackPrompt = obj
                            end
                        end
                    end
                end
            end

            if model and not checkedModels[model] then
                checkedModels[model] = true
                inspectContainer(model)
            end

            inspectContainer(part)
        end

        return fallbackPrompt
    end

    -- Setelah TP, tunggu prompt muncul/ter-update.
    -- TIDAK melakukan TP ulang selama menunggu.
    local promptDeadline = os.clock() + 1.20
    while os.clock() < promptDeadline and not machinePrompt do
        machinePrompt = findLifeMachinePrompt()
        if not machinePrompt then
            task.wait(0.06)
        end
    end

    if machinePrompt then
        NotifyToast("Life Machine", "Prompt berhasil ditemukan", "success")
        -- Hilangkan ketergantungan terhadap arah kamera/line-of-sight
        -- bila property ini tersedia di client.
        local oldLOS = machinePrompt.RequiresLineOfSight
        pcall(function()
            machinePrompt.RequiresLineOfSight = false
        end)

        -- Metode utama: fireproximityprompt bila executor menyediakan.
        -- Ini tidak bergantung pada kamera atau tulisan prompt sedang terlihat.
        if typeof(fireproximityprompt) == "function" then
            local ok = pcall(function()
                fireproximityprompt(machinePrompt)
            end)
            firedMachine = ok
        else
            -- Fallback Roblox input path.
            local ok = pcall(function()
                machinePrompt:InputHoldBegin()
                if machinePrompt.HoldDuration > 0 then
                    task.wait(machinePrompt.HoldDuration + 0.05)
                else
                    task.wait(0.08)
                end
                machinePrompt:InputHoldEnd()
            end)
            firedMachine = ok
        end

        pcall(function()
            machinePrompt.RequiresLineOfSight = oldLOS
        end)
    end

    -- Lepaskan lock setelah SATU percobaan aktivasi.
    if humanoid then
        humanoid.AutoRotate = oldAutoRotate == nil and true or oldAutoRotate
    end
    hrp.Anchored = oldAnchored

    -- Beri server sedikit waktu memproses trigger sebelum pulang.
    task.wait(0.20)

    -- SELALU pulang sekali ke posisi idle.
    local returnRoot = character and character:FindFirstChild("HumanoidRootPart")
    if returnRoot then
        returnRoot.CFrame = originalCFrame
        returnRoot.AssemblyLinearVelocity = originalVelocity
        NotifyToast("Life Machine", "berhasil kembali ke posisi awal", "success")
    end

    if UIStatus_LifeMachine then
        if firedMachine then
            NotifyToast("Life Machine", "sukses • mesin berhasil dipicu", "success")
            UIStatus_LifeMachine.Text = "✅ SUCCESS! SIKLUS SELESAI"
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(50, 255, 100)
        else
            NotifyToast("Life Machine", "gagal • prompt mesin tidak terpicu", "error")
            UIStatus_LifeMachine.Text = "⚠️ PROMPT MESIN TIDAK TERPICU"
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(255, 180, 50)
        end
    end

    task.wait(1.0)
    isLifeMachineExecuting = false
    if acquiredLifeTeleportLock and teleportLockOwner == "LIFE" then
        teleportLockOwner = nil
    end

    return firedMachine
end

local function GetEventScheduleWIB()
    local utc_time = os.time()
    local wib_time = utc_time + (7 * 3600)
    local date = os.date("!*t", wib_time)
    local h = date.hour; local m = date.min; local s = date.sec
    
    if h % 3 == 1 then
        local sisaDetik = 3600 - ((m * 60) + s)
        return { state = "ACTIVE", timeLeft = sisaDetik }
    else
        local nextHour = h + 1
        while nextHour % 3 ~= 1 do nextHour = nextHour + 1 end
        local jamSisa = nextHour - h - 1; local menitSisa = 59 - m; local detikSisa = 60 - s
        return { state = "COOLDOWN", timeLeft = (jamSisa * 3600) + (menitSisa * 60) + detikSisa }
    end
end

local function GetArcadiaScheduleWIB()
    local utc_time = os.time()
    local wib_time = utc_time + (7 * 3600)
    local date = os.date("!*t", wib_time)
    local h = date.hour; local m = date.min; local s = date.sec

    -- Jadwal global Arcadia mengikuti jam event yang sama seperti Auto TP Cuaca:
    -- event dimulai setiap jam ketika h % 3 == 1.
    -- Timer ini TIDAK pernah menjadi trigger teleport. Ia hanya menentukan
    -- kapan scanner UI Kraken dibuka (20 menit sebelum event).
    local eventHour = h
    if h % 3 ~= 1 or (h % 3 == 1 and m >= 5) then
        eventHour = h
        while eventHour % 3 ~= 1 do eventHour = eventHour + 1 end
        if eventHour == h and m >= 5 then eventHour = eventHour + 3 end
    end

    local secondsNow = (h * 3600) + (m * 60) + s
    local eventSeconds = (eventHour * 3600)
    local untilEvent = eventSeconds - secondsNow

    -- Event berikutnya sudah masuk window 20 menit:
    -- aktifkan scanner, tetapi tetap menunggu UI Battle asli.
    if untilEvent > 0 and untilEvent <= (20 * 60) then
        return { state = "SCAN", timeLeft = untilEvent }
    end

    -- Lima menit setelah jam mulai: beri scanner sedikit grace period bila
    -- UI Battle terlambat muncul. Ini tetap BUKAN trigger TP.
    if untilEvent <= 0 and untilEvent >= -(5 * 60) then
        return { state = "SCAN", timeLeft = 0 }
    end

    -- Di luar window scanner, tunggu event global berikutnya.
    if untilEvent <= 0 then
        eventHour = eventHour + 3
        eventSeconds = eventHour * 3600
        untilEvent = eventSeconds - secondsNow
    end

    return { state = "COOLDOWN", timeLeft = untilEvent }
end

local function formatSecondsToText(seconds)
    local h = math.floor(seconds / 3600); local m = math.floor((seconds % 3600) / 60); local s = seconds % 60
    if h > 0 then return string.format("%02dh %02dm %02ds", h, m, s) else return string.format("%02dm %02ds", m, s) end
end

local function GetWeatherIconOnly()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local boardPos = spotKordinat.Board.Position
    
    for _, gui in ipairs(workspace:GetDescendants()) do
        if gui:IsA("SurfaceGui") then
            local part = gui.Parent
            if gui.Adornee then part = gui.Adornee end
            if part and part:IsA("BasePart") then
                if (part.Position - boardPos).Magnitude <= 10 then
                    for _, obj in ipairs(gui:GetDescendants()) do
                        if (obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("Decal") or obj:IsA("Texture")) then
                            local img = (obj:IsA("Decal") or obj:IsA("Texture")) and tostring(obj.Texture) or tostring(obj.Image)
                            local pureId = string.match(img, "%d+")
                            local imgLower = string.lower(img)
                            local isVisible = (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and (obj.Visible and obj.ImageTransparency < 0.9) or (obj.Transparency < 0.9)

                            if isVisible and pureId and img ~= "" and not string.find(imgLower, "shadow") then
                                if DatabaseIconCuaca[pureId] then return DatabaseIconCuaca[pureId] end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function PulangKeSetPos()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and posisiSimpanan then
        hrp.CFrame = posisiSimpanan
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

local function PulangKeSetPosArcadia()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and posisiSimpananArcadia then
        hrp.CFrame = posisiSimpananArcadia
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

-- ========================================================
-- 3. ENGINE WEBHOOK & PLAYER TRACKER
-- ========================================================
local MapDictionary = {
    ["Crystalline Passage"] = "Ancient Ruin (Runtuhan Kuno)",
    ["Underwater City"] = "Underwater City (Kota Atlantis)",
    ["Desolate Deep"] = "Desolate Deep (Palung Terdalam)",
    ["Roslit Bay"] = "Roslit Bay (Teluk Roslit)",
    ["Mushgrove Swamp"] = "Mushgrove Swamp (Rawa Jamur)",
    ["Terrapin Island"] = "Terrapin Island (Pulau Kura-kura)",
    ["Sunstone Island"] = "Sunstone Island (Pulau Matahari)",
    ["Statue of Sovereignty"] = "Statue of Sovereignty (Patung Raja)",
    ["Keepers Altar"] = "Keepers Altar (Altar Penjaga)",
    ["Snowcap Island"] = "Snowcap Island (Pulau Salju)",
    ["Forsaken Shores"] = "Forsaken Shores (Pantai Terabaikan)"
}

local BlacklistKeywords = {
    "crate", "teleport", "stand", "board", "shop", "vendor", "seller", 
    "buy", "leaderboard", "npc", "rod", "throne"
}

local function IsBlacklistedLocation(name)
    local lowerName = string.lower(name)
    for _, kw in ipairs(BlacklistKeywords) do
        if string.find(lowerName, kw) then return true end
    end
    return false
end

local trackedPlayers = {}
local UIStatus_PlayerMon
local trackerUIPaused = false
local isTrackerActive = ConfigData.WebhookPlayer or false

local function GetPlayerLocation(targetPlayer)
    local char = targetPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Loading/Mati" end

    local closestName = nil; local minDist = math.huge
    local mapFolders = {"Zones", "Islands", "Map", "World", "Locations"}
    
    for _, folderName in ipairs(mapFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if not IsBlacklistedLocation(child.Name) then
                    local pos = child:IsA("Model") and child:GetPivot().Position or (child:IsA("BasePart") and child.Position or nil)
                    if pos then
                        local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
                        if dist < minDist then minDist = dist; closestName = child.Name end
                    end
                end
            end
        end
    end

    if closestName and minDist <= 3500 then 
        return MapDictionary[closestName] or closestName 
    end
    return "Lautan Luas (Ocean)"
end

local function SendPlayerList(isManual)
    local url = ConfigData.WebhookURL
    if not url or url == "" or not string.find(url, "discord") then
        if UIStatus_PlayerMon then
            task.spawn(function()
                trackerUIPaused = true
                UIStatus_PlayerMon.Text = "Status: Link Webhook Kosong!"
                UIStatus_PlayerMon.TextColor3 = Color3.fromRGB(255, 100, 100)
                task.wait(3); trackerUIPaused = false
            end)
        end return
    end
    url = url:match("^%s*(.-)%s*$")

    if isManual and UIStatus_PlayerMon then 
        UIStatus_PlayerMon.Text = "Menyiapkan Data..."
        UIStatus_PlayerMon.TextColor3 = Color3.fromRGB(255, 200, 50) 
    end

    local currentOnlineMap = {}
    for _, p in ipairs(Players:GetPlayers()) do
        currentOnlineMap[p.UserId] = true
        local loc = GetPlayerLocation(p)
        if trackedPlayers[p.UserId] then 
            trackedPlayers[p.UserId].IsOnline = true; trackedPlayers[p.UserId].Location = loc
        else 
            trackedPlayers[p.UserId] = {Name = p.Name, DisplayName = p.DisplayName, IsOnline = true, Location = loc} 
        end
    end
    for userId, data in pairs(trackedPlayers) do 
        if not currentOnlineMap[userId] then data.IsOnline = false end 
    end

    local onlineCount = 0; local totalTracked = 0; local sortedList = {}
    for _, data in pairs(trackedPlayers) do table.insert(sortedList, data) end
    table.sort(sortedList, function(a, b) 
        if a.IsOnline ~= b.IsOnline then return a.IsOnline end; 
        return a.DisplayName:lower() < b.DisplayName:lower() 
    end)

    local playerLines = {}
    for i, data in ipairs(sortedList) do
        totalTracked = totalTracked + 1; if data.IsOnline then onlineCount = onlineCount + 1 end
        local icon = data.IsOnline and "🟢" or "🔴"
        local locInfo = data.IsOnline and ("📍 " .. data.Location) or ("👻 Last Loc: " .. data.Location)
        table.insert(playerLines, string.format("%s %d. %s (@%s) | %s", icon, i, data.DisplayName, data.Name, locInfo))
    end

    local embedChunks = {}; local currentChunk = ""
    for _, line in ipairs(playerLines) do
        if #currentChunk + #line > 900 then
            table.insert(embedChunks, currentChunk); currentChunk = line .. "\n"
        else
            currentChunk = currentChunk .. line .. "\n"
        end
    end
    if currentChunk ~= "" then table.insert(embedChunks, currentChunk) end

    local maxPlayer = Players.MaxPlayers; local disconnectedCount = totalTracked - onlineCount
    local wibTime = os.time() + (7 * 3600); local tglWIB = os.date("!%d/%m/%y", wibTime); local jamWIB = os.date("!%H:%M:%S", wibTime)     

    local embedFields = {
        {["name"] = "🕒 Waktu Laporan (WIB)", ["value"] = string.format("📅 **Tanggal:** %s\n⏰ **Jam:** %s", tglWIB, jamWIB), ["inline"] = false},
        {["name"] = "📊 Ringkasan Server", ["value"] = string.format("🟢 **Online:** %d / %d\n🔴 **Disconnected:** %d", onlineCount, maxPlayer, disconnectedCount), ["inline"] = false}
    }

    if #embedChunks == 0 then
        table.insert(embedFields, {["name"] = "👤 Player Database", ["value"] = "```\n[ Data Kosong ]\n```", ["inline"] = false})
    else
        for idx, chunkText in ipairs(embedChunks) do
            local headerName = (idx == 1) and "👤 Player Database & Location Map" or ("👤 Player Database (Bagian " .. idx .. ")")
            table.insert(embedFields, {["name"] = headerName, ["value"] = "```\n" .. chunkText .. "```", ["inline"] = false})
        end
    end

    local payload = {
        ["username"] = "Shadow Tracker Premium",
        ["embeds"] = {{
            ["title"] = isManual and "🛠️ [TEST] SHADOW WEBHOOK TRACKER" or "🕸️ SHADOW WEBHOOK TRACKER",
            ["color"] = 9371895,
            ["fields"] = embedFields,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") 
        }}
    }

    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if requestFunc then
        task.spawn(function()
            local success, response = pcall(function()
                return requestFunc({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
            end)
            if success and response and (response.StatusCode == 200 or response.StatusCode == 204) then
                if UIStatus_PlayerMon then
                    trackerUIPaused = true
                    UIStatus_PlayerMon.Text = "Status: TEMBUS (Sukses Kirim)!"
                    UIStatus_PlayerMon.TextColor3 = Color3.fromRGB(100, 255, 100)
                    task.wait(3); trackerUIPaused = false
                end
            end
        end)
    end
end

local function SendJoinLeaveNotification(targetPlayer, isJoin)
    local url = ConfigData.WebhookURL
    if not url or url == "" or not string.find(url, "discord") then return end
    if not ConfigData.WebhookJoinLeave then return end

    url = url:match("^%s*(.-)%s*$")
    local statusText = isJoin and "🟢 JOINED THE SERVER" or "🔴 LEFT THE SERVER"
    local colorCode = isJoin and 3066993 or 15158332
    
    local function FireWebhook(locationText)
        local payload = {
            ["username"] = "Shadow Tracker Alerts",
            ["embeds"] = {{
                ["title"] = "🔔 PLAYER ACTIVITY ALERT",
                ["color"] = colorCode,
                ["fields"] = {
                    {["name"] = "👤 Player", ["value"] = string.format("**%s**\n(@%s)", targetPlayer.DisplayName, targetPlayer.Name), ["inline"] = true},
                    {["name"] = "📊 Action", ["value"] = statusText, ["inline"] = true},
                    {["name"] = "📍 Location", ["value"] = locationText, ["inline"] = false}
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if requestFunc then
            task.spawn(function() pcall(function() requestFunc({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end) end)
        end
    end

    if isJoin then
        task.delay(4, function()
            local loc = GetPlayerLocation(targetPlayer)
            FireWebhook(loc)
        end)
    else
        local loc = "Lautan Luas (Ocean)"
        if trackedPlayers[targetPlayer.UserId] then loc = "Last Loc: " .. trackedPlayers[targetPlayer.UserId].Location end
        FireWebhook(loc)
    end
end

Players.PlayerAdded:Connect(function(p) SendJoinLeaveNotification(p, true) end)
Players.PlayerRemoving:Connect(function(p) SendJoinLeaveNotification(p, false) end)

-- ========================================================
-- 4. ENGINE CLAY POTATO MODE + ALWAYS DAYLIGHT
-- ========================================================
local clayPotatoActive = false
local clayLightingConn = nil
local clayDescendantConn = nil
local clayDaylightThread = nil

local function DisableClayPotato()
    clayPotatoActive = false
    if clayLightingConn then pcall(function() clayLightingConn:Disconnect() end); clayLightingConn = nil end
    if clayDescendantConn then pcall(function() clayDescendantConn:Disconnect() end); clayDescendantConn = nil end
    -- Do not try to restore game graphics here: Clay Potato only changes client-side
    -- visual properties and the game may legitimately update them while it is active.
end

local function EnableClayPotato()
    if clayPotatoActive then return end
    clayPotatoActive = true
    local GRAY_COLOR = Color3.fromRGB(140, 140, 140)

    local function forceDaylight()
        if not ConfigData.ClayPotato or not clayPotatoActive then return end
        pcall(function()
            Lighting.TimeOfDay = "12:00:00"
            Lighting.GlobalShadows = false
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 9e9
        end)
    end

    forceDaylight()

    -- Lightweight periodic enforcement instead of Lighting.Changed firing on every
    -- lighting property change. This avoids a noisy event connection while keeping
    -- the visual mode persistent.
    clayDaylightThread = task.spawn(function()
        while clayPotatoActive and ConfigData.ClayPotato do
            forceDaylight()
            task.wait(5)
        end
    end)

    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0.8
        end
    end)

    local function isMyPlayerStuff(obj)
        if player.Character and (obj == player.Character or obj:IsDescendantOf(player.Character)) then return true end
        local backpack = player:FindFirstChild("Backpack")
        if backpack and (obj == backpack or obj:IsDescendantOf(backpack)) then return true end
        return false
    end

    local function isVisualObject(obj)
        return obj:IsA("BasePart") or obj:IsA("SpecialMesh")
            or obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance")
            or obj:IsA("Clothing") or obj:IsA("ShirtGraphic")
            or obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("ParticleEmitter")
            or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Sparkles") or obj:IsA("Fire")
            or obj:IsA("Smoke") or obj:IsA("Highlight") or obj:IsA("Light")
    end

    local function superNuke(obj)
        if not obj or not ConfigData.ClayPotato or not clayPotatoActive then return end
        if isMyPlayerStuff(obj) or not isVisualObject(obj) then return end

        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
                obj.Color = GRAY_COLOR
                if obj:IsA("MeshPart") then obj.TextureID = "" end
            elseif obj:IsA("SpecialMesh") then
                obj.TextureId = ""
            elseif obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("Clothing") or obj:IsA("ShirtGraphic") then
                obj:Destroy()
            elseif obj:IsA("PostEffect") or obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                or obj:IsA("Beam") or obj:IsA("Sparkles") or obj:IsA("Fire")
                or obj:IsA("Smoke") or obj:IsA("Highlight") then
                obj.Enabled = false
            elseif obj:IsA("Light") then
                obj.Enabled = false
            end
        end)
    end

    -- Process the existing world in small batches so enabling the mode does not
    -- monopolize a frame on large maps.
    task.spawn(function()
        local allObjects = workspace:GetDescendants()
        for i = 1, #allObjects do
            if not ConfigData.ClayPotato or not clayPotatoActive then break end
            superNuke(allObjects[i])
            if i % 150 == 0 then task.wait() end
        end
    end)

    clayDescendantConn = workspace.DescendantAdded:Connect(function(obj)
        if ConfigData.ClayPotato and clayPotatoActive and isVisualObject(obj) then
            task.defer(superNuke, obj)
        end
    end)
end

-- ========================================================
-- 5. UI SYSTEM (SHADOW PANEL V8)
-- ========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Shadow_Panel_V8"
ScreenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui

-- ========================================================
-- COMPACT TOAST NOTIFICATION SYSTEM
-- Safe/global notification layer: max 4 visible, FIFO queue, never drops.
-- ========================================================
local ToastHolder = Instance.new("Frame")
ToastHolder.Name = "ToastHolder"
ToastHolder.Size = UDim2.new(0, 250, 0, 185)
ToastHolder.Position = UDim2.new(1, -10, 1, -10)
ToastHolder.AnchorPoint = Vector2.new(1, 1)
ToastHolder.BackgroundTransparency = 1
ToastHolder.BorderSizePixel = 0
ToastHolder.ZIndex = 1000
ToastHolder.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.FillDirection = Enum.FillDirection.Vertical
ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.Padding = UDim.new(0, 5)
ToastLayout.Parent = ToastHolder

local toastSerial = 0
local activeToasts = {}
local queuedToasts = {}
local toastBurstUntil = 0

local function SafeToastTween(instance, info, props)
    pcall(function()
        TweenService:Create(instance, info, props):Play()
    end)
end

local function BuildToast(title, message, kind)
    toastSerial = toastSerial + 1

    local toast = Instance.new("Frame")
    toast.Name = "Toast_" .. tostring(toastSerial)
    toast.Size = UDim2.new(0, 250, 0, 40)
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.LayoutOrder = toastSerial
    toast.ZIndex = 1000
    toast.Parent = ToastHolder

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.Position = UDim2.new(0, 22, 0, 0)
    card.BackgroundColor3 = c_content
    card.BackgroundTransparency = 0.12
    card.BorderSizePixel = 0
    card.ZIndex = 1001
    card.Parent = toast
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke")
    stroke.Color = c_accent
    stroke.Transparency = 0.35
    stroke.Thickness = 1
    stroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -12)
    accent.Position = UDim2.new(0, 5, 0, 6)
    accent.BackgroundColor3 = c_accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 1002
    accent.Parent = card
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 22, 1, 0)
    icon.Position = UDim2.new(0, 13, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = (kind == "error" and "!") or (kind == "info" and "i") or "✓"
    icon.TextColor3 = c_accent
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 14
    icon.ZIndex = 1002
    icon.Parent = card

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -48, 1, -6)
    label.Position = UDim2.new(0, 38, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = tostring(title) .. "  •  " .. tostring(message)
    label.TextColor3 = c_text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.ZIndex = 1002
    label.Parent = card

    return toast
end

local function RemoveToast(toast)
    for i = #activeToasts, 1, -1 do
        if activeToasts[i] == toast then
            table.remove(activeToasts, i)
            break
        end
    end

    if toast and toast.Parent then
        local card = toast:FindFirstChild("Card")
        if card then
            SafeToastTween(card, TweenInfo.new(0.12), {
                Position = UDim2.new(0, 24, 0, 0),
                BackgroundTransparency = 1
            })
        end
        task.delay(0.14, function()
            pcall(function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end)
    end
end

local function ShowToast(data)
    if #activeToasts >= 4 then return false end

    local toast = BuildToast(data.title, data.message, data.kind)
    table.insert(activeToasts, toast)

    local card = toast:FindFirstChild("Card")
    if card then
        SafeToastTween(card, TweenInfo.new(0.12), {
            Position = UDim2.new(0, 0, 0, 0)
        })
    end

    -- Normal = 2s. During a burst/queue = 1.15s, while queued items remain.
    local fast = (#activeToasts >= 4) or (#queuedToasts > 0) or (os.clock() < toastBurstUntil)
    local lifetime = fast and 1.15 or 2.0

    task.delay(lifetime, function()
        RemoveToast(toast)
        if #queuedToasts > 0 then
            local nextData = table.remove(queuedToasts, 1)
            task.defer(function()
                ShowToast(nextData)
            end)
        end
    end)

    return true
end

NotifyToast = function(title, message, kind)
    -- Notifications must never be able to break the main script.
    pcall(function()
        title = tostring(title or "Shadow Hub")
        message = tostring(message or "")
        kind = kind or "success"

        if #activeToasts >= 3 then
            toastBurstUntil = os.clock() + 0.8
        end

        local data = {title = title, message = message, kind = kind}
        if #activeToasts < 4 then
            ShowToast(data)
        else
            table.insert(queuedToasts, data)
        end
    end)
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, ConfigData.UISizeX or 520, 0, ConfigData.UISizeY or 320)
MainFrame.Position = UDim2.new(0.5, -(ConfigData.UISizeX or 520)/2, 0.5, -(ConfigData.UISizeY or 320)/2)
MainFrame.BackgroundColor3 = c_bg; MainFrame.Active = true; MainFrame.Draggable = true
MainFrame:SetAttribute("ThemeRole", "bg")
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MS = Instance.new("UIStroke", MainFrame); MS.Color = Color3.fromRGB(40, 40, 50); MS.Thickness = 1
MS:SetAttribute("ThemeRole", "stroke")

local LogoBtn = Instance.new("TextButton", ScreenGui)
LogoBtn.Size = UDim2.new(0, 45, 0, 45); LogoBtn.Position = UDim2.new(0, 15, 0.45, 0)
LogoBtn.BackgroundColor3 = c_sidebar; LogoBtn.Text = "SHDW\n🚀"; LogoBtn.TextColor3 = c_accent
LogoBtn:SetAttribute("ThemeRole", "sidebar")
LogoBtn.Font = Enum.Font.GothamBlack; LogoBtn.TextSize = 11; LogoBtn.Active = true; LogoBtn.Draggable = true; LogoBtn.Visible = false
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundTransparency = 1

local TitleLabel = Instance.new("TextLabel", Header)
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0); TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "⚜️ SHADOW HUB 🚀"; TitleLabel.TextColor3 = c_accent
TitleLabel:SetAttribute("ThemeRole", "accent_text")
TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 13; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 40, 0, 40); CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "—"; CloseBtn.TextColor3 = c_accent
CloseBtn:SetAttribute("ThemeRole", "accent_text")
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 16

LogoBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true; LogoBtn.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; LogoBtn.Visible = true end)

local ResizeHandle = Instance.new("TextButton", MainFrame)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20); ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1; ResizeHandle.Text = "◢"; ResizeHandle.TextColor3 = c_subtext
ResizeHandle:SetAttribute("ThemeRole", "subtext")
ResizeHandle.TextSize = 14; ResizeHandle.Font = Enum.Font.GothamBold

local isDraggingResize = false; local dragStartPos, startSize
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingResize = true; dragStartPos = input.Position; startSize = MainFrame.Size
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingResize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        MainFrame.Size = UDim2.new(0, math.clamp(startSize.X.Offset + delta.X, 400, 900), 0, math.clamp(startSize.Y.Offset + delta.Y, 250, 600))
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if isDraggingResize and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDraggingResize = false; ConfigData.UISizeX = MainFrame.Size.X.Offset; ConfigData.UISizeY = MainFrame.Size.Y.Offset; SaveConfig()
    end
end)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, -40); Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = c_sidebar; Sidebar.BorderSizePixel = 0
Sidebar:SetAttribute("ThemeRole", "sidebar")
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.Padding = UDim.new(0, 4); SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Pages = {}
local function CreateTab(name, active)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(0.92, 0, 0, 34); btn.BackgroundColor3 = active and Color3.fromRGB(35, 35, 45) or c_sidebar
    btn.Text = "  " .. name; btn.TextColor3 = active and c_text or c_subtext
    btn:SetAttribute("ThemeRole", active and "content" or "sidebar")
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 10; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 3, 0.6, 0); indicator.Position = UDim2.new(0, 2, 0.2, 0)
    indicator.BackgroundColor3 = c_accent; indicator.BorderSizePixel = 0; indicator.Visible = active
    indicator:SetAttribute("ThemeRole", "accent_bg")
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local PageScroll = Instance.new("ScrollingFrame", MainFrame)
    PageScroll.Size = UDim2.new(1, -170, 1, -50); PageScroll.Position = UDim2.new(0, 170, 0, 40)
    PageScroll.BackgroundTransparency = 1; PageScroll.BorderSizePixel = 0
    PageScroll.ScrollBarThickness = 3; PageScroll.ScrollBarImageColor3 = c_accent; PageScroll.Visible = active
    PageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    PageScroll:SetAttribute("ThemeRole", "scroll")
    local Layout = Instance.new("UIListLayout", PageScroll)
    Layout.Padding = UDim.new(0, 8); Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", PageScroll).PaddingBottom = UDim.new(0, 25)

    Pages[name] = {Button = btn, Indicator = indicator, Frame = PageScroll}
    btn.MouseButton1Click:Connect(function()
        for pName, pData in pairs(Pages) do
            local isTarget = (pName == name)
            pData.Frame.Visible = isTarget; pData.Indicator.Visible = isTarget
            pData.Button:SetAttribute("ThemeRole", isTarget and "content" or "sidebar")
        end
        ApplyTheme()
    end)
    return PageScroll
end

local TabAutomation   = CreateTab("⚡ Automation", true)
local TabArcadiaEvent = CreateTab("🎪 EVENT ARCADIA", false)
local TabBooster      = CreateTab("🚀 Booster & RAM", false)
local TabWebhooks     = CreateTab("📡 Discord Webhooks", false)
local TabTeleport     = CreateTab("🌍 Teleport Island", false)
local TabPlayerMods   = CreateTab("🛠️ Player & Server", false)
local TabConfig       = CreateTab("⚙️ Config Manager", false)

local function CreateDropdown(parent, titleText)
    local DropdownFrame = Instance.new("Frame", parent)
    DropdownFrame.Size = UDim2.new(1, -10, 0, 38); DropdownFrame.BackgroundColor3 = c_content
    DropdownFrame:SetAttribute("ThemeRole", "content")
    DropdownFrame.ClipsDescendants = true; DropdownFrame.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 8)
    
    local TopBtn = Instance.new("TextButton", DropdownFrame)
    TopBtn.Size = UDim2.new(1, 0, 0, 38); TopBtn.BackgroundTransparency = 1
    TopBtn.Text = "   " .. titleText; TopBtn.TextColor3 = c_text; TopBtn:SetAttribute("ThemeRole", "text")
    TopBtn.Font = Enum.Font.GothamBold; TopBtn.TextSize = 11; TopBtn.TextXAlignment = Enum.TextXAlignment.Left
    
    local ItemsContainer = Instance.new("Frame", DropdownFrame)
    ItemsContainer.Size = UDim2.new(1, 0, 0, 0); ItemsContainer.Position = UDim2.new(0, 0, 0, 38)
    ItemsContainer.BackgroundTransparency = 1; ItemsContainer.AutomaticSize = Enum.AutomaticSize.Y
    local ItemLayout = Instance.new("UIListLayout", ItemsContainer)
    ItemLayout.Padding = UDim.new(0, 6); ItemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", ItemsContainer).PaddingBottom = UDim.new(0, 8)

    -- Default dropdown state: CLOSED
    local isOpen = false
    ItemsContainer.Visible = false
    TopBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        ItemsContainer.Visible = isOpen
    end)
    return ItemsContainer
end

local function CreateToggle(parent, text, configKey, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(0.95, 0, 0, 32); Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.65, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = text; Label.TextColor3 = c_text; Label:SetAttribute("ThemeRole", "text")
    Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 10; Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ToggleBtn = Instance.new("TextButton", Frame)
    ToggleBtn.Size = UDim2.new(0, 36, 0, 18); ToggleBtn.Position = UDim2.new(1, -45, 0.5, -9)
    ToggleBtn.BackgroundColor3 = ConfigData[configKey] and c_accent or Color3.fromRGB(60, 60, 70); ToggleBtn.Text = ""
    ToggleBtn:SetAttribute("ThemeRole", ConfigData[configKey] and "accent_bg" or "none")
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame", ToggleBtn)
    Circle.Size = UDim2.new(0, 14, 0, 14); Circle.Position = ConfigData[configKey] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    local state = ConfigData[configKey] or false

    UI_Updaters[configKey] = function(newState)
        state = newState
        local targetColor = state and c_accent or Color3.fromRGB(60, 60, 70)
        local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        ToggleBtn:SetAttribute("ThemeRole", state and "accent_bg" or "none")
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        if callback then callback(state) end
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ConfigData[configKey] = state
        SaveConfig()
        UI_Updaters[configKey](state)
        local toastTitle = (configKey == "AutoPellet" and "Pellet Machine")
            or (configKey == "AutoFishingToggle" and "Auto Fishing")
            or (configKey == "AutoTP" and "Auto TP Cuaca")
            or (configKey == "AutoArcadia" and "Auto TP Kraken")
            or (configKey == "AutoLifeMachine" and "Life Machine")
            or text
        NotifyToast(toastTitle, state and "berhasil ON" or "berhasil OFF", state and "success" or "info")
    end)
    if state and callback then callback(state) end
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(0.95, 0, 0, 32); Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Btn.Text = text; Btn.TextColor3 = c_text; Btn:SetAttribute("ThemeRole", "text"); Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 10
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", Btn); s.Color = Color3.fromRGB(50, 50, 60); s.Thickness = 1
    Btn.MouseButton1Click:Connect(function()
        local result = callback and callback()
        -- Every button action gets a toast. Callbacks may return a custom
        -- message for a more precise notification (e.g. TP destination).
        if result ~= false then
            local msg = type(result) == "string" and result or "berhasil dijalankan"
            local lowerText = string.lower(text)
            -- Pellet has its own detailed cycle notifications; avoid a duplicate
            -- generic toast for that button.
            if not string.find(lowerText, "pellet machine", 1, true) then
                NotifyToast(text, msg, "success")
            end
        end
    end)
    return Btn
end

local function CreateTextBox(parent, placeholder, configKey, callback)
    local BoxFrame = Instance.new("Frame", parent)
    BoxFrame.Size = UDim2.new(0.95, 0, 0, 32); BoxFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Instance.new("UICorner", BoxFrame).CornerRadius = UDim.new(0, 6)
    
    local Box = Instance.new("TextBox", BoxFrame)
    Box.Size = UDim2.new(1, -20, 1, 0); Box.Position = UDim2.new(0, 10, 0, 0)
    Box.BackgroundTransparency = 1; Box.PlaceholderText = placeholder
    Box.Text = tostring(ConfigData[configKey] or ""); Box.TextColor3 = c_text; Box:SetAttribute("ThemeRole", "text")
    Box.PlaceholderColor3 = c_subtext; Box.Font = Enum.Font.GothamSemibold; Box.TextSize = 10; Box.TextXAlignment = Enum.TextXAlignment.Left; Box.ClearTextOnFocus = false
    
    UI_Updaters[configKey] = function(newState) Box.Text = tostring(newState) end
    Box.FocusLost:Connect(function()
        ConfigData[configKey] = Box.Text
        SaveConfig()
        if callback then callback(Box.Text) end
        NotifyToast(placeholder, "berhasil disimpan", "success")
    end)
end

local function CreateStatusLabel(parent)
    local Label = Instance.new("TextLabel", parent)
    Label.Size = UDim2.new(0.95, 0, 0, 28); Label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Label.Text = "Status: IDLE"; Label.TextColor3 = c_subtext; Label:SetAttribute("ThemeRole", "subtext")
    Label.Font = Enum.Font.GothamBold; Label.TextSize = 10
    Instance.new("UICorner", Label).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", Label); s.Color = c_accent; s.Thickness = 1; s:SetAttribute("ThemeRole", "stroke")
    return Label
end

local function CreateSelector(parent, titleText, items, onSelect)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(0.95, 0, 0, 32); Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.4, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = titleText; Label.TextColor3 = c_text; Label:SetAttribute("ThemeRole", "text")
    Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 10; Label.TextXAlignment = Enum.TextXAlignment.Left

    local SelectBtn = Instance.new("TextButton", Frame)
    SelectBtn.Size = UDim2.new(0.55, -10, 0, 24); SelectBtn.Position = UDim2.new(0.45, 0, 0.5, -12)
    SelectBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); SelectBtn.Text = "Select Option"; SelectBtn.TextColor3 = c_subtext; SelectBtn:SetAttribute("ThemeRole", "subtext")
    SelectBtn.Font = Enum.Font.GothamSemibold; SelectBtn.TextSize = 10
    Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", SelectBtn).Color = Color3.fromRGB(50, 50, 60)

    local ListContainer = Instance.new("Frame", parent)
    ListContainer.Size = UDim2.new(0.95, 0, 0, 100); ListContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ListContainer.Visible = false
    Instance.new("UICorner", ListContainer).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", ListContainer).Color = Color3.fromRGB(50, 50, 60)

    local Scroll = Instance.new("ScrollingFrame", ListContainer)
    Scroll.Size = UDim2.new(1, -4, 1, -4); Scroll.Position = UDim2.new(0, 2, 0, 2)
    Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = c_accent
    Scroll:SetAttribute("ThemeRole", "scroll")
    local ScrollLayout = Instance.new("UIListLayout", Scroll)
    ScrollLayout.Padding = UDim.new(0, 2); ScrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    SelectBtn.MouseButton1Click:Connect(function() ListContainer.Visible = not ListContainer.Visible end)

    local function populate(newItems)
        for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local ySize = 0
        for _, item in ipairs(newItems) do
            local btn = Instance.new("TextButton", Scroll)
            btn.Size = UDim2.new(1, -4, 0, 24); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            btn.Text = " " .. item; btn.TextColor3 = c_text; btn:SetAttribute("ThemeRole", "text")
            btn.Font = Enum.Font.Gotham; btn.TextSize = 10; btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                SelectBtn.Text = item; SelectBtn.TextColor3 = c_text; SelectBtn:SetAttribute("ThemeRole", "text"); ListContainer.Visible = false
                if onSelect then onSelect(item) end
                NotifyToast(titleText, "berhasil pilih: " .. tostring(item), "info")
            end)
            ySize = ySize + 26
        end
        Scroll.CanvasSize = UDim2.new(0, 0, 0, ySize)
        ListContainer.Size = UDim2.new(0.95, 0, 0, math.clamp(ySize + 4, 30, 120))
    end
    populate(items)
    return Frame, populate, SelectBtn
end

local function CreateInfoLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(0.95, 0, 0, 20); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = c_subtext; lbl:SetAttribute("ThemeRole", "subtext")
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 9; lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

-- ========================================================
-- 6. MENU SETUP (AUTOMATION, ARCADIA, BOOSTER, WEBHOOKS, TELEPORT)
-- ========================================================
local DropElemental = CreateDropdown(TabAutomation, "Event Elemental TP")
local UIStatus_Elemental = CreateStatusLabel(DropElemental)
CreateToggle(DropElemental, "Enable Auto TP Cuaca", "AutoTP", function(state)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if state then if hrp and not posisiSimpanan then posisiSimpanan = hrp.CFrame end
    else isWeatherTPBusy = false; UIStatus_Elemental.Text = "SYSTEM PAUSED"; UIStatus_Elemental.TextColor3 = c_subtext end
end)

local elementalMapNames = {"Volcano (Gunung Berapi)", "Blizzard (Es / Ice Storm)", "Storm (Badai)"}
local elementalKeyMap = {["Volcano (Gunung Berapi)"] = "Volcano", ["Blizzard (Es / Ice Storm)"] = "Storm", ["Storm (Badai)"] = "Storm"}
local selectedElementalMapKey = nil
CreateSelector(DropElemental, "Manual Weather TP", elementalMapNames, function(selText) selectedElementalMapKey = elementalKeyMap[selText] end)
local BtnTPElementalManual = CreateButton(DropElemental, "Teleport Manual to Weather Map", function()
    if not selectedElementalMapKey then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and spotKordinat[selectedElementalMapKey] then
        local targetCF = spotKordinat[selectedElementalMapKey]
        hrp.CFrame = CFrame.new(targetCF.Position + Vector3.new(0, 3, 0)) * targetCF.Rotation; hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        return "berhasil TP ke " .. tostring(selectedElementalMapKey)
    end
    return false
end)
BtnTPElementalManual.BackgroundColor3 = c_sidebar; BtnTPElementalManual.TextColor3 = c_accent
BtnTPElementalManual:SetAttribute("ThemeRole", "accent_text"); Instance.new("UIStroke", BtnTPElementalManual).Color = c_accent

local DropArcadia = CreateDropdown(TabAutomation, "Event Arcadia TP")
local UIStatus_Arcadia = CreateStatusLabel(DropArcadia)
CreateToggle(DropArcadia, "Enable Auto TP Arcadia", "AutoArcadia", function(state)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if state then if hrp and not posisiSimpananArcadia then posisiSimpananArcadia = hrp.CFrame end
    else isArcadiaTPBusy = false; UIStatus_Arcadia.Text = "SYSTEM PAUSED"; UIStatus_Arcadia.TextColor3 = c_subtext end
end)
local BtnTPArcadiaManual = CreateButton(DropArcadia, "Teleport Manual to Arcadia", function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and spotKordinat.Arcadia then
        local targetCF = spotKordinat.Arcadia
        hrp.CFrame = CFrame.new(targetCF.Position + Vector3.new(0, 3, 0)) * targetCF.Rotation; hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        return "berhasil TP ke Arcadia"
    end
    return false
end)
BtnTPArcadiaManual.BackgroundColor3 = c_sidebar; BtnTPArcadiaManual.TextColor3 = c_accent
BtnTPArcadiaManual:SetAttribute("ThemeRole", "accent_text"); Instance.new("UIStroke", BtnTPArcadiaManual).Color = c_accent

local DropFishing = CreateDropdown(TabAutomation, "🎣 Auto Fishing Manager")
local fishingModes = {"Map 1 (Throne Room)", "Map 2 (Canyon)", "Dual Map (Canyon, Throne)", "Triple Map (Canyon, Throne, Invader's)"}
local FishingSelectorFrame, FishingPopulate, FishingSelectBtn = CreateSelector(DropFishing, "Farming Mode", fishingModes, function(sel)
    ConfigData.SelectedFarmingMode = sel
    SaveConfig()
    if ConfigData.AutoFishingToggle then forceFarmTP = true end
end)
UI_Updaters["SelectedFarmingMode"] = function(newState) FishingSelectBtn.Text = newState; FishingSelectBtn.TextColor3 = c_text end
if not ConfigData.SelectedFarmingMode then ConfigData.SelectedFarmingMode = "Map 1 (Throne Room)" end
FishingSelectBtn.Text = ConfigData.SelectedFarmingMode; FishingSelectBtn.TextColor3 = c_text

CreateToggle(DropFishing, "Enable Auto Fishing", "AutoFishingToggle", function(state)
    if state then forceFarmTP = true end
end)
local UIStatus_Fishing = CreateStatusLabel(DropFishing)
if not ConfigData.AutoFishingToggle then UIStatus_Fishing.Text = "AUTO FISHING: OFF"; UIStatus_Fishing.TextColor3 = c_subtext end

local BtnManualTPThrone = CreateButton(DropFishing, "📌 Manual TP ke Throne Room", function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(standPositionRot); hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); return "berhasil TP ke Throne Room" end
    return false
end)
local BtnManualTPCanyon = CreateButton(DropFishing, "📌 Manual TP ke Canyon", function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = map2CFrame; hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); return "berhasil TP ke Canyon" end
    return false
end)
local BtnManualTPInvader = CreateButton(DropFishing, "📌 Manual TP ke Invader's", function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = invaderCFrame; hrp.AssemblyLinearVelocity = Vector3.new(0,0,0); return "berhasil TP ke Invader's" end
    return false
end)

local BtnResetDualMap = CreateButton(DropFishing, "🔄 Reset Farm State", function()
    ConfigData.FarmMapCurrent = "Canyon"
    ConfigData.DualMapTimer = 0
    ConfigData.DualMapSubTimer = 0
    ConfigData.DualMapPoolIndex = 1
    forceFarmTP = true
    SaveConfig()
    BtnResetDualMap.Text = "✅ Farm State Kembali Default!"
    BtnResetDualMap.TextColor3 = Color3.fromRGB(100, 255, 100)
    task.delay(1.5, function() 
        BtnResetDualMap.Text = "🔄 Reset Farm State" 
        BtnResetDualMap.TextColor3 = c_text
    end)
end)

-- ========================================================
-- TAB ARCADIA EVENT (AUTO PELLET MACHINE & LIFE MACHINE)
-- ========================================================
local DropPellet = CreateDropdown(TabArcadiaEvent, "🎰 Pellet Machine Automation")
local UIStatus_Pellet = CreateStatusLabel(DropPellet)
local pelletToggleReady = false

if not ConfigData.AutoPellet then 
    UIStatus_Pellet.Text = "AUTO PELLET: OFF"
    UIStatus_Pellet.TextColor3 = c_subtext 
end

CreateToggle(DropPellet, "Enable Auto Pellet Machine", "AutoPellet", function(state)
    if state then
        UIStatus_Pellet.Text = "AUTO PELLET: ON (MENUNGGU INVADER'S)"
        UIStatus_Pellet.TextColor3 = Color3.fromRGB(50, 255, 100)
        pelletAutoInsideInvader = false
        pelletAutoStartAt = 0
    else
        UIStatus_Pellet.Text = "AUTO PELLET: OFF"
        UIStatus_Pellet.TextColor3 = c_subtext
        pelletAutoInsideInvader = false
        pelletAutoStartAt = 0
    end
end)
pelletToggleReady = true

local BtnManualPellet = CreateButton(DropPellet, "📌 Manual Pellet Machine (Force)", function()
    if ExecutePelletCycle then
        NotifyToast("Pellet Machine", "manual force dijalankan", "info")
        task.spawn(function()
            local ok = ExecutePelletCycle(true)
            if not ok then
                NotifyToast("Pellet Machine", "manual gagal / sedang dipakai sistem lain", "error")
            end
        end)
    end
end)
BtnManualPellet.BackgroundColor3 = c_sidebar
BtnManualPellet.TextColor3 = c_accent
BtnManualPellet:SetAttribute("ThemeRole", "accent_text")
Instance.new("UIStroke", BtnManualPellet).Color = c_accent

local DropLifeMachine = CreateDropdown(TabArcadiaEvent, "⚙️ Life Machine Automation")
local UIStatus_LifeMachine = CreateStatusLabel(DropLifeMachine)
if not ConfigData.AutoLifeMachine then
    UIStatus_LifeMachine.Text = "LIFE MACHINE: OFF"
    UIStatus_LifeMachine.TextColor3 = c_subtext
end

CreateToggle(DropLifeMachine, "Enable Life Machine", "AutoLifeMachine", function(state)
    if state then
        local remaining, _, source = GetLifeMachineCooldownRemaining()
        if remaining > 0 then
            UIStatus_LifeMachine.Text = "LIFE MACHINE: CD " .. formatSecondsToText(remaining) .. " [" .. tostring(source) .. "]"
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(255, 200, 50)
        elseif source == "UNKNOWN" then
            UIStatus_LifeMachine.Text = "LIFE MACHINE: SYNCING MACHINE..."
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            UIStatus_LifeMachine.Text = "LIFE MACHINE: READY"
            UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(50, 255, 100)
        end
    else
        UIStatus_LifeMachine.Text = "LIFE MACHINE: OFF"
        UIStatus_LifeMachine.TextColor3 = c_subtext
        lifeExtraLifeUIArmed = true
    end
end)

local BtnManualLifeMachine = CreateButton(DropLifeMachine, "⚡ Manual Trigger Life Machine", function()
    if not isLifeMachineExecuting and not isPelletExecuting and teleportLockOwner ~= "PELLET" and not arcadiaEventActive then
        task.spawn(function() ExecuteLifeMachine(UIStatus_LifeMachine, true) end)
        return "manual trigger berhasil dimulai"
    end
    return false
end)
BtnManualLifeMachine.BackgroundColor3 = c_sidebar
BtnManualLifeMachine.TextColor3 = c_accent
BtnManualLifeMachine:SetAttribute("ThemeRole", "accent_text")
Instance.new("UIStroke", BtnManualLifeMachine).Color = c_accent


local DropBooster = CreateDropdown(TabBooster, "🚀 Graphic & Performance Booster")
local UIStatus_Booster = CreateStatusLabel(DropBooster); UIStatus_Booster.Text = "BOOSTER STATUS: ACTIVE"; UIStatus_Booster.TextColor3 = Color3.fromRGB(50, 255, 100)
CreateToggle(DropBooster, "FPS Booster (Nuke Visuals)", "FPSBooster", function(state) if UIStatus_Booster then UIStatus_Booster.Text = "FPS BOOSTER: " .. (state and "ON" or "OFF"); UIStatus_Booster.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end end)
CreateToggle(DropBooster, "Clay Potato Mode", "ClayPotato", function(state) if state then EnableClayPotato() else DisableClayPotato() end; if UIStatus_Booster then UIStatus_Booster.Text = "CLAY POTATO: " .. (state and "ON" or "OFF"); UIStatus_Booster.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end end)
CreateToggle(DropBooster, "Disable 3D Rendering", "Disable3D", function(state) RunService:Set3dRenderingEnabled(not state); if UIStatus_Booster then UIStatus_Booster.Text = "3D RENDERING: " .. (state and "DISABLED" or "ENABLED"); UIStatus_Booster.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end end)
CreateToggle(DropBooster, "Clear Water", "ClearWater", function(state) if UIStatus_Booster then UIStatus_Booster.Text = "CLEAR WATER: " .. (state and "ON" or "OFF"); UIStatus_Booster.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end end)
CreateToggle(DropBooster, "Limit 30 FPS", "Limit30FPS", function(state) if setfpscap then setfpscap(state and 30 or 60) end; if UIStatus_Booster then UIStatus_Booster.Text = "LIMIT 30 FPS: " .. (state and "ON" or "OFF"); UIStatus_Booster.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end end)
CreateToggle(DropBooster, "Auto Clean RAM", "AutoRAM", function(state) if UIStatus_Booster then UIStatus_Booster.Text = "AUTO RAM: " .. (state and "ON" or "OFF"); UIStatus_Booster.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end end)

local DropGlobalWeb = CreateDropdown(TabWebhooks, "🔗 Global Webhook Configuration")
CreateTextBox(DropGlobalWeb, "Paste Webhook URL Discord Di Sini...", "WebhookURL", function(txt) end)
local DropWebToggles = CreateDropdown(TabWebhooks, "⚙️ Active Webhook Features")
UIStatus_PlayerMon = CreateStatusLabel(DropWebToggles)
local trackerInterval = 3600; local trackerRemaining = 0
CreateToggle(DropWebToggles, "Player Tracker Webhook", "WebhookPlayer", function(state)
    isTrackerActive = state
    if state then trackerRemaining = trackerInterval else trackerRemaining = 0; trackerUIPaused = false end
    if UIStatus_PlayerMon then UIStatus_PlayerMon.Text = state and "TRACKER: ON" or "TRACKER: OFF"; UIStatus_PlayerMon.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end
end)
CreateToggle(DropWebToggles, "Join / Leave Alert Webhook", "WebhookJoinLeave", function(state)
    if UIStatus_PlayerMon then UIStatus_PlayerMon.Text = state and "JOIN/LEAVE ALERT: ON" or "JOIN/LEAVE ALERT: OFF"; UIStatus_PlayerMon.TextColor3 = state and Color3.fromRGB(50, 255, 100) or c_subtext end
end)
local DropWebTest = CreateDropdown(TabWebhooks, "🧪 Test Webhook Triggers")
CreateButton(DropWebTest, "🚀 Kirim Test Player Tracker Manual", function() SendPlayerList(true) end)

local DropMapTP = CreateDropdown(TabTeleport, "Teleport to Island")
local MapLocations = {
    {Name = "Hutan Kuno", Pos = Vector3.new(1482.70, 11.14, -300.65), Rot = -30.84}, {Name = "Kedalaman Esoterik", Pos = Vector3.new(3210.66, -1302.86, 1407.32), Rot = 18.56},
    {Name = "Kedalaman Kristal", Pos = Vector3.new(5703.96, -905.21, 15328.31), Rot = -161.77}, {Name = "Ngarai Tembaga (Spot 1)", Pos = Vector3.new(-4171.59, 3.23, 566.77), Rot = 148.32},
    {Name = "Ngarai Tembaga (Spot 2)", Pos = Vector3.new(-4164.58, 59.63, 409.79), Rot = 104.76}, {Name = "Pulau Kawah", Pos = Vector3.new(978.88, 47.48, 5086.54), Rot = 127.91},
    {Name = "Runtuhan Kuno", Pos = Vector3.new(6089.14, -585.92, 4639.69), Rot = 142.21}, {Name = "Tambang Canyon Tembaga", Pos = Vector3.new(-4031.78, -544.08, 577.91), Rot = 25.84},
    {Name = "Terumbu Karang", Pos = Vector3.new(-3028.41, 2.51, 2269.79), Rot = 84.12}
}
local selectedMap = nil; local mapNames = {}
for _, map in ipairs(MapLocations) do table.insert(mapNames, map.Name) end
CreateSelector(DropMapTP, "Select Island", mapNames, function(sel) selectedMap = sel end)
local BtnTeleportMap = CreateButton(DropMapTP, "Teleport", function()
    if not selectedMap then return end
    for _, map in ipairs(MapLocations) do
        if map.Name == selectedMap then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(map.Pos) * CFrame.Angles(0, math.rad(map.Rot), 0)
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                return "berhasil TP ke " .. tostring(map.Name)
            end
            break
        end
    end
end)
BtnTeleportMap.BackgroundColor3 = c_sidebar; BtnTeleportMap.TextColor3 = c_accent
BtnTeleportMap:SetAttribute("ThemeRole", "accent_text"); Instance.new("UIStroke", BtnTeleportMap).Color = c_accent

local DropPlayerTP = CreateDropdown(TabTeleport, "Teleport to Player")
local playerMap = {}; local selectedPlayerObj = nil
local PlayerFrame, PlayerPopulate, PlayerSelectBtn = CreateSelector(DropPlayerTP, "Select Player", {}, function(selText) selectedPlayerObj = playerMap[selText] end)
local BtnTeleportPlayer = CreateButton(DropPlayerTP, "Teleport to selected Player", function()
    if not selectedPlayerObj then return end
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local targetHrp = selectedPlayerObj.Character and selectedPlayerObj.Character:FindFirstChild("HumanoidRootPart")
    if myHrp and targetHrp then
        myHrp.CFrame = targetHrp.CFrame
        myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        return "berhasil TP ke " .. tostring(selectedPlayerObj.DisplayName or selectedPlayerObj.Name)
    end
    return false
end)
BtnTeleportPlayer.BackgroundColor3 = c_sidebar; BtnTeleportPlayer.TextColor3 = c_accent
BtnTeleportPlayer:SetAttribute("ThemeRole", "accent_text"); Instance.new("UIStroke", BtnTeleportPlayer).Color = c_accent
local function LoadPlayers()
    playerMap = {}; local pDisplayNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then local pText = p.DisplayName .. " (@" .. p.Name .. ")"; table.insert(pDisplayNames, pText); playerMap[pText] = p end
    end
    PlayerPopulate(pDisplayNames); selectedPlayerObj = nil; PlayerSelectBtn.Text = "Select Option"; PlayerSelectBtn.TextColor3 = c_subtext
end
CreateButton(DropPlayerTP, "Refresh Player List", LoadPlayers); LoadPlayers()

local DropSavedTP = CreateDropdown(TabTeleport, "📌 Custom Saved Location")
-- Dibaca dari ConfigData supaya lokasi tidak hilang saat rejoin / reconnect.
local savedCustomLocation = DeserializeCFrame(ConfigData.SavedCustomLocation)

local BtnSaveLoc = CreateButton(DropSavedTP, "Save Current Location", function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedCustomLocation = hrp.CFrame
        ConfigData.SavedCustomLocation = SerializeCFrame(savedCustomLocation)
        SaveConfig()
        BtnSaveLoc.Text = "Location Saved Permanently!"
        BtnSaveLoc.TextColor3 = Color3.fromRGB(50, 255, 100)
        return "lokasi berhasil disimpan"
    else
        BtnSaveLoc.Text = "Player Not Found!"
        BtnSaveLoc.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    task.delay(2, function()
        BtnSaveLoc.Text = "Save Current Location"
        BtnSaveLoc.TextColor3 = c_text
    end)
end)

local BtnTeleportLoc = CreateButton(DropSavedTP, "Teleport to Saved", function()
    -- Refresh dari ConfigData juga agar data tetap menjadi sumber kebenaran.
    if not savedCustomLocation then
        savedCustomLocation = DeserializeCFrame(ConfigData.SavedCustomLocation)
    end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if savedCustomLocation and hrp then
        hrp.CFrame = savedCustomLocation
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        BtnTeleportLoc.Text = "Teleported to Saved!"
        BtnTeleportLoc.TextColor3 = Color3.fromRGB(100, 200, 255)
        return "berhasil TP ke Saved Location"
    else
        BtnTeleportLoc.Text = "No Save Found!"
        BtnTeleportLoc.TextColor3 = Color3.fromRGB(255, 100, 100)
        return false
    end
    task.delay(2, function()
        BtnTeleportLoc.Text = "Teleport to Saved"
        BtnTeleportLoc.TextColor3 = c_text
    end)
end)

local BtnResetLoc = CreateButton(DropSavedTP, "Reset Saved Location", function()
    savedCustomLocation = nil
    ConfigData.SavedCustomLocation = nil
    SaveConfig()
    BtnResetLoc.Text = "Location Reset Permanently!"
    BtnResetLoc.TextColor3 = Color3.fromRGB(255, 200, 50)
    task.delay(2, function()
        BtnResetLoc.Text = "Reset Saved Location"
        BtnResetLoc.TextColor3 = c_text
    end)
end)
CreateToggle(DropSavedTP, "Auto Teleport on Spawn", "AutoTeleportSpawn", function(state) end)

player.CharacterAdded:Connect(function(char)
    if ConfigData.AutoTeleportSpawn and savedCustomLocation then
        task.spawn(function()
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                task.wait(0.5)
                hrp.CFrame = savedCustomLocation
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                NotifyToast("Auto Teleport Spawn", "berhasil TP ke Saved Location", "success")
            end
        end)
    end
end)

local DropConfigSystem = CreateDropdown(TabConfig, "Configuration Manager")
CreateButton(DropConfigSystem, "💾 Save UI Settings Manual", function() SaveConfig() end)
local BtnReset = CreateButton(DropConfigSystem, "⚠️ Reset Settingan (Kembali Default)", function() end)
BtnReset.MouseButton1Click:Connect(function()
    ResetConfig()
    BtnReset.Text = "✅ Reset Global Berhasil!"; BtnReset.TextColor3 = Color3.fromRGB(100, 255, 100)
    task.wait(2); BtnReset.Text = "⚠️ Reset Settingan (Kembali Default)"; BtnReset.TextColor3 = c_text
end)

-- ==========================================================
-- 6.5. PLAYER & SERVER MODS 
-- ==========================================================
local DropSafety = CreateDropdown(TabPlayerMods, "🛡️ Server & Safety Mods")
CreateToggle(DropSafety, "Staff Detector & Auto Hop", "StaffDetector", function(state) end)

-- REJOIN / AUTO RECONNECT
-- Rejoin ke experience yang sama tanpa memaksa JobId tertentu.
-- Ini menghindari kegagalan saat instance saat ini private/reserved atau
-- ketika Roblox menolak teleport langsung ke JobId yang sedang aktif.
local rejoinInProgress = false
local function RequestRejoin(source)
    if rejoinInProgress then return false end
    rejoinInProgress = true

    local ts = game:GetService("TeleportService")
    local ok, err = pcall(function()
        ts:Teleport(game.PlaceId, player)
    end)

    if not ok then
        warn("[ShadowHub] " .. tostring(source or "Rejoin") .. " gagal: " .. tostring(err))
        rejoinInProgress = false
        return false
    end
    return true
end

-- Jika Roblox menolak/menggagalkan inisiasi teleport, izinkan percobaan lagi.
TeleportService.TeleportInitFailed:Connect(function(failedPlayer, teleportResult, errorMessage)
    if failedPlayer == player then
        rejoinInProgress = false
        warn("[ShadowHub] Rejoin/teleport gagal: " .. tostring(teleportResult) .. " - " .. tostring(errorMessage))
    end
end)

-- Auto reconnect memakai jalur rejoin yang sama dengan tombol manual.
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if ConfigData.AutoReconnect then
        RequestRejoin("Auto Reconnect")
    end
end)
CreateToggle(DropSafety, "Auto Reconnect (Anti DC/Kick)", "AutoReconnect", function(state) end)

CreateButton(DropSafety, "🔄 Rejoin Server (Sama)", function()
    RequestRejoin("Manual Rejoin")
end)

CreateButton(DropSafety, "🌍 Server Hop (Lainnya)", function()
    local Http = game:GetService("HttpService")
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        local response = req and req({Url = Api, Method = "GET"}).Body or game:HttpGet(Api)
        local data = Http:JSONDecode(response)
        if data and data.data then
            local servers = {}
            for _, srv in ipairs(data.data) do
                if type(srv) == "table" and tonumber(srv.playing) and tonumber(srv.maxPlayers) and srv.playing < srv.maxPlayers - 1 and srv.id ~= game.JobId then
                    table.insert(servers, srv.id)
                end
            end
            if #servers > 0 then
                TPS:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
            else
                TPS:Teleport(game.PlaceId, player)
            end
        end
    end)
end)

local DropCamera = CreateDropdown(TabPlayerMods, "🎥 Camera System")
CreateInfoLabel(DropCamera, "Info PC: Tekan F3 untuk on/off. Gerak [WASD], Naik [E/Space], Turun [Q/Shift].")
CreateInfoLabel(DropCamera, "Info Mobile: Gunakan Joystick layar untuk gerak, usap layar untuk putar kamera.")

CreateToggle(DropCamera, "Enable Freecam", "Freecam", function(state)
    local cam = workspace.CurrentCamera
    if state then
        if not workspace:FindFirstChild("ShadowFreecamDummy") then
            local dummy = Instance.new("Model", workspace)
            dummy.Name = "ShadowFreecamDummy"
            local fc = Instance.new("Part", dummy)
            fc.Name = "HumanoidRootPart"
            fc.Anchored = true; fc.CanCollide = false; fc.Transparency = 1; fc.Size = Vector3.new(1,1,1)
            local hum = Instance.new("Humanoid", dummy)
            local char = player.Character
            if char and char:FindFirstChild("Head") then fc.CFrame = char.Head.CFrame end
            dummy.PrimaryPart = fc
        end
        cam.CameraSubject = workspace:FindFirstChild("ShadowFreecamDummy"):FindFirstChild("Humanoid")
    else
        local char = player.Character; if char and char:FindFirstChild("Humanoid") then cam.CameraSubject = char.Humanoid end
        local dummy = workspace:FindFirstChild("ShadowFreecamDummy"); if dummy then dummy:Destroy() end
    end
end)

CreateToggle(DropCamera, "Unlimited Zoom", "UnlimitedZoom", function(state)
    player.CameraMaxZoomDistance = state and math.huge or 128
end)

local DropPlayer = CreateDropdown(TabPlayerMods, "🦸 Player Feature")

CreateToggle(DropPlayer, "Enable Custom Sprint", "SprintToggle", function(state) end)
CreateTextBox(DropPlayer, "Walk Speed (Default: 16)", "SprintSpeed", function(txt) end)
CreateToggle(DropPlayer, "Enable Fly Mode", "FlyMode", function(state) end)
CreateTextBox(DropPlayer, "Fly Speed (Default: 50)", "FlySpeed", function(txt) end)
CreateToggle(DropPlayer, "Hide Stats (Fake Name/Lv)", "HideStats", function(state) end)
CreateTextBox(DropPlayer, "Custom Fake Name", "CustomName", function(txt) end)
CreateTextBox(DropPlayer, "Custom Fake Level", "CustomLevel", function(txt) end)
CreateToggle(DropPlayer, "Roblox Plus Verification Logo", "RobloxPlusBadge", function(state) end)
CreateToggle(DropPlayer, "Infinite Jump", "InfiniteJump", function(state) end)
CreateToggle(DropPlayer, "No Clip (Tembus Objek)", "NoClip", function(state) end)
CreateToggle(DropPlayer, "Lava Kill Immunity", "LavaImmunity", function(state) end)
CreateToggle(DropPlayer, "Hide Character (Invisible)", "Invisible", function(state)
    local char = player.Character; if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = state and 1 or 0
        elseif v:IsA("Decal") then v.Transparency = state and 1 or 0 end
    end
end)

local DropTheme = CreateDropdown(TabPlayerMods, "🎨 Tema UI Panel")
CreateSelector(DropTheme, "Pilih Tema", {"Default", "Elegant Gold", "Crimson Blood", "Ocean Blue", "Neon Cyber"}, function(sel)
    ConfigData.SelectedTheme = sel; SaveConfig(); ApplyTheme()
end)

-- ==========================================================
-- 7. BACKGROUND ENGINES & THREADS
-- ==========================================================
ApplyTheme()
player.CameraMaxZoomDistance = ConfigData.UnlimitedZoom and math.huge or 128

UserInputService.JumpRequest:Connect(function()
    if ConfigData.InfiniteJump and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F3 then
        ConfigData.Freecam = not ConfigData.Freecam
        if UI_Updaters["Freecam"] then UI_Updaters["Freecam"](ConfigData.Freecam) end
    end
end)

RunService.Stepped:Connect(function()
    local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if ConfigData.NoClip and char then
        for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    
    if hum then 
        pcall(function() 
            hum.WalkSpeed = ConfigData.SprintToggle and (tonumber(ConfigData.SprintSpeed) or 16) or 16 
        end) 
    end
    
    if ConfigData.FlyMode and hrp and hum then
        local cam = workspace.CurrentCamera
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then ctrl.f = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then ctrl.b = -1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then ctrl.l = -1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then ctrl.r = 1 end
        
        local flySpeed = tonumber(ConfigData.FlySpeed) or 50
        hum.PlatformStand = true
        
        local bv = hrp:FindFirstChild("ShadowFlyVelocity") or Instance.new("BodyVelocity", hrp)
        bv.Name = "ShadowFlyVelocity"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = (cam.CFrame.LookVector * (ctrl.f + ctrl.b) + cam.CFrame.RightVector * (ctrl.l + ctrl.r)) * flySpeed
        
        local bg = hrp:FindFirstChild("ShadowFlyGyro") or Instance.new("BodyGyro", hrp)
        bg.Name = "ShadowFlyGyro"; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = cam.CFrame
    elseif hum and hum.PlatformStand then
        hum.PlatformStand = false
        if hrp:FindFirstChild("ShadowFlyVelocity") then hrp.ShadowFlyVelocity:Destroy() end
        if hrp:FindFirstChild("ShadowFlyGyro") then hrp.ShadowFlyGyro:Destroy() end
    end

    if ConfigData.Freecam then
        local dummy = workspace:FindFirstChild("ShadowFreecamDummy")
        if dummy and dummy.PrimaryPart then
            local fc = dummy.PrimaryPart
            local cam = workspace.CurrentCamera
            local spd = 2; local mov = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mov = mov + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mov = mov - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mov = mov - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mov = mov + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then mov = mov + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mov = mov - Vector3.new(0,1,0) end
            fc.CFrame = fc.CFrame + (mov * spd)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if ConfigData.LavaImmunity then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and (string.find(string.lower(v.Name), "lava") or v.Material == Enum.Material.Neon) then
                    v.CanTouch = false
                end
            end
        end
        if (ConfigData.HideStats or ConfigData.RobloxPlusBadge) and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                for _, gui in pairs(head:GetChildren()) do
                    if gui:IsA("BillboardGui") then
                        for _, text in pairs(gui:GetDescendants()) do
                            if text:IsA("TextLabel") and ConfigData.HideStats then
                                if string.find(text.Text, player.Name) or string.find(text.Text, player.DisplayName) then 
                                    text.Text = ConfigData.CustomName ~= "" and ConfigData.CustomName or "HiddenShadow" 
                                end
                                if string.find(string.lower(text.Text), "lv") then 
                                    text.Text = "Lv. " .. (ConfigData.CustomLevel ~= "" and ConfigData.CustomLevel or "999") 
                                end
                            elseif text:IsA("ImageLabel") then 
                                if ConfigData.RobloxPlusBadge then
                                    text.Visible = true
                                    text.Image = "rbxassetid://10250085440"
                                else
                                    text.Visible = false 
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if ConfigData.StaffDetector then
        local isStaff = false
        if p:GetRankInGroup(game.CreatorId) >= 200 then isStaff = true end
        local rName = string.lower(p:GetRoleInGroup(game.CreatorId) or "")
        if string.find(rName, "admin") or string.find(rName, "mod") or string.find(rName, "staff") then isStaff = true end
        if isStaff then
            pcall(function()
                local Http = game:GetService("HttpService"); local TPS = game:GetService("TeleportService")
                local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                local data = Http:JSONDecode(game:HttpGet(Api))
                for _, srv in ipairs(data.data) do
                    if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then TPS:TeleportToPlaceInstance(game.PlaceId, srv.id, player); break end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isTrackerActive then
            if trackerRemaining <= 0 then
                SendPlayerList(false); trackerRemaining = trackerInterval
            else
                trackerRemaining = trackerRemaining - 1
                if not trackerUIPaused and UIStatus_PlayerMon then
                    local menit = math.floor(trackerRemaining / 60); local detik = trackerRemaining % 60
                    UIStatus_PlayerMon.Text = string.format("TRACKER AKTIF : NEXT SEND %02d:%02d", menit, detik)
                    UIStatus_PlayerMon.TextColor3 = Color3.fromRGB(50, 255, 100)
                end
            end
        end
    end
end)

player.Idled:Connect(function() if ConfigData.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end end)
-- Beberapa executor Roblox hanya mengizinkan collectgarbage("count").
-- Lindungi panggilan agar executor tidak menghasilkan error berulang.
task.spawn(function()
    while true do
        task.wait(1800)
        if ConfigData.AutoRAM then
            pcall(function() collectgarbage("collect") end)
        end
    end
end)

-- ====== [THREAD 1]: AUTO TP CUACA ======
local hasTeleportedToWeather = false
task.spawn(function()
    while true do
        task.wait(1)
        if ConfigData.AutoTP then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then isWeatherTPBusy = false; continue end
            local schedule = GetEventScheduleWIB()

            if schedule.state == "COOLDOWN" then
                isWeatherTPBusy = false 
                hasTeleportedToWeather = false
                
                while ConfigData.AutoTP do
                    local realTimeSchedule = GetEventScheduleWIB()
                    if realTimeSchedule.state == "ACTIVE" then break end 
                    UIStatus_Elemental.Text = "CD: " .. formatSecondsToText(realTimeSchedule.timeLeft)
                    UIStatus_Elemental.TextColor3 = Color3.fromRGB(255, 200, 50)
                    task.wait(1)
                end
            elseif schedule.state == "ACTIVE" then
                UIStatus_Elemental.Text = "MENUJU PAPAN..."; UIStatus_Elemental.TextColor3 = Color3.fromRGB(100, 200, 255)
                if not isPelletExecuting and teleportLockOwner ~= "PELLET" and not isLifeMachineExecuting and not hasTeleportedToWeather then
                    hrp.CFrame = spotKordinat.Board
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    NotifyToast("Auto TP Cuaca", "berhasil TP ke Board", "success")
                    task.wait(1.5)
                end
                
                local cuacaAktif = GetWeatherIconOnly()
                if cuacaAktif then
                    local targetCFrame = spotKordinat[cuacaAktif]; isWeatherTPBusy = true
                    while ConfigData.AutoTP do
                        local realTimeSchedule = GetEventScheduleWIB()
                        if realTimeSchedule.state == "COOLDOWN" then break end 
                        UIStatus_Elemental.Text = string.upper(cuacaAktif) .. ": " .. formatSecondsToText(realTimeSchedule.timeLeft)
                        UIStatus_Elemental.TextColor3 = Color3.fromRGB(50, 255, 100)
                        
                        -- Execute teleport once safely (No Lock Loop)
                        if hrp and targetCFrame and not hasTeleportedToWeather and not isPelletExecuting and teleportLockOwner ~= "PELLET" and not isLifeMachineExecuting and not arcadiaEventActive then
                            hrp.CFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, 3, 0)) * targetCFrame.Rotation
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            hasTeleportedToWeather = true
                            NotifyToast("Auto TP Cuaca", "berhasil TP ke " .. tostring(cuacaAktif), "success")
                            if ConfigData.AutoFishingToggle then forceFarmTP = true end
                        end
                        task.wait(1)
                    end
                    isWeatherTPBusy = false
                    hasTeleportedToWeather = false
                else
                    isWeatherTPBusy = false; UIStatus_Elemental.Text = "MENUNGGU ICON CUACA..."; UIStatus_Elemental.TextColor3 = c_subtext; task.wait(1)
                end
            end
        else
            isWeatherTPBusy = false
            hasTeleportedToWeather = false
        end
    end
end)

-- ====== [THREAD 1.5]: AUTO TP ARCADIA ======
--
-- SIKLUS BARU:
--   1) Waktu global hanya membuka scanner 20 menit sebelum jadwal Kraken.
--   2) UI Battle Kraken adalah SATU-SATUNYA trigger TP ke Arcadia.
--   3) Setelah Battle dimulai, tunggu UI Defeat.
--   4) Jika Defeat tidak terlihat, backup 5 menit dari waktu Battle dimulai.
--   5) Setelah return, scanner OFF dan kembali menunggu jadwal global berikutnya.
--
local hasTeleportedToArcadia = false
arcadiaEventActive = false
local arcadiaEventReturnCFrame = nil
local arcadiaEventSource = "NONE"
local arcadiaBackupDeadline = nil
local arcadiaBattleUISeen = false
local arcadiaLastEventState = "NONE"
local arcadiaScannerActive = false

local function NormalizeEventText(text)
    text = string.lower(tostring(text or ""))
    text = text:gsub("[^%w%s]", " ")
    text = text:gsub("%s+", " ")
    return text
end

local function GetKrakenEventUIState()
    local battleFound = false
    local defeatFound = false

    local function scanGuiRoot(root)
        if not root then return end
        local visibleText = {}
        local hasBattleTitle, hasDefeatTitle, hasStartedText = false, false, false
        for _, gui in ipairs(root:GetDescendants()) do
            if (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox"))
                and gui.Visible then
                local txt = NormalizeEventText(gui.Text)
                if txt ~= "" then
                    table.insert(visibleText, txt)
                    if string.find(txt, "pertempuran kraken", 1, true)
                        or string.find(txt, "kraken battle", 1, true) then
                        hasBattleTitle = true
                    end
                    if string.find(txt, "kekalahan kraken", 1, true)
                        or string.find(txt, "kraken defeat", 1, true) then
                        hasDefeatTitle = true
                    end
                    if string.find(txt, "acara telah dimulai", 1, true)
                        or string.find(txt, "event has started", 1, true)
                        or string.find(txt, "battle has started", 1, true) then
                        hasStartedText = true
                    end
                end

                if string.find(txt, "pertempuran kraken", 1, true)
                    or string.find(txt, "kraken battle", 1, true) then
                    if string.find(txt, "acara telah dimulai", 1, true)
                        or string.find(txt, "event has started", 1, true)
                        or string.find(txt, "battle has started", 1, true) then
                        battleFound = true
                    end
                end
                if string.find(txt, "kekalahan kraken", 1, true)
                    or string.find(txt, "kraken defeat", 1, true) then
                    if string.find(txt, "acara telah dimulai", 1, true)
                        or string.find(txt, "event has started", 1, true)
                        or string.find(txt, "battle has started", 1, true) then
                        defeatFound = true
                    end
                end
            end
        end

        local joined = " " .. table.concat(visibleText, " ") .. " "
        if hasBattleTitle and hasStartedText then battleFound = true end
        if hasDefeatTitle and hasStartedText then defeatFound = true end
        if (string.find(joined, "pertempuran kraken", 1, true)
                or string.find(joined, "kraken battle", 1, true))
            and (string.find(joined, "acara telah dimulai", 1, true)
                or string.find(joined, "event has started", 1, true)
                or string.find(joined, "battle has started", 1, true)) then
            battleFound = true
        end
        if (string.find(joined, "kekalahan kraken", 1, true)
                or string.find(joined, "kraken defeat", 1, true))
            and (string.find(joined, "acara telah dimulai", 1, true)
                or string.find(joined, "event has started", 1, true)
                or string.find(joined, "battle has started", 1, true)) then
            defeatFound = true
        end
    end

    scanGuiRoot(player:FindFirstChildOfClass("PlayerGui"))
    pcall(function() scanGuiRoot(CoreGui) end)

    if defeatFound then
        return "DEFEAT"
    elseif battleFound then
        return "BATTLE"
    end
    return "NONE"
end

local function ReturnFromArcadiaEvent()
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if arcadiaEventReturnCFrame then
        hrp.CFrame = arcadiaEventReturnCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    elseif ConfigData.AutoFishingToggle then
        forceFarmTP = true
    end
end

local function StartArcadiaEvent(source)
    if arcadiaEventActive or not ConfigData.AutoArcadia then return end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    arcadiaEventReturnCFrame = hrp.CFrame
    arcadiaEventActive = true
    isArcadiaTPBusy = true
    hasTeleportedToArcadia = true
    arcadiaEventSource = source or "UI"
    arcadiaBattleUISeen = true

    -- Backup 5 menit dimulai tepat saat UI Battle terdeteksi.
    -- Jika UI Defeat tidak pernah terlihat (mis. DC/GUI hilang), event
    -- otomatis selesai setelah deadline ini.
    arcadiaBackupDeadline = os.clock() + (5 * 60)

    local targetCFrame = spotKordinat.Arcadia
    if targetCFrame then
        hrp.CFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, 3, 0)) * targetCFrame.Rotation
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        NotifyToast("Auto TP Kraken", "berhasil TP ke Arcadia", "success")
    end

    if UIStatus_Arcadia then
        UIStatus_Arcadia.Text = "KRAKEN BATTLE: MENUJU ARCADIA..."
        UIStatus_Arcadia.TextColor3 = Color3.fromRGB(100, 200, 255)
    end
end

local function FinishArcadiaEvent(reason)
    if not arcadiaEventActive then return end

    arcadiaEventActive = false
    hasTeleportedToArcadia = false
    isArcadiaTPBusy = false
    arcadiaScannerActive = false

    ReturnFromArcadiaEvent()

    if UIStatus_Arcadia then
        if reason == "DEFEAT" then
            UIStatus_Arcadia.Text = ConfigData.AutoFishingToggle
                and "KRAKEN KALAH: FARM LANJUT"
                or "KRAKEN KALAH: KEMBALI & IDLE"
        elseif reason == "BACKUP_END" then
            UIStatus_Arcadia.Text = ConfigData.AutoFishingToggle
                and "BACKUP 5M: FARM LANJUT"
                or "BACKUP 5M: KEMBALI & IDLE"
        else
            UIStatus_Arcadia.Text = "ARCADIA: SELESAI, KEMBALI"
        end
        UIStatus_Arcadia.TextColor3 = Color3.fromRGB(50, 255, 100)
    end

    -- Jadwal global TIDAK di-reset di sini. Setelah return, loop akan
    -- menghitung ulang waktu global dan menunggu window scanner berikutnya.
    arcadiaEventReturnCFrame = nil
    arcadiaEventSource = "NONE"
    arcadiaBackupDeadline = nil
    arcadiaBattleUISeen = false
    NotifyToast("Auto TP Kraken", "event selesai • berhasil kembali", "success")
end

task.spawn(function()
    while true do
        task.wait(0.20)

        if not ConfigData.AutoArcadia then
            if arcadiaEventActive then
                FinishArcadiaEvent("DISABLED")
            else
                isArcadiaTPBusy = false
                hasTeleportedToArcadia = false
                arcadiaScannerActive = false
            end
            continue
        end

        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Saat event aktif, scanner tetap hidup karena UI Defeat adalah
        -- trigger utama untuk mengakhiri event.
        if arcadiaEventActive then
            local uiState = GetKrakenEventUIState()
            arcadiaLastEventState = uiState

            if uiState == "DEFEAT" then
                FinishArcadiaEvent("DEFEAT")
                continue
            end

            -- Jika Defeat tidak pernah terlihat, backup 5 menit tetap menjadi
            -- safety net. Ini mencakup UI hilang/DC setelah Battle terdeteksi.
            if arcadiaBackupDeadline and os.clock() >= arcadiaBackupDeadline then
                FinishArcadiaEvent("BACKUP_END")
                continue
            end

            if UIStatus_Arcadia then
                local left = arcadiaBackupDeadline and math.max(0, math.ceil(arcadiaBackupDeadline - os.clock())) or 0
                UIStatus_Arcadia.Text = "KRAKEN BATTLE: MENUNGGU KALAH (BACKUP " .. formatSecondsToText(left) .. ")"
                UIStatus_Arcadia.TextColor3 = Color3.fromRGB(255, 200, 50)
            end
            continue
        end

        -- Di luar event aktif, JANGAN scan UI Kraken terus-menerus.
        -- Global timer hanya menentukan kapan scanner dibuka.
        local schedule = GetArcadiaScheduleWIB()

        if schedule.state == "SCAN" then
            arcadiaScannerActive = true
            local uiState = GetKrakenEventUIState()
            arcadiaLastEventState = uiState

            if uiState == "BATTLE" then
                StartArcadiaEvent("UI")
            else
                if UIStatus_Arcadia then
                    if schedule.timeLeft > 0 then
                        UIStatus_Arcadia.Text = "SCANNING KRAKEN: EVENT " .. formatSecondsToText(schedule.timeLeft)
                    else
                        UIStatus_Arcadia.Text = "SCANNING KRAKEN: MENUNGGU BATTLE UI..."
                    end
                    UIStatus_Arcadia.TextColor3 = Color3.fromRGB(255, 200, 50)
                end
            end
        else
            arcadiaScannerActive = false
            if UIStatus_Arcadia then
                UIStatus_Arcadia.Text = "NEXT KRAKEN: " .. formatSecondsToText(schedule.timeLeft)
                UIStatus_Arcadia.TextColor3 = Color3.fromRGB(255, 200, 50)
            end
        end
    end
end)

-- ====== [THREAD 1.6]: AUTO LIFE MACHINE PERFECT LOGIC ======
task.spawn(function()
    while true do
        task.wait(0.5) -- Sedikit dipercepat agar real-time CD lebih akurat update nya
        if ConfigData.AutoLifeMachine then
            
            -- Status Life Machine selalu ditampilkan:
            -- WORLD = timer fisik mesin, PERSISTED = timestamp terakhir
            -- yang disimpan sebelum DC/rejoin.
            local lifeCDRemaining = 0
            local lifeCDText = "READY"
            local lifeCDSource = "PERSISTED"

            if not isLifeMachineExecuting then
                lifeCDRemaining, lifeCDText, lifeCDSource = GetLifeMachineCooldownRemaining()

                if lifeCDRemaining > 0 then
                    UIStatus_LifeMachine.Text = string.format(
                        "LIFE MACHINE: CD %s [%s]",
                        formatSecondsToText(lifeCDRemaining),
                        lifeCDSource
                    )
                    UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(255, 200, 50)
                elseif lifeCDSource == "UNKNOWN" then
                    UIStatus_LifeMachine.Text = "LIFE MACHINE: SYNCING MACHINE..."
                    UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(100, 200, 255)
                else
                    UIStatus_LifeMachine.Text = "LIFE MACHINE: READY"
                    UIStatus_LifeMachine.TextColor3 = Color3.fromRGB(50, 255, 100)
                end
            end

            if not isLifeMachineExecuting and not isPelletExecuting and teleportLockOwner ~= "PELLET" then
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                -- Deteksi popup Extra Life dalam bahasa Inggris maupun Indonesia.
                -- Beberapa UI memecah kalimat ke beberapa label, jadi gabungkan
                -- teks yang terlihat dan scan PlayerGui serta CoreGui.
                local foundUI = false
                local function scanExtraLifeUI(root)
                    if not root or foundUI then return end
                    local visibleTexts = {}
                    for _, gui in ipairs(root:GetDescendants()) do
                        if (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox"))
                            and gui.Visible then
                            local txt = NormalizeEventText(gui.Text)
                            if txt ~= "" then
                                table.insert(visibleTexts, txt)
                                if string.find(txt, "you fished up an extra life", 1, true)
                                    or string.find(txt, "you caught an extra life", 1, true)
                                    or string.find(txt, "anda menangkap kehidupan ekstra", 1, true)
                                    or string.find(txt, "anda menangkap nyawa ekstra", 1, true)
                                    or string.find(txt, "anda mendapatkan nyawa ekstra", 1, true)
                                    or string.find(txt, "anda menangkap extra life", 1, true) then
                                    foundUI = true
                                    return
                                end
                            end
                        end
                    end
                    local joined = " " .. table.concat(visibleTexts, " ") .. " "
                    local hasIndonesianCatch = string.find(joined, "anda menangkap", 1, true)
                        and (string.find(joined, "kehidupan ekstra", 1, true)
                            or string.find(joined, "nyawa ekstra", 1, true)
                            or string.find(joined, "extra life", 1, true))
                    if hasIndonesianCatch
                        or string.find(joined, "you fished up an extra life", 1, true)
                        or string.find(joined, "you caught an extra life", 1, true)
                        or string.find(joined, "anda menangkap kehidupan ekstra", 1, true)
                        or string.find(joined, "anda menangkap nyawa ekstra", 1, true)
                        or string.find(joined, "anda mendapatkan nyawa ekstra", 1, true)
                        or string.find(joined, "anda menangkap extra life", 1, true) then
                        foundUI = true
                    end
                end

                scanExtraLifeUI(player:FindFirstChildOfClass("PlayerGui"))
                pcall(function() scanExtraLifeUI(CoreGui) end)

                if not foundUI then
                    -- Popup sudah hilang: sistem kembali siap menerima
                    -- kemunculan Extra Life berikutnya.
                    lifeExtraLifeUIArmed = true
                elseif lifeExtraLifeUIArmed then
                    local distToInvaderMap = (hrp.Position - invaderPos).Magnitude

                    if distToInvaderMap < 350 then
                        -- Disarm SEBELUM teleport supaya popup yang sama
                        -- tidak menyebabkan perjalanan 2-3 kali.
                        lifeExtraLifeUIArmed = false
                        ExecuteLifeMachine(UIStatus_LifeMachine, false)
                    end
                end
            end
        else
            if UIStatus_LifeMachine and UIStatus_LifeMachine.Text ~= "LIFE MACHINE: OFF" then
                UIStatus_LifeMachine.Text = "LIFE MACHINE: OFF"
                UIStatus_LifeMachine.TextColor3 = c_subtext
            end
        end
    end
end)


-- ====== [THREAD 1.75]: AUTO PELLET MACHINE - 4x FAST CYCLE / INVADER'S ONLY ======
local function clickTargetUI(targetButton)
    if targetButton and targetButton.Visible and targetButton.AbsoluteSize.X > 0 then
        local absPos = targetButton.AbsolutePosition
        local absSize = targetButton.AbsoluteSize
        local inset = GuiService:GetGuiInset()

        local clickX = absPos.X + (absSize.X / 2)
        local clickY = absPos.Y + (absSize.Y / 2) + inset.Y

        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
        end)
        return true
    end
    return false
end

local function findCloseButton(uiContainer)
    local candidates = {}

    for _, gui in pairs(uiContainer:GetDescendants()) do
        if gui:IsA("GuiButton") and gui.Visible and gui.AbsoluteSize.X > 0 then
            table.insert(candidates, gui)
        end
    end

    for _, gui in ipairs(candidates) do
        local name = string.lower(gui.Name)
        local txt = gui:IsA("TextButton") and string.lower(gui.Text or "") or ""
        if string.find(name, "close") or string.find(name, "exit") or name == "x" or txt == "x" then
            return gui
        end
    end

    local bestGuess = nil
    local highestScore = -math.huge

    for _, gui in ipairs(candidates) do
        local absSize = gui.AbsoluteSize
        local absPos = gui.AbsolutePosition

        local ratio = math.max(absSize.X, absSize.Y) / math.max(1, math.min(absSize.X, absSize.Y))
        if ratio <= 2.5 and absSize.X < 90 and absSize.Y < 90 then
            local score = absPos.X - (absPos.Y * 3)
            if score > highestScore then
                highestScore = score
                bestGuess = gui
            end
        end
    end

    return bestGuess
end

local function firePelletPrompt()
    local fired = false

    for _, desc in pairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local parentPart = desc.Parent
            local isNear = true

            if parentPart and parentPart:IsA("BasePart") then
                isNear = (parentPart.Position - spotKordinat.PelletMachine.Position).Magnitude < 25
            end

            if isNear and (
                string.find(string.lower(desc.ObjectText or ""), "pellet")
                or string.find(string.lower(desc.ActionText or ""), "use")
                or string.find(string.lower(desc.ObjectText or ""), "machine")
            ) then
                if fireproximityprompt then
                    fireproximityprompt(desc)
                    fired = true
                end
            end
        end
    end

    if not fired then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end

-- Mesin/UI logic existing dipertahankan: feed sampai state mesin selesai,
-- lalu close ketika Full / Not Enough. Di akhir cycle kita juga force-close
-- jika UI masih terbuka.
local function processFeedMachineAndClose()
    local feedResult = "FEEDING"
    for attempt = 1, 6 do
        local targetFeedButton = nil
        local isFull = false
        local isNotEnough = false
        local mainUIContainer = nil

        for _, gui in pairs(player.PlayerGui:GetDescendants()) do
            if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                local txt = string.lower(gui.Text or "")

                if string.find(txt, "ghost slots full") then
                    isFull = true
                    local parent = gui
                    while parent and not parent:IsA("ScreenGui") do
                        parent = parent.Parent
                    end
                    mainUIContainer = parent or player.PlayerGui
                    break
                elseif string.find(txt, "need") and string.find(txt, "more") then
                    isNotEnough = true
                    local parent = gui
                    while parent and not parent:IsA("ScreenGui") do
                        parent = parent.Parent
                    end
                    mainUIContainer = parent or player.PlayerGui
                    break
                elseif string.find(txt, "feed machine") then
                    local parent = gui
                    for i = 1, 5 do
                        if parent and parent:IsA("GuiButton") then
                            targetFeedButton = parent
                            break
                        end
                        parent = parent.Parent
                    end
                end
            end
        end

        if isFull then
            if UIStatus_Pellet then
                UIStatus_Pellet.Text = "STATUS: MESIN FULL! CLOSING..."
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
            NotifyToast("Pellet Machine", "mesin FULL • UI ditutup", "info")
            feedResult = "FULL"
            task.wait(0.25)

            local closeButton = findCloseButton(mainUIContainer or player.PlayerGui)
            if closeButton then
                clickTargetUI(closeButton)
                task.wait(0.35)
            end
            break
        end

        if isNotEnough then
            if UIStatus_Pellet then
                UIStatus_Pellet.Text = "STATUS: PELLET TIDAK CUKUP! CLOSING..."
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 150, 50)
            end
            NotifyToast("Pellet Machine", "pellet tidak cukup • UI ditutup", "error")
            feedResult = "NOT_ENOUGH"
            task.wait(0.25)

            local closeButton = findCloseButton(mainUIContainer or player.PlayerGui)
            if closeButton then
                clickTargetUI(closeButton)
                task.wait(0.35)
            end
            break
        end

        if targetFeedButton then
            if UIStatus_Pellet then
                UIStatus_Pellet.Text = "STATUS: FEEDING MACHINE (" .. attempt .. "/6)"
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(50, 255, 100)
            end
            clickTargetUI(targetFeedButton)
            if attempt == 1 then
                NotifyToast("Pellet Machine", "Feed Machine berhasil dijalankan", "success")
            end
            task.wait(1.5)
        else
            task.wait(0.35)
        end
    end

    -- User wants every 1x cycle to end with the UI closed.
    task.wait(0.15)
    local closeButton = findCloseButton(player.PlayerGui)
    if closeButton then
        clickTargetUI(closeButton)
        NotifyToast("Pellet Machine", "UI berhasil ditutup", "success")
        task.wait(0.35)
    end
    return feedResult
end

-- One complete pellet-machine cycle:
-- 1) TP machine -> 2) open UI with E -> 3) immediately TP to final position
-- 4) Feed Machine -> 5) close UI.
ExecutePelletCycle = function(isManual)
    if isPelletExecuting or isLifeMachineExecuting or arcadiaEventActive then
        return false
    end
    -- If another system owns the teleport lock, Pellet waits. Otherwise Pellet takes it.
    if teleportLockOwner and teleportLockOwner ~= "PELLET" then
        return false
    end
    local acquiredPelletTeleportLock = false

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end

    -- Auto is restricted to Invader's. Manual intentionally bypasses this.
    if not isManual then
        local distToInvaderMap = (hrp.Position - invaderPos).Magnitude
        if distToInvaderMap > 350 then
            return false
        end
    end

    if not teleportLockOwner then
        teleportLockOwner = "PELLET"
        acquiredPelletTeleportLock = true
    end
    isPelletExecuting = true
    local originalCFrame = hrp.CFrame

    local ok, err = pcall(function()
        -- STEP 1: TP pellet machine.
        if UIStatus_Pellet then
            UIStatus_Pellet.Text = isManual and "MANUAL: MENUJU MESIN PELLET" or "AUTO: MENUJU MESIN PELLET"
            UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 200, 50)
        end

        hrp.CFrame = spotKordinat.PelletMachine
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        NotifyToast("Pellet Machine", "berhasil TP ke mesin", "success")
        -- Give Invader's -> Arcadia streaming/rendering time to finish before E.
        task.wait(1.50)

        -- STEP 2: Open the pellet UI.
        if UIStatus_Pellet then
            UIStatus_Pellet.Text = "STATUS: MENGAKTIFKAN MESIN (E)"
            UIStatus_Pellet.TextColor3 = Color3.fromRGB(100, 255, 255)
        end

        firePelletPrompt()
        NotifyToast("Pellet Machine", "ProximityPrompt / E berhasil", "success")
        task.wait(0.45)

        -- STEP 3: Return to the character's original/final position.
        -- IMPORTANT: this is NOT Arcadia. The Pellet UI remains open, so the
        -- Feed Machine can be processed from wherever the character started.
        if UIStatus_Pellet then
            UIStatus_Pellet.Text = "STATUS: KEMBALI KE POSISI AWAL"
            UIStatus_Pellet.TextColor3 = Color3.fromRGB(100, 255, 255)
        end

        hrp.CFrame = originalCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        NotifyToast("Pellet Machine", "berhasil kembali ke posisi awal", "success")
        task.wait(0.25)

        -- STEP 4 + 5: Existing Feed Machine logic, then close.
        local feedResult = processFeedMachineAndClose()
        if feedResult == "FEEDING" then
            NotifyToast("Pellet Machine", "cycle feeding selesai", "success")
        end
    end)

    -- Safety: never leave the UI open after a cycle if a close button exists.
    if player.PlayerGui then
        task.wait(0.1)
        local closeButton = findCloseButton(player.PlayerGui)
        if closeButton then
            clickTargetUI(closeButton)
            task.wait(0.25)
        end
    end

    -- Return to the position from which the 4x batch started.
    character = player.Character
    hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp and originalCFrame then
        hrp.CFrame = originalCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end

    if ConfigData.AutoFishingToggle then
        forceFarmTP = true
    end

    isPelletExecuting = false
    if acquiredPelletTeleportLock and teleportLockOwner == "PELLET" then
        teleportLockOwner = nil
    end

    if not ok then
        if UIStatus_Pellet then
            UIStatus_Pellet.Text = "STATUS: CYCLE ERROR, RETRY NEXT"
            UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        NotifyToast("Pellet Machine", "cycle gagal • akan retry", "error")
        return false, err
    end

    return true
end

task.spawn(function()
    while true do
        task.wait(0.25)

        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")

        if not ConfigData.AutoPellet then
            pelletAutoInsideInvader = false
            pelletAutoStartAt = 0
            continue
        end

        if not hrp then
            continue
        end

        -- Auto can only START while physically inside Invader's.
        local distToInvaderMap = (hrp.Position - invaderPos).Magnitude
        local insideInvader = distToInvaderMap <= 350

        if not insideInvader then
            pelletAutoInsideInvader = false
            pelletAutoStartAt = 0

            if not isPelletExecuting and UIStatus_Pellet then
                UIStatus_Pellet.Text = "AUTO PELLET: MENUNGGU INVADER'S"
                UIStatus_Pellet.TextColor3 = c_subtext
            end

            continue
        end

        -- Detect arrival/entry into Invader's and arm the required 15s delay.
        if not pelletAutoInsideInvader then
            pelletAutoInsideInvader = true
            pelletAutoStartAt = os.clock() + 15

            if UIStatus_Pellet then
                UIStatus_Pellet.Text = "AUTO PELLET: TUNGGU 15 DETIK DI INVADER'S"
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 200, 50)
            end
            NotifyToast("Pellet Machine", "masuk Invader's • start dalam 15 detik", "info")
        end

        if os.clock() < pelletAutoStartAt then
            continue
        end

        if isPelletExecuting or isLifeMachineExecuting or arcadiaEventActive then
            continue
        end

        -- One batch = exactly 4 complete cycles.
        -- Hold teleport priority for the entire 4-cycle batch, including the 5s gaps.
        if teleportLockOwner and teleportLockOwner ~= "PELLET" then
            continue
        end
        teleportLockOwner = "PELLET"
        local batchCharacter = player.Character
        local batchHRP = batchCharacter and batchCharacter:FindFirstChild("HumanoidRootPart")
        local originalCFrame = batchHRP and batchHRP.CFrame

        local batchOK = true

        for cycle = 1, 4 do
            if not ConfigData.AutoPellet then
                batchOK = false
                break
            end

            if UIStatus_Pellet then
                UIStatus_Pellet.Text = string.format("AUTO PELLET: SIKLUS %d/4", cycle)
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(50, 255, 100)
            end
            NotifyToast("Pellet Machine", string.format("siklus %d/4 dimulai", cycle), "info")

            -- Execute the inner cycle while holding the batch lock.
            isPelletExecuting = false
            local ok = ExecutePelletCycle(false)
            if not ok then
                batchOK = false
                break
            end

            -- 5s only BETWEEN cycles, not before the final cooldown.
            if cycle < 4 then
                if UIStatus_Pellet then
                    UIStatus_Pellet.Text = string.format("AUTO PELLET: JEDA %ds (%d/4)", 5, cycle)
                    UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 200, 50)
                end
                NotifyToast("Pellet Machine", string.format("siklus %d selesai • jeda 5 detik", cycle), "info")
                task.wait(5)
            end
        end

        -- Ensure batch lock is released and return to the batch-start position.
        batchCharacter = player.Character
        batchHRP = batchCharacter and batchCharacter:FindFirstChild("HumanoidRootPart")
        if batchHRP and originalCFrame then
            batchHRP.CFrame = originalCFrame
            batchHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end

        isPelletExecuting = false
        if teleportLockOwner == "PELLET" then
            teleportLockOwner = nil
        end

        if not batchOK then
            if UIStatus_Pellet and ConfigData.AutoPellet then
                UIStatus_Pellet.Text = "AUTO PELLET: BATCH BERHENTI / MENUNGGU INVADER'S"
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 150, 50)
            end
            task.wait(1)
            continue
        end

        NotifyToast("Pellet Machine", "4/4 sukses • cooldown 30 menit dimulai", "success")

        -- 30-minute cooldown starts ONLY after the 4th cycle.
        local pelletCooldown = 1800
        while pelletCooldown > 0 and ConfigData.AutoPellet do
            if UIStatus_Pellet then
                local m = math.floor(pelletCooldown / 60)
                local sec = pelletCooldown % 60
                UIStatus_Pellet.Text = string.format("PELLET COOLDOWN: %02dm %02ds", m, sec)
                UIStatus_Pellet.TextColor3 = Color3.fromRGB(255, 200, 50)
            end

            task.wait(1)
            pelletCooldown = pelletCooldown - 1
        end

        if UIStatus_Pellet and ConfigData.AutoPellet then
            UIStatus_Pellet.Text = "AUTO PELLET: ON (MENUNGGU SIKLUS)"
            UIStatus_Pellet.TextColor3 = Color3.fromRGB(50, 255, 100)
        end

        -- Re-arm the 15s gate only when the player enters Invader's again.
        pelletAutoInsideInvader = false
        pelletAutoStartAt = 0
    end
end)

-- ====== [THREAD 2]: AUTO FISHING / FARM MODE ENGINE (NO LOCK POS) ======
task.spawn(function()
    while true do
        task.wait(1)
        if ConfigData.AutoFishingToggle then
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            
            -- Jangan ganggu Event/Pellet/Life Machine jika sedang sibuk teleport
            local isEventActive = (isWeatherTPBusy or isArcadiaTPBusy or arcadiaEventActive or isPelletExecuting or isLifeMachineExecuting or teleportLockOwner == "PELLET")

            if hrp then
                if ConfigData.SelectedFarmingMode == "Map 1 (Throne Room)" then
                    ConfigData.FarmMapCurrent = "Throne"
                    
                    ConfigData.DualMapSubTimer = ConfigData.DualMapSubTimer + 1
                    if ConfigData.DualMapSubTimer >= rotateInterval then
                        ConfigData.DualMapSubTimer = 0
                        ConfigData.DualMapPoolIndex = (ConfigData.DualMapPoolIndex % #poolAngles) + 1
                        SaveConfig()
                        NotifyToast("Auto Fishing", string.format("rotate %d/%d siap", ConfigData.DualMapPoolIndex, #poolAngles), "info")
                        forceFarmTP = true
                    end
                    
                    if not isEventActive and forceFarmTP then
                        local currentAngle = poolAngles[ConfigData.DualMapPoolIndex] or poolAngles[1]
                        hrp.CFrame = CFrame.new(standPositionRot) * CFrame.Angles(0, math.rad(currentAngle), 0)
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        NotifyToast("Auto Fishing", string.format("berhasil rotate %d/%d", ConfigData.DualMapPoolIndex, #poolAngles), "success")
                        forceFarmTP = false
                    end
                    
                    local sisaRot = rotateInterval - ConfigData.DualMapSubTimer
                    if UIStatus_Fishing then
                        UIStatus_Fishing.Text = string.format("MAP 1 (POOL %d): %s", ConfigData.DualMapPoolIndex, formatSecondsToText(sisaRot))
                        UIStatus_Fishing.TextColor3 = Color3.fromRGB(50, 255, 100)
                    end

                elseif ConfigData.SelectedFarmingMode == "Map 2 (Canyon)" then
                    ConfigData.FarmMapCurrent = "Canyon"
                    
                    if not isEventActive and forceFarmTP then
                        hrp.CFrame = map2CFrame
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        NotifyToast("Auto Fishing", "berhasil TP ke Canyon", "success")
                        forceFarmTP = false
                    end

                    if UIStatus_Fishing then
                        UIStatus_Fishing.Text = "MAP 2 (CANYON): ACTIVE"
                        UIStatus_Fishing.TextColor3 = Color3.fromRGB(50, 255, 100)
                    end

                elseif ConfigData.SelectedFarmingMode == "Dual Map (Canyon, Throne)" then
                    ConfigData.DualMapTimer = ConfigData.DualMapTimer + 1
                    if ConfigData.DualMapTimer >= dualMapInterval then
                        ConfigData.DualMapTimer = 0
                        if ConfigData.FarmMapCurrent == "Canyon" then
                            ConfigData.FarmMapCurrent = "Throne"
                            ConfigData.DualMapPoolIndex = 1
                        else
                            ConfigData.FarmMapCurrent = "Canyon"
                        end
                        SaveConfig()
                        forceFarmTP = true
                    end
                    
                    if ConfigData.FarmMapCurrent == "Throne" then
                        ConfigData.DualMapSubTimer = ConfigData.DualMapSubTimer + 1
                        if ConfigData.DualMapSubTimer >= rotateInterval then
                            ConfigData.DualMapSubTimer = 0
                            ConfigData.DualMapPoolIndex = (ConfigData.DualMapPoolIndex % #poolAngles) + 1
                            SaveConfig()
                            forceFarmTP = true
                        end
                    end
                    
                    if not isEventActive and forceFarmTP then
                        if ConfigData.FarmMapCurrent == "Canyon" then
                            hrp.CFrame = map2CFrame
                            NotifyToast("Auto Fishing", "berhasil TP ke Canyon", "success")
                        else
                            local currentAngle = poolAngles[ConfigData.DualMapPoolIndex] or poolAngles[1]
                            hrp.CFrame = CFrame.new(standPositionRot) * CFrame.Angles(0, math.rad(currentAngle), 0)
                            NotifyToast("Auto Fishing", string.format("berhasil rotate %d/%d", ConfigData.DualMapPoolIndex, #poolAngles), "success")
                        end
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        forceFarmTP = false
                    end
                    
                    local sisaDual = dualMapInterval - ConfigData.DualMapTimer
                    if UIStatus_Fishing then
                        if ConfigData.FarmMapCurrent == "Canyon" then
                            UIStatus_Fishing.Text = string.format("DUAL MAP (CANYON): SWAP IN %s", formatSecondsToText(sisaDual))
                        else
                            local sisaRot = rotateInterval - ConfigData.DualMapSubTimer
                            UIStatus_Fishing.Text = string.format("DUAL MAP (THRONE P%d): %s | SWAP: %s", ConfigData.DualMapPoolIndex, formatSecondsToText(sisaRot), formatSecondsToText(sisaDual))
                        end
                        UIStatus_Fishing.TextColor3 = Color3.fromRGB(50, 255, 100)
                    end

                elseif ConfigData.SelectedFarmingMode == "Triple Map (Canyon, Throne, Invader's)" then
                    ConfigData.DualMapTimer = ConfigData.DualMapTimer + 1
                    if ConfigData.DualMapTimer >= dualMapInterval then
                        ConfigData.DualMapTimer = 0
                        if ConfigData.FarmMapCurrent == "Canyon" then
                            ConfigData.FarmMapCurrent = "Throne"
                            ConfigData.DualMapPoolIndex = 1
                        elseif ConfigData.FarmMapCurrent == "Throne" then
                            ConfigData.FarmMapCurrent = "Invader"
                        else
                            ConfigData.FarmMapCurrent = "Canyon"
                        end
                        SaveConfig()
                        forceFarmTP = true
                    end
                    
                    if ConfigData.FarmMapCurrent == "Throne" then
                        ConfigData.DualMapSubTimer = ConfigData.DualMapSubTimer + 1
                        if ConfigData.DualMapSubTimer >= rotateInterval then
                            ConfigData.DualMapSubTimer = 0
                            ConfigData.DualMapPoolIndex = (ConfigData.DualMapPoolIndex % #poolAngles) + 1
                            SaveConfig()
                            forceFarmTP = true
                        end
                    end
                    
                    if not isEventActive and forceFarmTP then
                        if ConfigData.FarmMapCurrent == "Canyon" then
                            hrp.CFrame = map2CFrame
                            NotifyToast("Auto Fishing", "berhasil TP ke Canyon", "success")
                        elseif ConfigData.FarmMapCurrent == "Invader" then
                            hrp.CFrame = invaderCFrame
                            NotifyToast("Auto Fishing", "berhasil TP ke Invader's", "success")
                        else
                            local currentAngle = poolAngles[ConfigData.DualMapPoolIndex] or poolAngles[1]
                            hrp.CFrame = CFrame.new(standPositionRot) * CFrame.Angles(0, math.rad(currentAngle), 0)
                            NotifyToast("Auto Fishing", string.format("berhasil rotate %d/%d", ConfigData.DualMapPoolIndex, #poolAngles), "success")
                        end
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        forceFarmTP = false
                    end
                    
                    local sisaDual = dualMapInterval - ConfigData.DualMapTimer
                    if UIStatus_Fishing then
                        if ConfigData.FarmMapCurrent == "Canyon" then
                            UIStatus_Fishing.Text = string.format("TRIPLE MAP (CANYON): SWAP IN %s", formatSecondsToText(sisaDual))
                        elseif ConfigData.FarmMapCurrent == "Invader" then
                            UIStatus_Fishing.Text = string.format("TRIPLE MAP (INVADER): SWAP IN %s", formatSecondsToText(sisaDual))
                        else
                            local sisaRot = rotateInterval - ConfigData.DualMapSubTimer
                            UIStatus_Fishing.Text = string.format("TRIPLE MAP (THRONE P%d): %s | SWAP: %s", ConfigData.DualMapPoolIndex, formatSecondsToText(sisaRot), formatSecondsToText(sisaDual))
                        end
                        UIStatus_Fishing.TextColor3 = Color3.fromRGB(50, 255, 100)
                    end
                end
            end
        end
    end
end)
