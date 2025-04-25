local obsi = require("obsi2")
local vars = require("vars")
local game = require("game")
local render = require("render")

-- Obsi run functions --
function obsi.load()
    game.resetDeck()
    game.createBaseDeck()
    vars.baseDeck = game.createBaseDeck()
    vars.currentDeck = game.shuffleDeck(vars.baseDeck)
    game.dealHand(vars.currentDeck, vars.handSize)
end

function obsi.onKeyPress(key)
    vars.debugPrint[2] = key
    if key == keys.space then -- SPACE
        if vars.sortMode == "suit" then
            vars.sortMode = "rank"
        else
            vars.sortMode = "suit"
        end
        vars.currentHand = game.sort(vars.currentHand)
    end
    if key == keys.e then -- E
        game.dealHand(vars.currentDeck, 1)
    end
end

function obsi.onMousePress(x, y, button)
    vars.debugPrint[1] = x .. ", " .. y .. ", " .. button
end

function obsi.update()
    -- vars.debugPrint[1] = obsi.mouse.getX() .. ", " .. obsi.mouse.getY()
    if obsi.keyboard.isDown("q") then
        obsi.quit()
    end
end

function obsi.draw()
    render.renderbg()
    render.renderPlayBtn()
    render.renderSortBtn()
    render.renderDiscardBtn()
    render.renderMoney()
    render.renderAnte()
    render.renderScore()
    render.renderJokers()
    render.renderConsumables()
    render.renderDeck()
    render.renderHand()

    obsi.graphics.write(vars.sortMode, 10, 5, colors.white, colors.green)
    obsi.graphics.write(tostring(vars.debugPrint[1]), 26, 1, colors.white, colors.black)
    obsi.graphics.write(tostring(vars.debugPrint[2]), 26, 2, colors.white, colors.black)
    -- renderAllCards(currentDeck)
end

obsi.init()
