--// Created By CDHW
--// 2026-08-23 15:20 CDT
--// https://www.roblox.com/games/13379208636/Attack-on-Titan-Revolution

local player = game.Players.LocalPlayer
local titans = game.Workspace:WaitForChild("Titans")

local POST
local GET

for number, remote in game.ReplicatedStorage:GetDescendants() do
    if remote.Name == "POST" and remote:IsA("RemoteEvent") then
        POST = remote
    elseif remote.Name == "GET" and remote:IsA("RemoteFunction") then
        GET = remote
    end

    if POST and GET then
        break
    end
end

local function getNape(titan)
    local hitboxes = titan:FindFirstChild("Hitboxes")

    if hitboxes then
        local hit = hitboxes:FindFirstChild("Hit")

        if hit then
            local nape = hit:FindFirstChild("Nape")

            if nape then
                return nape
            end
        end
    end

    return titan:FindFirstChild("Nape", true)
end

local function getTarget()
    if not player.Character then
        return
    end

    local root = player.Character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local target
    local nape
    local distance = math.huge

    for number, titan in titans:GetChildren() do
        if titan:IsA("Model") then
            local hum = titan:FindFirstChild("Humanoid")
            local neck = getNape(titan)

            if hum and hum.Health > 0 and neck and neck:IsA("BasePart") then
                local mag = (root.Position - neck.Position).Magnitude

                if mag < distance then
                    distance = mag
                    target = titan
                    nape = neck
                end
            end
        end
    end

    return target, nape
end

local function needReload()
    if not player.Character then
        return false
    end

    local rig = game.Workspace:FindFirstChild("Rig_" .. player.Character.Name, true)

    if not rig then
        rig = player.Character
    end

    local found = false

    for number, blade in rig:GetDescendants() do
        if string.sub(blade.Name, 1, 6) == "Blade_" then
            found = true

            if blade:GetAttribute("Broken") == true then
                return true
            end
        end
    end

    if found == false then
        return true
    end

    return false
end

local function refill()
    if not GET or not player.Character then
        return
    end

    local root = player.Character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local station
    local distance = math.huge

    for number, part in game.Workspace:GetDescendants() do
        if part.Name == "Refill" and part:IsA("BasePart") then
            local mag = (root.Position - part.Position).Magnitude

            if mag < distance then
                distance = mag
                station = part
            end
        end
    end

    if not station or not POST then
        GET:InvokeServer("Blades", "Reload")
        task.wait(0.1)
        return
    end

    local old = root.CFrame

    root.CFrame = station.CFrame * CFrame.new(0, 5, 0)

    task.wait(0.2)

    POST:FireServer("Attacks", "Reload", station)

    task.wait(2)

    GET:InvokeServer("Blades", "Reload")

    task.wait(0.1)

    if player.Character then
        root = player.Character:FindFirstChild("HumanoidRootPart")

        if root then
            root.CFrame = old
        end
    end
end

while true do
    if not player.Character then
        task.wait(1)
        continue
    end

    local root = player.Character:FindFirstChild("HumanoidRootPart")

    if not root then
        task.wait(1)
        continue
    end

    if needReload() == true then
        refill()
        task.wait(0.2)
    end

    local titan, nape = getTarget()

    if not titan or not nape then
        task.wait(0.5)
        continue
    end

    local hum = titan:FindFirstChild("Humanoid")

    while hum and hum.Health > 0 do
        if not player.Character then
            break
        end

        root = player.Character:FindFirstChild("HumanoidRootPart")

        if not root then
            break
        end

        if not nape or not nape.Parent then
            nape = getNape(titan)
        end

        if not nape then
            break
        end

        if needReload() == true then
            refill()

            if player.Character then
                root = player.Character:FindFirstChild("HumanoidRootPart")
            end

            if not root then
                break
            end
        end

        local tween = game.TweenService:Create(
            root,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad),
            {CFrame = nape.CFrame * CFrame.new(0, 0, 5)}
        )

        tween:Play()
        tween.Completed:Wait()

        if POST then
            POST:FireServer("Attacks", "Slash", true)

            task.wait(0.05)

            POST:FireServer("Hitboxes", "Register", nape, 50, 0)
        end

        task.wait(0.15)

        hum = titan:FindFirstChild("Humanoid")
    end

    task.wait()
end
