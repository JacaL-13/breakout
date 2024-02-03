--[[
    GD50
    Breakout Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state the game is in when we've just started; should
    simply display "Breakout" in large text, as well as a message to press
    Enter to begin.
]] -- the "__includes" bit here means we're going to inherit all of the methods
-- that BaseState has, so it will have empty versions of all StateMachine methods
-- even if we don't override them ourselves; handy to avoid superfluous code!
StartState = Class {
    __includes = BaseState
}

-- whether we're highlighting "Start" or "High Scores"
local highlighted = 1

function StartState:enter(params)
    self.highScores = params.highScores
end

function StartState:update(dt)
    -- toggle highlighted option if we press an arrow key up or down
    if love.keyboard.wasPressed('down') then
        highlighted = highlighted < 3 and highlighted + 1 or 1
        gSounds['paddle-hit']:play()
    elseif love.keyboard.wasPressed('up') then
        highlighted = highlighted > 1 and highlighted - 1 or 3
        gSounds['paddle-hit']:play()
    end

    -- confirm whichever option we have selected to change screens
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gSounds['confirm']:play()

        if highlighted == 1 then
            gStateMachine:change('paddle-select', {
                highScores = self.highScores
            })
        elseif highlighted == 2 then
            gStateMachine:change('high-scores', {
                highScores = self.highScores
            })
        else
            humanPlayer = false

            gStateMachine:change('paddle-select', {
                highScores = self.highScores
            })
        end
    end

    -- we no longer have this globally, so include here
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function StartState:render()
    -- title
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf("BREAKOUT", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, 'center')

    -- instructions
    love.graphics.setFont(gFonts['medium'])

    -- if we're highlighting 1, render that option blue
    if highlighted == 1 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    end
    love.graphics.printf("START", 0, VIRTUAL_HEIGHT / 2 + 60, VIRTUAL_WIDTH, 'center')

    -- reset the color
    love.graphics.setColor(1, 1, 1, 1)

    -- render option 2 blue if we're highlighting that one
    if highlighted == 2 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    end
    love.graphics.printf("HIGH SCORES", 0, VIRTUAL_HEIGHT / 2 + 80, VIRTUAL_WIDTH, 'center')

	-- reset the color
	love.graphics.setColor(1, 1, 1, 1)

    -- render option 3 blue if we're highlighting that one
    if highlighted == 3 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    end
    love.graphics.printf("AI MODE", 0, VIRTUAL_HEIGHT / 2 + 100, VIRTUAL_WIDTH, 'center')

    -- reset the color
    love.graphics.setColor(1, 1, 1, 1)
end
