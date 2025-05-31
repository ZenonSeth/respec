Note: This is still work in progress - docs are missing and existing api may change in the near future.

# Form
To create a form use:
```lua
respec.Form(specFunction, builderFunction)
```

## State
Forms have a concept of `state` - a lua table, that can be given to its `show()` function, and is also passed when creating the form, and to any event-handlers (e.g. button click listeners) where the `state` can be modified and will persist until the form is closed.

## `specFunction`
`specFunction` must be a either:
- A simple `spec` table with the format shown below
- A function that accepts the `state` object, `function(state)`. The function must return the `spec` table.

`spec` table format:
 ```lua
 {
    w = 8, h = 9, 
    -- Optional: the width and height of the formspec. Corresponds to `size[]`
    -- Special values: respec.const.wrap_content to simply make the form big enough for all the elements it contains
    -- if either w/h is unset, wrap_content is assumed for the missing value.

    formspec_version = 4, 
    -- Required: cannot be lower than 2 (due to real_coordinates)  Corresponds to `formspec_version[]`
    
    -- Paddings are all optional.
    -- Form (aka Layout) Paddings will push all elements inwards from the corresponding edge.
    paddings = 3,
     -- sets all four default paddings to 3
    paddings = { hor = 4, ver = 2 }
     -- sets before/after paddings to 4 and above/below paddings to 2
    paddings = { before = 3, after = 3, above = 3, below = 4 }
    -- sets the paddings on each side correspondingly

    pos_x = 0.5, pos_y = 0.5, 
    -- Optional: the position on the screen (0-1). Corresponds to `position[]` formspec element
    
    anchor_x = 0.5, anchor_y = 0.5,
    -- Optional: the anchor for the on-screen position. Corresponds to `anchor[]`

    screen_padding_x = 0.05, screen_padding_y = 0.05,
    -- Optional: the padding required around the form, in screen proportion. Corresponds to `padding[]`
    
    no_prepend = false,
    -- Optional: disables player:set_formspec_prepend. Corresponds to `no_prepend[]`
    
    allow_close = true,
    -- Optional: if false, disable using closing formspec via esc or similar. Corresponds to `allow_close[]`

    -- Background Color config: these 3 elements correspond to a `bgcolor[]` formspec element

    bgcolor = "#RRGGBB",
    -- Optional: the background color of the formspec, in a formspec `ColorString` format
    -- Usually requires `no_prepend = true` in order to have an effect

    fbgcolor = "#RRGGBB",
    -- Optional: Only if formspec_ve >= 3. The full-screen background color when showing the formspec, in a formspec `ColorString` format

    bgfullscreen = "false",
    -- Optional, if formspec_ver >= 3, otherwise must be present if `bgcolor` is present.
    -- string, can have one of these values:
    -- "false": Only the non-fullscreen background color is drawn. (default)
    -- "true": Only the fullscreen background color is drawn.
    -- "both": Only if formspec_ver >= 3. The non-fullscreen and the fullscreen background color are drawn.
    -- "neither": Only if formspec_ver >= 3. No background color is drawn.

    borderColor = "#RRGGBB",
    -- Optional. Specify the color of a 1px border to be drawn around the form
    -- Note that in order to render correctly, this also sets all box[] elements to noclip

    set_focus = "id",
    -- Corresponds to set_focus[id]. Set which element is focused when the form is opened.
    -- Only certain elements can be focused, see: https://github.com/luanti-org/luanti/blob/master/doc/lua_api.md#set_focusnameforce

    reshowOnInteract = false,
    -- Optional. Default is `true`
    -- When `true` (default), the form will always be re-shown to the user after they
    -- interact with an element that triggers a callback
    -- When `false`, each individual element is required to `return true` from its 
    -- individual interaction function in order to reshow the form to the user.

    -- Default margins. Optional. All 3 versions do the same thing, but allow shorthands
    -- If present, the default margins will be used for any element that doesn't specify a corresponding margin

    defaultElementMargins = 3,
     -- sets all four default margins to 3
    defaultElementMargins = { hor = 4, ver = 2 }
     -- sets before/after margins to 4 and above/below ,margins to 2
    defaultElementMargins = { before = 3, after = 3, above = 3, below = 4 }
     -- sets the default margins to given values
 }
```
## `builderFunction`
The `builderFunction` param can be either:
- A simple table
- A function `function(state)` which gets passed the Form's `state`, and must return a table
 
In both cases, the table must be a list of `respec.elements` which will be shown on the form.

## Showing the Form
Forms can be shown by calling their `:show(playerName, state)` function, where:
- `playerName` is the player to whom you want to show the form.
- `state` is optional, and should be a lua table which will then get passed to the applicable functions, as listed above.<br>
  If omitted, the form functions will still get an empty table as their state

## Reshowing a Form
If for some reason you have a reference to a form (say `myForm`), and need to manually reshow it, you can do so by calling:
```lua
  myForm:reshow(playerName) -- playerName must be a string
```
This function won't do anything if the form isn't already shown to this player.

## Showing a Form for a Node's `on_rightclick`
If you need to show a form from a node's `on_rightclick` callback, the Form class provides a utility method to do so easily:

```lua
function Form:show_from_node_rightclick(extraState, checkProtection)
```
Parameters:
- `extraState`: optional. The data to be sent in the `state.extra` field - see table below
- `checkProtection`: optional. If true, the form will check `core.is_protected(pos)`, and only show the form to players who have access to the position

When you use this method, the `Form`'s `builderFunction` will automatically receive the following data in the `state` variable when a showing to the user:
```lua
  {
    pos = position,
    -- the pos param from the callback, is a vector with x,y,z coords
    
    node = nodeTable,
    -- the node table callback param

    nodeMeta = meta,
    -- the node's looked-up meta-data object, using core.get_meta(pos) function
    
    player = objectRef,
    -- the `clicker` callback param, the live object reference to a Player (checked to be a player)

    playerName = string,
    -- the name of the player who right-clicked
    
    itemstack = ItemStack,
    -- the callback param, ItemStack object that the user used to right-click on the node
    
    pointed_thing = pointed_thing,
    -- the pointed thing data passed by callback
    
    extra = extraState
    -- the optional `extraState` variable passed in `show_from_node_rightclick` - can be `nil`
  }
```
For further info on these params see Luanti's [Node definition](https://github.com/luanti-org/luanti/blob/master/doc/lua_api.md#node-definition) documentation.

Example:
```lua
  local myForm = respec.Form(...) -- create a new form
  core.register_node("mymod:mynode", {
    -- other defs here
    on_rightclick = myForm:show_from_node_rightclick(nil, true)
     -- form will be shown when user right-clicks this node, but only if the user has protection access
  })
```

## Example
Creating and immediately showing a formspec to `singleplayer`:
 ```lua
  respec.Form({
      formspec_version = 5,
      margins = 0.25,
    },
    {
      respec.elements.Label { w = 3, h = 0.5, text = "Hello World!" },
    }
  ):show("singleplayer")
 end
 ```

# Layout

A layout is the element that positions all other elements. Internally each Form creates its own Layout by default, which doesn't need to be managed or configured.

Layouts themselves are Physical Elements, and can be created by calling `respec.Layout(physicalElementSpec)`

Nested layouts are planned, but not yet supported.

# Elements

An element simply corresponds to a formspec element.
Elements come in two categories: Physical and Non-Physical.

## List of Non-physical Elements

Non-Physical elements are just elements that aren't displayed, but instead perform some sort of configuration.
These elements each have their own custom specifications, see below for each.

### Listring
Corresponds to the `listring` formspec element.

Created via:
```lua
  respec.elements.ListRing(spec)
```
`spec` is an optional parameter that may be omitted/nil to simply create a `listring[]`

Spec:
```lua
{
  {"inventory_location1", "list_name1"},
  {"inventory_location2", "list_name2"},
  -- Can be repeated - specifies inv locations to add to this listring.
  -- Each entry will create, in the order they're specified, a separate `listring[inv_location, list_name]` formspec element
}
```

# Physical Element

A Physical Element is a type of element that can be displayed, positioned, and resized in some way.

## Physical Element Common Spec
This spec is common between all physical elements, and each Physical Element has its own additional data that can be added to its spec. (see `List of Physical Elements` below)

```lua
{
  id = "string", 
  -- Optional. Can be used by other elements to align to this one. IDs within the same Layout must be unique.
  
  width = 3, w = 3,
  -- Usually required. If not specified, 0 is assumed.
  -- number, in real units, how wide this element is. Pass 0 to let start/end constraints determine width
  -- Can specify either "width" or "w" value for shorthand
  
  height = 3, h = 3,
  -- Usually required. If not specified, 0 is assumed.
  -- number, in real units, how tall this element is. Pass 0 to let top/bottom constraints determine width
  -- Can specify either "height" or "h" value for shorthand

  visibility = respec.const.visible,
  -- Optional. Default value is `visible`
  -- can be one of respec.consts.[visible/invisible/gone]
  -- Visible elements take up space and are drawn in the formspec.
  -- Invisible elements take up space, but are not drawn in the formspec.
  -- Gone elements don't take up space, nor are they drawn in the formspec.

  visible = true -- or false : accepts booleans instead of constants
  -- Optional. Can be used instead of specifying `visibility`
  -- Same as specifying visibility = VISIBLE or visibility = GONE
  
-- Margins: All margins are optional. Default value is 0 for all of them.
-- Any combination of the below are acceptable.
-- Negative margins may not work as expected
-- If multiple are present, then more specific margins override the more general ones

  margins = 4, -- sets all margins to 4
  margins_hor = 5, -- sets both start and end margins to 5
  margins_ver = 3, -- sets both top and bottom margins to 3
  margin_start = 1, -- sets start margin to 1
  margin_end = 1, -- sets the end margin to 1
  margin_top = 1, -- sets the top margin to 1
  margin_bottom = 1, -- sets the bottom margin to 1

-- Alignment: All alignments are optional.
-- If no vertical alignment specified, top_to_parent_top is assumed.
-- If no horizontal alignment is specified, start_to_parent_start is assumed.
-- When height or width are 0, then both the corresponding alignments should be specified instead to determine size.
-- You should not specify multiple alignments - e.g. aligning top to multiple elements.
-- If multiple conflicting alignments are present, only one will be used.
-- Alignment isn't affected by the other element's margins
-- Aligning to elements which have visibility = gone is allowed, and the alignment
-- will instead inherit the gone element's alignment

  center_hor = true,
  -- shorthand for specifying both start_to_parent_start and end_to_parent_end

  center_ver = true,
  -- shorthand for specifying both top_to_parent_top and bottom_to_parent_bottom

  center_hor = "other_id",
  -- shorthand for specifying both start_to_start_of="other_id" and end_to_end_of="other_id"

  center_ver = "other_id",
  -- shorthand for specifying both top_to_top_of="other_id" and bottom_to_bottom_of="other_id"

  top_to_top_of = "other_id",
  -- aligns the top of this element to the top of another element with the provided "other_id"

  top_to_bottom_of = "other_id",
  -- aligns the top of this element to the bottom of another element with the provided "other_id"

  top_to_parent_top = true,
  -- when set to `true`, aligns the top of the element to the parent Layout's top

  bottom_to_top_of = "other_id",
  -- aligns the bottom of this element to the top of another element with the provided "other_id"

  bottom_to_bottom_of = "other_id",
  -- aligns the bottom of this element to the bottom of another element with the provided "other_id"

  bottom_to_parent_bottom = true,
  -- whenever set to `true`, aligns the bottom of the element to the parent Layout's bottom

  start_to_start_of = "other_id",
  -- aligns the start of this element to the start of another element with the provided "other_id"

  start_to_end_of = "other_id",
  -- aligns the start of this element to the end of another element with the provided "other_id"

  start_to_parent_start = true,
  -- when set to `true, aligns the start of the element to the parent Layout's start

  end_to_start_of = "other_id",
  -- aligns the end of this element to the start of another element with the provided "other_id"

  end_to_end_of = "other_id",
  -- aligns the end of this element to the end of another element with the provided "other_id"

  end_to_parent_end = true,
  -- when set to `true, aligns the end of the element to the parent Layout's end

  -- Shorthand align flags
  -- The above flags are more technically correct, but they are more quite verbose.
  -- The following flags do the same as the above, but are easier to write:
    alignTop = "other_id",    -- shorthand for top_to_top_of
    alignBottom = "other_id", -- shorthand for bottom_to_bottom_of
    alignStart = "other_id",  -- shorthand for start_to_start_of
    alignEnd = "other_id",    -- shorthand for end_to_end_of
    below = "other_id",       -- shorthand for top_to_bottom_of
    above = "other_id",       -- shorthand for bottom_to_top_of
    before = "other_id",      -- shorthand for end_to_start_of
    after = "other_id"        -- shorthand for start_to_end_of
    toTop = true,             -- shorthand for top_to_parent_top
    toBottom = true,          -- shorthand for bottom_to_parent_bottom
    toStart = true,           -- shorthand for start_to_parent_start
    toEnd = true,             -- shorthand for end_to_parent_end

-- Biases: all are optional. 
-- When applicable, they shift how far along the element is positioned between its start and end points.
--
-- For example: an element with start_to_parent_start and end_to_parent_end and hor_bias of 0.5 (the default) will be placed in the center:
-- |    [ELEMENT]      |
-- Setting hor_bias to 0 will place the element to its alignment's start:
-- |[ELEMENT]          |
-- Setting hor_bias to 1 will place the element to its alignment's end:
-- |          [ELEMENT]|
--
-- Biases apply only when both corresponding side constraints are specified and the corresponding size is fixed (not 0)

  hor_bias = 0.5,
  -- the horizontal bias, defaults to 0.5 if not specified. Requires a start and end constraint to be set
  ver_bias = 0.5,
  -- the vertical bias, default to 0.5 if not specified. Requires a top and bottom constraint to be set.

  borderColor = "#RRGGBB",
  -- Optional. Specify the color of a 1px border to be drawn around the element (not including margins)
  -- This doesn't use the formspec style[] element, it is manually done on top of whatever style[] you set. This is here primarily because not all elements support an outline in style[]
}

```
### Notes on Visibility
When an element is `visible` or `invisible` it will take up space for the purposes of other elements aligning to it.

When an element is set to `gone` (aka `visible = false`) then any other element aligning to it will try to inherit the alignment of the `gone` element as best as it can. This means that a series elements where each aligns to the one before it should still work if an element in the series is set to `visible = false`.

## List of Physical Elements

All Physical Elements take a `spec` table as input.
This `spec` table may contain any of the common physical elements spec above, alongside element-specific specifications listed below.

### Label
Corresponds to formspec `label`

Created via:
```lua
  respec.elements.Label(spec)
```

Spec:
```lua
{
  text = "Label text here",
  -- string to be shown in label
  area = true,
  -- if set to `true` then make this an area label, which constraints its text to the size.
  -- For more info see: https://github.com/luanti-org/luanti/blob/master/doc/lua_api.md#labelxywhlabel
}
```

### Button
Corresponds to formspec `button`

Created via:
```lua
  respec.elements.Button(spec)
```

Spec:
```lua
{
  text = "Button text",
  -- string to be shown in Button
  
  on_click = function(state, fields) return true end,
  -- a function to be called when the button is clicked
  -- `state` is the form's state, can be modified here.
  -- `fields` is the value of the fields in the form
  -- Note that only fields with specified IDs will be present
  -- if reshowOnInteract is false, then return `true` from this function to re-show the formspec
}
```
### Checkbox
Corresponds to formspec `checkbox`

Created via:
```lua
  respec.elements.Checkbox(spec)
```

Spec:
```lua
  text = "Chexbox text",
  -- string to be shown (to the right of the checkbox)

  on_click = function(state, fields) return true end
  -- a function to be called when the checkbox is clicked
  -- `state` is the form's state, can be modified here
  -- `fields` is the value of the fields in the form
  -- Note that only fields with specified IDs will be present
  -- if reshowOnInteract is false, then return `true` from this function to re-show the formspec
```
