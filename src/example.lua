
  local elem = respec.elements
  local myForm = respec.Form(
  function(state)
    if not state.posx then state.posx = 0.5 end
    if not state.posy then state.posy = 0.5 end
    return {
    -- w = respec.const.wrap_content, h = 6.2,
    formspec_version = 5,
    margins = 0.2,
    bgcolor = "#252525CC",
    -- fbgcolor = "#0000FFAA",
    pos_x = state.posx, pos_y = state.posy,
    no_prepend = true,
    bgfullscreen = "both",
  }
  end
  ,
  function(initState)
  local mv = 0.01
  return {
    elem.Label {
      id = "title",
      text = "Relative Formspec Layout Demo",
      w = 3, h = 0.5,
      top_to_bottom_of = "moveupbtn",
      start_to_parent_start = true,
      end_to_parent_end = true,
    },
    elem.Label {
      id = "label1",
      w = 1, h = 0.5,
      text = "Count = "..(initState.count or "0"),
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
      on_click = function(state, fields)
        d.log("click fields = ".. dump(fields):gsub("\n", " "))
        state.count = (state.count or 0) + 1
        return true
      end,
    },
    elem.Label {
      id = "label2",
      w = 2.2, h = 0.5,
      text ="Hello there "..(initState.playerName or ""),
      margins = 0.25,
      top_to_bottom_of = "btn_id",
      start_to_start_of = "btn_id",
      area = true, -- no effect unless formspec_version >= 9
      end_to_end_of = "btn_id",
    },
    elem.Label {
      id = "label3",
      w = 9.8, h = 0.4,
      margin_start = 0.0,
      text = "You right-clicked on a node at: "..dump(initState.pos):gsub("\n"," "),
      top_to_bottom_of = "label2",
      start_to_parent_start = true,
      -- end_to_parent_end = true,
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
    elem.Label {
      id = "label5",
      -- margin_end = 1,
      w = 0.8, h = 0.4,
      text = "--==--",
      top_to_bottom_of = "label4",
      end_to_parent_end = true,
    },
    -- test buttons to move form around screen
    elem.Button {
      id = "moveupbtn",
      w = 1, h = 0.3,
      top_to_parent_top = true,
      start_to_parent_start = true,
      end_to_parent_end = true,
      text = "^",
      on_click = function(state)
        state.posy = math.max(state.posy - mv, 0) ; return true
      end
    },
    elem.Button {
      w = 1, h = 0.3,
      bottom_to_parent_bottom = true,
      start_to_parent_start = true,
      end_to_parent_end = true,
      text = "v",
      on_click = function(state)
        state.posy = math.max(state.posy + mv, 0) ; return true
      end
    },
    elem.Button {
      w = 0.3, h = 1,
      start_to_parent_start = true,
      top_to_parent_top = true,
      bottom_to_parent_bottom = true,
      text = "<",
      on_click = function(state)
        state.posx = math.max(state.posx - mv, 0) ; return true
      end
    },
    elem.Button {
      w = 0.3, h = 1,
      end_to_parent_end = true,
      top_to_parent_top = true,
      bottom_to_parent_bottom = true,
      text = ">",
      on_click = function(state)
        state.posx = math.max(state.posx + mv, 0) ; return true
      end
    },
  } end)

respec.util.engine.register_node("respec:gui_builder", {
  description = "GUI Builder",
  drawtype = "normal",
  tiles = {"default_mossycobble.png"},
  groups = {oddly_breakable_by_hand = 3},
  on_rightclick = myForm:show_from_node_rightclick(nil, true)
})
