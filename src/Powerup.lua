Powerup = Class{}

local fallSpeed = 50

function Powerup:init(x, y, type)
	self.x = x
	self.y = y
	self.dy = fallSpeed

	self.width = 16
	self.height = 16
	self.type = type
end

function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function Powerup:update(dt)
	self.y = self.y + self.dy * dt

end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type],
        self.x, self.y)
end