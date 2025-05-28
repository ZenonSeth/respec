local PATH = respec.MODPATH.."/src/"
respec.internal = {}

-- order matters
dofile(PATH.."settings.lua")
dofile(PATH.."util.lua")
dofile(PATH.."const.lua")
dofile(PATH.."graph.lua")
dofile(PATH.."element.lua")
dofile(PATH.."elements.lua")
dofile(PATH.."layout_logic.lua")
dofile(PATH.."layout.lua")
dofile(PATH.."form.lua")

-- temporary
dofile(PATH.."example.lua")