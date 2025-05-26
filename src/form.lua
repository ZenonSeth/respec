
respec.WRAP_CONTENT = -1

local formspecID = 0

local function verify_specification(spec)
  if not spec or type(spec) ~= "table" then
    error("Specification was not a table!")
  end
  if not spec.w or not spec.h or type(spec.w) ~= "number" or type(spec.h) ~= "number" then
    error("Specification missing required width/height!")
  end
  if not spec.formspec_version or type(spec.formspec_version) ~= "number" or spec.formspec_version < 2 then
    error("Specification.formspec_version is invalid! Must be a number, and greater than 2")
  end
  -- TODO: verify optional params' types, though maybe without fatal errors
  return spec
end

local function getNextFormspaceName()
  formspecID = formspecID + 1 -- overflow doesn't really matter here
  return "respec_"..(formspecID)
end

local function fsc(n,x,y)
  return ""..n.."["..x..","..y.."]"
end

-- not public - return the form defition string
local function get_form_str(form)
  local sp = form.spec
  local str = "formspec_version["..sp.formspec_version.."]"
  str = str..fsc("size", sp.w, sp.h) -- TODO: propagate layout wrapped size and use it instead
  if sp.pos_x and sp.pos_y then
    str = str..fsc("position", sp.pos_x, sp.pos_y)
  end
  if sp.anchor_x and sp.anchor_y then
    str = str..fsc("anchor", sp.anchor_x, sp.anchor_y)
  end
  if sp.screen_padding_x and sp.screen_padding_y then
    str = str..fsc("padding", sp.screen_padding_x, sp.screen_padding_y)
  end
  if sp.no_prepend then
    str = str.."no_prepend[]"
  end
  if sp.allow_close == false then
    str = str.."allow_close[false]"
  end
  return str
end

-- not public
local function get_formspec_string(form)
  form.layout:measure(true)
  local formDef = get_form_str(form)
  local debugGrid = ""
  if respec.settings.debug then
    debugGrid = respec.util.formspec_unit_grid(form.spec.w, form.spec.h)
  end
  local layoutFs = form.layout:to_formspec_string(form.spec.formspec_version)
  d.log((formDef..layoutFs):gsub("]", "]\n"))
  return formDef..debugGrid..layoutFs
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

respec.FormClass = {
}

--[[
 `specification` must be a table in the following format:
 ```{
    w = 8, h = 9, -- Required: the width and height of the formspec. Corresponds to `size[]`
                  -- Special values: respec.WRAP_CONTENT to simply make the form big enough for all the elements it contains
    formspec_version = 4, -- Required: cannot be lower than 2 (due to real_coordinates)  Corresponds to `formspec_version[]`
    margins = 4 or {} -- Optional: sets the inside paddings of the formspec that affects where elements align to.
      -- 4 : if just a number is passed, all paddings are set to this number
      -- {horizontal = 4, vertical = 4} -- set the horizontal or vertical paddings separate. Either is optional
      -- {left = 4, right = 4, top = 0, bottom = 0}, -- Set the specfic paddings for each side. All are optional
    pos_x = 0.5, pos_y = 0.5, -- Optional: the position on the screen (0-1). Corresponds to `position[]`
    anchor_x = 0.5, anchor_y = 0.5,  -- Optional: the anchor for the on-screen position. Corresponds to `anchor[]`
    screen_padding_x = 0.05, screen_padding_y = 0.05, -- Optional: the padding required around the form, in screen proportion. Corresponds to `padding[]`
    no_prepend = false, -- Optional: disables player:set_formspec_prepend. Corresponds to `no_prepend[]`
    allow_close = true, -- Optional: if false, disable using closing formspec via esc or similar. Corresponds to `allow_close[]`
 }```

 `layoutBuilder` is a function used to create the form's layout.
 It simply gets passed a `data` object which can be used to maintain information between re-showing the form. 
 
 The function must return a list of elements (created via respec.Elements)

 For example:
 ```
 function(data)
  return {
    respec.Elements.Label("label_id", 3, 1)
      :text("Count = "..(data.count or "0"))
      :top_to_parent_top():left_to_parent_left(),

    respec.Elements.Button("btn_id", 3, 1)
      :text("Press me!")
      :top_to_bottom_of("label_id")
      :left_to_left_of("label_id")
      :add_on_click(function(dataFromOnClick)
        dataFromOnClick.count = (dataFromOnClick.count or 0) + 1
        return true
      end)
  }
 end
 ```
]]
function respec.Form(specification, layoutBuilder)
  -- It's safer to use respec.Form( ) instead
  function respec.FormClass:new(uniqueID, spec, builder)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    self.id = uniqueID
    self.layoutBuilder = builder
    self.spec = verify_specification(spec)
    self.layout = respec.Layout((uniqueID or "").."_layout", spec.w, spec.h)
    self.state = "" -- hmm

    local mgs = self.spec.margins
    local mgType = type(mgs)
    if mgType == "number" then self.layout:margins_all(mgs)
    elseif mgType == "table" then
      if type(mgs.horizontal) == "number" then self.layout:margins_hor(mgs.horizontal) end
      if type(mgs.vertical) == "number" then self.layout:margins_ver(mgs.vertical) end
      if type(mgs.top) == "number" then self.layout:margin_top(mgs.top) end
      if type(mgs.bottom) == "number" then self.layout:margin_top(mgs.bottom) end
      if type(mgs.left) == "number" then self.layout:margin_top(mgs.left) end
      if type(mgs.right) == "number" then self.layout:margin_top(mgs.right) end
    end

    return obj
  end

  return respec.FormClass:new(getNextFormspaceName(), specification, layoutBuilder)
end

--[[ Show the formspec to the player by the given name.
  `playerName` is required, must be a string
  `data` is optional, and is the object passed to the build function (if empty, its )
--]]
function respec.FormClass:show(playerName, data)
  data = data or {}
  local layoutData = self.layoutBuilder(data)
  self.layout:set_elements(layoutData)
  core.show_formspec(playerName, self.id, get_formspec_string(self))
end
