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

log{{text="control computer started"}}

local function power(id, state)
  commands.computercraft(state and "turn-on" or "shutdown", tostring(id))
end

local computerCount = 3
local thisComputer = 0
local function powerCycleAll()
  for i=0, computerCount, 1 do
    if i ~= thisComputer then
      power(i, false)
      power(i, true)
    end
  end
end

local function reset()
  log{{text="resetting"}}
  votes = {}
  powerCycleAll()
  --commands.clear("@a")
  log{
    {text = "voting begins "},
    {text = "NOW", color = "yellow"},
    {text = " - you have ", color = "white"},
    {text = "30", color = "green"},
    {text = " seconds", color = "white"}
  }
  local tids = {
    [os.startTimer(5)] = 25,
    [os.startTimer(10)] = 20,
    [os.startTimer(15)] = 15,
    [os.startTimer(20)] = 10,
    [os.startTimer(25)] = 5,
    [os.startTimer(26)] = 4,
    [os.startTimer(27)] = 3,
    [os.startTimer(28)] = 2,
    [os.startTimer(29)] = 1,
  }
  local tid_last = os.startTimer(30)
  while true do
    local signal, _t, chan, _, id = os.pullEvent()
    if signal == "timer" then
      if _t == tid_last then break end
      if tids[_t] then
        log{
          {text = tostring(tids[_t]), color = "green"},
          {text = " seconds remain", color = "white"}
        }
      end
    end
    if signal == "modem_message" and chan == 795 then
      print("got a vote for " .. id)
      votes[id] = (votes[id] or 0) + 1
    end
  end
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
  local gmf, err = loadfile("/gamemodes/"..gmids[votes[1].name]..".lua", nil,
    nil, _ENV)
  if not gmf then
    log {
      {text = "Failed to launch the game", color = "red"}
    }
    log {
      {text = "Error reason: ", color = "white"},
      {text = err, color = "red"}
    }
  else
    gmf(log)
  end
end

reset()
