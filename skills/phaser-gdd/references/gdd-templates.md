# GDD Template Examples

These three outlines show how a complete 12-section GDD reads for different genres. Each makes concrete design decisions rather than leaving blanks. Use them as starting points and replace every detail with your own.

## Platformer: "Crystal Caverns"

1. **Game Overview:** 2D side-scrolling platformer for ages 8+. Explore crystal-filled caves, avoid traps, and rescue trapped miners.
2. **Core Loop:** Enter room, dodge hazards, collect crystals, reach the exit portal. Crystals fund upgrades between worlds.
3. **Mechanics:** Run (150 px/s), variable-height jump (tap vs hold), wall-slide, wall-jump. Dash ability unlocks in World 3. No combat; all threats are environmental.
4. **Progression:** 5 worlds with 4 levels each. Crystal-gate thresholds (20/50/100/180) unlock the next world. Hidden star shards unlock a bonus world.
5. **Levels:** Cave (tutorial), Ice (slippery physics), Lava (rising magma timer), Underwater (floaty gravity), Crystal Palace (all mechanics combined).
6. **Characters:** Explorer sprite with 3 hearts and incremental ability unlocks. Enemies: Bats (horizontal patrol), Golems (chase on sight), Slimes (bounce pad on defeat).
7. **UI:** Hearts top-left, crystal counter top-right, minimap bottom-right in large levels. World map screen between levels with node-path layout.
8. **Art:** Pixel art with 16x16 tiles. Core palette: #1d1d2b (shadow), #4488ff (crystal blue), #ff44aa (danger pink), #44ffaa (collectible green). Each world shifts the mid-tones.
9. **Audio:** Ambient cave-echo loops layered with per-world chiptune BGM. SFX: crystal chime on pickup, thud on land, whoosh on dash. Volume ducking during pause menu.
10. **Tech:** Phaser 4 with Arcade Physics. Target 60 fps at 800x600, scale mode FIT. Tilemap layers for background, collision, and foreground parallax.
11. **Platforms:** Web primary (itch.io, Newgrounds). Mobile builds via Capacitor with virtual d-pad and two action buttons.
12. **Release:** Free on web at launch. Mobile release at $1.99 after 4 weeks. Post-launch: community level editor stretch goal.

## Puzzle: "Hex Merge"

1. **Game Overview:** Hexagonal tile-merging puzzle. Mobile-first, portrait 360x640. Casual audience, single-session play.
2. **Core Loop:** Place a colored hex, merge three or more adjacent matches, chain reactions score multipliers, board fills up means game over.
3. **Mechanics:** Tap to place tile in any empty cell. Matching neighbors merge into a higher-tier color (red > orange > yellow > white). Cascading merges trigger automatically. Time-pressure mode adds a 60-second countdown.
4. **Progression:** Endless mode with persistent high score. Daily challenge mode with a fixed seed. Tier milestones (reach white tile) unlock new board shapes.
5. **Levels:** Board variants: small hex (19 cells), medium hex (37 cells), diamond (25 cells), triangle (21 cells). Unlocked sequentially.
6. **Characters:** No narrative characters. Tile tiers have subtle face expressions (calm, excited, radiant) as visual feedback.
7. **UI:** Score and combo counter centered top. Next-tile preview bottom. Pause icon top-right. End screen with share button.
8. **Art:** Flat vector hexagons with soft gradients. Background: #0f0a1a. Tile palette: warm spectrum reds through whites. Gentle glow particles on merges.
9. **Audio:** Soft lo-fi BGM loop. Ascending xylophone notes per merge tier. Satisfying pop SFX on chain reactions. Haptic feedback on mobile.
10. **Tech:** Phaser 4, no physics. All movement via tweens and timeline sequences. Hex grid stored as offset-coordinate array.
11. **Platforms:** Mobile web (PWA installable), desktop browser. No native builds planned initially.
12. **Release:** Free-to-play, ad-supported (interstitial between rounds). Remove ads IAP at $2.99. Daily challenges drive retention.

## RPG: "Woodland Quest"

1. **Game Overview:** Top-down action RPG set in an enchanted forest. Ages 12+. Estimated 4-6 hour campaign.
2. **Core Loop:** Explore overworld, accept quests from NPCs, clear dungeon, defeat boss, gain loot, return to village.
3. **Mechanics:** 8-directional movement at 120 px/s. Real-time combat: sword (melee arc), bow (projectile). Dodge-roll with 0.8s cooldown and i-frames. Potion use mapped to quick-slot.
4. **Progression:** Three dungeons in fixed order. Each boss drops a key item that opens the next zone. Side quests yield gold and gear upgrades. Level cap 15.
5. **Levels:** Whispering Woods (overworld hub), Hollow Burrow dungeon, Thornveil Marsh dungeon, Ancient Canopy dungeon, plus the starting village.
6. **Characters:** Player: fox ranger with sword/bow. NPCs: owl shopkeeper, badger blacksmith, deer quest-giver. Enemies: mushroom scouts, vine crawlers, bark golems. Bosses: Spider Queen, Marsh Wyrm, Elder Treant.
7. **UI:** Hearts and mana bar top-left, quick-slots bottom-center, inventory screen (grid-based), quest log tab, dialog box bottom third with portrait and text.
8. **Art:** 16x16 pixel tiles, 32x32 character sprites. Earth-tone palette: #2b1d0e, #4a7a2e, #d4a437, #e8dcc8. Animated water and foliage tiles.
9. **Audio:** Forest ambiance with birdsong. Unique BGM per zone (folk/acoustic style). Combat stinger on enemy encounters. UI click and equip SFX.
10. **Tech:** Phaser 4 Arcade Physics with zero gravity. Tilemap collision layers. Dialog system via JSON script files. Save state to localStorage.
11. **Platforms:** Desktop web primary. Mobile playable with virtual joystick and two-button overlay. Electron build for offline distribution.
12. **Release:** Free demo (first dungeon). Full game $4.99 on itch.io. Post-launch patch with New Game+ mode.
