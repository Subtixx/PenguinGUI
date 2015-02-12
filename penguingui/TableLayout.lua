--- Lua port of the Java TableLayout library

TableLayout = class()

local table = table
local bit32 = bit32
local math = math
local _ENV = TableLayout

local NULL = {}

CENTER = bit32.lshift(1, 0)
TOP = bit32.lshift(1, 1)
BOTTOM = bit32.lshift(1, 2)
LEFT = bit32.lshift(1, 3)
RIGHT = bit32.lshift(1, 4)

Debug = {
  NONE = 0,
  ALL = 1,
  TABLE = 2,
  CELL = 3,
  WIDGET
}

function _init(self, toolkit)
  self.toolkit = nil
  self.tableWidget = nil
  self.columns = 0
  self.rows = 0
  
  self.cells = {}
  self.cellDefaults = nil
  self.columnDefaults = {}
  self.rowDefaults = nil

  self.sizeInvalid = true
  self.columnMinWidth = {}
  self.rowMinHeight = {}
  self.columnPrefWidth = {}
  self.rowPrefHeight = {}
  self.tableMinWidth = 0
  self.tableMinHeight = 0
  self.tablePrefWidth = 0
  self.tablePrefHeight = 0
  self.columnWidth = {}
  self.rowHeight = {}
  self.expandWidth = {}
  self.expandHeight = {}
  self.columnWeightedWidth = {}
  self.rowWeightedHeight = {}

  self.padTop = nil
  self.padLeft = nil
  self.padBottom = nil
  self.padRight = nil
  self.align = CENTER
  self.debug = Debug.NONE 
  
  self.toolkit = toolkit
  self.cellDefaults = toolkit:obtainCell(self)
  self.cellDefaults:defaults()
end

function invalidate(self)
  self.sizeInvalid = true
end

function invalidateHierarchy(self)
  -- TODO implementation
end

function add(self, widget)
  local cells = self.cells
  local cell = self.toolkit:obtainCell(self)
  cell.widget = widget

  if #cells > 0 then
    -- Set cell column and row
    local lastCell = cells[#cells]
    if not lastCell.endRow then
      cell.column = lastCell.column + lastCell.colspan
      cell.row = lastCell.row
    else
      cell.column = 1
      cell.row = lastCell.row + 1
    end
    -- Set index of cell above
    if cell.row > 1 then
      for i=#cells,1,-1 do
        local other = cells[i]
        local column = other.column
        local nn = column + other.colspan
        while column < nn do
          if column == cell.column then
            cell.cellAboveIndex = i
            goto outer
          end
          column = column + 1
        end
      end
      ::outer::
    end
  else
    cell.column = 1
    cell.row = 1
  end
  table.insert(cells, cell)

  cell:set(self.cellDefaults)
  if cell.column <= #self.columnDefaults then
    local columnCell = self.columnDefaults[cell.column]
    if columnCell ~= NULL then
      cell:merge(columnCell)
    end
  end
  cell:merge(self.rowDefaults)

  if widget ~= nil then
    self.toolkit:addChild(self.tableWidget, widget)
  end

  return cell
end

--- Indicates that subsequent cells should be added to a new row and returns the
-- cell values that will be used as the defaults for all cells in the new row.
function row(self)
  if #cells > 0 then
    self:endRow()
  end
  if self.rowDefaults ~= nil then
    self.toolkit:freeCell(self.rowDefaults)
  end
  self.rowDefaults = toolkit:obtainCell(self)
  self.rowDefaults:clear()
  return self.rowDefaults
end

function endRow(self)
  local cells = self.cells
  local rowColumns = 0
  for i=#cells,1,-1 do
    local cell = cells[i]
    if cell.endRow then
      break
    end
    rowColumns = rowColumns + cell.colspan
  end
  self.columns = math.max(self.columns, rowColumns)
  self.rows = self.rows + 1
  cells[#cells].endRow = true
  self:invalidate()
end

function columnDefaults(self, column)
  local cell = #self.columnDefaults >= column and
    self.columnDefaults[column] or nil
  if cell == nil then
    cell = self.toolkit:obtainCell(self)
    cell:clear()
    if column > #self.columnDefaults then
      for i=#self.columnDefaults,column-2,1 do
        table.insert(self.columnDefaults, NULL)
      end
      table.insert(self.columnDefaults, cell)
    else
      self.columnDefaults[column] = cell
    end
  end
  return cell
end

function reset(self)
  self:clear()
  self.padTop = nil
  self.padLeft = nil
  self.padBottom = nil
  self.padRight = nil
  self.align = CENTER
  if self.debug ~= Debug.NONE then
    self.toolkit:clearDebugRectangles(self)
  end
  self.debug = Debug.NONE
  self.cellDefaults:defaults()
  local i = 1
  local n = #self.columnDefaults
  while i <= n do
    local columnCell = self.columnDefaults[i]
    if columnCell ~= NULL then
      self.toolkit:freeCell(columnCell)
    end
    i = i + 1
  end
  self:columnDefaults = {}
end

function clear(self)
  for i=#self.cells,1,-1 do
    local cell = self.cells[i]
    local widget = cell.widget
    if widget ~= nil then
      self.toolkit:removeChild(self.tableWidget, widget)
    end
    self.toolkit:freeCell(cell)
  end
  self.cells = {}
  self.rows = 0
  self.columns = 0
  if self.rowDefaults ~= nil then
    self.toolkit:freeCell(self.rowDefaults)
  end
  self.rowDefaults = nil
  self:invalidate()
end

function getCell(self, widget)
  local n = #self.cells
  for i=1,n,1 do
    local c = self.cells[i]
    if c.widget == widget then
      return c
    end
  end
  return nil
end

function getMinWidth(self)
  if self.sizeInvalid then
    self:computeSize()
  end
  return self.tableMinWidth
end

function getMinHeight(self)
  if self.sizeInvalid then
    self:computeSize()
  end
  return self.tableMinHeight
end

function getPrefWidth(self)
  if self.sizeInvalid then
    self:computeSize()
  end
  return self.tablePrefWidth
end

function getPrefHeight(self)
  if self.sizeInvalid then
    self:computeSize()
  end
  return self.tablePrefHeight
end

function defaults(self)
  return self.cellDefaults
end

function pad(self, pad)
  self.padTop = pad
  self.padLeft = pad
  self.padBottom = pad
  self.padRight = pad
  self.sizeInvalid = true
  return self
end

function pad(self, top, left, bottom, right)
  self.padTop = top
  self.padLeft = left
  self.padBottom = bottom
  self.padRight = right
  self.sizeInvalid = true
  return self
end

function setPadTop(self, padTop)
  self.padTop = padTop
  self.sizeInvalid = true
  return self
end

function setPadLeft(self, padLeft)
  self.padLeft = padLeft
  self.sizeInvalid = true
  return self
end

function setPadBottom(self, padBottom)
  self.padBottom = padBottom
  self.sizeInvalid = true
  return self
end

function setPadRight(self, padRight)
  self.padRight = padRight
  self.sizeInvalid = true
  return self
end

function setAlign(self, align)
  self.align = align
  return self
end

function center(self)
  self.align = CENTER
  return self
end

function top(self)
  self.align = bit32.bor(self.align, TOP)
  self.align = bit32.band(self.align, bit32.bnot(BOTTOM))
  return self
end

function left(self)
  self.align = bit32.bor(self.align, LEFT)
  self.align = bit32.band(self.align, bit32.bnot(RIGHT))
  return self
end

function bottom(self)
  self.align = bit32.bor(self.align, BOTTOM)
  self.align = bit32.band(self.align, bit32.bnot(TOP))
  return self
end

function right(self)
  self.align = bit32.bor(self.align, RIGHT)
  self.align = bit32.band(self.align, bit32.bnot(LEFT))
  return self
end

function debugAll(self)
  self.debug = Debug.ALL
  self:invalidate()
  return self
end

function debugTable(self)
  self.debug = Debug.TABLE
  self:invalidate()
  return self
end

function debugCell(self)
  self.debug = Debug.CELL
  self:invalidate()
  return self
end

function debugWidget(self)
  self.debug = Debug.WIDGET
  self:invalidate()
  return self
end

function setDebug(self, debug)
  self.debug = debug
  if debug == Debug.NONE then
    self.toolkit:clearDebugRectangles(self)
  else
    self:invalidate()
  end
  return self
end

function getRow(self, y)
  local row = 0
  y = y + self.padTop
  local i = 1
  local n = #self.cells
  if n == 0 then
    return -1
  end
  if n == 1 then
    return 1
  end
  -- Using y-up coordinate system
  while i <= n do
    local c = self.cells[i]
    i = i + 1
    if c:getIgnore() then
      -- continue
    else
      if c.widgetY + c.computedPadTop < y then
        break
      end
      if c.endRow then
        row = row + 1
      end
    end
  end
  return row
end

function ensureSize(array, size)
  if array == nil or #array < size then
    local out = {}
    for i=1,size,1 do
      out[i] = 0
    end
    return out
  end
  local n = #array
  for i=1,n,1 do
    array[i] = 0
  end
  return array
end

function computeSize(self)
  self.sizeInvalid = false

  local toolkit = self.toolkit
  local cells = self.cells

  if #cells > = and not cells[#cells].endRow then
    self:endRow()
  end

  local columnMinWidth = ensureSize(self.columnMinWidth, columns)
  self.columnMinWidth = columnMinWidth
  local rowMinHeight = ensureSize(self.rowMinHeight, rows)
  self.rowMinHeight = rowMinHeight
  local columnPrefWidth = ensureSize(self.columnPrefWidth, columns)
  self.columnPrefWidth = columnPrefWidth
  local rowPrefHeight = ensureSize(self.rowPrefHeight, rows)
  self.rowPrefHeight = rowPrefHeight
  local columnWidth = ensureSize(self.columnWidth, columns)
  self.columnWidth = columnWidth
  local rowHeight = ensureSize(self.rowHeight, rows)
  self.rowHeight = rowHeight
  local expandWidth = ensureSize(self.expandWidth, columns)
  self.expandWidth = expandWidth
  local expandHeight = ensureSize(self.expandHeight, rows)
  self.expandHeight = expandHeight

  local spaceRightLast = 0
  local n = #cells
  for i=1,n,1 do
    local c = cells[i]
    if c.ignore then
      goto continue
    end

    -- Collect columns/rows that expand.
    if c.expandY ~= 0 and expandHeight[c.row] == 0 then
      expandHeight[c.row] = c.expandY
    end
    if c.colspan == 1 and c.expandX ~= 0 and expandWidth[c.column] == 0 then
      expandWidth[c.column] = c.expandX
    end

    -- Compute combined padding/spacing for cells
    -- Spacing between widgets isn't additive, the larger is used.
    -- ALso, no spacing around edges.
    c.computedPadLeft = c.padLeft +
      (c.column == 1 and 0 or math.max(0, c.spaceLeft - spaceRightLast))
    c.computedPadTop = c.padTop
    if c.cellAboveIndex ~= -1 then
      local above = cells[c.cellAboveIndex]
      c.computedPadTop = c.computedPadTop +
        math.max(0, c.spaceTop - above.spaceBottom)
    end
    local spaceRight = c.spaceRight
    c.computedPadRight = c.padRight +
      ((c.column + c.colspan) == columns + 1 and 0 or spaceRight)
    c.computedPadBottom = c.padBottom + (c.row == rows and 0 or c.spaceBottom)
    spaceRightLast = spaceRight

    -- Determine minimum and preferred cell sizes.
    local prefWidth = c.prefWidth
    local prefHeight = c.prefHeight
    local minWidth = c.minWidth
    local minHeight = c.minHeight
    local maxWidth = c.maxWidth
    local maxHeight = c.maxHeight
    if prefWidth < minWidth then
      prefWidth = minWidth
    end
    
    ::continue::
  end
end
