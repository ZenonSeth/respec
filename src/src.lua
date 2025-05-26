local PATH = respec.MODPATH.."/src/"
respec.internal = {}

-- order matters
dofile(PATH.."settings.lua")
dofile(PATH.."util.lua")
dofile(PATH.."consts.lua")
dofile(PATH.."graph.lua")
dofile(PATH.."element.lua")
dofile(PATH.."elements.lua")
dofile(PATH.."layout_logic.lua")
dofile(PATH.."layout.lua")
dofile(PATH.."form.lua")
--
local function test()
  local form = respec.form({w = 4, h = 3, formspec_version = 5})
  form:add({

  })
end

local function get_subview(cond1, cond2)
  local subview = respec.subview()
  if cond1 then
    subview.add(  )
    respec.form()
  end
end

local function show_formspec(playerName)
  local elem = respec.elements
  respec.Form({
    w = 4.7, h = 6.2,
    formspec_version = 5,
    margins = 1,
  }, function(state) return {
      elem.Label("label_id", 1, 0.5)
        :text("Count = "..(state.count or "0"))
        :area_label()
        -- :margin_right(0.25)
        :top_to_parent_top():left_to_parent_left(),

      elem.Button("btn_id", 1, 0.5)
        :text("Press me!")
        :top_to_top_of("label_id")
        :left_to_right_of("label_id")
        :margins_hor(0.25)
        :add_on_click(function(stateClick)
          stateClick.count = (stateClick.count or 0) + 1
          return true
        end),
        elem.Label("label2", 2, 0.5)
        :text("Another one?")
        :margins_all(0.25)
        :top_to_bottom_of("btn_id")
        :left_to_left_of("btn_id")
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
