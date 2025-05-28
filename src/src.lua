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
    -- w = respec.const.wrap_content, h = 6.2,
    formspec_version = 5,
    margins = 0.2,
  }, function(state) return {
      elem.Label {
        id = "title",
        text = "Relative Formspec Layout Demo",
        w = 3, h = 0.5,
        start_to_parent_start = true,
        end_to_parent_end = true,
      },
      elem.Label {
        id = "label1",
        w = 1, h = 0.5,
        text = "Count = "..(state.count or "0"),
        area = true, -- no effect unless formspec_version >= 9
        top_to_bottom_of = "title",
        margins_hor = 0.25,
        margins_ver = 0.25,
      },
      elem.Button {
        id = "btn_id",
        w = 2, h = 0.5,
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
        id = "label2",
        w = 1, h = 0.5,
        text ="Another",
        margins = 0.25,
        top_to_bottom_of = "btn_id",
        start_to_start_of = "btn_id",
        area = true, -- no effect unless formspec_version >= 9
        end_to_end_of = "btn_id", -- TODO not working, fix it
      },
      elem.Label {
        id = "label3",
        w = 0.8, h = 0.4,
        margin_start = 0.4,
        text = "--==--",
        top_to_bottom_of = "label2",
        start_to_parent_start = true,
        end_to_parent_end = true,
      },
      elem.Label {
        id = "label4",
        w = 0.8, h = 0.4,
        text = "--==--",
        top_to_bottom_of = "label3",
        start_to_parent_start = true,
        end_to_parent_end = true,
        hor_bias = 0.75,
      },
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
