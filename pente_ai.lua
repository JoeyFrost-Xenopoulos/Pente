local boardSize = 19

-- For lines, we only need 4 directions to avoid evaluating the same line twice
local directionsHalf = {
    {1, 0}, {0, 1}, {1, 1}, {1, -1}
}

-- For captures, we need all 8 directions to check specific patterns
local directionsFull = {
    {1, 0}, {0, 1}, {1, 1}, {1, -1},
    {-1, 0}, {0, -1}, {-1, -1}, {-1, 1}
}

local function inside(x, y)
    return x >= 1 and x <= boardSize and y >= 1 and y <= boardSize
end

-- Counts contiguous stones and checks if the ends are open (empty space)
local function getLineDetails(stones, x, y, dx, dy, player)
    local count = 1
    local openEnds = 0

    -- Check positive direction
    local cx, cy = x + dx, y + dy
    while inside(cx, cy) and stones[cy][cx] == player do
        count = count + 1
        cx = cx + dx
        cy = cy + dy
    end
    -- Is the positive end open?
    if inside(cx, cy) and stones[cy][cx] == 0 then
        openEnds = openEnds + 1
    end

    -- Check negative direction
    cx, cy = x - dx, y - dy
    while inside(cx, cy) and stones[cy][cx] == player do
        count = count + 1
        cx = cx - dx
        cy = cy - dy
    end
    -- Is the negative end open?
    if inside(cx, cy) and stones[cy][cx] == 0 then
        openEnds = openEnds + 1
    end

    return count, openEnds
end

-- Evaluates the strength of lines created by placing a stone
local function evaluateLines(stones, x, y, player)
    local score = 0
    for _, d in ipairs(directionsHalf) do
        local count, openEnds = getLineDetails(stones, x, y, d[1], d[2], player)
        
        if count >= 5 then
            score = score + 1000000 -- Guaranteed Win
        elseif count == 4 then
            if openEnds == 2 then
                score = score + 100000 -- Open 4 (unstoppable win on next turn)
            elseif openEnds == 1 then
                score = score + 10000  -- Blocked 4 (strong threat, but blockable)
            end
        elseif count == 3 then
            if openEnds == 2 then
                score = score + 5000   -- Open 3 (creates an Open 4 next turn)
            elseif openEnds == 1 then
                score = score + 500    -- Blocked 3
            end
        elseif count == 2 then
            if openEnds == 2 then
                score = score + 100    -- Open 2
            elseif openEnds == 1 then
                score = score + 10     -- Blocked 2
            end
        end
    end
    return score
end

-- Counts how many captures placing a stone at (x,y) will execute
local function getCaptureCount(stones, x, y, player)
    local enemy = 3 - player
    local captures = 0
    for _, d in ipairs(directionsFull) do
        local dx, dy = d[1], d[2]
        local x1, y1 = x + dx, y + dy
        local x2, y2 = x + dx * 2, y + dy * 2
        local x3, y3 = x + dx * 3, y + dy * 3
        
        if inside(x3, y3) then
            if stones[y1][x1] == enemy and
               stones[y2][x2] == enemy and
               stones[y3][x3] == player then
                captures = captures + 1
            end
        end
    end
    return captures
end

local function evaluateMove(stones, x, y, player)
    local enemy = 3 - player
    
    -- OFFENSIVE: What does this move do for us?
    local offensiveScore = evaluateLines(stones, x, y, player)
    local offensiveCaptures = getCaptureCount(stones, x, y, player)
    offensiveScore = offensiveScore + (offensiveCaptures * 20000)

    -- DEFENSIVE: What does this move prevent the enemy from doing?
    local defensiveScore = evaluateLines(stones, x, y, enemy)
    local defensiveCaptures = getCaptureCount(stones, x, y, enemy)
    -- We slightly overvalue blocking enemy captures so the AI plays safely
    defensiveScore = defensiveScore + (defensiveCaptures * 25000) 

    -- POSITIONAL: Small bonus for playing closer to the center (breaks ties naturally)
    local centerDist = math.abs(x - 10) + math.abs(y - 10)
    local positionalBonus = (20 - centerDist) 

    -- Total score prioritizes our best attacks, but heavily weights stopping enemy attacks
    return offensiveScore + (defensiveScore * 0.9) + positionalBonus
end

local function findBestMove(stones, player)
    local bestScore = -1
    local bestMoves = {}

    for y = 1, boardSize do
        for x = 1, boardSize do
            if stones[y][x] == 0 then
                local score = evaluateMove(stones, x, y, player)
                
                if score > bestScore then
                    bestScore = score
                    bestMoves = {{x, y}}
                elseif score == bestScore then
                    table.insert(bestMoves, {x, y})
                end
            end
        end
    end

    -- Pick a random move among equally good best options
    if #bestMoves > 0 then
        local move = bestMoves[math.random(1, #bestMoves)]
        return move[1], move[2]
    end

    return 10, 10 -- Fallback to center on the very rare chance the board is full
end

return {
    findBestMove = findBestMove
}