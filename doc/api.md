TODO : document the API once it's settled

# Form


# Layout


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
