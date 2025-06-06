local S = respec.TRANSLATOR

local function numToFontMod(n)
  if not n then return "0" end
  if n >= 0 then return "+"..tostring(n) end
  return tostring(n)
end

  local elem = respec.elements
  local form1 = respec.Form(
  function(state)
    if not state.posx then state.posx = 0.5 end
    if not state.posy then state.posy = 0.5 end
    return {
    --w = 13, h = 4,
    w = 14,
    formspec_version = 5,
    paddings = 0.2,
    bgcolor = "#252525CC",
    borderColor = "#0FF",
    -- fbgcolor = "#0000FFAA",
    pos_x = state.posx, pos_y = state.posy,
    no_prepend = true,
    bgfullscreen = "both",
    --defaultElementMargins = 0.2,
    set_focus = "field1",
  }
  end
  ,
  function(iState)
  if iState.ch1 == nil then
    iState.ch1 = true ; iState.ch2 = true ; iState.ch3 = true
    iState.fontSize = 0
    iState.title = "The Quick Brown Fox\nJumps Over The Lazy DOG\nJumps Over The Lazy DOG"
    iState.field1 = iState.title
  end
  local mv = 0.01
  return {
    elem.StyleType {
      target = "*",
      -- font = "mono",
      font_size = numToFontMod(iState.fontSize),
    },
    elem.Label {
      id = "title",
      text = (iState.title),
      w = respec.const.wrap_content, h = respec.const.wrap_content,
      -- below = "moveupbtn",
      center_hor = true, -- equivalent of the two commented out lines below
      -- start_to_parent_start = true,
      -- end_to_parent_end = true,
    },

    -- elem.Label {
    --   id = "label1",
    --   w = 1, h = 0.5,
    --   text = ""..(iState.count or "0"),
    --   area = true, -- no effect unless formspec_version >= 9
    --   below = "title",
    --   -- margins_hor = 0.25,
    --   -- margins_ver = 0.25,
    -- },
    elem.Field {
      id = "field1",
      w = 3, h = 0.5,
      below = "title",
      label = "Change Title",
      text = iState.field1 or "",
      closeOnEnter = false,
      onSubmit = function(state, value, fields)
        state.field1 = value
        state.title = value
      end
    },
    elem.Button {
      id = "btn1",
      paddingsHor = 0.5,
      paddingsVer = 0.1,
      text = "Set Title",
      below = "field1",
      alignStart = "field1",
      margins_ver = 0.25,
      margins_hor = 0.25,
      visible = iState.ch1 == true,
      -- borderColor = "#0000FF",
      on_click = function(state, fields)
        state.title = fields["field1"] or ""
      end,
      style = {
        font = "mono",
        font_size = "+8",
      }
    },
    -- elem.StyleType {
    --   target = "button:pressed",
    --   font_size = "+1",
    -- },
    elem.Button {
      id = "btn2",
      paddingsHor = 0.5, paddingsVer = 0.2,
      text = "+ font size",
      alignTop = "btn1",
      before = "btn3",
      margins = 0.25,
      visible = iState.ch2 == true,
      -- margins = 0.25,
      -- borderColor = "#0000FF",
      on_click = function(state, fields)
        state.count = (state.count or 0) + 2
        state.fontSize = state.fontSize + 1
      end,
    },
    elem.Button {
      id = "btn3",
      paddingsHor = 0.5, paddingsVer = 0.2,
      text = "- font size",
      alignTop = "btn2",
      toEnd = true,
      visible = iState.ch3 == true,
      margins = 0.25,
      -- borderColor = "#0000FF",
      on_click = function(state, fields)
        state.count = (state.count or 0) + 3
        state.fontSize = state.fontSize - 1
      end,
    },
    elem.Label {
      id = "label2",
      -- w = respec.const.wrap_content, h = 0.5,
      text ="Hi "..(iState.rightclick.playerName or ""),
      margins = 0.25,
      below = "label3",
      alignStart = "btn1",
      after = "list_in",
      -- area = true, -- no effect unless formspec_version >= 9
      -- alignEnd = "btn1",
    },
    elem.Label {
      id = "label3",
      w = 12.8, h = 0.4,
      text = "You right-clicked on a node at: "..dump(iState.rightclick.pos):gsub("\n"," "),
      below = "btn1",
      margins = 0.1,
      -- center_hor = true,
      toStart = true,
      -- end_to_parent_end = true,
    },
    elem.StyleType {
      target = "list",
      size = 0.5,
      spacing = "0.2,0.1",
    },
    elem.ListColors {
      slotBg = "#CCC",
      slotBgHover = "#AAA",
      -- tooltipBg = "#FFF",
      -- tooltipFont = "#333",
    },
    elem.List {
      id = "list_in",
      w = 3, h = 2,
      inv = respec.inv.node("in"),
      below = "label3",
      borderColor = "#ff0",
      margins = 0.25,
    },
    elem.List {
      id = "list_main",
      w = 8, h = 4,
      inv = respec.inv.player("main"),
      below = "list_in",
      margins = 0.25,
    },
    elem.ListRing {
      respec.inv.node("in"),
      respec.inv.player("main"),
    },
    elem.Label {
      id = "label4",
      w = 0.8, h = 0.4,
      text = "--==--",
      below = "label3",
      after = "list_in",
      -- toEnd = true,
      -- hor_bias = 0.75,
    },
    elem.Label {
      id = "label5",
      -- margin_end = 1,
      text = "What is this?",
      below = "list_main",
      -- after = "list_in",
      toStart = true,
      margins = 0.2,
      chain_type_hor = respec.const.chain_packed,
      before = "ch1",
      -- toEnd = true,
    },
    elem.Checkbox {
      id = "ch1",
      margins = 0.2,
      text = "Btn1 Toggle",
      checked = iState.ch1 == true,
      alignTop = "label5",
      after = "label5",
      before = "ch2",
      on_click = function(state, fields)
        state.ch1 = fields["ch1"] == "true"
      end
    },
    elem.Checkbox {
      id = "ch2",
      margins = 0.2,
      text = "Btn2 Toggle",
      checked = iState.ch2 == true,
      center_ver = "ch1",
      after = "ch1",
      before = "ch3",
      on_click = function(state, fields)
        state.ch2 = fields["ch2"] == "true"
      end
    },
    elem.Checkbox {
      id = "ch3",
      margins = 0.2,
      text = "Btn3 Toggle",
      center_ver = "ch1",
      after = "ch2",
      checked = iState.ch3 == true,
      alingtop = "ch1",
      toEnd = true,
      on_click = function(state, fields, f)
        state.ch3 = fields["ch3"] == "true"
      end
    },
    elem.Button {
      id = "PLBTN",
       w = 2, h = 0.5,
      text = "PLACEHOLDER",
      alignStart = "label5",
      below = "label5",
    }
    -- -- test buttons to move form around screen
    -- elem.Button {
    --   id = "moveupbtn",
    --   w = 1, h = 0.3, margins = 0,
    --   toTop = true,
    --   center_hor = true,
    --   text = "^",
    --   margin_top = -0.2, -- negative margins are allowed, though may not work as expected
    --   on_click = function(state)
    --     state.posy = math.max(state.posy - mv, 0)
    --   end
    -- },
    -- elem.Button {
    --   w = 1, h = 0.3, margins = 0,
    --   toBottom = true,
    --   center_hor = true,
    --   margin_bottom = -0.2, -- negative margins are allowed, though may not work as expected
    --   text = "v",
    --   on_click = function(state)
    --     state.posy = math.max(state.posy + mv, 0)
    --   end
    -- },
    -- elem.Button {
    --   w = 0.3, h = 1, margins = 0,
    --   toStart = true,
    --   center_ver = true,
    --   margin_start = -0.2, -- negative margins are allowed, though may not work as expected
    --   text = "<",
    --   on_click = function(state)
    --     state.posx = math.max(state.posx - mv, 0)
    --   end
    -- },
    -- elem.Button {
    --   w = 0.3, h = 1, margins = 0,
    --   toEnd = true,
    --   center_ver = true,
    --   margin_end = -0.2, -- negative margins are allowed, though may not work as expected
    --   text = ">",
    --   on_click = function(state)
    --     state.posx = math.max(state.posx + mv, 0)
    --   end
    -- },
  } end)

local form2 = respec.Form({
    --w = 13, h = 4,
    formspec_version = 9,
    paddings = 0.2,
  },
  function (init)

    local tbl = {"Hi there.. test of scroll container!"}
    -- for C = 0,150,1 do
    --   table.insert(tbl, string.format("%x", 22 + C).."|"..string.char(22 + C).."|")
    -- end

    return {
      elem.Label {
        id = "lbl1",
        w = 10, h = 0.5,
        text = table.concat(tbl, " "),
        -- area = true,
      },
      elem.Button {
        id = "obbf", text = "before sc", paddingsHor = 0.3, paddingsVer = 0.2, below = "lbl1",
      },
      -- elem.Button { w = 1, h = 0.5, id = "obtn1", below = "lbl1", toStart = true, toEnd = true},
      -- elem.Button { w = 0, h = 0.5, id = "obtn2", below = "obtn1", alignStart = "obtn1", toEnd = true},
      elem.ScrollContainer{
        id = "sc1",
        w = 4, h = 4, below = "lbl1", after = "obbf",
        -- orientation = "horizontal",
        customBorderColor = "#FFF",
        -- scrollbarOptions = { arrows = "hide" },
        elements = {
          elem.Button {
            id = "btn1", text = init.btn1text, toStart = true, paddingsHor = 0.5, paddingsVer = 0.1,
            tooltip = "This is just one button!",
          },
          elem.Button {
            id = "btn2", w = 0, h = 1.5, toStart = true, text = "Hey 2", below = "btn1", before = "btn3",
          },
          elem.Button {
            id = "btn3", w = 3, h = 3.5, after = "btn1", text = "Hey 3", below = "btn1"
          },
          elem.Label {
            text = "Just some random text\nthat goes down below", w = 0, center_hor = true, below = "btn3",
            tooltip = "This is a tooltip on a label!",
          }
        },
        -- scrollbarListener = function(st, ex, f)
        --   st.btn1text = tostring(ex.value)
        -- end,
      },
      elem.Button {
        id = "btn4", w = 2, h = 0.5, text = "After container",
        after = "sc1", borderColor = "#9ff", below = "lbl1"
      },

  } end)

respec.util.engine.register_node("respec:gui_builder", {
  description = "GUI Builder",
  drawtype = "normal",
  tiles = {"default_mossycobble.png"},
  groups = {oddly_breakable_by_hand = 3},
  after_place_node = function(pos, placer, itemstack, pointed_thing)
    local m = core.get_meta(pos)
    local i = m:get_inventory()
    i:set_size("in", 16)
    i:set_size("out", 16)
  end,
  on_rightclick = form2:show_from_node_rightclick(nil, true)
})
