local addon = select(2,...);
local UIParent = UIParent;

-- Function to reposition DurabilityFrame to bottom left corner
local function RepositionDurabilityFrame()
    if DurabilityFrame then
        DurabilityFrame:ClearAllPoints()
        DurabilityFrame:SetPoint("RIGHT", UIParent, "RIGHT", -260, 280)
        -- DurabilityFrame:SetUserPlaced(true)
    end
end

-- Create event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")

-- Event handler
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DrakeishUI" then
        -- Reposition immediately when addon loads
        RepositionDurabilityFrame()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Reposition on login and entering world
        RepositionDurabilityFrame()
        
        -- Add small delay to ensure frame is fully loaded
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.5 then
                RepositionDurabilityFrame()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

