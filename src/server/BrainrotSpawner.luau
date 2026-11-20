local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BrainrotSpawner = {}
local active = {}
local BaseManager
local Economy
local BrainrotData
local started = false

local function makePart(model, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function addValue(model, className, name, value)
	local object = Instance.new(className)
	object.Name = name
	object.Value = value
	object.Parent = model
end

local function removeActive(record)
	for index, current in ipairs(active) do
		if current == record then
			table.remove(active, index)
			break
		end
	end
	record.onConveyor = false
	if record.connection then
		record.connection:Disconnect()
		record.connection = nil
	end
end

local function inPurchaseRange(player, body)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root and root:IsA("BasePart") and humanoid and humanoid.Health > 0
		and (root.Position - body.Position).Magnitude <= 32
end

local function spawnBrainrot()
	local definition, mutation, mutationMultiplier = BrainrotData.roll()
	if type(definition) ~= "table" or type(mutation) ~= "string" or type(mutationMultiplier) ~= "number" then
		return
	end
	local scale = definition.Scale
	if type(scale) ~= "number" or scale <= 0 or scale ~= scale or scale == math.huge then
		return
	end
	if type(definition.Name) ~= "string" or typeof(definition.Color) ~= "Color3" then
		return
	end
	local cost = definition.Cost
	local income = type(definition.Income) == "number" and definition.Income * mutationMultiplier or nil
	if type(cost) ~= "number" or cost < 0 or cost ~= cost or cost == math.huge then
		return
	end
	if not income or income < 0 or income ~= income or income == math.huge then
		return
	end
	cost = math.ceil(cost)
	local model = Instance.new("Model")
	model.Name = definition.Name
	local start = Config.CONVEYOR_START
	local bodyHeight = 3 * scale
	local body = makePart(model, "Body", Vector3.new(2, 3, 1.5) * scale,
		start + Vector3.new(0, bodyHeight / 2, 0), definition.Color)
	local headPosition = start + Vector3.new(0, bodyHeight + 0.8 * scale, 0)
	makePart(model, "Head", Vector3.new(1.8, 1.6, 1.6) * scale, headPosition, definition.Color)
	for _, side in ipairs({ -1, 1 }) do
		makePart(model, side < 0 and "LeftEye" or "RightEye", Vector3.new(0.25, 0.3, 0.12) * scale,
			headPosition + Vector3.new(side * 0.4, 0.1, -0.83) * scale, Color3.new(0, 0, 0))
	end
	local platformColor = Color3.fromRGB(65, 65, 75)
	if mutation == "Gold" then
		platformColor = Color3.fromRGB(255, 200, 40)
	elseif mutation == "Diamond" then
		platformColor = Color3.fromRGB(100, 230, 255)
	end
	makePart(model, "Platform", Vector3.new(3, 0.4, 3) * scale,
		start - Vector3.new(0, 0.2 * scale, 0), platformColor)
	model.PrimaryPart = body
	addValue(model, "StringValue", "BrainrotId", HttpService:GenerateGUID(false))
	addValue(model, "StringValue", "DefinitionName", definition.Name)
	addValue(model, "StringValue", "Mutation", mutation)
	addValue(model, "NumberValue", "Income", income)
	addValue(model, "NumberValue", "Cost", cost)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 32
	detector.Parent = body
	model.Parent = Workspace
	local record = {
		model = model,
		definition = definition,
		mutation = mutation,
		income = income,
		cost = cost,
		onConveyor = true,
		purchasing = false,
	}
	table.insert(active, record)
	record.connection = detector.MouseClick:Connect(function(player)
		local success, message = pcall(function()
			if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
				return
			end
			if not record.onConveyor or record.purchasing or not model.Parent or not body.Parent then
				return
			end
			if not BaseManager.getFreeSlot(player) or Economy.getMoney(player) < cost or not inPurchaseRange(player, body) then
				return
			end
			record.purchasing = true
			if not Economy.addMoney(player, -cost) then
				record.purchasing = false
				return
			end
			removeActive(record)
			if not BaseManager.placeBrainrot(player, model, definition, mutation, income) then
				Economy.addMoney(player, cost)
				model:Destroy()
				Economy.updateState(player)
			end
		end)
		if not success then
			warn("Brainrot Bay purchase handler: " .. tostring(message))
		end
	end)
end

function BrainrotSpawner.init(baseManager, economy, brainrotData)
	BaseManager = baseManager
	Economy = economy
	BrainrotData = brainrotData
end

function BrainrotSpawner.start()
	if started or not BaseManager or not Economy or not BrainrotData then
		return
	end
	started = true
	RunService.Heartbeat:Connect(function(deltaTime)
		for index = #active, 1, -1 do
			local record = active[index]
			local model = record.model
			if not model.Parent or not model.PrimaryPart or not model.PrimaryPart.Parent then
				removeActive(record)
			else
				local pivot = model:GetPivot()
				local distance = math.min(Config.CONVEYOR_SPEED * deltaTime, math.max(0, Config.CONVEYOR_END.X - pivot.Position.X))
				if pivot.Position.X + distance >= Config.CONVEYOR_END.X then
					removeActive(record)
					model:Destroy()
				else
					model:PivotTo(pivot + Vector3.new(distance, 0, 0))
				end
			end
		end
	end)
	task.spawn(function()
		while started do
			task.wait(Config.SPAWN_INTERVAL)
			if #active < Config.MAX_CONVEYOR then
				spawnBrainrot()
			end
		end
	end)
end

return BrainrotSpawner
