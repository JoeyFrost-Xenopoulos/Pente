local boardSize = 19

local directionsFull = {
    {1, 0}, {0, 1}, {1, 1}, {1, -1},
    {-1, 0}, {0, -1}, {-1, -1}, {-1, 1}
}

local function inside(x, y)
    return x >= 1 and x <= boardSize and y >= 1 and y <= boardSize
end

local function countInDirection(stones, x, y, dx, dy, player)
    local count = 0
    local cx, cy = x + dx, y + dy
    while inside(cx, cy) and stones[cy][cx] == player do
        count = count + 1
        cx = cx + dx
        cy = cy + dy
    end
    return count
end

local function evaluateLine(stones, x, y, player)
    local score = 0
    for _, d in ipairs(directionsFull) do
        local total = 1 + countInDirection(stones, x, y, d[1], d[2], player) +
                          countInDirection(stones, x, y, -d[1], -d[2], player)
        if total >= 5 then
            score = score + 100000
        elseif total == 4 then
            score = score + 10000
        elseif total == 3 then
            score = score + 1000
        end
    end
    return score
end

local function checkCaptureOpportunity(stones, x, y, player)
    local enemy = 3 - player
    local score = 0
    for _, d in ipairs(directionsFull) do
        local dx, dy = d[1], d[2]
        
        local x1, y1 = x + dx, y + dy
        local x2, y2 = x + dx * 2, y + dy * 2
        local x3, y3 = x + dx * 3, y + dy * 3
        if inside(x3, y3) and inside(x1, y1) and inside(x2, y2) then
            if stones[y1] and stones[y1][x1] == enemy and
               stones[y2] and stones[y2][x2] == enemy and
               stones[y3] and stones[y3][x3] == player then
                score = score + 20000
            end
        end
    end
    return score
end

local function findBestMove(stones, player)
    local bestScore = -1
    local bestMoves = {}

    for y = 1, boardSize do
        for x = 1, boardSize do
            if stones[y][x] == 0 then
                local score = 0
                score = score + evaluateLine(stones, x, y, player)
                score = score + checkCaptureOpportunity(stones, x, y, player)
                score = score + evaluateLine(stones, x, y, 3 - player) * 0.8
                score = score + checkCaptureOpportunity(stones, x, y, 3 - player) * 0.5

                if score > bestScore then
                    bestScore = score
                    bestMoves = {{x, y}}
                elseif score == bestScore then
                    table.insert(bestMoves, {x, y})
                end
            end
        end
    end

    if #bestMoves == 0 then
        for y = 1, boardSize do
            for x = 1, boardSize do
                if stones[y][x] == 0 then
                    table.insert(bestMoves, {x, y})
                end
            end
        end
    end

    local move = bestMoves[math.random(1, #bestMoves)]
    if move then
        local centerX, centerY = 10, 10
        local centerDist = math.abs(move[1] - centerX) + math.abs(move[2] - centerY)
        if centerDist > 8 then
            for _, m in ipairs(bestMoves) do
                local d = math.abs(m[1] - centerX) + math.abs(m[2] - centerY)
                if d < centerDist then
                    move = m
                    centerDist = d
                end
            end
        end
    end

    return move[1], move[2]
end

return {
    findBestMove = findBestMove
}