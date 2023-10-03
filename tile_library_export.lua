-- Export a 400 x 300 sprite with a tilemap
-- of 8 x 12 tiles into a 1,250 byte file,
-- with a single uint_8 value for each tile.

-- Verify that a file is open, and it has the correct dimensions.
local sprite = app.activeSprite
if not sprite then
  app.alert("No active sprite selected.")
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

-- Verify that the color mode is ColorMode.INDEXED
if not sprite.colorMode == ColorMode.INDEXED then
  app.alert("Color mode is not indexed.")
end

-- Find the active cel.
local cel = app.activeCel
if cel == nil then
  app.alert("No cel selected.")
  return
end

local palette = sprite.palettes[1]

-- Check that the tiles appear, exactly once,
-- until each has appeared in the tilemap.
-- Blank tiles are ignored.
local nextIndex = 1
for pixel in app.activeCel.image:pixels() do
  if pixel() == 0 then
    goto continue
  end
  if pixel() == nextIndex then
    nextIndex = nextIndex + 1
  else
    app.alert("Out of sequence value: " .. nextIndex)
    app.alert("Pixel: " .. pixel())
    return
  end
  -- Check to see if all of the tiles have been seen
  if nextIndex == #layer.tileset then
    break
  end

  ::continue::
end

-- Present a dialog to the user to get the file path
-- and their ActiveWhite / ActiveBlack choice.

local dialog = Dialog("Export tile library as a .dat File")
dialog:label{id="lab1",label="",text="Export tile library as a .dat file."}
 :file{id = "path", label="Export Path", filename="",open=false,filetypes={"dat"}, save=true, focus=true}
 :separator{}
 :button{id="ok",text="&OK",focus=true}
 :button{text="&Cancel" }
 :show()

-- Return early if they pressed cancel.
if not dialog.data.ok then return end

-- Open a handler for the output file.
local libraryFile = io.open(dialog.data.path,"wb")

-- Write 12 bytes of 0s to the output file
-- for the blank tile
for _ = 1,12 do
  libraryFile:write(string.pack("B", 0))
end

-- Iterate through the tiles, and write the data for
-- each one 
for tileId = 1,(#layer.tileset - 1) do
  for row = 0,11 do
    local rowByte = 0

    for col = 0,7 do
      local colorIndex = layer.tileset:tile(tileId).image:getPixel(col,row)
      -- If this pixel is white, add a bit to this row's byte
      local pixelColor = palette:getColor(colorIndex)
      if (pixelColor.red == 255) and (pixelColor.green == 255) and (pixelColor.blue == 255) then
        rowByte = rowByte | (1 << (7 - col))
      end
    end
    libraryFile:write(string.pack("B", rowByte))
  end
end

-- Pad the end of the file with 0s to give the file
-- a total size of 4kB
for _ = 1,(256 - #layer.tileset) do
  for _ = 1,12 do
    libraryFile:write(string.pack("B", 0))
  end
end

-- Close the file handler.
libraryFile:close()

app.alert("Tile library exported to " .. dialog.data.path)