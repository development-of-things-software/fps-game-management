-- Auto-replenisher for chests --

local core = require("gamemodes.core")

local chestLocations = {
  {229,69,-56},
  {195,97,-14},
  {168,88,-5},
  {162,88,12},
  {166,88,-3},
  {199,88,-4},
  {179,66,-49}
}

-- these get better loot but are harder to find
local specialChestLocations = {
  {205,75,-19},
  {190,74,32},
  {161,86,27},
  {234,73,-33},
  {166,88,12}
}

-- gets the best loot, but there's only one
-- and it's hard to find
local verySpecialChest = {206,84,11}

-- item data format: {item, min, max}

-- loot for basic (common) chests
-- each chest has between 2 and 15 slots of some
-- item, each of which is chosen at random, then
-- the amount of that is chosen from the min and
-- max specified in the loot tables.
-- if the minimum is below zero, then only values
-- above zero will result in any item going into
-- the chest - so, for example, min/max of -98/1
-- means that only about 1 in 100 slots will
-- contain that item.
-- TODO: perhaps have a better way of doing item
-- probability biases than having its entry
-- repeated a bunch of times?
local lootTable = {
  {"cgm:pistol", -8, 1},
  {"cgm:basic_bullet", 1, 24},
  {"cgm:basic_bullet", -2, 12},
  {"cgm:grenade", 0, 4},
  {"cgm:stun_grenade", -5, 2},
  {"cgm:shotgun", -9, 1},
  {"cgm:basic_bullet", 2, 16},
  {"cgm:rifle", -15, 1},
  {"cgm:basic_bullet", -5, 34},
  {"cgm:grenade_launcher", -10, 1},
  {"cgm:shell", 1, 15},
  {"cgm:pistol", -8, 1},
  {"cgm:light_stock", -2, 1},
  {"cgm:tactical_stock", -2, 1},
  {"cgm:silencer", -2, 1},
  {"timeless_and_classic:round45", -1, 52},
  {"timeless_and_classic:round45", -1, 52},
  {"cgm:weighted_stock", -2, 1},
  {"cgm:light_grip", -2, 1},
  {"cgm:pistol", -8, 1},
  {"cgm:specialised_grip", -2, 1},
  {"cgm:short_scope", -2, 1},
  {"cgm:long_scope", -2, 1},
  {"cgm:medium_scope", -2, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
  {"minecraft:cooked_beef", 8, 32},
}

-- loot for special (rarer, more hidden) chests
local specialLootTable = {
  {"cgm:advanced_bullet", 1, 32},
  {"cgm:minigun", -5, 1},
  {"cgm:minigun", -5, 1},
  {"cgm:minigun", -5, 1},
  {"cgm:minigun", -5, 1},
  {"cgm:minigun", -5, 1},
  {"cgm:machine_pistol", -10, 1},
  {"cgm:machine_pistol", -10, 1},
  {"cgm:machine_pistol", -10, 1},
  {"cgm:machine_pistol", -10, 1},
  {"cgm:machine_pistol", -10, 1},
  {"cgm:grenade", -3, 33},
  {"cgm:advanced_bullet", 1, 45},
  {"cgm:basic_bullet", 4, 52},
  {"cgm:basic_bullet", -10, 60},
  {"cgm:light_stock", -2, 1},
  {"cgm:tactical_stock", -2, 1},
  {"cgm:silencer", -2, 1},
  {"cgm:weighted_stock", -2, 1},
  {"timeless_and_classic:round45", -1, 52},
  {"cgm:light_grip", -2, 1},
  {"cgm:specialised_grip", -2, 1},
  {"cgm:short_scope", -2, 1},
  {"cgm:long_scope", -2, 1},
  {"cgm:medium_scope", -2, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"thermal:flux_capacitor{Energy: 100000, Mode: 2}", 0, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"ironjetpacks:stone_jetpack", -1, 1},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
  {"minecraft:cooked_beef", 8, 64},
}

-- loot for the very special chest
local verySpecialLootTable = {
  {"cgm:heavy_rifle", -10, 1},
  {"cgm:heavy_rifle", -10, 1},
  {"cgm:heavy_rifle", -10, 1},
  {"cgm:heavy_rifle", -10, 1},
  {"cgm:heavy_rifle", -10, 1},
  {"cgm:heavy_rifle", -10, 1},
  {"cgm:advanced_bullet", -1, 44},
  {"cgm:grenade", -3, 18},
  {"timeless_and_classic:vector45", -3, 1},
  {"timeless_and_classic:vector45", -3, 1},
  {"timeless_and_classic:vector45", -3, 1},
  {"timeless_and_classic:round45", -1, 52},
  {"timeless_and_classic:round45", -1, 52},
  {"timeless_and_classic:round45", -1, 52},
  {"cgm:light_stock", -2, 1},
  {"cgm:tactical_stock", -2, 1},
  {"cgm:silencer", -2, 1},
  {"cgm:weighted_stock", -2, 1},
  {"cgm:light_grip", -2, 1},
  {"cgm:specialised_grip", -2, 1},
  {"cgm:short_scope", -2, 1},
  {"cgm:long_scope", -2, 1},
  {"cgm:medium_scope", -2, 1},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
  {"minecraft:golden_carrot", 10, 64},
}

local function refreshChest(chest, loot)
  local x, y, z = chest[1], chest[2], chest[3]
  local nitems = math.random(2, 15)
  local slots = {}
  for i=1, nitems, 1 do
    local item = loot[math.random(1, #loot)]
    local count = math.random(item[2], item[3])
    if count > 0 then
      local slot
      repeat
        slot = math.random(0, 26)
      until not slots[slot]
      slots[slot] = {item[1], count}
    end
  end
  for slot, idat in pairs(slots) do
    commands.async.replaceitem("block", x, y, z,
      "container."..slot, idat[1], idat[2])
  end
end

local lib = {}

function lib.init()
  core.log {
    {color = "white", text = "["},
    {color = "red", text = "loot"},
    {color = "white", text = "] emptying chests"},
  }
  for i, chest in ipairs(chestLocations) do
    commands.setblock(chest[1], chest[2], chest[3], "chest")
  end
  for i, chest in ipairs(specialChestLocations) do
    commands.setblock(chest[1], chest[2], chest[3], "chest")
  end
  commands.setblock(verySpecialChest[1], verySpecialChest[2],
    verySpecialChest[3], "chest")
end

function lib.refreshChests()
  core.log {
    {color = "white", text = "["},
    {color = "red", text = "loot"},
    {color = "white", text = "] refilling chests"},
  }
  -- refresh basic chests
  for i, chest in ipairs(chestLocations) do
    refreshChest(chest, lootTable)
  end
  for i, chest in ipairs(specialChestLocations) do
    refreshChest(chest, specialLootTable)
  end
  refreshChest(verySpecialChest, verySpecialLootTable)
end

return lib
