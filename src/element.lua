
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

local function valid_id(value)
  if not value or type(value) ~= "string" then return "" end
  return value
end

local function valid_size(value)
  if not value or type(value) ~= "number" then return 0 end
  if value < 0 then
    return 0
  else
    return value
  end
end

local function clamp(value, min, max)
  if value < min then return min elseif value > max then return max else return value end
end

local function valid_margin(value)
  if not value or type(value) ~= "number" then return 0 end
  return value -- allow negative margins, unless we have an issue later
end

-- check if this is a formspec element we support
local function verify_fsName(fn)
  if not fn or type(fn) ~= "string" then return false end
  return supported_elements_info[fn] ~= nil
end

----------------------------------------------------------------
-- public functions
----------------------------------------------------------------
---
function respec.is_physical(fsName)
  local inf = supported_elements_info[fsName]
  return inf and inf[1] == true
end


-- base element only has a formspec name and tostring
respec.Element = Class()

function respec.Element:init(fsName)
  -- members
  self.fsName = fsName or ""
  self.physical = false
end

respec.PhysicalElement = Class(respec.Element)

-- To be overriden by child classes
function respec.Element:to_formspec_string(formspecVersion) d.log("called base to_formspec_string") ; return "" end -- to be overriden by specific elements

-- don't use directly, instead use one of the `respec.elements.` functions instead
function respec.PhysicalElement:init(fsName, id, w, h)
  -- o = respec.Element:new(o, fsName)
  -- setmetatable(o, self)
  -- self.__index = self
  respec.Element.init(self, fsName)
  self.visible = true -- elements can be set to be invisible or gone
  self.width = valid_size(w)  -- the width set by user
  self.height = valid_size(h) -- the height set by user
  self.visbility = VISIBLE
  self.margins = {[TOP] = UNSET, [BOT] = UNSET, [LFT] = UNSET, [RGT] = UNSET} -- the margins
  self.align = {
      [TOP] = {ref = "", side = UNSET},
      [BOT] = {ref = "", side = UNSET},
      [LFT] = {ref = "", side = UNSET},
      [RGT] = {ref = "", side = UNSET}
    }
  self.horBias = 0.5
  self.verBias = 0.5
  self.chainType = UNSET
  self.measured = { -- represents the location of the outer bounds that include margins
      [TOP] = UNSET, [BOT] = UNSET, [LFT] = UNSET, [RGT] = UNSET,
      w = UNSET, h = UNSET, -- the actual elements (not bounds) w/h
      customX = UNSET, customY = UNSET -- customX/Y override the start where the element is drawn instead of using margins
  }

  self.id = valid_id(id)
  self.physical = true
end

-- returns true if element is valid for use in a Layout, false if not
function respec.internal.verify_element(e)
  -- this is tricky cause any garbage might be pased in
  -- an element requires: ID, fsName, width, height, a table of margins, a table of aligns, a table of measured
  -- and a to_formspec_string function
  if (e) then return true end -- just ignore this complex check for now
  return e and type(e) == "table"
    and e.id and type(e.id) == "string" and e.id ~= ""
    and verify_fsName(e.fsName)
    and e.width and type(e.width) == "number"
    and e.height and type(e.height) == "number"
    and e.margin and type(e.margin) == "table"
    and e.margin[TOP] and type (e.margin[TOP]) == "number"
    and e.margin[BOT] and type (e.margin[BOT]) == "number"
    and e.margin[LFT] and type (e.margin[LFT]) == "number"
    and e.margin[RGT] and type (e.margin[RGT]) == "number"
    and e.align and type(e.align) == "table" -- maybe check individual refs?
    and e.align[TOP] and type(e.align[TOP]) == "table"
    and e.align[BOT] and type(e.align[BOT]) == "table"
    and e.align[LFT] and type(e.align[LFT]) == "table"
    and e.align[RGT] and type(e.align[RGT]) == "table"
    and e.measured and type(e.measured) == "table"
    and e.measured.w and type(e.measured.w) == "number"
    and e.measured.h and type(e.measured.h) == "number"
    and e.measured.x and type(e.measured.x) == "number"
    and e.measured.y and type(e.measured.y) == "number"
    and e.to_formspec_string and type(e.to_formspec_string) == "function"
end

----------------------------------------------------------------
-- Element class API functions
----------------------------------------------------------------

-- align the top of this element to the top of the parent container (layout or form)
function respec.PhysicalElement:top_to_parent_top()
  self.align[TOP].ref = ""
  self.align[TOP].side = con.parent
  return self
end

-- align the bottom of this element to the bottom of the parent container (layout or form)
function respec.PhysicalElement:bottom_to_parent_bottom()
  self.align[BOT].ref = ""
  self.align[BOT].side = con.parent
  return self
end

-- align the left of this element to the left of the parent container (layout or form)
function respec.PhysicalElement:left_to_parent_left()
  self.align[LFT].ref = ""
  self.align[LFT].side = con.parent
  return self
end

-- align the right of this element to the right of the parent container (layout or form)
function respec.PhysicalElement:right_to_parent_right()
  self.align[RGT].ref = ""
  self.align[RGT].side = con.parent
  return self
end

-- align the top of this element to the top of another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:top_to_top_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: "..(self.id)..":top_to_top_of invalid refId")
    return self
  end
  self.align[TOP].ref = refId
  self.align[TOP].side = TOP
  return self
end

-- align the top of this element to the bottom of another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:top_to_bottom_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: "..(self.id)..":top_to_bottom_of invalid refId")
    return self
  end
  self.align[TOP].ref = refId
  self.align[TOP].side = BOT
  return self
end

-- align the bottom of this element to the top of another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:bottom_to_top_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: "..(self.id)..":bottom_to_top_of invalid refId")
    return self
  end
  self.align[BOT].ref = refId
  self.align[BOT].side = TOP
  return self
end

-- align the bottom of this element to the bottom of another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:bottom_to_bottom_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: "..(self.id)..":bottom_to_bottom_of invalid refId")
    return self
  end
  self.align[BOT].ref = refId
  self.align[BOT].side = BOT
  return self
end

-- align the left side of this element to the left side another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:left_to_left_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: left_to_left_of invalid refId")
    return self
  end
  self.align[LFT].ref = refId
  self.align[LFT].side = LFT
  return self
end

-- align the left side of this element to the right side another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:left_to_right_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: left_to_right_of invalid refId")
    return self
  end
  self.align[LFT].ref = refId
  self.align[LFT].side = RGT
  return self
end

-- align the right of this element to the left side of another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:right_to_left_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: right_to_left_of invalid refId")
    return self
  end
  self.align[RGT].ref = refId
  self.align[RGT].side = LFT
  return self
end

-- align the right of this element to the left side of another element
-- `refId` must be a string ID of another element
function respec.PhysicalElement:right_to_right_of(refId)
  if not refId or type(refId) ~= "string" then
    respec.log_error("Error: right_to_right_of invalid refId")
    return self
  end
  self.align[RGT].ref = refId
  self.align[RGT].side = RGT
  return self
end

-- sets all margins (left, right, top, bottom) to desired value
-- `margin` must be a number.
function respec.PhysicalElement:margins_all(margin)
  local p = valid_margin(margin)
  self.margins[TOP] = p
  self.margins[BOT] = p
  self.margins[LFT] = p
  self.margins[RGT] = p
  return self
end

-- sets horizontal margins (left and right)
-- `margin` must be a number.
function respec.PhysicalElement:margins_hor(margin)
  local p = valid_margin(margin)
  self.margins[LFT] = p
  self.margins[RGT] = p
  return self
end

-- sets vertical margins (top and bottom)
-- `margin` must be a number.
function respec.PhysicalElement:margins_ver(margin)
  local p = valid_margin(margin)
  self.margins[TOP] = p
  self.margins[BOT] = p
  return self
end

-- sets margin top
-- `margin` must be a number.
function respec.PhysicalElement:margin_top(margin)
  self.margins[TOP] = valid_margin(margin)
  return self
end

-- sets margin bottom
-- `margin` must be a number.
function respec.PhysicalElement:margin_bottom(margin)
  self.margins[BOT] = valid_margin(margin)
  return self
end

-- sets margin left
-- `margin` must be a number.
function respec.PhysicalElement:margin_left(margin)
  self.margins[LFT] = valid_margin(margin)
  return self
end

-- sets margin right
-- `margin` must be a number.
function respec.PhysicalElement:margin_right(margin)
  self.margins[RGT] = valid_margin(margin)
  return self
end

-- sets the visibility of this element
-- `visibility` must be one of respec.consts.visible/invisible/gone
function respec.PhysicalElement:visibility(visibility)
  if visibility ~= VISIBLE and visibility ~= INVISIBLE and visibility ~= GONE then return self end
  self.visbility = visibility
  return self
end

-- sets the visibility of this element to respec.consts.visible
function respec.PhysicalElement:set_visible()
  self.visbility = VISIBLE
  return self
end

-- sets the visibility of this element to respec.consts.invisible
function respec.PhysicalElement:set_invisible()
  self.visbility = INVISIBLE
  return self
end

-- sets the visibility of this element to respec.consts.gone
function respec.PhysicalElement:set_gone()
  self.visbility = GONE
  return self
end

-- sets the horizontal bias. Values 0-1 accepted
-- This is only used when left and right are aligned AND setting the fixed width - to move the element horizontally within available space.
-- 0 will put the element all the way to the left, 1 all the way to the right of the available space
function respec.PhysicalElement:set_hor_bias(bias)
  self.horBias = clamp(bias, 0, 1)
  return self
end

-- sets the vertical bias. Values 0-1 accepted
-- This is only used when top and bottom are aligned AND setting the fixed height - to move the element vertically within available space.
-- 0 will put the element all the way to the top, 1 all the way to the bottom of the available space
function respec.PhysicalElement:set_ver_bias(bias)
  self.verBias = clamp(bias, 0, 1)
  return self
end
