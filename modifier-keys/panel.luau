--!nonstrict
-- Modifier Keys panel: help tab + key statistics tab.
--
-- The panel never touches the statistics file itself. It asks the `input`
-- service for a snapshot over noctalia.state and renders whatever comes back.

local keymap = require("./keymap.luau")

local MOD_ORDER = { "super", "alt", "ctrl", "shift" }

local DEFAULT_MODIFIERS = {
  super = "⌘",
  alt = "⌥",
  ctrl = "⌃",
  shift = "🡅",
}

local DEFAULT_GESTURES = {
  scroll = "⥤ ⥥ ⥢ ⥣",
  swipe3 = "🡆 🡇 🡄 🡅",
  swipe4 = "⭲ ⭳ ⭰ ⭱",
  click = "󰳽",
  motion = "󰆽",
  pinch = "󰘖 󰘕",
}

local tab = "help"
local range = "today"
local stats = nil
local confirmClear = false
local requestSeq = 0
local modifierSymbols = {}
local gestureSymbols = {}

local function tr(key)
  return noctalia.tr(key)
end

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
end

local function formatNumber(value)
  local text = tostring(math.floor(tonumber(value) or 0))
  local out = text
  while true do
    local replaced, count = out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    if count == 0 then
      break
    end
    out = replaced
  end
  return out
end

local function requestStats()
  requestSeq = requestSeq + 1
  noctalia.state.set("mk.stats.request", { range = range, seq = requestSeq })
end

-- ── Rendering helpers ────────────────────────────────────────────────────

local render

local function rangeButton(id, label)
  return ui.button({
    text = label,
    variant = range == id and "primary" or "ghost",
    controlSize = "sm",
    onClick = function()
      range = id
      confirmClear = false
      requestStats()
      render()
    end,
  })
end

local function helpRow(symbol, name, detail)
  return ui.row({ gap = 12, align = "center", padding = 8, radius = 8, fill = "surface/0.35" }, {
    ui.label({ text = symbol, color = "primary", fontSize = 16, fontWeight = "bold", width = 90 }),
    ui.label({ text = name, flexGrow = 1, fontSize = 13 }),
    ui.label({ text = detail, color = "on_surface_variant", fontSize = 12 }),
  })
end

local function sectionTitle(text)
  return ui.label({ text = text, fontSize = 15, fontWeight = "bold", color = "primary" })
end

local function helpView()
  local state = noctalia.state.get("mk.state") or {}
  local mods = state.mods or {}
  local rows = {}

  rows[#rows + 1] = sectionTitle(tr("settings.modifierKeys"))
  for _, name in ipairs(MOD_ORDER) do
    local label = name:sub(1, 1):upper() .. name:sub(2)
    local keyName = name == "super" and "Meta" or name
    local symbol = modifierSymbols[name]
    local active = mods[name] == true
    rows[#rows + 1] = ui.row({ gap = 12, align = "center", padding = 8, radius = 8, fill = active and "primary/0.15" or "surface/0.35" }, {
      ui.label({
        text = symbol,
        color = active and "primary" or "on_surface_variant",
        fontSize = 16,
        fontWeight = "bold",
        width = 90,
      }),
      ui.label({ text = tr(name), flexGrow = 1, fontSize = 13 }),
      ui.label({ text = keyName, color = "on_surface_variant", fontSize = 12 }),
    })
  end

  rows[#rows + 1] = ui.separator({ spacing = 4 })
  rows[#rows + 1] = sectionTitle(tr("gestures"))
  rows[#rows + 1] = helpRow(gestureSymbols.scroll, tr("scroll"), "POINTER_SCROLL_FINGER")
  rows[#rows + 1] = helpRow(gestureSymbols.click, tr("click"), "BTN_LEFT")
  rows[#rows + 1] = helpRow(gestureSymbols.swipe3, tr("swipe3"), "GESTURE_SWIPE 3")
  rows[#rows + 1] = helpRow(gestureSymbols.swipe4, tr("swipe4"), "GESTURE_SWIPE 4")
  rows[#rows + 1] = helpRow(gestureSymbols.pinch, tr("pinch"), "GESTURE_PINCH")
  rows[#rows + 1] = helpRow(gestureSymbols.motion, tr("motion"), "POINTER_MOTION")

  return ui.scroll({ flexGrow = 1, gap = 6 }, rows)
end

local function statRow(index, name, count, maxCount)
  local ratio = 0
  if maxCount > 0 then
    ratio = math.min(1, count / maxCount)
  end
  return ui.column({ gap = 3 }, {
    ui.row({ gap = 8, justify = "space_between" }, {
      ui.label({ text = index .. ". " .. name, fontSize = 12, flexGrow = 1 }),
      ui.label({ text = formatNumber(count), fontSize = 12, color = "on_surface_variant" }),
    }),
    ui.progress({ progress = ratio, height = 3, radius = 2, fill = "primary", track = "surface" }),
  })
end

local function statList(titleText, items, formatItem)
  local rows = { sectionTitle(titleText) }
  if #items == 0 then
    rows[#rows + 1] = ui.label({ text = tr("stats.noData"), color = "on_surface_variant", fontSize = 12 })
    return rows
  end

  local maxCount = items[1].count or 1
  for index, item in ipairs(items) do
    rows[#rows + 1] = statRow(index, formatItem(item.key), item.count, maxCount)
  end
  return rows
end

local function summaryCard(label, value)
  return ui.column({ gap = 2, flexGrow = 1, padding = 10, radius = 8, fill = "surface/0.35" }, {
    ui.label({ text = label, color = "on_surface_variant", fontSize = 11 }),
    ui.label({ text = value, fontSize = 16, fontWeight = "bold", maxLines = 1 }),
  })
end

local function statsView()
  local snapshot = stats or { total = 0, topKeys = {}, topShortcuts = {} }
  local topKeys = snapshot.topKeys or {}
  local topShortcuts = snapshot.topShortcuts or {}

  local mostKey = "-"
  if topKeys[1] ~= nil then
    mostKey = keymap.display(topKeys[1].key) .. " (" .. formatNumber(topKeys[1].count) .. ")"
  end
  local mostShortcut = "-"
  if topShortcuts[1] ~= nil then
    mostShortcut = keymap.formatShortcut(topShortcuts[1].key)
      .. " (" .. formatNumber(topShortcuts[1].count) .. ")"
  end

  local children = {
    ui.row({ gap = 4 }, {
      rangeButton("today", tr("stats.today")),
      rangeButton("yesterday", tr("stats.yesterday")),
      rangeButton("week", tr("stats.thisWeek")),
      rangeButton("month", tr("stats.thisMonth")),
      rangeButton("all", tr("stats.allTime")),
    }),
    ui.row({ gap = 8 }, {
      summaryCard(tr("stats.totalKeypresses"), formatNumber(snapshot.total)),
      summaryCard(tr("stats.mostUsedKey"), mostKey),
      summaryCard(tr("stats.mostUsedShortcut"), mostShortcut),
    }),
  }

  for _, row in ipairs(statList(tr("stats.topKeys"), topKeys, function(key)
    return keymap.display(key)
  end)) do
    children[#children + 1] = row
  end

  for _, row in ipairs(statList(tr("stats.topShortcuts"), topShortcuts, function(shortcut)
    return keymap.formatShortcut(shortcut)
  end)) do
    children[#children + 1] = row
  end

  children[#children + 1] = ui.row({ gap = 8, justify = "space_between", align = "center" }, {
    ui.label({
      text = confirmClear and tr("stats.clearConfirm") or "",
      color = "error",
      fontSize = 12,
      flexGrow = 1,
      visible = confirmClear,
    }),
    ui.button({
      text = confirmClear and tr("confirm") or tr("stats.clearStats"),
      variant = "destructive",
      glyph = "trash",
      onClick = function()
        if confirmClear then
          confirmClear = false
          noctalia.state.set("mk.stats.command", { action = "clear", seq = noctalia.nowMs() })
        else
          confirmClear = true
          render()
        end
      end,
    }),
    ui.button({
      text = tr("cancel"),
      variant = "ghost",
      enabled = confirmClear,
      onClick = function()
        confirmClear = false
        render()
      end,
    }),
  })

  return ui.scroll({ flexGrow = 1, gap = 10 }, children)
end

render = function()
  local tabButtons = ui.row({ gap = 6, align = "center" }, {
    ui.button({
      text = tr("help"),
      variant = tab == "help" and "primary" or "ghost",
      onClick = function()
        tab = "help"
        render()
      end,
    }),
    ui.button({
      text = tr("stats.title"),
      variant = tab == "stats" and "primary" or "ghost",
      onClick = function()
        tab = "stats"
        confirmClear = false
        requestStats()
        render()
      end,
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.button({
      glyph = "x",
      variant = "ghost",
      onClick = function()
        panel.close()
      end,
    }),
  })

  panel.render(ui.column({ flexGrow = 1, gap = 10, padding = 16 }, {
    tabButtons,
    ui.separator({ spacing = 2 }),
    tab == "help" and helpView() or statsView(),
  }))
end

-- ── Lifecycle ────────────────────────────────────────────────────────────

function onOpen(_context)
  loadSymbols()
  if tab == "stats" then
    requestStats()
  end
  render()
end

noctalia.state.watch("mk.stats", function(value)
  if type(value) == "table" then
    stats = value
  end
  if tab == "stats" then
    render()
  end
end)

noctalia.state.watch("mk.state", function(_value)
  if tab == "help" then
    render()
  end
end)

function onConfigChanged()
  loadSymbols()
  render()
end

loadSymbols()
render()
