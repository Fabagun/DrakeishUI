-- DrakeishUI_SocialNE/modules/pvp/Window.lua — DrakeishUI_Social_PVPFrame shell.
--
-- Same chrome recipe as Social/LFG: rock body + PortraitFrameTemplate nineslice + portrait
-- cutout + title + close. Hosts the stock PVPFrame (Honor & Arena) and PVPBattlegroundFrame
-- (Battlegrounds) as embedded panes so Blizzard's queue/arena APIs stay the state machine.
-- Open.lua redirects TogglePVPFrame / PVPParentFrame OnShow here and keeps the parchment parent
-- hidden.

local NE = DrakeishUI_SocialNE
if not NE then return end

NE.pvp = NE.pvp or {}
local P = NE.pvp
local LOC = NE.L

local FRAME_NAME = "DrakeishUI_Social_PVPFrame"
local MODULE = "PVP"

-- Stock PVPParentFrame is 384×512; shell adds modern title band + bottom tabs + inset padding
-- so the native layout can sit centered inside the content well (not stretched via SetAllPoints).
local STOCK_SIZE = { w = 384, h = 512 }
local PVP_SIZE = { w = 420, h = 570 }

local TABS = {
  { mode = "HONOR", label = (PVP or "PvP"), panel = "HonorPanel" },
  { mode = "BG",    label = (BATTLEGROUNDS or "Battlegrounds"), panel = "BGPanel" },
}

local function isModuleEnabled()
  local dragon = NE.dragon
  if not (dragon and dragon.db and dragon.db.profile and dragon.db.profile.newera) then return true end
  local m = dragon.db.profile.newera.modules and dragon.db.profile.newera.modules[MODULE]
  if type(m) == "table" and m.enabled ~= nil then return m.enabled and true or false end
  return true
end
P.IsEnabled = isModuleEnabled

local PVP_MIN_LEVEL = SHOW_PVP_LEVEL or 10
P.PVP_MIN_LEVEL = PVP_MIN_LEVEL

local function playerLevel()
  return UnitLevel("player") or 0
end

function P.IsUnlocked()
  return playerLevel() >= PVP_MIN_LEVEL
end

local function lockedMessage()
  return format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL or "This feature becomes available at level %d.",
                PVP_MIN_LEVEL)
end

-- ---------------------------------------------------------------------------
-- Chrome
-- ---------------------------------------------------------------------------
-- Owner art: assets/PVP_window.blp (128x128 rectangle). CreateMaskTexture is a no-op on this
-- client and SetPortraitToTexture is unreliable on addon paths, so we ship a pre-masked
-- PVP_window_circle.tga (transparent corners) and SetTexture it like Social's battlenet portrait.
local PVP_PORTRAIT_FDID = 9001001
local PVP_PORTRAIT_PATH = "Interface\\AddOns\\DrakeishUI\\assets\\PVP_window_circle"
local FACTION_CREST_TC = { 0.03125, 0.59375, 0.03125, 0.59375 }

local function pvpPortraitPath()
  local path
  if NE.tex and NE.tex.localFiles and NE.tex.localFiles[PVP_PORTRAIT_FDID] then
    path = NE.tex.localFiles[PVP_PORTRAIT_FDID]
  elseif NE.tex and NE.tex.Local then
    path = NE.tex.Local(PVP_PORTRAIT_FDID)
  end
  path = path or PVP_PORTRAIT_PATH
  return (path:gsub("%.[bB][lL][pP]$", ""):gsub("%.[tT][gG][aA]$", ""))
end

local function applyPVPPortrait(tex)
  if not tex then return end
  local path = pvpPortraitPath()
  if path then
    tex:SetTexture(path)
    tex:SetTexCoord(0, 1, 0, 1)
    tex:Show()
    return
  end
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  if faction == "Alliance" or faction == "Horde" then
    tex:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. faction)
    tex:SetTexCoord(FACTION_CREST_TC[1], FACTION_CREST_TC[2], FACTION_CREST_TC[3], FACTION_CREST_TC[4])
  else
    tex:SetTexture("Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-03")
    tex:SetTexCoord(0, 1, 0, 1)
  end
  tex:Show()
end

local function buildChrome(f)
  local body = f:CreateTexture(nil, "BACKGROUND", nil, -8)
  local rockPath = NE.tex and NE.tex.Local and NE.tex.Local(374155)
  if not rockPath and NE.tex and NE.tex.localFiles then rockPath = NE.tex.localFiles[374155] end
  body:SetTexture(rockPath or "Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
  body:SetHorizTile(true); body:SetVertTile(true)
  body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -21)
  body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  f.Body = body

  local streaks = f:CreateTexture(nil, "BORDER")
  if NE.tex and NE.tex.SetAtlas then NE.tex.SetAtlas(streaks, "_UI-Frame-TopTileStreaks", false) end
  streaks:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -21)
  streaks:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -21)
  streaks:SetHeight(43); streaks:SetHorizTile(true)

  local ns = CreateFrame("Frame", nil, f)
  ns:SetAllPoints(f)
  if NE.nineslice and NE.nineslice.ApplyLayout then NE.nineslice.ApplyLayout(ns, "PortraitFrameTemplate") end
  f.NineSlice = ns

  local tc = CreateFrame("Frame", nil, f)
  tc:SetFrameLevel((ns:GetFrameLevel() or 2) + 10)
  tc:SetPoint("TOPLEFT",  f, "TOPLEFT",  58, -1)
  tc:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, -1)
  tc:SetHeight(20); tc:EnableMouse(false)
  local titleStr = tc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleStr:SetJustifyH("CENTER")
  titleStr:SetPoint("TOP",   f, "TOP",    0,  -6)
  titleStr:SetPoint("LEFT",  f, "LEFT",   58,  0)
  titleStr:SetPoint("RIGHT", f, "RIGHT", -58,  0)
  titleStr:SetText(PLAYER_V_PLAYER or "Player vs. Player")
  f.TitleContainer = tc
  f.TitleText = titleStr
  f.Title = titleStr

  local close = CreateFrame("Button", FRAME_NAME .. "CloseButton", f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 0)
  close:SetScript("OnClick", function() P.Hide() end)
  if NE.panelchrome and NE.panelchrome.ModernizeCloseButton then
    NE.panelchrome.ModernizeCloseButton(close, { frameLevelBump = 10 })
  end
  f.CloseButton = close

  -- Named texture so SetPortraitToTexture can target it by name if needed.
  if not f.PortraitTex then
    f.PortraitTex = ns:CreateTexture(FRAME_NAME .. "Portrait", "ARTWORK")
  end
  if NE.portrait and NE.portrait.ApplyCutout then
    NE.portrait.ApplyCutout(f.PortraitTex, f, { size = 58, anchor = { "TOPLEFT", -4, 7 } })
  end
  applyPVPPortrait(f.PortraitTex)
end

local function setTitleForMode(f, mode)
  local t
  if mode == "BG" then
    t = BATTLEGROUNDS or "Battlegrounds"
  else
    t = PLAYER_V_PLAYER or "Player vs. Player"
  end
  if NE.panelchrome and NE.panelchrome.SetTitle then
    NE.panelchrome.SetTitle(f, t)
  elseif f.TitleText then
    f.TitleText:SetText(t)
  end
end

-- ---------------------------------------------------------------------------
-- Strip stock parchment chrome so only content art remains inside the inset.
-- New Era has no PVPParentFrame skin — its Inspect PvP pane rebuilds content and
-- specifically calls out UI-Character-PVP as the native parchment plate. Inside our
-- rock shell that plate is leftover chrome, not content (unlike Inspect).
-- ---------------------------------------------------------------------------
local HIDE_TEX_SUBSTR = {
  "UI-Character-General-",
  "UI-Character-Charactertab-",
  "UI-Battlefield-Top",
  "UI-Battlefield-Icon",
  "UI-QueueFromAnywhere-Bot",
  "TempPortrait",
}

local HIDE_NAME = {
  PVPFramePortrait = true,
  PVPFrameBackground = true,
  PVPBattlegroundFramePortrait = true,
  PVPBattlegroundFrameFrameLabel = true,
}

local function texturePath(tex)
  if not tex then return nil end
  if tex.GetTexture then
    local ok, path = pcall(tex.GetTexture, tex)
    if ok and type(path) == "string" then return path end
  end
  return nil
end

local function shouldHideTexture(tex)
  local n = tex.GetName and tex:GetName()
  if n and HIDE_NAME[n] then return true end
  local path = texturePath(tex)
  if not path then return false end
  local lower = path:lower()
  -- Full parchment PVP plate (keep UI-Character-PVP-Elements — honor table art).
  if lower:find("ui%-character%-pvp", 1) and not lower:find("ui%-character%-pvp%-elements", 1) then
    return true
  end
  for _, sub in ipairs(HIDE_TEX_SUBSTR) do
    if path:find(sub, 1, true) then return true end
  end
  return false
end

local function hideChromeRegion(r)
  if not r then return end
  r._nePvPChromeHidden = true
  if r.Hide then r:Hide() end
  if r.SetAlpha then r:SetAlpha(0) end
  -- Stock updates can re-Show these; neuter Show like New Era's Inspect PvP squelch.
  if r.Show and not r._nePvPShowNuked then
    r._nePvPShowNuked = true
    r.Show = r.Hide
  end
end

local function stripFrameChrome(frame)
  if not frame then return end

  local regions = { frame:GetRegions() }
  for i = 1, #regions do
    local r = regions[i]
    if r and r.GetObjectType then
      local kind = r:GetObjectType()
      if kind == "Texture" then
        if r._nePvPChromeHidden or shouldHideTexture(r) then
          hideChromeRegion(r)
        end
      elseif kind == "FontString" then
        local text = r.GetText and r:GetText()
        -- Stock title strings only — leave honor/arena labels alone.
        if text == (PLAYER_V_PLAYER or "Player vs. Player")
           or text == (BATTLEGROUNDS or "Battlegrounds")
           or text == (PVP or "PvP") then
          local name = r.GetName and r:GetName()
          if not name or name == "PVPBattlegroundFrameFrameLabel" then
            hideChromeRegion(r)
          end
        end
      end
    end
  end
end

local function stripParentChrome()
  local parent = _G.PVPParentFrame
  if not parent then return end

  local close = _G.PVPParentFrameCloseButton
  if close then close:Hide(); close:SetAlpha(0); close:EnableMouse(false) end
  if _G.PVPParentFrameTab1 then _G.PVPParentFrameTab1:Hide(); _G.PVPParentFrameTab1:EnableMouse(false) end
  if _G.PVPParentFrameTab2 then _G.PVPParentFrameTab2:Hide(); _G.PVPParentFrameTab2:EnableMouse(false) end

  local regions = { parent:GetRegions() }
  for i = 1, #regions do
    hideChromeRegion(regions[i])
  end
end

local function embedStockPane(stock, host)
  if not (stock and host) then return end
  stripFrameChrome(stock)
  stock:SetParent(host)
  stock:ClearAllPoints()
  -- Keep the stock layout box (absolute child anchors) and center it in our inset well.
  -- SetAllPoints stretched the frame and left TOPLEFT list vs BOTTOM-centered map unaligned.
  stock:SetSize(STOCK_SIZE.w, STOCK_SIZE.h)
  stock:SetPoint("CENTER", host, "CENTER", 0, 0)
  stock:SetFrameLevel((host:GetFrameLevel() or 1) + 1)
  stock:EnableMouse(true)
  local level = (stock:GetFrameLevel() or 1) + 8
  if host.InsetBorder then host.InsetBorder:SetFrameLevel(level) end
  if host.HonorWell and host.HonorWell.InsetBorder then host.HonorWell.InsetBorder:SetFrameLevel(level) end
  if host.ArenaWell and host.ArenaWell.InsetBorder then host.ArenaWell.InsetBorder:SetFrameLevel(level) end
end

-- Arena team rows are LEFT-anchored to PVPFrameBackground at x=13. Nudge them right, and drop
-- the arena block so its bordered well can sit clear of the honor well.
local ARENA_TEAM_SHIFT_X = 5
local ARENA_SECTION_DROP = 18
local function shiftArenaTeams()
  local bg = _G.PVPFrameBackground
  if not bg then return end
  local rows = {
    { std = _G.PVPTeam1Standard, y = 85 - ARENA_SECTION_DROP },
    { std = _G.PVPTeam2Standard, y = 0 - ARENA_SECTION_DROP },
    { std = _G.PVPTeam3Standard, y = -85 - ARENA_SECTION_DROP },
  }
  for _, row in ipairs(rows) do
    local std = row.std
    if std then
      std:ClearAllPoints()
      std:SetPoint("LEFT", bg, "LEFT", 13 + ARENA_TEAM_SHIFT_X, row.y)
    end
  end
  local arena = _G.PVPFrameArena
  if arena then
    arena:ClearAllPoints()
    arena:SetPoint("TOPLEFT", bg, "TOPLEFT", 120, -95 - ARENA_SECTION_DROP)
  end
  local toggle = _G.PVPFrameToggleButton
  if toggle and not toggle._neShifted then
    toggle._neShifted = true
    local p, rel, rp, x, y = toggle:GetPoint(1)
    if p then
      toggle:ClearAllPoints()
      toggle:SetPoint(p, rel or bg, rp or p, (x or 0) + ARENA_TEAM_SHIFT_X, (y or 0) - ARENA_SECTION_DROP)
    end
  end
end

-- Battlegrounds: stock map sits at BOTTOM x=-11 (parchment optical center). Re-center map + lore
-- scroll + BG list in our clean inset so the block reads centered.
local function centerBattlegroundContent()
  local bgFrame = _G.PVPBattlegroundFrame
  if not bgFrame then return end

  -- BG name list (295px buttons) was left-padded for parchment; center the column.
  local type1 = _G.BattlegroundType1
  if type1 then
    local listW = 295
    local left = math.floor((STOCK_SIZE.w - listW) / 2)
    type1:ClearAllPoints()
    type1:SetPoint("TOPLEFT", bgFrame, "TOPLEFT", left, -79)
  end

  local nameHeader = _G.PVPBattlegroundFrameNameHeader
  if nameHeader and type1 then
    nameHeader:ClearAllPoints()
    nameHeader:SetPoint("BOTTOMLEFT", type1, "TOPLEFT", 0, 8)
  end

  local tex = _G.PVPBattlegroundFrameBGTex
  if tex then
    tex:ClearAllPoints()
    tex:SetSize(333, 241)
    tex:SetPoint("BOTTOM", bgFrame, "BOTTOM", 0, 95)
  end

  local scroll = _G.PVPBattlegroundFrameInfoScrollFrame
  if scroll and tex then
    local sw = scroll:GetWidth() or 298
    local sh = scroll:GetHeight() or 232
    scroll:ClearAllPoints()
    scroll:SetSize(sw, sh)
    scroll:SetPoint("CENTER", tex, "CENTER", 0, 0)
  end

  -- Join / cancel row under the map, centered as a group (Cancel is the rightmost anchor).
  -- Group width ≈ GroupJoin(136) + Join(109) + Cancel(83) + gaps ≈ 330; Cancel center ≈ +124.
  -- Parked below the dark well, on the rock. Join and Group Join stay anchored to Cancel.
  local cancel = _G.PVPBattlegroundFrameCancelButton
  if cancel then
    cancel:ClearAllPoints()
    cancel:SetPoint("BOTTOM", bgFrame, "BOTTOM", 124, -3)
  end
end

-- Battlegrounds only: pull the dark well up so the rock shows under the border.
local BG_WELL_BOTTOM_LIFT = 14

local function shortenBattlegroundWell(panel)
  if not panel or panel._neWellShortened then return end
  panel._neWellShortened = true
  if panel.Bg then
    panel.Bg:ClearAllPoints()
    panel.Bg:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.Bg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, BG_WELL_BOTTOM_LIFT)
  end
  if panel.InsetBorder then
    panel.InsetBorder:ClearAllPoints()
    panel.InsetBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.InsetBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, BG_WELL_BOTTOM_LIFT)
  end
end

-- Dark recessed well + thin gold InsetFrameTemplate border — same recipe as Who/Friends/Raid.
local function dressPanelInset(panel)
  if not panel or panel._neInsetDressed then return end
  panel._neInsetDressed = true
  local bg = panel:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(0.06, 0.06, 0.07, 0.75)
  bg:SetAllPoints(panel)
  panel.Bg = bg
  if NE.nineslice and NE.nineslice.AttachInset then
    panel.InsetBorder = NE.nineslice.AttachInset(panel, 0, 0, 0, 0)
  end
end

-- Selection list (right edge): same track + character-frame thumb as the other bars, no end arrows.
-- The stock slider's carved groove (UI-Character-ScrollBar) is a separate texture, and its thumb
-- runs bottom-to-top. Hide that art and use the hand-built bar, which puts the top of the list
-- at the top of the track.
local function buryTexture(tex)
  if not tex or not tex.Hide or tex._neScrollBuried then return end
  tex._neScrollBuried = true
  tex:Hide()
  if tex.SetAlpha then tex:SetAlpha(0) end
  if tex.SetTexture then tex:SetTexture(nil) end
  tex.Show = tex.Hide
end

-- The list frame carries its own carved scrollbar border, separate from the slider.
local function buryScrollChrome(frame)
  if not frame or not frame.GetRegions then return end
  local regions = { frame:GetRegions() }
  for i = 1, #regions do
    local r = regions[i]
    if r and r.GetObjectType and r:GetObjectType() == "Texture" then
      buryTexture(r)
    end
  end
end

local function reskinBattlegroundListScroll()
  local scroll = _G.PVPBattlegroundFrameTypeScrollFrame
  if not scroll or scroll._neReskinned then return end
  local barName = scroll:GetName() and (scroll:GetName() .. "ScrollBar")
  scroll.ScrollBar = scroll.ScrollBar or (barName and _G[barName])
  if not scroll.ScrollBar then return end
  scroll._neReskinned = true

  local scrollName = scroll:GetName()
  if scrollName then
    buryTexture(_G[scrollName .. "ScrollBarTop"])
    buryTexture(_G[scrollName .. "ScrollBarBottom"])
    buryTexture(_G[scrollName .. "ScrollBarMiddle"])
  end
  buryScrollChrome(scroll)
  buryScrollChrome(scroll.ScrollBar)
  local parent = scroll:GetParent()
  if parent and parent.GetRegions then
    local regions = { parent:GetRegions() }
    for i = 1, #regions do
      local r = regions[i]
      local n = r and r.GetName and r:GetName()
      if n and n:find("ScrollBar", 1, true) then
        buryTexture(r)
      end
    end
  end
  if barName then
    for _, suffix in ipairs({ "Top", "Bottom", "Middle", "BG", "ThumbTexture" }) do
      buryTexture(_G[barName .. suffix])
    end
  end
  scroll:HookScript("OnShow", function()
    buryScrollChrome(scroll)
    buryScrollChrome(scroll.ScrollBar)
  end)

  if NE.scrollbar and NE.scrollbar.BuildCustom then
    local ok, bar = pcall(NE.scrollbar.BuildCustom, scroll, { x = -4, alwaysShow = true })
    if ok and bar and NE.scrollbar.Raise then
      NE.scrollbar.Raise(bar, "DIALOG", (scroll:GetFrameLevel() or 1) + 10)
    end
  end
end

-- Gold inset ring around the selected-BG map art (PVPBattlegroundFrameBGTex + lore text over it).
local function frameBattlegroundMap()
  local bgFrame = _G.PVPBattlegroundFrame
  local tex = _G.PVPBattlegroundFrameBGTex
  if not (bgFrame and tex) then return end

  centerBattlegroundContent()

  local ring = bgFrame._neMapRing
  if not ring then
    ring = CreateFrame("Frame", FRAME_NAME .. "BGMapRing", bgFrame)
    ring:EnableMouse(false)
    bgFrame._neMapRing = ring
    if NE.nineslice and NE.nineslice.AttachInset then
      NE.nineslice.AttachInset(ring, 0, 0, 0, 0)
    end
  end

  ring:ClearAllPoints()
  -- Was tex±3 (width +6); pull sides in so width drops ~5px.
  ring:SetPoint("TOPLEFT", tex, "TOPLEFT", 0, 3)
  ring:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 1, -3)
  local base = bgFrame:GetFrameLevel() or 1
  local scroll = _G.PVPBattlegroundFrameInfoScrollFrame
  local scrollLevel = scroll and scroll:GetFrameLevel() or (base + 5)
  ring:SetFrameLevel(math.max(base + 4, scrollLevel - 1))
  ring:Show()
  reskinBattlegroundListScroll()
end

local function resweepStockChrome()
  stripParentChrome()
  if _G.PVPFrame then stripFrameChrome(_G.PVPFrame) end
  if _G.PVPBattlegroundFrame then stripFrameChrome(_G.PVPBattlegroundFrame) end
end

-- ---------------------------------------------------------------------------
-- Panels + tabs
-- ---------------------------------------------------------------------------
local function buildHonorArenaWells(panel)
  if panel._neSplit then return end
  panel._neSplit = true
  -- Stock PVPFrame is centered in this panel. Honor (points + kill table) occupies the top
  -- of that frame; Arena (points + the three teams) sits below it. Two wells, rock between.
  local honor = CreateFrame("Frame", FRAME_NAME .. "HonorWell", panel)
  honor:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -3)
  honor:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -3)
  honor:SetHeight(108)
  dressPanelInset(honor)

  local arena = CreateFrame("Frame", FRAME_NAME .. "ArenaWell", panel)
  arena:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -125)
  arena:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -125)
  arena:SetHeight(304)
  dressPanelInset(arena)

  panel.HonorWell = honor
  panel.ArenaWell = arena
end

local function buildPanels(f)
  for _, t in ipairs(TABS) do
    local p = CreateFrame("Frame", FRAME_NAME .. t.panel, f)
    p:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -56)
    p:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 36)
    p:Hide()
    if t.mode == "BG" then
      dressPanelInset(p)
      shortenBattlegroundWell(p)
    else
      buildHonorArenaWells(p)
    end
    f[t.panel] = p
  end
end

local function buildTabs(f)
  f._tabNames = {}
  f._tabIds = {}
  for i, t in ipairs(TABS) do
    local name = FRAME_NAME .. "Tab" .. i
    local tab = CreateFrame("Button", name, f, "CharacterFrameTabButtonTemplate")
    tab:SetID(i)
    tab:SetText(t.label)
    tab._mode = t.mode
    tab:SetScript("OnClick", function(self) P.SetMode(self._mode, true) end)
    f._tabNames[#f._tabNames + 1] = name
    f._tabIds[t.mode] = i
    if NE.tabs and NE.tabs.ReskinClassicTab then NE.tabs.ReskinClassicTab(name) end
  end
  if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(f, #TABS) end
  if NE.tabs and NE.tabs.SizeAndAnchorTabs then
    NE.tabs.SizeAndAnchorTabs(f, f._tabNames, { startX = 16, startY = 2, parentPoint = "BOTTOMLEFT" })
  end
end

local function syncStockTab(mode)
  -- Keep PanelTemplates / PVPBattlegroundFrame_UpdateVisible in sync with our tab.
  local parent = _G.PVPParentFrame
  if not parent then return end

  -- Stock PVPFrame_OnHide always calls PVPFrame_SetJustBG(false). While we are in just-BG
  -- mode, hiding PVPFrame for the Battlegrounds tab must not clear that flag.
  local restore
  if mode == "BG" and parent.justBG and type(_G.PVPFrame_SetJustBG) == "function" then
    restore = _G.PVPFrame_SetJustBG
    _G.PVPFrame_SetJustBG = function() end
  end

  if mode == "BG" then
    if _G.PVPFrame and _G.PVPFrame:IsShown() then _G.PVPFrame:Hide() end
    if _G.PVPBattlegroundFrame then _G.PVPBattlegroundFrame:Show() end
    if PanelTemplates_SetTab then PanelTemplates_SetTab(parent, 2) end
  else
    if _G.PVPBattlegroundFrame and _G.PVPBattlegroundFrame:IsShown() then _G.PVPBattlegroundFrame:Hide() end
    if _G.PVPFrame then _G.PVPFrame:Show() end
    if PanelTemplates_SetTab then PanelTemplates_SetTab(parent, 1) end
  end

  if restore then _G.PVPFrame_SetJustBG = restore end
end

local function updateJustBGTabs(f)
  local justBG = _G.PVPFrame_IsJustBG and _G.PVPFrame_IsJustBG()
  f._justBG = justBG and true or false
  local names = {}
  for i, t in ipairs(TABS) do
    local tab = _G[FRAME_NAME .. "Tab" .. i]
    if justBG and t.mode == "HONOR" then
      if tab then tab:Hide() end
    else
      if tab then tab:Show() end
      names[#names + 1] = FRAME_NAME .. "Tab" .. i
    end
  end
  if NE.tabs and NE.tabs.SizeAndAnchorTabs then
    NE.tabs.SizeAndAnchorTabs(f, names, { startX = 16, startY = 2, parentPoint = "BOTTOMLEFT" })
  end
end

function P.SetMode(mode, userInitiated)
  local f = P.frame
  if not f then return end
  if f._justBG then mode = "BG" end

  for _, t in ipairs(TABS) do
    if f[t.panel] then f[t.panel]:SetShown(t.mode == mode) end
  end
  f._mode = mode
  local id = f._tabIds[mode]
  if id then
    f._currentTab = id
    if PanelTemplates_SetTab then PanelTemplates_SetTab(f, id) end
  end
  setTitleForMode(f, mode)
  syncStockTab(mode)
  resweepStockChrome()
  if mode == "HONOR" then shiftArenaTeams() end
  if mode == "BG" then frameBattlegroundMap() end

  if userInitiated and PlaySound then PlaySound("igCharacterInfoTab") end
end

local function ensureEmbedded()
  local f = P.frame
  if not f or f._embedded then
    if f and f._embedded then frameBattlegroundMap() end
    return
  end
  if not (_G.PVPFrame and _G.PVPBattlegroundFrame) then return end

  stripParentChrome()
  embedStockPane(_G.PVPFrame, f.HonorPanel)
  embedStockPane(_G.PVPBattlegroundFrame, f.BGPanel)
  shiftArenaTeams()
  frameBattlegroundMap()

  -- Team details popup stays usable above the shell.
  local details = _G.PVPTeamDetails
  if details then
    details:SetParent(f)
    details:SetFrameStrata(f:GetFrameStrata() or "DIALOG")
    details:SetFrameLevel((f:GetFrameLevel() or 1) + 50)
  end

  f._embedded = true
end

-- ---------------------------------------------------------------------------
-- Construction + show/hide
-- ---------------------------------------------------------------------------
local function createWindow()
  if P.frame then return P.frame end

  local f = CreateFrame("Frame", FRAME_NAME, UIParent)
  if NE.buttonskin and NE.buttonskin.Watch then pcall(NE.buttonskin.Watch, f) end
  f:SetSize(PVP_SIZE.w, PVP_SIZE.h)
  f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  f:Hide()
  P.frame = f

  buildChrome(f)
  buildPanels(f)
  buildTabs(f)

  f:HookScript("OnShow", function(self)
    ensureEmbedded()
    resweepStockChrome()
    applyPVPPortrait(self.PortraitTex)
    updateJustBGTabs(self)
    local mode = self._justBG and "BG" or (self._mode or "HONOR")
    P.SetMode(mode)
    if _G.PVPFrame_OnShow and _G.PVPFrame and mode == "HONOR" then
      -- Refresh honor/arena data without relying on the stock parent show path.
      if PVPFrame_SetFaction then PVPFrame_SetFaction() end
      if PVPFrame_Update then PVPFrame_Update() end
    end
    if mode == "BG" and PVPBattleground_UpdateBattlegrounds then
      pcall(PVPBattleground_UpdateBattlegrounds)
    end
    -- PVPFrame_SetFaction / updates can re-show the parchment plate — sweep again.
    resweepStockChrome()
    if UpdateMicroButtons then UpdateMicroButtons() end
  end)

  f:HookScript("OnHide", function()
    -- Clear just-BG when the player closes our shell (matches stock leaving justBG).
    if _G.PVPFrame_IsJustBG and _G.PVPFrame_IsJustBG() and _G.PVPFrame_SetJustBG then
      -- Avoid re-entrancy into our Show; only clear the flag + CloseBattlefield.
      local parent = _G.PVPParentFrame
      if parent then parent.justBG = false end
      if CloseBattlefield then CloseBattlefield() end
      if PVPBattlegroundFrame_UpdateVisible then PVPBattlegroundFrame_UpdateVisible() end
    end
    if UpdateMicroButtons then UpdateMicroButtons() end
  end)

  if NE.FrameUtil and NE.FrameUtil.WirePanelSounds then
    NE.FrameUtil.WirePanelSounds(f, "igCharacterInfoOpen", "igCharacterInfoClose")
  end
  if NE.FrameUtil and NE.FrameUtil.EscClose then NE.FrameUtil.EscClose(FRAME_NAME) end

  if NE.scale and NE.scale.Apply and NE.scale.SetFrame then
    pcall(NE.scale.SetFrame, "pvp", f)
    pcall(NE.scale.Apply, "pvp")
  elseif NE.panelchrome and NE.panelchrome.PinPixelPerfect then
    NE.panelchrome.PinPixelPerfect(f)
  end

  if NE.panelmgr and NE.panelmgr.Register then NE.panelmgr.Register(f) end

  return f
end
P.Create = createWindow

function P.Show(mode)
  if not isModuleEnabled() then return end
  if not P.IsUnlocked() then
    if UIErrorsFrame then UIErrorsFrame:AddMessage(lockedMessage(), 1.0, 0.1, 0.1, 1.0) end
    return
  end
  local f = createWindow()
  ensureEmbedded()
  updateJustBGTabs(f)
  if f._justBG then mode = "BG" end
  f:Show()
  if mode then P.SetMode(mode) end
end

function P.Hide()
  if P.frame then P.frame:Hide() end
end

function P.Toggle(mode)
  if not isModuleEnabled() then return end
  if not P.IsUnlocked() then
    if UIErrorsFrame then UIErrorsFrame:AddMessage(lockedMessage(), 1.0, 0.1, 0.1, 1.0) end
    return
  end
  -- Stock TogglePVPFrame exits just-BG instead of toggling the parent.
  if _G.PVPFrame_IsJustBG and _G.PVPFrame_IsJustBG() then
    if _G.PVPFrame_SetJustBG then _G.PVPFrame_SetJustBG(false) end
    P.Hide()
    return
  end
  local f = createWindow()
  if f:IsShown() then
    if mode and mode ~= f._mode then
      P.SetMode(mode, true)
    else
      P.Hide()
    end
  else
    P.Show(mode)
  end
end

-- Keep our tabs in sync when stock just-BG flips (NPC queue / battlefield close).
if type(_G.PVPFrame_SetJustBG) == "function" then
  hooksecurefunc("PVPFrame_SetJustBG", function(justBG)
    if not isModuleEnabled() then return end
    local f = P.frame
    if not f then return end
    updateJustBGTabs(f)
    if justBG then
      if not f:IsShown() then P.Show("BG") else P.SetMode("BG") end
    end
  end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
  if isModuleEnabled() then createWindow() end
  if NE.RegisterPanel then
    NE.RegisterPanel({
      id = MODULE,
      title = PLAYER_V_PLAYER or "Player vs. Player",
      desc = (LOC and LOC["Modern PvP window over Honor/Arena and Battlegrounds."])
             or "Modern PvP window over Honor/Arena and Battlegrounds.",
      frame = P.frame,
      openFn = function() P.Show() end,
      closeFn = P.Hide,
      order = 65,
    })
  end
end)
