local boardSize = 19
local cellSize = 35
local margin = 40

local stones = {}
local currentPlayer = 1
local blackCaptures = 0
local whiteCaptures = 0
local gameOver = false
local winner = nil
local history = {}
local historyIndex = 0

local function takeSnapshot(mx, my, mp)
    local stonesCopy = {}
    for y = 1, boardSize do
        stonesCopy[y] = {}
        for x = 1, boardSize do
            stonesCopy[y][x] = stones[y][x]
        end
    end
    
    return {
        stones = stonesCopy,
        currentPlayer = currentPlayer,
        blackCaptures = blackCaptures,
        whiteCaptures = whiteCaptures,
        gameOver = gameOver,
        winner = winner,
        moveX = mx,
        moveY = my,
        movePlayer = mp
    }
end

local function restoreSnapshot(snap)
    for y = 1, boardSize do
        for x = 1, boardSize do
            stones[y][x] = snap.stones[y][x]
        end
    end
    currentPlayer = snap.currentPlayer
    blackCaptures = snap.blackCaptures
    whiteCaptures = snap.whiteCaptures
    gameOver = snap.gameOver
    winner = snap.winner
end

local directions = {
    {1,0}, {0,1}, {1,1}, {1,-1},
    {-1,0}, {0,-1}, {-1,-1}, {-1,1}
}

local function inside(x, y)
    return x >= 1 and x <= boardSize and y >= 1 and y <= boardSize
end

local function checkCaptures(x, y, player)
    local enemy = 3 - player
    
    for _, d in ipairs(directions) do
        local dx, dy = d[1], d[2]
        local x1, y1 = x + dx, y + dy
        local x2, y2 = x + dx * 2, y + dy * 2
        local x3, y3 = x + dx * 3, y + dy * 3
        
        if inside(x3, y3) then
            if stones[y1][x1] == enemy and
               stones[y2][x2] == enemy and
               stones[y3][x3] == player then
                stones[y1][x1] = 0
                stones[y2][x2] = 0
                if player == 1 then
                    blackCaptures = blackCaptures + 1
                else
                    whiteCaptures = whiteCaptures + 1
                end
            end
        end
    end
end

local function countDirection(x, y, dx, dy, player)
    local count = 0
    x, y = x + dx, y + dy
    while inside(x, y) and stones[y][x] == player do
        count = count + 1
        x, y = x + dx, y + dy
    end
    return count
end

local function checkWin(x, y, player)
    local axes = {{1,0}, {0,1}, {1,1}, {1,-1}}
    
    for _, a in ipairs(axes) do
        local total = 1 + countDirection(x, y, a[1], a[2], player) +
                          countDirection(x, y, -a[1], -a[2], player)
        if total >= 5 then
            winner = player
            gameOver = true
            return
        end
    end
    
    if blackCaptures >= 15 then
        winner = 1
        gameOver = true
    elseif whiteCaptures >= 15 then
        winner = 2
        gameOver = true
    end
end

local function makeMove(x, y, player)
    if inside(x, y) and stones[y][x] == 0 then
        stones[y][x] = player
        checkCaptures(x, y, player)
        checkWin(x, y, player)
        if not gameOver then
            currentPlayer = 3 - currentPlayer
        end
        return true
    end
    return false
end

local function init()
    for y = 1, boardSize do
        stones[y] = {}
        for x = 1, boardSize do
            stones[y][x] = 0
        end
    end
    currentPlayer = 1
    blackCaptures = 0
    whiteCaptures = 0
    gameOver = false
    winner = nil
    
    history = {}
    historyIndex = 0
    table.insert(history, takeSnapshot(nil, nil, nil))
    historyIndex = 1
end

local function pushHistory(x, y, player)
    if historyIndex < #history then
        for i = historyIndex + 1, #history do
            history[i] = nil
        end
    end
    table.insert(history, takeSnapshot(x, y, player))
    historyIndex = #history
end

local function goBack()
    if historyIndex > 1 then
        historyIndex = historyIndex - 1
        restoreSnapshot(history[historyIndex])
    end
end

local function goForward()
    if historyIndex < #history then
        historyIndex = historyIndex + 1
        restoreSnapshot(history[historyIndex])
    end
end

return {
    init = init,
    makeMove = makeMove,
    stones = stones,
    currentPlayer = function() return currentPlayer end,
    setCurrentPlayer = function(p) currentPlayer = p end,
    blackCaptures = function() return blackCaptures end,
    whiteCaptures = function() return whiteCaptures end,
    gameOver = function() return gameOver end,
    winner = function() return winner end,
    boardSize = boardSize,
    cellSize = cellSize,
    margin = margin,
    canGoBack = function() return historyIndex > 1 end,
    canGoForward = function() return historyIndex < #history end,
    goBack = goBack,
    goForward = goForward,
    isAtCurrentPosition = function() return historyIndex == #history end,
    pushHistory = pushHistory,
    getHistory = function() return history, historyIndex end
}