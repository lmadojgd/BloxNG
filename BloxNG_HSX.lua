if game.PlaceId ~= 83784149502814 then
	warn("[HollyScriptX] Wrong game brody")
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Settings = {
	AutoFarm    = false,
	FlySpeed    = 200,
	AutoCrash   = false,
	SpamRemotes = false,
}

local flying = false
local flyBody = nil

local function getHRP()
	local c = LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function notify(title, text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title, Text = text, Duration = 4
		})
	end)
end

local function tween(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- =============================================
-- FLY
-- =============================================
local function startFly()
	local hrp = getHRP()
	if not hrp or flying then return end
	flying = true

	local bg = Instance.new("BodyGyro", hrp)
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = 1e6
	bg.Name = "HSXGyro"

	local bv = Instance.new("BodyVelocity", hrp)
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	bv.Name = "HSXVelocity"

	flyBody = {bg = bg, bv = bv}

	local cam = workspace.CurrentCamera
	RunService:BindToRenderStep("HSXFly", Enum.RenderPriority.Camera.Value + 1, function()
		if not flying then
			RunService:UnbindFromRenderStep("HSXFly")
			return
		end
		local hrp2 = getHRP()
		if not hrp2 then return end

		local cf = cam.CFrame
		local moveVec = Vector3.zero
		local spd = Settings.FlySpeed

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec = moveVec - Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then spd = spd * 2 end

		if moveVec.Magnitude > 0 then
			bv.Velocity = moveVec.Unit * spd
		else
			bv.Velocity = Vector3.zero
		end

		bg.CFrame = cf
	end)
end

local function stopFly()
	flying = false
	local hrp = getHRP()
	if hrp then
		local gyro = hrp:FindFirstChild("HSXGyro")
		local vel = hrp:FindFirstChild("HSXVelocity")
		if gyro then gyro:Destroy() end
		if vel then vel:Destroy() end
	end
	flyBody = nil
	RunService:UnbindFromRenderStep("HSXFly")
end

-- =============================================
-- REMOTE FINDER + MONEY FARM
-- =============================================
local foundRemotes = {}

local function findMoneyRemotes()
	foundRemotes = {}
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			local name = obj.Name:lower()
			if name:find("money") or name:find("cash") or name:find("coin")
				or name:find("currency") or name:find("earn") or name:find("reward")
				or name:find("credit") or name:find("score") or name:find("point")
				or name:find("crash") or name:find("damage") or name:find("hit")
				or name:find("car") or name:find("vehicle") or name:find("speed") then
				table.insert(foundRemotes, obj)
			end
		end
	end
	return foundRemotes
end

local function spamRemotes()
	local remotes = findMoneyRemotes()
	if #remotes == 0 then
		notify("HollyScriptX", "No money remotes found!")
		return
	end
	for _, remote in ipairs(remotes) do
		pcall(function()
			if remote:IsA("RemoteEvent") then
				remote:FireServer()
				remote:FireServer(999999)
				remote:FireServer(LocalPlayer)
				remote:FireServer(true)
			elseif remote:IsA("RemoteFunction") then
				remote:InvokeServer()
				remote:InvokeServer(999999)
			end
		end)
	end
end

-- =============================================
-- AUTO CRASH FARM (high speed crash = money)
-- =============================================
local autoCrashConn = nil

local function startAutoCrash()
	if autoCrashConn then return end

	local function doCrash()
		local hrp = getHRP()
		if not hrp then return end

		-- find nearest car/vehicle
		local bestCar = nil
		local bestDist = math.huge
		for _, obj in ipairs(workspace:GetDescendants()) do
			if (obj.Name:lower():find("car") or obj.Name:lower():find("vehicle") or obj.Name:lower():find("chassis"))
				and obj:IsA("Model") then
				local root = obj:FindFirstChildWhichIsA("BasePart")
				if root then
					local dist = (hrp.Position - root.Position).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestCar = root
					end
				end
			end
		end

		if bestCar then
			TweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {
				CFrame = bestCar.CFrame * CFrame.new(0, 2, -5)
			}):Play()
			task.wait(0.3)
			bestCar.AssemblyLinearVelocity = hrp.CFrame.LookVector * Settings.FlySpeed
		end

		spamRemotes()
	end

	autoCrashConn = RunService.Heartbeat:Connect(function()
		if Settings.AutoCrash then
			task.spawn(doCrash)
			task.wait(0.5)
		end
	end)
end

local function stopAutoCrash()
	if autoCrashConn then
		autoCrashConn:Disconnect()
		autoCrashConn = nil
	end
end

-- =============================================
-- REMOTE LIST (debug)
-- =============================================
local function listRemotes()
	local remotes = findMoneyRemotes()
	if #remotes == 0 then
		notify("HollyScriptX", "No remotes found in ReplicatedStorage")
		return
	end
	for _, r in ipairs(remotes) do
		print("[HSX Remote]", r:GetFullName(), "-", r.ClassName)
	end
	notify("HollyScriptX", "Found " .. #remotes .. " remotes — check output")
end

-- =============================================
-- NOUSIGI STYLE UI
-- =============================================
local sg = Instance.new("ScreenGui")
sg.Name = "HollyScriptX_BloxNG"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 340)
main.Position = UDim2.new(0, 20, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(90, 90, 70)
mainStroke.Thickness = 1

local mainGrad = Instance.new("UIGradient", main)
mainGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,200))
}
mainGrad.Rotation = 90
mainGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.92),
	NumberSequenceKeypoint.new(1, 0.92)
}

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundTransparency = 1
topBar.Parent = main

local topStroke = Instance.new("Frame", topBar)
topStroke.Size = UDim2.new(1, 0, 0, 1)
topStroke.Position = UDim2.new(0, 0, 1, -1)
topStroke.BackgroundColor3 = Color3.fromRGB(90, 90, 70)
topStroke.BackgroundTransparency = 0.6
topStroke.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -10, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = string.format('<font color="rgb(255,206,27)">HollyScriptX</font> <font color="rgb(170,170,160)">BloxNG</font>')
titleLbl.RichText = true
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.TextColor3 = Color3.fromRGB(235, 235, 230)
titleLbl.Parent = topBar

local versionLbl = Instance.new("TextLabel")
versionLbl.Size = UDim2.new(0, 40, 1, 0)
versionLbl.Position = UDim2.new(1, -45, 0, 0)
versionLbl.BackgroundTransparency = 1
versionLbl.Text = "v1.0"
versionLbl.Font = Enum.Font.Gotham
versionLbl.TextSize = 11
versionLbl.TextColor3 = Color3.fromRGB(120, 120, 110)
versionLbl.Parent = topBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1
content.Parent = main

local list = Instance.new("UIListLayout", content)
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.HorizontalAlignment = Enum.HorizontalAlignment.Center

local pad = Instance.new("UIPadding", content)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 8)

local function makeSection(text)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 20)
	f.BackgroundTransparency = 1
	f.Parent = content

	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(255, 206, 27)
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local underline = Instance.new("Frame", f)
	underline.Size = UDim2.new(1, 0, 0, 1)
	underline.Position = UDim2.new(0, 0, 1, -1)
	underline.BackgroundColor3 = Color3.fromRGB(255, 206, 27)
	underline.BackgroundTransparency = 0.6
	underline.BorderSizePixel = 0

	return f
end

local function makeToggle(text, desc, callback)
	local state = false

	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 44)
	f.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	f.BorderSizePixel = 0
	f.Parent = content
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1, -50, 0, 20)
	lbl.Position = UDim2.new(0, 10, 0, 5)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.fromRGB(235, 235, 230)
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local descLbl = Instance.new("TextLabel", f)
	descLbl.Size = UDim2.new(1, -50, 0, 16)
	descLbl.Position = UDim2.new(0, 10, 0, 24)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = desc or ""
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextSize = 11
	descLbl.TextColor3 = Color3.fromRGB(185, 185, 185)
	descLbl.TextXAlignment = Enum.TextXAlignment.Left

	local track = Instance.new("Frame", f)
	track.Size = UDim2.new(0, 36, 0, 18)
	track.Position = UDim2.new(1, -46, 0.5, -9)
	track.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
	track.BorderSizePixel = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", track)
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new(0, 3, 0.5, -6)
	knob.BackgroundColor3 = Color3.fromRGB(120, 120, 110)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""

	btn.MouseButton1Click:Connect(function()
		state = not state
		tween(track, 0.25, { BackgroundColor3 = state and Color3.fromRGB(255, 206, 27) or Color3.fromRGB(48, 48, 56) })
		tween(knob, 0.25, {
			Position = state and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
			BackgroundColor3 = state and Color3.fromRGB(18, 18, 22) or Color3.fromRGB(120, 120, 110)
		})
		callback(state)
	end)

	return f, function() return state end
end

local function makeButton(text, desc, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 36)
	f.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	f.BorderSizePixel = 0
	f.Parent = content
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.fromRGB(255, 206, 27)
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""

	btn.MouseButton1Click:Connect(function()
		tween(f, 0.1, { BackgroundColor3 = Color3.fromRGB(48, 48, 56) })
		task.delay(0.1, function()
			tween(f, 0.1, { BackgroundColor3 = Color3.fromRGB(28, 28, 34) })
		end)
		callback()
	end)

	return f
end

local function makeSlider(text, min, max, default, callback)
	local value = default

	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 50)
	f.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	f.BorderSizePixel = 0
	f.Parent = content
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1, -50, 0, 20)
	lbl.Position = UDim2.new(0, 10, 0, 5)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.fromRGB(235, 235, 230)
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local valLbl = Instance.new("TextLabel", f)
	valLbl.Size = UDim2.new(0, 40, 0, 20)
	valLbl.Position = UDim2.new(1, -50, 0, 5)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(default)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 12
	valLbl.TextColor3 = Color3.fromRGB(255, 206, 27)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("Frame", f)
	track.Size = UDim2.new(1, -20, 0, 4)
	track.Position = UDim2.new(0, 10, 0, 34)
	track.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
	track.BorderSizePixel = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", track)
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 206, 27)
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local draggingSlider = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
		end
	end)
	track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local trackPos = track.AbsolutePosition.X
			local trackSize = track.AbsoluteSize.X
			local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
			value = math.floor(min + (max - min) * rel)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			valLbl.Text = tostring(value)
			callback(value)
		end
	end)

	return f
end

-- =============================================
-- BUILD UI
-- =============================================
makeSection("MONEY FARM")
makeToggle("Spam Remotes", "fire money remotes fast", function(v)
	Settings.SpamRemotes = v
	if v then
		task.spawn(function()
			while Settings.SpamRemotes do
				spamRemotes()
				task.wait(0.3)
			end
		end)
	end
end)

makeToggle("Auto Crash Farm", "crash cars at high speed", function(v)
	Settings.AutoCrash = v
	if v then startAutoCrash() else stopAutoCrash() end
end)

makeButton("List Remotes (Console)", nil, function()
	listRemotes()
end)

makeSection("FLY")
makeToggle("Fly", "WASD + Space/Ctrl to move", function(v)
	if v then startFly() else stopFly() end
end)

makeSlider("Fly Speed", 50, 500, 200, function(v)
	Settings.FlySpeed = v
end)

makeSection("PLAYER")
makeSlider("Walk Speed", 16, 500, 16, function(v)
	local hum = getHum()
	if hum then hum.WalkSpeed = v end
end)

makeButton("Rejoin", nil, function()
	pcall(function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
	end)
end)

-- =============================================
-- DRAG
-- =============================================
local dragging, dragInput, dragStart, startPos
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
topBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- =============================================
-- KEYBIND (RightShift toggle)
-- =============================================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
	end
end)

notify("HollyScriptX", "BloxNG loaded! RightShift to toggle")
