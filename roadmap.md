# Roadmap to ReSpec 1.0

## Missing Features
- Event handling callbacks for all interactive elements
- Element Chains: same as constraint layout chains
  - packed/packed-inside/spread
- Nested Layouts
- Maybe implement custom Tab Headers / helpers

## Stretch goals
- `wrap_contents` width for certain elements:
  - using `core.get_player_window_information(player_name)` to scale on 5.7+ clients
  - label, button, button_url, vertlabel,
- Guidelines: same as constraint layout guidelines
  - Why? Because they're not really that hard to implement tbh.
  - Why not? Because Luanti formspecs aren't nearly as dynamic as Layouts on Android



## Supported Formspec Elements

Checked ones are done (or mostly done).

- [x] `formspec_version`
- [x] `size` : missing fixed_size param
- [x] `position`
- [x] `anchor`
- [x] `padding`
- [x] `no_prepend`
- [x] `allow_close`
- [x] `bgcolor`: To be added to Form specification

- [ ] `scroll_container`: to contain its own layout
- [ ] `list` : Needs special attention since w/h are specified in num slots, not size
- [ ] `listcolors` : probably leave it as standalone element since it can apply to multiple lists
- [ ] `tooltip` : gui_element_name ones should be build into each `PhysicalElement`
- [ ] `tooltip` : area tooltip as standalone element
- [ ] `image`
- [ ] `animated_image`
- [ ] `model`
- [ ] `item_image`
- [ ] `background` : standalone + possibly also incorporate it into each physical element
- [ ] `background9` : standalone + possibly also incorporate it into each physical element
- [ ] `pwdfield`
- [ ] `field`
- [ ] `field_enter_after_edit` : incorporate as flag in regular field
- [ ] `field_close_on_enter` : incorporate as flag in regular field
- [ ] `textarea`
- [x] `label`
- [ ] `hypertext`
- [ ] `vertlabel` : hmm maybe a flag on existing label? depends
- [x] `button`
- [ ] `button_url`
- [x] `set_focus` : Implemented as part of Form's specification
- [ ] `image_button` : optional params noclip, drawborder, pressed texture name
- [ ] `item_image_button`
- [ ] `button_exit` : incorporate as flag into regular button
- [ ] `button_url_exit` : incorporate as flag into regular button_url
- [ ] `image_button_exit` : incorporate as flag into regular image_button
- [ ] `textlist` : optional params selected idx, transparent
- [ ] `tabheader` : may support requiring height - maybe
- [ ] `box`
- [ ] `dropdown` : may require w+h
- [x] `checkbox` : Still needs wrap_content, if necessary
- [ ] `scrollbar`
- [ ] `scrollbaroptions` : nonphysical
- [ ] `table`
- [ ] `tableoptions` : maybe as param to table
- [ ] `tablecolumns` : maybe as special class only available in table
- [x] `style` : nonphysical. Incorporated into physical elements' spec.
- [x] `style_type` : nonphysical


## Explicitly Unsupported Formspec Elements
- `real_coordinates[<bool>]`
  Reason: This is the default past formspec v2, and the layout algorithm is build
  with this being always on in mind. Therefore, we always assume this is true, and
  don't support turning it off or lower formspec versions.

- `container[<X>,<Y>]`/`container_end[]`
  Reason: Because this library already performs laying out of elements.
  Similar effect can be achieved by using alignment and margins

- Size-less `field[]`
  Reason: Edge-case usage, and most of its usage is for trivial forms that
  don't require any complex laying out of elements

