local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Economy = {}
local multipliers = {}
local rebirthCounts = {}
local incomeRemainders = {}
local BaseManager
local StateUpdate
local started = false

local function isPlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players
end

local function moneyValue(player)
	if not isPlayer(player) then
		return nil
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")
	if money and money:IsA("IntValue") then
		return money
	end
	return nil
end

function Economy.init(baseManager, remotes)
	BaseManager = baseManager
	StateUpdate = remotes and remotes:FindFirstChild("StateUpdate")
end

function Economy.addPlayer(player)
	if not isPlayer(player) then
		return
	end
	multipliers[player] = multipliers[player] or 1
	rebirthCounts[player] = rebirthCounts[player] or 0
	incomeRemainders[player] = incomeRemainders[player] or 0
end

function Economy.removePlayer(player)
	if not player then
		return
	end
	multipliers[player] = nil
	rebirthCounts[player] = nil
	incomeRemainders[player] = nil
end

function Economy.getMoney(player)
	local money = moneyValue(player)
	return money and money.Value or 0
end

function Economy.addMoney(player, amount)
	local money = moneyValue(player)
	if not money or type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then
		return false
	end
	local nextValue = money.Value + math.floor(amount)
	if nextValue < 0 or nextValue > 9007199254740991 then
		return false
	end
	money.Value = nextValue
	return true
end

function Economy.getState(player)
	local totalIncome = 0
	local count = 0
	if player and BaseManager then
		for _, record in ipairs(BaseManager.getOwned(player)) do
			local model = record.model
			if model and model.Parent then
				totalIncome += record.income
				count += 1
			end
		end
	end
	local multiplier = player and multipliers[player] or 1
	return {
		Money = Economy.getMoney(player),
		IncomePerSecond = totalIncome * multiplier,
		RebirthCount = player and rebirthCounts[player] or 0,
		Multiplier = multiplier,
		BrainrotCount = count,
	}
end

function Economy.updateState(player)
	if isPlayer(player) and StateUpdate and StateUpdate.Parent then
		StateUpdate:FireClient(player, Economy.getState(player))
	end
end

function Economy.sellBrainrot(player, brainrotId)
	if not isPlayer(player) or not BaseManager or not moneyValue(player) then
		return false
	end
	local record = BaseManager.getBrainrot(player, brainrotId)
	if not record or not record.model or not record.model.Parent then
		return false
	end
	local owner = record.model:FindFirstChild("OwnerId")
	local cost = record.model:FindFirstChild("Cost")
	if not owner or not owner:IsA("IntValue") or owner.Value ~= player.UserId then
		return false
	end
	if not cost or not cost:IsA("NumberValue") or cost.Value < 0 or cost.Value ~= cost.Value or cost.Value == math.huge then
		return false
	end
	local refund = math.floor(cost.Value * Config.SELL_REFUND)
	if Economy.getMoney(player) + refund > 9007199254740991 then
		return false
	end
	if not BaseManager.removeBrainrot(player, brainrotId) then
		return false
	end
	Economy.addMoney(player, refund)
	Economy.updateState(player)
	return true
end

function Economy.rebirth(player)
	local money = moneyValue(player)
	if not money or not BaseManager or money.Value < Config.REBIRTH_COST then
		return false
	end
	local nextMultiplier = (multipliers[player] or 1) * Config.REBIRTH_MULTIPLIER
	if nextMultiplier == math.huge then
		return false
	end
	money.Value = 0
	incomeRemainders[player] = 0
	local records = BaseManager.getOwned(player)
	for index = #records, 1, -1 do
		BaseManager.removeBrainrot(player, records[index].id)
	end
	multipliers[player] = nextMultiplier
	rebirthCounts[player] = (rebirthCounts[player] or 0) + 1
	Economy.updateState(player)
	return true
end

function Economy.start()
	if started or not BaseManager then
		return
	end
	started = true
	task.spawn(function()
		while started do
			task.wait(Config.INCOME_TICK)
			for _, player in ipairs(Players:GetPlayers()) do
				if moneyValue(player) then
					local state = Economy.getState(player)
					local accrued = state.IncomePerSecond * Config.INCOME_TICK + (incomeRemainders[player] or 0)
					local payout = math.floor(accrued)
					if Economy.addMoney(player, payout) then
						incomeRemainders[player] = accrued - payout
					end
					Economy.updateState(player)
				end
			end
		end
	end)
end

return Economy
