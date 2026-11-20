local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local StealSystem = {}
local BaseManager
local Economy
local WaveAlert
local activeByPlayer = {}
local activeByBrainrot = {}

local function isPlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players
end

local function validAttempt(stealer, owner, brainrotId, expectedRecord, expectedCharacter)
	if not isPlayer(stealer) or not isPlayer(owner) or stealer == owner then
		return nil
	end
	if not BaseManager.getFreeSlot(stealer) then
		return nil
	end
	local record = BaseManager.getBrainrot(owner, brainrotId)
	if not record or (expectedRecord and record ~= expectedRecord) then
		return nil
	end
	local model = record.model
	if not model or not model.Parent or not model.PrimaryPart or not model.PrimaryPart.Parent then
		return nil
	end
	local ownerValue = model:FindFirstChild("OwnerId")
	if not ownerValue or not ownerValue:IsA("IntValue") or ownerValue.Value ~= owner.UserId then
		return nil
	end
	local character = stealer.Character
	if expectedCharacter and character ~= expectedCharacter then
		return nil
	end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	if (root.Position - model.PrimaryPart.Position).Magnitude > 40 then
		return nil
	end
	return record
end

local function clearAttempt(attempt)
	if activeByPlayer[attempt.stealer] == attempt then
		activeByPlayer[attempt.stealer] = nil
	end
	if activeByBrainrot[attempt.id] == attempt then
		activeByBrainrot[attempt.id] = nil
	end
end

function StealSystem.init(baseManager, economy, remotes)
	BaseManager = baseManager
	Economy = economy
	WaveAlert = remotes and remotes:FindFirstChild("WaveAlert")
end

function StealSystem.trySteal(stealer, owner, brainrotId)
	if not BaseManager or not Economy or not stealer or type(brainrotId) ~= "string" then
		return false
	end
	if activeByPlayer[stealer] or activeByBrainrot[brainrotId] then
		return false
	end
	local record = validAttempt(stealer, owner, brainrotId)
	if not record then
		return false
	end
	local attempt = { stealer = stealer, owner = owner, id = brainrotId }
	local character = stealer.Character
	activeByPlayer[stealer] = attempt
	activeByBrainrot[brainrotId] = attempt
	local success, result = pcall(function()
		local elapsed = 0
		while elapsed < Config.STEAL_CHANNEL_TIME do
			elapsed += task.wait(math.min(0.1, Config.STEAL_CHANNEL_TIME - elapsed))
			if activeByPlayer[stealer] ~= attempt or activeByBrainrot[brainrotId] ~= attempt then
				return false
			end
			if not validAttempt(stealer, owner, brainrotId, record, character) then
				return false
			end
		end
		if not validAttempt(stealer, owner, brainrotId, record, character) then
			return false
		end
		local removed = BaseManager.removeBrainrot(owner, brainrotId, true)
		if removed ~= record then
			return false
		end
		if not BaseManager.placeBrainrot(stealer, record.model, record.definition, record.mutation, record.income) then
			if not BaseManager.placeBrainrot(owner, record.model, record.definition, record.mutation, record.income) then
				if record.model then
					record.model:Destroy()
				end
			end
			return false
		end
		Economy.updateState(stealer)
		Economy.updateState(owner)
		if WaveAlert and WaveAlert.Parent then
			WaveAlert:FireClient(stealer, "Kamu mencuri " .. record.definition.Name .. "!")
			WaveAlert:FireClient(owner, record.definition.Name .. " dicuri!")
		end
		return true
	end)
	clearAttempt(attempt)
	if not success then
		warn("Brainrot Bay steal handler: " .. tostring(result))
		return false
	end
	return result
end

function StealSystem.removePlayer(player)
	if not player then
		return
	end
	local cancelled = {}
	for _, attempt in pairs(activeByBrainrot) do
		if attempt.stealer == player or attempt.owner == player then
			table.insert(cancelled, attempt)
		end
	end
	for _, attempt in ipairs(cancelled) do
		clearAttempt(attempt)
	end
end

return StealSystem
