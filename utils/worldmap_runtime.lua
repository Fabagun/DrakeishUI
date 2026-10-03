-- Runtime helpers the DragonUI worldmap expects on the shared addon table.
local addon = select(2, ...)

addon._timerPool = addon._timerPool or {}

if not addon.After then
    function addon:After(delay, callback)
        if type(callback) ~= "function" then return end
        delay = tonumber(delay) or 0
        if delay < 0 then delay = 0 end
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
                if cb then cb() end
            end
        end)
    end
end

-- Locale-aware fonts (worldmap coords / pin labels).
if not addon.Fonts then
    local locale = GetLocale()
    local system = ({
        koKR = "Fonts\\2002.TTF",
        zhCN = "Fonts\\ZYKai_T.TTF",
        zhTW = "Fonts\\bLEI00D.TTF",
        ruRU = "Fonts\\FRIZQT__.TTF",
    })[locale]
    local primary = system or "Fonts\\FRIZQT__.TTF"
    local expressway = addon._dir and (addon._dir .. "expressway.ttf") or primary
    addon.Fonts = {
        PRIMARY = primary,
        ACTIONBAR = system or expressway,
        NARROW = system or expressway,
        ARIALN = system or "Fonts\\ARIALN.TTF",
        locale = locale,
    }
end

function addon:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00cc66DrakeishUI:|r " .. tostring(msg))
    end
end

function addon:Debug() end
function addon:Error(msg)
    self:Print(tostring(msg))
end

-- Defer protected ops until combat ends (worldmap layout/boot).
addon.CombatQueue = addon.CombatQueue or { pending = {}, isRegistered = false }

function addon.CombatQueue:Add(id, func, ...)
    if not id or type(func) ~= "function" then return false end
    self.pending[id] = { func = func, args = { ... } }
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_ENABLED" then
                addon.CombatQueue:ProcessQueue()
            end
        end)
    end
    if not self.isRegistered then
        self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.isRegistered = true
    end
    return true
end

function addon.CombatQueue:ProcessQueue()
    local pending = self.pending
    self.pending = {}
    for _, op in pairs(pending) do
        pcall(op.func, unpack(op.args))
    end
    if self.isRegistered and self.eventFrame then
        self.eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.isRegistered = false
    end
end

-- Run now if out of combat; otherwise queue until PLAYER_REGEN_ENABLED.
function addon.CombatQueue:ExecuteOrQueue(id, func, ...)
    if type(func) ~= "function" then return false end
    if InCombatLockdown and InCombatLockdown() then
        return self:Add(id, func, ...)
    end
    local ok, err = pcall(func, ...)
    if not ok then
        addon:Error(tostring(err))
        return false
    end
    return true
end

function addon:SafeExecute(moduleId, operationName, func, ...)
    local queueId = tostring(moduleId or "mod") .. "_" .. tostring(operationName or "op")
    return addon.CombatQueue:ExecuteOrQueue(queueId, func, ...)
end
