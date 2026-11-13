-- nekozame-mac: PaperWM, scrolling tiling, with the same window keys as AeroSpace. waits for hammerspoon to read macOS 27's spaces properly
-- (github.com/Hammerspoon/hammerspoon/issues/3897); until then AeroSpace does the
-- windows. to use it: echo paperwm > ~/.config/nekozame/wm, quit aerospace, reload
local WIN = { "ctrl", "alt" }
local function bind(mods, key, fn) hs.hotkey.bind(mods, key, fn) end
local function focused(fn) return function() local win = hs.window.focusedWindow(); if win then fn(win) end end end
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
-- spaces 1-9: Option+number, Shift to take the window
for i = 1, 9 do
    binds["switch_space_" .. i] = { { "alt" }, tostring(i) }
    binds["move_window_" .. i] = { { "alt", "shift" }, tostring(i) }
end
spoon.PaperWM:bindHotkeys(binds)
spoon.PaperWM.window_gap = 10
-- room for the bar (46px, over the macOS menu bar)
spoon.PaperWM.external_bar = { top = 46 }
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
