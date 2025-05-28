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

local function show_formspec(playerName)
  local elem = respec.elements
  respec.Form({
    w = 4.7, h = 6.2,
    formspec_version = 5,
    margins = 1,
  }, function(state) return {
      elem.Label {
        id = "label1",
        w = 1, h = 0.5,
        text = "Count = "..(state.count or "0"),
        area = true, -- no effect unless formspec_version >= 9
        margins_hor = 0.25,
        margins_ver = 0.25,
      },

      elem.Button {
        id = "btn_id",
        w = 1, h = 0.5,
        text = "Press me!",
        top_to_top_of = "label1",
        start_to_end_of = "label1",
        margins_ver = 0.25,
        margins_hor = 0.25,
        on_click = function(stateClick)
          stateClick.count = (stateClick.count or 0) + 1
          return true
        end,
      },
      elem.Label {
        w = 1, h = 0.5,
        text ="Another one?",
        margins = 0.25,
        top_to_bottom_of = "btn_id",
        start_to_start_of = "btn_id",
        area = true, -- no effect unless formspec_version >= 9
        -- end_to_end_of = "btn_id", -- TODO not working, fix it
      }
    } end
  ):show(playerName)
end

core.register_node("respec:gui_builder", {
  description = "GUI Builder",
  drawtype = "normal",
  tiles = {"default_mossycobble.png"},
  groups = {oddly_breakable_by_hand = 3},
  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if not clicker or not clicker:is_player() then return end
    local playerName = clicker:get_player_name()
    show_formspec(playerName)
  end
})
