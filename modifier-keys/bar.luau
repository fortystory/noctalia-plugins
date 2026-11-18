--!nonstrict
-- Modifier Keys bar widget.
--
-- Renders the four modifier symbols plus the last key / gesture from the
-- snapshot published by the `input` service. Click opens the panel, right
-- click opens the plugin settings.

local keymap = require("./keymap.luau")

local MOD_ORDER = { "super", "alt", "ctrl", "shift" }

local DEFAULT_MODIFIERS = {
  super = "⌘",
  alt = "⌥",
  ctrl = "⌃",
  shift = "🡅",
}

local DEFAULT_GESTURES = {
  motion = "󰆽",
}

local state = noctalia.state.get("mk.state") or {}
local modifierSymbols = {}
local gestureSymbols = {}
local lastVertical = nil

local function decodeMap(key)
  local raw = noctalia.getConfig(key)
  if type(raw) ~= "string" or raw == "" then
    return {}
  end
  local ok, value = pcall(noctalia.json.decode, raw)
  if ok and type(value) == "table" then
    return value
  end
  return {}
end

local function loadSymbols()
  local modifiers = decodeMap("modifier_symbols")
  local gestures = decodeMap("gesture_symbols")

  modifierSymbols = {}
  for _, name in ipairs(MOD_ORDER) do
    modifierSymbols[name] = keymap.lookup(modifiers, name) or DEFAULT_MODIFIERS[name]
  end

  gestureSymbols = {}
  for key, value in pairs(DEFAULT_GESTURES) do
    gestureSymbols[key] = keymap.lookup(gestures, key) or value
  end
  gestureSymbols.motion = keymap.lookup(gestures, "motion") or DEFAULT_GESTURES.motion
end

local function showGesture()
  local cfg = noctalia.getConfig("show_gesture")
  return cfg ~= false
end

local function render()
  local vertical = barWidget.isVertical()
  lastVertical = vertical
  local children = {}

  local spacing = tonumber(noctalia.getConfig("symbol_spacing")) or 2
  local slotWidth = tonumber(noctalia.getConfig("symbol_width")) or 16
  local fontFamily = noctalia.getConfig("font_family")
  if type(fontFamily) ~= "string" or fontFamily == "" then
    fontFamily = nil
  end
  local activeColor = noctalia.getConfig("active_color") or "primary"
  local inactiveColor = noctalia.getConfig("inactive_color") or "on_surface_variant"

  -- ui.label ignores `width` in v5; a fixed-width flex container is the slot.
  local function slot(props)
    return ui.row({ width = slotWidth, justify = "center", align = "center" }, {
      ui.label(props),
    })
  end

  local mods = state.mods or {}
  local fading = state.fading or {}
  local inCombo = state.inCombo or {}
  local comboVisible = state.isFading == true

  for _, name in ipairs(MOD_ORDER) do
    local pressed = mods[name] == true
    local isFading = fading[name] == true
    local inComboNow = comboVisible and inCombo[name] == true
    local active = pressed or isFading or inComboNow

    children[#children + 1] = slot({
      text = modifierSymbols[name],
      color = active and activeColor or inactiveColor,
      opacity = pressed and 1.0 or ((isFading or inComboNow) and 0.8 or 0.5),
      fontWeight = "bold",
      fontFamily = fontFamily,
      maxWidth = slotWidth,
      maxLines = 1,
      textAlign = "center",
    })
  end

  local gesture = state.gesture or ""
  local motion = state.motion == true
  local keyText = state.keyText or ""

  local displayText = ""
  local displayActive = false
  local displayFading = false

  if gesture ~= "" and showGesture() then
    displayText = gesture
    displayActive = true
    displayFading = state.gestureFading == true
  elseif motion and showGesture() then
    displayText = gestureSymbols.motion or "󰆽"
    displayActive = true
    displayFading = false
  elseif keyText ~= "" then
    displayText = keyText
    displayActive = true
    displayFading = state.isFading == true
  else
    displayText = "_"
  end

  children[#children + 1] = slot({
    text = displayText,
    color = displayActive and activeColor or inactiveColor,
    opacity = displayActive and (displayFading and 0.6 or 1.0) or 0.2,
    fontWeight = "bold",
    fontFamily = fontFamily,
    maxWidth = slotWidth,
    maxLines = 1,
    textAlign = "center",
  })

  -- Keep a small symmetric buffer so glyphs wider than their slot cannot be
  -- clipped by the capsule edge or the bar slot when the widget has no capsule.
  -- On a vertical bar the main axis is height, so the buffer goes above/below;
  -- horizontal padding would only overflow the narrow bar thickness.
  local make = vertical and ui.column or ui.row
  local rootProps = { gap = spacing, align = "center", justify = "center" }
  rootProps[vertical and "paddingV" or "paddingH"] = 8
  barWidget.render(make(rootProps, children))
end

noctalia.state.watch("mk.state", function(value)
  if type(value) == "table" then
    state = value
  else
    state = {}
  end
  render()
end)

function onConfigChanged()
  loadSymbols()
  render()
end

-- The top-level render can run before the host has laid the bar out, when
-- barWidget.isVertical() still reports the horizontal default. Re-render as
-- soon as the layout direction differs from the one that was drawn.
function update()
  if lastVertical == nil or barWidget.isVertical() ~= lastVertical then
    render()
  end
end

loadSymbols()
render()
