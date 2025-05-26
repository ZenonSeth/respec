-- defines the specific elements

local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right
local UNSET = con.unset

--
local function min0(value)
  if value < 0 then return 0 else return value end
end

local function get_debug_box(obj)
  if respec.settings.debug then
    local ms = obj.measured
    local mg = obj.margins
    local mgt = min0(mg[TOP])
    local mgb = min0(mg[BOT])
    local mgl = min0(mg[LFT])
    local mgr = min0(mg[RGT])
    local boundColor = "#0000FF68"
    local elemColor = "#00FF0068"
    local bound = "box["..ms[LFT]..","..ms[TOP]..";"..(ms.w + mgl + mgr)..","..(ms.h + mgt + mgb)..";"..boundColor.."]"
    local elem = "box["..(ms[LFT] + mgl)..","..(ms[TOP] + mgt)..";"..(ms.w)..","..(ms.h)..";"..elemColor.."]"
    return bound..elem
  else return "" end
end

-- utility funcs

-- TODO - Fix up these functions
local function append_args(str, ...)
  if ... == nil then
    str = str..";"
  else
    local args = {...}
    if #args == 0 then str = str..";"
    else
      for _, a in ipairs(args) do
        str = str..";"..core.formspec_escape(a)
      end
    end
  end
  str = str.."]"
  return str
end

-- TODO - Fix up these functions
local function pos_only(obj, customY)
  if not customY then customY = 0 end
  -- TODO: add offsets from measured class
  return get_debug_box(obj)..(obj.fsName).."["..(obj.measured[LFT] + min0(obj.margins[LFT]))..","..(obj.measured[TOP] + min0(obj.margins[TOP]) + customY)
end

local function pos_and_size(obj)
  local ms = obj.measured
  local mg = obj.margins
  local mgt = min0(mg[TOP])
  local mgb = min0(mg[BOT])
  local mgl = min0(mg[LFT])
  local mgr = min0(mg[RGT])
  return get_debug_box(obj)..(obj.fsName).."["..(ms[LFT] + mgl)..","..(ms[TOP] + mgt)..";"..(ms.w)..","..(ms.h)
end


----------------------------------------------------------------
--- Public API : Elements
----------------------------------------------------------------

local Class = respec.util.Class

----------------------------------------------------------------
-- label
-- w and h are used for laying out the label,
-- but for them to affect (aka clip/wrap) the label, you must call area_label()
----------------------------------------------------------------
respec.elements.Label = Class(respec.PhysicalElement) -- PhysElem("label", id, w, h)
function respec.elements.Label:init(id, w, h)
  respec.PhysicalElement.init(self, "label", id, w, h)
  self.txt = ""
  self.areaLabel = false
end

-- `text` must be a string
function respec.elements.Label:text(text)
  if not text or type(text) ~= "string" then return end
  self.txt = text
  return self
end

-- sets label to be an area_label (aka have both position and width/height)
-- requires formspec min version 9 - otherwise ignored
function respec.elements.Label:area_label()
  self.areaLabel = true
  return self
end

-- override
function respec.elements.Label:to_formspec_string(formspecVersion)
  d.log("label.txt = "..dump(self.txt))
  if self.areaLabel and formspecVersion >= 9 then
    return append_args(pos_and_size(self), self.txt)
  else
  local yOffset = self.measured.h / 2
  return append_args(pos_only(self, yOffset), self.txt)
  end
end

----------------------------------------------------------------
-- button
----------------------------------------------------------------
respec.elements.Button = Class(respec.PhysicalElement)
function respec.elements.Button:init(id, w, h)
  respec.PhysicalElement.init(self, "button", id, w, h)
  self.txt = ""
  self.click_listeners = {}
end
-- `txt` must be a string
function respec.elements.Button:text(txt)
  if not txt or type(txt) ~= "string" then return end
  self.txt = txt
  return self
end

-- `onClickFunction` must be a function accepting the current state. Return `true` to re-show the formspec.
function respec.elements.Button:add_on_click(onClickFunction)
  if not onClickFunction or type(onClickFunction) ~= "function" then return end
  table.insert(self.click_listeners, onClickFunction)
  return self
end

-- override
function respec.elements.Button:to_formspec_string(_)
  return append_args(pos_and_size(self), self.id, self.txt)
end


----------------------------------------------------------------
-- listring
----------------------------------------------------------------
respec.elements.ListRing = Class(respec.Element)
function respec.elements.ListRing:init()
  respec.Element.init(self, "listring")
end

-- add a list-ring entry
-- `inventoryLocation` and `listName` must both be strings
function respec.elements.ListRing:add_ring(inventoryLocation, listName)
  table.insert(self.rings, {loc = inventoryLocation, name = listName})
  return self
end
function respec.elements.ListRing:to_formspec_string(_)
  -- TODO: generalize this
  local s = ""
  for _, ring in ipairs(self.rings) do
    s = s..self.fsName.."["..ring.loc..";"..ring.name.."]"
  end
  if s == "" then s = self.fsName.."[]" end
  return s
end
