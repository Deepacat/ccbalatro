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
    vars.debugPrint[2] = keys.getName(key)
    if key == keys.space then -- SPACE
        game.changeSortMode()
    end
    if key == keys.e then -- E
        game.dealHand(vars.currentDeck, 1)
    end
end

function obsi.onMousePress(x, y, button)
    vars.debugPrint[1] = x .. ", " .. y .. ", " .. button
    vars.debugPrint[3] = "clicked nothing"

    if vars.gameState == "blindDeckview" then -- EXIT DECKVIEW
        vars.gameState = "blind"
    end
    if game.mouseCollCheck(24, 17, 3, 2) then -- SORT BUTTON
        vars.debugPrint[3] = "clicked sort"
        game.changeSortMode()
    end
    if game.mouseCollCheck(48, 14, 3, 3) then -- DECKVIEW
        vars.debugPrint[3] = "clicked deck"
        vars.gameState = "blindDeckview"
    end
    if game.mouseCollCheck(16, 17, 7, 2) then -- PLAY BUTTON
        vars.debugPrint[3] = "clicked play"
    end
    if game.mouseCollCheck(28, 17, 7, 2) then -- DISCARD BUTTON
        vars.debugPrint[3] = "clicked discard"
    end
end

function obsi.update()
    -- vars.debugPrint[1] = obsi.mouse.getX() .. ", " .. obsi.mouse.getY()
    if obsi.keyboard.isDown("q") then
        obsi.quit()
    end
end

function obsi.draw()
    render.renderbg()
    if vars.gameState == "blind" then
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

        obsi.graphics.write(tostring(vars.debugPrint[1]), 26, 1, colors.white, colors.black)
        obsi.graphics.write(tostring(vars.debugPrint[2]), 26, 2, colors.white, colors.black)
        obsi.graphics.write(tostring(vars.debugPrint[3]), 26, 3, colors.white, colors.black)
    end
    if vars.gameState == "blindDeckview" then
        render.renderAllCards(game.sort(vars.currentDeck))
    end
end

obsi.init()
