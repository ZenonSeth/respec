
  local elem = respec.elements
  local myForm = respec.Form(
  function(state)
    if not state.posx then state.posx = 0.5 end
    if not state.posy then state.posy = 0.5 end
    return {
    -- w = respec.const.wrap_content, h = 6.2,
    formspec_version = 5,
    paddings = 0.2,
    bgcolor = "#252525CC",
    borderColor = "#0FF",
    -- fbgcolor = "#0000FFAA",
    pos_x = state.posx, pos_y = state.posy,
    no_prepend = true,
    bgfullscreen = "both",
    defaultElementMargins = 0.2,
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
      below = "moveupbtn",
      center_hor = true, -- equivalent of the two commented out lines below
      -- start_to_parent_start = true,
      -- end_to_parent_end = true,
    },
    elem.Label {
      id = "label1",
      w = 1, h = 0.5,
      text = "Count = "..(iState.count or "0"),
      area = true, -- no effect unless formspec_version >= 9
      below = "title",
      margins_hor = 0.25,
      margins_ver = 0.25,
    },
    elem.Button {
      id = "btn1",
      w = 2, h = 0.5,
      text = "1!",
      alignTop = "label1",
      before = "btn2",
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
      alignTop = "btn1",
      before = "btn3",
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
      alignTop = "btn2",
      toEnd = true,
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
      below = "label1",
      alignStart = "btn1",
      center_hor = true,
      area = true, -- no effect unless formspec_version >= 9
      end_to_end_of = "btn1",
    },
    elem.Label {
      id = "label3",
      w = 9.8, h = 0.4,
      text = "You right-clicked on a node at: "..dump(iState.pos):gsub("\n"," "),
      below = "label2",
      toStart = true,
      -- end_to_parent_end = true,
    },
    elem.Label {
      id = "label4",
      w = 0.8, h = 0.4,
      text = "--==--",
      below = "label3",
      toStart = true,
      toEnd = true,
      hor_bias = 0.75,
    },
    elem.Label {
      id = "label5",
      -- margin_end = 1,
      w = 0.8, h = 0.4,
      text = "--==--",
      below = "label4",
      toEnd = true,
    },
    elem.Checkbox {
      id = "ch1",
      margins = 0.2,
      w = 1.8, h = 0.4,
      text = "Btn1 Toggle",
      checked = iState.ch1 == true,
      below = "label5",
      on_click = function(state, fields)
        d.log("ch1, fields = "..dump(fields))
        state.ch1 = fields["ch1"] == "true"
      end
    },
    elem.Checkbox {
      id = "ch2",
      margins = 0.2,
      w = 1.8, h = 0.4,
      text = "Btn2 Toggle",
      checked = iState.ch2 == true,
      center_ver = "ch1",
      after = "ch1",
      on_click = function(state, fields)
        d.log("ch2, fields = "..dump(fields))
        state.ch2 = fields["ch2"] == "true"
      end
    },
    elem.Checkbox {
      id = "ch3",
      margins = 0.2,
      w = 1.8, h = 0.4,
      text = "Btn3 Toggle",
      center_ver = "ch1",
      after = "ch2",
      checked = iState.ch3 == true,
      below = "label5",
      on_click = function(state, fields)
        d.log("ch3, fields = "..dump(fields))
        state.ch3 = fields["ch3"] == "true"
      end
    },
    -- test buttons to move form around screen
    elem.Button {
      id = "moveupbtn",
      w = 1, h = 0.3, margins = 0,
      toTop = true,
      center_hor = true,
      text = "^",
      on_click = function(state)
        state.posy = math.max(state.posy - mv, 0)
      end
    },
    elem.Button {
      w = 1, h = 0.3, margins = 0,
      toBottom = true,
      center_hor = true,
      text = "v",
      on_click = function(state)
        state.posy = math.max(state.posy + mv, 0)
      end
    },
    elem.Button {
      w = 0.3, h = 1, margins = 0,
      toStart = true,
      center_ver = true,
      text = "<",
      on_click = function(state)
        state.posx = math.max(state.posx - mv, 0)
      end
    },
    elem.Button {
      w = 0.3, h = 1, margins = 0,
      toEnd = true,
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
