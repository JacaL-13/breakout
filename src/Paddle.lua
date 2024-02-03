--[[
    GD50
    Breakout Remake

    -- Paddle Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a paddle that can move left and right. Used in the main
    program to deflect the ball toward the bricks; if the ball passes
    the paddle, the player loses one heart. The Paddle can have a skin,
    which the player gets to choose upon starting the game.
]] Paddle = Class {}

--[[
    Our Paddle will initialize at the same spot every time, in the middle
    of the world horizontally, toward the bottom.
]]
function Paddle:init(skin, size)
    -- x is placed in the middle
    self.x = VIRTUAL_WIDTH / 2 - 32

    -- y is placed a little above the bottom edge of the screen
    self.y = VIRTUAL_HEIGHT - 32

    -- start us off with no velocity
    self.dx = 0

    -- set paddle dimensions based on size
    self.width = size * 32
    self.height = 16

    -- the skin only has the effect of changing our color, used to offset us
    -- into the gPaddleSkins table later
    self.skin = skin

    -- the variant is which of the four paddle sizes we currently are; 2
    -- is the starting size, as the smallest is too tough to start with
    self.size = size
end

function Paddle:update(dt, ballsnPowerups)
    if humanPlayer then
        -- keyboard input
        if love.keyboard.isDown('left') then
            self.dx = -PADDLE_SPEED
        elseif love.keyboard.isDown('right') then
            self.dx = PADDLE_SPEED
        else
            self.dx = 0
        end

    else
        -- ai input
        if ballsnPowerups ~= nil then

            -- loop through balls and get closest one
            local closest = nil

            for k, ball in pairs(ballsnPowerups) do
                ball.incoming = ball.dy > 0

                if ball.incoming then
                    if closest == nil then
                        closest = ball
                    else
                        if ball.y > closest.y and ball.y < self.y + self.height then
                            closest = ball
                        end
                    end
                end
            end

            if closest == nil then
                for k, ball in pairs(ballsnPowerups) do
                    if closest == nil then
                        closest = ball
                    else
                        if ball.y > closest.y then
                            closest = ball
                        end
                    end
                end
            end

            local intercept = 0

            if closest.dx == nil or closest.dx == 0 or not closest.incoming then
                intercept = closest.x
            else
                -- calculate trajectory of ball
                local trajectory = closest.dy / closest.dx

                -- calculate point where ball will intercept paddle's y
                local yIntercept = closest.y - (trajectory * closest.x)

                intercept = (self.y - 8 - yIntercept) / trajectory

                -- if intercept is off the screen recalculate intercept
                if intercept < 0 then
					-- if the number of screens the ball would have to travel to get to the paddle is even, then the ball will be on
					-- the same side of the screen as the paddle. Use modulo to get how far the ball will continue after all bounces
                    intercept =
                        math.floor(math.abs(intercept) / VIRTUAL_WIDTH) % 2 == 0 and -intercept % VIRTUAL_WIDTH or
                            intercept % VIRTUAL_WIDTH
                elseif intercept > VIRTUAL_WIDTH then
                    intercept =
                        math.floor(math.abs(intercept) / VIRTUAL_WIDTH) % 2 == 0 and intercept % VIRTUAL_WIDTH or
                            -intercept % VIRTUAL_WIDTH
                end
            end

            -- compensate for paddle width
            intercept = math.floor(intercept - self.width / 2)

            -- lower speed when close to target
            local distance = math.abs(intercept - self.x)

            if intercept < self.x then
                self.dx = math.max(-PADDLE_SPEED * distance / 10, -PADDLE_SPEED)
            elseif intercept > self.x then
                self.dx = math.min(PADDLE_SPEED * distance / 10, PADDLE_SPEED)
            else
                self.dx = 0
            end

        else
            self.dx = 0
        end
    end

    -- math.max here ensures that we're the greater of 0 or the player's
    -- current calculated Y position when pressing up so that we don't
    -- go into the negatives; the movement calculation is simply our
    -- previously-defined paddle speed scaled by dt
    if self.dx < 0 then
        self.x = math.max(0, self.x + self.dx * dt)
        -- similar to before, this time we use math.min to ensure we don't
        -- go any farther than the bottom of the screen minus the paddle's
        -- height (or else it will go partially below, since position is
        -- based on its top left corner)
    else
        self.x = math.min(VIRTUAL_WIDTH - self.width, self.x + self.dx * dt)
    end
end

function Paddle:collides(target)
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    return true
end

--[[
    Render the paddle by drawing the main texture, passing in the quad
    that corresponds to the proper skin and size.
]]
function Paddle:render()
    love.graphics.draw(gTextures['main'], gFrames['paddles'][self.size + 4 * (self.skin - 1)], self.x, self.y)
end
