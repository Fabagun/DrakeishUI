-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.

local addon = select(2, ...)
local CP = addon.CharacterPanel

-- Some 3.3.5a repacks ship a replacement PaperDollFrame in patched FrameXML. Blizzard's widget
-- names survive there as hidden, sizeless, unanchored, unscripted stubs while a parallel set does
-- the work, so every builder that reaches for a stock name silently dresses a dead frame. This puts
-- the stock topology back and stands the replacement down. Every step is gated on the deviation it
-- repairs, so on a stock client the whole file is a no-op.

local SLOT_SIZE = 37
local AMMO_SIZE = 27
local MODEL_W, MODEL_H, MODEL_X, MODEL_Y = 233, 215, 65, -78

local LEFT_COLUMN = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
    "CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
}
local RIGHT_COLUMN = {
    "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
    "CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot",
}
local WEAPON_ROW = { "CharacterMainHandSlot", "CharacterSecondaryHandSlot", "CharacterRangedSlot" }

-- Blizzard's own direct children of PaperDollFrame, verified against 3.3.5a FrameXML. A named child
-- outside this set was put there by the replacement, and is what stands down.
local STOCK_CHILDREN = {
    "PlayerTitleFrame", "PlayerTitlePickerFrame", "CharacterModelFrame",
    "CharacterAttributesFrame", "CharacterResistanceFrame", "CharacterAmmoSlot",
    "GearManagerToggleButton", "PaperDollFrameItemFlyout", "GearManagerDialog",
}
for _, group in ipairs({ LEFT_COLUMN, RIGHT_COLUMN, WEAPON_ROW }) do
    for _, name in ipairs(group) do STOCK_CHILDREN[#STOCK_CHILDREN + 1] = name end
end

local isStockChild = {}
for _, name in ipairs(STOCK_CHILDREN) do isStockChild[name] = true end

-- Where Blizzard parents each widget a replacement is free to have re-homed under its own frames.
local STOCK_PARENT = {
    CharacterModelFrameRotateLeftButton = "CharacterModelFrame",
    CharacterModelFrameRotateRightButton = "CharacterModelFrame",
}
for _, name in ipairs(STOCK_CHILDREN) do STOCK_PARENT[name] = "PaperDollFrame" end

local stoodDown = {}
local topologyRestored, sizeHooked, ammoHooked, announced

-- ---------------------------------------------------------------------------------------------
-- Detection
-- ---------------------------------------------------------------------------------------------

-- Asked of the STOCK widgets, never of how many strangers hang off PaperDollFrame: plenty of addons
-- park a button there, and on a stock client that must not read as a replaced paperdoll.
-- Also detect Patch-ZA / Cata-style paperdoll (EquipInset/NewPanel/Expand) which keeps live
-- stock names but fights CharacterFrame.Inset and panel size every OnShow.
local function paperDollReplaced()
    if type(_G.characterframe_toggle_size) == "function" then return true end
    local pdf = _G.PaperDollFrame
    if pdf and (pdf.NewPanel or pdf.EquipInset or pdf.StatsInset or _G.PaperDollSidebarTabs) then
        return true
    end
    local model = _G.CharacterModelFrame
    if model and not model:GetScript("OnUpdate") then return true end
    local head = _G.CharacterHeadSlot
    if head and head:GetNumPoints() == 0 then return true end
    return false
end

local function foreignChildren()
    local out = {}
    local pdf = _G.PaperDollFrame
    if not pdf then return out end
    for _, child in ipairs({ pdf:GetChildren() }) do
        local name = child.GetName and child:GetName()
        if name and not isStockChild[name] and not child._duiOwned
            and strsub(name, 1, 8) ~= "DrakeishUI" then
            out[#out + 1] = child
        end
    end
    return out
end

-- ---------------------------------------------------------------------------------------------
-- Putting the stock topology back
-- ---------------------------------------------------------------------------------------------

local function rehome(name)
    local f, parent = _G[name], _G[STOCK_PARENT[name]]
    if not f or not parent or not f.SetParent or f:GetParent() == parent then return end
    f:SetParent(parent)
end

-- Only the head of each chain is absolute; slots.lua re-pins those and the rest follows it, which
-- is the whole reason the chain has to exist before that builder runs.
local function chain(names, point, x, y, relPoint, dx, dy)
    local prev
    for _, name in ipairs(names) do
        local slot = _G[name]
        if slot then
            slot._duiRevived = true
            slot:SetSize(SLOT_SIZE, SLOT_SIZE)
            slot:ClearAllPoints()
            if prev then
                slot:SetPoint("TOPLEFT", prev, relPoint, dx, dy)
            else
                slot:SetPoint("TOPLEFT", _G.PaperDollFrame, point, x, y)
            end
            slot:Show()
            prev = slot
        end
    end
    return prev
end

local function restoreSlots()
    chain(LEFT_COLUMN, "TOPLEFT", 21, -74, "BOTTOMLEFT", 0, -4)
    chain(RIGHT_COLUMN, "TOPLEFT", 305, -74, "BOTTOMLEFT", 0, -4)
    local ranged = chain(WEAPON_ROW, "BOTTOMLEFT", 122, 127, "TOPRIGHT", 5, 0)

    local ammo = _G.CharacterAmmoSlot
    if not ammo or not ranged then return end
    ammo._duiRevived = true
    ammo:SetSize(AMMO_SIZE, AMMO_SIZE)
    ammo:ClearAllPoints()
    ammo:SetPoint("LEFT", ranged, "RIGHT", 15, 0)
end

-- Blizzard's PaperDollFrame_OnShow does this for the ammo slot; a replacement does it for its own
-- copy instead, so relic classes would keep an ammo slot they cannot use.
local function applyAmmoVisibility()
    local ammo = _G.CharacterAmmoSlot
    -- The hook outlives a disable, and the slot is the client's own stub again by then.
    if not ammo or not ammo._duiRevived or not CP:Enabled() then return end
    if UnitHasRelicSlot("player") then ammo:Hide() else ammo:Show() end
end

local function hookAmmoVisibility()
    local pdf = _G.PaperDollFrame
    if ammoHooked or not pdf then return end
    ammoHooked = true
    pdf:HookScript("OnShow", applyAmmoVisibility)
end

local function restoreModel()
    local model = _G.CharacterModelFrame
    -- Blizzard's own OnUpdate is the tell: a live model always carries it, a stub never does.
    if not model or model._duiRevived or model:GetScript("OnUpdate") then return end
    model._duiRevived = true
    if _G.Model_OnLoad then _G.Model_OnLoad(model) end
    model:SetSize(MODEL_W, MODEL_H)
    if model:GetNumPoints() == 0 then
        model:SetPoint("TOPLEFT", model:GetParent(), "TOPLEFT", MODEL_X, MODEL_Y)
    end
    if _G.Model_OnUpdate then model:SetScript("OnUpdate", _G.Model_OnUpdate) end
    if _G.CharacterModelFrame_OnMouseUp then
        model:SetScript("OnMouseUp", _G.CharacterModelFrame_OnMouseUp)
        model:SetScript("OnReceiveDrag", _G.CharacterModelFrame_OnMouseUp)
    end
    model:SetScript("OnEvent", function(self, event)
        if event == "DISPLAY_SIZE_CHANGED" then self:RefreshUnit() else self:SetUnit("player") end
    end)
    model:RegisterEvent("DISPLAY_SIZE_CHANGED")
    model:RegisterEvent("UNIT_MODEL_CHANGED")
    model:RegisterEvent("PLAYER_ENTERING_WORLD")
    model:SetUnit("player")
end

-- Split from the repair above so a re-enable without a reload stands the same widgets back up
-- without re-anchoring them: by then those anchors belong to slots.lua and model.lua.
local REVIVED_EXTRA = {
    "CharacterAmmoSlot", "CharacterModelFrame",
    "CharacterModelFrameRotateLeftButton", "CharacterModelFrameRotateRightButton",
}

local function eachRevived(fn)
    for _, group in ipairs({ LEFT_COLUMN, RIGHT_COLUMN, WEAPON_ROW, REVIVED_EXTRA }) do
        for _, name in ipairs(group) do
            local f = _G[name]
            if f and f._duiRevived then fn(f) end
        end
    end
end

local function standUpRevived()
    eachRevived(function(f) f:Show() end)
    applyAmmoVisibility()
end

-- ZA parents Character*Slot under EquipInset. Pull them (and any stock child still there)
-- back to PaperDollFrame before EquipInset is stood down, or they vanish with it.
local function evacuateZaContainers()
    local pdf = _G.PaperDollFrame
    if not pdf then return end
    for _, key in ipairs({ "EquipInset", "NewPanel", "StatsInset" }) do
        local container = pdf[key]
        if container and container.GetChildren then
            for _, child in ipairs({ container:GetChildren() }) do
                local name = child.GetName and child:GetName()
                if name and isStockChild[name] then
                    child:SetParent(pdf)
                    child:Show()
                    child._duiRevived = true
                end
            end
        end
    end
end

local function refreshSlotIcons()
    local update = _G.PaperDollItemSlotButton_Update
    for _, group in ipairs({ LEFT_COLUMN, RIGHT_COLUMN, WEAPON_ROW }) do
        for _, name in ipairs(group) do
            local slot = _G[name]
            if slot then
                slot:Show()
                if type(update) == "function" then pcall(update, slot) end
            end
        end
    end
    local ammo = _G.CharacterAmmoSlot
    if ammo and type(update) == "function" then pcall(update, ammo) end
end

local function restoreTopology()
    evacuateZaContainers()
    for name in pairs(STOCK_PARENT) do rehome(name) end

    if not topologyRestored then
        topologyRestored = true
        restoreSlots()
        restoreModel()
        -- Model_OnUpdate resolves the hold-to-rotate pair by global name off the model it runs on, so
        -- these only answer once they hang under the frame whose name prefixes theirs.
        for _, name in ipairs({ "CharacterModelFrameRotateLeftButton", "CharacterModelFrameRotateRightButton" }) do
            local btn = _G[name]
            if btn and _G.CharacterModelFrame and _G.CharacterModelFrame._duiRevived then
                btn._duiRevived = true
            end
        end
        hookAmmoVisibility()
    else
        -- Reclaim only: do not re-chain anchors (slots.lua owns inset pins after first build).
        standUpRevived()
    end
    refreshSlotIcons()
end

-- ---------------------------------------------------------------------------------------------
-- Standing the replacement down
-- ---------------------------------------------------------------------------------------------

-- Hidden, never unhooked or emptied: the replacement's own code goes on calling Show and SetUnit on
-- these, and neutering Show is what makes those calls harmless instead of an error.
local function standDown(frame)
    if frame._duiStoodDown then return end
    frame._duiStoodDown = true
    frame._duiShow = frame.Show
    frame.Show = frame.Hide
    frame:Hide()
    stoodDown[#stoodDown + 1] = frame
end

-- ---------------------------------------------------------------------------------------------
-- Holding the window's size
-- ---------------------------------------------------------------------------------------------

local reasserting

-- A replacement drives CharacterFrame's size from its own paperdoll and calls that from every
-- show, hide, tab click and name update, which is what kept snapping the panel back.
function CP.ReassertPanelSize()
    local cf = _G.CharacterFrame
    if reasserting or not cf or not cf._duiChromeBuilt then return end
    if not CP:Enabled() or not CP:CanLayout() then return end

    reasserting = true
    local active = (CP.ActiveTabName and CP.ActiveTabName()) or "PaperDollFrame"
    if CP.SetInsetForTab then CP.SetInsetForTab(active) end
    -- After SetInsetForTab, never instead of it: that one owns the narrow width the sidebar widens.
    if cf.InsetRight and cf.InsetRight:IsShown() and CP.EXPANDED_WIDTH then
        cf:SetWidth(CP.EXPANDED_WIDTH)
    end
    if CP.ReanchorCloseButton then CP.ReanchorCloseButton() end
    reasserting = false
end

local function hookExternalResize()
    if sizeHooked then return end
    sizeHooked = true

    if type(_G.characterframe_toggle_size) == "function" then
        hooksecurefunc("characterframe_toggle_size", CP.ReassertPanelSize)
    end

    -- Patch-ZA paperdoll hides CharacterFrame.Inset and calls Expand/Collapse every show/hide.
    -- Pin the inset DrakeishUI chrome owns and snap size back after those calls.
    local reclaiming
    local function reclaimAfterZa()
        if reclaiming or not CP:Enabled() then return end
        reclaiming = true
        local cf = _G.CharacterFrame
        if cf and cf.Inset then
            -- ZA Expand does Inset:Hide(); keep our show path alive even if they call Hide after us.
            if not cf.Inset._duiZaHidePinned then
                cf.Inset._duiZaHidePinned = true
                cf.Inset._duiZaHide = cf.Inset.Hide
                cf.Inset.Hide = function(self)
                    if CP:Enabled() then return end
                    return self._duiZaHide(self)
                end
            end
            cf.Inset:Show()
        end
        -- ZA may have tucked slots back under EquipInset during OnShow; pull them out again.
        restoreTopology()
        if CP.ReanchorEquipmentSlots then CP.ReanchorEquipmentSlots() end
        CP.ReassertPanelSize()
        if CP.ApplyChromeForTab then
            CP.ApplyChromeForTab((CP.ActiveTabName and CP.ActiveTabName()) or "PaperDollFrame")
        end
        -- Level line: pcall so a missing shim never aborts the rest of reclaim.
        if _G.PaperDollFrame_SetLevel then pcall(_G.PaperDollFrame_SetLevel) end
        reclaiming = false
    end

    local pdf = _G.PaperDollFrame
    if pdf and not pdf._duiZaReclaimHooked then
        pdf._duiZaReclaimHooked = true
        pdf:HookScript("OnShow", reclaimAfterZa)
        pdf:HookScript("OnHide", function()
            if CP:Enabled() then CP.ReassertPanelSize() end
        end)
    end

    if type(_G.CharacterFrame_Expand) == "function" and not _G._duiZaExpandHooked then
        _G._duiZaExpandHooked = true
        hooksecurefunc("CharacterFrame_Expand", reclaimAfterZa)
    end
    if type(_G.CharacterFrame_Collapse) == "function" and not _G._duiZaCollapseHooked then
        _G._duiZaCollapseHooked = true
        hooksecurefunc("CharacterFrame_Collapse", reclaimAfterZa)
    end
end

-- ---------------------------------------------------------------------------------------------

local function build()
    if not _G.PaperDollFrame or not paperDollReplaced() then return end

    local foreign = foreignChildren()
    if not announced then
        announced = true
        addon:Debug("CharacterPanel: replacement PaperDollFrame detected, restoring stock topology ("
            .. #foreign .. " foreign widgets)")
    end

    restoreTopology()
    standUpRevived()
    for _, frame in ipairs(foreign) do standDown(frame) end
    -- Named ZA widgets may hang as keys on PaperDollFrame rather than GetChildren() names.
    for _, key in ipairs({ "NewPanel", "EquipInset", "StatsInset" }) do
        local f = _G.PaperDollFrame[key]
        if f then standDown(f) end
    end
    if _G.PaperDollSidebarTabs then standDown(_G.PaperDollSidebarTabs) end
    hookExternalResize()
end

-- The re-parenting and the anchors stay: they repair the CLIENT, not our decoration, and every
-- widget they touch is hidden again below. Undoing them would only reorder the next enable's bugs.
function CP.RestoreCompatHD()
    for _, frame in ipairs(stoodDown) do
        if frame._duiShow then
            frame.Show = frame._duiShow
            frame._duiShow = nil
        end
        frame._duiStoodDown = nil
        frame:Show()
    end
    stoodDown = {}

    local inset = _G.CharacterFrame and _G.CharacterFrame.Inset
    if inset and inset._duiZaHidePinned then
        inset.Hide = inset._duiZaHide
        inset._duiZaHide = nil
        inset._duiZaHidePinned = nil
    end

    eachRevived(function(f) f:Hide() end)
end

CP:RegisterBuilder("compat_hd", build)
