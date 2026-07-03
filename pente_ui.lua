local pente = require "pente"
local help = require "pente_help"

local ui = {
    historyScrollY = 0,
    gameState = "selectColor",
    userColor = 1,
    helpVisible = false
}

local function coordLabel(x, y)
    if not x then return "Start" end
    local col = x
    if col >= 9 then col = col + 1 end
    return string.char(64 + col) .. y
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
    ui.historyScrollY = math.min(ui.historyScrollY, maxScrollY)

    local startLine = totalLines - visibleCount - ui.historyScrollY + 1
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
            thumbY = trackY + (ui.historyScrollY / maxScrollY) * (trackHeight - thumbHeight)
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

local function drawHelp()
    help.drawHelp()
end

local function drawStones()
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
end

local function drawHelpButton()
    local w = love.graphics.getWidth()

    local r = 11
    local margin = 16

    local x = w - margin - r
    local y = margin + r

    local mx, my = love.mouse.getPosition()
    local dx, dy = mx - x, my - y
    local hovered = (dx * dx + dy * dy <= r * r)

    -- button body
    if hovered then
        love.graphics.setColor(0.25, 0.25, 0.3)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end

    love.graphics.circle("fill", x, y, r)

    -- border highlight (subtle polish)
    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.circle("line", x, y, r)

    -- question mark (proper centering)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("?", x - 10, y - 8, 20, "center")
end

local function drawGameState()
    local w = love.graphics.getWidth()
    local cx, cy = w - 20, 20
    local r = 12

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Black Captures: " .. pente.blackCaptures() .. " / 15", 40, 10)
    love.graphics.print("White Captures: " .. pente.whiteCaptures() .. " / 15", 530, 10)

    drawHelpButton()
    drawHistory()

    if pente.gameOver() then
        local text = pente.winner() == 1 and "Black Wins!" or "White Wins!"
        love.graphics.printf(text, -100, 20, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to play again", 305, 50, love.graphics.getWidth(), "center")
    end
end

local function handleGameStateHelpClick(mx, my)
    return help.handleGameStateHelpClick(mx, my)
end

local function handleHelpCloseClick(mx, my)
    return help.handleHelpCloseClick(mx, my)
end

local function handleColorSelectionClick(mx, my)
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    local buttonW, buttonH = 120, 60
    local gap = 20

    local blackX = cx - buttonW - gap/2
    local blackY = cy - buttonH/2
    if mx >= blackX and mx <= blackX + buttonW and my >= blackY and my <= blackY + buttonH then
        return "black"
    end

    local whiteX = cx + gap/2
    local whiteY = cy - buttonH/2
    if mx >= whiteX and mx <= whiteX + buttonW and my >= whiteY and my <= whiteY + buttonH then
        return "white"
    end

    return nil
end

local function getGameState()
    return ui.gameState
end

local function setGameState(state)
    ui.gameState = state
end

local function getUserColor()
    return ui.userColor
end

local function setUserColor(color)
    ui.userColor = color
end

local function isHelpVisible()
    return ui.helpVisible
end

local function setHelpVisible(visible)
    ui.helpVisible = visible
end

local function getHistoryScrollY()
    return ui.historyScrollY
end

local function setHistoryScrollY(y)
    ui.historyScrollY = y
end

local function resetHistoryScroll()
    ui.historyScrollY = 0
end

return {
    coordLabel = coordLabel,
    drawBoard = drawBoard,
    drawHistory = drawHistory,
    drawColorSelection = drawColorSelection,
    drawHelp = drawHelp,
    drawStones = drawStones,
    drawGameState = drawGameState,
    handleGameStateHelpClick = handleGameStateHelpClick,
    handleHelpCloseClick = handleHelpCloseClick,
    handleColorSelectionClick = handleColorSelectionClick,
    getGameState = getGameState,
    setGameState = setGameState,
    getUserColor = getUserColor,
    setUserColor = setUserColor,
    isHelpVisible = isHelpVisible,
    setHelpVisible = setHelpVisible,
    getHistoryScrollY = getHistoryScrollY,
    setHistoryScrollY = setHistoryScrollY,
    resetHistoryScroll = resetHistoryScroll
}