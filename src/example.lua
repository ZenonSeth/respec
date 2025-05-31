
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
    borderColor = "#0FF",
    -- fbgcolor = "#0000FFAA",
    pos_x = state.posx, pos_y = state.posy,
    no_prepend = true,
    bgfullscreen = "both",
  }
  end
  ,
  function(iState)
  if iState.ch1 == nil then
    iState.ch1 = true ; iState.ch2 = true ; iState.ch3 = true
  end
  local mv = 0.01
  return {
    elem.Label {
      id = "title",
      text = "Relative Formspec Layout Demo",
      w = 3, h = 0.5,
      top_to_bottom_of = "moveupbtn",
      center_hor = true, -- equivalent of the two commented out lines below
      -- start_to_parent_start = true,
      -- end_to_parent_end = true,
    },
    elem.Label {
      id = "label1",
      w = 1, h = 0.5,
      text = "Count = "..(iState.count or "0"),
      area = true, -- no effect unless formspec_version >= 9
      top_to_bottom_of = "title",
      margins_hor = 0.25,
      margins_ver = 0.25,
    },
    elem.Button {
      id = "btn_id",
      w = 2, h = 0.5,
      text = "1!",
      top_to_top_of = "label1",
      start_to_end_of = "label1",
      margins_ver = 0.25,
      margins_hor = 0.25,
      visible = iState.ch1 == true,
      borderColor = "#0000FF",
      on_click = function(state, fields)
        state.count = (state.count or 0) + 1
      end,
    },
    elem.Button {
      id = "btn2",
      w = 2, h = 0.5,
      text = "2!",
      top_to_top_of = "btn_id",
      start_to_end_of = "btn_id",
      visible = iState.ch2 == true,
      margins = 0.25,
      borderColor = "#0000FF",
      on_click = function(state, fields)
        state.count = (state.count or 0) + 2
      end,
    },
    elem.Button {
      id = "btn3",
      w = 2, h = 0.5,
      text = "3!",
      top_to_top_of = "btn2",
      start_to_end_of = "btn2",
      visible = iState.ch3 == true,
      margins = 0.25,
      borderColor = "#0000FF",
      on_click = function(state, fields)
        state.count = (state.count or 0) + 3
      end,
    },
    elem.Label {
      id = "label2",
      w = 1.2, h = 0.5,
      text ="Hi "..(iState.playerName or ""),
      margins = 0.25,
      top_to_bottom_of = "label1",
      start_to_start_of = "btn_id",
      center_hor = true,
      area = true, -- no effect unless formspec_version >= 9
      end_to_end_of = "btn_id",
    },
    elem.Label {
      id = "label3",
      w = 9.8, h = 0.4,
      margin_start = 0.0,
      text = "You right-clicked on a node at: "..dump(iState.pos):gsub("\n"," "),
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
    elem.Checkbox {
      id = "ch1",
      margins = 0.2,
      w = 1.8, h = 0.4,
      text = "Btn1 Toggle",
      checked = iState.ch1 == true,
      top_to_bottom_of = "label5",
      on_click = function(state, fields)
        d.log("ch1, fields = "..dump(fields))
        state.ch1 = fields["ch1"] == "true"
      end
    },
    elem.Checkbox {
      id = "ch2",
      margins = 0.2,
      w = 1.8, h = 0.4,
      text = "Btn1 Toggle",
      checked = iState.ch2 == true,
      center_ver = "ch1",
      start_to_end_of = "ch1",
      on_click = function(state, fields)
        d.log("ch2, fields = "..dump(fields))
        state.ch2 = fields["ch2"] == "true"
      end
    },
    elem.Checkbox {
      id = "ch3",
      margins = 0.2,
      w = 1.8, h = 0.4,
      text = "Btn1 Toggle",
      center_ver = "ch1",
      start_to_end_of = "ch2",
      checked = iState.ch3 == true,
      top_to_bottom_of = "label5",
      on_click = function(state, fields)
        d.log("ch3, fields = "..dump(fields))
        state.ch3 = fields["ch3"] == "true"
      end
    },
    -- test buttons to move form around screen
    elem.Button {
      id = "moveupbtn",
      w = 1, h = 0.3,
      top_to_parent_top = true,
      center_hor = true,
      text = "^",
      on_click = function(state)
        state.posy = math.max(state.posy - mv, 0)
      end
    },
    elem.Button {
      w = 1, h = 0.3,
      bottom_to_parent_bottom = true,
      center_hor = true,
      text = "v",
      on_click = function(state)
        state.posy = math.max(state.posy + mv, 0)
      end
    },
    elem.Button {
      w = 0.3, h = 1,
      start_to_parent_start = true,
      center_ver = true,
      text = "<",
      on_click = function(state)
        state.posx = math.max(state.posx - mv, 0)
      end
    },
    elem.Button {
      w = 0.3, h = 1,
      end_to_parent_end = true,
      center_ver = true,
      text = ">",
      on_click = function(state)
        state.posx = math.max(state.posx + mv, 0)
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
