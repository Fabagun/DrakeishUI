-- DragonUI_NewEra/modules/talents/LoadoutsUI.lua — talent loadouts UI (Phase 2a).
--
-- The user-facing layer over Loadouts.lua (the data layer): a "Loadouts" button on the talent
-- window's bottom bar that opens a panel listing saved builds, with Save current / Import / Export /
-- Load / Rename / Delete, plus the "Server uses custom talents" guard toggle + server label.
--
-- Apply path: Load stages the build into the live preview (Loadouts.T.LO_StageBuild) and the user
-- commits with the existing bottom-bar Apply button. Import runs the compatibility guard
-- (T.LO_ImportString) and routes a mismatch through a confirm dialog before saving.

local NE = DrakeishUI_SocialNE
local L = NE.L
local T = NE.talents or {}
NE.talents = T

local ROWS  = 9      -- visible saved-build rows
local ROW_H = 22

-- ----------------------------------------------------------------------------
-- StaticPopups (text I/O — single-line edit boxes, the untainted 3.3.5a way).
-- ----------------------------------------------------------------------------
local function refresh() if T.LO_RefreshPanel then T.LO_RefreshPanel() end end
local function msg(s) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffLoadouts|r: " .. tostring(s)) end
local showLoadoutPopup

StaticPopupDialogs["DrakeishUI_TALENT_LO_SAVE"] = {
  text = L["Name this loadout (saves your current spec):"],
  button1 = SAVE or "Save", button2 = CANCEL or "Cancel",
  hasEditBox = 1, maxLetters = 40, timeout = 0, whileDead = 1, hideOnEscape = 1,
  OnAccept = function(self)
    local name = (self.editBox or self.EditBox):GetText()
    if name and name ~= "" then
      if T.LO_SaveCurrent(name) then msg("saved '" .. name .. "'.") else msg("could not save.") end
      refresh()
    end
  end,
  EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_RENAME"] = {
  text = L["Rename loadout:"],
  button1 = OKAY or "OK", button2 = CANCEL or "Cancel",
  hasEditBox = 1, maxLetters = 40, timeout = 0, whileDead = 1, hideOnEscape = 1,
  OnShow = function(self) (self.editBox or self.EditBox):SetText(T._loSelected or "") end,
  OnAccept = function(self)
    local newName = (self.editBox or self.EditBox):GetText()
    if T._loSelected and newName and newName ~= "" then
      if T.LO_Rename(T._loSelected, newName) then T._loSelected = newName else msg("rename failed (name taken?).") end
      refresh()
    end
  end,
  EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_DELETE"] = {
  text = L["Delete loadout '%s'?"],
  button1 = DELETE or "Delete", button2 = CANCEL or "Cancel",
  timeout = 0, whileDead = 1, hideOnEscape = 1, showAlert = 1,
  OnAccept = function() if T._loSelected then T.LO_Delete(T._loSelected); T._loSelected = nil; refresh() end end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_EXPORT"] = {
  text = L["Copy this build string (Ctrl+C). Talented & the WoWhead/wotlkdb calculators import it too:"],
  button1 = CLOSE or "Close",
  hasEditBox = 1, editBoxWidth = 260, timeout = 0, whileDead = 1, hideOnEscape = 1,
  OnShow = function(self)
    local eb = self.editBox or self.EditBox
    eb:SetText(T._loExportText or "")
    eb:HighlightText(); eb:SetFocus()
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_IMPORT"] = {
  text = L["Paste a talent string or calculator URL (Talented / WoWhead / wotlkdb):"],
  button1 = OKAY or "OK", button2 = CANCEL or "Cancel",
  hasEditBox = 1, editBoxWidth = 260, maxLetters = 400, timeout = 0, whileDead = 1, hideOnEscape = 1,
  OnAccept = function(self) if T.LO_ImportFromText then T.LO_ImportFromText((self.editBox or self.EditBox):GetText()) end end,
  EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_IMPORT_WARN"] = {
  text = L["%s\n\nImport anyway?"],
  button1 = YES or "Yes", button2 = NO or "No",
  timeout = 0, whileDead = 1, hideOnEscape = 1, showAlert = 1,
  OnAccept = function() showLoadoutPopup("DrakeishUI_TALENT_LO_IMPORT_NAME") end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_IMPORT_NAME"] = {
  text = L["Name this imported loadout:"],
  button1 = SAVE or "Save", button2 = CANCEL or "Cancel",
  hasEditBox = 1, maxLetters = 40, timeout = 0, whileDead = 1, hideOnEscape = 1,
  OnAccept = function(self)
    local name = (self.editBox or self.EditBox):GetText()
    if name and name ~= "" and T._loPendingImport then
      T.LO_Save(name, T._loPendingImport); T._loPendingImport = nil; refresh()
      msg("imported '" .. name .. "'.")
    end
  end,
  EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
}

StaticPopupDialogs["DrakeishUI_TALENT_LO_CONFLICT"] = {
  text = "%s",
  button1 = OKAY or "OK",
  timeout = 0, whileDead = 1, hideOnEscape = 1, showAlert = 1,
}

-- The stock StaticPopup is shared with every other dialog in the game, so these prompts get
-- their own frame. Same metal border, rock fill, and red buttons as the Loadouts window.
local prompt
local function ensurePrompt()
  if prompt then return prompt end
  prompt = CreateFrame("Frame", "DrakeishUI_TalentLoadoutPrompt", UIParent)
  prompt:SetSize(440, 160)
  prompt:SetPoint("CENTER", UIParent, "CENTER", 0, 90)
  prompt:SetFrameStrata("FULLSCREEN_DIALOG")
  prompt:EnableMouse(true)
  prompt:Hide()
  tinsert(UISpecialFrames, "DrakeishUI_TalentLoadoutPrompt")

  local PC = NE.panelchrome
  if PC and PC.Apply then
    PC.Apply(prompt, {
      layout = "ButtonFrameTemplateNoPortrait",
      noPortrait = true,
      noCloseButton = true,
    })
    if prompt.Bg then
      prompt.Bg:ClearAllPoints()
      prompt.Bg:SetPoint("TOPLEFT", prompt, "TOPLEFT", 6, -20)
      prompt.Bg:SetPoint("BOTTOMRIGHT", prompt, "BOTTOMRIGHT", -2, 2)
    end
  end

  prompt.text = prompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  prompt.text:SetPoint("TOP", prompt, "TOP", 0, -32)
  prompt.text:SetWidth(392)
  prompt.text:SetJustifyH("CENTER")
  prompt.text:SetJustifyV("TOP")

  prompt.editWell = CreateFrame("Frame", nil, prompt)
  prompt.editWell:SetSize(232, 26)
  local fill = prompt.editWell:CreateTexture(nil, "BACKGROUND")
  fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetVertexColor(0.06, 0.06, 0.07, 0.9)
  fill:SetAllPoints(prompt.editWell)
  if NE.nineslice and NE.nineslice.AttachInset then
    prompt.editWell.Inset = NE.nineslice.AttachInset(prompt.editWell, 0, 0, 0, 0)
  end

  prompt.editBox = CreateFrame("EditBox", nil, prompt)
  prompt.editBox:SetFontObject(ChatFontNormal)
  prompt.editBox:SetAutoFocus(false)
  prompt.editBox:SetJustifyH("CENTER")
  prompt.editBox:SetHeight(18)
  prompt.editBox:SetScript("OnEscapePressed", function() prompt:Hide() end)
  prompt.editBox:SetScript("OnEnterPressed", function() prompt.button1:Click() end)

  local function makeBtn(name)
    local b = CreateFrame("Button", name, prompt, "UIPanelButtonTemplate")
    b:SetSize(120, 24)
    return b
  end
  prompt.button1 = makeBtn("DrakeishUI_TalentLoadoutPromptAccept")
  prompt.button2 = makeBtn("DrakeishUI_TalentLoadoutPromptCancel")
  prompt.button1:SetScript("OnClick", function()
    local which = prompt._which
    local fn = prompt._onAccept
    if fn then fn(prompt) end
    if prompt._which == which then prompt:Hide() end
  end)
  prompt.button2:SetScript("OnClick", function() prompt:Hide() end)

  local chromeLevel = ((prompt.NineSlice and prompt.NineSlice.GetFrameLevel and prompt.NineSlice:GetFrameLevel()) or prompt:GetFrameLevel() or 1) + 5
  local kids = { prompt:GetChildren() }
  for i = 1, #kids do
    local c = kids[i]
    if c and c ~= prompt.NineSlice and c ~= prompt._neTitleBand and c.SetFrameLevel then
      c:SetFrameLevel(chromeLevel)
    end
  end
  if prompt.editBox.SetFrameLevel then prompt.editBox:SetFrameLevel(chromeLevel + 2) end
  if NE.buttonskin and NE.buttonskin.SkinPanelButtons then
    NE.buttonskin.SkinPanelButtons(prompt)
  end

  function prompt:Layout()
    self.text:SetWidth(self:GetWidth() - 48)
    local textH = self.text:GetStringHeight() or 16
    if textH < 16 then textH = 16 end
    local y = 32 + textH + 12
    if self.editWell:IsShown() then
      self.editWell:ClearAllPoints()
      self.editWell:SetPoint("TOP", self, "TOP", 0, -y)
      self.editBox:ClearAllPoints()
      self.editBox:SetPoint("LEFT", self.editWell, "LEFT", 8, 0)
      self.editBox:SetPoint("RIGHT", self.editWell, "RIGHT", -8, 0)
      y = y + self.editWell:GetHeight() + 14
    end
    self:SetHeight(y + 24 + 18)
    self.button1:ClearAllPoints()
    self.button2:ClearAllPoints()
    if self.button2:IsShown() then
      self.button1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -8, 16)
      self.button2:SetPoint("BOTTOMLEFT", self, "BOTTOM", 8, 16)
    else
      self.button1:SetPoint("BOTTOM", self, "BOTTOM", 0, 16)
    end
  end
  prompt:SetScript("OnShow", function(self) self:Layout() end)
  return prompt
end

showLoadoutPopup = function(which, textArg)
  local d = StaticPopupDialogs[which]
  if not d then return end
  local f = ensurePrompt()
  local text = d.text or ""
  if textArg ~= nil then
    local ok, formatted = pcall(string.format, text, textArg)
    if ok then text = formatted end
  end
  f._which = which
  f._onAccept = d.OnAccept
  f.text:SetText(text)
  f.button1:SetText(d.button1 or OKAY or "OK")
  if d.button2 then
    f.button2:SetText(d.button2)
    f.button2:Show()
  else
    f.button2:Hide()
  end
  if d.hasEditBox then
    f.editWell:Show()
    f.editBox:Show()
    f.editBox:SetMaxLetters(d.maxLetters or 255)
    local w = d.editBoxWidth or 220
    f.editWell:SetWidth(w + 16)
    f.editBox:SetText("")
  else
    f.editWell:Hide()
    f.editBox:Hide()
  end
  f:Show()
  f:Layout()
  if d.OnShow then d.OnShow(f) end
  if d.hasEditBox then f.editBox:SetFocus(); f.editBox:HighlightText() end
end

-- ----------------------------------------------------------------------------
-- Flow helpers (referenced by the popups + buttons).
-- ----------------------------------------------------------------------------
function T.LO_ImportFromText(text)
  local build, verdict = T.LO_ImportString(text)
  if not build then msg(verdict and verdict.error or "could not read that string."); return end
  T._loPendingImport = build
  if verdict.warn then
    StaticPopupDialogs["DrakeishUI_TALENT_LO_IMPORT_WARN"].text = verdict.reason .. "\n\nImport anyway?"
    showLoadoutPopup("DrakeishUI_TALENT_LO_IMPORT_WARN")
  else
    showLoadoutPopup("DrakeishUI_TALENT_LO_IMPORT_NAME")
  end
end

local function exportText(name)
  local code, url, tagged
  if name then code, url, tagged = T.LO_Encode(T.LO_Get(name)) else code, url, tagged = T.LO_ExportCurrent() end
  T._loExportText = tagged or code
  if T._loExportText then showLoadoutPopup("DrakeishUI_TALENT_LO_EXPORT") else msg("nothing to export.") end
end

local function loadBuild(name)
  local b = T.LO_Get(name); if not b then return end
  local ok, conflicts = T.LO_StageBuild(b)
  if T.LO_HidePanel then T.LO_HidePanel() end
  if not ok and conflicts and #conflicts > 0 then
    local lines = {}
    for i = 1, math.min(#conflicts, 6) do
      local c = conflicts[i]
      lines[#lines + 1] = L["  %s: have %d, build wants %d"]:format(c.name, c.have or 0, c.want or 0)
    end
    StaticPopupDialogs["DrakeishUI_TALENT_LO_CONFLICT"].text =
      L["This loadout has fewer points in some talents than you've already spent, so it needs a respec first:\n"]
      .. table.concat(lines, "\n")
      .. L["\n\nReset at a class trainer, then load again. (The rest has been staged — click Apply to learn it.)"]
    showLoadoutPopup("DrakeishUI_TALENT_LO_CONFLICT")
  else
    msg("staged '" .. name .. "' — review the highlighted talents and click Apply to learn.")
  end
end

-- ----------------------------------------------------------------------------
-- The panel.
-- ----------------------------------------------------------------------------
local panel

local function styleButton(b)
  return b   -- UIPanelButtonTemplate already matches the bottom-bar Apply/Reset look
end

local function buildPanel()
  if panel then return panel end
  local host = T.frame or UIParent
  panel = CreateFrame("Frame", "DrakeishUI_TalentLoadouts", host)
  panel:SetSize(380, 460)
  panel:SetPoint("CENTER", host, "CENTER", 0, 10)
  panel:SetFrameStrata("DIALOG")
  panel:EnableMouse(true)
  panel:Hide()

  -- Same metal frame and rock body as the other windows. The stock dialog border sat on top of it.
  local PC = NE.panelchrome
  if PC and PC.Apply then
    PC.Apply(panel, {
      layout = "ButtonFrameTemplateNoPortrait",
      noPortrait = true,
      title = L["Loadouts"],
    })
    local fs = panel._neTitle or panel.Title
    if fs then
      fs:ClearAllPoints()
      fs:SetPoint("TOP", panel, "TOP", 0, -5)
      fs:SetJustifyH("CENTER")
    end
    if panel.Bg then
      panel.Bg:ClearAllPoints()
      panel.Bg:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -20)
      panel.Bg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    end
  elseif panel.SetBackdrop then
    panel:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
  end

  -- Top actions: Save current, Import.
  local save = styleButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
  save:SetSize(150, 24); save:SetPoint("TOPLEFT", 16, -44); save:SetText(L["Save current spec…"])
  save:SetScript("OnClick", function() showLoadoutPopup("DrakeishUI_TALENT_LO_SAVE") end)

  local import = styleButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
  import:SetSize(150, 24); import:SetPoint("TOPRIGHT", -16, -44); import:SetText(L["Import…"])
  import:SetScript("OnClick", function() showLoadoutPopup("DrakeishUI_TALENT_LO_IMPORT") end)

  -- Saved-build list (FauxScrollFrame — must be NAMED on 3.3.5a).
  local listBG = CreateFrame("Frame", nil, panel)
  listBG:SetPoint("TOPLEFT", 16, -78)
  listBG:SetPoint("TOPRIGHT", -16, -78)
  listBG:SetHeight(ROWS * ROW_H + 8)
  local listFill = listBG:CreateTexture(nil, "BACKGROUND")
  listFill:SetTexture("Interface\\Buttons\\WHITE8X8")
  listFill:SetVertexColor(0.06, 0.06, 0.07, 0.75)
  listFill:SetAllPoints(listBG)
  if NE.nineslice and NE.nineslice.AttachInset then
    listBG.InsetBorder = NE.nineslice.AttachInset(listBG, 0, 0, 0, 0)
  end

  local scroll = CreateFrame("ScrollFrame", "DrakeishUI_TalentLoadoutsScroll", listBG, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", -26, 4)
  scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, T.LO_RefreshPanel)
  end)
  panel.scroll = scroll

  panel.rows = {}
  for i = 1, ROWS do
    local row = CreateFrame("Button", nil, listBG)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -((i - 1) * ROW_H))
    row:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD"); hl:SetAlpha(0.4)
    local sel = row:CreateTexture(nil, "ARTWORK")
    sel:SetAllPoints(); sel:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    sel:SetBlendMode("ADD"); sel:SetAlpha(0.55); sel:Hide()
    row.sel = sel
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", 6, 0)
    row.pts = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.pts:SetPoint("RIGHT", -8, 0)
    row:SetScript("OnClick", function(self)
      T._loSelected = self._name
      T.LO_RefreshPanel()
    end)
    panel.rows[i] = row
  end

  -- Per-selection actions.
  local function actBtn(label, x, w, onClick)
    local b = styleButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
    b:SetSize(w, 24)
    b:SetPoint("TOPLEFT", 16 + x, -(78 + ROWS * ROW_H + 16))
    b:SetText(label); b:SetScript("OnClick", onClick)
    return b
  end
  panel.bLoad   = actBtn("Load",   0,   84, function() if T._loSelected then loadBuild(T._loSelected) end end)
  panel.bExport = actBtn("Export", 88,  84, function() if T._loSelected then exportText(T._loSelected) end end)
  panel.bRename = actBtn("Rename", 176, 84, function() if T._loSelected then showLoadoutPopup("DrakeishUI_TALENT_LO_RENAME") end end)
  panel.bDelete = actBtn("Delete", 264, 84, function() if T._loSelected then showLoadoutPopup("DrakeishUI_TALENT_LO_DELETE", T._loSelected) end end)

  -- Custom-talent guard toggle. (The server label in exports/warnings is taken automatically from
  -- the realm name — see T.LO_ServerLabel — so there's no manual field to get wrong.)
  local cb = CreateFrame("CheckButton", "DrakeishUI_TalentLoadoutsCustomCB", panel, "UICheckButtonTemplate")
  cb:SetPoint("BOTTOMLEFT", 14, 34)
  cb:SetSize(24, 24)
  local cbText = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cbText:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  cbText:SetText(L["Server uses custom talents"])
  cb:SetChecked(T.LO_IsCustomServer())
  cb:SetScript("OnClick", function(self) T.LO_SetCustomServer(self:GetChecked() and true or false) end)
  panel.cb = cb

  local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 16, 16)
  hint:SetPoint("BOTTOMRIGHT", -16, 16)
  hint:SetJustifyH("LEFT")
  hint:SetText(L["Tags exported builds with this realm so imports onto other layouts warn first."])

  -- The metal nineslice paints above the frame. Lift the list, buttons, and close X over it.
  local chromeLevel = ((panel.NineSlice and panel.NineSlice.GetFrameLevel and panel.NineSlice:GetFrameLevel()) or panel:GetFrameLevel() or 1) + 5
  local kids = { panel:GetChildren() }
  for i = 1, #kids do
    local c = kids[i]
    if c and c ~= panel.NineSlice and c ~= panel._neTitleBand and c ~= panel.CloseButton and c.SetFrameLevel then
      c:SetFrameLevel(chromeLevel)
    end
  end
  if panel.CloseButton and panel.CloseButton.SetFrameLevel then
    panel.CloseButton:SetFrameLevel(chromeLevel + 15)
  end
  if NE.buttonskin and NE.buttonskin.SkinPanelButtons then
    NE.buttonskin.SkinPanelButtons(panel)
  end
  if NE.scrollbar and NE.scrollbar.BuildCustom then
    NE.scrollbar.BuildCustom(scroll)
  end

  return panel
end

-- Rebuild the visible list + selection state from the store.
function T.LO_RefreshPanel()
  if not panel or not panel:IsShown() then return end
  local names = T.LO_List()
  local offset = FauxScrollFrame_GetOffset(panel.scroll) or 0
  FauxScrollFrame_Update(panel.scroll, #names, ROWS, ROW_H)
  for i = 1, ROWS do
    local row = panel.rows[i]
    local idx = i + offset
    local name = names[idx]
    if name then
      row._name = name
      row.name:SetText(name)
      row.pts:SetText(T.LO_Summary(T.LO_Get(name) or { ranks = {} }))
      if name == T._loSelected then row.sel:Show() else row.sel:Hide() end   -- no SetShown on 3.3.5a
      row:Show()
    else
      row._name = nil
      row:Hide()
    end
  end
  -- enable/disable per-selection buttons
  local has = T._loSelected and T.LO_Get(T._loSelected) and true or false
  for _, b in ipairs({ panel.bLoad, panel.bExport, panel.bRename, panel.bDelete }) do
    if b then if has then b:Enable() else b:Disable() end end
  end
  -- keep the guard widgets in sync
  if panel.cb then panel.cb:SetChecked(T.LO_IsCustomServer()) end
end

function T.LO_HidePanel() if panel then panel:Hide() end end
function T.LO_TogglePanel()
  buildPanel()
  if panel:IsShown() then panel:Hide() else
    panel:Show()
    T.LO_RefreshPanel()
  end
end

-- ----------------------------------------------------------------------------
-- Bottom-bar "Loadouts" button. Created lazily on the talent frame once it exists.
-- ----------------------------------------------------------------------------
local function ensureBarButton()
  local f = T.frame
  if not f or f._loBtn then return end
  local b = CreateFrame("Button", "DrakeishUI_TalentLoadoutsButton", f, "UIPanelButtonTemplate")
  b:SetSize(120, 26)
  b:SetPoint("BOTTOM", f, "BOTTOM", 0, ((T.FRAME and T.FRAME.CHROME_B) or 0) + 27)
  b:SetText(L["Loadouts"])
  b:SetScript("OnClick", function() T.LO_TogglePanel() end)
  f._loBtn = b
end

-- The scaffold calls T.Populate on show; piggyback to make sure our button exists. We wrap it once.
local function hookPopulate()
  if T._loPopulateHooked then return end
  local orig = T.Populate
  if type(orig) ~= "function" then return end
  T._loPopulateHooked = true
  T.Populate = function(...)
    local r = orig(...)
    ensureBarButton()
    return r
  end
end

-- Loadouts.lua + Behavior.lua load before us (toc order), so T.Populate already exists.
hookPopulate()
