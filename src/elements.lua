-- defines the specific elements

local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right
local WRAP = con.wrap_content
local UNSET = con.unset

-- utility funcs

local num_or = respec.util.num_or
local str_or =  respec.util.str_or
local bool_or =  respec.util.bool_or
local min0 = respec.util.min0
local log_error = respec.log_error
local engine = respec.util.engine

local get_valid_style = respec.elements.get_valid_style
respec.elements.get_valid_style = nil
local measure_text = respec.internal.measure_text
respec.internal.measure_text = nil

local function get_style_type_data(spec)
  if type(spec) ~= "table" then return nil end
  local entires = {}
  for k, v in pairs(spec) do
    local typeV = type(v)
    if typeV == "string" or typeV == "number" or typeV == "boolean" then
      entires[tostring(k)] = tostring(v)
    end
  end
  return entires
end

-- returns invloc, listname
local function get_inv_loc_and_name_from_data(data, persist)
  local invLoc = data[1] or ""
  local listName = data[2] or ""
  local state = persist.state
  if invLoc == -1  then -- special case to autopopulate with position from state
    if not state or not state.rightclick or not state.rightclick.pos then
      log_error("Error: List cannot be created, did you forget to use `show_from_node_rightclick()`?")
      return ""
    end
    local pos = state.rightclick.pos
    invLoc = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  end
  return invLoc, listName
end

local function get_merged_styles(persist, useCommon, typeStyleName, elemStyleData)
  local baseSt = {}
  if useCommon then
    local all = persist["style_*"]
    if all then for k, v in pairs(all) do baseSt[k] = v end end
  end
  if typeStyleName then
    local st = persist[typeStyleName]
    if st then for k,v in pairs(st) do baseSt[k] = v end end
  end
  if type(elemStyleData) == "table" then
    for k,v in pairs(elemStyleData) do baseSt[k] = v end
  end
  return baseSt
end

local function get_valid_orientation(orientStr)
  if type(orientStr) ~= "string" or string.len(orientStr) == 0 then return "vertical" end
  if orientStr:sub(1,1) == "h" then
    return "horizontal"
  else
    return "vertical"
  end
end

local function get_scrollbar_spec_for_container(cont, spec)
  local id = cont.id ; if id == "" then id = cont.internalId end
  local rs = {
    w = 0, h = 0,
    id = id.."_scrollbar",
    listener = spec.scrollbarListener,
    orientation = cont.orientation,
  }
  local isVert = cont.orientation:sub(1,1) == "v"
  if isVert then
    rs.w = cont.barSize
    rs.h = cont.height
    rs.centerVer = cont.id
    rs.after = cont.id
    rs.marginStart = -cont.margins[RGT]
  else
    rs.w = cont.width
    rs.h = cont.barSize
    rs.centerHor = cont.id
    rs.below = cont.id
    rs.marginTop = -cont.margins[BOT]
  end
  return rs
end

local function update_measurements_to_fit_aspect_ratio(m, r)
  if r and m.h > 0 then
    local sR = m.w / m.h
    if sR > r then -- height is limiting, so make width smaller
      local nw = r * m.h
      m.xOffset = m.xOffset + (m.w - nw) / 2 ; m.w = nw
    else -- width is limiting so make height smaller
      local nh = m.w / r
      m.yOffset = m.yOffset + (m.h - nh) / 2 ; m.h = nh
    end
  end
end

-- minv/maxv in range 0-255
local function randclrval(minv, maxv)
  return string.format("%x", math.random(minv, maxv))
end

local elemInfo = respec.internal.supported_elements

--- debug box stuff

local fsmakeelem = respec.util.fs_make_elem
local make_elem = function (obj, ...)
  return fsmakeelem(obj.fsName, ...)
end

-- common funcs

-- returns a "x,y" position string
local function pos_only(obj, customY, customX)
  if not customY then customY = 0 end
  local x = obj.measured[LFT] + obj.margins[LFT] + obj.measured.xOffset + num_or(customX, 0)
  local y = obj.measured[TOP] + obj.margins[TOP] + obj.measured.yOffset + num_or(customY, 0)
  return ""..x..","..y
end

-- returns a "x,y;w,h" position + size string
local function pos_and_size(obj, customY, customX)
  local ms = obj.measured
  return pos_only(obj, customY, customX)..";"..(ms.w)..","..(ms.h)
end

local function get_list_xywh(self)
  return pos_only(self)..";"..self.slotW..","..self.slotH
end

local function set_to_wrap_if_absent(spec)
  if not spec.w and not spec.width then spec.w = WRAP end
  if not spec.h and not spec.height then spec.h = WRAP end
end

local Class = respec.util.Class

----------------------------------------------------------------
--- Public API : Elements
----------------------------------------------------------------

----------------------------------------------------------------
-- Physical Elements
----------------------------------------------------------------

----------------------------------------------------------------
-- Label (label and vertlabel)
----------------------------------------------------------------
respec.elements.Label = Class(respec.PhysicalElement)
function respec.elements.Label:init(spec)
  set_to_wrap_if_absent(spec)
  local einf =  elemInfo.label
  self.vertical = (spec.vertical == true)
  if self.vertical then einf = elemInfo.vertlabel end
  respec.PhysicalElement.init(self, einf, spec)
  self.origW = self.width ; self.origH = self.height
  self.txt = str_or(spec.text, "")
  self.areaLabel = spec.area == true
end
-- override
function respec.elements.Label:to_formspec_string(ver, _)
  if (not self.vertical) and self.areaLabel and ver >= 9 then
    return make_elem(self, pos_and_size(self), self.txt)
  else
  local xOffset, yOffset
  if self.vertical then
    xOffset = self.measured.w / 2
  else
    yOffset = self.measured.h / 2
    if num_or(self.numLines, 1) > 1 then
      yOffset = self.measured.h / (self.numLines * 2)
    end
  end
  return make_elem(self, pos_only(self, yOffset, xOffset), self.txt)
  end
end
-- override
function respec.elements.Label:before_measure(persist)
  local style = get_merged_styles(persist, true, "style_label")
  if self.origW == WRAP or self.origH == WRAP then
    local wh = measure_text(self.txt, persist.playerName, style.font == "mono", style.font_size, 1, self.vertical)
    self.numLines = wh.numLines
    if self.origW == WRAP then self.width = wh.width end
    if self.origH == WRAP then self.height = wh.height end
  end
end

----------------------------------------------------------------
-- button
----------------------------------------------------------------
respec.elements.Button = Class(respec.PhysicalElement)
function respec.elements.Button:init(spec)
  local ei = elemInfo.button ; if spec.exit == true then ei = elemInfo.button_exit end
  set_to_wrap_if_absent(spec)
  respec.PhysicalElement.init(self, ei, spec)
  self.origW = self.width ; self.origH = self.height
  self.paddingsHor = num_or(spec.paddingsHor or spec.paddings, 0) * 2
  self.paddingsVer = num_or(spec.paddingsVer or spec.paddings, 0) * 2
  self.styleData = get_style_type_data(spec.style)
  self.txt = str_or(spec.text, "")
  if type(spec.onClick) == "function" then
    self.on_interact = spec.onClick
  end
end
-- override
function respec.elements.Button:before_measure(persist)
  if self.origW == WRAP or self.origH == WRAP then
    local style = get_merged_styles(persist, true, "style_button", self.styleData)
    local wh = measure_text(self.txt, persist.playerName, style.font == "mono", style.font_size)
    wh.width = wh.width + 2/5 -- approx width of checkbox
    if self.origW == WRAP then self.width = wh.width + self.paddingsHor end
    if self.origH == WRAP then self.height = wh.height + self.paddingsVer end
  end
end
-- override
function respec.elements.Button:to_formspec_string(_, _)
  return make_elem(self, pos_and_size(self), self.internalId, self.txt)
end

----------------------------------------------------------------
-- ButtonUrl (button_url)
----------------------------------------------------------------
respec.elements.ButtonUrl = Class(respec.PhysicalElement)
function respec.elements.ButtonUrl:init(spec)
  local ei = elemInfo.button_url ; if spec.exit == true then ei = elemInfo.button_url_exit end
  respec.PhysicalElement.init(self, ei, spec)
  self.url = str_or(spec.url, "")
  self.txt = str_or(spec.text, self.url)
  if type(spec.onClick) == "function" then
    self.on_interact = spec.onClick
  end
end
-- override
function respec.elements.ButtonUrl:to_formspec_string(_, _)
  return make_elem(self, pos_and_size(self), self.internalId, self.txt, self.url)
end

----------------------------------------------------------------
-- checkbox
----------------------------------------------------------------
respec.elements.Checkbox = Class(respec.PhysicalElement)
function respec.elements.Checkbox:init(spec)
  set_to_wrap_if_absent(spec)
  respec.PhysicalElement.init(self, elemInfo.checkbox, spec)
  self.origW = self.width ; self.origH = self.height
  self.txt = str_or(spec.text, "")
  self.checked = spec.checked == true
  self.styleData = get_style_type_data(spec.style)
  if type(spec.onClick) == "function" then
    self.on_interact = spec.onClick
  end
end
-- override
function respec.elements.Checkbox:before_measure(persist)
  if self.origW == WRAP or self.origH == WRAP then
    local style = get_merged_styles(persist, false, "style_checkbox", self.style)
    local wh = measure_text(self.txt, persist.playerName, style.font == "mono", style.font_size)
    wh.width = wh.width + 2/5 -- approx width of checkbox
    if self.origW == WRAP then self.width = wh.width end
    if self.origH == WRAP then self.height = wh.height end
  end
end
-- override
function respec.elements.Checkbox:to_formspec_string(ver, _)
  local yOffset = 0
  if ver >= 3 then yOffset = self.measured.h / 2 end
  return make_elem(self, pos_only(self, yOffset), self.internalId, self.txt, tostring(self.checked))
end

----------------------------------------------------------------
-- list
----------------------------------------------------------------
respec.elements.List = Class(respec.PhysicalElement)
function respec.elements.List:init(spec)
  respec.PhysicalElement.init(self, elemInfo.list, spec)
  if type(spec.inv) ~= "table" then
    log_error("List spec incorrect, `inv` param must be a table!")
  else
    self.inv = spec.inv
  end
  self.slotW = self.width -- copy these as they will be overwritten later
  self.slotH = self.height
  self.startIndex = min0(num_or(spec.startIndex, 0))
end
-- override
function respec.elements.List:to_formspec_string(_, persist)
  local invLoc, listName = get_inv_loc_and_name_from_data(self.inv, persist)
  return make_elem(self, invLoc, listName, get_list_xywh(self), self.startIndex)
end
-- override
function respec.elements.List:before_measure(persist)
  local sizeX = 1 ; local sizeY = 1
  local padX = 0.25 ; local padY = 0.25
  local style = persist["style_list"]
  if style then
    local size = style["size"] or "1"
    local v1 = size:split(",", false)
    sizeX = v1[1] ; sizeY = v1[2] or v1[1]
    local pad = style["spacing"] or "0.25"
    local v2 = pad:split(",", false)
    padX = v2[1] ; padY = v2[2] or v2[1]
  end
  self.width = min0(self.slotW * (sizeX + padX) - padX)
  self.height = min0(self.slotH * (sizeY + padY) - padY)
end

----------------------------------------------------------------
-- Background (background[] and background9[])
----------------------------------------------------------------
respec.elements.Background = Class(respec.PhysicalElement)
function respec.elements.Background:init(spec)
  spec.width = num_or(spec.width or spec.w, 1)
  spec.height = num_or(spec.height or spec.h, 1)
  self.ignoreLayoutPaddings = true -- special flag used in layout_logic
  local elem = elemInfo.background
  if type(spec.middle) == "number" or type(spec.middle) == "string" then elem = elemInfo.background9 end

  respec.PhysicalElement.init(self, elem, spec)

  self.texture = spec.texture
  if type(spec.fill) == "boolean" then
    self.fill = spec.fill
  else
    self.fill = true
  end
  if elem == elemInfo.background9 then
    self.middle = tostring(spec.middle)
  end
end
-- override
function respec.elements.Background:to_formspec_string(_, _)
  if self.middle then
    local autoclip = self.fill
    if autoclip == nil then autoclip = true end
    return make_elem(self, pos_and_size(self), self.texture, tostring(autoclip), self.middle)
  else
    local autoclip = self.fill
    if autoclip ~= nil then autoclip = tostring(autoclip) end
    return make_elem(self, pos_and_size(self), self.texture, autoclip)
  end
end

----------------------------------------------------------------
-- Field
----------------------------------------------------------------
respec.elements.Field = Class(respec.PhysicalElement)
function respec.elements.Field:init(spec)
  local einf = elemInfo.field
  local isPassword = (spec.isPassword == true)
  if isPassword then einf = elemInfo.pwdfield end
  respec.PhysicalElement.init(self, einf, spec)
  self.isPassword = isPassword
  self.txt = str_or(spec.text, "")
  self.label = str_or(spec.label, "")
  self.closeOnEnter = bool_or(spec.closeOnEnter)
  self.enterAfterEdit = bool_or(spec.enterAfterEdit)
  if type(spec.onSubmit) == "function" then
    self.on_interact = spec.onSubmit
  end
end
-- override
function respec.elements.Field:before_measure(persist)
  if self.label ~= "" then
    if self.margins[TOP] == UNSET then
      local ms = measure_text(self.label, persist.playerName)
      self.margins[TOP] = ms.height
    end
  end
end
-- override
function respec.elements.Field:to_formspec_string(_, _)
  local elems = {}
  if self.closeOnEnter == false then
    table.insert(elems, fsmakeelem("field_close_on_enter", self.internalId, "false"))
  end
  if self.enterAfterEdit == true then
    table.insert(elems, fsmakeelem("field_enter_after_edit", self.internalId, "true"))
  end
  local deftxt = self.txt ; if self.isPassword then deftxt = nil end
  table.insert(elems, make_elem(self, pos_and_size(self), self.internalId, self.label, deftxt))
  return table.concat(elems, "")
end

----------------------------------------------------------------
-- PasswordField (pwdfield[])
----------------------------------------------------------------
respec.elements.PasswordField = Class(respec.elements.Field)
function respec.elements.PasswordField:init(spec)
  spec.isPassword = true
  respec.elements.Field.init(self, spec)
end

----------------------------------------------------------------
-- Scroll Container (scroll_container)
----------------------------------------------------------------
respec.elements.ScrollContainer = Class(respec.PhysicalElement)
function respec.elements.ScrollContainer:init(spec)
  self.scrollElems = spec.elements
  spec.elements = nil
  respec.PhysicalElement.init(self, elemInfo.scroll_container, spec)
  self.layout = respec.Layout(spec)
  self.orientation = get_valid_orientation(spec.orientation)

  local exScroll = type(spec.externalScrollbar) == "string"
  self.scrollFactor = num_or(spec.scrollFactor, 0.1)

  if exScroll then
    self.externalScrollbar = spec.externalScrollbar
  else
    self.barSize = num_or(spec.scrollbarSize, 0.2)
    if self.barSize <= 0 then self.barSize = 0.2 end
    if self.orientation:sub(1,1) == "v" then -- vertical
      if self.margins[RGT] == UNSET then self.margins[RGT] = self.barSize
      else self.margins[RGT] = self.margins[RGT] + self.barSize end
    else -- horizontal
      if self.margins[BOT] == UNSET then self.margins[BOT] = self.barSize
      else self.margins[BOT] = self.margins[BOT] + self.barSize end
    end
    if type(spec.scrollbarOptions) == "table" then
      self.scrollbarOptions = respec.elements.ScrollbarOptions(spec.scrollbarOptions)
    end
    local scrollbarSpec = get_scrollbar_spec_for_container(self, spec)
    self.scrollbar = respec.elements.Scrollbar(scrollbarSpec)
  end
end
-- when added to parent layout
function respec.elements.ScrollContainer:on_added(idGen, layout)
  self.layout:set_elements(self.scrollElems, idGen, layout.ids, layout.fieldElemsById)
  return { self.scrollbar }
end
-- before being measured
function respec.elements.ScrollContainer:before_measure(persist)
  self.layout.playerName = persist.playerName
end
-- after measured is complete
function respec.elements.ScrollContainer:after_measure()
  local isVert = self.orientation:sub(1,1) == "v"
  if isVert then
    self.layout.width = self.width ; self.layout.height = WRAP
  else
    self.layout.width = WRAP ; self.layout.height = self.height
  end
  self.layout:measure(true)
end
-- override
function respec.elements.ScrollContainer:to_formspec_string(ver, persist)
  local str = {}
  local sbid = self.externalScrollbar or ""
  if self.scrollbar then sbid = self.scrollbar.internalId or "" end
  if self.scrollbarOptions then
    str[#str+1] = self.scrollbarOptions:to_formspec_string()
  end
  str[#str+1] = make_elem(self, pos_and_size(self), sbid, self.orientation, self.scrollFactor, "0")
  str[#str+1] = self.layout:to_formspec_string(ver, persist)
  str[#str+1] = fsmakeelem("scroll_container_end")
  return table.concat(str, "")
end

----------------------------------------------------------------
-- Scrollbar 
----------------------------------------------------------------
respec.elements.Scrollbar = Class(respec.PhysicalElement)
function respec.elements.Scrollbar:init(spec)
  respec.PhysicalElement.init(self, elemInfo.scrollbar, spec)
  self.orientation = get_valid_orientation(spec.orientation)
  self.value = str_or(spec.value, "0-1000")
  if type(spec.listener) == "function" then
    self.on_scroll = spec.listener
    self.on_interact = function(state, value, fields)
      local ex = engine.explode_scrollbar_event(value)
      state.rintern[self.internalId] = ex.value
      self.on_scroll(state, ex, fields)
    end
  end
end
-- override
function respec.elements.Scrollbar:to_formspec_string(ver, persist)
  local value = persist.state.rintern[self.internalId] or 0
  return make_elem(self, pos_and_size(self), self.orientation, self.internalId, value)
end

----------------------------------------------------------------
-- Image 
----------------------------------------------------------------
respec.elements.Image = Class(respec.PhysicalElement)
function respec.elements.Image:init(spec)
  local einf = elemInfo.image
  if num_or(spec.frameCount, 0) > 0 then
    einf = elemInfo.animated_image
    self.frameC = spec.frameCount
    self.frameT = num_or(spec.frameTime, 0)
    self.frameS = num_or(spec.frameStart)
    if type(spec.listener) == "function" then
      self.on_interact = spec.listener
    end
  end
  respec.PhysicalElement.init(self, einf, spec)
  self.img = str_or(spec.image, "")
  if type(spec.middle) == "number" or type(spec.middle) == "string" then
    self.mid = tostring(spec.middle)
  end
  local r = num_or(spec.ratio, 0)
  if r > 0.01 then self.ratio = r end
end
-- override
function respec.elements.Image:to_formspec_string(ver, _)
  update_measurements_to_fit_aspect_ratio(self.measured, self.ratio)
  local mid = nil
  if self.mid and ver >= 6 then mid = self.mid end
  if self.frameC then
    return make_elem(self, pos_and_size(self), self.internalId, self.img, self.frameC, self.frameT, self.frameS or 1, mid)
  else
    return make_elem(self, pos_and_size(self), self.img, mid)
  end
end

----------------------------------------------------------------
-- ItemImage (item_image)
----------------------------------------------------------------
respec.elements.ItemImage = Class(respec.PhysicalElement)
function respec.elements.ItemImage:init(spec)
  respec.PhysicalElement.init(self, elemInfo.item_image, spec)
  self.img = str_or(spec.item, "")
  local r = num_or(spec.ratio, 0)
  if r > 0.01 then self.ratio = r end
end
-- override
function respec.elements.ItemImage:to_formspec_string(_, _)
  update_measurements_to_fit_aspect_ratio(self.measured, self.ratio)
  return make_elem(self, pos_and_size(self), self.img)
end

----------------------------------------------------------------
-- TextArea
----------------------------------------------------------------
respec.elements.TextArea = Class(respec.PhysicalElement)
function respec.elements.TextArea:init(spec)
  respec.PhysicalElement.init(self, elemInfo.textarea, spec)
  self.label = str_or(spec.label, "")
  self.txt = str_or(spec.text, "")
end
-- override
function respec.elements.TextArea:before_measure(persist)
  if self.label ~= "" then
    if self.margins[TOP] == UNSET then
      local ms = measure_text(self.label, persist.playerName)
      self.margins[TOP] = ms.height
    end
  end
end

-- override
function respec.elements.TextArea:to_formspec_string(_, _)
  update_measurements_to_fit_aspect_ratio(self.measured, self.ratio)
  local id = self.internalId ; if self.id == "" then id = "" end
  return make_elem(self, pos_and_size(self), id, self.label, self.txt)
end

----------------------------------------------------------------
-- TextArea
----------------------------------------------------------------
respec.elements.Hypertext = Class(respec.PhysicalElement)
function respec.elements.Hypertext:init(spec)
  respec.PhysicalElement.init(self, elemInfo.hypertext, spec)
  self.txt = str_or(spec.text, "")
  if type(spec.listener) == "function" then
    self.on_interact = spec.listener
  end
end
-- override
function respec.elements.Hypertext:to_formspec_string(_, _)
  return make_elem(self, pos_and_size(self), self.internalId, self.txt)
end

----------------------------------------------------------------
-- Non-Physical Elements
----------------------------------------------------------------

----------------------------------------------------------------
-- listring
----------------------------------------------------------------
respec.elements.ListRing = Class(respec.Element)
function respec.elements.ListRing:init(spec)
  respec.Element.init(self, elemInfo.listring)
  self.rings = spec
  if type(self.rings) ~= "table" then self.rings = {} end
end
-- override
function respec.elements.ListRing:to_formspec_string(_, persist)
  local s = ""
  for _, ring in ipairs(self.rings) do
    local invloc, listname = get_inv_loc_and_name_from_data(ring, persist)
    s = s..make_elem(self, invloc, listname)
  end
  if s == "" then s = make_elem(self) end
  return s
end

----------------------------------------------------------------
-- StyleType (style_type)
----------------------------------------------------------------
respec.elements.StyleType = Class(respec.Element)
function respec.elements.StyleType:init(spec)
  respec.Element.init(self, elemInfo.style_type)
  self.target = str_or(spec.target, nil)
  if self.target then
    self.style = get_valid_style(self.fsName, spec)
    if self.style then
      self.styleData = get_style_type_data(spec)
    end
  end
end
-- override
function respec.elements.StyleType:before_measure(persist)
  if self.styleData then
    persist["style_"..self.target] = self.styleData
  end
end
-- override
function respec.elements.StyleType:to_formspec_string(_, _)
  if not self.target or type(self.style) ~= "table" then return "" end
  local propsStr = self.style[""]
  if propsStr == "" then return "" end
  return make_elem(self, self.target, propsStr)
end

----------------------------------------------------------------
-- listcolors
----------------------------------------------------------------
respec.elements.ListColors = Class(respec.Element)
function respec.elements.ListColors:init(spec)
  respec.Element.init(self, elemInfo.listcolors)
  self.slotStr = str_or(spec.slotBg, "")..";"..str_or(spec.slotBgHover, "")
  self.borderStr = str_or(spec.slotBorder)
  if spec.tooltipBg or spec.tooltipFont then
    self.borderStr = str_or(self.borderStr, "")
    self.tooltipStr = str_or(spec.tooltipBg, "")..";"..str_or(spec.tooltipFont, "")
  end
end
-- override
function respec.elements.ListColors:to_formspec_string(_, _)
  return make_elem(self, self.slotStr, self.borderStr, self.tooltipStr)
end

----------------------------------------------------------------
-- ScrollbarOptions
----------------------------------------------------------------
local function valid_arrows(arrowStr)
  if type(arrowStr) ~= "string" or string.len(arrowStr) == 0 then return "default" end
  if arrowStr:sub(1,1) == "s" then
    return "show"
  else
    return "hide"
  end
end
respec.elements.ScrollbarOptions = Class(respec.Element)
function respec.elements.ScrollbarOptions:init(spec)
  respec.Element.init(self, elemInfo.scrollbaroptions)
  self.min = num_or(spec.min, 0)
  self.max = num_or(spec.max, 1000)
  self.sstep = num_or(spec.smallstep, 10)
  self.lstep = num_or(spec.largestep, 100)
  self.thumb = num_or(spec.thumbsize, 10)
  self.arrows = valid_arrows(spec.arrows)
end
-- override
function respec.elements.ScrollbarOptions:to_formspec_string(_, _)
  return make_elem(self, 
    "min="..self.min, "max="..self.max, "smallstep="..self.sstep, "largestep="..self.lstep,
    "thumbsize="..self.thumb, "arrows="..self.arrows
  )
end
