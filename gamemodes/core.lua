-- core gameplay library --

local PLAYER_RESPAWN_WAIT = 5

local loadouts = {
  standard = {
    ["armor.head"] = "minecraft:leather_helmet",
    ["armor.chest"] = "minecraft:iron_chestplate",
    ["armor.legs"] = "minecraft:leather_leggings",
    ["armor.feet"] = "minecraft:leather_boots",
    ["hotbar.0"] = "cgm:pistol",
    ["hotbar.1"] = "cgm:basic_bullet 64",
    ["hotbar.2"] = "minecraft:stone_sword",
    ["hotbar.3"] = "minecraft:cooked_beef 32"
  },
  minimal = {
    ["armor.chest"] = "minecraft:iron_chestplate",
    ["hotbar.0"] = "minecraft:stone_sword"
  }
}

local core = {}

-- custom command wrappers to preserve events
local function makeCommand(name)
  return function(...)--[[
    local id = commands.async[name](...)
    while true do
      local signal = table.pack(os.pullEvent())
      if signal[1] == "task_complete" and signal[2] == id then
        return table.unpack(signal, 3, signal.n)
      end
      os.queueEvent(table.unpack(signal, 1, signal.n))
    end--]]
    return commands.exec(table.concat(table.pack(name, ...), " "))
  end
end

core.commands = setmetatable({}, {__index = function(t, k)
  t[k] = makeCommand(k)
  return t[k]
end})

-- e.g. core.team.join("example", "FooBarBazUser")
core.team = setmetatable({}, {__index = function(t, k)
  return function(...)
    return core.commands.team(k, ...)
  end
end})

-- override team.add()
function core.team.add(name, dname)
  dname = '"' .. dname .. '"'
  return core.commands.team("add", name, dname)
end

-- initialize a team
-- team name MUST be a valid color!
function core.team.init(name, showNameInternally)
  core.team.add(name, name)
  core.team.modify(name, "color", name)
  core.team.modify(name, "prefix ["..name.."] ")
  core.commands.scoreboard("players set", name, "teamkills 0")
  if showNameInternally then
    core.team.modify(name, "nametagVisibility hideForOtherTeams")
    core.team.modify(name, "friendlyFire false")
  else
    core.team.modify(name, "nametagVisibility never")
    core.team.modify(name, "friendlyFire true")
  end
end

-- if there are teams, then they will be dropped
-- at these locations
local teamLocations = {
  {198, 77, -17},
  {181, 97, 30}
}

local teamColors = { "red", "blue" }

-- get all online players
-- TODO: this may break on servers with
-- plugins, particularly if those plugins
-- change the output of '/list'
function core.getPlayers()
  local success, output = core.commands.list()
  if output then
    local players = {}
    local plist = output[1]:match("online: (.+)")
    for name in plist:gmatch("[^ ,]+") do
      players[#players+1] = name
    end
    return players
  end
  error("could not get list of players")
end

function core.giveItems(name, loadout)
  core.commands.clear(name)
  for k, v in pairs(loadout) do
    commands.async.replaceitem("entity", name, k, v)
  end
end

local startPosition = {
  210, -15
}

-- if a player joins in the middle of a
-- game, we can still register them
-- TODO: actually implement that functionality,
-- preferably in a sane manner
local playerCounts = {}
function core.registerPlayer(name)
  local team = 1
  for i, count in ipairs(playerCounts) do
    if count > playerCounts[team] then team = i end
  end
  team = teamColors[team]
  core.team.join(team, name)
  core.commands.scoreboard("players set", name, "kills", 0)
end

function core.retrieveScoreboard(name, board)
  local _, result = core.commands.scoreboard("players get", name, board)
  local res = result[1]:match(name.." has (%d) ")
  return tonumber(res)
end

function core.runGame(params)
  local players = core.getPlayers()
  -- add teams
  if params.teams then
    -- fancy colored names, friendly fire disabled, and nametags show to
    -- other team member
    for i, name in ipairs(teamColors) do
      playerCounts[i] = 0
      core.team.init(name, true)
    end
    for i, name in ipairs(players) do
      core.registerPlayer(name)
    end
  else
    -- no fancy colored names, friendly fire enabled, and nametags never show
    core.team.init("white", false)
    core.team.join("white", "@a")
  end

  for i, name in ipairs(players) do
    core.giveItems(name, loadouts[params.loadout])
  end

  -- spread players, if necessary
  if params.spread then
    commands.spreadplayers(startPosition[1], startPosition[2],
      50, 50, "false @a")
  else
    for i, pos in ipairs(teamLocations) do
      commands.async.tp("@a[team="..teamColors[i].."]", table.unpack(pos))
    end
  end

  -- main loop
  core.log{{text = "The game is starting"}}
  
  -- require this here to avoid loops
  local loot = require("loot")

  loot.refreshChests()
  
  local game_ended = os.startTimer(params.gameEnd)
  local loot_refresh = os.startTimer(params.lootRefresh)
  local player_refresh = os.startTimer(PLAYER_RESPAWN_WAIT)

  while true do
    local signal = table.pack(os.pullEvent())
    if signal[1] == "computer_command" then
      if signal[2] == "game_end" then break end
    elseif signal[1] == "timer" then
      if signal[2] == game_ended then break
      elseif signal[2] == loot_refresh then
        loot.refreshChests()
        loot_refresh = os.startTimer(params.lootRefresh)
      elseif signal[2] == player_refresh then
        player_refresh = os.startTimer(PLAYER_RESPAWN_WAIT)
        -- clear up empty flux capacitors
        core.commands.clear("@a thermal:flux_capacitor{Energy:0}")
        if params.multilife then
          -- for each player that just died, throw them back in the fray
          for i, pname in ipairs(players) do
            local count = core.retrieveScoreboard(pname, "deaths")
            if count > 0 then
              core.commands.scoreboard("players set", pname, "deaths 0")
              core.giveItems(pname, loadouts[params.loadout])
              core.commands.spreadplayers(startPosition[1], startPosition[2],
                50, 40, "false", pname)
            end
          end
        end
      end
    end
  end
  
  -- game over
  core.log {
    {text = "The game is now over", color = "yellow"}
  }

  -- for teamed games
  if params.teams then
    local counts = {}
    for i, name in ipairs(teamColors) do
      -- sum up all kills
      commands.execute(
        "as @a[team="..name.."] run scoreboard players operation", name,
        "teamkills += @s kills")
  
      -- empty the team
      core.team.empty(name)
  
      -- get the team's kill count
      local kills = core.retrieveScoreboard(name, "teamkills")
      counts[#counts+1] = {name = name, kills = kills}
    end
  
    table.sort(counts, function(a, b)
      return a.kills > b.kills
    end)
  
    core.log {
      {text = "The "},
      {text = counts[1].name:upper(), colors = counts[1].name},
      {text = " team has won with ", color = "white"},
      {text = tostring(counts[1].kills), color = "yellow"},
      {text = " frags!", color = "white"}
    }
  else -- non-teamed games (i.e. FFA)
    core.team.empty("white")
    local counts = {}
    for i, name in ipairs(players) do
      counts[#counts+1] = {
        name = name, kills = core.retrieveScoreboard(name, "kills")
      }
      commands.scoreboard("players set", name, "kills 0")
    end
    table.sort(counts, function(a, b)
      return a.kills > b.kills
    end)
    core.log {
      {text = counts[1].name, color = "green"},
      {text = " has won with ", color = "white"},
      {text = tostring(counts[1].kills), color = "yellow"},
      {text = " frags!", color = "white"},
    }
  end
  commands.kill("@e[type=item]")
  for _, player in ipairs(players) do
    commands.gamemode("spectator", player)
    commands.effect("give", player, "minecraft:instant_health 10 120 true")
    commands.effect("give", player, "minecraft:saturation 10 120 true")
  end
end

return core
