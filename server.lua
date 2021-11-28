-- the server deals with things like gamemodes --

local modem = peripheral.find("modem")
modem.open(795)
local votes = {}

local gamemodes = {
  "Free-for-all",
  "Team Deathmatch"
}

local gmids = {
  ["Free-for-all"] = "ffa",
  ["Team Deathmatch"] = "tdm"
}

local function tojson(t)
  local s = "["
  for i=1, #t, 1 do
    if #s > 1 then s = s .. "," end
    s = s .. "{"
    local n = 0
    for k, v in pairs(t[i]) do
      if n > 0 then s = s .. "," end
      n = n + 1
      s = s .. string.format("%q:%q", k, v)
    end
    s = s .. "}"
  end
  return s .. "]"
end

local function broadcast(text)
  commands.tellraw("@a", tojson(text))
end

local function log(text)
  local msg = {
    {color = "white", text = "["},
    {color = "green", text = "server"},
    {color = "white", text = "] "},
  }
  for i=1, #text, 1 do
    msg[#msg+1] = text[i]
  end
  broadcast(msg)
end

-- give the core gameplay stuff the log function
local core = require("gamemodes.core")
local loot = require("loot")
core.log = log

log{{text="control computer started"}}

local function power(id, state)
  commands.computercraft(state and "turn-on" or "shutdown", tostring(id))
end

local computerCount = 10
local thisComputer = 1
local function powerCycleAll()
  for i=0, computerCount, 1 do
    if i ~= thisComputer then
      power(i, false)
      power(i, true)
    end
  end
end

-- where to teleport players so they can vote
local votePosition = {
  171, 42, -42,
  -- facing toward the monitor!
  -90, 0
}

local function reset()
  log{{text="resetting"}}
  votes = {}
  powerCycleAll()
  loot.init()
  log {
    {text = "voting begins "},
    {text = "NOW", color = "yellow"},
  }
  -- teleport all players to the waiting area
  commands.tp("@a", 182, 42, -41)
  local players = core.getPlayers()
  for i, name in ipairs(players) do
    commands.tp(name, table.unpack(votePosition))
    while true do
      local signal, _t, chan, _, id = os.pullEvent()
      if signal == "modem_message" and chan == 795 then
        print("got a vote for " .. id)
        votes[id] = (votes[id] or 0) + 1
        -- teleport player back to the waiting area
        commands.title(name, "actionbar",
          '"Vote accepted. Please wait for others."')
        commands.tp(name, 182, 42, -41)
        break
      end
    end
  end
  
  -- sort votes
  for i=1, #gamemodes, 1 do
    votes[i] = {count = votes[i] or 0, name = gamemodes[i]}
  end
  table.sort(votes, function(a, b)
    return a.count > b.count
  end)

  log {
    {text = "The chosen game mode is ", color = "white"},
    {text = votes[1].name, color = "red"}
  }
  local gmf = require("gamemodes."..gmids[votes[1].name])
  gmf()
end

while true do
  reset()
end
