-- the server deals with things like gamemodes --

local votes = {}

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
  commands.computercraft(state and "turn-on" or "shutdown", id)
end

local function reset()
  log{{text="resetting"}}
  votes = {}
  power(0, false)
  power(0, true)
  --commands.clear("@a")
  log{
    {text = "voting begins "},
    {text = "NOW", color = "yellow"},
    {text = " - you have ", color = "white"},
    {text = "30", color = "green"},
    {text = " seconds", color = "white"}
  }
  local tid = os.startTimer(30)
  while true do
    local signal, _t, chan, _, id = os.pullEvent()
    if signal == "timer" and _t == tid then break end
    if signal == "modem_message" and chan == 795 then
      votes[id] = (votes[id] or 0) + 1
    end
  end
  
end

reset()
