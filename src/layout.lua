
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
    s=s.."box[0,0;"..layout.margins[LFT]..","..layout.measured[BOT]..";#FFFF0028]"
    s=s.."box[0,0;"..layout.measured[RGT]..","..layout.margins[TOP]..";#FFFF0028]"
    s=s.."box[0,"..
        (layout.measured[BOT] - layout.margins[BOT])..";"..
        layout.measured[RGT]..","..layout.margins[BOT]..";#FFFF0028]"
    s=s.."box["..(layout.measured[RGT] - layout.margins[RGT])..
        ",0;"..
        layout.margins[RGT]..","..layout.measured[BOT]..";#FFFF0028]"
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

----------------------------------------------------------------
-- Layout class public functions
----------------------------------------------------------------

-- creates a new layout class that handles laying out other elements (including nested Layouts)
-- spec: table with the following format:
-- {
--     `id` : String, optional - used for alinging other elements to this layout
--     `w`: Required: width of the layout, 0 to set width via align left/right
--     `h`: Required: height of the layout, 0 to set height via align top/bottom
--    padding = 1,  -- WIP NOT WORKING! Optional, only used when WRAP_CONTENT is used for width or height. 
--                  -- The extra padding to include between elements and the border of the form when wrapping them
--

respec.Layout = respec.util.Class(respec.PhysicalElement)

function respec.Layout:init(layoutId, spec)
  if not spec.id then spec.id = unique_layout_id() end
  respec.PhysicalElement.init(self, suppElems._LAYOUT, spec)
  self.elements = {}
  self.fieldElemsById = {}
  self.elementsGraph = respec.graph.new()
  self.ids = {}
  self.padding = 0
  -- defaultMarginsHor = UNSET -- not used
  -- defaultMarginsVer = UNSET -- not used
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
