-- defines the specific elements

local con = respec.const
local TOP = con.top
local LFT = con.left
local WRAP = con.wrap_content
local UNSET = con.unset

-- utility funcs

local num_or = respec.util.num_or
local str_or =  respec.util.str_or
local bool_or =  respec.util.bool_or
local min0 = respec.util.min0
local log_error = respec.log_error

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

-- minv/maxv in range 0-255
local function randclrval(minv, maxv)
  return string.format("%x", math.random(minv, maxv))
end

local fesc = respec.util.engine.formspec_escape
local elemInfo = respec.internal.supported_elements

--- debug box stuff

local fsmakeelem = respec.util.fs_make_elem
local make_elem = function (obj, ...)
  return fsmakeelem(obj.fsName, ...)
end

-- common funcs

-- returns a "x,y" position string
local function pos_only(obj, customY)
  if not customY then customY = 0 end
  local x = obj.measured[LFT] + min0(obj.margins[LFT]) + min0(obj.measured.xOffset)
  local y = obj.measured[TOP] + min0(obj.margins[TOP]) + min0(obj.measured.yOffset) + num_or(customY, 0)
  return ""..x..","..y
end

-- returns a "x,y;w,h" position + size string
local function pos_and_size(obj, customY)
  local ms = obj.measured
  return pos_only(obj, customY)..";"..(ms.w)..","..(ms.h)
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
-- Label
----------------------------------------------------------------
respec.elements.Label = Class(respec.PhysicalElement) -- PhysElem("label", id, w, h)
function respec.elements.Label:init(spec)
  set_to_wrap_if_absent(spec)
  respec.PhysicalElement.init(self, elemInfo.label, spec)
  self.origW = self.width ; self.origH = self.height
  self.txt = str_or(spec.text, "")
  self.areaLabel = spec.area == true
end
-- override
function respec.elements.Label:to_formspec_string(ver, _)
  if self.areaLabel and ver >= 9 then
    return make_elem(self, pos_and_size(self), fesc(self.txt))
  else
  local yOffset = self.measured.h / 2
  if num_or(self.numLines, 1) > 1 then
    yOffset = self.measured.h / (self.numLines * 2)
  end
  return make_elem(self, pos_only(self, yOffset), fesc(self.txt))
  end
end
-- override
function respec.elements.Label:before_measure(persist)
  local style = get_merged_styles(persist, true, "style_label")
  if self.origW == WRAP or self.origH == WRAP then
    local wh = measure_text(self.txt, persist.playerName, style.font == "mono", style.font_size)
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
  set_to_wrap_if_absent(spec)
  respec.PhysicalElement.init(self, elemInfo.button, spec)
  self.origW = self.width ; self.origH = self.height
  self.paddingsHor = num_or(spec.paddingsHor or spec.paddings, 0) * 2
  self.paddingsVer = num_or(spec.paddingsVer or spec.paddings, 0) * 2
  self.styleData = get_style_type_data(spec.style)
  self.txt = str_or(spec.text, "")
  if type(spec.on_click) == "function" then
    self.on_interact = spec.on_click
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
  return make_elem(self, pos_and_size(self), self.internalId, fesc(self.txt))
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
  if type(spec.on_click) == "function" then
    self.on_interact = spec.on_click
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
  return make_elem(self, pos_only(self, yOffset), self.internalId, fesc(self.txt), tostring(self.checked))
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
  local deftxt = fesc(self.txt) ; if self.isPassword then deftxt = nil end
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
-- style_type
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
