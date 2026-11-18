"""nekozame-mac's emulation: each emulator pointed at your library and at ~/Emulation/saves,
the folder nekozame-saves syncs, the same layout as nekozame os. Only these settings are
set, the rest stay yours; each file is backed up once first (.before-nekozame).

  python3 configure.py LIBRARY     LIBRARY: the folder with roms/ and bios/
"""
import configparser
import os
import re
import shutil
import sys

HOME = os.path.expanduser("~")
SUPPORT = os.path.join(HOME, "Library/Application Support")
SAVES = os.path.join(HOME, "Emulation/saves")


def ok(msg):
    print(f"  ✓ {msg}")


def backup(path):
    if os.path.exists(path) and not os.path.exists(path + ".before-nekozame"):
        shutil.copy2(path, path + ".before-nekozame")


def set_ini(path, section, values):
    """an ini's keys set in a section, everything else as it was (case kept)"""
    backup(path)
    c = configparser.RawConfigParser(strict=False, interpolation=None)
    c.optionxform = str
    if os.path.exists(path):
        c.read(path, encoding="utf-8")
    if not c.has_section(section):
        c.add_section(section)
    for k, v in values.items():
        c.set(section, k, v)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".new", "w", encoding="utf-8") as f:
        c.write(f, space_around_delimiters=True)
    os.replace(path + ".new", path)


def set_cfg(path, values):
    """retroarch's key = "value" lines: these set, the rest as it was"""
    backup(path)
    text = open(path, errors="replace").read() if os.path.exists(path) else ""
    for k, v in values.items():
        text = re.sub(rf"^{re.escape(k)} = .*\n?", "", text, flags=re.M)
    text = text.rstrip("\n") + ("\n" if text.strip() else "")
    text += "".join(f'{k} = "{v}"\n' for k, v in values.items())
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write(text)


def link(name, there):
    """~/Emulation/saves/NAME -> where the emulator keeps them, unless something's there"""
    here = os.path.join(SAVES, name)
    if os.path.lexists(here):
        return
    os.makedirs(there, exist_ok=True)
    os.makedirs(os.path.dirname(here), exist_ok=True)
    os.symlink(there, here)


def ppsspp_stick():
    """PPSSPP's memory stick folder on macOS: wherever it already is, or its default"""
    for d in (os.path.join(HOME, "Documents/PPSSPP"), os.path.join(SUPPORT, "PPSSPP"), os.path.join(HOME, ".config/ppsspp")):
        if os.path.isdir(os.path.join(d, "PSP")):
            return d
    return os.path.join(HOME, "Documents/PPSSPP")


def main(lib):
    roms, bios = os.path.join(lib, "roms"), os.path.join(lib, "bios")
    if os.path.isdir("/Applications/RetroArch.app"):
        set_cfg(os.path.join(SUPPORT, "RetroArch/config/retroarch.cfg"),
                {"system_directory": bios, "rgui_browser_directory": roms})
        ok("RetroArch: BIOS files and games from the library (its saves: its own Cloud Sync)")
    if os.path.isdir("/Applications/PCSX2.app"):
        for d in ("saves", "states"):
            os.makedirs(os.path.join(SAVES, "pcsx2", d), exist_ok=True)
        ini = os.path.join(SUPPORT, "PCSX2/inis/PCSX2.ini")
        set_ini(ini, "Folders", {"Bios": bios, "MemoryCards": f"{SAVES}/pcsx2/saves", "SaveStates": f"{SAVES}/pcsx2/states"})
        set_ini(ini, "GameList", {"RecursivePaths": os.path.join(roms, "ps2")})
        set_ini(ini, "UI", {"SetupWizardIncomplete": "false"})
        ok("PCSX2: BIOS, games, memory cards and save states")
    if os.path.isdir("/Applications/Dolphin.app"):
        base = os.path.join(SUPPORT, "Dolphin")
        set_ini(os.path.join(base, "Config/Dolphin.ini"), "General",
                {"ISOPaths": "2", "ISOPath0": os.path.join(roms, "gc"), "ISOPath1": os.path.join(roms, "wii")})
        for d in ("GC", "Wii", "StateSaves"):
            link(f"dolphin/{d}", os.path.join(base, d))
        ok("Dolphin: GameCube and Wii games, and its saves")
    if os.path.isdir("/Applications/PPSSPP.app"):
        stick = ppsspp_stick()
        set_ini(os.path.join(stick, "PSP/SYSTEM/ppsspp.ini"), "General", {"CurrentDirectory": os.path.join(roms, "psp")})
        link("ppsspp/saves", os.path.join(stick, "PSP/SAVEDATA"))
        link("ppsspp/states", os.path.join(stick, "PSP/PPSSPP_STATE"))
        ok("PPSSPP: games, saves and save states")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
