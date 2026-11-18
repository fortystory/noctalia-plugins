--!nonstrict
-- Key name tables shared by the bar, panel and service entries.
-- Pure functions: every entry gets its own module instance, so this module
-- must not hold mutable state.

local M = {}

M.MODIFIERS = { "Super", "Ctrl", "Alt", "Shift" }
M.MODIFIER_SYMBOLS = {
  SUPER = "󰘳",
  CTRL = "⌃",
  ALT = "⌥",
  SHIFT = "⇧",
}

-- libinput key name -> normalized modifier group.
M.MODIFIER_KEYS = {
  LEFTMETA = "Super",
  RIGHTMETA = "Super",
  LEFTALT = "Alt",
  RIGHTALT = "Alt",
  LEFTCTRL = "Ctrl",
  RIGHTCTRL = "Ctrl",
  LEFTSHIFT = "Shift",
  RIGHTSHIFT = "Shift",
}

-- Case-insensitive table lookup: JSON symbols may use SUPER/CTRL/... or
-- super/ctrl/... (and RightClick/rightClick for gestures).
function M.lookup(map, key)
  if type(map) ~= "table" or type(key) ~= "string" then
    return nil
  end
  if map[key] ~= nil then
    return map[key]
  end
  local lower = key:lower()
  for mapKey, value in pairs(map) do
    if type(mapKey) == "string" and mapKey:lower() == lower then
      return value
    end
  end
  return nil
end

local DISPLAY = {
  F1 = "󱊫", F2 = "󱊬", F3 = "󱊭", F4 = "󱊮", F5 = "󱊯", F6 = "󱊰",
  F7 = "󱊱", F8 = "󱊲", F9 = "󱊳", F10 = "󱊴", F11 = "󱊵", F12 = "󱊶",
  HOME = "", END = "", PAGEUP = "", PAGEDOWN = "",
  INSERT = "", DELETE = "󰹾",
  UP = "↑", DOWN = "↓", LEFT = "←", RIGHT = "→",
  PLAYPAUSE = "󰐎", PAUSE = "", STOP = "", PREVIOUS = "󰒮", NEXT = "󰒭",
  PREVIOUSSONG = "󰒮", NEXTSONG = "󰒭",
  MUTE = "", VOLUMEUP = "", VOLUMEDOWN = "",
  SPACE = "󱁐", TAB = "", ENTER = "󰌑", ESCAPE = "⎋", ESC = "⎋",
  BACKSPACE = "󰁮", CAPSLOCK = "⇪", PRINT = "",
  NUMLOCK = "", SCROLLLOCK = "",
  LEFTSHIFT = "🡅", RIGHTSHIFT = "🡅",
  LEFTCTRL = "", RIGHTCTRL = "",
  LEFTALT = "", RIGHTALT = "",
  LEFTMETA = "", RIGHTMETA = "",
  SLASH = "/", BACKSLASH = "\\", APOSTROPHE = "\"", SEMICOLON = ";",
  LEFTBRACE = "[", RIGHTBRACE = "]", COMMA = ",", DOT = ".",
  KPPLUS = "+", MINUS = "-", EQUAL = "=", GRAVE = "`",
  SUPER = "󰘳", META = "󰘳", CONTROL = "⌃", ALT = "⌥", SHIFT = "⇧",
}

-- Human-readable symbol for a key name (bar and statistics).
function M.display(keyName)
  local name = tostring(keyName or ""):upper()
  if DISPLAY[name] then
    return DISPLAY[name]
  end
  if #name == 1 and name:match("%a") then
    return name:lower()
  end
  return name
end

-- "Super+Ctrl+C" -> "󰘳 + ⌃ + c"
function M.formatShortcut(shortcut)
  if shortcut == nil or shortcut == "" then
    return "-"
  end
  local out = {}
  local parts = {}
  for part in tostring(shortcut):gmatch("[^+]+") do
    parts[#parts + 1] = part:upper()
  end
  for index, part in ipairs(parts) do
    if index < #parts and M.MODIFIER_SYMBOLS[part] then
      out[#out + 1] = M.MODIFIER_SYMBOLS[part]
    else
      out[#out + 1] = M.display(part)
    end
  end
  return table.concat(out, " + ")
end

return M
