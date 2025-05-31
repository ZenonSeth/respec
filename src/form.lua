local con = respec.const

local engine = respec.util.engine

-- shownForms entries format: { form = formRef, state = state }
local shownForms = {}

local function is_str(v) return type(v) == "string" end

local function set_shown_form_data(playerName, formId, data)
  if not shownForms[playerName] then shownForms[playerName] = { count = 0 } end
  local formData = shownForms[playerName]
  formData.count = formData.count + 1
  formData[formId] = data -- just override anything else here before
end

-- returns the data for this form, or nil
local function get_shown_form_data(playerName, formId)
  if not shownForms[playerName] then
    return nil
  end
  return shownForms[playerName][formId]
end

local function remove_shown_form_data(playerName, formId)
  if not shownForms[playerName] then
    respec.log_warn("Trying to remove form data for a player that wasn't there?")
    return
  end
  local formData = shownForms[playerName]
  formData[formId] = nil
  formData.count = formData.count - 1
  if formData.count <= 0 then -- it shoudn't be negative, but just in case
    shownForms[playerName] = nil
  end
end

local function remove_all_shown_form_data_for(playerName)
  shownForms[playerName] = nil
end

----------------------------------------------------------------
-- Form creation util
----------------------------------------------------------------
---
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

local formspecID = 0
local function getNextFormspaceName()
  formspecID = formspecID + 1 -- overflow doesn't really matter here
  return "respec:form_"..(formspecID)
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
local ins = table.insert
local function get_form_str(form)
  local sp = form.spec
  local tbl = {}
  ins(tbl, "formspec_version["..sp.formspec_version.."]")
  ins(tbl, fsc("size", sp.w, sp.h))
  if sp.pos_x and sp.pos_y then
    ins(tbl, fsc("position", sp.pos_x, sp.pos_y))
  end
  if sp.anchor_x and sp.anchor_y then
    ins(tbl, fsc("anchor", sp.anchor_x, sp.anchor_y))
  end
  if sp.screen_padding_x and sp.screen_padding_y then
    ins(tbl, fsc("padding", sp.screen_padding_x, sp.screen_padding_y))
  end
  if sp.no_prepend then
    ins(tbl, "no_prepend[]")
  end
  if sp.allow_close == false then
    ins(tbl, "allow_close[false]")
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
    ins(tbl, bgcf)
  end
  if is_str(sp.set_focus) then
    ins(tbl, "set_focus["..sp.set_focus.."]")
  end
  if is_str(sp.borderColor) then
    ins(tbl, respec.util.fs_make_outline(0, 0, sp.w, sp.h, sp.borderColor, true))
  end
  return table.concat(tbl, "")
end

-- not public
local function get_formspec_string(form)
  form.layout:measure(true)
  local spec = form.spec
  -- update if necessary
  if spec.w == con.wrap_content then spec.w = form.layout.measured[con.right] end
  if spec.h == con.wrap_content then spec.h = form.layout.measured[con.bottom] end
  local formDef = get_form_str(form)
  local debugGrid = ""
  if respec.settings.debug() then
    debugGrid = respec.util.grid(spec.w, spec.h, 5)
  end
  local layoutFs = form.layout:to_formspec_string(spec.formspec_version)
  -- d.log((formDef..layoutFs):gsub("]", "]\n"))
  return formDef..debugGrid..layoutFs
end

-- `self` should be the form
local function handle_spec(self, state)
  local spec = "error"
  if type(self.init_spec) == "table" then spec = self.init_spec
  elseif type(self.init_spec) == "function" then
    spec = self.init_spec(state)
    if type(spec) ~= "table" then
      respec.log_error("specification function did not return a table!")
      return
    end
  else
    respec.log_error("specification must be a table or function!")
    return
  end
    -- customs setup of spec since its root layout
  if not spec.w and not spec.width then spec.w = con.wrap_content end
  if not spec.h and not spec.height then spec.h = con.wrap_content end
  self.spec = verify_specification(spec)
  self.layout = respec.Layout((self.id or "").."_layout", spec)
  self.state = spec.state or {}
  self.bgcolor = spec.bgcolor
  self.fbgcolor = spec.fbgcolor
  self.bgfullscreen = spec.bgfullscreen
  self.reshowOnInteract = true
  if spec.reshowOnInteract == false then self.reshowOnInteract = false end
  return true
end

-- self is the form
local function get_layout_data(self, state)
  if type(self.init_layout) == "table" then
    return self.init_layout
  elseif type(self.init_layout) == "function" then
    local data = self.init_layout(state)
    if type(data) ~= "table" then
      respec.log_error("layoutBuilder returned a value that's not a table!")
      return nil
    end
    return data
  else
    respec.log_error("layoutBuilder must be table or function!")
    return nil
  end
end

-- `self` is the form
-- return true if successful, false otherwise
local function setup_form_for_showing(self, state)
  if not handle_spec(self, state) then return false end
  local layoutData = get_layout_data(self, state)
  if not layoutData then return false end
  self.layout:set_elements(layoutData)
  return true
end

-- returns a new table with keys being the user-specified IDs of each element
local function get_translated_fields(fields, interactiveElems)
  local translated = {}
  for k, v in pairs(interactiveElems) do
    local fieldVal = fields[k]
    if fieldVal and v.id ~= "" then
      translated[v.id] = fieldVal
    end
  end
  return translated
end

----------------------------------------------------------------
-- Event handling functions
----------------------------------------------------------------

local function on_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  local playerName = player:get_player_name()
  local formData = get_shown_form_data(playerName, formname)
  if not formData then return false end
  local form = formData.form

  local interactiveElems = form.layout:get_interactive_elements()
  local translatedFields = get_translated_fields(fields, interactiveElems)
  local reshow = form.reshowOnInteract
  for elemId, elem in pairs(interactiveElems) do
    if fields[elemId] then
      local requestedReshow = elem.on_interact(formData.state, translatedFields)
      reshow = requestedReshow or reshow
    end
  end

  -- Keep this last
  if fields.quit then
    remove_shown_form_data(playerName, formname)
    -- TODO call form on quit func
  end

  if reshow then
    form:reshow(playerName)
  end

  return true
end

local function on_player_leave(obj, _)
  if not obj or not obj:is_player() then return end
  local playerName = obj:get_player_name()
  remove_all_shown_form_data_for(playerName)
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

respec.Form = respec.util.Class()

--[[
  Create a form, with the given specification and layoutBuilder function
]]
function respec.Form:init(specification, layoutBuilder)
  self.id = getNextFormspaceName()
  self.init_spec = specification
  self.init_layout = layoutBuilder
end

--[[ 
  Show the formspec to the player by the given name.
  `playerName` is required, must be a string
  `state` is optional, and is the object passed to the build function. 
   If not specified, an empty table will be passed to the creation functions.
  returns true if successfully shown, false otherwise
--]]
function respec.Form:show(playerName, state)
  state = state or {}
  if not setup_form_for_showing(self, state) then return false end

  local id = self.id
  local existing = get_shown_form_data(playerName, id)
  if existing then -- why was this already there? remove it.
    remove_shown_form_data(playerName, id)
  end

  engine.show_formspec(playerName, id, get_formspec_string(self))
  set_shown_form_data(playerName, id, { form = self, state = state })
  return true
end

-- reshows the form to the player, only if it was already shown!
-- returns true if successfully reshown, false otherwise
function respec.Form:reshow(playerName)
  local data = get_shown_form_data(playerName, self.id)
  if not data then return false end
  local state = data.state
  if not setup_form_for_showing(self, state) then return false end
  engine.show_formspec(playerName, self.id, get_formspec_string(self))
  return true
end

--[[ 
  `extraState` is optional, can be nil
  `checkProtection` is optional, if `true` then the function will check against protection
  This method will automatically add some data to the `state`
  See doc/api.md for information
]]
local get_meta = respec.util.engine.get_meta
local is_protected = respec.util.engine.is_protected
function respec.Form:show_from_node_rightclick(extraState, checkProtection)
  return function(pos, node, user, itemstack, pointed_thing)
    if not user or not user:is_player() then return end
    local playerName = user:get_player_name() ; if type(playerName) ~= "string" then return end
    if checkProtection then
      if is_protected(pos, playerName) then return end
    end
    self:show(playerName, {
      pos = pos,
      node = node,
      nodeMeta = get_meta(pos),
      player = user,
      playerName = playerName,
      itemstack = itemstack,
      pointed_thing = pointed_thing,
      extra = extraState
    })
  end
end

----------------------------------------------------------------
-- Minetest callbacks registration
----------------------------------------------------------------

engine.register_on_player_receive_fields(on_receive_fields)
engine.register_on_leaveplayer(on_player_leave)
