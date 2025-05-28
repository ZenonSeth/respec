-- defines the specific elements

local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right

-- utility funcs

local function num_or(v, o) if type(v) == "number" then return v else return o end end
local function str_or(v, o) if type(v) == "string" then return v else return o end end

local function min0(value)
  if num_or(value, 0) < 0 then return 0 else return value end
end

-- minv/maxv in range 0-255
local function randclrval(minv, maxv)
  return string.format("%x", math.random(minv, maxv))
end

local fesc = core.formspec_escape

local outl = respec.util.fs_make_outline

--- debug box stuff
local function get_debug_box(obj)
  if respec.settings.debug() then
    local ms = obj.measured
    local mg = obj.margins
    local mgt = min0(mg[TOP])
    local mgb = min0(mg[BOT])
    local mgl = min0(mg[LFT])
    local mgr = min0(mg[RGT])
    local boundColor = "#0000FF38"
    local elemColor = "#00FF0038"

    local bx = ms[LFT] + min0(ms.xOffset)
    local by = ms[TOP] + min0(ms.yOffset)
    local bw = ms.w + mgl + mgr
    local bh = ms.h + mgt + mgb
    local bound = "box["..bx..","..by..";"..bw..","..bh..";"..boundColor.."]"
    bound = bound..outl(bx, by, bw, bh)

    local ex = ms[LFT] + mgl + min0(ms.xOffset)
    local ey = ms[TOP] + mgt + min0(ms.yOffset)
    local ew = ms.w
    local eh = ms.h
    local elem = "box["..ex..","..ey..";"..ew..","..eh..";"..elemColor.."]"
    elem = elem..outl(ex, ey, ew, eh)
    return bound..elem
  else return "" end
end

local make_elem = function (obj, ...)
  return get_debug_box(obj)..respec.util.fs_make_elem(obj.fsName, ...)
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
-- Label
----------------------------------------------------------------
respec.elements.Label = Class(respec.PhysicalElement) -- PhysElem("label", id, w, h)
function respec.elements.Label:init(spec)
  respec.PhysicalElement.init(self, "label", spec)
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
  respec.PhysicalElement.init(self, "button", spec)
  self.internal_id = "" -- TODO: generate unique id
  self.txt = str_or(spec.text, "")
  if type(spec.on_click) == "function" then
    self.click_listener = spec.click_listener
  end
end

-- override
function respec.elements.Button:to_formspec_string(_)
  return make_elem(self, pos_and_size(self), self.internal_id, fesc(self.txt))
end


----------------------------------------------------------------
-- listring
----------------------------------------------------------------
respec.elements.ListRing = Class(respec.Element)
function respec.elements.ListRing:init(spec)
  respec.Element.init(self, "listring")
  self.rings = spec
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
