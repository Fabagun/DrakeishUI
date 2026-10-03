# Changelog

## 2.0.0

### Nameplates
- Show nameplates for enemies, friends, and neutrals, saved with the client
- Three modes: selected unit only, that same look on every unit, or native Blizzard plates
- Selected unit in the all-units mode uses a bright name with a blue halo
- Level numbers sit closer to their shadow

### Raid frames
- Compact raid frames, shown while in a raid when the toggle is on
- Two frame styles
- Health fill shades darker on the left and lighter on the right, matching the nameplates

### Minimap
- Border turns with the map, and the double arrow stays on north
- Rotate minimap checkbox, kept in step with Interface → Display
- Minimap button toggle travels with the border

### Settings
- DrakeishUI settings window for party frames, chat, bars, gryphons, raid frames, nameplates, Diablo orbs, and the pet frame
- Gryphon style and raid frame style are numbered cycles and persist on reload

### Windows
- Talent window with loadouts, using the modern frame chrome
- Spellbook, character panel, collections, encounter journal, social window, and world map use the same chrome
- Bags use Bagster, with search and sort, in place of Combuctor

### Diablo orbs
- Guardian and Demon Hunter power orbs use their class power color
- Health orb stays red

## 1.0.0

### Diablo Orbs Integration
- **Added Mistra's Diablo Orbs**: Integrated the full Diablo-style orb system for health, mana, and pet
- **Pet Orb Enhancements**:
  - Moved pet orb to bottom of screen, aligned with main orbs
  - Changed pet orb to display only health (removed power display)
  - Made pet orb red color brighter (20% more vibrant) than player health orb
  - Updated pet orb to use same texture as player health orb for consistency
  - Centered health fonts since only health is displayed
  - Fixed positioning and sizing to fit properly within circular orb frame

### Custom Diablo Target Frame
- **New Custom Target Frame**: Created a Diablo-style target frame that replaces the default when Diablo orbs are active
- **Features**:
  - Uses custom Diablo textures (d3_targetframe.tga, d3_targetframe_background.tga)
  - Health and mana bars positioned under the frame textures
  - Name and level text positioned like party frames
  - Classification indicators (boss, rare, elite) displayed above the frame
  - Health bar color options:
    - Class colors for player targets (like party frames)
    - Red or green option for non-player targets
    - Red color option for bosses/world bosses
  - Tooltip support on mouseover (matches normal target frame behavior)
  - Proper restoration of default target frame when Diablo orbs are deactivated

### UI Toggles
- **Pet Orb Toggle**: Added checkbox to toggle pet orb visibility
- **Smart State Management**: Pet orb toggle is only enabled when Diablo orbs are active
- **Visual Feedback**: Toggle checkbox is greyed out when Diablo orbs are inactive

### Bug Fixes
- Fixed target frame restoration when deactivating Diablo orbs
- Fixed border textures and portrait not appearing after deactivation
- Fixed Lua error with button9 nil value in buff frame toggle
- Improved state detection for custom target frame on reload
- Fixed pet orb power color detection (now uses focus/energy/mana correctly)

### Code Improvements
- Enhanced DragonflightUI restoration logic with multiple delayed attempts
- Improved frame visibility synchronization
- Better error handling and nil checks
- Optimized texture positioning and sizing

