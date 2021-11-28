-- free-for-all gamemode --
-- this is the most basic gamemode
-- there are no teams
-- there are few rules

local core = require("gamemodes.core")

return function()
  core.log {
    {text = "You have 10 minutes.  Score as many frags as possible.",
      color = "yellow"}
  }

  core.runGame {
    -- game takes ten minutes
    gameEnd = 60 * 10,
    -- loot refreshes every minute
    lootRefresh = 60,
    -- standard loadout
    loadout = "standard",
    -- spread players evenly
    spread = true,
    -- do not use multiple teams
    teams = false,
    -- refresh players upon death
    multilife = true
  }
end
