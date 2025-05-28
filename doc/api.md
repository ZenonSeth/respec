Note: This is still work in progress - docs are missing and existing api may change in the near future.

# Form
To create a form use the `respec.Form(spec, builder)` function.

`spec` must be a table in the following format:
 ```lua
 {
    w = 8, h = 9, 
    -- Optional: the width and height of the formspec. Corresponds to `size[]`
    -- Special values: respec.const.wrap_content to simply make the form big enough for all the elements it contains
    -- if either w/h is unset, wrap_content is assumed for the missing value.

    formspec_version = 4, 
    -- Required: cannot be lower than 2 (due to real_coordinates)  Corresponds to `formspec_version[]`
    
    -- Margins are all optional, and combination may be used.
    -- Form margins will push all elements inwards from the corresponding edge.
    margins = 4, -- sets margins on all sides to this value
    margins_hor = 3, -- sets horizontal (start/end) margins to this value
    margins_ver = 3, -- sets vertical (top/bottom) margins to this value
    margin_top = 2, -- set the top margin to this value
    margin_bottom = 2, -- set the bottom margin to this value
    margin_start = 2, -- set the start margin to this value
    margin_end = 2, -- set the end margin to this value

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
 }
```

The `layoutBuilder` param must be function used to create the form's layout.
 It simply gets passed a `data` object which can be used to maintain information between re-showing the form. 
 
 The function must return a list of elements (created via `respec.elements`)

 For example:
 ```lua
 function(data)
  return {
    respec.elements.Label(labelSpec),
    respec.elements.Button(buttonSpec),
  }
 end
 ```


# Layout

A layout is the element that positions all other elements. Internally each Form creates its own Layout by default, which doesn't need to be managed or configured.

Nested layouts are planned, but not yet supported.

# Elements

An element simply corresponds to a formspec element.
Elements come in two categories: Physical and Non-Physical.

Non-Physical elements are just elements that aren't displayed, but instead perform some sort of configuration.
These elements each have their own custom specifications, see below for each.

## List of Non-physical Elements

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
  {"inventory_location", "list_name"},
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
}
```
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
  -- See formspec doc for more info
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
  
  on_click = function(state) return true end,
  -- a function to be called when the button is clicked
  -- `state` is the data object that gets passed to the `spec_builder` in the form, which can be modified by this function to affect what's shown
  -- return `true` to re-show the formspec to the user
}
```
