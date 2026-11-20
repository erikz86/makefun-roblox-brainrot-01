local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BaseManager = {}
local baseIndices = {}
local baseOwners = {}
local owned = {}
local clickConnections = {}
local Economy
local StealSystem

local function isPlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players
end

local function updateState(player)
	if Economy then
		Economy.updateState(player)
	end
end

local function disconnectClick(model)
	local connection = clickConnections[model]
	if connection then
		connection:Disconnect()
		clickConnections[model] = nil
	end
end

function BaseManager.init(economy, stealSystem)
	Economy = economy
	StealSystem = stealSystem
end

function BaseManager.assignBase(player)
	if not isPlayer(player) then
		return nil
	end
	if baseIndices[player] then
		return baseIndices[player]
	end
	for index in ipairs(Config.BASE_POSITIONS) do
		if not baseOwners[index] then
			baseOwners[index] = player
			baseIndices[player] = index
			owned[player] = {}
			player:SetAttribute("BaseIndex", index)
			return index
		end
	end
	return nil
end

function BaseManager.getOwned(player)
	if not player then
		return {}
	end
	return owned[player] or {}
end

function BaseManager.getBrainrot(player, brainrotId)
	if not player or type(brainrotId) ~= "string" then
		return nil
	end
	for _, record in ipairs(BaseManager.getOwned(player)) do
		if record.id == brainrotId then
			return record
		end
	end
	return nil
end

function BaseManager.getFreeSlot(player)
	if not isPlayer(player) or not baseIndices[player] then
		return nil
	end
	local taken = {}
	for _, record in ipairs(BaseManager.getOwned(player)) do
		taken[record.slot] = true
	end
	for slot = 1, math.min(Config.SLOTS_PER_BASE, #Config.SLOT_OFFSETS) do
		if not taken[slot] then
			return slot
		end
	end
	return nil
end

function BaseManager.getBasePosition(player)
	local index = player and baseIndices[player]
	return index and Config.BASE_POSITIONS[index] or nil
end

function BaseManager.getOccupiedBases()
	local bases = {}
	for index, player in pairs(baseOwners) do
		if isPlayer(player) and #BaseManager.getOwned(player) > 0 then
			table.insert(bases, { player = player, position = Config.BASE_POSITIONS[index] })
		end
	end
	return bases
end

function BaseManager.placeBrainrot(player, model, definition, mutation, income)
	if not isPlayer(player) or typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false
	end
	if not model.Parent or type(definition) ~= "table" or type(mutation) ~= "string" then
		return false
	end
	if type(income) ~= "number" or income ~= income or income < 0 or income == math.huge then
		return false
	end
	local slot = BaseManager.getFreeSlot(player)
	local basePosition = BaseManager.getBasePosition(player)
	local body = model:FindFirstChild("Body")
	local idValue = model:FindFirstChild("BrainrotId")
	if not slot or not basePosition or not body or not body:IsA("BasePart") then
		return false
	end
	if not idValue or not idValue:IsA("StringValue") or idValue.Value == "" then
		return false
	end
	for _, records in pairs(owned) do
		for _, record in ipairs(records) do
			if record.model == model or record.id == idValue.Value then
				return false
			end
		end
	end
	local ownerValue = model:FindFirstChild("OwnerId")
	if ownerValue and not ownerValue:IsA("IntValue") then
		return false
	end
	model.PrimaryPart = body
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model:PivotTo(CFrame.new(basePosition + Config.SLOT_OFFSETS[slot] + Vector3.new(0, body.Size.Y / 2, 0)))
	if not ownerValue then
		ownerValue = Instance.new("IntValue")
		ownerValue.Name = "OwnerId"
		ownerValue.Parent = model
	end
	ownerValue.Value = player.UserId
	disconnectClick(model)
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("ClickDetector") then
			child:Destroy()
		end
	end
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 32
	detector.Parent = body
	local record = {
		id = idValue.Value,
		definition = definition,
		mutation = mutation,
		income = income,
		slot = slot,
		model = model,
	}
	table.insert(owned[player], record)
	clickConnections[model] = detector.MouseClick:Connect(function(clicker)
		local success, message = pcall(function()
			if not isPlayer(clicker) or not model.Parent or not ownerValue.Parent then
				return
			end
			local owner = Players:GetPlayerByUserId(ownerValue.Value)
			if not owner or BaseManager.getBrainrot(owner, record.id) ~= record then
				return
			end
			if clicker == owner then
				if Economy then
					Economy.sellBrainrot(owner, record.id)
				end
			elseif StealSystem then
				StealSystem.trySteal(clicker, owner, record.id)
			end
		end)
		if not success then
			warn("Brainrot Bay base click: " .. tostring(message))
		end
	end)
	updateState(player)
	return true
end

function BaseManager.removeBrainrot(player, brainrotId, preserveModel)
	if not player or type(brainrotId) ~= "string" then
		return nil
	end
	local records = owned[player]
	if not records then
		return nil
	end
	for index, record in ipairs(records) do
		if record.id == brainrotId then
			table.remove(records, index)
			local model = record.model
			if model then
				disconnectClick(model)
				if preserveModel then
					local ownerValue = model:FindFirstChild("OwnerId")
					if ownerValue and ownerValue:IsA("IntValue") then
						ownerValue.Value = 0
					end
				else
					model:Destroy()
				end
			end
			updateState(player)
			return record
		end
	end
	return nil
end

function BaseManager.releaseBase(player)
	if not player then
		return
	end
	for _, record in ipairs(BaseManager.getOwned(player)) do
		if record.model then
			disconnectClick(record.model)
			record.model:Destroy()
		end
	end
	owned[player] = nil
	local index = baseIndices[player]
	if index then
		baseOwners[index] = nil
	end
	baseIndices[player] = nil
	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute("BaseIndex", nil)
	end
end

return BaseManager
