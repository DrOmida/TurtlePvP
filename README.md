# WSGFlagCaller v2

A WoW 1.12 / Turtle WoW addon perfectly designed for Warsong Gulch. It tracks flag carriers, features a clean click-to-focus HUD, calculates precise 3D distance to the carriers, and calls out Enemy Flag Carrier health milestones in standard Battleground chat. Complete with smart anti-spam healing hysteresis.

## Requirements
# TurtlePvP

A versatile PvP utility suite tailored for Turtle WoW, providing an intelligent HUD, passive enemy tracking, and rapid tactical reporting across Warsong Gulch and Custom Arenas.

## Features

- **Warsong Gulch Flag Tracker:**
  - Live HUD displaying the HP and Distance to both Flag Carriers.
  - Automatic `/bg` callouts when the enemy FC's health hits 75, 50, and 25%.
  - Zero-config auto-recovery via passive buffs — picks up missed carriers automatically.
- **Arena Enemy Tracker HUD:**
  - Automatically activates in Turtle WoW's custom arena zones (The Blood Arena, Lordaeron Arena, Sunstrider Court, The Blood Ring).
  - Passively harvests enemy data from targets, mouseovers, nameplates, and combat logs.
  - HUD displays up to 8 enemies simultaneously with Name, HP bar, estimated absolute distance, and class colors.
  - Warns you immediately with `[🔔]` when an enemy uses a PvP Trinket, Racial (WotF/Escape Artist/Stoneform), or Perception.
- **EFC Location Reporter:**
  - A dedicated grid of 23 location buttons tailored to Warsong Gulch.
  - Click a location button to instantly announce the enemy flag carrier's position in Battleground chat (automatically using Common/Orcish depending on your faction).
  - Displays a live Nampower-driven HP Bar of the EFC right inside the reporter frame.
- **Modern Restyled Config Panel:**
  - Fast, modular interface. Click the Minimap button (or use slash commands) to toggle features independently.

## Requirements

To unlock the full power of TurtlePvP (accurate distance and precise HP tracking), install the following optional dependencies:
- **[Nampower](https://twinstar-addons.github.io/addons/nampower/)** (Fetches absolute Player HP limits and GUIDs for tracking behind objects)
- **[UnitXP](https://github.com/allfoxwy/UnitXP)** (Calculates precise 3D distances between you and the enemy carriers/arena players)

## Commands

- `/tpvp` or `/turtlepvp`: Open the Config Panel UI
- `/tpvp force wsg`: Force the addon into Warsong Gulch mode (for testing outside of BGs)
- `/tpvp force arena`: Force the addon into Arena mode (for testing outside of Arenas)
- `/tpvp reset`: Resets all frame positions back to defaults
- `/tpvp status`: Prints module and dependency activation status to your chat log
- `/tpvp debug on/off`: Toggles internal debugging output

## Moving Frames

You can freely click and drag the **Flag Tracking HUD**, the **Arena Enemies HUD**, and the **EFC Reporter Grid** anywhere on your screen. Their positions are automatically saved to your character's `TurtlePvPConfig`.

## Credits & Thanks
- Included `v3.1 EFC Reporter` based on the original EFCReport concept by **Cubenicke (Yrrol@vanillagaming)**.
- Original map positioning layout and location icons by **lanevegame**.
- Initial design and architecture inspired by **Spy**, **TurtleHonorSpyEnhanced**, and vanilla tracking mechanics.
