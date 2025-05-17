local obsi = require("obsi2")
local vars = require("vars")
local util = require("util")
local game = require("game")

local render = {}

function render.renderbg()
    obsi.graphics.setBackgroundColor(colors.green)
end

function render.renderScore()
    obsi.graphics.write(tostring(vars.curChips), 2, 10, colors.white, colors.blue)
    obsi.graphics.write("x", 2 + #tostring(vars.curChips), 10, colors.white, colors.green)
    obsi.graphics.write(tostring(vars.curMult), 3 + #tostring(vars.curChips), 10, colors.white, colors.red)
    if (vars.handTypeText ~= "") then
        obsi.graphics.write(vars.handTypeText .. " Lv" .. vars.handTypes[vars.handTypeText].level,
            2, 11, colors.white, colors.green)
    end
    obsi.graphics.write(vars.currentScore .. "/", 2, 12, colors.white, colors.green)
    obsi.graphics.write(tostring(vars.blindGoal), 2, 13, colors.white, colors.green)
end

function render.renderMoney()
    obsi.graphics.write("$:" .. tostring(vars.money), 2, 17, colors.white, colors.lime)
end

function render.renderAnte()
    obsi.graphics.write("A:" .. vars.ante .. "/8", 2, 18, colors.white, colors.orange)
end

function render.renderPlayBtn()
    obsi.graphics.setForegroundColor(colors.cyan)
    obsi.graphics.rectangle("fill", 16, 17, 7, 2)
    obsi.graphics.write("PLAY", 17, 17, colors.white, colors.cyan)
    obsi.graphics.write(vars.handsLeft .. "/" .. vars.maxHands, 18, 18, colors.white, colors.cyan)
end

function render.renderDiscardBtn()
    obsi.graphics.setForegroundColor(colors.red)
    obsi.graphics.rectangle("fill", 28, 17, 7, 2)
    obsi.graphics.write("DISCARD", 28, 17, colors.white, colors.red)
    obsi.graphics.write(vars.discardsLeft .. "/" .. vars.maxDiscards, 30, 18, colors.white, colors.red)
end

function render.renderSortBtn()
    obsi.graphics.setForegroundColor(colors.orange)
    obsi.graphics.rectangle("fill", 24, 17, 3, 2)
    obsi.graphics.write("S O", 24, 17, colors.white, colors.orange)
    obsi.graphics.write("R T", 24, 18, colors.white, colors.orange)
end

function render.renderJokers()
    local x = 2
    local y = 2
    for joker in util.all(vars.heldJokers) do
        joker:place(x, y)
        joker:draw()
        obsi.graphics.setForegroundColor(colors.white)
        obsi.graphics.rectangle("fill", x, y, 3, 3)
        obsi.graphics.write(tostring(joker.name), x, y, colors.white, colors.black)
        x = x + 4
        y = y + 1
    end
    obsi.graphics.write(tostring(#vars.heldJokers) .. "/" .. tostring(vars.currentMaxJokers), 2, 6, colors.white,
        colors.green)
end

function render.renderConsumables()
    obsi.graphics.setForegroundColor(colors.white)
    obsi.graphics.rectangle("fill", 48, 2, 3, 3)
    obsi.graphics.write(tostring(#vars.heldConsumables) .. "/" .. tostring(vars.currentMaxConsumables), 48, 6,
        colors.white,
        colors.green)
end

function render.renderDeck()
    -- maybe use nfp asset later
    obsi.graphics.rectangle("fill", 48, 14, 3, 3)
    obsi.graphics.write(#vars.currentDeck .. "/" .. #vars.fullDeck, 46, 18, colors.white, colors.green)
end

function render.renderHand()
    for i = 1, #vars.currentHand do
        local baseX = (vars.screenWidth / 2 + 1) - (#vars.currentHand * 3 / 2)
        local baseY = 14
        local cur = vars.currentHand[i]
        obsi.graphics.rectangle("fill", baseX + 3 * (i - 1), baseY, 2, 2)
        obsi.graphics.write(tostring(cur.rank), baseX + 3 * (i - 1), baseY, cur.suit[3], colors.white)
        obsi.graphics.write(" " .. cur.suit[2], baseX + 3 * (i - 1), baseY + 1, cur.suit[3], colors.white)
    end
end

-- debug function to see all cards, may repurpose later for viewing deck
function render.renderAllCards(cards)
    local function drawAll(cardsToDraw, y)
        local baseXOff = 1
        local baseX = 2
        local baseY = y
        for i = 1, #cardsToDraw do
            local cur = cardsToDraw[i]
            obsi.graphics.rectangle("fill", baseX + 3 * (baseXOff - 1), baseY, 2, 2)
            obsi.graphics.write(tostring(cur.rank), baseX + 3 * (baseXOff - 1), baseY, cur.suit[3], colors.white)
            obsi.graphics.write(" " .. cur.suit[2], baseX + 3 * (baseXOff - 1), baseY + 1, cur.suit[3], colors.white)
            baseXOff = baseXOff + 1
            if baseXOff > 16 then
                baseXOff = 1
                baseY = baseY + 3
            end
        end
    end

    if cards == "viewScreen" then
        local cardSuits = { {}, {}, {}, {} }
        for card in util.all(game.sort(vars.currentDeck)) do
            if card.suit[1] == "H" then
                util.add(cardSuits[1], card)
            elseif card.suit[1] == "D" then
                util.add(cardSuits[2], card)
            elseif card.suit[1] == "C" then
                util.add(cardSuits[3], card)
            elseif card.suit[1] == "S" then
                util.add(cardSuits[4], card)
            end
        end

        drawAll(cardSuits[1], 2)
        drawAll(cardSuits[2], 5)
        drawAll(cardSuits[3], 8)
        drawAll(cardSuits[4], 11)
    end
    if cards ~= "viewScreen" then
        drawAll(cards, 1)
    end
end

return render
