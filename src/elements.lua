-- defines the specific elements

local con = respec.const
local TOP = con.top
local LFT = con.left

-- utility funcs

local num_or = respec.util.num_or
local str_or =  respec.util.str_or
local min0 = respec.util.min0

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
function respec.elements.Label:to_formspec_string(formspecVersion)
  if self.areaLabel and formspecVersion >= 9 then
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
function respec.elements.Button:to_formspec_string(_)
  return make_elem(self, pos_and_size(self), self.internalId, fesc(self.txt))
end


-- checkbox

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
function respec.elements.Checkbox:to_formspec_string(ver)
  local yOffset = 0
  if ver >= 3 then yOffset = self.measured.h / 2 end
  return make_elem(self, pos_only(self, yOffset), self.internalId, fesc(self.txt), tostring(self.checked))
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
function respec.elements.ListRing:to_formspec_string(_)
  local s = ""
  for _, ring in ipairs(self.rings) do
    s = s..make_elem(self, fesc(str_or(ring[1], "")), fesc(str_or(ring[2], "")))
  end
  if s == "" then s = make_elem(self) end
  return s
end
