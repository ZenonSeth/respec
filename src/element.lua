
local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right
local UNSET = con.unset
local VISIBLE = con.visible
local INVISIBLE = con.invisible
local GONE = con.gone

respec.elements = {} -- init this table here
local Class = respec.util.Class

-- format is { physical, minFormspecVersion }
local supported_elements_info = {
  _LAYOUT = { true, 1 }, label = { true, 1 }, button = { true, 1 }, scroll_container = { true, 3 }, list = { true, 1 }, listring = { false, 1 }, listcolors = { false, 1 }, tooltip = { false, 1 }, image = { true, 1 }, animated_image = { true, 6 }, model = { true, 1 }, item_image = { true, 1 }, bgcolor = { false, 3 }, background = { false, 1 }, background9 = { false, 2 }, pwdfield = { true, 1 }, field = { true, 1 }, field_enter_after_edit = { true, 7 }, field_close_on_enter = { true, 1 }, textarea = { true, 1 }, hypertext = { true, 1 }, vertlabel = { true, 1 }, button_url = { true, 1 }, image_button = { true, 1 }, item_image_button = { true, 1 }, button_exit = { true, 1 }, button_url_exit = { true, 1 }, image_button_exit = { true, 1 }, textlist = { true, 1 }, tabheader = { true, 1 }, box = { true, 1 }, dropdown = { true, 1 }, checkbox = { true, 1 }, scrollbar = { true, 1 }, scrollbaroptions = { false, 1 }, table = { true, 1 }, tableoptions = { false, 1 }, tablecolumns = { false, 1 }, style = { false, 1 }, style_type = { false, 1 }, set_focus = { false, 1 }
}

local function is_num(v) return type(v) == "number" end
local function is_str(v) return type(v) == "string" end

local function clamp(value, min, max)
  if value < min then return min elseif value > max then return max else return value end
end

----------------------------------------------------------------
-- spec related funcs
----------------------------------------------------------------

local function valid_id(value)
  if not is_str(value) then return "" end
  return value
end

local function valid_size(value)
  if not is_num(value) then return 0 end
  return value
end

local function valid_margin(value)
  if not is_num(value) then return 0 end
  return value -- allow negative margins, unless we have an issue later
end

local function valid_bias(b)
  if is_num(b) then return clamp(b, 0, 1) end
  return 0.5
end

-- check if this is a formspec element we support
local function verify_fsName(fn)
  if not is_str(fn) then return false end
  return supported_elements_info[fn] ~= nil
end

local function get_visibility(spec)
  local nv = spec.visibility
  if is_num(nv) and (nv == con.visible or nv == con.invisible or nv == con.gone) then
    return nv
  else
    return con.visible
  end
end

local function get_margins(spec)
  local margins = {[TOP] = 0, [BOT] = 0, [LFT] = 0, [RGT] = 0}
  if is_num(spec.margins) then
    local mg = spec.margins
    margins[TOP] = mg ; margins[BOT] = mg ; margins[LFT] = mg ; margins[RGT] = mg
  end
  if is_num(spec.margins_hor) then
    local mg = spec.margins_hor
    margins[LFT] = mg ; margins[RGT] = mg
  end
  if is_num(spec.margins_ver) then
    local mg = spec.margins_ver
    margins[TOP] = mg ; margins[BOT] = mg
  end
  if is_num(spec.margin_top) then margins[TOP] = spec.margin_top end
  if is_num(spec.margin_bottom) then margins[BOT] = spec.margin_bottom end
  if is_num(spec.margin_start) then margins[LFT] = spec.margin_start end
  if is_num(spec.margin_end) then margins[RGT] = spec.margin_end end

  return margins
end

local function alref(v, func) if is_str(v) then func(v) end end
local function get_align(spec)
  local at = {ref = "", side = UNSET}
  local ab = {ref = "", side = UNSET}
  local al = {ref = "", side = UNSET}
  local ar = {ref = "", side = UNSET}

  if spec.top_to_parent_top == true       then at.side = con.parent end
  if spec.bottom_to_parent_bottom == true then ab.side = con.parent end
  if spec.start_to_parent_start == true   then al.side = con.parent end
  if spec.end_to_parent_end == true       then ar.side = con.parent end

  alref(spec.top_to_top_of,    function(r) at.ref = r ; at.side = TOP end)
  alref(spec.top_to_bottom_of, function(r) at.ref = r ; at.side = BOT end)

  alref(spec.bottom_to_top_of,    function(r) ab.ref = r ; ab.side = TOP end)
  alref(spec.bottom_to_bottom_of, function(r) ab.ref = r ; ab.side = BOT end)

  alref(spec.start_to_start_of, function(r) al.ref = r ; al.side = LFT end)
  alref(spec.start_to_end_of,   function(r) al.ref = r ; al.side = RGT end)

  alref(spec.end_to_start_of, function(r) ar.ref = r ; ar.side = LFT end)
  alref(spec.end_to_end_of,   function(r) ar.ref = r ; ar.side = RGT end)

  if at.side == UNSET and ab.side == UNSET then
    at.side = con.parent
  end
  if al.side == UNSET and ar.side == UNSET then
    al.side = con.parent
  end

  -- d.log("aligns = "..dump({ [TOP] = at, [BOT] = ab, [LFT] = al, [RGT] = ar }))
  return { [TOP] = at, [BOT] = ab, [LFT] = al, [RGT] = ar }
end

----------------------------------------------------------------
-- public functions
----------------------------------------------------------------

-- base element only has a formspec name and tostring
respec.Element = Class()

function respec.Element:init(fsName)
  -- members
  self.fsName = fsName or ""
  self.physical = false
end

respec.PhysicalElement = Class(respec.Element)

-- To be overriden by child classes
function respec.Element:to_formspec_string(formspecVersion) respec.log_warn("called base to_formspec_string") ; return "" end -- to be overriden by specific elements

--[[
--- Do not use directly. Use one of the `respec.elements.` functions instead
--- `fsName` must tbe the formspec element name per Luanti's formspec API
--- `spec` must be a table as documented in doc/api.md
]]
function respec.PhysicalElement:init(fsName, spec)
  -- o = respec.Element:new(o, fsName)
  -- setmetatable(o, self)
  -- self.__index = self
  respec.Element.init(self, fsName)
  self.id = valid_id(spec.id)
  self.width = valid_size(spec.width or spec.w)  -- the width set by user
  self.height = valid_size(spec.height or spec.h) -- the height set by user
  self.visbility = get_visibility(spec)
  self.margins = get_margins(spec) -- the margins
  self.align = get_align(spec)
  self.horBias = valid_bias(spec.hor_bias)
  self.verBias = valid_bias(spec.ver_bias)
  self.chainType = UNSET
  self.measured = { -- represents the location of the outer bounds that include margins
      [TOP] = UNSET, [BOT] = UNSET, [LFT] = UNSET, [RGT] = UNSET,
      w = UNSET, h = UNSET, -- the actual elements (not bounds) w/h
      xOffset = 0, yOffset = 0 -- customX/Y add an offset
  }

  self.physical = true
end
