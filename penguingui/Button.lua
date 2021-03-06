--- A clickable button.
-- @classmod Button
-- @usage -- Create an empty button that prints when it is clicked
-- local button = Button(0, 0, 100, 100)
-- button.onClick = function(component, button)
--   print("Clicked with mouse button " .. button)
-- end
Button = class(Component)
--- The color of the outer border of this button.
Button.outerBorderColor = {0, 0, 0}
--- The color of the inner border of this button.
Button.innerBorderColor = {84, 84, 84}
--- The color of the inner border of this button when the mouse is over it.
Button.innerBorderHoverColor = {147, 147, 147}
--- The color of this button.
Button.color = {38, 38, 38}
--- The color of this button when the mouse is over it.
Button.hoverColor = {84, 84, 84}

--- Constructor
-- @section

--- Constructs a new Button.
--
-- @param x The x coordinate of the new component, relative to its parent.
-- @param y The y coordinate of the new component, relative to its parent.
-- @param width The width of the new component.
-- @param height The height of the new component.
function Button:_init(x, y, width, height)
  Component._init(self)
  self.mouseOver = false

  self.x = x
  self.y = y
  self.width = width
  self.height = height
end

--- @section end

function Button:update(dt)
  if self.pressed and not self.mouseOver then
    self:setPressed(false)
  end
end

function Button:draw(dt)
  local startX = self.x + self.offset[1]
  local startY = self.y + self.offset[2]
  local w = self.width
  local h = self.height
  
  local borderPoly = {
    {startX + 1, startY + 0.5},
    {startX + w - 1, startY + 0.5},
    {startX + w - 0.5, startY + 1},
    {startX + w - 0.5, startY + h - 1},
    {startX + w - 1, startY + h - 0.5},
    {startX + 1, startY + h - 0.5},
    {startX + 0.5, startY + h - 1},
    {startX + 0.5, startY + 1},
  }
  local innerBorderRect = {
    startX + 1, startY + 1, startX + w - 1, startY + h - 1
  }
  local rectOffset = 1.5
  local rect = {
    startX + rectOffset, startY + rectOffset, startX + w - rectOffset, startY + h - rectOffset
  }

  PtUtil.drawPoly(borderPoly, self.outerBorderColor, 1)
  if self.mouseOver then
    PtUtil.drawRect(innerBorderRect, self.innerBorderHoverColor, 0.5)
    PtUtil.fillRect(rect, self.hoverColor)
  else
    PtUtil.drawRect(innerBorderRect, self.innerBorderColor, 0.5)
    PtUtil.fillRect(rect, self.color)
  end
end

function Button:setPressed(pressed)
  if pressed and not self.pressed then
    self.x = self.x + 1
    self.y = self.y - 1
    self.layout = true
  end
  if not pressed and self.pressed then
    self.x = self.x - 1
    self.y = self.y + 1
    self.layout = true
  end
  self.pressed = pressed
end

function Button:clickEvent(position, button, pressed)
  if button <= 3 then
    if self.onClick and not pressed and self.pressed then
      self:onClick(button)
    end
    self:setPressed(pressed)
    return true
  end 
end

--- Called when this button is clicked.
-- @function onClick
--
-- @param button The mouse button that was used.
