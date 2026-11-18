--!nonstrict
-- Modifier Keys input service.
--
-- Reads libinput's event stream, tracks modifier state, the last key and
-- trackpad gestures, records key statistics, and publishes everything to the
-- bar widget and panel over noctalia.state.
--
-- Ported from the v4 BarWidget.qml parsing/state machine. The QML presentation
-- and QtQuick.LocalStorage statistics live in the respective entries now.

local keymap = require("./keymap.luau")
local Stats = require("./stats.luau")

local MOD_GROUP = { Super = "super", Ctrl = "ctrl", Alt = "alt", Shift = "shift" }
local MOD_ORDER = { "super", "alt", "ctrl", "shift" }
local MOD_NAMES = { super = "Super", alt = "Alt", ctrl = "Ctrl", shift = "Shift" }

local fadeMs = tonumber(noctalia.getConfig("fade_ms")) or 800
if fadeMs < 0 then
  fadeMs = 0
end

Stats.init(tonumber(noctalia.getConfig("stats_retention_days")) or 90)

-- ── State ────────────────────────────────────────────────────────────────

local mods = { super = false, alt = false, ctrl = false, shift = false }
local fading = { super = false, alt = false, ctrl = false, shift = false }
local inCombo = { super = false, alt = false, ctrl = false, shift = false }
local modifierFadeAt = { super = 0, alt = 0, ctrl = 0, shift = 0 }

local pressedKeys = {}
local keyText = ""
local isFading = false
local keyFadeAt = 0

local gestureSymbol = ""
local gestureActive = false
local gestureFading = false
local gestureFadeAt = 0
local gestureDeltaX = 0
local gestureDeltaY = 0
local gestureFingerCount = 0
local pinchScale = 1.0
local pinchActive = false

local motionActive = false
local motionFadeAt = 0

local dirty = true
local statsDirty = false
local statsRequested = false
local statsRange = "today"
local lastStatsPublish = 0

-- ── Publishing ───────────────────────────────────────────────────────────

local function publish()
  noctalia.state.set("mk.state", {
    mods = mods,
    fading = fading,
    inCombo = inCombo,
    isFading = isFading,
    keyText = keyText,
    gesture = gestureSymbol,
    gestureFading = gestureFading,
    motion = motionActive,
  })
  dirty = false
end

local function publishStats()
  noctalia.state.set("mk.stats", Stats.snapshot(statsRange))
  lastStatsPublish = noctalia.nowMs()
  statsDirty = false
end

-- ── Keyboard display helpers ─────────────────────────────────────────────

local function containsKey(key)
  for _, value in ipairs(pressedKeys) do
    if value == key then
      return true
    end
  end
  return false
end

local function clearModifierFading()
  for _, name in ipairs(MOD_ORDER) do
    fading[name] = false
    modifierFadeAt[name] = 0
  end
end

local function addKey(keyName)
  if containsKey(keyName) then
    return
  end

  clearModifierFading()

  for _, name in ipairs(MOD_ORDER) do
    inCombo[name] = mods[name]
  end

  pressedKeys[#pressedKeys + 1] = keyName
  if #pressedKeys > 1 then
    table.remove(pressedKeys, 1)
  end

  keyText = keymap.display(keyName)
  isFading = false
  keyFadeAt = 0
  dirty = true
end

local function removeKey(keyName)
  for index = #pressedKeys, 1, -1 do
    if pressedKeys[index] == keyName then
      table.remove(pressedKeys, index)
    end
  end

  if #pressedKeys > 0 then
    keyText = keymap.display(pressedKeys[#pressedKeys])
    isFading = true
    keyFadeAt = noctalia.nowMs() + fadeMs
  else
    isFading = true
    keyFadeAt = noctalia.nowMs() + fadeMs
  end
  dirty = true
end

local function clearKeyboardState()
  pressedKeys = {}
  keyText = ""
  isFading = false
  keyFadeAt = 0
  for _, name in ipairs(MOD_ORDER) do
    inCombo[name] = false
  end
  dirty = true
end

-- ── Gesture helpers ──────────────────────────────────────────────────────

local function clearGesture()
  gestureSymbol = ""
  gestureActive = false
  gestureFading = false
  gestureFadeAt = 0
  gestureDeltaX = 0
  gestureDeltaY = 0
  gestureFingerCount = 0
  pinchActive = false
  pinchScale = 1.0
  dirty = true
end

local function showGesture(symbol)
  local changed = false
  if symbol ~= nil and symbol ~= "" and symbol ~= gestureSymbol then
    gestureSymbol = symbol
    changed = true
  end
  if not gestureActive then
    gestureActive = true
    changed = true
  end
  if gestureFading then
    gestureFading = false
    changed = true
  end
  gestureFadeAt = 0
  if changed then
    dirty = true
  end
end

local function endGesture()
  gestureActive = false
  if gestureSymbol ~= "" then
    gestureFading = true
    gestureFadeAt = noctalia.nowMs() + fadeMs
  end
  dirty = true
end

local function resetGestureDeltas()
  gestureDeltaX = 0
  gestureDeltaY = 0
  gestureFingerCount = 0
end

-- ── Modifier helpers ─────────────────────────────────────────────────────

local function setModifier(group, pressed)
  if mods[group] == pressed then
    return
  end

  if pressed then
    clearModifierFading()
  else
    fading[group] = true
    modifierFadeAt[group] = noctalia.nowMs() + fadeMs
  end

  mods[group] = pressed
  dirty = true
end

local function loadGestureSymbols()
  local raw = noctalia.getConfig("gesture_symbols")
  if type(raw) ~= "string" or raw == "" then
    return {}
  end
  local ok, decoded = pcall(noctalia.json.decode, raw)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return {}
end

local gestureSymbols = loadGestureSymbols()
local defaultGestureSymbols = {
  scroll = { "⥤", "⥥", "⥢", "⥣" },
  swipe3 = { "🡆", "🡇", "🡄", "🡅" },
  swipe4 = { "⭲", "⭳", "⭰", "⭱" },
  click = "󰳽",
  rightClick = "󰳾",
  middleClick = "󰻃",
  motion = "󰆽",
  pinchIn = "󰘖",
  pinchOut = "󰘕",
}

local function gestureValue(name)
  return keymap.lookup(gestureSymbols, name) or defaultGestureSymbols[name]
end

local function directionSymbol(name, direction)
  local values = gestureValue(name)
  if type(values) == "table" and values[direction + 1] ~= nil then
    return values[direction + 1]
  end
  return nil
end

-- ── libinput parsing (ported from BarWidget.qml) ─────────────────────────

local function recordKeyPress(keyName)
  local active = {}
  for _, modifierName in ipairs(keymap.MODIFIERS) do
    local group = MOD_GROUP[modifierName]
    if group ~= nil and mods[group] then
      active[#active + 1] = modifierName
    end
  end
  Stats.record(keyName, active)
  statsDirty = true
end

local function parseKeyboardEvent(line)
  local isPressed = line:find("pressed", 1, true) ~= nil
  local isReleased = line:find("released", 1, true) ~= nil
  if not isPressed and not isReleased then
    return
  end

  local keyName = line:match("KEY_(%w+)")
  if keyName == nil then
    return
  end
  keyName = keyName:upper()

  local group = keymap.MODIFIER_KEYS[keyName]
  if group ~= nil then
    setModifier(MOD_GROUP[group], isPressed)
    return
  end

  if isPressed then
    addKey(keyName)
    recordKeyPress(keyName)
  else
    removeKey(keyName)
  end
end

local function parsePointerButton(line)
  local button = line:match("BTN_(%w+)")
  if button == nil then
    return
  end

  if line:find("pressed", 1, true) ~= nil then
    clearKeyboardState()

    if button == "LEFT" then
      showGesture(gestureValue("click") or "󰳽")
    elseif button == "RIGHT" then
      showGesture(gestureValue("rightClick") or "󰳾")
    elseif button == "MIDDLE" then
      showGesture(gestureValue("middleClick") or "󰻃")
    end
  else
    endGesture()
  end
end

local function parseScrollEvent(line)
  local vertText = line:match("vert%s+(-?[%d%.]+)/")
  local horizText = line:match("horiz%s+(-?[%d%.]+)/")
  if vertText == nil or horizText == nil then
    return
  end

  local vert = tonumber(vertText) or 0
  local horiz = tonumber(horizText) or 0
  local isNewGesture = gestureDeltaX == 0 and gestureDeltaY == 0 and not gestureActive

  gestureDeltaX = gestureDeltaX + horiz
  gestureDeltaY = gestureDeltaY + vert

  if isNewGesture then
    clearKeyboardState()
  end

  local threshold = 15
  if math.abs(gestureDeltaX) > threshold or math.abs(gestureDeltaY) > threshold then
    local direction = -1
    if math.abs(gestureDeltaX) > math.abs(gestureDeltaY) then
      direction = gestureDeltaX > 0 and 2 or 0
    else
      direction = gestureDeltaY > 0 and 1 or 3
    end
    showGesture(directionSymbol("scroll", direction))
  end

  if math.abs(vert) < 0.5 and math.abs(horiz) < 0.5
    and (math.abs(gestureDeltaX) > 5 or math.abs(gestureDeltaY) > 5) then
    if gestureActive then
      endGesture()
    end
    resetGestureDeltas()
  end
end

local function parseSwipeEvent(line)
  if line:find("GESTURE_SWIPE_BEGIN", 1, true) ~= nil then
    local fingers = line:match("GESTURE_SWIPE_BEGIN%s+%S+%s+(%d+)")
    if fingers ~= nil then
      gestureFingerCount = tonumber(fingers) or 0
      gestureDeltaX = 0
      gestureDeltaY = 0
    end
    clearKeyboardState()
    gestureActive = true
    gestureFading = false
    gestureFadeAt = 0
    dirty = true
  elseif line:find("GESTURE_SWIPE_UPDATE", 1, true) ~= nil then
    local dx, dy = line:match("GESTURE_SWIPE_UPDATE%s+%S+%s+%d+%s+(-?[%d%.]+)/(-?[%d%.]+)")
    if dx ~= nil and dy ~= nil then
      gestureDeltaX = gestureDeltaX + (tonumber(dx) or 0)
      gestureDeltaY = gestureDeltaY + (tonumber(dy) or 0)
    end

    local threshold = 20
    if math.abs(gestureDeltaX) > threshold or math.abs(gestureDeltaY) > threshold then
      local direction = -1
      if math.abs(gestureDeltaX) > math.abs(gestureDeltaY) then
        direction = gestureDeltaX > 0 and 2 or 0
      else
        direction = gestureDeltaY > 0 and 1 or 3
      end

      if gestureFingerCount == 3 then
        showGesture(directionSymbol("swipe3", direction))
      elseif gestureFingerCount == 4 then
        showGesture(directionSymbol("swipe4", direction))
      end
    end
  elseif line:find("GESTURE_SWIPE_END", 1, true) ~= nil then
    endGesture()
    resetGestureDeltas()
  end
end

local function parsePinchEvent(line)
  if line:find("GESTURE_PINCH_BEGIN", 1, true) ~= nil then
    clearKeyboardState()
    gestureActive = true
    gestureFading = false
    gestureFadeAt = 0
    pinchActive = true
    pinchScale = 1.0
    dirty = true
  elseif line:find("GESTURE_PINCH_UPDATE", 1, true) ~= nil then
    local scaleText = line:match("(%d+%.%d+)/(%d+%.%d+)")
    if scaleText ~= nil then
      local newScale = tonumber(scaleText)
      if newScale ~= nil and newScale ~= pinchScale then
        local delta = newScale - pinchScale
        pinchScale = newScale
        if delta > 0.05 then
          showGesture(gestureValue("pinchOut") or "󰩮")
        elseif delta < -0.05 then
          showGesture(gestureValue("pinchIn") or "󰩯")
        end
      end
    end
  elseif line:find("GESTURE_PINCH_END", 1, true) ~= nil then
    endGesture()
    pinchActive = false
    pinchScale = 1.0
  end
end

local function parseMotionEvent()
  if gestureActive then
    return
  end
  if not motionActive then
    clearKeyboardState()
  end
  motionActive = true
  motionFadeAt = noctalia.nowMs() + 200
  dirty = true
end

local function handle(line)
  if line:find("kernel bug", 1, true) ~= nil or line:find("Touch jump detected", 1, true) ~= nil then
    return
  end

  if line:find("KEYBOARD_KEY", 1, true) ~= nil then
    parseKeyboardEvent(line)
    return
  end

  if line:find("POINTER_BUTTON", 1, true) ~= nil then
    parsePointerButton(line)
  elseif line:find("POINTER_SCROLL_FINGER", 1, true) ~= nil then
    parseScrollEvent(line)
  elseif line:find("GESTURE_SWIPE", 1, true) ~= nil then
    parseSwipeEvent(line)
  elseif line:find("GESTURE_PINCH", 1, true) ~= nil then
    parsePinchEvent(line)
  elseif line:find("POINTER_MOTION", 1, true) ~= nil then
    parseMotionEvent()
  end
end

-- ── Timers ───────────────────────────────────────────────────────────────

local lastDate = os.date("%Y-%m-%d")

local function applyTimeouts()
  local now = noctalia.nowMs()

  for _, name in ipairs(MOD_ORDER) do
    if fading[name] and now >= modifierFadeAt[name] then
      fading[name] = false
      modifierFadeAt[name] = 0
      dirty = true
    end
  end

  if isFading and keyFadeAt > 0 and now >= keyFadeAt then
    keyText = ""
    isFading = false
    keyFadeAt = 0
    for _, name in ipairs(MOD_ORDER) do
      inCombo[name] = false
    end
    dirty = true
  end

  if gestureFading and gestureFadeAt > 0 and now >= gestureFadeAt then
    clearGesture()
  end

  if motionActive and motionFadeAt > 0 and now >= motionFadeAt then
    motionActive = false
    motionFadeAt = 0
    dirty = true
  end

  local date = os.date("%Y-%m-%d")
  if date ~= lastDate then
    lastDate = date
    Stats.cleanup()
    statsDirty = true
  end
end

function update()
  applyTimeouts()

  if dirty then
    publish()
  end

  Stats.flushIfDue()

  if statsRequested and statsDirty and noctalia.nowMs() - lastStatsPublish >= 2000 then
    publishStats()
  end
end

-- ── Commands from the panel ──────────────────────────────────────────────

noctalia.state.watch("mk.stats.request", function(request)
  if type(request) ~= "table" or type(request.range) ~= "string" then
    return
  end
  statsRange = request.range
  statsRequested = true
  publishStats()
end)

noctalia.state.watch("mk.stats.command", function(command)
  if type(command) == "table" and command.action == "clear" then
    Stats.clear()
    statsDirty = true
    publishStats()
  end
end)

-- ── Start ────────────────────────────────────────────────────────────────

local defaultCommand = "libinput debug-events --show-keycodes"
local captureCommand = noctalia.getConfig("capture_command") or defaultCommand
if captureCommand == "" then
  captureCommand = defaultCommand
end

-- runStream has no exit callback, so keep a supervisor loop alive; libinput
-- exits on device hotplug errors and the loop restarts it.
local streamCommand = captureCommand
if not captureCommand:find("while ", 1, true) then
  streamCommand = "while true; do " .. captureCommand .. "; sleep 1; done"
end

noctalia.setUpdateInterval(50)

if not noctalia.runStream(streamCommand, handle) then
  noctalia.notifyError(
    noctalia.tr("title"),
    noctalia.tr("errors.capture_failed", { command = captureCommand })
  )
end

publish()

function onExit()
  Stats.flush()
end
