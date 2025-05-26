respec.util = {}

-- Code from http://lua-users.org/wiki/SimpleLuaClasses with slight modifications
respec.util.Class = function (base, init)
  local c = {}    -- a new class instance
  if not init and type(base) == 'function' then
  init = base
  base = nil
  elseif type(base) == 'table' then
  -- our new class is a shallow copy of the base class!
    for i,v in pairs(base) do
        c[i] = v
    end
    c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c

  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__call = function(class_tbl, ...)
  local obj = {}
  setmetatable(obj,c)
  if init then
    init(obj,...)
  elseif obj.init then
    obj.init(obj, ...)
  elseif base and base.init then
    base.init(obj, ...)
  end
  return obj
  end
  c.init = init
  c.is_a = function(self, klass)
    local m = getmetatable(self)
    while m do 
        if m == klass then return true end
        m = m._base
    end
    return false
  end
  setmetatable(c, mt)
  return c
end

if core and core.log and type(core.log) == "function" then
  respec.log_error = function(msg)
    core.log("error", msg)
    print("ReSpec ERROR: "..msg)
  end
else
  respec.log_error = function(msg)
    print("ReSpec ERROR: "..msg)
  end
end

if core and core.log and type(core.log) == "function" then
  respec.log_warn = function(msg)
    core.log("warning", msg)
    print("ReSpec WARNING: "..msg)
  end
else
  respec.log_warn = function(msg)
    print("ReSpec WARNING: "..msg)
  end
end

function respec.util.list_to_set(table)
  local set = {}
  for _, v in ipairs(table) do
    set[v] = true
  end
  return set
end

local function grid_cell(x,y)
  local clr = "#3F3F3F"
  if (x + y) % 2 == 1 then clr = "#222222" end
  return "box["..x..","..y..";1,1;"..clr.."]"
end
function respec.util.formspec_unit_grid(width, height)
  local tmp = {}
  local w = math.floor(width) + 1
  local h = math.floor(height) + 1
  for x = 0, w do
    for y = 0, h do
      table.insert(tmp, grid_cell(x, y))
    end
  end
  local lines = ""
  for i = 0, width * 4 do
    lines=lines.."box["..(i * 0.25)..",0;0.01,"..h..";#888888]"
  end
  for j = 1, height * 4 do
    lines=lines.."box[0,"..(j * 0.25)..";"..w..",0.01;#888888]"
  end

  return table.concat(tmp, "")..lines
end

-- debug stuff

d = {} -- bad debug
local dlog = function(str)
  core.log("info", str)
  core.chat_send_all(str)
end
d.log = function(str)
  dlog("--->>>")
  dlog(str)
  dlog("----<<<")
end
