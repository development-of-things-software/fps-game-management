-- the server deals with things like gamemodes --

local MIN_PLAYERS = 2

local modem = peripheral.find("modem")
modem.open(795)
local votes = {}

local gamemodes = {
  "Free-for-all",
  "Team Deathmatch",
  "Midieval Free-for-all"
}

local gmids = {
  ["Free-for-all"] = "ffa",
  ["Team Deathmatch"] = "tdm",
  ["Midieval Free-for-all"] = "mid"
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

-- where to teleport players so they can vote
local votePosition = {
  171, 42, -42,
  -- facing toward the monitor!
  -90, 0
}

local function reset()
  log{{text="resetting"}}
  votes = {}
  loot.init()
  local players, nplayers
  repeat
    commands.clear("@a")
    commands.gamemode("adventure @a")
    -- teleport all players to the waiting area
    commands.tp("@a", 182, 43, -42)
    players = core.getPlayers()
    if #players ~= nplayers then
      log {
        {text = "We have ", color = "gold"},
        {text = tostring(#players), color = "yellow"},
        {text = " of the ", color = "gold"},
        {text = tostring(MIN_PLAYERS), color = "yellow"},
        {text = " players required to start a match.", color = "gold"},
      }
    end
    nplayers = #players
  until #players >= MIN_PLAYERS
  local countdown = 10
  for i=countdown, 1, -1 do
    os.sleep(1)
    log {
      {text = "Voting begins in "},
      {text = tostring(i), color = "yellow"},
      {text = " seconds", color = "white"}
    }
  end
  players = core.getPlayers()
  --[[
  for i, name in ipairs(players) do
    commands.tp(name, table.unpack(votePosition))]]
    commands.replaceitem(
      "entity @a hotbar.0 computercraft:pocket_computer_advanced{ComputerId:1}")
    local tid = os.startTimer(20)
    local tvotes = 0
    while true do
      local signal, _t, chan, _, id = os.pullEvent()
      if signal == "modem_message" and chan == 795 then
        print("got a vote for " .. id)
        tvotes = tvotes + 1
        votes[id] = (votes[id] or 0) + 1
        -- teleport player back to the waiting area
        commands.title(name, "actionbar",
          '"Vote accepted. Please wait for others."')
        --commands.tp(name, 182, 42, -41)
        break
      end
      if (signal == "timer" and _t == tid) or tvotes == #players then
        log {
          {text = "Voting is ", color = "white"},
          {text = "OVER", color = "red"}
        }
        break
      end
    end
  --end
  
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
