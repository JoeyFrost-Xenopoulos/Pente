local ai = require "pente_ai"
local pente = require "pente"

function love.load()
    love.window.setTitle("PlayPente")
    local historyWidth = 200
    love.window.setMode(
        pente.margin + pente.cellSize * (pente.boardSize - 1) + pente.margin + historyWidth,
        pente.margin * 2 + pente.cellSize * (pente.boardSize - 1)
    )
    pente.init()
end

function love.update()
end

function love.keypressed(key)
    if key == "left" then
        pente.goBack()
    elseif key == "right" then
        pente.goForward()
    end
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

local function coordLabel(x, y)
    if not x then return "Start" end
    local col = x
    if col >= 9 then col = col + 1 end
    return string.char(64 + col) .. y
end

local function drawHistory()
    local history, hIdx = pente.getHistory()
    local boardRight = pente.margin + pente.cellSize * (pente.boardSize - 1)
    local panelX = boardRight + 30
    local panelY = 75
    local lineHeight = 16
    local panelW = 190
    
    local maxVisible = math.floor((love.graphics.getHeight() - panelY - 10) / lineHeight)
    
    if hIdx <= 1 then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", panelX - 5, panelY - 5, panelW, 20)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print("Start position", panelX, panelY)
        love.graphics.setColor(0, 0, 0)
        return
    end
    
    local lines = {}
    local moveNum = 1
    local i = 2
    while i <= hIdx do
        local snap = history[i]
        local blackMove = snap.moveX and coordLabel(snap.moveX, snap.moveY) or "???"
        
        local whiteMove = ""
        local lineEndIdx = i
        if i + 1 <= hIdx then
            local nextSnap = history[i + 1]
            if nextSnap.movePlayer == 2 then
                whiteMove = nextSnap.moveX and coordLabel(nextSnap.moveX, nextSnap.moveY) or "???"
                lineEndIdx = i + 1
            end
        end
        
        local lineText = moveNum .. ". " .. blackMove
        if whiteMove ~= "" then
            lineText = lineText .. "    " .. whiteMove
        end
        
        local isCurrent = (lineEndIdx == hIdx)
        
        table.insert(lines, {
            text = lineText,
            isCurrent = isCurrent
        })
        
        moveNum = moveNum + 1
        i = lineEndIdx + 1
    end
    
    local totalLines = #lines
    local visibleCount = math.min(totalLines, maxVisible)
    local startLine = totalLines - visibleCount + 1
    if startLine < 1 then startLine = 1 end
    
    local panelH = visibleCount * lineHeight + 8
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", panelX - 5, panelY - 5, panelW, panelH)
    love.graphics.setColor(0.9, 0.9, 0.9)
    
    for idx = startLine, totalLines do
        local line = lines[idx]
        local y = panelY + (idx - startLine) * lineHeight
        if line.isCurrent then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
        end
        love.graphics.print(line.text, panelX, y)
    end
    
    love.graphics.setColor(0, 0, 0)
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
    
    drawHistory()
    
    if pente.gameOver() then
        local text = pente.winner() == 1 and "Black Wins!" or "White Wins!"
        love.graphics.printf(text, 0, 20, love.graphics.getWidth(), "center")
    end
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end
    if pente.gameOver() then return end
    if not pente.isAtCurrentPosition() then return end
    
    local gx = math.floor((mx - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1
    local gy = math.floor((my - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1
    
    if gx < 1 or gx > pente.boardSize or gy < 1 or gy > pente.boardSize then return end
    
    local player = pente.currentPlayer()
    if pente.makeMove(gx, gy, player) then
        pente.pushHistory(gx, gy, player)
        if not pente.gameOver() then
            local aiX, aiY = ai.findBestMove(pente.stones, 2)
            if aiX and aiY then
                local aiPlayer = pente.currentPlayer()
                pente.makeMove(aiX, aiY, aiPlayer)
                pente.pushHistory(aiX, aiY, aiPlayer)
            end
        end
    end
end