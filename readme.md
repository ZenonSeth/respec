This mod is in Beta. See [roadmap.md](https://github.com/ZenonSeth/respec/blob/main/roadmap.md)

# Respec
Respec, from "**Re**lative Form**spec**", is a formspec library for [Luanti](https://www.luanti.org).

Respec aims to support all features from the [Luanti Formspec API](https://github.com/luanti-org/luanti/blob/master/doc/lua_api.md#formspec) past formspec version 2, with [two minor exceptions](#specifically-unsupported-formspec-elements).

Respec provides:
- Easy and versatile method of positioning and sizing of elements
- Auto-sizing for some text elements
- Easy callbacks for interactive elements
- Quality-of-life features to decrease how much code has to be written

Respec's system of positioning and sizing of elements uses relative positioning, which is inspired by and strongly based on [Android's Constraint Layout](https://developer.android.com/develop/ui/views/layout/constraint-layout), with which Respec shares many similarities (e.g. chains).<br>
However knowledge of Android or Constraint Layout is not required.

## Getting Started
[Getting Started page on the Github Wiki](https://github.com/ZenonSeth/respec/wiki)

## API

The API docs can be found under [doc/api.md](https://github.com/ZenonSeth/respec/blob/main/doc/api.md).

## Specifically Unsupported Formspec Elements
- `real_coordinates[<bool>]`<br>
  **Reason**: This is set to `true` by default past formspec v2, and Respec's layout algorithm is build
  with the assumption that this is always enabled. There is also no functional difference in what can be achieved with formspecs by not supporting this element, so Respec assumes real coordinates are always on, and turning them off is not supported.

- Size-less `field[]`<br>
  **Reason**: This element only has an edge-case usage for trivial forms that don't require any laying out of elements. Note that regular `field[]` elements and all their functionalities are fully supported.
