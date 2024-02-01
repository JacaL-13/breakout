--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]] PlayState = Class {
    __includes = BaseState
}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]

local growScore = 500

function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {params.ball}
    self.level = params.level

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)

    self.powerupsLeft = params.powerupsLeft or 2

    self.bricksLeft = params.bricksLeft or #self.bricks

    self.powerups = {}

    self.lockedBricks = 0

	self.key = params.key or false

end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- spawn two additional balls at paddle position add them to self.balls and give them random velocities

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

                -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end

        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- check if score has passed a multiple of growScore and increase paddle size if it has
                local oldScore = math.floor(self.score / growScore)

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                if math.floor(self.score / growScore) > oldScore and self.paddle.size < 4 then
                    self.paddle.size = self.paddle.size + 1
                    self.paddle.width = self.paddle.size * 32
                    self.paddle.x = self.paddle.x - 16
                end

                -- trigger the brick's hit function, which removes it from play
                local brickDestroyed = brick:hit(self.key)

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                if brickDestroyed then
                    -- Look through bricks and count locked bricks
                    for k, brick in pairs(self.bricks) do
                        if brick.locked then
                            self.lockedBricks = self.lockedBricks + 1
                        end
                    end

                    print(self.lockedBricks)

                    local multiBallRoll = math.random(self.bricksLeft)

                    local keyRoll = math.random(self.bricksLeft - self.lockedBricks)

                    self.bricksLeft = self.bricksLeft - 1

                    -- go to our victory screen if there are no more bricks left
                    -- if self:checkVictory() then
                    if self.bricksLeft == 0 then
                        gSounds['victory']:play()

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            ball = self.balls[1],
                            recoverPoints = self.recoverPoints
                        })
                    else
                        if multiBallRoll <= self.powerupsLeft then
                            local newPowerUp = Powerup(brick.x + brick.width / 2, brick.y, 9)
                            table.insert(self.powerups, newPowerUp)

                            self.powerupsLeft = self.powerupsLeft - 1

                            self.nextPowerup = math.random(1, self.bricksLeft)
                        end
                        if keyRoll <= self.lockedBricks then
                            local newKey = Powerup(brick.x + brick.width / 2, brick.y, 10)
                            table.insert(self.powerups, newKey)
                        end
                    end
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8

                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32

                    -- top edge if no X collisions, always check
                elseif ball.y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8

                    -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end

        -- if ball other than the last goes below bounds, remove it from play
        if ball.y >= VIRTUAL_HEIGHT and #self.balls > 1 then
            table.remove(self.balls, k)
        end
    end

    -- detect collision across all bricks with the ball

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.balls[1].y >= VIRTUAL_HEIGHT then
        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
            self.paddle.width = self.paddle.size * 32
            self.paddle.x = self.paddle.x + 16
        end

        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                bricksLeft = self.bricksLeft,
                powerupsLeft = self.powerupsLeft,
                paddleSize = self.paddleSize,
				key = self.key
            })
        end
    end

    if #self.powerups > 0 then
        -- update all powerups
        for k, powerup in pairs(self.powerups) do
            powerup:update(dt)
        end

        if self.powerup:collides(self.paddle) then
            if self.powerup.type == 9 then
                -- spawn two additional balls at paddle position add them to self.balls and give them random velocities
                local ball1 = Ball(math.random(7))
                local ball2 = Ball(math.random(7))

                ball1.x = self.paddle.x + (self.paddle.width / 2) - 4
                ball1.y = self.paddle.y - 8
                ball1.dx = math.random(-200, 200)
                ball1.dy = math.random(-50, -60)

                ball2.x = self.paddle.x + (self.paddle.width / 2) - 4
                ball2.y = self.paddle.y - 8
                ball2.dx = math.random(-200, 200)
                ball2.dy = math.random(-50, -60)

                table.insert(self.balls, ball1)
                table.insert(self.balls, ball2)
            elseif self.powerup.type == 10 then
                self.key = true
            end

            self.powerup = nil
        elseif self.powerup.y >= VIRTUAL_HEIGHT then
            self.powerup = nil
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, ball in pairs(self.balls) do
        ball:render()
    end

    if self.powerup ~= nil then
        self.powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end
