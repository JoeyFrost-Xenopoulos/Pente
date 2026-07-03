local boardSize = 19

-- 4 directions for line building (Horizontal, Vertical, Diagonal Right, Diagonal Left)
local directionsHalf = {
    {1, 0}, {0, 1}, {1, 1}, {1, -1}
}

-- 8 directions for captures
local directionsFull = {
    {1, 0}, {0, 1}, {1, 1}, {1, -1},
    {-1, 0}, {0, -1}, {-1, -1}, {-1, 1}
}

local function inside(x, y)
    return x >= 1 and x <= boardSize and y >= 1 and y <= boardSize
end

-- Counts contiguous stones and open ends
local function getLineDetails(stones, x, y, dx, dy, player)
    local count = 1
    local openEnds = 0

    -- Positive direction
    local cx, cy = x + dx, y + dy
    while inside(cx, cy) and stones[cy][cx] == player do
        count = count + 1
        cx = cx + dx
        cy = cy + dy
    end
    if inside(cx, cy) and stones[cy][cx] == 0 then openEnds = openEnds + 1 end

    -- Negative direction
    cx, cy = x - dx, y - dy
    while inside(cx, cy) and stones[cy][cx] == player do
        count = count + 1
        cx = cx - dx
        cy = cy - dy
    end
    if inside(cx, cy) and stones[cy][cx] == 0 then openEnds = openEnds + 1 end

    return count, openEnds
end

-- Evaluates lines and specifically tracks lethal combinations
local function evaluateLines(stones, x, y, player)
    local score = 0
    local open4s = 0
    local open3s = 0
    local blocked4s = 0

    for _, d in ipairs(directionsHalf) do
        local count, openEnds = getLineDetails(stones, x, y, d[1], d[2], player)
        
        if count >= 5 then
            score = score + 10000000 -- Guaranteed Win
        elseif count == 4 then
            if openEnds == 2 then
                open4s = open4s + 1
                score = score + 100000 
            elseif openEnds == 1 then
                blocked4s = blocked4s + 1
                score = score + 10000  
            end
        elseif count == 3 then
            if openEnds == 2 then
                open3s = open3s + 1
                score = score + 5000   
            elseif openEnds == 1 then
                score = score + 500    
            end
        elseif count == 2 then
            if openEnds == 2 then
                score = score + 100    
            elseif openEnds == 1 then
                score = score + 10     
            end
        end
    end

    -- COMBINATION MULTIPLIERS: This is what makes the AI truly dangerous.
    -- Double Open 3, or Open 4 + Open 3 are usually game-ending threats.
    if open4s >= 1 and open3s >= 1 then
        score = score + 500000
    elseif open3s >= 2 then
        score = score + 400000
    elseif blocked4s >= 2 then
        score = score + 300000
    end

    return score
end

-- Actually executes a move on the board temporarily to see the real outcome
local function simulateMoveAndCaptures(stones, x, y, player)
    local enemy = 3 - player
    local capturesMade = 0
    local capturedStones = {}

    -- 1. Place the stone
    stones[y][x] = player

    -- 2. Find and remove captures
    for _, d in ipairs(directionsFull) do
        local dx, dy = d[1], d[2]
        local x1, y1 = x + dx, y + dy
        local x2, y2 = x + dx * 2, y + dy * 2
        local x3, y3 = x + dx * 3, y + dy * 3
        
        if inside(x3, y3) then
            if stones[y1][x1] == enemy and
               stones[y2][x2] == enemy and
               stones[y3][x3] == player then
                
                -- Execute capture
                stones[y1][x1] = 0
                stones[y2][x2] = 0
                capturesMade = capturesMade + 1
                table.insert(capturedStones, {x1, y1, x2, y2})
            end
        end
    end

    return capturesMade, capturedStones
end

-- Reverts the simulated move
local function undoMove(stones, x, y, capturedStones, enemy)
    stones[y][x] = 0
    for _, cap in ipairs(capturedStones) do
        stones[cap[2]][cap[1]] = enemy
        stones[cap[4]][cap[3]] = enemy
    end
end

-- Evaluates the total strength of a specific move
local function evaluateMove(stones, x, y, player)
    local enemy = 3 - player
    
    -- DEFENSIVE: What would happen if the enemy played here?
    -- We check this BEFORE we simulate our move, to see what we are blocking.
    local defensiveScore = evaluateLines(stones, x, y, enemy)
    -- Simulate enemy playing here to see how many of our stones they would capture
    local enemyCaptures, enemyCapData = simulateMoveAndCaptures(stones, x, y, enemy)
    undoMove(stones, x, y, enemyCapData, player)
    
    -- Heavily prioritize preventing enemy captures (and wins)
    defensiveScore = defensiveScore + (enemyCaptures * 30000)

    -- OFFENSIVE: Simulate our move
    local myCaptures, myCapData = simulateMoveAndCaptures(stones, x, y, player)
    
    -- Evaluate our line strength *after* captures are removed from the board
    local offensiveScore = evaluateLines(stones, x, y, player)
    offensiveScore = offensiveScore + (myCaptures * 25000)

    -- Undo our simulated move to restore board state
    undoMove(stones, x, y, myCapData, enemy)

    -- POSITIONAL: Play closer to the center to break ties
    local centerDist = math.abs(x - 10) + math.abs(y - 10)
    local positionalBonus = (20 - centerDist) * 2 

    -- Combine scores. In Pente, blocking a win is as important as making one.
    return offensiveScore + (defensiveScore * 1.1) + positionalBonus
end

-- Finds only tiles within a 2-space radius of existing stones (Massive speed boost)
local function getRelevantMoves(stones)
    local moves = {}
    local visited = {}
    local hasStones = false

    for y = 1, boardSize do
        for x = 1, boardSize do
            if stones[y][x] ~= 0 then
                hasStones = true
                for dy = -2, 2 do
                    for dx = -2, 2 do
                        local ny, nx = y + dy, x + dx
                        if inside(nx, ny) and stones[ny][nx] == 0 then
                            local id = ny * boardSize + nx
                            if not visited[id] then
                                visited[id] = true
                                table.insert(moves, {x = nx, y = ny})
                            end
                        end
                    end
                end
            end
        end
    end

    return moves, hasStones
end

local function findBestMove(stones, player)
    local relevantMoves, hasStones = getRelevantMoves(stones)

    -- If the board is completely empty, play dead center
    if not hasStones then
        return 10, 10
    end

    local bestScore = -math.huge
    local bestMoves = {}

    for _, move in ipairs(relevantMoves) do
        local score = evaluateMove(stones, move.x, move.y, player)
        
        if score > bestScore then
            bestScore = score
            bestMoves = {move}
        elseif score == bestScore then
            table.insert(bestMoves, move)
        end
    end

    -- Pick a random move among equally good options to keep the AI unpredictable
    if #bestMoves > 0 then
        local chosen = bestMoves[math.random(1, #bestMoves)]
        return chosen.x, chosen.y
    end

    return 10, 10
end

return {
    findBestMove = findBestMove
}