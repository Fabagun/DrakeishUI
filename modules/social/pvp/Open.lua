-- DrakeishUI_SocialNE/modules/pvp/Open.lua — route TogglePVPFrame / PVPParentFrame (and legacy
-- BattlefieldFrame) to DrakeishUI_Social_PVPFrame and suppress the stock parchment parent.
-- Same recipe as modules/lfg/Open.lua.

local NE = DrakeishUI_SocialNE
if not NE then return end

NE.pvp = NE.pvp or {}
local P = NE.pvp

local function enabled()
  return not P.IsEnabled or P.IsEnabled()
end

local wired = false
local function wireRedirects()
  if wired then return end
  wired = true

  if type(_G.TogglePVPFrame) == "function" then
    local orig = _G.TogglePVPFrame
    _G.TogglePVPFrame = function(...)
      if enabled() and P.Toggle then
        P.Toggle()
        return
      end
      return orig(...)
    end
  end

  -- Anything that ShowUIPanel(PVPParentFrame)s (NPC gossip, queue-anywhere, other addons)
  -- gets swallowed and rerouted. HideUIPanel keeps UIPanel bookkeeping clean.
  if _G.PVPParentFrame and not _G.PVPParentFrame._nePvPHooked then
    _G.PVPParentFrame._nePvPHooked = true
    _G.PVPParentFrame:HookScript("OnShow", function(self)
      if not enabled() then return end
      if HideUIPanel then HideUIPanel(self) else self:Hide() end
      local mode = (_G.PVPFrame_IsJustBG and _G.PVPFrame_IsJustBG()) and "BG" or nil
      if P.Show then P.Show(mode) end
    end)
  end

  -- Legacy BattlefieldFrame (pre-Wrath queue UI): hide and open our Battlegrounds tab.
  if _G.BattlefieldFrame and not _G.BattlefieldFrame._nePvPHooked then
    _G.BattlefieldFrame._nePvPHooked = true
    _G.BattlefieldFrame:HookScript("OnShow", function(self)
      if not enabled() then return end
      if HideUIPanel then HideUIPanel(self) else self:Hide() end
      if P.Show then P.Show("BG") end
    end)
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  wireRedirects()
end)
