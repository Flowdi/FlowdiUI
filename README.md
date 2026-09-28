# FlowdiUI

FlowdiUI is a modular interface MVP for **World of Warcraft: Forever**. It combines a clean blue/black visual language with a deliberately conservative implementation based on Blizzard's secure UI systems.

FlowdiUI includes a fully English settings area with General, Style, Fonts, Textures, Colors, and Improvements tabs. Selectors use dropdown menus with font and texture previews, while sliders show their exact current value. Open it with `/fui`, the addon-compartment icon, or the FlowdiUI entry in the Escape menu.

## Included in the MVP

- Independent layouts and visibility controls for eight player action bars plus Pet and Stance bars without replacing secure Blizzard action buttons
- Lightweight nameplate styling
- Custom player, pet, target, focus, target-of-target, and target-chain frames
- Configurable Buff and Debuff displays for player, target, and focus frames, including secure hostile-target Debuffs
- Custom clickable party and raid frames with optional member-pet frames, secret-safe range fading, healer-focused positional aura filters, independent profiles, and live settings previews
- Chat styling
- Dark bag styling while retaining Blizzard bag behavior
- Two movable DataText panels plus an optional Minimap panel
- Darkmode treatment for common Blizzard windows
- In-game module settings with the Flowdi logo
- Full sidebar settings with live sliders and module-specific pages
- Global style presets plus configurable fonts, outlines, textures, and interface colors
- Bundled Expressway and Continuum Medium fonts plus dynamic SharedMedia font and texture discovery with preview dropdowns
- Independent font selection for Action Bars, Nameplates, Unit Frames, Party/Raid Frames, Chat, and Data Panels
- Movable settings window with a remembered screen position
- Global Improvements controls for lag tolerance, combat text, tutorials, invites, borders, and icon cropping
- Direct FlowdiUI entry in the Escape game menu
- Optional unified dark Game Menu with black buttons, white labels, and blue hover accents
- FlowdiUI skin toolkit with dedicated Forever skins for character, quests, gossip, bank, bags, merchants, mail, and the world map
- Up to twelve assignable DataText slots across all panels
- DataTexts for system performance, inventory, social information, progression, location, character statistics, mail, volume, date, and time
- DataText tooltips and click actions
- Chat copy window, timestamps, fading controls, and configurable visibility duration
- Bag item-level text and quality-colored item borders
- Central Unlock Mode with labeled movers, an optional layout grid, and Save & Exit

## Group-frame integrations

Party and Raid buttons have stable global names and expose a dedicated high-level aura anchor. External aura displays can resolve a secure group frame with `FlowdiUI:GetGroupUnitFrame("raid1")` (or a party unit such as `party2`) and anchor to its `FlowdiAuraAnchor` field. `FlowdiUI:GetUnitFrame(unit)` remains available when an integration should prefer the matching main Unit Frame and fall back to a group frame.

## Installation

Copy the `FlowdiUI` folder into the Forever client AddOns directory, normally:

`World of Warcraft/_classic_beta_/Interface/AddOns/FlowdiUI`

The folder structure must end in `FlowdiUI/FlowdiUI_Camelot.toc`.

## Commands

- `/fui` or `/flowdi` — open settings
- `/fui unlock` — open the central Unlock Mode
- `/fui lock` — save and close Unlock Mode

Module changes require `/reload` and the settings window provides a reload button.

Most visual settings, including scaling, font size, opacity, nameplate height, and Darkmode brightness, apply immediately. Module activation changes still require `/reload`.

## MVP boundaries

FlowdiUI intentionally does not include combat automation, an aura scripting engine, or a damage meter. Bag and action-bar behavior remains powered by Blizzard's implementation to minimize combat-lockdown and taint problems.
