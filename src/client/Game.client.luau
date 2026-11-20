local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
while not player do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end
player:WaitForChild("PlayerGui")

local HUD = require(script.Parent:WaitForChild("HUD"))
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
HUD.build()

local function getRemote(name)
	while true do
		local remote = ReplicatedStorage:FindFirstChild(name, true)
		if remote and remote:IsA("RemoteEvent") then
			return remote
		end
		ReplicatedStorage.DescendantAdded:Wait()
	end
end

task.spawn(function()
	getRemote("StateUpdate").OnClientEvent:Connect(HUD.update)
end)

task.spawn(function()
	getRemote("WaveAlert").OnClientEvent:Connect(HUD.showAlert)
end)

local button = HUD.rebirthButton
if button then
	local buyRebirth = getRemote("BuyRebirth")
	button.Activated:Connect(function()
		buyRebirth:FireServer()
	end)
end
