-- Constants
local GAME_WIDTH = 128
local GAME_HEIGHT = 128
local RENDER_SCALE = 3

-- Game objects
local player

-- Initializes the game
function love.load()
  -- Create the playable car
  createPlayer()
end

-- Updates the game state
function love.update(dt)
  -- Apply the player car's velocity to her position
  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt
end

-- Renders the game
function love.draw()
  -- Set some drawing filters
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.graphics.scale(RENDER_SCALE, RENDER_SCALE)

  -- Clear the screen
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle('fill', 0, 0, GAME_WIDTH, GAME_HEIGHT)
  love.graphics.setColor(1, 1, 1, 1)
end

-- Creates the playable car
function createPlayer(x, y)
  player = {
    x = x,
    y = y,
    vx = 0,
    vy = 0
  }
end

-- Loads a pixelated image
function loadImage(filePath)
  local image = love.graphics.newImage(filePath)
  image:setFilter('nearest', 'nearest')
  return image
end

-- Draws a 16x16 sprite from an image, spriteNum=1 is the upper-leftmost sprite
function drawImage(image, spriteNum, flipHorizontally, x, y)
  local columns = math.floor(image:getWidth() / 16)
  local col = (spriteNum - 1) % columns
  local row = math.floor((spriteNum - 1) / columns)
  local quad = love.graphics.newQuad(16 * col, 16 * row, 16, 16, image:getDimensions())
  love.graphics.draw(image, quad, x + (flipHorizontally and 16 or 0), y, 0, flipHorizontally and -1 or 1, 1)
end
