# nekozame-mac

macOS as close to [nekozame os](https://git.sr.ht/~purplekairi1312/nekozame-os) as it gets, for when you're on a Mac too.

- [PaperWM](https://github.com/mogenson/PaperWM.spoon) for scrolling tiling like niri, with niri's shortcuts from nekozame os, so the same keys work on both. Option is niri's Mod (Super) and Cmd is niri's Alt, since that's where they sit on a PC keyboard. Option+Shift+/ shows them all
- A [SketchyBar](https://github.com/FelixKratz/SketchyBar) bar like DankMaterialShell's: spaces, the focused app, what's playing, volume and the clock
- The animated catshark wallpaper, sharp on any screen shape <3
- The [nekozame theme](https://git.sr.ht/~purplekairi1312/nekozame-theme) in Ghostty, Emacs, cava and btop, and fastfetch with the bubble logo
- Zen with the same privacy setup as nekozame os: Dark Reader, uBlock Origin, Privacy Badger, LibRedirect, ClearURLs, Consent-O-Matic and [nekojs](https://git.sr.ht/~purplekairi1312/nekojs), DuckDuckGo, HTTPS-only, no telemetry, no WebRTC leaks (Helium optional, with the same)
- Doom Emacs as `$EDITOR`, always running as a daemon (evil mode or another editor if you want)
- Tailscale and Moonlight, to reach your nekozame os machines
- Music production on request: Bitwig, Reaper, LMMS and free plugins

## Install

Needs [Homebrew](https://brew.sh).

```sh
git clone https://git.sr.ht/~purplekairi1312/nekozame-mac ~/.local/share/nekozame-mac
~/.local/share/nekozame-mac/setup.sh
```

It asks about the optional bits, and keeps your own configs where you have them. Run it again to update. Then give Hammerspoon Accessibility access (System Settings → Privacy & Security), and log out and back in once.

## License

GPL-3.0-or-later. The wallpaper and logo are nekozame os art, CC BY-NC-SA 4.0, downloaded from there when you install.
