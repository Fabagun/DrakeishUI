-- Minimal DragonUI-compatible API so Bagster/BagSort run inside DrakeishUI.
local addon = select(2, ...)

-- AceLocale-style: missing keys return themselves (Bagster LKEYS rely on this).
if type(addon.L) ~= "table" then
    addon.L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
end
addon.LO = addon.LO or addon.L

addon._timerPool = addon._timerPool or {}

function addon:After(delay, callback)
    if type(callback) ~= "function" then
        return
    end
    delay = tonumber(delay) or 0
    if delay < 0 then
        delay = 0
    end
    local f = table.remove(self._timerPool) or CreateFrame("Frame")
    f._elapsed = 0
    f._delay = delay
    f._callback = callback
    f:SetScript("OnUpdate", function(self, dt)
        self._elapsed = self._elapsed + dt
        if self._elapsed >= self._delay then
            self:SetScript("OnUpdate", nil)
            local cb = self._callback
            self._callback = nil
            table.insert(addon._timerPool, self)
            if cb then
                cb()
            end
        end
    end)
end

function addon:RegisterModule(name, moduleTable, displayName, description, options)
    self._modules = self._modules or {}
    self._modules[name] = moduleTable
    return moduleTable
end

function addon:ShouldDeferModuleDisable()
    return false
end

-- Optional hooks used by bagster money tooltip / itemlevel; no-ops if unused.
function addon.GetCharacterMoney()
    return nil
end

function addon.RegisterAltMoneyFrame()
end

addon.UpdateItemLevelSlot = addon.UpdateItemLevelSlot or function() end

local BAGSTER_DEFAULTS = {
    enabled = true,
    money_display = "icons",
    item_scale = 1,
    item_spacing = 2,
    bag_break = 1,
    break_space = 1.3,
    glow_quality = true,
    glow_quest = true,
    glow_alpha = 1,
    show_quality_filter = true,
}

local BAGSORT_DEFAULTS = {
    enabled = true,
    bank_fill_from_bags = true,
    lockedSlots = {},
    move_interval = 0.1,
    lock_hotkey = "ALT_LEFT",
    lock_color = { 0.15, 0.80, 1.00, 0.95 },
    reverse_stack = false,
}

local WORLDMAP_DEFAULTS = {
    enabled = true,
    questLog = true,
    maximized = false,
    objectives = true,
    landmarks = true,
    fog = true,
    entrances = true,
    graveyards = true,
    flightPoints = true,
    inns = true,
    coordinates = true,
    zoneLevels = true,
    fadeWhenMoving = false,
    moveAlpha = 0.4,
}

local COLLECTIONS_DEFAULTS = {
    enabled = true,
}

local CHARACTERPANEL_DEFAULTS = {
    enabled = true,
    class_portrait = true,
    class_level_text = true,
    dark_background = false,
    grey_model_backdrop = true,
    hide_model_controls = false,
    model_controls_reset_only = false,
    skills_hide_maxed = false,
    rep_standing = 0,
    rep_hide_inactive = false,
    currency_hide_empty = false,
    show_item_level = true,
    show_gear_score = false,
}

local ITEMLEVEL_DEFAULTS = {
    enabled = true,
    font_size = 12,
    font_family = "expressway",
    font_outline = "THICKOUTLINE",
    position = "BOTTOM",
    show_average = true,
    tooltip_cvar = false,
    bags = true,
    bank = true,
    guildbank = true,
    character = true,
    inspect = true,
    merchant = true,
    trade = true,
    loot = true,
    lootroll = true,
    mail = true,
    auction = true,
}

local function DeepCopy(src, dst)
    if type(src) ~= "table" then
        return
    end
    dst = dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            DeepCopy(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function EnsureDB()
    if type(DrakeishUI_BagDB) ~= "table" then
        DrakeishUI_BagDB = {}
    end
    local root = DrakeishUI_BagDB
    if type(root.profile) ~= "table" then
        root.profile = {}
    end
    if type(root.global) ~= "table" then
        root.global = {}
    end
    if type(root.global.bagsterCache) ~= "table" then
        root.global.bagsterCache = {}
    end
    if type(root.global.characterMoney) ~= "table" then
        root.global.characterMoney = {}
    end
    if type(root.profile.modules) ~= "table" then
        root.profile.modules = {}
    end
    root.profile.modules.bagster = DeepCopy(BAGSTER_DEFAULTS, root.profile.modules.bagster or {})
    root.profile.modules.bagsort = DeepCopy(BAGSORT_DEFAULTS, root.profile.modules.bagsort or {})
    root.profile.modules.worldmap = DeepCopy(WORLDMAP_DEFAULTS, root.profile.modules.worldmap or {})
    root.profile.modules.collections = DeepCopy(COLLECTIONS_DEFAULTS, root.profile.modules.collections or {})
    root.profile.modules.characterpanel = DeepCopy(CHARACTERPANEL_DEFAULTS, root.profile.modules.characterpanel or {})
    root.profile.modules.itemlevel = DeepCopy(ITEMLEVEL_DEFAULTS, root.profile.modules.itemlevel or {})
    -- Bagster has its own retail skin; keep Blizzard bag skin off.
    if type(root.profile.modules.bags_skin) ~= "table" then
        root.profile.modules.bags_skin = { enabled = false }
    else
        root.profile.modules.bags_skin.enabled = false
    end
    -- Force bagster/bagsort/worldmap/collections/characterpanel/itemlevel on.
    root.profile.modules.bagster.enabled = true
    root.profile.modules.bagsort.enabled = true
    root.profile.modules.worldmap.enabled = true
    root.profile.modules.collections.enabled = true
    root.profile.modules.characterpanel.enabled = true
    root.profile.modules.itemlevel.enabled = true
    root.profile.modules.itemlevel.character = true

    -- Per-character favorites for Pets & Mounts (keyed by realm-player).
    if type(root.chars) ~= "table" then
        root.chars = {}
    end
    local player = UnitName and UnitName("player")
    local realm = GetRealmName and GetRealmName()
    if player and realm then
        local key = realm .. "-" .. player
        if type(root.chars[key]) ~= "table" then
            root.chars[key] = {}
        end
        root.char = root.chars[key]
    else
        root.char = root.char or {}
    end

    addon.db = root
    return root
end

function addon:GetModuleConfig(moduleName)
    EnsureDB()
    return self.db and self.db.profile and self.db.profile.modules
        and self.db.profile.modules[moduleName]
end

function addon:IsModuleEnabled(moduleName)
    local cfg = self:GetModuleConfig(moduleName)
    return cfg and cfg.enabled or false
end

-- SavedVariables may load after this file; refresh on ADDON_LOADED / login (char key needs player name).
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == "DrakeishUI" then
        EnsureDB()
    elseif event == "PLAYER_LOGIN" then
        EnsureDB()
        self:UnregisterAllEvents()
    end
end)

EnsureDB()
