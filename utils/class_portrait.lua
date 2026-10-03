-- HD class portrait icons for Character panel / unit frames.
local addon = select(2, ...)

addon.UF = addon.UF or {}

-- Prefer addon._dir so the path always matches this install's assets folder.
local CLASS_ICON_HD_PREFIX = (addon._dir or "Interface\\AddOns\\DrakeishUI\\assets\\") .. "ClassIcons\\"
local CLASS_ICON_CLASSIC = "Interface\\TargetingFrame\\UI-Classes-Circles"

--- Apply a class icon to a portrait texture.
--- @param texture Texture
--- @param classFile string e.g. "WARRIOR", "DEATHKNIGHT"
--- @param preferHD boolean|nil when true (or nil), use per-class HD art; else classic circles
--- @return boolean success
function addon.UF.ApplyClassPortraitIcon(texture, classFile, preferHD)
    if not texture or not classFile then
        return false
    end

    if preferHD ~= false then
        -- No file extension — client resolves .blp/.tga from the path.
        texture:SetTexture(CLASS_ICON_HD_PREFIX .. classFile)
        texture:SetTexCoord(0, 1, 0, 1)
        local path = texture:GetTexture()
        if path and not string.find(string.lower(tostring(path)), "ui%-classes%-circles") then
            return true
        end
        -- Fall through to classic if HD path failed to resolve.
    end

    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
    if not coords then
        return false
    end

    texture:SetTexture(CLASS_ICON_CLASSIC)
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    return true
end
