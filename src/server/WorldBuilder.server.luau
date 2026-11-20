local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local world = Instance.new("Folder")
world.Name = "BrainrotBayWorld"

local function color(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function makePart(name, size, position, tint, options)
	options = options or {}
	local part = Instance.new(options.className or "Part")
	part.Name = name
	part.Size = size
	part.CFrame = options.cframe or CFrame.new(position)
	part.Color = tint
	part.Anchored = true
	part.CanCollide = options.canCollide ~= false
	part.Transparency = options.transparency or 0
	part.Material = Enum.Material.SmoothPlastic
	if options.shape then
		part.Shape = options.shape
	end
	part.Parent = world
	return part
end

local ground = makePart("Ground", Vector3.new(Config.GROUND_SIZE, 1, Config.GROUND_SIZE),
	Vector3.new(0, -0.5, 0), color(85, 166, 91))
-- Inset the rendered surface so the flush base tops do not flicker.
local groundMesh = Instance.new("BlockMesh")
groundMesh.Scale = Vector3.new(1, 0.96, 1)
groundMesh.Parent = ground

local conveyor = (Config.CONVEYOR_START + Config.CONVEYOR_END) / 2
local beltLength = Config.CONVEYOR_END.X - Config.CONVEYOR_START.X + 10
makePart("Conveyor", Vector3.new(beltLength, 1, 12), Vector3.new(conveyor.X, 0.5, conveyor.Z),
	color(53, 58, 68))
for index, offset in ipairs({ -6, 6 }) do
	makePart("ConveyorRail" .. index, Vector3.new(beltLength, 1, 1),
		Vector3.new(conveyor.X, 1.5, conveyor.Z + offset), color(98, 113, 126))
end
makePart("SpawnPad", Vector3.new(8, 1, 12),
	Vector3.new(Config.CONVEYOR_START.X - 5, 0.5, conveyor.Z), color(46, 219, 113))
makePart("DespawnPad", Vector3.new(8, 1, 12),
	Vector3.new(Config.CONVEYOR_END.X + 5, 0.5, conveyor.Z), color(241, 76, 79))

local baseColors = { color(222, 76, 78), color(65, 143, 231), color(48, 192, 119), color(255, 205, 72) }
local slotStyle = { canCollide = false, transparency = 0.6 }
for index, position in ipairs(Config.BASE_POSITIONS) do
	local baseName = "Base" .. index
	makePart(baseName, Vector3.new(Config.BASE_SIZE, 1, Config.BASE_SIZE),
		position + Vector3.new(0, -0.5, 0), baseColors[index] or baseColors[1])
	for slot = 1, Config.SLOTS_PER_BASE do
		local offset = Config.SLOT_OFFSETS[slot]
		if offset then
			makePart(baseName .. "Slot" .. slot, Vector3.new(4, 0.2, 4),
				position + offset + Vector3.new(0, 0.1, 0), color(255, 255, 255), slotStyle)
		end
	end
end

makePart("SpawnLocation", Vector3.new(6, 1, 6),
	Vector3.new(Config.SPAWN_POINT.X, 0.5, Config.SPAWN_POINT.Z), color(119, 224, 238),
	{ className = "SpawnLocation" })

local trees = {
	Vector3.new(-114, 0, -76), Vector3.new(-117, 0, -26), Vector3.new(-108, 0, 33),
	Vector3.new(-111, 0, 105), Vector3.new(110, 0, -71), Vector3.new(116, 0, -18),
	Vector3.new(109, 0, 43), Vector3.new(112, 0, 105),
}
local greens = { color(34, 125, 83), color(58, 151, 77), color(77, 173, 85) }
for index, position in ipairs(trees) do
	local height = 5 + index % 3
	local trunk = position + Vector3.new(0, height / 2, 0)
	makePart("TreeTrunk" .. index, Vector3.new(height, 2, 2), trunk, color(113, 74, 46),
		{ shape = Enum.PartType.Cylinder, cframe = CFrame.new(trunk) * CFrame.Angles(0, 0, math.pi / 2) })
	makePart("TreeCrown" .. index, Vector3.new(7, 7, 7), position + Vector3.new(0, height + 2, 0),
		greens[(index - 1) % #greens + 1], { shape = Enum.PartType.Ball })
end

local rocks = {
	Vector3.new(-96, 0, -63), Vector3.new(-65, 0, -38), Vector3.new(-99, 0, 54),
	Vector3.new(76, 0, -55), Vector3.new(97, 0, 18), Vector3.new(44, 0, 109),
}
for index, position in ipairs(rocks) do
	local height = 2 + index % 2
	makePart("Rock" .. index, Vector3.new(4 + index % 3, height, 4), position + Vector3.new(0, height / 2, 0),
		color(117, 126, 131), { shape = Enum.PartType.Ball })
end

local signPosition = Vector3.new(0, 8, -125)
local sign = makePart("BaySign", Vector3.new(20, 6, 1), signPosition, color(27, 46, 53),
	{ canCollide = false, cframe = CFrame.lookAt(signPosition, signPosition + Vector3.new(0, 0, 1)) })
local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
surface.CanvasSize = Vector2.new(400, 120)
surface.LightInfluence = 0
surface.Parent = sign

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 1)
title.BackgroundTransparency = 1
title.Text = "BRAINROT BAY"
title.TextColor3 = color(255, 231, 70)
title.TextSize = 48
title.Font = Enum.Font.SourceSansBold
title.Parent = surface

world.Parent = Workspace
