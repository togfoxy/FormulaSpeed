# cam11 camera library

## Introduction

This is a simple, low-level camera library that makes use of the
[Transform](https://love2d.org/wiki/Transform) object introduced in Löve
(love2d) version 11.0.

It is intended as either a simple camera for games that don't need more, or as
a basis for a more sophisticated camera handling library.

It does not provide any clamping, usually needed for games where the map should
completely cover the viewport even when reaching a border.

It was designed with speed in mind. While camera setup is usually something
that does not require speed, as it's typically performed only once per frame,
operations like transforming points to screen or world coordinates can
potentially be used many times.

This library uses a lazy approach, meaning it does not perform any unnecessary
updates of the transformation. For this to work as expected, it's important
not to access the fields directly unless you understand the consequences, and
use the accessor methods instead.

## Definitions

Here we use the term "screen" to refer to the drawing area, i.e. the drawable
area within the window, which in fullscreen mode, matches the whole physical
screen, but in general it does not necessarily do so.

This camera library is made to draw in a viewport. The viewport is any
rectangular area of the screen, or it can cover the whole screen, which is the
default. This viewport is always defined in screen coordinates. You can choose
whether to apply clipping to the viewport (using the Löve scissor) when
attaching the camera; by default, it only clips when the viewport is not set to
cover the whole screen.

There seems to be some confusion when defining coordinate systems.

When working with a map, we're using coordinates relative to an origin in the
map. For example, a 4096x4096 map can use an origin located at the top left
corner of the map, and then a point like (2000, 1000) will be 2000 units
(pixels, usually) to the east, and 1000 units to the south of that point. This
point (2000, 1000) is said to be in *world coordinates*. The term "world" is
used instead of "map" because it is more general: what you're drawing might not
be a map, but it's usually a world of some kind. The `love.physics` module, for
example, uses the same term. If you're drawing a map, the terms "world
coordinates" and "map coordinates" are equivalent.

When drawing e.g. a map to the screen using the camera, one point of the map
located, say, at coordinate (2000, 1000), does not necessarily end up in the
screen at the same coordinate. For example, if the camera is centred on that
point in an 800x600 screen using a full screen viewport, the final positon on
the screen of that point will be (400, 300). This (400, 300) is relative to the
origin of the screen, which is the top left corner. The points that use the
top left corner of the screen as origin, and use the display units, are said to
be expressed in *screen coordinates*. Löve uses this coordinate system, for
example, for reporting the mouse and touch position, for the scissor functions,
and for drawing immediately at the start of `love.draw()` or after using
`love.graphics.origin()`. This camera library uses these coordinates for
defining the viewport.

Some libraries use the term "camera coordinates". We find that term confusing,
because the camera deals with both types of coordinates, therefore we avoid it
and use only screen coordinates, for the coordinates of points of the screen,
and world coordinates, for the coordinates of the world before it is drawn
through the camera.

The library includes functions for converting coordinates from screen to world
and vice versa. A typical use is to determine the position in the world of the
mouse, because the mouse position is reported in screen coordinates, and it's
often necessary to determine where in the world the click happened.

## Usage example

This is an **incomplete** example which invokes some made up functions you
could be using in your program, and that aren't defined in this snippet:

```
local cam

function love.load()
  cam = require 'cam11'()
  cam:setZoom(2)
end

function love.update(dt)
  player:update(dt)
  cam:setPos(player:getPos())
end

function love.mousepressed(x, y, b)
  local xw, yw = cam:toWorld(x, y)
  map:mousepressed(xw, yw, b)
end

function love.draw()
  cam:attach()
  map:draw()
  player:draw()
  cam:detach()
end
```

## Reference

`local Camera = require 'cam11'`: Returns the Camera class.

`local cam = Camera.new([x], [y], [zoom], [angle], [viewport_x], [viewport_y], [viewport_w], [viewport_h], [focus_x], [focus_y])`:
Create a new camera instance object at the given position, zoom and angle,
using the given viewport. Remember that it's a class method, therefore the dot
syntax must be used, instead of the colon syntax.

`x` and `y` are the position the camera must point to, in world coordinates.
Both default to 0.

`zoom` is the magnification factor. For example, a value of 3 means to magnify
the drawing 3X. The default is 1.

`angle` is the rotation angle, in radians, relative to the focus point.
Following LÖVE's axis conventions, positive values mean clockwise rotation. The
default is 0.

`viewport_x` and `viewport_y` are the coordinates of the top left corner of the
viewport where the camera will be rendered, in screen coordinates. The default
is 0 for both.

`viewport_w` and `viewport_h` are the viewport's width and height. A value of
`false` (the default) or `nil` means to use the current screen width or height
for the corresponding parameter. Note that when using the current width or
height, the current transformation must be invalidated when the screen size
changes, by calling `cam:setDirty()` (described below), such that when it's
needed, it's regenerated with the new width and height. This invalidation can
be done in the `love.resize` and `love.displayrotated` (for 11.3+) events.

The `focus_x` and `focus_y` parameters are the fraction of the viewport's width
and height, respectively, that the camera should point to. Both default to 0.5,
meaning the centre of the viewport.

`local cam = Camera(...)`: Alternative C++-like syntax for `Camera.new(...)`.

The following are methods of the instance, described using `cam` as the name of
the instance:

`cam:setDirty([dirty])`: A value of `true` (default) invalidates the
transformation, meaning it will be regenerated the next time it's needed.
A value of `false` means the transformation will not be regenerated the next
time it's needed, which can potentially lead to invalid results based on an
obsolete transformation. Don't set it to `false` unless you understand the
consequences.

`cam:attach([clip])`: Replaces the LÖVE transformation with the current camera
parameters, remembering the old transformation in order to restore it later.
`cam:attach()` must have one corresponding `cam:detach()`. Always call
`cam:detach()` before calling `cam:attach()` again.

The optional `clip` parameter specifies whether to use the LÖVE scissor to clip
to the viewport. A value of `false` indicates not to clip; otherwise it clips.
The default is to clip unless the viewport is set to follow the screen width
and height. The clipping intersects the current scissor, rather than replace
it, to be GUI-friendly. If clipping was performed, the scissor will be restored
when calling `cam:detach()`.

`cam:detach()`: Restores the LÖVE transformation that was active since the
latest `cam:attach()`, and if clipping was performed, also restores the scissor
that was active. You must call `cam:attach()` before calling this function.

`cam:setPos(x, y)`: Changes the current *x* and *y* coordinates that the camera
must point to.

`cam:setZoom(zoom)`: Changes the current zoom of the camera.

`cam:setAngle(angle)`: Changes the current angle of the camera.

`cam:setViewport([x], [y], [w], [h], [fx], [fy])`: Changes the current
viewport's left and top coordinates, width, height, fraction of focus point
horizontal and vertical, respectively. See `Camera.new()` for details.

`cam:toScreen(x, y)`: Transforms world coordinates to screen coordinates,
returning the result.

`cam:toWorld(x, y)`: Transforms screen coordinates to world coordinates,
returning the result.

`cam:getTransform()`: Returns the current internal `Transform` object.

`cam:getPos()`: Returns the current *x* and *y* coordinates the camera is set
to point at, in world coordinates.

`cam:getX()`: Like above, but it returns only the *x* coordinate.

`cam:getY()`: Like above, but it returns only the *y* coordinate.

`cam:getZoom()`: Returns the current zoom value.

`cam:getAngle()`: Returns the angle that the camera is set to, in radians.

`cam:getViewport()`: Returns the x, y, width, height, focus X fraction, focus Y
fraction of the current viewport.

`cam:getVPTopLeft()`: Returns the top left coordinate, in screen coordinates,
of the current viewport. Equivalent to *x* and *y* of `cam:getViewport()`.

`cam:getVPBottomRight()`: Returns the bottom right coordinate, in screen
coordinates, of the current viewport.

`cam:getVPFocusPoint()`: Returns the focus point of the camera, in screen
coordinates.

Note that in order to obtain the current viewport rectangle in world
coordinates, or the axis-aligned bounding rectangle that encloses it, you can
use the functions below, as follows:

```
-- Return left, top, right bottom of the bounding rectangle of the rotated
-- viewport, in world coordinates
local min = math.min
local max = math.max

local function getVPRect(cam)
  local left, top = cam:getVPTopLeft()
  local right, bottom = cam:getVPBottomRight()
  local x1, y1 = cam:toWorld(left, top)
  local x2, y2 = cam:toWorld(right, top)
  local x3, y3 = cam:toWorld(right, bottom)
  local x4, y4 = cam:toWorld(left, bottom)
  return x1, y1, x2, y2, x3, y3, x4, y4
end

local function getBoundingVPRect(cam)
  local x1, y1, x2, y2, x3, y3, x4, y4 = getVPRect(cam)
  return min(min(x1, x2), min(x3, x4)), min(min(y1, y2), min(y3, y4)),
         max(max(x1, x2), max(x3, x4)), max(max(y1, y2), max(y3, y4))
end
```

## Feedback

Have you found a problem? Please let me know so I can fix it! It helps me a lot
if you report any issues you find. You're getting this library for free, after
all, so why not pay me back this way? That's what keeps the free software world
rolling: mutual help.

https://notabug.org/pgimeno/cam11/issues

Have any feedback? You can post in the love2d forums:

https://love2d.org/forums/viewtopic.php?f=5&t=8766

## License

This library is distributed under the following license terms:

Copyright © 2019 Pedro Gimeno Fortea

You can do whatever you want with this software, under the sole condition
that this notice and any copyright notices are preserved. It is offered
with no warrany, not even implied.
