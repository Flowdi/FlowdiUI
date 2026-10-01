# FlowdiUI Layer Tracker

Standalone Layer Tracker for World of Warcraft: Forever. It does not require FlowdiUI or NovaWorldBuffs.

## Usage

- `/flayer` opens the settings.
- `/flayer scan` scans visible outdoor NPCs and requests peer data.
- `/flayer unlock` enables the mover.
- `/flayer lock` saves the position and closes the mover.
- `/flayer reset` restores the default position.

Left-clicking the panel scans and synchronizes. Right-clicking opens the settings. Hovering shows all recently observed layers in the current zone.

Blizzard exposes no authoritative layer count to addons. The displayed count is inferred from outdoor NPC GUIDs and observations shared by other compatible FlowdiUI Layer Tracker users.

The standalone addon uses the same guarded protocol as FlowdiUI's integrated tracker, so both editions can exchange observations. Only one of the two panels should be enabled on the same client.
