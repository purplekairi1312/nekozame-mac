"""Heroic Games Launcher in nekozame: the theme in its custom themes folder (yours if you set one),
and picked when Heroic is on its default theme; a theme you picked stays.
  python3 apply.py HEROIC_CONFIG_DIR NEKOZAME_CSS
(the same as nekozame os does it, in nekozame-apps-theme)"""
import json, os, shutil, sys
conf, css = sys.argv[1:]
def load(p):
    try:
        return json.load(open(p))
    except (OSError, ValueError):
        return {}
def save(p, d):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p + ".new", "w") as f:
        json.dump(d, f, indent=2)
    os.replace(p + ".new", p)
settings = load(os.path.join(conf, "config.json"))
default = settings.setdefault("defaultSettings", {})
folder = default.get("customThemesPath") or os.path.join(conf, "themes")
target = os.path.join(folder, "nekozame.css")
if os.path.exists(target) and "nekozame for Heroic" not in open(target, errors="replace").read():
    print(f"  · {target} is yours, kept")
else:
    os.makedirs(folder, exist_ok=True)
    shutil.copy(css, target)
if not default.get("customThemesPath") and os.path.exists(os.path.join(conf, "config.json")):  # (heroic writes the rest itself)
    default["customThemesPath"] = folder
    save(os.path.join(conf, "config.json"), settings)
store = os.path.join(conf, "store/config.json")
s = load(store)
if s.get("theme", "midnightMirage") == "midnightMirage":
    s["theme"] = "nekozame.css"  # a custom theme goes by its file
    save(store, s)
    print("  ✓ heroic, in nekozame")
elif s.get("theme") == "nekozame.css":
    print("  ✓ heroic, in nekozame")
else:
    print("  ✓ heroic: nekozame is in its themes (Settings → Accessibility → Select theme)")
