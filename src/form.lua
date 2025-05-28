
respec.WRAP_CONTENT = -1

local formspecID = 0

local function verify_specification(spec)
  if not spec or type(spec) ~= "table" then
    error("Specification was not a table!")
  end
  if (type(spec.w) ~= "number" and type(spec.width) ~= "number") or (type(spec.h) ~= "number" and type(spec) ~= "number") then
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
  local ltm = form.layout.measured
  local sp = form.spec
  local str = "formspec_version["..sp.formspec_version.."]"
  str = str..fsc("size", sp.w, sp.h)
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
  -- update if necessary
  if form.spec.w == respec.const.wrap_content then form.spec.w = form.layout.measured[respec.const.right] end
  if form.spec.h == respec.const.wrap_content then form.spec.h = form.layout.measured[respec.const.bottom] end
  local formDef = get_form_str(form)
  local debugGrid = ""
  if respec.settings.debug then
    debugGrid = respec.util.grid(form.spec.w, form.spec.h, 5)
  end
  local layoutFs = form.layout:to_formspec_string(form.spec.formspec_version)
  d.log((formDef..layoutFs):gsub("]", "]\n"))
  return formDef..debugGrid..layoutFs
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

respec.FormClass = {}

--[[
 `specification` must be a table in the following format:
 ```{
    w = 8, h = 9, -- Optional: the width and height of the formspec. Corresponds to `size[]`
                  -- Special values: respec.const.wrap_content to simply make the form big enough for all the elements it contains
                  -- if either w/h is unset, wrap_content is assumed
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
    respec.Elements.Label(labelSpec),
    respec.Elements.Button(buttonSpec),
  }
 end
 ```
]]
function respec.Form(specification, layoutBuilder)

  function respec.FormClass:new(uniqueID, spec, builder)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    self.id = uniqueID
    self.layoutBuilder = builder
    -- customs setup of spec since its root layout
    if not spec.w and not spec.width then spec.w = respec.const.wrap_content end
    if not spec.h and not spec.height then spec.h = respec.const.wrap_content end
    self.spec = verify_specification(spec)
    self.layout = respec.Layout((uniqueID or "").."_layout", spec)
    self.state = spec.state or {}
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
