local ai = require "pente_ai"
local pente = require "pente"

function love.load()
    love.window.setTitle("PlayPente")
    love.window.setMode(
        pente.margin * 2 + pente.cellSize * (pente.boardSize - 1),
        pente.margin * 2 + pente.cellSize * (pente.boardSize - 1)
    )
    pente.init()
end

function love.update()
end

local function drawBoard()
    for i = 0, pente.boardSize - 1 do
        local pos = pente.margin + i * pente.cellSize
        love.graphics.line(pente.margin, pos, pente.margin + pente.cellSize * (pente.boardSize - 1), pos)
        love.graphics.line(pos, pente.margin, pos, pente.margin + pente.cellSize * (pente.boardSize - 1))
    end
    
    local stars = {4, 10, 16}
    for _, y in ipairs(stars) do
        for _, x in ipairs(stars) do
            love.graphics.circle(
                "fill",
                pente.margin + (x - 1) * pente.cellSize,
                pente.margin + (y - 1) * pente.cellSize,
                4
            )
        end
    end
end

function love.draw()
    love.graphics.clear(0.85, 0.7, 0.45)
    love.graphics.setColor(0, 0, 0)
    drawBoard()
    
    local stones = pente.stones
    for y = 1, pente.boardSize do
        for x = 1, pente.boardSize do
            if stones[y][x] ~= 0 then
                if stones[y][x] == 1 then
                    love.graphics.setColor(0, 0, 0)
                else
                    love.graphics.setColor(1, 1, 1)
                end
                love.graphics.circle(
                    "fill",
                    pente.margin + (x - 1) * pente.cellSize,
                    pente.margin + (y - 1) * pente.cellSize,
                    pente.cellSize * 0.42
                )
                if stones[y][x] == 2 then
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.circle(
                        "line",
                        pente.margin + (x - 1) * pente.cellSize,
                        pente.margin + (y - 1) * pente.cellSize,
                        pente.cellSize * 0.42
                    )
                end
            end
        end
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Black Captures: " .. pente.blackCaptures() .. " / 15", 40, 10)
    love.graphics.print("White Captures: " .. pente.whiteCaptures() .. " / 15", 550, 10)
    
    if pente.gameOver() then
        local text = pente.winner() == 1 and "Black Wins!" or "White Wins!"
        love.graphics.printf(text, 0, 20, love.graphics.getWidth(), "center")
    end
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end
    if pente.gameOver() then return end
    
    local gx = math.floor((mx - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1
    local gy = math.floor((my - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1
    
    if gx < 1 or gx > pente.boardSize or gy < 1 or gy > pente.boardSize then return end
    
    if pente.makeMove(gx, gy, pente.currentPlayer()) then
        if not pente.gameOver() then
            local aiX, aiY = ai.findBestMove(pente.stones, 2)
            pente.makeMove(aiX, aiY, 2)
        end
    end
end