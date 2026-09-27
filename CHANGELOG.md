# Changelog

## 0.6.4

- Added a high-priority dark cover above every native Game Menu artwork layer.
- Kept the original secure buttons while rendering clean dark surfaces, borders, labels, and hover colors above them.

## 0.6.3

- Replaced the layered menu-button treatment with direct native texture recoloring for reliable dark buttons.
- Moved the FlowdiUI entry directly below Options and removed the fragile middle-menu insertion.
- Preserved every native menu label and button, including Return to Game.

## 0.6.2

- Replaced optional external status-bar aliases with self-contained game-media choices.
- Rebuilt Game Menu button surfaces above the native artwork for consistent dark styling.
- Restored the Return to Game label and protected all menu labels with reliable fallbacks.

## 0.6.1

- Rebuilt the complete Game Menu as a unified dark interface instead of recoloring individual native buttons.
- Added a near-black menu background, blue frame border, dark native-button replacements, white labels, and brighter blue hover states.
- Kept the FlowdiUI entry visually distinct with a stronger two-pixel accent border.
- Enabled the dark Game Menu by default and migrated existing profiles to the new design.

## 0.6.0

- Reworked the Escape-menu entry to preserve the native decorative button shape while using a black center, blue border treatment, white label, and brighter hover state.
- Added an optional dark treatment for every native Game Menu button.
- Added a second independently movable DataText panel with up to five configurable slots.
- Added an optional one- or two-slot panel above or below the Minimap.
- Added separate Primary Panel, Second Panel, Minimap Panel, and general appearance settings.
- Added backdrop, border, transparency, slot-count, width, height, position, scale, opacity, and font-size controls.
- Expanded DataTexts with attributes, combat ratings, experience, reputation, item level, movement speed, location, date, mail, and volume.
- Added repository metadata and removed third-party comparison language from public documentation.

## 0.5.1

- Replaced the native red Escape-menu artwork with an opaque black FlowdiUI button, neon-blue border and brand mark, and white label.
- Wired damage, healing, and combat-text-scale controls to Forever's `_v2` combat-text CVars while retaining legacy compatibility.
- Added independent font overrides for Action Bars, Nameplates, Unit Frames, Party/Raid Frames, Chat, and Data Panels.
- Added `Global` and `Name Font` inheritance choices for module fonts.
- Made lower dropdowns open upward so long SharedMedia lists remain usable.

## 0.5.0

- Added a FlowdiUI-colored Escape-menu button with accent border, cyan label, and hover feedback.
- Made the settings window movable from all four edges and persisted its position.
- Added dynamic LibSharedMedia font and status-bar discovery.
- Added mouse-wheel scrolling for long dropdown menus.
- Replaced the unsupported dropdown glyph with a universally supported `v`.
- Added an Improvements tab with options-window scale, lag tolerance, combat-text controls, tutorial suppression, invite acceptance, border thickness, and icon cropping.
- Kept panel backgrounds independent from selectable status-bar textures.

## 0.4.1

- Replaced click-cycling selectors with true dropdown menus.
- Added live font previews to every font selector.
- Added live status-bar previews to every texture selector.
- Added persistent numeric value boxes beside every slider.

## 0.4.0

- Rebuilt Global Settings with General, Style, Fonts, Textures, and Colors tabs.
- Added FlowdiUI, Blizzard, and Classic style presets.
- Added global font, outline, font-size, name-font, and combat-font choices.
- Added primary and secondary status-bar texture choices.
- Added live accent, background, health, and power color controls.
- Added global UI, game-menu, background-opacity, camera-distance, key-down casting, and auto-repair controls.
- Converted all FlowdiUI user-facing text to English.
- Reworked the Escape-menu entry for Forever's dynamic button-pool layout.

## 0.3.0

- Added a reusable FlowdiUI skin toolkit.
- Added dedicated Forever skins for character, quest, gossip, bank, bags, merchant, mail, and world-map windows.
- Replaced the fixed information bar with five configurable DataText slots.
- Added System, Bags, Gold, Durability, Time, Coordinates, Friends, and Guild providers.
- Added DataText tooltips and click actions.
- Added settings search and substantially expanded module controls.
- Added configurable unit-frame dimensions, power height, and font size.
- Added configurable party and raid-frame dimensions.
- Added configurable nameplate width and cast-bar height.
- Added chat copy, timestamp, fade, and visibility controls.
- Added item-level labels and quality borders to bag items.
