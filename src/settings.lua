
respec.settings = {}
local override = true

local debugOverrides = {}
function respec.settings.debug(playerName)
  if not playerName then playerName = "singleplayer" end
  return debugOverrides[playerName] == true
end

function respec.settings.set_debug_for(playerName, debugTF)
  if debugTF then debugOverrides[playerName] = true
  else debugOverrides[playerName] = nil end
end
