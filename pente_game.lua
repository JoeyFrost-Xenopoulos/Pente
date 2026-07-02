local pente = require "pente"
local ai = require "pente_ai"
local historyScrollY = 0
local gameState = "selectColor"
local userColor = 1

function love.load()
    love.window.setTitle("PlayPente")
    local historyWidth = 200
    love.window.setMode(
        pente.margin + pente.cellSize * (pente.boardSize - 1) + pente.margin + historyWidth,
        pente.margin * 2 + pente.cellSize * (pente.boardSize - 1)
    )
    pente.init()
    gameState = "selectColor"
    userColor = 1
end

function love.update()
    if gameState == "playing" and pente.gameOver() then
        gameState = "gameOver"
    end
end

function love.keypressed(key)
    if gameState ~= "playing" and gameState ~= "gameOver" then return end

    if key == "left" then
        pente.goBack()
    elseif key == "right" then
        pente.goForward()
    elseif key == "r" and pente.gameOver() then
        pente.init()
        gameState = "selectColor"
        historyScrollY = 0
    end
end

function love.wheelmoved(x, y)
    if gameState ~= "playing" and gameState ~= "gameOver" then return end
    historyScrollY = historyScrollY + y
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
        love.graphics.print("Start position", panelX, panelY - 2)
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

        local lineText = string.format("%d. %-6s    %s", moveNum, blackMove, whiteMove)

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
    local maxScrollY = totalLines - visibleCount
    if maxScrollY < 0 then maxScrollY = 0 end
    historyScrollY = math.min(historyScrollY, maxScrollY)

    local startLine = totalLines - visibleCount - historyScrollY + 1
    if startLine < 1 then startLine = 1 end
    if startLine > totalLines then startLine = totalLines end

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

    if totalLines > visibleCount then
        local trackX = panelX + panelW - 5
        local trackWidth = 3
        local trackY = panelY - 5
        local trackHeight = panelH

        local thumbHeight = math.max(20, (visibleCount / totalLines) * trackHeight)
        local thumbY = trackY
        if maxScrollY > 0 then
            thumbY = trackY + (historyScrollY / maxScrollY) * (trackHeight - thumbHeight)
        end

        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", trackX, trackY, trackWidth, trackHeight)
        love.graphics.setColor(0.7, 0.7, 0.7, 0.9)
        love.graphics.rectangle("fill", trackX, thumbY, trackWidth, thumbHeight)
    end

    love.graphics.setColor(0, 0, 0)
end

local function drawColorSelection()
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    local buttonW, buttonH = 120, 60
    local gap = 20

    local blackX = cx - buttonW - gap/2
    local blackY = cy - buttonH/2
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", blackX, blackY, buttonW, buttonH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Play as Black", blackX, blackY + 20, buttonW, "center")

    local whiteX = cx + gap/2
    local whiteY = cy - buttonH/2
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", whiteX, whiteY, buttonW, buttonH)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Play as White", whiteX, whiteY + 20, buttonW, "center")
end

function love.draw()
    love.graphics.clear(1, 1, 1)
    love.graphics.setColor(0.85, 0.7, 0.45)
    local boardRight = pente.margin + pente.cellSize * (pente.boardSize - 1)
    local boardBottom = pente.margin + pente.cellSize * (pente.boardSize - 1)
    love.graphics.rectangle("fill", pente.margin, pente.margin, boardRight - pente.margin, boardBottom - pente.margin)
    love.graphics.setColor(0, 0, 0)
    drawBoard()

    if gameState == "selectColor" then
        drawColorSelection()
        return
    end

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
    love.graphics.print("White Captures: " .. pente.whiteCaptures() .. " / 15", 530, 10)

    drawHistory()

    if pente.gameOver() then
        local text = pente.winner() == 1 and "Black Wins!" or "White Wins!"
        love.graphics.printf(text, -100, 20, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to play again", 305, 50, love.graphics.getWidth(), "center")
    end
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end

    if gameState == "selectColor" then
        local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
        local buttonW, buttonH = 120, 60
        local gap = 20

        local blackX = cx - buttonW - gap/2
        local blackY = cy - buttonH/2
        if mx >= blackX and mx <= blackX + buttonW and my >= blackY and my <= blackY + buttonH then
            userColor = 1
            gameState = "playing"
            return
        end

        local whiteX = cx + gap/2
        local whiteY = cy - buttonH/2
        if mx >= whiteX and mx <= whiteX + buttonW and my >= whiteY and my <= whiteY + buttonH then
            userColor = 2
            gameState = "playing"
            local aiPlayer = 1
            local aiX, aiY = ai.findBestMove(pente.stones, aiPlayer)
            if aiX and aiY then
                pente.makeMove(aiX, aiY, aiPlayer)
                pente.pushHistory(aiX, aiY, aiPlayer)
            end
            return
        end
        return
    end

    if gameState ~= "playing" then return end
    if pente.gameOver() then return end
    if not pente.isAtCurrentPosition() then return end

    local gx = math.floor((mx - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1
    local gy = math.floor((my - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1

    if gx < 1 or gx > pente.boardSize or gy < 1 or gy > pente.boardSize then return end

    if pente.currentPlayer() ~= userColor then return end

    local player = userColor
    if pente.makeMove(gx, gy, player) then
        pente.pushHistory(gx, gy, player)
        if not pente.gameOver() then
            local aiPlayer = 3 - userColor
            local aiX, aiY = ai.findBestMove(pente.stones, aiPlayer)
            if aiX and aiY then
                pente.makeMove(aiX, aiY, aiPlayer)
                pente.pushHistory(aiX, aiY, aiPlayer)
            end
        end
        historyScrollY = 0
    end
end
