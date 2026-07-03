local pente = require "pente"
local ai = require "pente_ai"
local ui = require "pente_ui"
local help = require "pente_help"

function love.load()
    love.window.setTitle("PlayPente")
    local historyWidth = 200
    love.window.setMode(
        pente.margin + pente.cellSize * (pente.boardSize - 1) + pente.margin + historyWidth,
        pente.margin * 2 + pente.cellSize * (pente.boardSize - 1)
    )
    pente.init()
    ui.setGameState("selectColor")
    ui.setUserColor(1)
end

function love.update()
    if ui.getGameState() == "playing" and pente.gameOver() then
        ui.setGameState("gameOver")
    end
end

function love.keypressed(key)
    if key == "escape" then
        ui.setHelpVisible(false)
        return
    end
    if ui.getGameState() ~= "playing" and ui.getGameState() ~= "gameOver" then return end

    if key == "left" then
        pente.goBack()
    elseif key == "right" then
        pente.goForward()
    elseif key == "r" and pente.gameOver() then
        pente.init()
        ui.setGameState("selectColor")
        ui.resetHistoryScroll()
    end

    if ui.helpVisible then
        if key == "right" then help.nextPage() end
        if key == "left" then help.prevPage() end
    end
end

function love.wheelmoved(x, y)
    if ui.getGameState() ~= "playing" and ui.getGameState() ~= "gameOver" then return end
    ui.setHistoryScrollY(ui.getHistoryScrollY() + y)

    if ui.helpVisible then
        if y > 0 then help.prevPage() end
        if y < 0 then help.nextPage() end
    end
end

function love.draw()
    love.graphics.clear(1, 1, 1)
    love.graphics.setColor(0.85, 0.7, 0.45)
    local boardRight = pente.margin + pente.cellSize * (pente.boardSize - 1)
    local boardBottom = pente.margin + pente.cellSize * (pente.boardSize - 1)
    love.graphics.rectangle("fill", pente.margin, pente.margin, boardRight - pente.margin, boardBottom - pente.margin)
    love.graphics.setColor(0, 0, 0)
    ui.drawBoard()

    if ui.getGameState() == "selectColor" then
        ui.drawColorSelection()
        return
    end

    ui.drawStones()
    ui.drawGameState()

    if ui.isHelpVisible() then
        ui.drawHelp()
    end
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end

    if ui.isHelpVisible() then
    if help.handleHelpCloseClick(mx, my) then
        ui.setHelpVisible(false)
        return
    end

    if help.handleArrowClick(mx, my) then
        return
    end

    return
    end

    if ui.handleGameStateHelpClick(mx, my) then
        ui.setHelpVisible(true)
        return
    end

    if ui.getGameState() == "selectColor" then
        local choice = ui.handleColorSelectionClick(mx, my)
        if choice == "black" then
            ui.setUserColor(1)
            ui.setGameState("playing")
        elseif choice == "white" then
            ui.setUserColor(2)
            ui.setGameState("playing")
            local aiPlayer = 1
            local aiX, aiY = ai.findBestMove(pente.stones, aiPlayer)
            if aiX and aiY then
                pente.makeMove(aiX, aiY, aiPlayer)
                pente.pushHistory(aiX, aiY, aiPlayer)
            end
        end
        return
    end

    if ui.getGameState() ~= "playing" then return end
    if pente.gameOver() then return end
    if not pente.isAtCurrentPosition() then return end

    local gx = math.floor((mx - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1
    local gy = math.floor((my - pente.margin + pente.cellSize / 2) / pente.cellSize) + 1

    if gx < 1 or gx > pente.boardSize or gy < 1 or gy > pente.boardSize then return end

    if pente.currentPlayer() ~= ui.getUserColor() then return end

    local player = ui.getUserColor()
    if pente.makeMove(gx, gy, player) then
        pente.pushHistory(gx, gy, player)
        if not pente.gameOver() then
            local aiPlayer = 3 - ui.getUserColor()
            local aiX, aiY = ai.findBestMove(pente.stones, aiPlayer)
            if aiX and aiY then
                pente.makeMove(aiX, aiY, aiPlayer)
                pente.pushHistory(aiX, aiY, aiPlayer)
            end
        end
        ui.resetHistoryScroll()
    end
end