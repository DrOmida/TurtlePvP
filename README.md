# TurtlePvP

A versatile PvP utility suite tailored for Turtle WoW, providing an intelligent HUD, passive enemy tracking, and rapid tactical reporting across Warsong Gulch and Custom Arenas.

## Features

### 🏴 Warsong Gulch Flag Tracker
- Live HUD displaying the HP and distance to both Flag Carriers.
- Automatic `/bg` callouts when the enemy FC's health hits 75%, 50%, and 25%.
- Zero-config auto-recovery via passive buffs — picks up missed carriers automatically.

### ⚔️ Arena Enemy Tracker HUD
Automatically activates in Turtle WoW's custom arena zones (The Blood Arena, Lordaeron Arena, Sunstrider Court, The Blood Ring).

- Passively discovers enemies from targets, mouseovers, and combat log events — no targeting required.
- Displays up to 8 enemies simultaneously with:
  - Name in class colour
  - Distance colour-coded by range (red ≤20y, yellow ≤40y, white beyond)
  - HP bar that shifts green → yellow → red
  - Trinket indicator — green when available, turns red for 2 minutes after use. Detects all PvP trinkets and racial abilities (Will of the Forsaken, Stoneform, Escape Artist, Perception, Berserking, Blood Fury, War Stomp, Shadowmeld).
  - Cast bar on line 2 of each row showing the spell being cast with a live countdown timer. Channeled spells (Drain Life, Mind Flay, Arcane Missiles, etc.) show an orange pulsing bar instead.
  - Target indicator on line 2, positioned under the name and stopping at the HP bar's left edge. Colour-coded: red background if they are targeting you, orange if targeting a teammate, blue if targeting someone else.
- Dynamic HUD width — automatically resizes the frame to fit the longest enemy name, keeping the layout compact.
- Pull timer — when the arena announces "Fifteen seconds until the battle begins!", automatically triggers `/pull 15` via DBM or BigWigs if installed (with party leader check), or sends a party message as fallback.
- Totem and pet filtering — only real players are tracked. Shaman totems, hunter pets, warlock minions, and druid treants are blocked by both name pattern matching and unit player verification.

### 📍 EFC Location Reporter
- A dedicated grid of 23 location buttons tailored to Warsong Gulch.
- Click a location button to instantly announce the enemy flag carrier's position in Battleground chat (automatically uses Common or Orcish depending on your faction).
- Displays a live Nampower-driven HP bar of the EFC inside the reporter frame.

### ⚙️ Config Panel
- Fast, modular interface. Click the minimap button or use slash commands to toggle features independently.

---

## Requirements

To unlock the full power of TurtlePvP, install these optional dependencies:

| Dependency | What it unlocks |
|------------|-----------------|
| **[Nampower](https://twinstar-addons.github.io/addons/nampower/)** | Accurate HP values and GUIDs for enemies behind objects or out of range |
| **[UnitXP](https://github.com/allfoxwy/UnitXP)** | Precise 3D distance between you and carriers/arena enemies |

*The addon works without both, but HP and distance readouts will be limited to whoever you currently have targeted.*

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/tpvp` or `/turtlepvp` | Open the Config Panel |
| `/tpvp force wsg` | Force WSG mode (for testing outside battlegrounds) |
| `/tpvp force arena` | Force Arena mode (for testing outside arenas) |
| `/tpvp force efc` | Force toggle the EFC Location Map |
| `/tpvp test wsg` | Populate the WSG Flag HUD with fake test carriers |
| `/tpvp reset` | Reset all frame positions to defaults |
| `/tpvp status` | Print module and dependency status to chat |
| `/tpvp debug on/off` | Toggle internal debug output |

---

## Moving Frames

Click and drag the **Flag Tracking HUD**, **Arena Enemies HUD**, and **EFC Reporter Grid** anywhere on screen. Positions are saved automatically to your character's `TurtlePvPConfig`. Right-click the title bar of the Arena HUD to lock/unlock it.

---

## Arena HUD — How It Works

### Enemy Discovery
Enemies are discovered passively through:
- **Unit token scan every 0.5 seconds** — checks `target`, `mouseover`, and `targettarget`. Only names that pass `UnitIsPlayer()` are accepted, which blocks all totems and pets at the source.
- **Combat log events** — eight `HOSTILEPLAYER` event types are monitored. A name from the combat log is only added if it was already confirmed as a real player by the unit token scan, preventing any totem or pet from slipping through.

### Trinket Detection
Detected via the exact spell names that appear in `CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF` messages. The 2-minute cooldown resets automatically. A chat alert prints when a trinket or racial is used.

### Cast Bar
Cast times are sourced from a hardcoded table of 1.12 spell data covering all nine classes. Channeled spells (Drain Life, Mind Flay, Blizzard, Hurricane, etc.) display differently — a full orange bar — and clear when the enemy takes another action. Unknown spells fall back to a 3-second estimate.

### Target Tracking
The addon reads `targettarget` each scan cycle to capture who your current target is targeting. The last known target is kept until a fresh read updates it.

---

## Credits & Thanks
- Included `v3.1 EFC Reporter` based on the original EFCReport concept by **Cubenicke (Yrrol@vanillagaming)**.
- Original map positioning layout and location icons by **lanevegame**.
- Arena enemy detection approach inspired by enemyFrames by **zetone/byCFM2**.