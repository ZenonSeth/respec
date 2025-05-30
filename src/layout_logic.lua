
local con = respec.const
local TOP = con.top
local BOT = con.bottom
local LFT = con.left
local RGT = con.right
local UNSET = con.unset
local PARENT = con.parent

local min0 = respec.util.min0
local function clamp(value, min, max)
  if value < min then return min elseif value > max then return max else return value end
end

local function update_container_measurements(side, value, layoutMeasurements)
  if side == TOP or side == BOT then
    if value > layoutMeasurements.max_y then layoutMeasurements.max_y = value end
  else
    if value > layoutMeasurements.max_x then layoutMeasurements.max_x = value end
  end
end

local function invalidate_tree(root, isWidth)
  if not root then return end
  root.resolved = false
  root.element.measured[root.side] = UNSET
  if isWidth then
    root.element.measured.w = UNSET
    root.element.measured.xOffset = UNSET
  else
    root.element.measured.h = UNSET
    root.element.measured.yOffset = UNSET
  end
  for _, child in ipairs(root.childNodes) do
    invalidate_tree(child, isWidth)
  end
end

local function set_fixed_size_if_possible(element)
  local measured = element.measured
  if measured.w == UNSET and element.width > 0 then
    measured.w = element.width
  end

  if measured.h == UNSET and element.height > 0 then
    measured.h = element.height
  end
end

local function set_dynamic_size_if_possible(element, measured, margins)
  if measured.w == UNSET then
    if element.width == 0 then -- width set from aligns
      if measured[LFT] ~= UNSET and measured[RGT] ~= UNSET then
        measured.w = min0(measured[RGT] - measured[LFT]) - min0(margins[RGT]) - min0(margins[LFT])
      end
    -- elseif element.width == con.wrap_content -- TODO - currently only supported for Layout which is handled elsewhere
    end
  end

  if measured.h == UNSET then
    if element.height == 0 then -- height set from measured y/ey
      if measured[TOP] ~= UNSET and measured[BOT] ~= UNSET then
        measured.h = min0(measured[BOT] - measured[TOP]) - min0(margins[TOP]) - min0(margins[BOT])
      end
    -- elseif element.height == con.wrap_content -- TODO - currently only supported for Layout which is handled elsewhere
    end
  end
end

--[[
 S1: nearer to zero side
 S2: futher from zero, opposite side
 align: the element.align table - read-only
 margins: the element.margins table - read-only
 measured: the element.measured table, read-write
 size: the elements set width or height (depending)
 bias: the hor/ver bias (depending)
 set_measured_size: func to set the measured width/height
 set_measured_custom_offset: func to set the custom X/Y offset
]]
local function update_side_logic(S1, S2, align, measured, margins, size, bias, set_measured_size, set_measured_custom_offset)
  if align[S1].side == UNSET and align[S2].side == UNSET then
    -- not a good user case, S2h S1/S2 were unset. But resolve it now
    measured[S1] = 0 ; measured[S2] = size + min0(margins[S1]) + min0(margins[S2])
    set_measured_size(size)
  elseif align[S1].side == UNSET then -- S1 was unset but S2 was set
    if measured[S2] ~= UNSET and size > 0 then -- S2 was also already measured
      -- d.log("setting side 2 based on side 1 for"..elem.id..": "..measured[S1].." + "..size.." + "..min0(margins[S1]).." + "..min0(margins[S2]))
      measured[S1] = measured[S2] - size - min0(margins[S1]) - min0(margins[S2])
      set_measured_size(size)
    end
  elseif align[S2].side == UNSET then -- S2 was unset but S1 was set
    if measured[S1] ~= UNSET and size > 0 then -- S1 was also already measured
      -- d.log("setting side 2 based on side 1 for"..elem.id..": "..measured[S1].." + "..size.." + "..min0(margins[S1]).." + "..min0(margins[S2]))
      measured[S2] = measured[S1] + size + min0(margins[S1]) + min0(margins[S2])
      set_measured_size(size)
    end
  else -- S2h align S1 and S2 were set
    if measured[S1] ~= UNSET and measured[S2] ~= UNSET then
      if size > 0 then -- position element equally between start/end
        -- calc custom offset
        local availSpace = measured[S2] - measured[S1] - margins[S1] - margins[S2]
        local leftoverSpace = availSpace - size -- note that this CAN go negative
        local bias2 = clamp(bias or 0.5, 0, 1)
        local spaceBefore = leftoverSpace * bias2
        set_measured_size(size)
        set_measured_custom_offset(spaceBefore)
      else -- size was 0 or unset, just set it from our width minus margins
        set_measured_size(measured[S2] - measured[S1] - margins[S1] - margins[S2])
      end
    end
  end
end

local function update_element_sides_based_on_align(elem, side)
  local align = elem.align
  local margins = elem.margins
  local measured = elem.measured
  -- NOTE: nested ifs cannot be flattened! Logic needs to hold as it is
  if side == TOP or side == BOT then
    -- d.log("update side logic top/bot.. elem = "..dump(elem))
    update_side_logic(TOP, BOT, align, measured, margins, elem.height, elem.verBias,
      function(v) measured.h = v end,
      function(v) measured.yOffset = v end
    )
  elseif side == LFT or side == RGT then
    -- d.log("update side logic lft/rgt.. elem = "..dump(elem))
    update_side_logic(LFT, RGT, align, measured, margins, elem.width, elem.horBias,
      function(v) measured.w = v end,
      function(v) measured.xOffset = v end
    )
  end
end

-- returns true if measuring was successful, false if the root can't be measured
local function perform_layout_of_node(layout, node, containerMeasurements, parentNode)
  local side = node.side
  local elem = node.element
  local align = elem.align
  local ref = align[side]
  local refSide = ref.side
  local measured = elem.measured
  local margins = elem.margins

  -- d.log("performing layout of: "..elem.id..", side = "..side)

  -- first see if we can first easily set the height or width
  set_fixed_size_if_possible(elem)

  if node.resolved then -- this shouldn't happen - reference loops are unreachable by this algorithm
    return true
  end

  if elem.elements ~= nil then -- this is a sub-layout
    -- perform the layout of this sub-layout before proceeding - this may also set its size
    respec.internal.perform_layout(elem)
  end

  if not parentNode then
    -- root node 
    -- check if it has absolute measurement set
    if refSide == PARENT then
      local value = layout.measured[side]
      -- d.log("align "..elem.id..":"..side.." to parent, rawval = "..value)
      if value == UNSET then -- parent layout hasn't set its bounds yet, likely due to wrap content
        return false -- we need to wait until after other stuff is measured
      end

      local marginSign = 1 ; if side == BOT or side == RGT then marginSign = -1 end
      value = value + marginSign * min0(layout.margins[side])
      -- d.log("align "..elem.id..":"..side.." to parent. LayoutMargins = "..dump(layout.margins).." value = "..value)

      measured[side] = value

      set_dynamic_size_if_possible(elem, measured, margins)
      update_element_sides_based_on_align(elem, side)
      update_container_measurements(side, value, containerMeasurements)
      -- node.resolvedVal = elem.measured[side]
      node.resolved = true
      -- now do the same for each child node
      for _, child in ipairs(node.childNodes) do
        local ret = perform_layout_of_node(layout, child, containerMeasurements, node)
        if not ret then return false end -- in theroy this shouldn't happen
      end
      return true
    elseif refSide == UNSET then
      -- check if other side is set
      update_element_sides_based_on_align(elem, side)
      update_container_measurements(side, measured[side], containerMeasurements)
      if measured[side] ~= UNSET then -- we set it
        node.resolved = true

        -- now do the same for each child node
        for _, child in ipairs(node.childNodes) do
          local ret = perform_layout_of_node(layout, child, containerMeasurements, node)
          if not ret then return false end -- in theroy this shouldn't happen
        end
        return true -- child nodes should resolve fine because they only depend on parent (hmm)
      else return false end -- could happen when side depends on opposite side, but that wasn't resolved yet
    else -- root node but not parent aligned, nor other side set yet. Can probably resolve later
      return false
    end
  else -- a child node (aka side) should be ready to resolve from parent node (aka referenced side)
    -- get the aligned side's measured value
    local refValue = parentNode.element.measured[refSide]
    -- d.log("Peform layout of child node. ChildSide = "..side..", parentSide = "..refSide..", parent val = "..refValue)
    if refValue == UNSET then respec.log_error("parent node was not measured?") ; return false end -- should not happen
    node.element.measured[side] = refValue
    set_dynamic_size_if_possible(elem, measured, margins)
    update_element_sides_based_on_align(elem, side)
    -- node.resolvedVal = elem.measured[side]
    node.resolved = true
    update_container_measurements(side, refValue, containerMeasurements)
    for _, child in ipairs(node.childNodes) do
      local ret = perform_layout_of_node(layout, child, containerMeasurements, node)
      if not ret then return false end -- in theroy this shouldn't happen
    end
    return true
  end
  -- not reachable here
end

local function update_container_measurements_if_necessary(layout, containerMeasurements)
  local align = layout.align
  local measured = layout.measured
  local margins = layout.margins

  if layout.width == con.wrap_content then
    if align[LFT].side == UNSET and align[RGT] == UNSET then
      -- both left/right were unaligned - treat this as a root
      measured[LFT] = 0 ; measured[RGT] = min0(margins[LFT]) + min0(margins[RGT]) + containerMeasurements.max_x
      measured.w = containerMeasurements.max_x
    elseif align[LFT].side == UNSET then -- left was usnet but right was set
      measured[LFT] = measured[RGT] - margins[LFT] - margins[RGT] - containerMeasurements.max_x -- unsure if this is correct..
      measured.w = containerMeasurements.max_x
    elseif align[RGT].side == UNSET then -- right was usnet but left was set
      measured[RGT] = measured[LFT] + margins[RGT] + containerMeasurements.max_x
      measured.w = containerMeasurements.max_x
    -- else: both set? wrap content will be ignored
    end
  end
  if layout.height == con.wrap_content then
    if align[TOP].side == UNSET and align[BOT] == UNSET then
      -- both left/right were unaligned - treat this as a root
      measured[TOP] = 0 ; measured[BOT] = min0(margins[TOP]) + min0(margins[BOT]) + containerMeasurements.max_y
      measured.h = containerMeasurements.max_y
    elseif align[TOP].side == UNSET then -- left was usnet but right was set
      measured[TOP] = measured[BOT] - margins[TOP] - margins[BOT] - containerMeasurements.max_y -- unsure if this is correct..
      measured.h = containerMeasurements.max_y
    elseif align[BOT].side == UNSET then -- right was usnet but left was set
      measured[BOT] = measured[TOP] + margins[BOT] + containerMeasurements.max_y
      measured.h = containerMeasurements.max_y
    -- else: both set? wrap content will be ignored
    end
  end
end

--================================================================
-- public functions
--================================================================

-- To be called internally only
-- Performs the laying-out process of each element
function respec.internal.perform_layout(layout, containerMeasurements)
  local graph = layout.elementsGraph
  local childLayouts = {} -- TODO: handle child layouting

  -- TODO possibly go through all elements and mark as unmeasured? only an issue if remeasured twice which shouldn't happen
  -- starting from each root, evaluate all nodes - mark them as measured

  -- TODO: optimize this: need to figure out dependencies somehow
  local remaining = {}
  local numRemaining = 0
  local containerMeasurements = containerMeasurements or { max_x = 0, max_y = 0 }
  -- d.log("layout graph = "..dump(graph))
  for _, root in pairs(graph.roots) do
    local res = perform_layout_of_node(layout, root, containerMeasurements)
    if not res then table.insert(remaining, root) ; numRemaining = numRemaining + 1 end
  end
  update_container_measurements_if_necessary(layout, containerMeasurements)

  -- BIG TODO: Figure out how to handle chains the way Android does

  -- TODO : iterate and remove remaining, ensuring number of remaining always decreases

  local oldMaxX = containerMeasurements.max_x
  local oldMaxY = containerMeasurements.max_y
  while numRemaining > 0 do
    for i, node in ipairs(remaining) do
      local res = perform_layout_of_node(layout, node, containerMeasurements)
      if res then table.remove(remaining, i) end
    end
    local newRemainig = #remaining
    if newRemainig == numRemaining then -- this is an issue. At least one should have been resolved
      respec.log_error("Unable to resolve some layouts in "..dump(layout))
      return false
    end
    numRemaining = newRemainig
  end

  update_container_measurements_if_necessary(layout, containerMeasurements)

  local changedEnd = oldMaxX ~= containerMeasurements.max_x
  local changedBot = oldMaxY ~= containerMeasurements.max_y

  if changedEnd or changedBot then
    -- invalidate corresponding nodes
    local mustRelayout = false
    if changedEnd then
      for _, root in pairs(graph.roots) do
        if root.side == RGT and root.element.align[RGT].side == PARENT then
          invalidate_tree(root, true)
          mustRelayout = true
        end
      end
    end
    if changedBot then
      for _, root in pairs(graph.roots) do
        if root.side == BOT and root.element.align[BOT].side == PARENT then
          invalidate_tree(root, false)
          mustRelayout = true
        end
      end
    end
    if mustRelayout then
      respec.internal.perform_layout(layout, containerMeasurements)
    end
  end
end

-- To be called internally only
-- Special case of perform layout where the layout is the root one in the form
function respec.internal.perform_layout_of_form_layout(formLayout)
  -- form root layout always starts at 0, 0 - but may have wrap width/height
  local ms = formLayout.measured
  local mg = formLayout.margins
  ms[LFT] = 0
  ms[TOP] = 0
  if formLayout.width > 0 then
    ms[RGT] = formLayout.width
    ms.w = formLayout.width - min0(mg[LFT]) - min0(mg[RGT])
  end
  if formLayout.height > 0 then
    ms[BOT] = formLayout.height
    ms.h = formLayout.height - min0(mg[TOP]) - min0(mg[BOT])
  end
  respec.internal.perform_layout(formLayout) -- do the rest of the layout
end
