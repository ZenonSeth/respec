
local ri = respec.internal
local suppElems = ri.supported_elements
local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right
local VISIBLE = con.visible

local layoutCount = 0
local function unique_layout_id()
  layoutCount = layoutCount + 1 -- overflow doesn't matter
  return "LAYOUT_"..layoutCount
end

local function get_debug_formspec(layout)
  local s = ""
  if respec.settings.debug() then
    local inset = layout.paddings
    s=s.."box[0,0;"..inset[LFT]..","..layout.measured[BOT]..";#FFFF0028]"
    s=s.."box[0,0;"..layout.measured[RGT]..","..inset[TOP]..";#FFFF0028]"
    s=s.."box[0,"..
        (layout.measured[BOT] - inset[BOT])..";"..
        layout.measured[RGT]..","..inset[BOT]..";#FFFF0028]"
    s=s.."box["..(layout.measured[RGT] - inset[RGT])..
        ",0;"..
        inset[RGT]..","..layout.measured[BOT]..";#FFFF0028]"
  end
  return s
end

local fs_elem_box = respec.internal.fs_elem_box
local function add_common_formspec_string(elem, str)
  local ret = str
  ret = fs_elem_box(elem)..ret
  if not elem.disableCustom and type(elem.borderColor) == "string" then
    ret = ret..fs_elem_box(elem, true, elem.borderColor)
  end
  return ret
end

local num_or = respec.util.num_or

local function parse_common_padd_marg_into(inf, tbl)
  if not inf then return tbl end
  if type(inf) == "number" then
    tbl[TOP] = inf ; tbl[BOT] = inf ; tbl[LFT] = inf ; tbl[RGT] = inf
  elseif type(inf) == table then
    local mL = num_or(inf.hor, 0) ; local mR = mL
    local mT = num_or(inf.ver, 0) ; local mB = mT
    mT = num_or(inf.above,  mT)
    mB = num_or(inf.below,  mB)
    mL = num_or(inf.before, mL)
    mR = num_or(inf.after,  mR)
    tbl[TOP] = mT ; tbl[BOT] = mB ; tbl[LFT] = mL ; tbl[RGT] = mR
  end
end

-- return a table of paddings, with 0 if not set
local function get_paddings(spec)
  local pad = {[TOP] = 0, [BOT] = 0, [LFT] = 0, [RGT] = 0}
  local inf = spec.paddings
  parse_common_padd_marg_into(inf, pad)
  return pad
end

local function get_default_element_margins(spec)
  local defM = {[TOP] = 0, [BOT] = 0, [LFT] = 0, [RGT] = 0}
  local inf = spec.defaultElementMargins
  parse_common_padd_marg_into(inf, defM)
  return defM
end

----------------------------------------------------------------
-- Layout class public functions
----------------------------------------------------------------

-- creates a new layout class that handles laying out other elements (including nested Layouts)
-- spec: table. A subset of the form's spec- see doc/api.md.
-- There shouldn't be a need to ever use this manually
respec.Layout = respec.util.Class(respec.PhysicalElement)

function respec.Layout:init(spec)
  if type(spec.id) ~= "string" then spec.id = unique_layout_id() end
  respec.PhysicalElement.init(self, suppElems._LAYOUT, spec)
  self.elements = {}
  self.fieldElemsById = {}
  self.elementsGraph = respec.graph.new()
  self.ids = {}
  self.paddings = get_paddings(spec)
  self.defaultMargins = get_default_element_margins(spec)
  self.serialized = nil
end
local function do_add(self, element)
  if self.serialized then
    -- TODO: check if anything related to layouting has changed, if not return last serialization
  end
  local newId = element.id
  if not element.info then return end -- invalid element
  if newId and newId ~= "" and self.ids[newId] then
    -- multiple elements with no ID are allowed, but not two with same ID
    respec.log_error("Elements within the same layout cannot have the same ID: "..newId)
    return self
  end
  table.insert(self.elements, element)

  if element.info.inFields then
    self.fieldElemsById[element.internalId] = element
  end
  self.elementsGraph:add_element(element)
  self.ids[newId] = true
  return self
end

-- Sets the content of this layout. If any previous content was set, it will be overwritten
-- Use one of the `respec.elements.` functions to create elements.
function respec.Layout:set_elements(elementsList)
  self.elements = {}
  self.fieldElemsById = {}
  for _, element in ipairs(elementsList) do
    do_add(self, element)
  end
  -- cleanup
  self.ids = nil
  return self
end

function respec.Layout:measure(isRoot)
  if isRoot then
    ri.perform_layout_of_form_layout(self)
  else
    ri.perform_layout(self)
  end
  self.serialized = false
end

-- override of element func
function respec.Layout:to_formspec_string(formspecVersion)
  -- TODO: since elements can be re-set, then check elements state against old state
  if not self.serialized then
    self.serialized = true
    local tbl = {}
    for _, el in ipairs(self.elements) do
      if el.visibility == VISIBLE then
        if el.fsName ~= nil then
          table.insert(tbl, add_common_formspec_string(el, el:to_formspec_string(formspecVersion)))
        end
      end
    end
    self.serialized = table.concat(tbl, "")
  end
  local debug = get_debug_formspec(self)
  return debug..self.serialized
end

function respec.Layout:get_interactive_elements()
  -- TODO handle sub-layouts
  return self.fieldElemsById
end
