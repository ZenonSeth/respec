
local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right
local UNSET = con.unset
local VISIBLE = con.visible
local INVISIBLE = con.invisible
local GONE = con.gone
local PARENT = con.parent

respec.elements = {} -- init this table here
local Class = respec.util.Class

local function minf(tbl) return { name = tbl[1], minVer = tbl[2], inFields = tbl[3] } end

-- format is { name = "formspec_name", minVer = MIN_VERSION_INT, inFields = IS_FIELD_SENT }
respec.internal.supported_elements = {
  _LAYOUT =           minf { "_LAYOUT", 1, false },
  label =             minf { "label", 1, false },
  button =            minf { "button", 1, true },
  scroll_container =  minf { "scroll_container", 3, false },
  list =              minf { "list", 1, true },
  listring =          minf { "listring", 1, false },
  listcolors =        minf { "listcolors", 1, false},
  tooltip =           minf { "tooltip", 1, false },
  image =             minf { "image", 1, false },
  animated_image =    minf { "animated_image", 6, false },
  model =             minf { "model", 1, false },
  item_image =        minf { "item_image", 1, false },
  background =        minf { "background", 1, false },
  background9 =       minf { "background9", 2, false },
  pwdfield =          minf { "pwdfield", 1, true }, -- maybe incorporate into "field"
  field =             minf { "field", 1, true },
  field_enter_after_edit = minf { "field_enter_after_edit", 7, false }, -- incorporate into field
  field_close_on_enter =  minf { "field_close_on_enter", 1, false }, -- incorporate into field
  textarea =          minf { "textarea", 1, true },
  hypertext =         minf { "hypertext", 1, false },
  vertlabel =         minf { "vertlabel", 1, false },
  button_url =        minf { "button_url", 1, true },
  image_button =      minf { "image_button", 1, true },
  item_image_button = minf { "item_image_button", 1, true },
  button_exit =       minf { "button_exit", 1, true }, -- incorporate into button
  button_url_exit =   minf { "button_url_exit", 1, true }, -- incorporate into button_url
  image_button_exit = minf { "image_button_exit", 1, true }, -- incorporate into image_button
  textlist =          minf { "textlist", 1, true },
  tabheader =         minf { "tabheader", 1, true },
  box =               minf { "box", 1, false },
  dropdown =          minf { "dropdown", 1, true },
  checkbox =          minf { "checkbox", 1, true },
  scrollbar =         minf { "scrollbar", 1, true },
  scrollbaroptions =  minf { "scrollbaroptions", 1, false },
  table =             minf { "table", 1, false },
  tableoptions =      minf { "tableoptions", 1, false }, -- hmm
  tablecolumns =      minf { "tablecolumns", 1, false }, -- maybe incorporate into table
  style =             minf { "style", 1, false },
  style_type =        minf { "style_type", 1, false },
  set_focus =         minf { "set_focus", 1, false } -- incorporate into form
}
local elem_info = respec.internal.supported_elements

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

local function valid_bias(b)
  if is_num(b) then return clamp(b, 0, 1) end
  return 0.5
end

local function get_visibility(spec)
  local nv = spec.visibility
  if is_num(nv) and (nv == VISIBLE or nv == INVISIBLE or nv == GONE) then
    return nv
  else
    return VISIBLE
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

  if spec.top_to_parent_top == true       then at.side = PARENT end
  if spec.bottom_to_parent_bottom == true then ab.side = PARENT end
  if spec.start_to_parent_start == true   then al.side = PARENT end
  if spec.end_to_parent_end == true       then ar.side = PARENT end

  alref(spec.top_to_top_of,    function(r) at.ref = r ; at.side = TOP end)
  alref(spec.top_to_bottom_of, function(r) at.ref = r ; at.side = BOT end)

  alref(spec.bottom_to_top_of,    function(r) ab.ref = r ; ab.side = TOP end)
  alref(spec.bottom_to_bottom_of, function(r) ab.ref = r ; ab.side = BOT end)

  alref(spec.start_to_start_of, function(r) al.ref = r ; al.side = LFT end)
  alref(spec.start_to_end_of,   function(r) al.ref = r ; al.side = RGT end)

  alref(spec.end_to_start_of, function(r) ar.ref = r ; ar.side = LFT end)
  alref(spec.end_to_end_of,   function(r) ar.ref = r ; ar.side = RGT end)

  if at.side == UNSET and ab.side == UNSET then
    at.side = PARENT
  end
  if al.side == UNSET and ar.side == UNSET then
    al.side = PARENT
  end

  -- d.log("aligns = "..dump({ [TOP] = at, [BOT] = ab, [LFT] = al, [RGT] = ar }))
  return { [TOP] = at, [BOT] = ab, [LFT] = al, [RGT] = ar }
end

local elem_unique_id = 0
local function  get_unique_id()
  elem_unique_id = elem_unique_id + 1 -- overflow doesn't matter
  return tostring(elem_unique_id)
end

----------------------------------------------------------------
-- public functions
----------------------------------------------------------------

-- base element, for non-physical elements
respec.Element = Class()

function respec.Element:init(fselem)
  if fselem and fselem.name and elem_info[fselem.name] then
    self.fsName = fselem.name
    self.info = fselem
  else
    respec.log_error("Unsupported element created: "..dump(fselem))
  end
  self.physical = false
  self.internalId = get_unique_id()
end

respec.PhysicalElement = Class(respec.Element)

-- To be overriden by child classes
function respec.Element:to_formspec_string(formspecVersion)
  respec.log_warn("called base to_formspec_string") ; return ""
end

--[[
--- Do not use directly. Use one of the `respec.elements.` functions instead
--- `fselem` must be an entry from the respec.internal.supported_elements table
--- `spec` must be a table as documented in doc/api.md
]]
function respec.PhysicalElement:init(fselem, spec)
  -- o = respec.Element:new(o, fsName)
  -- setmetatable(o, self)
  -- self.__index = self
  respec.Element.init(self, fselem)
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
  self.on_interact = function(...) end -- to be overwritten by interactive elements

  self.physical = true
end
