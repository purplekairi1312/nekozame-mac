-- nekozame-mac: niri's shortcuts from nekozame os, on PaperWM (scrolling tiling
-- like niri). niri's Mod (Super) is Option here and niri's Alt is Cmd: on a PC
-- keyboard Option and Cmd sit where Super and Alt are, so the same keys do the
-- same things on both. Option+Shift+/ shows them all.
local MOD = "alt"
local function k(extra, key)
    local mods = { MOD }
    for _, m in ipairs(extra or {}) do table.insert(mods, m) end
    return { mods, key }
end

-- the hs command (the bar's space buttons use it)
require("hs.ipc")
hs.ipc.cliInstall("/opt/homebrew")

hs.loadSpoon("PaperWM")
local binds = {
    focus_left = k(nil, "h"), focus_right = k(nil, "l"), focus_up = k(nil, "k"), focus_down = k(nil, "j"),
    swap_left = k({ "shift" }, "h"), swap_right = k({ "shift" }, "l"),
    swap_up = k({ "shift" }, "k"), swap_down = k({ "shift" }, "j"),
    full_width = k(nil, "f"),                    -- niri: maximize-column
    cycle_width = k(nil, "r"),                   -- switch-preset-column-width
    cycle_height = k({ "shift" }, "r"),          -- switch-preset-window-height
    center_window = k(nil, "c"),                 -- center-column
    increase_width = k(nil, "="), decrease_width = k(nil, "-"),
    slurp_in = k(nil, "["), barf_out = k(nil, "]"),  -- consume / expel window
    toggle_stack = k(nil, "w"),                  -- toggle-column-tabbed-display
    toggle_floating = k({ "shift" }, "t"),
    focus_floating = k({ "shift" }, "v"),
    focus_window_first = k(nil, "home"), focus_window_last = k(nil, "end"),
    -- niri's workspaces go down/up; macOS spaces go right/left
    switch_space_r = k(nil, "u"), switch_space_l = k(nil, "i"),
    move_window_r = k({ "ctrl" }, "u"), move_window_l = k({ "ctrl" }, "i"),
}
for i = 1, 9 do
    binds["switch_space_" .. i] = k(nil, tostring(i))
    binds["move_window_" .. i] = k({ "shift" }, tostring(i))
end
spoon.PaperWM:bindHotkeys(binds)
-- arrows too, like niri
for key, act in pairs({ left = "focus_left", right = "focus_right", up = "focus_up", down = "focus_down" }) do
    hs.hotkey.bind({ MOD }, key, function() spoon.PaperWM.actions.actions()[act]() end)
end
for key, act in pairs({ left = "swap_left", right = "swap_right", up = "swap_up", down = "swap_down" }) do
    hs.hotkey.bind({ MOD, "shift" }, key, function() spoon.PaperWM.actions.actions()[act]() end)
end
spoon.PaperWM.window_gap = 10
spoon.PaperWM:start()

local function bind(mods, key, fn) hs.hotkey.bind(mods, key, fn) end
local function run(cmd, args) hs.task.new(cmd, nil, args or {}):start() end

-- terminal: a new ghostty window
local function terminal()
    local app = hs.application.get("com.mitchellh.ghostty")
    if app then app:selectMenuItem({ "File", "New Window" }) else hs.application.launchOrFocusByBundleID("com.mitchellh.ghostty") end
end
bind({ MOD }, "t", terminal)
bind({ MOD }, "return", terminal)
-- launcher: spotlight (Cmd+Space is spotlight anyway, niri's Alt+Space)
bind({ MOD }, "space", function() hs.eventtap.keyStroke({ "cmd" }, "space") end)
-- clipboard history: spotlight's
bind({ MOD }, "v", function() hs.eventtap.keyStroke({ "cmd" }, "space"); hs.timer.doAfter(0.3, function() hs.eventtap.keyStroke({ "cmd" }, "4") end) end)
bind({ MOD }, "q", function() local w = hs.window.focusedWindow(); if w then w:close() end end)
bind({ "cmd" }, "f4", function() local w = hs.window.focusedWindow(); if w then w:close() end end)
bind({ MOD, "shift" }, "f", function() local w = hs.window.focusedWindow(); if w then w:toggleFullScreen() end end)
-- overview: mission control
bind({ MOD }, "o", function() hs.spaces.toggleMissionControl() end)
bind({ MOD }, "tab", function() hs.spaces.toggleMissionControl() end)
bind({ MOD }, ",", function() hs.application.launchOrFocusByBundleID("com.apple.systempreferences") end)
bind({ MOD, "cmd" }, "l", function() hs.caffeinate.lockScreen() end)
bind({ "ctrl", "cmd" }, "delete", function() hs.application.launchOrFocusByBundleID("com.apple.ActivityMonitor") end)
bind({ MOD, "shift" }, "p", function() run("/usr/bin/pmset", { "displaysleepnow" }) end)
-- screenshots: Print is F13 on a PC keyboard plugged into a mac
bind({}, "f13", function() run("/usr/sbin/screencapture", { "-i", "-c" }) end)
bind({ "ctrl" }, "f13", function() run("/usr/sbin/screencapture", { "-c" }) end)
bind({ "cmd" }, "f13", function() run("/usr/sbin/screencapture", { "-i", "-w", "-c" }) end)

-- monitors: niri's Mod+Ctrl (focus) and Mod+Shift+Ctrl (move the window)
local function focusScreen(dir)
    local s = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local target = dir == "left" and s:toWest() or dir == "right" and s:toEast() or dir == "up" and s:toNorth() or s:toSouth()
    if not target then return end
    for _, w in ipairs(hs.window.orderedWindows()) do
        if w:screen() == target and w:isStandard() then w:focus(); return end
    end
end
for key, dir in pairs({ h = "left", l = "right", k = "up", j = "down", left = "left", right = "right" }) do
    bind({ MOD, "ctrl" }, key, function() focusScreen(dir) end)
    bind({ MOD, "shift", "ctrl" }, key, function()
        local w = hs.window.focusedWindow(); if not w then return end
        if dir == "left" then w:moveOneScreenWest() elseif dir == "right" then w:moveOneScreenEast()
        elseif dir == "up" then w:moveOneScreenNorth() else w:moveOneScreenSouth() end
    end)
end

-- power menu (niri: Mod+X), log out is in it too (niri: Mod+Shift+E)
local power = hs.chooser.new(function(c)
    if not c then return end
    ({ lock = hs.caffeinate.lockScreen, sleep = hs.caffeinate.systemSleep,
       logout = function() hs.caffeinate.logOut() end,
       restart = function() hs.caffeinate.restartSystem() end,
       shutdown = function() hs.caffeinate.shutdownSystem() end })[c.id]()
end)
power:choices({ { text = "Lock", id = "lock" }, { text = "Sleep", id = "sleep" }, { text = "Log out", id = "logout" },
                { text = "Restart", id = "restart" }, { text = "Shut down", id = "shutdown" } })
bind({ MOD }, "x", function() power:show() end)
bind({ MOD, "shift" }, "e", function() power:show() end)

-- the shortcuts, like niri's Mod+Shift+/
local help = [[
Option = niri's Mod (Super)       Cmd = niri's Alt
Option+T / Return   terminal      Option+Space   launcher
Option+Q            close         Option+Shift+F fullscreen
Option+H J K L      focus         Option+Shift+H J K L  move
Option+F            full width    Option+R / Shift+R  sizes
Option+- / =        narrower / wider     Option+C  center
Option+[ / ]        into / out of column Option+W  stack
Option+1-9          space         Option+Shift+1-9  move to space
Option+U / I        next / previous space (Ctrl: take window)
Option+Ctrl+H/L     other monitor (Shift: take window)
Option+O / Tab      overview      Option+X  power menu
Option+Cmd+L        lock          Option+V  clipboard history
Cmd+Tab             windows       F13 (Print)  screenshot
]]
bind({ MOD, "shift" }, "/", function() hs.alert.show(help, { textFont = "Hack Nerd Font Mono", textSize = 15,
    fillColor = { hex = "#5a4f6e", alpha = 0.97 }, strokeColor = { hex = "#ffc0e5" }, textColor = { hex = "#ffffff" } }, 8) end)

hs.alert.defaultStyle.fillColor = { hex = "#5a4f6e", alpha = 0.95 }
hs.alert.defaultStyle.strokeColor = { hex = "#ffc0e5" }
