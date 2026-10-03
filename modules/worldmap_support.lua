-- CharacterPanel helpers shared by worldmap (and character panel itself).
-- Do NOT stub RegisterBuilder — characterpanel/core.lua owns the real registry.
local addon = select(2, ...)

addon.CharacterPanel = addon.CharacterPanel or {}
local CP = addon.CharacterPanel

-- Pane inset nine-slice (from DragonUI characterpanel/paneborder.lua)
local CORNER_SIZE = 6
local EDGE_THICKNESS = 3
local BOTTOM_DROP = -1
local OUTSET_SIGN = {
    TOPLEFT = { -1, 1 }, TOPRIGHT = { 1, 1 },
    BOTTOMLEFT = { -1, -1 }, BOTTOMRIGHT = { 1, -1 },
}

function CP.DrawPaneBorder(host, target, outset)
    if not host or not target or host._duiPaneBorder then return end
    host._duiPaneBorder = true
    outset = outset or 0

    local function corner(atlas, point, drop)
        local t = host:CreateTexture(nil, "BORDER", nil, -5)
        t:set_atlas(atlas, true)
        t:SetSize(CORNER_SIZE, CORNER_SIZE)
        local sign = OUTSET_SIGN[point]
        t:SetPoint(point, target, point, sign[1] * outset, sign[2] * outset + (drop or 0))
        return t
    end

    local tl = corner("UI-Frame-InnerTopLeft", "TOPLEFT")
    local tr = corner("UI-Frame-InnerTopRight", "TOPRIGHT")
    local bl = corner("UI-Frame-InnerBotLeftCorner", "BOTTOMLEFT", BOTTOM_DROP)
    local br = corner("UI-Frame-InnerBotRight", "BOTTOMRIGHT", BOTTOM_DROP)

    local function edge(atlas, vertical, p1, a1, r1, p2, a2, r2)
        local t = host:CreateTexture(nil, "BORDER", nil, -5)
        t:set_atlas(atlas)
        if vertical then t:SetWidth(EDGE_THICKNESS) else t:SetHeight(EDGE_THICKNESS) end
        t:SetPoint(p1, a1, r1)
        t:SetPoint(p2, a2, r2)
    end

    edge("!UI-Frame-InnerLeftTile", true, "TOPLEFT", tl, "BOTTOMLEFT", "BOTTOMLEFT", bl, "TOPLEFT")
    edge("!UI-Frame-InnerRightTile", true, "TOPRIGHT", tr, "BOTTOMRIGHT", "BOTTOMRIGHT", br, "TOPRIGHT")
    edge("_UI-Frame-InnerTopTile", false, "TOPLEFT", tl, "TOPRIGHT", "TOPRIGHT", tr, "TOPLEFT")
    edge("_UI-Frame-InnerBotTile", false, "BOTTOMLEFT", bl, "BOTTOMRIGHT", "BOTTOMRIGHT", br, "BOTTOMLEFT")
end

local REDBUTTON = addon._dir .. "UI\\redbutton2x"

function CP.ModernizeCloseButton(cb, owner, x, y)
    if not cb or cb._duiModernized then return end
    cb._duiModernized = true

    cb:SetSize(24, 24)
    cb._duiOwner, cb._duiX, cb._duiY = owner, x or 1, y or 0
    cb:ClearAllPoints()
    cb:SetPoint("TOPRIGHT", owner, "TOPRIGHT", cb._duiX, cb._duiY)

    local function dress(getter, l, r, t, b, blend)
        local tex = cb[getter] and cb[getter](cb)
        if not tex then return end
        tex:SetTexture(REDBUTTON)
        tex:SetTexCoord(l, r, t, b)
        if blend then tex:SetBlendMode(blend) end
    end

    dress("GetNormalTexture", 39 / 256, 75 / 256, 1 / 128, 39 / 128)
    dress("GetPushedTexture", 39 / 256, 75 / 256, 81 / 128, 119 / 128)
    dress("GetDisabledTexture", 39 / 256, 75 / 256, 41 / 128, 79 / 128)
    dress("GetHighlightTexture", 115 / 256, 151 / 256, 1 / 128, 39 / 128, "ADD")
end
