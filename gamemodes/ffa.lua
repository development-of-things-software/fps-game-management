-- free-for-all gamemode --
-- this is the most basic gamemode
-- there are no teams
-- there are few rules

local log = ...

local core = require("gamemodes.core")

core.init()

log {
  {text = "You have 10 minutes.  Score as many frags as possible.",
    color = "yellow"}
}

os.sleep(60 * 10)

log {
  {text = "The game is over.",
    color = "yellow"}
}

commands.tp("@a", 151, 241, -41)
