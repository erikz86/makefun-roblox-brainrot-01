local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WaveSystem = {}
local BaseManager
local Economy
local WaveAlert
local active = {}
local started = false

local function destroyThief(record)
	if record.destroyed then
		return
	end
	record.destroyed = true
	if record.connection then
		record.connection:Disconnect()
		record.connection = nil
	end
	if record.model then
		record.model:Destroy()
	end
end

local function alertAll(message)
	if WaveAlert and WaveAlert.Parent then
		WaveAlert:FireAllClients(message)
	end
end

local function nearestBase(position, bases)
	local nearest
	local nearestDistance = math.huge
	for _, base in ipairs(bases) do
		local distance = (base.position - position).Magnitude
		if distance < nearestDistance then
			nearest = base
			nearestDistance = distance
		end
	end
	return nearest
end

local function attackBase(player)
	local lowest
	for _, record in ipairs(BaseManager.getOwned(player)) do
		if record.model and record.model.Parent and (not lowest or record.income < lowest.income) then
			lowest = record
		end
	end
	if lowest then
		BaseManager.removeBrainrot(player, lowest.id)
		Economy.updateState(player)
	end
end

local function spawnThief(index)
	local model = Instance.new("Model")
	model.Name = "Thief"
	local position = Config.CONVEYOR_END + Vector3.new(0, 2, (index - 1) * 4)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 3, 1.5)
	body.Position = position
	body.Color = Color3.fromRGB(35, 30, 45)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.7, 1.5, 1.5)
	head.Position = position + Vector3.new(0, 2.25, 0)
	head.Color = Color3.fromRGB(65, 55, 70)
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = false
	head.Parent = model
	model.PrimaryPart = body
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 32
	detector.Parent = body
	model.Parent = Workspace
	local record = { model = model, expiresAt = os.clock() + 60, destroyed = false }
	table.insert(active, record)
	record.connection = detector.MouseClick:Connect(function(player)
		local success, message = pcall(function()
			if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
				return
			end
			if record.destroyed or not model.Parent or not body.Parent then
				return
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
				return
			end
			if (root.Position - body.Position).Magnitude > 32 then
				return
			end
			destroyThief(record)
			alertAll("Pencuri diusir!")
		end)
		if not success then
			warn("Brainrot Bay thief click: " .. tostring(message))
		end
	end)
end

function WaveSystem.init(baseManager, economy, remotes)
	BaseManager = baseManager
	Economy = economy
	WaveAlert = remotes and remotes:FindFirstChild("WaveAlert")
end

function WaveSystem.start()
	if started or not BaseManager or not Economy then
		return
	end
	started = true
	RunService.Heartbeat:Connect(function(deltaTime)
		if #active == 0 then
			return
		end
		local bases = BaseManager.getOccupiedBases()
		local now = os.clock()
		for index = #active, 1, -1 do
			local record = active[index]
			local model = record.model
			if record.destroyed or not model.Parent or not model.PrimaryPart or not model.PrimaryPart.Parent or now >= record.expiresAt then
				destroyThief(record)
				table.remove(active, index)
			else
				local pivot = model:GetPivot()
				local target = nearestBase(pivot.Position, bases)
				if target then
					local destination = target.position + Vector3.new(0, 2, 0)
					local offset = destination - pivot.Position
					local distance = offset.Magnitude
					if distance > 0 then
						local step = math.min(distance, 10 * deltaTime)
						model:PivotTo(pivot + offset.Unit * step)
					end
					if (model:GetPivot().Position - target.position).Magnitude <= 6 then
						attackBase(target.player)
						destroyThief(record)
						table.remove(active, index)
					end
				end
			end
		end
	end)
	task.spawn(function()
		while started do
			task.wait(Config.WAVE_INTERVAL)
			alertAll("Gelombang pencuri datang! Klik pencuri untuk mengusirnya!")
			for index = 1, Config.WAVE_THIEF_COUNT do
				spawnThief(index)
			end
		end
	end)
end

return WaveSystem
