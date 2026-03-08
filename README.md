# <span style="color:#00ff7f">Turtle</span>PvP

A versatile PvP utility suite tailored for Turtle WoW, providing an intelligent HUD, passive enemy tracking, and rapid tactical reporting across Warsong Gulch and Custom Arenas.

> **Author:** Adimo @ Tel'abim  
> **Version:** 3.2  
> **GitHub:** https://github.com/DrOmida/WSGFlagCaller

---

## Features

### 🏴 Warsong Gulch Flag Tracker
- Live HUD displaying the HP and distance to both Flag Carriers.
- Automatic `/bg` callouts when the enemy FC's health hits **75%, 50%, and 25%**.
- Zero-config auto-recovery via passive buffs — picks up missed carriers automatically.
- Anti-spam sync via Addon Messages — only one player calls out at a time, Adimo gets priority.
- Silenced automatically when under **Curse of Tongues**.

### 📍 EFC Location Reporter
- A dedicated grid of **23 location buttons** tailored to Warsong Gulch.
- Click a location button to instantly announce the EFC position in Battleground chat.
- Automatically uses **Common** (Alliance) or **Orcish** (Horde) depending on your faction.
- Auto-shows when you enter Warsong Gulch (can be disabled in Settings).

### ⚔️ Arena Enemy Tracker HUD
Automatically activates in Turtle WoW's custom arena zones (Blood Arena, Lordaeron Arena, Sunstrider Court, Blood Ring).

- Passively discovers enemies from targets, mouseovers, and combat log events — no targeting required.
- Displays up to 8 enemies simultaneously with:
  - Name in **class colour**
  - **Distance** colour-coded by range (green ≤20y, yellow ≤40y, white beyond) — requires UnitXP
  - **HP bar** that shifts green → yellow → red
  - **Trinket indicator** — green when available, turns red for 2 minutes after use. Detects all PvP trinkets and racial abilities (Will of the Forsaken, Stoneform, Escape Artist, Berserking, Blood Fury, War Stomp, Shadowmeld).
  - **Cast bar** with a live countdown timer. Channeled spells show a pulsed orange bar.
  - **Target indicator** — red if targeting you, orange if targeting a teammate, blue if targeting someone else.
- Dynamic HUD width — resizes to fit the longest enemy name.
- Pull timer — when the arena announces "Fifteen seconds until the battle begins!", automatically triggers `/pull 15`.
- Totem and pet filtering — only real players are tracked.

### 🖱️ Minimap Button
- Sits on the Minimap ring (just like standard WoW addon buttons).
- Shows the **Alliance or Horde PvP banner** depending on your faction.
- **Click** to open the Settings panel.
- **Drag** to reposition it around the Minimap edge. Position is saved between sessions.

### ⚙️ Settings Panel
- Tabbed interface: **Settings** tab and **Credits** tab.
- Toggle individual features: WSG tracking, HP callouts, Flag Tracker HUD, EFC map, Arena HUD, distance, trinkets.
- **Test WSG HUD** and **Test Arena HUD** buttons to preview HUDs outside of PvP zones.
- **Reset Pos.** button resets all windows and the minimap button to their default positions.
- **Right-click any HUD** to lock or unlock its position (prevents accidental dragging).

---

## How It Works

### Starting Up
Load into the game — the addon initialises automatically. The minimap button appears on your minimap ring after login.

### Warsong Gulch
The WSG Flag Tracker activates automatically when you enter Warsong Gulch. It scans combat logs, buffs, and nearby unit tooltips to identify who is carrying the flag. The EFC Reporter grid also opens (if enabled), allowing you to call the EFC's location with a single click.

### Arena
The Arena HUD activates automatically when you enter a recognised arena zone. It passively builds a list of enemies from your targets, mouseovers, and combat events without you needing to interact with it.

### Locking / Unlocking Windows
All three HUD windows (WSG Flag Caller, Arena Enemy HUD, EFC Location Map) can be locked to prevent accidental dragging. **Right-click anywhere on a HUD** to toggle its lock state. An unlocked HUD shows a subtle green tint while being draggable.

---

## Requirements

To unlock the full power of TurtlePvP, install these optional dependencies:

| Dependency | What it unlocks |
|------------|-----------------|
| **[Nampower](https://twinstar-addons.github.io/addons/nampower/)** | Accurate HP values for enemies out of range or behind objects |
| **[UnitXP](https://github.com/allfoxwy/UnitXP)** | Precise 3D distance between you and carriers / arena enemies |

*The addon works without both, but HP and distance readouts will be limited to whoever you currently have targeted.*

---

## Slash Commands

Only the essential debug and override commands remain — everything else is controlled through the **Settings panel** (minimap button or `/tpvp`).

| Command | Description |
|---------|-------------|
| `/tpvp` or `/turtlepvp` | Open / close the Settings panel |
| `/tpvp reset` | Reset all frame positions to defaults |
| `/tpvp status` | Print module and dependency status to chat |
| `/tpvp debug on/off` | Toggle internal debug output |

---

## Credits & Thanks
- EFC Reporter based on the original concept by **Cubenicke (Yrrol@vanillagaming)**.
- Original map positioning layout and location icons by **lanevegame**.
- Arena enemy detection approach inspired by enemyFrames by **zetone/byCFM2**.