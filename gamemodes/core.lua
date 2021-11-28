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

-- e.g. core.team.join("example", "FooBarBazUser")
core.team = setmetatable({}, {__index = function(t, k)
  return function(...)
    return commands.team(k, ...)
  end
end})

-- override team.add()
function core.team.add(name, dname)
  dname = '"' .. dname .. '"'
  return commands.team("add", name, dname)
end

-- initialize a team
-- team name MUST be a valid color!
function core.team.init(name, showNameInternally)
  core.team.add(name, name)
  core.team.modify(name, "color", name)
  core.team.modify(name, "prefix", "["..name.."] ")
  commands.scoreboard("players", "set", name, "teamkills", 0)
  if showNameInternally then
    core.team.modify(name, "nametagVisibility", "hideForOtherTeams")
    core.team.modify(name, "friendlyFire", "false")
  else
    core.team.modify(name, "nametagVisibility", "never")
    core.team.modify(name, "friendlyFire", "true")
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
  local success, output = commands.exec("list")
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
  commands.clear(name)
  for k, v in pairs(loadout) do
    commands.replaceitem("entity", name, k, v)
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
  commands.scoreboard("players", "set", name, "kills", 0)
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
      50, 50, "false", "@a")
  else
    for i, pos in ipairs(teamPositions) do
      commands.tp("@a[team="..teamColors[i].."]", table.unpack(pos))
    end
  end

  -- main loop
  local game_ended = os.startTimer(params.gameEnd)
  local loot_refresh = os.startTimer(params.lootRefresh)
  local player_refresh = os.startTimer(PLAYER_RESPAWN_WAIT)

  core.log{{text = "The game is starting"}}
  
  -- require this here to avoid loops
  local loot = require("loot")

  loot.refreshChests()
  while true do
    local signal = table.pack(os.pullEvent())
    if signal[1] == "timer" then
      if signal[2] == game_ended then break end
      if signal[2] == loot_refresh then
        loot.refreshChests()
        loot_refresh = os.startTimer(params.lootRefresh)
      end
      if signal[2] == player_refresh then
        player_refresh = os.startTimer(PLAYER_RESPAWN_WAIT)
        -- clear up empty flux capacitors
        commands.clear("@a thermal:flux_capacitor{Energy:0}")
        if params.multilife then
          -- for each player that just died, throw them back in the fray
          for i, pname in ipairs(players) do
            local yes, result = commands.scoreboard("players get",
              pname, "deaths")
            local count = tonumber(result[1]:match(" has (%d) "))
            if count > 0 then
              commands.scoreboard("players set", pname, "deaths 0")
              core.giveItems(pname, loadouts[params.loadout])
              commands.spreadplayers(startPosition[1], startPosition[2],
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
      local _, result = commands.scoreboard("players get", name, "teamkills")
      local kills = result[1]:match(name.." has (%d) ")
      kills = tonumber(kills)
      counts[#counts+1] = {name = name, kills = kills}
    end
  
    table.sort(counts, function(a, b)
      return a.kills > b.kills
    end)
  
    core.log {
      {text = "The "},
      {text = counts[1].name:upper(), colors = counts[1].name},
      {text = " team has won!", color = "white"}
    }
  else -- non-teamed games (i.e. FFA)
  end
end

return core
