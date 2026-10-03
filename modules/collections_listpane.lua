-- CharacterPanel list helpers used by the Pets & Mounts journal (from DragonUI listpane/reveal).
local addon = select(2, ...)
addon.CharacterPanel = addon.CharacterPanel or {}
local CP = addon.CharacterPanel

-- No section-reveal animation for the collections list.
function CP.ListRevealActive() return false end
function CP.ListRevealAlpha() return 1 end
function CP.ListRevealShift() return 0 end

CP.LIST_ROW_H = 24
CP.LIST_SCROLLBAR_X = -9

local BAR_GUTTER, FLUSH_MARGIN = -22, -6

function CP.NewRowPool(parent, builder)
    return {
        rows = {},
        acquire = function(self)
            for _, row in ipairs(self.rows) do
                if not row._inUse then row._inUse = true; row:Show(); return row end
            end
            local row = builder(parent)
            self.rows[#self.rows + 1] = row
            row._inUse = true
            return row
        end,
        releaseAll = function(self)
            for _, row in ipairs(self.rows) do row._inUse = false; row:Hide() end
        end,
    }
end

function CP.PrewarmRowPools(scroll, rowHeight, pools)
    if not addon.After then return end
    addon:After(0, function()
        local visible = math.floor((scroll:GetHeight() or 0) / rowHeight) + 2
        if visible < 1 then return end
        for _, pool in pairs(pools) do
            for _ = 1, visible do pool:acquire() end
            pool:releaseAll()
        end
    end)
end

function CP.BuildListPane(host, scrollName, rowHeight, repaint, bottomInset, topInset)
    topInset = topInset or 0
    local scroll = CreateFrame("ScrollFrame", scrollName, host, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", host, "TOPLEFT", 6, -(6 + topInset))

    local clipper = CreateFrame("ScrollFrame", nil, host)
    clipper:SetPoint("TOPLEFT", host, "TOPLEFT", 6, -(6 + topInset))
    clipper:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", BAR_GUTTER, 6 + (bottomInset or 0))

    local content, lastRight

    local function sizeContent()
        if not content then return end
        content:SetSize(math.max(1, clipper:GetWidth() or 1),
            math.max(1, clipper:GetHeight() or 1) + rowHeight)
    end

    local function anchorRight()
        if CP.ListRevealActive and CP.ListRevealActive() then return end
        local right = scroll:IsShown() and BAR_GUTTER or FLUSH_MARGIN
        if right ~= lastRight then
            lastRight = right
            scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", right, 6 + (bottomInset or 0))
            clipper:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", right, 6 + (bottomInset or 0))
        end
        sizeContent()
    end
    anchorRight()

    scroll._duiAnchorRight = anchorRight
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, repaint)
    end)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local bar = _G[(self:GetName() or "") .. "ScrollBar"]
        if not bar then return end
        local min, max = bar:GetMinMaxValues()
        local value = bar:GetValue() - delta * rowHeight
        if value < min then value = min elseif value > max then value = max end
        bar:SetValue(value)
    end)
    if CP.ReskinScrollBar then
        CP.ReskinScrollBar(scroll, host, topInset, CP.LIST_SCROLLBAR_X, bottomInset, false)
    end

    content = CreateFrame("Frame", nil, clipper)
    content:SetSize(1, 1)
    clipper:SetScrollChild(content)
    content:SetFrameLevel(scroll:GetFrameLevel() + 5)
    sizeContent()
    clipper:SetScript("OnSizeChanged", sizeContent)

    return scroll, content
end

local painting

function CP.PaintListRows(scroll, content, flat, rowHeight, pools, paint)
    if painting then return end
    painting = true

    for _, pool in pairs(pools) do pool:releaseAll() end

    local visible = math.max(1, math.floor((scroll:GetHeight() or rowHeight) / rowHeight))
    FauxScrollFrame_Update(scroll, #flat, visible, rowHeight)

    local child = scroll:GetScrollChild()
    if child and scroll:IsShown() then
        child:SetHeight((scroll:GetHeight() or 0) + math.max(0, (#flat - visible) * rowHeight))
    end
    if scroll._duiAnchorRight then scroll._duiAnchorRight() end
    if CP.SyncScrollThumb then CP.SyncScrollThumb(scroll) end

    local offset = FauxScrollFrame_GetOffset(scroll) or 0
    local width = content:GetWidth() or 0
    if width <= 0 then
        painting = nil
        return
    end

    for i = 1, visible + 1 do
        local index = offset + i
        local data = flat[index]
        if data then
            local row, indent = paint(data)
            if row then
                indent = indent or 0
                row:ClearAllPoints()
                row:SetWidth(width - indent)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", indent,
                    -(i - 1) * rowHeight + (CP.ListRevealShift(index, rowHeight) or 0))
                row:Show()
                row:SetAlpha(CP.ListRevealAlpha(index) or 1)
            end
        end
    end

    painting = nil
end
