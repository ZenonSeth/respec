
respec.settings = {}

local debugOverrides = {}
function respec.settings.debug(playerName)
  d.log("debugOverrides = "..dump(debugOverrides))
  if not playerName then playerName = "singleplayer" end
  return debugOverrides[playerName] == true
end

function respec.settings.set_debug_for(playerName, debugTF)
  if debugTF then debugOverrides[playerName] = true
  else debugOverrides[playerName] = nil end
end
