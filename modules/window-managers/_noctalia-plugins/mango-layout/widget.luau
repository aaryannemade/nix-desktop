-- Noctalia bar widget: shows the MangoWM layout of the monitor this bar lives on.
-- Driven by `mmsg watch all-monitors`, which emits one JSON line per change, so
-- the widget updates instantly when switch_layout (Super+Alt+Space) is used.

local MMSG = "@mmsg@"

-- symbol -> { label, tabler glyph } (symbols from mango src/layout/layout.h)
local LAYOUTS = {
  T = { "Tile", "layout-sidebar" },
  S = { "Scroller", "carousel-horizontal" },
  G = { "Grid", "layout-grid" },
  M = { "Monocle", "app-window" },
  K = { "Deck", "layout-cards" },
  CT = { "Center Tile", "layout-columns" },
  RT = { "Right Tile", "layout-sidebar-right" },
  VS = { "Vertical Scroller", "carousel-vertical" },
  VT = { "Vertical Tile", "layout-navbar" },
  VG = { "Vertical Grid", "layout-grid" },
  VK = { "Vertical Deck", "layout-cards" },
  DW = { "Dwindle", "layout-dashboard" },
  F = { "Fair", "layout-2" },
  VF = { "Vertical Fair", "layout-2" },
}

local lastSymbol = nil
local lastMonitors = nil

-- barWidget.outputName() only works in host-driven calls (load, update, clicks):
-- runStream callbacks run without the widget snapshot, so it returns nil there.
-- Cache it while it's available and use the cached value in the stream callback.
local outputName = barWidget.outputName()

local function refreshOutputName()
  local name = barWidget.outputName()
  if name ~= nil and name ~= "" then
    outputName = name
  end
end

local function pickMonitor(monitors)
  if outputName ~= nil then
    for _, mon in ipairs(monitors) do
      if mon.name == outputName then
        return mon
      end
    end
  end
  -- Output name unknown (or not reported by mango): fall back to the focused monitor.
  for _, mon in ipairs(monitors) do
    if mon.active then
      return mon
    end
  end
  return monitors[1]
end

local function render(symbol)
  if symbol == nil or symbol == lastSymbol then
    return
  end
  lastSymbol = symbol
  local info = LAYOUTS[symbol] or { symbol, "layout" }
  barWidget.setGlyph(info[2])
  barWidget.setText(info[1])
  barWidget.setTooltip("Layout: " .. info[1] .. "\nClick or Super+Alt+Space to cycle")
end

local function handleLine(line)
  local ok, data = pcall(noctalia.json.decode, line)
  if not ok or type(data) ~= "table" or type(data.monitors) ~= "table" then
    return
  end
  lastMonitors = data.monitors
  local mon = pickMonitor(data.monitors)
  if mon ~= nil then
    render(mon.layout_symbol)
  end
end

-- Restart the watcher if mango's IPC drops (e.g. compositor reload).
noctalia.runStream("while :; do " .. MMSG .. " watch all-monitors; sleep 1; done", handleLine)

-- Host-driven (has the snapshot): keep the cached output name fresh and re-render
-- in case stream data arrived before the name was known.
function update()
  refreshOutputName()
  if lastMonitors ~= nil then
    local mon = pickMonitor(lastMonitors)
    if mon ~= nil then
      render(mon.layout_symbol)
    end
  end
end

function onClick()
  refreshOutputName()
  -- Focus this bar's monitor first so the click cycles *its* layout.
  if outputName ~= nil then
    noctalia.runAsync(MMSG .. " dispatch focusmon," .. outputName .. " && " .. MMSG .. " dispatch switch_layout")
  else
    noctalia.runAsync(MMSG .. " dispatch switch_layout")
  end
end
