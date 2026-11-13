-- nekozame-mac: the nekozame os shortcuts that aren't the window manager's.
--   Cmd          apps, like Super in nekozame os: macOS's own Cmd+C/V/X/Q..., plus
--                Cmd+Return terminal, Cmd+E files, Cmd+Shift+E yazi, Cmd+B browser
--   Ctrl+Option  windows, like Ctrl+Alt in nekozame os: AeroSpace (aerospace.toml),
--                or PaperWM (paperwm.lua) once hammerspoon can read macOS 27's
--                spaces: echo paperwm > ~/.config/nekozame/wm
-- Cmd+Shift+/ shows them all.

-- the hs command (the bar uses it)
require("hs.ipc")
if not hs.ipc.cliStatus("/opt/homebrew") then hs.ipc.cliInstall("/opt/homebrew") end

local HERE = debug.getinfo(1, "S").source:match("^@(.*/)")
local f = io.open(os.getenv("HOME") .. "/.config/nekozame/wm")
local WM = f and f:read("l") or "aerospace"
if f then f:close() end

local WIN = { "ctrl", "alt" }
local function bind(mods, key, fn) hs.hotkey.bind(mods, key, fn) end
local function run(cmd, args) hs.task.new(cmd, nil, args or {}):start() end

if WM == "paperwm" then dofile(HERE .. "paperwm.lua") end

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
  Return              fullscreen in place (+ Shift: macOS fullscreen)
  - / =               narrower / wider      R  even sizes
  [ / ]               join the window left / right
  W                   stack like tabs       Space  float
  C                   side by side / on top of each other
  Page Up / Down      prev / next workspace
  + Cmd + arrows      other monitor (+ Shift: take the window)
  Delete              power menu

workspaces: Option+1-9 (Alt+1-9 in nekozame os), + Shift takes the window

mouse: drag a window's edge to resize, its neighbours follow
]]
bind({ "cmd", "shift" }, "/", function() hs.alert.show(help, { textFont = "Hack Nerd Font Mono", textSize = 15,
    fillColor = { hex = "#5a4f6e", alpha = 0.97 }, strokeColor = { hex = "#ffc0e5" }, textColor = { hex = "#ffffff" } }, 10) end)

hs.alert.defaultStyle.fillColor = { hex = "#5a4f6e", alpha = 0.95 }
hs.alert.defaultStyle.strokeColor = { hex = "#ffc0e5" }
