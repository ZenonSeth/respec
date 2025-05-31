
respec.graph = {}

local con = respec.const
local UNSET = con.unset
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right

-- recursive search of nodes
-- find any node, starting from the given `rootNode`, which has the given id + side
local function find_parent(id, side, rootNode)
  if rootNode.element.id == id and rootNode.side == side then return rootNode end
  -- depth first search child nodes
  for _, childNode in ipairs(rootNode.childNodes) do
    local res = find_parent(id, side, childNode)
    if res ~= nil then return res end
  end
  return nil
end

----------------------------------------------------------------
-- node class
-- represents a single side of an element, and stores some info about arrangement
local function create_node(element, side)
  local node = {
    element = element,  -- the element for which this node describes a side
    side = side,        -- the side of the element which this node describes
    parentNode = nil,   -- which parent node this node is aligned to
    childNodes = {},    -- any nodes which align to this node
    -- resolvedVal = 0,
    resolved = false,
  }
  return node
end

local function connect_nodes(parent, child)
  table.insert(parent.childNodes, child)
  child.parentNode = parent
end
  local function add_root(graph, node)
    graph.roots[graph.rootsPos] = node
    graph.rootsPos = graph.rootsPos + 1
  end

  -- element - the table raf to the element
  -- side: one of consts.top/bottom/left/right
  -- returns the new node created, or nil if it failed
local function add_side(self, element, side)
  local sideRef = element.align[side]
  if sideRef.ref ~= "" and sideRef.ref == element.id then
    respec.log_error("Element with ID "..(element.id).." bounds reference itself - this is not allowed")
    return
  end

  -- each node (represting a side that may align somehow) has:
  -- a parent: either nil, in which case it's a root, or a ref to another node
  -- a list of child nodes which reference it, which may be empty
  local newNode = create_node(element, side)

  -- if side has a reference, try to find it in existing node
  if sideRef.ref ~= "" then
    -- d.log("trying to find parent for elem = "..element.id..", side = "..side..", ref = "..sideRef.ref)
    local foundParent = nil
    for _, rootNode in pairs(self.roots) do
      foundParent = find_parent(sideRef.ref, sideRef.side, rootNode)
      if foundParent then break end
    end
    if foundParent then
      connect_nodes(foundParent, newNode)
    else
      add_root(self, newNode)
    end
  else -- side has no reference ID
    -- even nodes without ref ID need to be in the graph, if they align with parent,
    -- or in case something else needs to align to them
    add_root(self, newNode)
  end

  -- now find any parentless nodes (aka roots) which may reference this node
  local ourId = element.id
  if ourId ~= "" then
    for k, rootNode in pairs(self.roots) do
      local ref =  rootNode.element.align[rootNode.side]
      if ref.ref == ourId and ref.side == side then
        connect_nodes(newNode, rootNode)
        -- remove rootNode from roots as it now has a parent
        self.roots[k] = nil
      end
    end
  end

  return newNode
end

local function add_sides_with_dependency_check(self, elem, S1, S2)
  local n1, n2
  if elem.align[S1] == UNSET then -- side 1 _might_ depend on S2
    n1 = add_side(self, elem, S2)
    n2 = add_side(self, elem, S1)
  else -- anything else just add them in order
    n1 = add_side(self, elem, S1)
    n2 = add_side(self, elem, S2)
  end
  if n1 then n1.oppositeNode = n2 end
  if n2 then n2.oppositeNode = n1 end
end

-- Public functions
----------------------------------------------------------------
-- graph class
-- represents a graph of side-to-side reference
function respec.graph.new()
  local graph = {
    rootsPos = 1, -- this isn't an index
    roots = {}
  }

  function graph:add_element(elem)
    if not elem.physical then return end -- graph is for rendered elements only
    add_sides_with_dependency_check(self, elem, TOP, BOT)
    add_sides_with_dependency_check(self, elem, LFT, RGT)
    return self
  end

  return graph
end
