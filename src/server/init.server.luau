local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))
local WaveSystem = require(script.Parent:WaitForChild("WaveSystem"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes and not remotes:IsA("Folder") then
	remotes:Destroy()
	remotes = nil
end
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

for _, name in ipairs({ "BuyRebirth", "StateUpdate", "WaveAlert" }) do
	local remote = remotes:FindFirstChild(name)
	if remote and not remote:IsA("RemoteEvent") then
		remote:Destroy()
		remote = nil
	end
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
end

BaseManager.init(Economy, StealSystem)
Economy.init(BaseManager, remotes)
StealSystem.init(BaseManager, Economy, remotes)
BrainrotSpawner.init(BaseManager, Economy, BrainrotData)
WaveSystem.init(BaseManager, Economy, remotes)

local initialized = {}

local function addPlayer(player)
	if not player or player.Parent ~= Players or initialized[player] then
		return
	end
	initialized[player] = true
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and not leaderstats:IsA("Folder") then
		leaderstats:Destroy()
		leaderstats = nil
	end
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local money = leaderstats:FindFirstChild("Money")
	if money and not money:IsA("IntValue") then
		money:Destroy()
		money = nil
	end
	if not money then
		money = Instance.new("IntValue")
		money.Name = "Money"
		money.Parent = leaderstats
	end
	money.Value = 0
	Economy.addPlayer(player)
	BaseManager.assignBase(player)
	Economy.updateState(player)
end

remotes.BuyRebirth.OnServerEvent:Connect(function(player)
	local success, message = pcall(function()
		if player and player.Parent == Players and initialized[player] then
			Economy.rebirth(player)
		end
	end)
	if not success then
		warn("Brainrot Bay rebirth handler: " .. tostring(message))
	end
end)

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	StealSystem.removePlayer(player)
	BaseManager.releaseBase(player)
	Economy.removePlayer(player)
	initialized[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	addPlayer(player)
end

Economy.start()
BrainrotSpawner.start()
WaveSystem.start()
