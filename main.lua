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
    if key == keys.space then -- Space to change sorting mode
        game.changeSortMode()
    end
    if key == keys.e then -- E to dealhand
        game.dealHand(vars.currentDeck, 1)
    end
    if key == keys.q then -- Q to quit
        obsi.quit()
    end
end

function obsi.onMousePress(x, y, button)
    vars.debugPrint[1] = x .. ", " .. y .. ", " .. button
    vars.debugPrint[3] = "clicked nothing"

    -- in game click checks
    if vars.gameState == "blind" then
        game.discardBtnClicked() -- DISCARD BUTTON
        game.playBtnClicked() -- PLAY BUTTON
        if game.handCollDown() then
            game.selectHand(game.handCollDown())
            game.updateSelectedCards()
            vars.debugPrint[3] = "clicked card"
        end
        if game.mouseCollCheck(24, 17, 3, 2) then -- SORT BUTTON
            vars.debugPrint[3] = "clicked sort"
            game.changeSortMode()
            return
        end
        if game.mouseCollCheck(48, 14, 3, 3) then -- DECKVIEW
            vars.debugPrint[3] = "clicked deck"
            vars.gameState = "blindDeckview"
            return
        end
    end
    if vars.gameState == "blindDeckview" then -- EXIT DECKVIEW
        vars.gameState = "blind"
        return
    end
end

function obsi.update()
end

function obsi.draw()
    render.renderbg()
    if vars.gameState == "blind" then -- ingame UI rendering
        game.drawHand()
        render.renderPlayBtn()
        render.renderSortBtn()
        render.renderDiscardBtn()
        render.renderMoney()
        render.renderAnte()
        render.renderScore()
        render.renderJokers()
        render.renderConsumables()
        render.renderDeck()
        -- render.renderHand()

        obsi.graphics.write(tostring(vars.debugPrint[1]), 26, 1, colors.white, colors.black)
        obsi.graphics.write(tostring(vars.debugPrint[2]), 26, 2, colors.white, colors.black)
        obsi.graphics.write(tostring(vars.debugPrint[3]), 26, 3, colors.white, colors.black)

    end
    if vars.gameState == "blindDeckview" then -- ingame deck view
        render.renderAllCards("viewScreen")
    end
end

obsi.init()
