-- Character Panel atlas entries (ported from DragonUI).
local addon = select(2, ...)
local assets = addon._dir
local A = addon.atlasinfo
if not A then return end

local rui_CharPanelBg = assets .. "CharacterPanel\\characterpanelbackground"
local rui_CharInfoA = assets .. "CharacterPanel\\characterinfoclasses-a"
local rui_CharInfoB = assets .. "CharacterPanel\\characterinfoclasses-b"
local rui_RingAlliance = assets .. "CharacterPanel\\ring-alliance"
local rui_RingHorde = assets .. "CharacterPanel\\ring-horde"
local rui_RingNeutral = assets .. "CharacterPanel\\ring-neutral"
local rui_Scrollbar = assets .. "CharacterPanel\\scrollbar"
local rui_ScrollbarMid = assets .. "CharacterPanel\\scrollbarmiddle"
local rui_CommonButtons = assets .. "CharacterPanel\\commonbuttons"
local rui_CommonIcons = assets .. "CharacterPanel\\commonicons"
local rui_ListExpand = assets .. "CharacterPanel\\listexpand"

A["character-panel-background"] = { rui_CharPanelBg, 450, 420, 0.000977, 0.440430, 0.001953, 0.822266 }
A["UI-Character-Info-Title"] = { rui_CharInfoA, 196, 40, 0.000977, 0.192383, 0.698242, 0.737305 }
A["UI-Character-Info-Line-Bounce"] = { rui_CharInfoA, 157, 19, 0.000977, 0.154297, 0.769531, 0.788086 }

A["ui-character-info-mage-bg"] = { rui_CharInfoA, 197, 355, 0.000977, 0.193359, 0.000977, 0.347656 }
A["ui-character-info-paladin-bg"] = { rui_CharInfoA, 197, 355, 0.195312, 0.387695, 0.000977, 0.347656 }
A["ui-character-info-rogue-bg"] = { rui_CharInfoA, 197, 355, 0.389648, 0.582031, 0.000977, 0.347656 }
A["ui-character-info-warlock-bg"] = { rui_CharInfoA, 197, 355, 0.583984, 0.776367, 0.000977, 0.347656 }
A["ui-character-info-warrior-bg"] = { rui_CharInfoA, 197, 355, 0.778320, 0.970703, 0.000977, 0.347656 }
A["ui-character-info-priest-bg"] = { rui_CharInfoA, 197, 355, 0.195312, 0.387695, 0.349609, 0.696289 }
A["ui-character-info-shaman-bg"] = { rui_CharInfoA, 197, 355, 0.389648, 0.582031, 0.349609, 0.696289 }
A["ui-character-info-deathknight-bg"] = { rui_CharInfoB, 197, 355, 0.000977, 0.193359, 0.001953, 0.695312 }
A["ui-character-info-druid-bg"] = { rui_CharInfoB, 197, 355, 0.389648, 0.582031, 0.001953, 0.695312 }
A["ui-character-info-hunter-bg"] = { rui_CharInfoB, 197, 355, 0.583984, 0.776367, 0.001953, 0.695312 }

-- Scrollbar / common icons may already exist from atlas_worldmap; set again is fine.
A["minimal-scrollbar-track-top"] = { rui_Scrollbar, 8, 8, 0.625, 0.75, 0.84375, 0.96875 }
A["minimal-scrollbar-track-bottom"] = { rui_Scrollbar, 8, 8, 0.625, 0.75, 0.6875, 0.8125 }
A["!minimal-scrollbar-track-middle"] = { rui_ScrollbarMid, 8, 1, 0.015625, 0.140625, 0, 0.000977 }
A["minimal-scrollbar-thumb-top"] = { rui_Scrollbar, 8, 8, 0.3125, 0.4375, 0.84375, 0.96875 }
A["minimal-scrollbar-thumb-bottom"] = { rui_Scrollbar, 8, 8, 0.609375, 0.734375, 0.484375, 0.609375 }
A["minimal-scrollbar-thumb-middle"] = { rui_ScrollbarMid, 8, 715, 0.484375, 0.609375, 0.000977, 0.699219 }
A["minimal-scrollbar-arrow-top"] = { rui_Scrollbar, 17, 11, 0.015625, 0.28125, 0.484375, 0.65625 }
A["minimal-scrollbar-arrow-bottom"] = { rui_Scrollbar, 17, 11, 0.015625, 0.28125, 0.28125, 0.453125 }

A["common-button-square-gray-up"] = { rui_CommonButtons, 42, 42, 0.000977, 0.250977, 0.536133, 0.786133 }
A["common-button-square-gray-down"] = { rui_CommonButtons, 42, 42, 0.000977, 0.250977, 0.284180, 0.534180 }
A["common-icon-rotateleft"] = { rui_CommonIcons, 20, 20, 0.126465, 0.175293, 0.756836, 0.854492 }
A["common-icon-rotateright"] = { rui_CommonIcons, 20, 20, 0.126465, 0.175293, 0.856445, 0.954102 }
A["common-icon-zoomin"] = { rui_CommonIcons, 25, 25, 0.504395, 0.629395, 0.000977, 0.250977 }
A["common-icon-zoomout"] = { rui_CommonIcons, 25, 25, 0.756348, 0.881348, 0.000977, 0.250977 }
A["common-icon-undo"] = { rui_CommonIcons, 25, 25, 0.378418, 0.503418, 0.252930, 0.502930 }
A["common-icon-checkmark"] = { rui_CommonIcons, 25, 25, 0.000488, 0.125488, 0.504883, 0.754883 }
A["common-icon-checkmark-yellow"] = { rui_CommonIcons, 25, 25, 0.126465, 0.251465, 0.000977, 0.250977 }
A["common-icon-delete"] = { rui_CommonIcons, 20, 20, 0.000488, 0.049316, 0.756836, 0.854492 }

A["honorsystem-portrait-alliance"] = { rui_RingAlliance, 50, 52, 0, 0.78125, 0, 0.8125 }
A["honorsystem-portrait-horde"] = { rui_RingHorde, 50, 52, 0, 0.78125, 0, 0.8125 }
A["honorsystem-portrait-neutral"] = { rui_RingNeutral, 50, 52, 0, 0.78125, 0, 0.8125 }

A["options_listexpand_left"] = { rui_ListExpand, 12, 26, 0.007812, 0.101562, 0.656250, 0.859375 }
A["_options_listexpand_middle"] = { rui_ListExpand, 1, 26, 0.000000, 0.007812, 0.218750, 0.421875 }
A["options_listexpand_right"] = { rui_ListExpand, 28, 26, 0.007812, 0.226562, 0.437500, 0.640625 }
A["options_listexpand_right_expanded"] = { rui_ListExpand, 28, 26, 0.242188, 0.460938, 0.437500, 0.640625 }
