-- Isolated compatibility namespace for the DragonUI New Era social-window port.
DrakeishUI_SocialNE = DrakeishUI_SocialNE or {}

local NE = DrakeishUI_SocialNE

-- The source locale table falls back to its English key when no translation exists.
NE.L = NE.L or setmetatable({}, {
  __index = function(_, key)
    return key
  end,
})

-- DrakeishUI has no New Era options/panel registry; these calls are informational.
NE.RegisterPanel = NE.RegisterPanel or function() end

-- Guild chat history. Saved variables are restored before this file runs.
DrakeishUI_SocialDB = DrakeishUI_SocialDB or {}
NE.db = DrakeishUI_SocialDB
