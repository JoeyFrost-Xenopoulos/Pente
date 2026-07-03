local help = {}

help.page = 1
help.maxPages = 3


----------------------------------------------------------------
-- INTERNAL UTILS
----------------------------------------------------------------

local function getModalBounds()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    local modalW, modalH = 380, 260
    local modalX = (w - modalW) / 2
    local modalY = (h - modalH) / 2

    return modalX, modalY, modalW, modalH
end

local function drawStone(x, y, r, color)
    if color == "black" then
        love.graphics.setColor(0, 0, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.circle("fill", x, y, r)

    if color == "white" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", x, y, r)
    end
end

local function drawMiniBoard(x, y, size, cell)
    love.graphics.setColor(0.2, 0.2, 0.2)

    for i = 0, size do
        love.graphics.line(x, y + i * cell, x + size * cell, y + i * cell)
        love.graphics.line(x + i * cell, y, x + i * cell, y + size * cell)
    end
end


----------------------------------------------------------------
-- NAVIGATION
----------------------------------------------------------------

function help.nextPage()
    help.page = help.page + 1
    if help.page > help.maxPages then help.page = 1 end
end

function help.prevPage()
    help.page = help.page - 1
    if help.page < 1 then help.page = help.maxPages end
end

function help.reset()
    help.page = 1
end


----------------------------------------------------------------
-- DRAW HELP MODAL
----------------------------------------------------------------

function help.drawHelp()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local modalX, modalY, modalW, modalH = getModalBounds()

    ------------------------------------------------------------
    -- BACKDROP
    ------------------------------------------------------------
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- shadow
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", modalX + 4, modalY + 6, modalW, modalH, 10, 10)

    -- panel
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10, 10)

    ------------------------------------------------------------
    -- HEADER
    ------------------------------------------------------------
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", modalX, modalY, modalW, 40, 10, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
        "How to Play Pente (" .. help.page .. "/" .. help.maxPages .. ")",
        modalX + 14,
        modalY + 12
    )

    ------------------------------------------------------------
    -- CLOSE BUTTON
    ------------------------------------------------------------
    local bx, by, br = modalX + modalW - 18, modalY + 20, 10

    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.circle("fill", bx, by, br)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("×", bx - 4, by - 9)

    ------------------------------------------------------------
    -- CONTENT AREA
    ------------------------------------------------------------
    local x = modalX + 18
    local y = modalY + 60

    love.graphics.setColor(0.1, 0.1, 0.1)


    ------------------------------------------------------------
    -- PAGE 1: BASIC RULES
    ------------------------------------------------------------
    if help.page == 1 then
        love.graphics.print("1. Place stones on intersections.", x, y)
        love.graphics.print("Black goes first.", x, y + 20)

        local bx, by = x, y + 55
        local cell = 14

        drawMiniBoard(bx, by, 5, cell)

        drawStone(bx + 2 * cell, by + 2 * cell, 6, "black")
        drawStone(bx + 3 * cell, by + 1 * cell, 6, "white")

        love.graphics.print("Play on grid intersections.", x, y + 140)
    end


    ------------------------------------------------------------
    -- PAGE 2: CAPTURES
    ------------------------------------------------------------
    if help.page == 2 then
        love.graphics.print("2. Capture enemy stones.", x, y)
        love.graphics.print("Surround 2 stones on both sides.", x, y + 20)

        local bx, by = x, y + 55
        local cell = 16

        drawMiniBoard(bx, by, 4, cell)

        -- capture pattern: B W W B
        drawStone(bx + 0 * cell, by + 2 * cell, 6, "black")
        drawStone(bx + 1 * cell, by + 2 * cell, 6, "white")
        drawStone(bx + 2 * cell, by + 2 * cell, 6, "white")
        drawStone(bx + 3 * cell, by + 2 * cell, 6, "black")

        love.graphics.print("White stones are removed.", x, y + 140)
    end


    ------------------------------------------------------------
    -- PAGE 3: WIN CONDITIONS
    ------------------------------------------------------------
    if help.page == 3 then
        love.graphics.print("3. Win Conditions:", x, y)

        love.graphics.print("• Get 5 in a row", x, y + 25)
        love.graphics.print("• OR capture 15 stones", x, y + 45)

        local bx, by = x, y + 80
        local cell = 14

        drawMiniBoard(bx, by, 6, cell)

        for i = 0, 4 do
            drawStone(bx + (i + 1) * cell, by + 3 * cell, 6, "black")
        end
    end


    ------------------------------------------------------------
    -- FOOTER (ARROW BUTTONS)
    ------------------------------------------------------------

    local footerY = modalY + modalH - 28

    local leftX = modalX + 80
    local rightX = modalX + modalW - 80
    local cy = footerY + 10
    local r = 10

    local function drawArrowButton(x, y, dir)
        local hovered = false

        local mx, my = love.mouse.getPosition()
        local dx, dy = mx - x, my - y
        if dx * dx + dy * dy <= r * r then
            hovered = true
        end

        -- circle background
        if hovered then
            love.graphics.setColor(0.25, 0.25, 0.3)
        else
            love.graphics.setColor(0.18, 0.18, 0.2)
        end

        love.graphics.circle("fill", x, y, r)

        -- arrow
        love.graphics.setColor(1, 1, 1)

        if dir == "left" then
            love.graphics.polygon("fill",
                x + 3, y - 5,
                x + 3, y + 5,
                x - 4, y
            )
        else
            love.graphics.polygon("fill",
                x - 3, y - 5,
                x - 3, y + 5,
                x + 4, y
            )
        end
    end

    drawArrowButton(leftX, cy, "left")
    drawArrowButton(rightX, cy, "right")

    -- page indicator (dots)
    love.graphics.setColor(0.3, 0.3, 0.3)

    for i = 1, help.maxPages do
        local dotX = modalX + modalW / 2 + (i - 2) * 14
        local dotY = cy

        if i == help.page then
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.circle("fill", dotX, dotY, 4)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.circle("line", dotX, dotY, 3)
        end
    end
end


----------------------------------------------------------------
-- INPUT HELPERS
----------------------------------------------------------------

function help.handleGameStateHelpClick(mx, my)
    local w = love.graphics.getWidth()

    local r = 11
    local margin = 16

    local cx = w - margin - r
    local cy = margin + r

    local dx, dy = mx - cx, my - cy
    return dx * dx + dy * dy <= r * r
end


function help.handleHelpCloseClick(mx, my)
    local modalX, modalY, modalW, modalH = getModalBounds()
    local bx, by, br = modalX + modalW - 18, modalY + 20, 10

    local dx, dy = mx - bx, my - by
    return dx * dx + dy * dy <= br * br
end

function help.handleArrowClick(mx, my)
    local modalX, modalY, modalW, modalH = getModalBounds()

    local footerY = modalY + modalH - 28
    local cy = footerY + 10
    local r = 10

    local leftX = modalX + 80
    local rightX = modalX + modalW - 80

    local function hit(x, y)
        local dx, dy = mx - x, my - y
        return dx * dx + dy * dy <= r * r
    end

    if hit(leftX, cy) then
        help.prevPage()
        return true
    end

    if hit(rightX, cy) then
        help.nextPage()
        return true
    end

    return false
end


return help