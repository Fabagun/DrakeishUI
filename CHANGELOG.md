# Changelog

## Recent Updates

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

