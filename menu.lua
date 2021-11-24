-- FPS map hosting software: Game selection --

local modem = peripheral.find("modem")

modem.open(795)

local function menu(title, items)
  term.setBackgroundColor(colors.lightBlue)
  term.setTextColor(colors.black)
  term.clear()
  local w, h = term.getSize()
  while true do
    term.setCursorPos(8, 2)
    term.write(title)
    for i=1, h - 5, 1 do
      term.setCursorPos(4, 3 + i)
      term.setBackgroundColor(i % 2 == 1 and colors.lightGray or colors.gray)
      local text = items[i] or ""
      term.write(text .. string.rep(" ", (w - 8) - #text))
    end
    local sig, btn, x, y = os.pullEvent()
    if sig == "monitor_touch" or sig == "mouse_click" then
      local item = y - 3
      if items[item] then
        term.setCursorPos(4, 3 + item)
        term.setBackgroundColor(colors.lime)
        term.write(items[item] .. string.rep(" ", (w - 8) - #items[item]))
        modem.transmit(795, 795, item)
        break
      end
    end
  end
  while true do os.pullEvent() end
end

local gamemodes = {
  "Free-for-all",
  "Team Deathmatch"
}

menu("Select Gamemode", gamemodes)
