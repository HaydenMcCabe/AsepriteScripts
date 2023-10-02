-- Export a 400 x 300 sprite with a tilemap
-- of 8 x 12 tiles into a 1,250 byte file,
-- with a single uint_8 value for each tile.

-- Verify that a file is open, and it has the correct dimensions.
local sprite = app.activeSprite
if not sprite then
  app.alert("No active sprite selected.")
  return
end
if not sprite.width == 400 or not sprite.height == 300 then
  app.alert("Image dimensions must be 400 x 300.")
  return
end

-- Verify that the selected layer is a tilemap, that the tilemap uses
-- 256 or fewer tiles, and the tiles are 8 x 12.
local layer = app.activeLayer
if not layer.isTilemap then
  app.alert("Selected layer is not tilemap.") 
  return
end
if #layer.tileset > 256 then
  app.alert("Tileset uses more than 256 tiles.")
  return
end
local tileWidth = layer.tileset:tile(1).image.bounds.width
local tileHeight = layer.tileset:tile(1).image.bounds.height
if not tileWidth == 8 or not tileHeight == 12 then
  app.alert("Tile size must be 8 x 12.")
  return
end

-- Find the active cel, and find its measurements
local cel = app.activeCel
if cel == nil then
  app.alert("No cel selected.")
  return
end

-- The selected cel is sized as the smallest rectangle
-- that contains all of the non-blank tiles from the
-- upper left corner.
local image = cel.image
-- Find the number of blank columns and rows
-- not used by the cel.
local blankColumns = 50 - image.bounds.width
local blankRows = 25 - image.bounds.height

-- Present a dialog to the user to find the output filename and
-- give them a chance to cancel.
local dialog = Dialog("Export Tilemap as .dat File")
dialog:label{id="lab1",label="",text="Export Tilemap as a .dat file."}
 :file{id = "path", label="Export Path", filename="",open=false,filetypes={"dat"}, save=true, focus=true}
 :separator{}
 :button{id="ok",text="&OK",focus=true}
 :button{text="&Cancel" }
 :show()

-- Return early if they pressed cancel.
if not dialog.data.ok then return end

-- Open a handler for the output file.
local mapFile = io.open(dialog.data.path,"wb")

-- Iterate through the pixels, adding in zeroes as
-- right padding for the missing columns.
local column = 0
for p in image:pixels() do
  -- Insert the uint_8 bits for the tile index
  mapFile:write(string.pack("B", p()))
  -- Iterate the column count, and insert
  -- blank columns and reset the column count
  -- as needed.
  column = column + 1
  if column == image.bounds.width then
    for _ = 1, blankColumns do
      mapFile:write(string.pack("B", 0))
    end
    column = 0
  end
end
-- Add the blank rows at the bottom
for _ = 1,(50 * blankRows) do
  mapFile:write(string.pack("B", 0))
end

-- Close the file handler.
mapFile:close()
