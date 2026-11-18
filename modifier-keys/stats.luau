--!nonstrict
-- Persistent key statistics for the Modifier Keys plugin.
--
-- Only the `input` service requires this module: entries have isolated module
-- caches, so a second instance (bar/panel) would load its own state and could
-- race on the JSON file. The panel reads snapshots published by the service
-- through noctalia.state instead.
--
-- Storage: <pluginDataDir>/stats.json
--   {
--     version = 1,
--     days = {
--       ["2026-11-18"] = {
--         total = 123,
--         keys = { A = 10, SPACE = 42 },
--         shortcuts = { ["Ctrl+C"] = 5 }
--       }
--     }
--   }

local M = {}

local FILE_NAME = "stats.json"
local FLUSH_MS = 5000
local TOP_LIMIT = 20

local dataDir = nil
local filePath = nil
local data = { version = 1, days = {} }
local dirty = false
local lastFlush = 0
local retentionDays = 90

local function today()
  return os.date("%Y-%m-%d")
end

local function dayTable(date)
  local day = data.days[date]
  if day == nil then
    day = { total = 0, keys = {}, shortcuts = {} }
    data.days[date] = day
  end
  return day
end

local function dayOf(date)
  local day = data.days[date]
  if day == nil then
    return { total = 0, keys = {}, shortcuts = {} }
  end
  day.keys = day.keys or {}
  day.shortcuts = day.shortcuts or {}
  day.total = day.total or 0
  return day
end

local function load()
  local raw, err = noctalia.readFile(filePath)
  if raw == nil then
    if type(err) == "string" and not err:find("No such file", 1, true) then
      noctalia.log("modifier-keys: cannot read stats: " .. err)
    end
    return
  end
  local decoded, decodeErr = noctalia.json.decode(raw)
  if type(decoded) ~= "table" or type(decoded.days) ~= "table" then
    noctalia.log("modifier-keys: ignoring invalid stats file: " .. tostring(decodeErr))
    return
  end
  data = decoded
  data.days = data.days or {}
  data.version = 1
end

local function save()
  local encoded, err = noctalia.json.encode(data)
  if encoded == nil then
    noctalia.log("modifier-keys: cannot encode stats: " .. tostring(err))
    return false
  end
  local ok, writeErr = noctalia.writeFile(filePath, encoded)
  if not ok then
    noctalia.log("modifier-keys: cannot write stats: " .. tostring(writeErr))
    return false
  end
  dirty = false
  lastFlush = noctalia.nowMs()
  return true
end

function M.init(configuredRetentionDays)
  local dir, dirErr = noctalia.pluginDataDir()
  if dir == nil then
    noctalia.log("modifier-keys: no plugin data dir: " .. tostring(dirErr))
    return
  end
  dataDir = dir
  noctalia.mkdirAll(dataDir)
  filePath = dataDir .. "/" .. FILE_NAME
  if type(configuredRetentionDays) == "number" and configuredRetentionDays >= 1 then
    retentionDays = math.floor(configuredRetentionDays)
  end
  load()
  M.cleanup()
end

-- Delete daily buckets older than the retention window.
function M.cleanup()
  if filePath == nil then
    return
  end
  local cutoff = os.date("%Y-%m-%d", os.time() - retentionDays * 86400)
  local removed = false
  for date in pairs(data.days) do
    if date < cutoff then
      data.days[date] = nil
      removed = true
    end
  end
  if removed then
    dirty = true
    save()
  end
end

-- Record one non-modifier key press. `modifiers` is an ordered list of
-- "Super"/"Ctrl"/"Alt"/"Shift" held at press time.
function M.record(keyName, modifiers)
  if filePath == nil or keyName == nil or keyName == "" then
    return
  end
  local day = dayTable(today())
  local key = tostring(keyName):upper()
  day.total = day.total + 1
  day.keys[key] = (day.keys[key] or 0) + 1

  if type(modifiers) == "table" and #modifiers > 0 then
    local shortcut = table.concat(modifiers, "+") .. "+" .. key
    day.shortcuts[shortcut] = (day.shortcuts[shortcut] or 0) + 1
  end

  dirty = true
end

-- Write buffered changes to disk at most once per FLUSH_MS.
function M.flushIfDue()
  if dirty and noctalia.nowMs() - lastFlush >= FLUSH_MS then
    save()
  end
end

function M.flush()
  if dirty then
    save()
  end
end

function M.clear()
  data = { version = 1, days = {} }
  dirty = true
  save()
end

local function rangeStart(range)
  local now = os.time()
  if range == "today" then
    return today()
  elseif range == "yesterday" then
    return os.date("%Y-%m-%d", now - 86400)
  elseif range == "week" then
    local t = os.date("*t", now)
    local daysSinceMonday = (t.wday + 5) % 7
    return os.date("%Y-%m-%d", now - daysSinceMonday * 86400)
  elseif range == "month" then
    return os.date("%Y-%m-01", now)
  end
  return nil -- "all"
end

local function inRange(date, start)
  return start == nil or date >= start
end

local function sortedTop(counter)
  local entries = {}
  for key, count in pairs(counter) do
    entries[#entries + 1] = { key = key, count = count }
  end
  table.sort(entries, function(a, b)
    if a.count == b.count then
      return a.key < b.key
    end
    return a.count > b.count
  end)
  local top = {}
  for index = 1, math.min(TOP_LIMIT, #entries) do
    top[#top + 1] = entries[index]
  end
  return top
end

-- Aggregated snapshot for the panel. `range` is one of
-- today | yesterday | week | month | all.
function M.snapshot(range)
  range = range or "today"
  local start = rangeStart(range)

  local total = 0
  local keys = {}
  local shortcuts = {}

  for date, day in pairs(data.days) do
    local included = false
    if range == "yesterday" then
      included = date == start
    else
      included = inRange(date, start)
    end
    if included then
      total = total + (day.total or 0)
      for key, count in pairs(day.keys or {}) do
        keys[key] = (keys[key] or 0) + count
      end
      for shortcut, count in pairs(day.shortcuts or {}) do
        shortcuts[shortcut] = (shortcuts[shortcut] or 0) + count
      end
    end
  end

  return {
    range = range,
    total = total,
    topKeys = sortedTop(keys),
    topShortcuts = sortedTop(shortcuts),
    updatedAt = noctalia.nowMs(),
  }
end

return M
