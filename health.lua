------------------------------------------------------------
--  Stand-alone Health Bar • bottom-right, split colors    --
------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Position + size (tweak these)
local PAD_X  = 30     -- px from right edge
local PAD_Y  = 120    -- px from bottom edge
local BAR_W  = 22     -- bar width in px
local BAR_H  = 150    -- bar height in px

local player = Players.LocalPlayer

-- Build an isolated UI so layouts can't fight it
local function buildUI()
    local pg = player:WaitForChild("PlayerGui")

    -- Replace any previous instance
    local old = pg:FindFirstChild("CustomHealthUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "CustomHealthUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.AnchorPoint = Vector2.new(1, 1)                        -- bottom-right
    holder.Position    = UDim2.new(1, -PAD_X, 1, -PAD_Y)
    holder.Size        = UDim2.new(0, BAR_W, 0, BAR_H)
    holder.BackgroundTransparency = 1
    holder.Parent = sg

    -- Background (dark red) + border
    local bg = Instance.new("Frame")
    bg.Name = "BarBG"
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(45, 10, 10)
    bg.BorderSizePixel = 0
    bg.Parent = holder

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Transparency = 0.2

    -- Red = missing HP (grows down from top)
    local red = Instance.new("Frame")
    red.Name = "MissingHealthFill"
    red.AnchorPoint = Vector2.new(0, 0)
    red.Position    = UDim2.fromScale(0, 0)
    red.Size        = UDim2.fromScale(1, 0)        -- filled by (1 - pct)
    red.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
    red.BorderSizePixel = 0
    red.Parent = bg
    Instance.new("UICorner", red).CornerRadius = UDim.new(0, 6)

    -- Green = current HP (grows up from bottom)
    local green = Instance.new("Frame")
    green.Name = "CurrentHealthFill"
    green.AnchorPoint = Vector2.new(0, 1)
    green.Position    = UDim2.fromScale(0, 1)
    green.Size        = UDim2.fromScale(1, 1)      -- filled by pct
    green.BackgroundColor3 = Color3.fromRGB(60, 210, 95)
    green.BorderSizePixel = 0
    green.Parent = bg
    Instance.new("UICorner", green).CornerRadius = UDim.new(0, 6)

    return green, red
end

local function wire(char)
    local hum = char:WaitForChild("Humanoid")
    local green, red = buildUI()
    if not (green and red) then return end

    local function sync()
        local max = math.max(1, hum.MaxHealth)
        local hp  = math.clamp(hum.Health, 0, max)
        local pct = hp / max
        -- clamp tiny float fuzz at full
        if max - hp <= 0.001 * max then pct = 1 end

        green.Size = UDim2.new(1, 0, pct,     0)   -- % health
        red.Size   = UDim2.new(1, 0, 1 - pct, 0)   -- % missing
    end

    sync()
    hum.HealthChanged:Connect(sync)
    hum:GetPropertyChangedSignal("MaxHealth"):Connect(sync)
    RunService.RenderStepped:Connect(sync)
end

player.CharacterAdded:Connect(wire)
if player.Character then wire(player.Character) end
