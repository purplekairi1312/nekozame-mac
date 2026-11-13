-- nekozame-mac: the nekozame os shortcuts, on PaperWM (scrolling tiling like niri).
--   Cmd          apps, like Super in nekozame os: macOS's own Cmd+C/V/X/Q..., plus
--                Cmd+Return terminal, Cmd+E files, Cmd+Shift+E yazi, Cmd+B browser
--   Ctrl+Option  windows, like Ctrl+Alt in nekozame os: focus, move, size, spaces
-- the mouse: Ctrl+Cmd+drag moves a window, Ctrl+Option+drag slides the row.
-- Cmd+Shift+/ shows them all.

-- the hs command (the bar's space buttons use it)
require("hs.ipc")
hs.ipc.cliInstall("/opt/homebrew")

local WIN = { "ctrl", "alt" }
local function w(extra, key)
    local mods = { table.unpack(WIN) }
    for _, m in ipairs(extra or {}) do table.insert(mods, m) end
    return { mods, key }
end

hs.loadSpoon("PaperWM")
local binds = {
    focus_left = w(nil, "left"), focus_right = w(nil, "right"), focus_up = w(nil, "up"), focus_down = w(nil, "down"),
    swap_left = w({ "shift" }, "left"), swap_right = w({ "shift" }, "right"),
    swap_up = w({ "shift" }, "up"), swap_down = w({ "shift" }, "down"),
    focus_window_first = w(nil, "home"), focus_window_last = w(nil, "end"),
    full_width = w(nil, "return"),               -- niri: maximize-column
    cycle_width = w(nil, "r"),                   -- switch-preset-column-width
    cycle_height = w({ "shift" }, "r"),          -- switch-preset-window-height
    decrease_width = w(nil, "-"), increase_width = w(nil, "="),
    center_window = w(nil, "c"),
    slurp_in = w(nil, "["), barf_out = w(nil, "]"),  -- consume / expel window
    toggle_stack = w(nil, "w"),                  -- tabbed column
    toggle_floating = w(nil, "space"),
    focus_floating = w({ "shift" }, "space"),
    -- niri's workspaces go down/up; macOS spaces go right/left
    switch_space_r = w(nil, "pagedown"), switch_space_l = w(nil, "pageup"),
    move_window_r = w({ "shift" }, "pagedown"), move_window_l = w({ "shift" }, "pageup"),
}
-- spaces 1-9: Option+number (Alt+number in nekozame os), Shift to take the window
for i = 1, 9 do
    binds["switch_space_" .. i] = { { "alt" }, tostring(i) }
    binds["move_window_" .. i] = { { "alt", "shift" }, tostring(i) }
end
spoon.PaperWM:bindHotkeys(binds)
spoon.PaperWM.window_gap = 10
-- room for the bar: 34px tall, 6px down from the very top of the screen
spoon.PaperWM.external_bar = { top = 40 }
-- the mouse: Ctrl+Cmd+drag picks a window up and drops it in a new spot (niri's
-- Super+drag); Ctrl+Option+drag slides the whole row. Cmd+click stays the apps'
spoon.PaperWM.lift_window = { "ctrl", "cmd" }
spoon.PaperWM.drag_window = { "ctrl", "alt" }
spoon.PaperWM.scroll_window = { "ctrl", "alt" }   -- Ctrl+Option+scroll slides the row
-- like niri: new windows take half the screen, side by side; Ctrl+Option+R cycles
-- a third, a half, two thirds
spoon.PaperWM.default_width = 0.5
spoon.PaperWM.window_ratios = { 1 / 3, 1 / 2, 2 / 3 }
-- not windows to tile: menu bar apps, popups
local filter = spoon.PaperWM.window_filter
for _, app in ipairs({ "Tailscale", "Hammerspoon", "System Settings", "Activity Monitor" }) do filter:rejectApp(app) end
filter:setAppFilter("Zen", { rejectTitles = { "^Extension:" } })
spoon.PaperWM:start()

local function bind(mods, key, fn) hs.hotkey.bind(mods, key, fn) end
local function run(cmd, args) hs.task.new(cmd, nil, args or {}):start() end
local function focused(fn) return function() local win = hs.window.focusedWindow(); if win then fn(win) end end end

-- === apps (Cmd) ===
local GHOSTTY = "com.mitchellh.ghostty"
local function terminal()
    local app = hs.application.get(GHOSTTY)
    if app then app:selectMenuItem({ "File", "New Window" }) else hs.application.launchOrFocusByBundleID(GHOSTTY) end
end
bind({ "cmd" }, "return", terminal)
bind({ "cmd" }, "e", function() run("/usr/bin/open", { os.getenv("HOME") }) end)        -- Finder
bind({ "cmd", "shift" }, "e", function() run("/usr/bin/open", { "-na", "Ghostty", "--args", "-e", "yazi" }) end)
bind({ "cmd" }, "b", function() hs.application.launchOrFocusByBundleID("app.zen-browser.zen") end)
-- (Cmd+Space spotlight, Cmd+Q quit, Cmd+Tab, Ctrl+Cmd+Q lock, Cmd+Shift+Q log out,
-- Cmd+Option+Esc force quit, Cmd+Shift+3/4/5 screenshots: macOS's own, and the
-- same keys in nekozame os)
-- screenshots on a PC keyboard: Print is F13 on a mac
bind({}, "f13", function() run("/usr/sbin/screencapture", { "-i", "-c" }) end)
bind({ "ctrl" }, "f13", function() run("/usr/sbin/screencapture", { "-c" }) end)
bind({ "alt" }, "f13", function() run("/usr/sbin/screencapture", { "-i", "-w", "-c" }) end)

-- === windows (Ctrl+Option) ===
bind(WIN, "q", focused(function(win) win:close() end))
bind({ "ctrl", "alt", "shift" }, "return", focused(function(win) win:toggleFullScreen() end))
bind(WIN, "o", function() hs.spaces.toggleMissionControl() end)  -- overview

-- monitors: add Cmd (focus), and Shift (take the window)
local function focusScreen(dir)
    local s = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local target = ({ left = s.toWest, right = s.toEast, up = s.toNorth, down = s.toSouth })[dir](s)
    if not target then return end
    for _, win in ipairs(hs.window.orderedWindows()) do
        if win:screen() == target and win:isStandard() then win:focus(); return end
    end
end
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind({ "ctrl", "alt", "cmd" }, dir, function() focusScreen(dir) end)
    bind({ "ctrl", "alt", "cmd", "shift" }, dir, focused(function(win)
        ({ left = win.moveOneScreenWest, right = win.moveOneScreenEast,
           up = win.moveOneScreenNorth, down = win.moveOneScreenSouth })[dir](win)
    end))
end

-- power menu: Ctrl+Option+Delete (Ctrl+Alt+Delete in nekozame os)
local power = hs.chooser.new(function(c)
    if not c then return end
    ({ lock = hs.caffeinate.lockScreen, sleep = hs.caffeinate.systemSleep,
       logout = function() hs.caffeinate.logOut() end,
       restart = function() hs.caffeinate.restartSystem() end,
       shutdown = function() hs.caffeinate.shutdownSystem() end })[c.id]()
end)
power:choices({ { text = "Lock", id = "lock" }, { text = "Sleep", id = "sleep" }, { text = "Log out", id = "logout" },
                { text = "Restart", id = "restart" }, { text = "Shut down", id = "shutdown" } })
bind(WIN, "forwarddelete", function() power:show() end)
bind(WIN, "delete", function() power:show() end)

-- dragging a tiled window by its title bar: PaperWM would keep pulling it back,
-- so it lets go while the window moves and tiles it where it's dropped (like niri).
-- the app still gets every click; this only looks around once a drag starts
local T = hs.eventtap.event.types
local drag = nil  -- { start = point, win = window, floated = bool }
-- (global: a local one gets garbage-collected and stops)
nekozameDragTap = hs.eventtap.new({ T.leftMouseDown, T.leftMouseDragged, T.leftMouseUp }, function(e)
    local t = e:getType()
    if t == T.leftMouseDown then
        drag = { start = e:location() }
    elseif t == T.leftMouseDragged and drag and not drag.floated then
        if drag.win == nil then
            drag.win = false
            for _, win in ipairs(hs.window.orderedWindows()) do
                if hs.geometry(drag.start):inside(win:frame()) then
                    if spoon.PaperWM.state.windowIndex(win) then drag.win = win; drag.frame = win:frame() end
                    break
                end
            end
        end
        if drag.win then
            local f = drag.win:frame()
            if f.x ~= drag.frame.x or f.y ~= drag.frame.y then  -- macOS is moving it: the title bar
                spoon.PaperWM.floating.toggleFloating(drag.win)
                drag.floated = true
            end
        end
    elseif t == T.leftMouseUp and drag then
        if drag.floated then
            local win = drag.win
            hs.timer.doAfter(0.05, function() spoon.PaperWM.floating.toggleFloating(win) end)
        end
        drag = nil
    end
    return false
end)
nekozameDragTap:start()

-- the focused app's menus (File, Edit...), from the bar: click its name there
function nekozameAppMenu()
    local app = hs.application.frontmostApplication()
    local function convert(items, path)
        local out = {}
        for _, it in ipairs(items or {}) do
            local title = it.AXTitle or ""
            if title == "" then
                table.insert(out, { title = "-" })
            else
                local p = { table.unpack(path) }; table.insert(p, title)
                local entry = { title = title, disabled = it.AXEnabled == false }
                local kids = it.AXChildren and it.AXChildren[1]
                if kids and #kids > 0 then entry.menu = convert(kids, p)
                else entry.fn = function() app:selectMenuItem(p) end end
                table.insert(out, entry)
            end
        end
        return out
    end
    local menu = convert(app:getMenuItems(), {})
    table.remove(menu, 1)  -- the Apple menu
    local m = hs.menubar.new(false)
    m:setMenu(menu)
    m:popupMenu(hs.mouse.absolutePosition(), true)
end

-- the shortcuts, like Super+Shift+/ in nekozame os
local help = [[
apps: Cmd (Super in nekozame os)
  Cmd+C / V / X       copy / paste / cut
  Cmd+Q               quit          Cmd+Space   launcher
  Cmd+Return          terminal      Cmd+B       browser
  Cmd+E / Shift+E     files / yazi
  Ctrl+Cmd+Q          lock          Cmd+Shift+3/4/5  screenshot

windows: Ctrl+Option (Ctrl+Alt in nekozame os)
  arrows              focus         + Shift     move
  Return              maximize      + Shift     fullscreen
  R / Shift+R         sizes         - / =       narrower / wider
  C                   center        [ / ]       into / out of column
  W                   stack         Space       float
  Option+1-9          space         + Shift     move to space
  Page Up / Down      prev / next space
  + Cmd + arrows      other monitor
  O                   overview      Delete      power menu

mouse
  Ctrl+Cmd+drag       move a window (Super+drag in nekozame os)
  Ctrl+Option+drag    slide the row (or Ctrl+Option+scroll)
  title bar drag      drop the window in a new spot
]]
bind({ "cmd", "shift" }, "/", function() hs.alert.show(help, { textFont = "Hack Nerd Font Mono", textSize = 15,
    fillColor = { hex = "#5a4f6e", alpha = 0.97 }, strokeColor = { hex = "#ffc0e5" }, textColor = { hex = "#ffffff" } }, 10) end)

hs.alert.defaultStyle.fillColor = { hex = "#5a4f6e", alpha = 0.95 }
hs.alert.defaultStyle.strokeColor = { hex = "#ffc0e5" }
