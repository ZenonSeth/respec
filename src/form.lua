local con = respec.const

local formspecID = 0

local function is_str(v) return type(v) == "string" end

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

local function get_valid_color(clrStr)
  if not is_str(clrStr) then return "" end
  return clrStr
end

local function get_valid_fullscreen(str)
  if type(str) == "boolean" then if str then return "true" else return "false" end end
  if not is_str(str) then return "" end
  if str == "true" or str == "false" or str == "both" or str == "neither" then
    return str
  end
  return ""
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
  local bgC = get_valid_color(sp.bgcolor)
  local fbgC = get_valid_color(sp.fbgcolor)
  local bgF = get_valid_fullscreen(sp.bgfullscreen)
  if bgC ~= "" then
    local bgcf = ""
    if sp.formspec_version >= 3 then
      bgcf = respec.util.fs_make_elem("bgcolor", bgC, bgF, fbgC)
    else
      bgcf = respec.util.fs_make_elem("bgcolor", bgC, bgF)
    end
    str = str..bgcf
  end
  return str
end

-- not public
local function get_formspec_string(form)
  form.layout:measure(true)
  -- update if necessary
  if form.spec.w == con.wrap_content then form.spec.w = form.layout.measured[con.right] end
  if form.spec.h == con.wrap_content then form.spec.h = form.layout.measured[con.bottom] end
  local formDef = get_form_str(form)
  local debugGrid = ""
  if respec.settings.debug() then
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
  Create a form, with the given specification and layoutBuilder function
]]
function respec.Form(specification, layoutBuilder)

  function respec.FormClass:new(uniqueID, spec, builder)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    self.id = uniqueID
    self.layoutBuilder = builder
    -- customs setup of spec since its root layout
    if not spec.w and not spec.width then spec.w = con.wrap_content end
    if not spec.h and not spec.height then spec.h = con.wrap_content end
    self.spec = verify_specification(spec)
    self.layout = respec.Layout((uniqueID or "").."_layout", spec)
    self.state = spec.state or {}
    self.bgColor = spec.bgColor
    self.fbgColor = spec.fbgColor
    self.bgFullscreen = spec.bgFullscreen
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
