-- "Midieval" gamemode --

local core = require("gamemodes.core")

return function()
  core.log {
    {text = "You have 10 minutes.  Score as many frags as possible.",
      color = "yellow"}
  }

  core.runGame {
    gameEnd = 60 * 10,
    lootRefresh = 60,
    loadout = "minimal",
    spread = true,
    teams = false,
    multilife = true
  }
end
