local Players = game:GetService("Players")
local HUD = {}

local gui
local money, income, count, rebirth, alert
local alertVersion = 0
local dark = Color3.fromRGB(22, 36, 43)
local white = Color3.fromRGB(255, 255, 255)
local mint = Color3.fromRGB(117, 255, 184)
local yellow = Color3.fromRGB(255, 218, 85)

local function round(object)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = object
end

local function panel(name, parent, position, size)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = dark
	frame.BackgroundTransparency = 0.16
	frame.BorderSizePixel = 0
	round(frame)
	frame.Parent = parent
	return frame
end

local function label(name, parent, value, size, tint, className)
	local object = Instance.new(className or "TextLabel")
	object.Name = name
	object.Size = UDim2.fromScale(1, 1)
	object.BackgroundTransparency = 1
	object.BorderSizePixel = 0
	object.Font = Enum.Font.SourceSansBold
	object.Text = value
	object.TextSize = size
	object.TextColor3 = tint
	object.Parent = parent
	return object
end

function HUD.build()
	if gui then
		return gui
	end
	local player = Players.LocalPlayer
	if not player then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBayGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local stats = panel("MoneyPanel", gui, UDim2.fromOffset(12, 60), UDim2.new(0.52, -18, 0, 105))
	local statsLimit = Instance.new("UISizeConstraint")
	statsLimit.MaxSize = Vector2.new(255, 105)
	statsLimit.Parent = stats
	local function stat(name, value, size, tint, y, height)
		local row = label(name, stats, value, size, tint)
		row.Position = UDim2.fromOffset(10, y)
		row.Size = UDim2.new(1, -20, 0, height)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextTruncate = Enum.TextTruncate.AtEnd
		return row
	end
	money = stat("Money", "Uang: $0", 28, white, 7, 35)
	income = stat("Income", "Pendapatan: $0/detik", 20, mint, 43, 25)
	count = stat("BrainrotCount", "Brainrot: 0", 20, white, 69, 26)

	local rebirthPanel = panel("RebirthPanel", gui, UDim2.new(1, -12, 0, 60), UDim2.new(0.48, -18, 0, 105))
	rebirthPanel.AnchorPoint = Vector2.new(1, 0)
	local rebirthLimit = Instance.new("UISizeConstraint")
	rebirthLimit.MaxSize = Vector2.new(220, 105)
	rebirthLimit.Parent = rebirthPanel
	rebirth = label("RebirthCount", rebirthPanel, "Rebirth: 0 (x1)", 20, white)
	rebirth.Position = UDim2.fromOffset(6, 7)
	rebirth.Size = UDim2.new(1, -12, 0, 33)
	rebirth.TextTruncate = Enum.TextTruncate.AtEnd
	local button = label("RebirthButton", rebirthPanel, "REBIRTH ($50.000)", 20, dark, "TextButton")
	button.Position = UDim2.fromOffset(8, 44)
	button.Size = UDim2.new(1, -16, 0, 51)
	button.BackgroundColor3 = yellow
	button.BackgroundTransparency = 0
	button.TextWrapped = true
	round(button)
	HUD.rebirthButton = button

	local hint = label("Hint", gui,
		"Klik brainrot di conveyor untuk membeli | Klik brainrot di basemu untuk menjual | Klik brainrot di base orang lain untuk mencuri",
		18, white)
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -14)
	hint.Size = UDim2.new(1, -24, 0, 0)
	hint.AutomaticSize = Enum.AutomaticSize.Y
	hint.BackgroundColor3 = dark
	hint.BackgroundTransparency = 0.16
	hint.TextWrapped = true
	local hintLimit = Instance.new("UISizeConstraint")
	hintLimit.MaxSize = Vector2.new(960, math.huge)
	hintLimit.Parent = hint
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 7)
	padding.PaddingBottom = UDim.new(0, 7)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = hint
	round(hint)

	alert = label("WaveAlert", gui, "", 22, yellow)
	alert.AnchorPoint = Vector2.new(0.5, 0)
	alert.Position = UDim2.new(0.5, 0, 0, 175)
	alert.Size = UDim2.new(1, -24, 0, 52)
	alert.BackgroundColor3 = Color3.fromRGB(116, 30, 48)
	alert.BackgroundTransparency = 0.08
	alert.TextWrapped = true
	alert.Visible = false
	local alertLimit = Instance.new("UISizeConstraint")
	alertLimit.MaxSize = Vector2.new(460, 52)
	alertLimit.Parent = alert
	round(alert)

	gui.Parent = playerGui
	return gui
end

local function displayNumber(value)
	return string.gsub(tostring(value), "%.", ",")
end

function HUD.update(state)
	if type(state) ~= "table" or not (money and income and count and rebirth) then
		return
	end
	if type(state.Money) == "number" then
		money.Text = "Uang: $" .. displayNumber(state.Money)
	end
	if type(state.IncomePerSecond) == "number" then
		income.Text = "Pendapatan: $" .. displayNumber(state.IncomePerSecond) .. "/detik"
	end
	if type(state.BrainrotCount) == "number" then
		count.Text = "Brainrot: " .. displayNumber(state.BrainrotCount)
	end
	if type(state.RebirthCount) == "number" and type(state.Multiplier) == "number" then
		rebirth.Text = "Rebirth: " .. displayNumber(state.RebirthCount) .. " (x" .. displayNumber(state.Multiplier) .. ")"
	end
end

function HUD.showAlert(message)
	if not alert or type(message) ~= "string" then
		return
	end
	alertVersion += 1
	local version = alertVersion
	alert.Text = message
	alert.Visible = true
	task.delay(4, function()
		if alert and version == alertVersion then
			alert.Visible = false
		end
	end)
end

return HUD
