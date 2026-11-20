local BrainrotData = {}

BrainrotData.DEFINITIONS = {
    {Name = "Tung Tung Toaster", Rarity = "Common", Cost = 100, Income = 5, Color = Color3.fromRGB(210, 180, 140), Scale = 1},
    {Name = "Bananini Banana", Rarity = "Common", Cost = 150, Income = 8, Color = Color3.fromRGB(250, 220, 80), Scale = 1},
    {Name = "Tralala Shark", Rarity = "Rare", Cost = 500, Income = 25, Color = Color3.fromRGB(90, 140, 220), Scale = 1.1},
    {Name = "Crocodilo Plane", Rarity = "Rare", Cost = 800, Income = 40, Color = Color3.fromRGB(120, 200, 120), Scale = 1.1},
    {Name = "Bombardiro Lizard", Rarity = "Epic", Cost = 2500, Income = 120, Color = Color3.fromRGB(220, 120, 60), Scale = 1.2},
    {Name = "Giraffa Espresso", Rarity = "Epic", Cost = 4000, Income = 200, Color = Color3.fromRGB(200, 160, 90), Scale = 1.2},
    {Name = "Chimpanzini Cappuccino", Rarity = "Legendary", Cost = 12000, Income = 600, Color = Color3.fromRGB(150, 110, 70), Scale = 1.3},
    {Name = "Frigo Camelo", Rarity = "Legendary", Cost = 20000, Income = 1000, Color = Color3.fromRGB(200, 200, 210), Scale = 1.3},
    {Name = "La Vaca Loco", Rarity = "Mythic", Cost = 60000, Income = 3000, Color = Color3.fromRGB(240, 240, 240), Scale = 1.45},
    {Name = "Trippi Troppi Fish", Rarity = "Mythic", Cost = 100000, Income = 5000, Color = Color3.fromRGB(255, 150, 180), Scale = 1.45},
    {Name = "Sahur Supreme", Rarity = "BrainrotGod", Cost = 500000, Income = 25000, Color = Color3.fromRGB(255, 215, 0), Scale = 1.6},
    {Name = "Matteo Ultimate", Rarity = "BrainrotGod", Cost = 1000000, Income = 50000, Color = Color3.fromRGB(180, 80, 255), Scale = 1.6},
}

BrainrotData.RARITY_WEIGHTS = {
    Common = 50,
    Rare = 28,
    Epic = 13,
    Legendary = 6,
    Mythic = 2,
    BrainrotGod = 1,
}

BrainrotData.MUTATIONS = {
    Normal = {Multiplier = 1, Chance = 0.85},
    Gold = {Multiplier = 2, Chance = 0.10},
    Diamond = {Multiplier = 5, Chance = 0.05},
}

local random = Random.new()
local rarityOrder = {"Common", "Rare", "Epic", "Legendary", "Mythic", "BrainrotGod"}
local mutationOrder = {"Normal", "Gold", "Diamond"}

function BrainrotData.roll()
    local totalWeight = 0
    for _, rarity in ipairs(rarityOrder) do
        totalWeight = totalWeight + BrainrotData.RARITY_WEIGHTS[rarity]
    end

    local rarityRoll = random:NextNumber() * totalWeight
    local selectedRarity = rarityOrder[#rarityOrder]
    local cumulativeWeight = 0
    for _, rarity in ipairs(rarityOrder) do
        cumulativeWeight = cumulativeWeight + BrainrotData.RARITY_WEIGHTS[rarity]
        if rarityRoll < cumulativeWeight then
            selectedRarity = rarity
            break
        end
    end

    local candidates = {}
    for _, definition in ipairs(BrainrotData.DEFINITIONS) do
        if definition.Rarity == selectedRarity then
            table.insert(candidates, definition)
        end
    end
    local definition = candidates[random:NextInteger(1, #candidates)]

    local mutationRoll = random:NextNumber()
    local mutationName = mutationOrder[#mutationOrder]
    local cumulativeChance = 0
    for _, name in ipairs(mutationOrder) do
        cumulativeChance = cumulativeChance + BrainrotData.MUTATIONS[name].Chance
        if mutationRoll < cumulativeChance then
            mutationName = name
            break
        end
    end

    return definition, mutationName, BrainrotData.MUTATIONS[mutationName].Multiplier
end

function BrainrotData.getByName(name)
    for _, definition in ipairs(BrainrotData.DEFINITIONS) do
        if definition.Name == name then
            return definition
        end
    end
    return nil
end

return BrainrotData
