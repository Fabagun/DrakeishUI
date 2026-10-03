-- DrakeishUI_SocialNE/modules/achievements/Window.lua — modern chrome for AchievementFrame.
--
-- Outer shell + a durable height boost. Yellow panes keep stock anchors; only their TOP
-- offsets are nudged down by the same amount as the height boost so a grey band opens
-- above them for the points total — bottoms/widths/sibling layout stay Blizzard's.

local NE = DrakeishUI_SocialNE
if not NE then return end

NE.achievements = NE.achievements or {}
local A = NE.achievements

local TOP_BAND = 56
-- Extra grey above the yellow panes (= how much we grow the window and drop TOP anchors).
local HEIGHT_BOOST = 40

local STOCK_BORDER = {
  "AchievementFrameMetalBorderLeft",
  "AchievementFrameMetalBorderRight",
  "AchievementFrameMetalBorderTop",
  "AchievementFrameMetalBorderBottom",
  "AchievementFrameMetalBorderTopLeft",
  "AchievementFrameMetalBorderTopRight",
  "AchievementFrameMetalBorderBottomLeft",
  "AchievementFrameMetalBorderBottomRight",
  "AchievementFrameWoodBorderTopLeft",
  "AchievementFrameWoodBorderTopRight",
  "AchievementFrameWoodBorderBottomLeft",
  "AchievementFrameWoodBorderBottomRight",
  "AchievementFrameBackground",
}

local HEADER_ART = {
  "AchievementFrameHeaderLeft",
  "AchievementFrameHeaderRight",
  "AchievementFrameHeaderPointBorder",
  "AchievementFrameHeaderRightDDLInset",
  -- Shown when a category is selected (filter dropdown); brown wood residue in the header.
  "AchievementFrameHeaderLeftDDLInset",
}

local TAB_NAMES = {
  "AchievementFrameTab1",
  "AchievementFrameTab2",
}

-- Only these hosts are candidates. We only nudge a host if a TOP* point is relative to
-- AchievementFrame itself — panes anchored to Categories follow it and must not be shifted again.
local YELLOW_HOSTS = {
  "AchievementFrameCategories",
  "AchievementFrameAchievements",
  "AchievementFrameStats",
  "AchievementFrameSummary",
  "AchievementFrameComparison",
}

local function hideNamed(name)
  local r = _G[name]
  if r and r.Hide then r:Hide() end
end

-- Stock scripts keep calling :Show() on wood header art — kill Show so it stays gone.
local function buryNamed(name)
  local r = _G[name]
  if not r or not r.Hide then return end
  r:Hide()
  if not r._neAchBuried and r.Show then
    r._neAchBuried = true
    r.Show = r.Hide
  end
end

local function buryHeaderArt()
  for _, name in ipairs(HEADER_ART) do buryNamed(name) end
end

-- Filter + search sit on stock header anchors (y=+10 / RightDDLInset) and end up under our chrome.
local function placeHeaderControls(f)
  local nsLevel = (f.NineSlice and f.NineSlice:GetFrameLevel()) or (f:GetFrameLevel() or 1)
  local points = _G.AchievementFrameHeaderPoints

  local filter = _G.AchievementFrameFilterDropDown
  if filter then
    if NE.dropdown and NE.dropdown.SkinFilter then
      NE.dropdown.SkinFilter(filter)
    end
    filter:ClearAllPoints()
    -- Same horizontal line as the achievement points total.
    if points then
      filter:SetPoint("TOP", points, "TOP", 0, 0)
      filter:SetPoint("RIGHT", f, "RIGHT", -36, 0)
    else
      filter:SetPoint("TOPRIGHT", f, "TOPRIGHT", -36, -34)
    end
    filter:SetFrameLevel(nsLevel + 20)
    if filter.SetFrameStrata then filter:SetFrameStrata(f:GetFrameStrata() or "MEDIUM") end
  end

  -- Newer clients ship a search box anchored to RightDDLInset (hidden wood) — lift it too.
  local search = f.searchBox or _G.AchievementFrameSearchBox
  if search then
    search:ClearAllPoints()
    if filter then
      search:SetPoint("RIGHT", filter, "LEFT", -8, 0)
      search:SetPoint("TOP", filter, "TOP", 0, 0)
    elseif points then
      search:SetPoint("TOP", points, "TOP", 0, 0)
      search:SetPoint("RIGHT", f, "RIGHT", -36, 0)
    else
      search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -36, -34)
    end
    search:SetFrameLevel(nsLevel + 20)
  end
end

local function rockPath()
  -- Same source Social / PvP use for the modern grey rock body.
  if NE.tex and NE.tex.localFiles and NE.tex.localFiles[374155] then
    return NE.tex.localFiles[374155]
  end
  if NE.tex and NE.tex.Local then
    local p = NE.tex.Local(374155)
    if p then return p end
  end
  return 374155
end

local function paintRockBody(f)
  local body = f.Bg or f.Body
  if not body then
    body = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    f.Bg = body
    f.Body = body
  end
  -- Untinted like Social/PvP — BODY_TINT 0.32 reads near-black in the gutters.
  body:SetTexture(rockPath(), "REPEAT", "REPEAT")
  body:SetHorizTile(true)
  body:SetVertTile(true)
  body:SetVertexColor(1, 1, 1, 1)
  body:SetTexCoord(0, 1, 0, 1)
  body:ClearAllPoints()
  body:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 2)
  body:Show()
  return body
end

-- UIPanel / Blizzard OnShow can reset size; capture base once and re-assert every show.
local function ensureHeight(f)
  local h = f:GetHeight() or 0
  if not f._neAchBaseH then
    if h > 100 then
      f._neAchBaseH = h
    else
      f._neAchBaseH = 500
    end
  end
  local want = f._neAchBaseH + HEIGHT_BOOST
  if math.abs((f:GetHeight() or 0) - want) > 0.5 then
    f:SetHeight(want)
  end
end

-- Shift TOP* anchors down by dy (negative). Leaves BOTTOM* / LEFT / RIGHT points alone.
-- Remembers stock TOP points so we can re-apply after Blizzard OnShow resets anchors.
local function nudgeTopAnchors(frame, dy, root)
  if not frame or not root then return end
  local n = (frame.GetNumPoints and frame:GetNumPoints()) or 0
  if n == 0 then return end

  if not frame._neAchTopOrig then
    local orig = {}
    for i = 1, n do
      local p, rel, rp, x, y = frame:GetPoint(i)
      -- Only TOP points pinned to the achievement window (not to Categories / each other).
      if (p == "TOPLEFT" or p == "TOPRIGHT" or p == "TOP") and (rel == root or rel == nil) then
        orig[#orig + 1] = { p, rel or root, rp, x or 0, y or 0 }
      end
    end
    if #orig == 0 then return end
    frame._neAchTopOrig = orig
  end

  for _, pt in ipairs(frame._neAchTopOrig) do
    frame:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5] + dy)
  end
end

-- Pin the left parchment (+ watermark via its BOTTOMLEFT→BG anchor) inside Categories.
-- CategoriesBG is a sibling texture on AchievementFrame, not a child of Categories.
local function syncCategoriesBG()
  local bg = _G.AchievementFrameCategoriesBG
  local cats = _G.AchievementFrameCategories
  if not (bg and cats) then return end
  -- Fill the yellow frame interior (tooltip-border insets ~5). Do NOT keep stock width 195 —
  -- that is wider than Categories (175) and bleeds into the gap toward the right pane.
  bg:ClearAllPoints()
  bg:SetPoint("TOPLEFT", cats, "TOPLEFT", 5, -5)
  bg:SetPoint("BOTTOMRIGHT", cats, "BOTTOMRIGHT", -5, 5)
end

local function openTopGap()
  local root = _G.AchievementFrame
  if not root then return end
  local dy = -HEIGHT_BOOST
  for _, name in ipairs(YELLOW_HOSTS) do
    nudgeTopAnchors(_G[name], dy, root)
  end
  syncCategoriesBG()
end

local function applyChrome(f)
  if f._neAchChrome then return end
  f._neAchChrome = true

  if f.SetBackdrop then f:SetBackdrop(nil) end
  for _, name in ipairs(STOCK_BORDER) do hideNamed(name) end

  ensureHeight(f)
  paintRockBody(f)

  local streaks = f:CreateTexture(nil, "BORDER")
  if NE.tex and NE.tex.SetAtlas then NE.tex.SetAtlas(streaks, "_UI-Frame-TopTileStreaks", false) end
  streaks:SetHorizTile(true)
  streaks:SetHeight(math.min(43, TOP_BAND - 8))
  streaks:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -4)
  streaks:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -4)
  f.TopTileStreaks = streaks

  local ns = CreateFrame("Frame", nil, f)
  ns:SetAllPoints(f)
  ns:EnableMouse(false)
  if NE.nineslice and NE.nineslice.ApplyLayout then
    NE.nineslice.ApplyLayout(ns, "PortraitFrameTemplate")
  end
  f.NineSlice = ns
  ns:SetFrameLevel((f:GetFrameLevel() or 1) + 8)

  local portrait = ns:CreateTexture(nil, "ARTWORK")
  if NE.portrait and NE.portrait.ApplyCutout then
    NE.portrait.ApplyCutout(portrait, f, { size = 58, anchor = { "TOPLEFT", -4, 7 } })
  else
    portrait:SetSize(58, 58)
    portrait:SetPoint("TOPLEFT", f, "TOPLEFT", -4, 7)
  end
  local achPortrait = (NE.tex and NE.tex.localFiles and NE.tex.localFiles[9001002])
    or "Interface\\AddOns\\DrakeishUI\\assets\\Achievement_window_circle"
  achPortrait = achPortrait:gsub("%.[bB][lL][pP]$", ""):gsub("%.[tT][gG][aA]$", "")
  portrait:SetTexture(achPortrait)
  portrait:SetTexCoord(0, 1, 0, 1)
  f.PortraitTex = portrait

  local stockClose = _G.AchievementFrameCloseButton
  if stockClose then
    stockClose:Hide()
    stockClose:EnableMouse(false)
    if not stockClose._neAchCloseSuppressed then
      stockClose._neAchCloseSuppressed = true
      stockClose:HookScript("OnShow", function(self) self:Hide() end)
    end
  end

  local close = f._neAchClose
  if not close then
    close = CreateFrame("Button", "DrakeishUI_AchievementCloseButton", f, "UIPanelCloseButton")
    f._neAchClose = close
  end
  close:ClearAllPoints()
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 0)
  close:SetScript("OnClick", function()
    if HideUIPanel then HideUIPanel(f) else f:Hide() end
  end)
  if NE.panelchrome and NE.panelchrome.ModernizeCloseButton then
    NE.panelchrome.ModernizeCloseButton(close, { anchor = false })
  end
  close:ClearAllPoints()
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 0)
  close:SetFrameLevel((f:GetFrameLevel() or 1) + 50)
  close:Show()
  f.CloseButton = close
end

local function relocateHeader(f)
  local header = _G.AchievementFrameHeader
  if not header then return end

  for _, name in ipairs(HEADER_ART) do buryNamed(name) end

  header:SetAlpha(1)
  -- BlizzMove uses AchievementFrameHeader as the drag handler — must accept mouse.
  header:EnableMouse(true)
  header:ClearAllPoints()
  header:SetPoint("TOPLEFT", f, "TOPLEFT", 58, -2)
  header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -36, -2)
  header:SetHeight(TOP_BAND - 4)
  header:SetFrameLevel((f.NineSlice and f.NineSlice:GetFrameLevel() or 2) + 12)

  local title = _G.AchievementFrameHeaderTitle
  if title then
    title:ClearAllPoints()
    title:SetPoint("TOP", header, "TOP", 0, -4)
    title:SetJustifyH("CENTER")
  end

  local points = _G.AchievementFrameHeaderPoints
  local shield = _G.AchievementFrameHeaderShield
  if points then
    points:ClearAllPoints()
    -- 10px lower than the prior band position (-22 → -32).
    points:SetPoint("TOP", header, "TOP", -10, -32)
    points:SetJustifyH("CENTER")
  end
  if shield and points then
    shield:ClearAllPoints()
    shield:SetPoint("LEFT", points, "RIGHT", 4, -1)
    shield:Show()
  end

  -- Dedicated title-band drag surface (BlizzMove prefers this when present).
  local handle = _G.DrakeishUIAchievementMoveHandle
  if not handle then
    handle = CreateFrame("Frame", "DrakeishUIAchievementMoveHandle", f)
  end
  handle:ClearAllPoints()
  handle:SetPoint("TOPLEFT", f, "TOPLEFT", 58, -2)
  handle:SetPoint("TOPRIGHT", f, "TOPRIGHT", -36, -2)
  handle:SetHeight(TOP_BAND - 4)
  handle:SetFrameLevel((f.NineSlice and f.NineSlice:GetFrameLevel() or 2) + 15)
  handle:EnableMouse(true)
  handle:Show()
  f:SetMovable(true)
  f:EnableMouse(true)
  if not handle._neAchDragWired then
    handle._neAchDragWired = true
    handle.frameToMove = f
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function(self)
      (self.frameToMove or f):StartMoving()
    end)
    handle:SetScript("OnDragStop", function(self)
      (self.frameToMove or f):StopMovingOrSizing()
    end)
  end

  placeHeaderControls(f)
end

-- Minimal scrollbars in the grey gutters: left of Categories, right of Achievements/Stats.
local SCROLL_PANES = {
  { host = "AchievementFrameCategories",      scroll = "AchievementFrameCategoriesContainer",      side = "LEFT" },
  { host = "AchievementFrameAchievements",    scroll = "AchievementFrameAchievementsContainer",    side = "RIGHT" },
  { host = "AchievementFrameStats",           scroll = "AchievementFrameStatsContainer",           side = "RIGHT" },
  { host = "AchievementFrameComparison",      scroll = "AchievementFrameComparisonContainer",      side = "RIGHT" },
  { host = "AchievementFrameComparisonStats", scroll = "AchievementFrameComparisonStatsContainer", side = "RIGHT" },
}

local BAR_Y_INSET = 7   -- Character-tab track inset (no arrow steppers)
local BAR_GAP = 3       -- air between yellow border and the 8px track

local function placeGutterBar(bar, host, side)
  if not (bar and host) then return end
  bar:ClearAllPoints()
  if side == "LEFT" then
    -- Sit in the grey strip between the window border and the left yellow frame.
    bar:SetPoint("TOPRIGHT", host, "TOPLEFT", -BAR_GAP, -BAR_Y_INSET)
    bar:SetPoint("BOTTOMRIGHT", host, "BOTTOMLEFT", -BAR_GAP, BAR_Y_INSET)
  else
    -- Sit in the grey strip between the right yellow frame and the window border.
    bar:SetPoint("TOPLEFT", host, "TOPRIGHT", BAR_GAP, -BAR_Y_INSET)
    bar:SetPoint("BOTTOMLEFT", host, "BOTTOMRIGHT", BAR_GAP, BAR_Y_INSET)
  end
  bar:SetWidth(8)
  bar:Show()
end

local function setupScrollbars()
  if not (NE.scrollbar and NE.scrollbar.BuildCustom) then return end
  for _, spec in ipairs(SCROLL_PANES) do
    local scroll = _G[spec.scroll]
    local host = _G[spec.host] or scroll
    if scroll then
      if not scroll._neCustomBar then
        -- BuildCustom always parks on TOPRIGHT first; we re-anchor into the gutter below.
        pcall(NE.scrollbar.BuildCustom, scroll, { x = -8 })
      end
      local bar = scroll._neCustomBar
      if bar then
        -- Undo a prior "hide forever" hook from the wheel-only experiment if present.
        if bar._neAchWheelHidden then
          bar._neAchWheelHidden = nil
        end
        placeGutterBar(bar, host, spec.side)
        if not bar._neAchGutterHook then
          bar._neAchGutterHook = true
          bar:HookScript("OnShow", function(b)
            placeGutterBar(b, host, spec.side)
          end)
        end
      end
    end
  end
end

local function hideStockTabHighlights(tabName)
  for _, suffix in ipairs({ "LeftHighlight", "MiddleHighlight", "RightHighlight" }) do
    local tex = _G[tabName .. suffix]
    if tex then
      tex:Hide()
      tex.Show = tex.Hide
    end
  end
  for _, suffix in ipairs({
    "Left", "Middle", "Right",
    "LeftDisabled", "MiddleDisabled", "RightDisabled",
  }) do
    local tex = _G[tabName .. suffix]
    if tex and tex.SetVertexColor then
      tex:SetVertexColor(1, 1, 1, 1)
    end
  end
end

local function reskinTabs(f)
  local names = {}
  for _, name in ipairs(TAB_NAMES) do
    if _G[name] then
      names[#names + 1] = name
      if NE.tabs and NE.tabs.ReskinClassicTab then
        NE.tabs.ReskinClassicTab(name)
      end
      hideStockTabHighlights(name)
    end
  end
  if #names > 0 and NE.tabs and NE.tabs.SizeAndAnchorTabs then
    NE.tabs.SizeAndAnchorTabs(f, names, {
      startX = 16,
      startY = 2,
      gap = 2,
      parentPoint = "BOTTOMLEFT",
    })
  end
end

local function skin()
  local f = _G.AchievementFrame
  if not f or f._neAchSkinned then return end
  f._neAchSkinned = true

  applyChrome(f)
  relocateHeader(f)
  placeHeaderControls(f)
  openTopGap()
  setupScrollbars()
  reskinTabs(f)

  -- Category select re-shows wood DDL insets + filter on stock anchors — bury & re-place.
  local achPane = _G.AchievementFrameAchievements
  if achPane and not achPane._neAchInsetHook then
    achPane._neAchInsetHook = true
    achPane:HookScript("OnShow", function()
      buryHeaderArt()
      placeHeaderControls(f)
    end)
  end

  f:HookScript("OnShow", function(self)
    for _, name in ipairs(STOCK_BORDER) do hideNamed(name) end
    buryHeaderArt()
    if self.SetBackdrop then self:SetBackdrop(nil) end
    ensureHeight(self)
    paintRockBody(self)
    openTopGap()
    setupScrollbars()
    placeHeaderControls(self)
    local close = self._neAchClose or self.CloseButton
    if close then
      close:SetFrameLevel((self:GetFrameLevel() or 1) + 50)
      close:Show()
    end
    local stockClose = _G.AchievementFrameCloseButton
    if stockClose then stockClose:Hide() end
  end)
end
A.Skin = skin

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "Blizzard_AchievementUI" then
    skin()
  elseif event == "PLAYER_LOGIN" then
    if IsAddOnLoaded and IsAddOnLoaded("Blizzard_AchievementUI") then
      skin()
    end
  end
end)
