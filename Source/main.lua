import "CoreLibs/graphics"
import "mode7"

playdate.display.setRefreshRate(0)

-- Set the pool size
mode7.pool.realloc(5000 * 1000)

function newWorld()
    -- Clear the pool before loading a new PGM
    mode7.pool.clear()

    local configuration = mode7.world.defaultConfiguration()
    configuration.width = 2048
    configuration.height = 2048
    configuration.depth = 2048

    local world = mode7.world.new(configuration)

    local bitmap = mode7.bitmap.loadPGM("images/track-0.pgm")
    world:setPlaneBitmap(bitmap)
    
    world:setPlaneFillColor(mode7.color.grayscale.new(60, 255))

    -- apples.pdt is generated via running `python resize.py -i apples -max 160 -min 8 -step 4`
    -- 
    local appleTable = mode7.imagetable.new("images/apples")
    
    addApple(world, appleTable, 246, 1106, 1.5)
    addApple(world, appleTable, 195, 1134, 1.5)

    local display = world:getMainDisplay()
    local camera = display:getCamera()

    local backgroundImage = mode7.image.new("images/background")
    display:getBackground():setImage(backgroundImage)

    camera:setPosition(220, 1200, 12)
    camera:setAngle(math.rad(-90))
    
    return world
end

function addApple(world, imageTable, x, y, z)
    local apple = mode7.sprite.new(16, 16, 3)
    apple:setPosition(x, y, z)
    apple:setImageTable(imageTable)
    apple:setImageCenter(0.5, 0.3)
    apple:setAngle(math.rad(-90))
    apple:setAlignment(mode7.sprite.kAlignmentOdd, mode7.sprite.kAlignmentOdd)
    
    local dataSource = apple:getDataSource()

    -- RPDev says 
    -- scale should be 39, the calc is (max - min) / step + 1. Rotation is 18 based on your spritesheet
    -- This causes the apples to only be visible from one side and then when you get close, the apples start getting big then small then big then small
    -- Example in /gifs/gif_1
    -- dataSource:setMinimumWidth(8)
    -- dataSource:setMaximumWidth(160)
    -- dataSource:setLengthForKey(39, mode7.sprite.datasource.kScale)
    -- dataSource:setLengthForKey(18, mode7.sprite.datasource.kAngle)

    -- This one is the closest to what I would expect, but it still is not right. The angles don't render and the sprite disappears when the camera gets close
    -- Example in /gifs/gif_2
    dataSource:setMinimumWidth(8)
    dataSource:setMaximumWidth(64) -- I changed this to 64 and it looks better. Random!!
    dataSource:setLengthForKey(14, mode7.sprite.datasource.kScale) -- 14 is a random number that just happened to look good
    -- dataSource:setLengthForKey(18, mode7.sprite.datasource.kAngle)


    world:addSprite(apple)

    return apple
end

function updateCamera(dt)
    local display = world:getMainDisplay()
    local camera = display:getCamera()

	local angle = camera:getAngle()
    local posX, posY, posZ = camera:getPosition()
    
    local angleDelta = 1 * dt

    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        angle = angle - angleDelta
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        angle = angle + angleDelta
	end
    
    local moveDelta = 100 * dt
    local moveVelocity = 0
    
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        moveVelocity = moveDelta
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        moveVelocity = -moveDelta
	end
    
    local heightDelta = 60 * dt
    local height = posZ

    if playdate.buttonIsPressed(playdate.kButtonA) then
        height = height + heightDelta
    elseif playdate.buttonIsPressed(playdate.kButtonB) then
        height = height - heightDelta
	end

    camera:setAngle(angle)

	local crankChange = playdate.getCrankChange()
    camera:setPitch(camera:getPitch() + crankChange * 0.005)

	local cameraX = posX + moveVelocity * math.cos(angle)
    local cameraY = posY + moveVelocity * math.sin(angle)

	camera:setPosition(cameraX, cameraY, height)
end

world = newWorld()

local menu = playdate.getSystemMenu()
local menuItem, error = menu:addMenuItem("Restart", function()
    world = newWorld()
end)

function playdate.update()
	local dt = playdate.getElapsedTime()
	playdate.resetElapsedTime()

    updateCamera(dt)

    playdate.graphics.clear()

    world:update()
    
    world:draw()

	playdate.drawFPS(0, 0)
end

