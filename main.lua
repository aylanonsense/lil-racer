-- Constants
local GAME_WIDTH = 150
local GAME_HEIGHT = 150
local RENDER_SCALE = 4

-- Game objects
local car
local puffs

-- Images
local carImage
local raceTrackImage
local raceTrackData

-- Souned effects
local engine1Sound
local engine2Sound
local engine3Sound
local engine4Sound
local crashSound

-- Initializes the game
function love.load()
  -- Load images
  carImage = loadImage('img/car.png')
  raceTrackImage = loadImage('img/race-track.png')
  raceTrackData = love.image.newImageData('img/race-track-data.png')

  -- Load sound effects
  engine1Sound = love.audio.newSource('sfx/engine1.wav', 'static')
  engine2Sound = love.audio.newSource('sfx/engine2.wav', 'static')
  engine3Sound = love.audio.newSource('sfx/engine3.wav', 'static')
  engine4Sound = love.audio.newSource('sfx/engine4.wav', 'static')
  crashSound = love.audio.newSource('sfx/crash.wav', 'static')

  -- Create the game objects
  puffs = {}
  createCar()
end

-- Updates the game state
function love.update(dt)
  -- Spawn a puff of smoke every now and then
  car.puffTimer = car.puffTimer + dt
  if car.puffTimer > 1.25 - math.abs(car.speed) / 40 then
    car.puffTimer = 0.00
    createPuff(car.x, car.y)
  end

  -- Make some engine noises
  car.engineNoiseTimer = car.engineNoiseTimer + dt
  if car.engineNoiseTimer > 0.17 then
    car.engineNoiseTimer = 0.00
    local speed = math.abs(car.speed)
    if speed > 30 then
      love.audio.play(engine4Sound:clone())
    elseif speed > 20 then
      love.audio.play(engine3Sound:clone())
    elseif speed > 10 then
      love.audio.play(engine2Sound:clone())
    else
      love.audio.play(engine1Sound:clone())
    end
  end

  -- Press down to brake
  if love.keyboard.isDown('down') then
    car.speed = math.max(car.speed - 20 * dt, -10)
  -- Press up to accelerate
  elseif love.keyboard.isDown('up') then
    car.speed = math.min(car.speed + 50 * dt, 40)
  -- Slow down when not accelerating
  else
    car.speed = car.speed * 0.98
  end

  -- Turn the car
  local turnSpeed = 3 * math.min(math.max(0, math.abs(car.speed) / 20), 1) - (car.speed > 20 and (car.speed - 20) / 20 or 0)
  if love.keyboard.isDown('left') then
    car.rotation = car.rotation - turnSpeed * dt
  end
  if love.keyboard.isDown('right') then
    car.rotation = car.rotation + turnSpeed * dt
  end
  car.rotation = (car.rotation + 2 * math.pi) % (2 * math.pi)

  -- Apply the car's velocity
  car.x = car.x + car.speed * -math.sin(car.rotation) * dt + car.bounceVelocityX * dt
  car.y = car.y + car.speed * math.cos(car.rotation) * dt + car.bounceVelocityY * dt

  -- Update the puffs of smoke
  for i = #puffs, 1, -1 do
    local puff = puffs[i]
    puff.y = puff.y - 10 * dt
    puff.timeToDisappear = puff.timeToDisappear - dt
    if puff.timeToDisappear <= 0 then
      table.remove(puffs, i)
    end
  end

  -- Check what terrain the car is currently on by looking at the race track data image
  local r, g, b = raceTrackData:getPixel(math.min(math.max(0, math.floor(car.x)), 149), math.min(math.max(0, math.floor(car.y)), 149))
  local isInBarrier = r > 0 -- red means barriers
  local isInRoughTerrain = b > 0 -- blue means rough terrain

  -- If the car runs off the track, it slows down
  if isInRoughTerrain then
    car.speed = car.speed * 0.95
  end

  -- If the car becomes lodged in a barrier, bounce it away
  if isInBarrier then
    local vx = car.speed * -math.sin(car.rotation) + car.bounceVelocityX
    local vy = car.speed * math.cos(car.rotation) + car.bounceVelocityY
    car.bounceVelocityX = -2 * vx
    car.bounceVelocityY = -2 * vy
    car.speed = car.speed * 0.50
    love.audio.play(crashSound:clone())
  end
  car.bounceVelocityX = car.bounceVelocityX * 0.90
  car.bounceVelocityY = car.bounceVelocityY * 0.90

  -- If the car ever gets out of bound, reset the car
  if car.x < 0 or car.y < 0 or car.x > GAME_WIDTH or car.y > GAME_HEIGHT then
    createCar()
  end
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

  -- Draw the race track
  love.graphics.draw(raceTrackImage, 0, 0)

  -- Draw the car
  local radiansPerSprite = 2 * math.pi / 16
  local sprite = math.floor((car.rotation + radiansPerSprite / 2) / radiansPerSprite) + 1
  if car.rotation >= math.pi then
    sprite = 18 - sprite
  end
  drawSprite(carImage, sprite, 12, 12, car.rotation >= math.pi, car.x - 6, car.y - 6)

  -- Draw the puffs of smoke coming out of the car
  love.graphics.setColor(115 / 255, 105 / 255, 92 / 255, 1)
  for _, puff in ipairs(puffs) do
    love.graphics.rectangle('fill', puff.x - 1, puff.y - 1, 2, 2)
  end
end

-- Creates the playable car
function createCar()
  car = {
    x = 95,
    y = 28,
    bounceVelocityX = 0,
    bounceVelocityY = 0,
    speed = 0,
    rotation = math.pi / 2,
    engineNoiseTimer = 0.00,
    puffTimer = 0.00
  }
end

-- Creates a puff of smoke
function createPuff(x, y)
  table.insert(puffs, {
    x = x,
    y = y,
    timeToDisappear = 2.00
  })
end

-- Loads a pixelated image
function loadImage(filePath)
  local image = love.graphics.newImage(filePath)
  image:setFilter('nearest', 'nearest')
  return image
end

-- Draws a sprite from a sprite sheet image, spriteNum=1 is the upper-leftmost sprite
function drawSprite(image, spriteNum, spriteWidth, spriteHeight, flipHorizontally, x, y)
  local columns = math.floor(image:getWidth() / spriteWidth)
  local col = (spriteNum - 1) % columns
  local row = math.floor((spriteNum - 1) / columns)
  local quad = love.graphics.newQuad(spriteWidth * col, spriteHeight * row, spriteWidth, spriteHeight, image:getDimensions())
  love.graphics.draw(image, quad, x + (flipHorizontally and spriteWidth or 0), y, 0, flipHorizontally and -1 or 1, 1)
end
