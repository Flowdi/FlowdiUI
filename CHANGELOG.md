# Changelog

## 0.8.18

- Fixed settings creation after the Aura Filters tab was attached to the Cast Bar tab list instead of the Aura tab list, restoring the game-menu button and `/fui`/`/flowdi` commands.
- Keeps Weakened Soul and other explicitly assigned debuffs at Bottom Left in Party/Raid frames.
- Adds a native crowd-control group at Bottom Right for stuns and similar control effects.
- Moves class-dispellable Magic, Disease, Poison, and Curse debuffs to the middle-right position and excludes crowd-control and explicitly positioned debuffs from that group.

## 0.8.17

- Connected Party/Raid Essential filters to separate combat-safe native containers for Top Left maintenance buffs, Top Right healing buffs, Right-side custom buffs, Bottom Left debuffs, Bottom Right dispels, and centered raid debuffs.
- Added native spell-ID Allow and Block lists to Unit Frame Buffs and Debuffs; Party/Raid filters now also support overriding Block lists.
- Made Party/Raid healing Buff filters default to player-cast auras so unrelated buffs from other classes do not occupy healing indicators.
- Fixed disabled aura tooltips by turning off the native button's mouse-motion channel when Tooltip is unchecked.
- Rebuilds affected native containers when filter, placement, ownership, tooltip, or visual settings change.

## 0.8.16

- Sizes every native AuraButton explicitly during its protected initializer; provider layout dimensions position buttons but do not give them a renderable size.
- Supplies an explicit empty candidate-filter table for unfiltered Buff and Debuff groups.
- Extends `/fui auradiag` with physical-size and shown-button counts.

## 0.8.15

- Replaced the separate Unit Frame and Party/Raid aura implementations with one shared native aura engine.
- Creates and styles every icon, cooldown, stack, and duration region before registering it with the protected aura provider, then binds the unit last.
- Queues Party/Raid aura groups across rendered frames so the provider's eager button-pool creation cannot exhaust the login script budget.
- Removed the runtime path back into addon-side aura iteration, keeping Buffs and Debuffs owned by the combat-safe client provider at all times.
- Added `/fui auradiag` to report provider, container, button-pool, and pending-build state if an installation needs verification.

## 0.8.14

- Replaced Unit Frame and Party/Raid aura displays with direct native containers attached to each unit button, removing the previous intermediary anchors and guarded-layout path.
- Reduced aura regions to the native icon, cooldown, and stack interfaces so combat visibility is driven solely by the client aura provider.
- Attached the Chat background directly to the primary chat frame and removed the independent geometry follower.
- Registered the real primary chat frame as the only FlowdiUI mover and expanded its text container across the full frame width.

## 0.8.13

- Forced Buff and Debuff displays on for Player, Target, Party, and Raid frames, including migration of existing profiles to unfiltered aura visibility.
- Corrected native aura activation order so fully configured containers bind their unit before being enabled and refreshed.
- Replaced the separate Chat anchor with a single mover attached directly to the primary chat frame.
- Made the independent Chat background follow the primary frame numerically and moved the native side-button frame out of the visible layout.

## 0.8.12

- Restored deferred protected aura-container construction while leaving combat `UNIT_AURA` updates entirely to the client provider.
- Removed the Party/Raid candidate prefilter and added a visible one-time diagnostic if native aura-container creation fails.
- Moved the primary Chat background and copy control onto an independent FlowdiUI host.
- Suppressed the native Chat Edit Mode selection and resize surfaces; Chat placement remains owned by FlowdiUI Unlock Mode.

## 0.8.11

- Rebuilt Unit Frame and Party/Raid aura containers during initial frame construction, binds their actual secure unit token last, and leaves combat aura updates to the protected client provider.
- Removed the premature Party/Raid spell-ID gate so enabled Buff and Debuff containers can populate before a later indicator-filter pass.
- Added Chat to FlowdiUI Unlock Mode with its own persistent anchor, independent of the native Edit Mode position.
- Removed the remaining social toast control and tightened the Chat background to the actual text frame.

## 0.8.10

- Kept native Unit Frame and Party/Raid auras refreshed on aura and roster events and protected their layout from restricted combat-data updates.
- Suppressed the remaining native Action Button cast, interrupt, reticle, flash, highlight, new-action, and pushed artwork while retaining functional cooldowns.
- Removed the left-side Chat voice, menu, and text-to-speech controls.
- Rebuilt the Chat copy dialog around a clipped scrolling text area so copied history stays inside the window.
- Added a Chat input-position option for placing the edit box above or below its chat frame.

## 0.8.9

- Added a live coordinate panel beside the selected Unlock Mode mover; clicking a mover shows its centered X/Y coordinates and dragging updates them continuously.
- Hidden Action Bar movers when their configured bar is disabled or its native bar is not active.
- Explicitly synchronized native aura-container visibility and enabled state after binding Unit Frame and Party/Raid units, matching the complete protected-container lifecycle.

## 0.8.8

- Deferred native Unit Frame and Party/Raid aura construction until the world is ready, and configured container flow layout before registering aura groups so Buffs and Debuffs can populate reliably.
- Replaced the misleading friendly `UnitInRange` shortcut with direct class-healing-spell range checks for Target, Party, and Raid frames.
- Kept Action Bar mover overlays synchronized with every button-size and scale change, including compact bars below the previous mover minimum size.

## 0.8.7

- Removed the explicit disable/enable cycle that prevented otherwise valid native Aura Containers from registering and rendering their Unit Frame and Party/Raid groups.
- Friendly Target range now prefers the client's checked group-range result and falls back to the first known class healing spell instead of one hard-coded spell.
- Registered all player, Pet, and Stance Action Bars with the central Unlock Mode and preserves their positions.
- Suppressed the native Main Action Bar page-number and previous/next controls visually and for mouse input.

## 0.8.6

- Rebuilt native Unit Frame and Party/Raid aura activation around the client's plain custom aura container lifecycle; failed native group creation now reports its actual error instead of silently hiding all auras.
- Replaced the invalid generic Target range path with separate hostile interact-range and friendly healing-spell checks, while leaving unknown or protected classifications fully visible.
- Corrected the Main Action Bar host from the obsolete menu bar frame to the current `MainActionBar` frame.
- Reworked empty Action Button detection around the button's native `HasAction` method and action attribute.
- Suppressed native empty-slot backgrounds and range glyphs instead of clearing managed icon textures.
- Added independent button-background color and opacity controls to every Action Bar.

## 0.8.5

- Replaced Unit Frame and Party/Raid aura reads with native protected aura containers so Buffs and Debuffs remain visible when combat aura data becomes secret.
- Removed all combat-time layout writes from native aura updates and enabled the protected layout-script guard.
- Fixed friendly Target and group-frame range fading by passing spell and group range results directly to the client's secret-safe alpha API.
- Removed the ineffective Global Settings Style tab.
- Added a Profiles page placeholder for future naming, assignment, copying, import, and export support.
- Added independent Action Bar scaling plus configurable FlowdiUI border size and color.
- Fixed Main Action Bar scaling, empty-slot icon cleanup, and missing-glyph boxes used by the action range indicator.

## 0.8.4

- Fixed friendly range fading so the player is always in range and distant Party, Raid, and friendly Target units use the client's protected range result correctly.
- Fixed secure Unit Frame Debuff containers by enabling them before unit assignment and added the same native Debuff path to the Player frame.
- Fully suppresses the native Player cast bar, including its interrupted animation, while the FlowdiUI cast bar provider is selected.
- Added independent settings for eight player action bars plus Pet and Stance bars.
- Added per-bar enable state, visibility mode, opacity, click-through, empty-button display, icon size, button count, rows, spacing, orientation, and text sizing.

## 0.8.3

- Made friendly Unit Frame and group-frame fading secret-safe with the client's native boolean-to-alpha API.
- Fixed `Only my buffs` by applying the player-source filter while the client collects auras instead of inspecting protected source data afterwards.
- Added an Essential aura mode for Party and Raid Frames with independent Top Left, Top Right, Bottom Left, Bottom Right, and Center assignments.
- Added editable comma-separated spell-ID or exact-name lists for maintenance buffs, healing buffs, special debuffs, and raid debuffs.
- Added class-aware dispellable Debuffs at Bottom Right and migrated existing profiles to the healer-focused buff filter.

## 0.8.2

- Bundled Continuum Medium and Expressway as selectable FlowdiUI fonts.
- Fixed friendly Target range fading by resolving the Target to its actual Party or Raid unit token before checking range.
- Prevented hostile Debuff updates from repositioning or restyling protected aura objects after unit assignment.
- Moved the hostile Debuff container onto a separate configurable anchor so normal aura events no longer taint its layout.

## 0.8.1

- Replaced hostile Unit Frame Debuff reads with the secure native aura container used by the current client.
- Added mouse-wheel scrolling and a visible scrollbar to every Unit Frame settings tab.
- Split Unit Frame range fading into a 40-yard friendly-group check and an independent 30-yard hostile check.
- Added a Player cast-bar provider selector that switches cleanly between the custom and native cast bars.
- Added more built-in client fonts and refreshed SharedMedia discovery whenever the settings window is first created.

## 0.8.0

- Added a configurable standalone Pet Unit Frame.
- Added optional attached pet frames for every Party and Raid member, including preview, height, and spacing controls.
- Added configurable 40-yard range fading for Target, Party, and Raid frames.
- Enabled Party and Raid buff-duration text by default and fixed the upgrade path for existing profiles.
- Added an explicit `Only my buffs` source filter for group-frame buffs.

## 0.7.9

- Added explicit Vertical and Horizontal orientations for Party Frames.
- Added stable global names and dedicated high-level aura anchors to every Party and Raid unit button.
- Added `FlowdiUI:GetGroupUnitFrame(unit)` plus `FlowdiAuraAnchor` for external raid-debuff integrations.

## 0.7.8

- Switched Unit Frame aura collection to the safe packed-aura iterator with a legacy fallback, fixing hostile-target Debuff discovery.
- Added optional Target of Target and Target of Target of Target frames with full Unit Frame settings and mover support.
- Rebuilt Party and Raid Frames around independent profiles and secure clickable unit buttons.
- Added a live layout preview that reflects dimensions, spacing, growth, colors, text, power bars, borders, Buffs, and Debuffs.
- Added Party/Raid controls for visibility, player inclusion, scale, dimensions, unit/group spacing, units per column, growth direction, health styling, text, auras, and status indicators.
- Added group-frame role, leader, raid-marker, ready-check, Buff, and Debuff rendering.

## 0.7.7

- Added independent 1-5 px line-thickness controls to the Unlock Mode grid.
- Replaced the unsupported Unlock Mode navigation glyph with a font-safe icon.
- Added configurable Buff and Debuff displays to Player, Target, and Focus frames.
- Added aura sizing, rows, spacing, borders, attachment anchors, X/Y offsets, growth, sorting, duration text, stack text, tooltips, cooldown swipes, desaturation, and click-through controls.
- Added compatibility paths for both table-based and legacy unit-aura APIs.

## 0.7.6

- Replaced scattered mover lock controls with one central Unlock Mode in the settings sidebar.
- Added labeled mover proxies for all movable FlowdiUI frames, including currently hidden or conditional frames.
- Added an optional adjustable layout grid and a top toolbar with Save & Exit.
- Forced a safe locked layout after login and preserved all moved positions in the active profile.

## 0.7.5

- Made every slider value box directly editable, including negative X/Y offsets.
- Added a Lock Movers action and restored cast-bar visibility to active casts or mover previews only.
- Replaced the placeholder combat square with the standard crossed-swords combat icon.
- Added optional incoming-heal prediction bars with separate personal/other-healer visibility, colors, and opacity.

## 0.7.4

- Moved Unit Frame indicators onto a dedicated high-level overlay so raid markers always render above bars and portraits.
- Expanded Cast Bar settings with General, Position, and Text sections.
- Added cast-bar width, height, textures, colors, opacity, reverse fill, strata, attachment anchors, X/Y offsets, icon placement, text placement, text size, and time format.
- Added detached cast bars that can be dragged independently while movers are unlocked.

## 0.7.3

- Fixed protected raid-marker indices and assigned the required marker sprite sheet.
- Added independent attachment target, icon anchor, attachment point, X/Y offset, and size controls for every Unit Frame indicator.
- Positioned raid markers on the upper frame edge by default.

## 0.7.2

- Fixed Health, Health %, Power, and Power % text on the Forever client.
- Routed protected unit values directly through secure-compatible font-string formatting.
- Kept a conventional numeric fallback for clients without the percentage APIs.

## 0.7.1

- Made every non-interactive area of the settings window available as a drag surface.
- Moved Unit Frame text elements onto their visible Health and Power bar layers.
- Added working per-frame cast bars with icon, height, opacity, and fill-color controls.
- Added raid-marker, group-leader, and combat indicators with independent sizes.
- Expanded Unit Frame navigation to seven focused settings tabs.

## 0.7.0

- Rebuilt Unit Frames around independent Player, Target, and Focus profiles.
- Added Display, Health Bar, Power Bar, Texts, and Portrait settings tabs.
- Added per-frame dimensions, texture, opacity, colors, visibility, strata, borders, tooltips, and hover controls.
- Added configurable left, right, center, extra, and power text assignments.
- Added attached 2D portraits with independent side and size controls.
- Added automatic migration of the previous shared Unit Frame dimensions.

## 0.6.7

- Matched the resting FlowdiUI button outline to the other Game Menu buttons while retaining the blue hover accent.

## 0.6.6

- Added a dedicated two-pixel blue outline around the FlowdiUI Game Menu button.
- Added a brighter branded border state on hover.

## 0.6.5

- Removed native three-segment button artwork at its actual texture-region source.
- Returned all labels to the original Blizzard font strings so pooled buttons keep their text reliably.
- Added compact inset backgrounds and borders without covering or replacing secure menu buttons.

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
