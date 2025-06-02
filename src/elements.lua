-- defines the specific elements

local con = respec.const
local TOP = con.top
local LFT = con.left

-- utility funcs

local num_or = respec.util.num_or
local str_or =  respec.util.str_or
local min0 = respec.util.min0

local get_valid_style = respec.elements.get_valid_style
respec.elements.get_valid_style = nil

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
  -- TODO: add offsets from measured class
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
  respec.PhysicalElement.init(self, elemInfo.label, spec)
  self.txt = str_or(spec.text, "")
  self.areaLabel = spec.area == true
end
-- override
function respec.elements.Label:to_formspec_string(ver, _)
  if self.areaLabel and ver >= 9 then
    return make_elem(self, pos_and_size(self), fesc(self.txt))
  else
  local yOffset = self.measured.h / 2
  return make_elem(self, pos_only(self, yOffset), fesc(self.txt))
  end
end

----------------------------------------------------------------
-- button
----------------------------------------------------------------
respec.elements.Button = Class(respec.PhysicalElement)
function respec.elements.Button:init(spec)
  respec.PhysicalElement.init(self, elemInfo.button, spec)
  self.txt = str_or(spec.text, "")
  if type(spec.on_click) == "function" then
    self.on_interact = spec.on_click
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
  respec.PhysicalElement.init(self, elemInfo.checkbox, spec)
  self.txt = str_or(spec.text, "")
  self.checked = spec.checked == true
  if type(spec.on_click) == "function" then
    self.on_interact = spec.on_click
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
  -- TODO: magic for width/height
  respec.PhysicalElement.init(self, elemInfo.list, spec)
  if type(spec.inv) ~= "table" then
    respec.log_error("List spec incorrect, `inv` param must be a table!")
  else
    self.inv = spec.inv
  end
  self.slotW = self.width -- copy these as they will be overwritten later
  self.slotH = self.height
  self.startIndex = min0(num_or(spec.startIndex, 0))
end
-- override
function respec.elements.List:to_formspec_string(_, persist)
  local idata = self.inv
  local invLoc = idata[1]
  local listName = idata[2]
  local state = persist.state
  if invLoc == -1  then -- special case to autopopulate with position from state
    if not state or not state.pos or not state.pos.x then
      respec.log_error("Error: List cannot be created, did you forget to use `show_from_node_rightclick()`?")
      return ""
    end
    local pos = state.pos
    invLoc = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  end
  return make_elem(self, invLoc, listName, get_list_xywh(self), self.startIndex)
end
-- override
function respec.elements.List:before_measure(persist)
  -- TODO: account for style config from persist
  local slotSize = 1
  local slotPad = 0.25
  self.width = min0(self.slotW * (slotSize + slotPad) - slotPad)
  self.height = min0(self.slotH * (slotSize + slotPad) - slotPad)
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
function respec.elements.ListRing:to_formspec_string(_, _)
  local s = ""
  for _, ring in ipairs(self.rings) do
    s = s..make_elem(self, fesc(str_or(ring[1], "")), fesc(str_or(ring[2], "")))
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
  end
end
-- override
function respec.elements.StyleType:to_formspec_string(_, _)
  if not self.target or type(self.style) ~= "table" then return "" end
  local propsStr = self.style[""]
  if propsStr == "" then return "" end
  return make_elem(self, fesc(self.target), fesc(propsStr))
end
