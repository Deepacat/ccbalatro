local obsi = require("obsi2")
local vars = require("vars")
local game = require("game")
local render = require("render")
local util = require("util")
local monitor = peripheral.find("monitor")

if monitor then
    monitor.setTextScale(1)
    local monx, mony = monitor.getSize()
    monitor.setTextScale(monx / 51)
end

-- Obsi run functions --
function obsi.load()
    game.makeHandTypesCopy()
    game.resetDeck()
    game.createBaseDeck()
    vars.baseDeck = game.createBaseDeck()
    vars.currentDeck = game.shuffleDeck(vars.baseDeck)
    game.dealHand(vars.currentDeck, vars.handSize)
    -- util.add(vars.heldJokers, game.specialCards.Jokers[util.rnd(21)])
    -- util.add(vars.heldJokers, game.specialCards.Jokers[util.rnd(21)])
    -- util.add(vars.heldJokers, game.specialCards.Jokers[util.rnd(21)])
    -- util.add(vars.heldJokers, game.specialCards.Jokers[util.rnd(21)])
    for joker in util.all(game.specialCards.Jokers) do
		util.add(vars.heldJokers, joker)
	end
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
    if button == 1 then
        -- in game click checks
        if vars.gameState == "blind" then
            game.discardBtnClicked() -- DISCARD BUTTON
            game.playBtnClicked()    -- PLAY BUTTON
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
    if button == 2 then
        if vars.gameState == "blind" then
            game.deselectAllCards()
        end
    end
end

vars.animation = util.cocreate(print)
function obsi.update()
    if util.costatus(vars.animation) ~= 'dead' then
        util.coresume(vars.animation)
        return
    end
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
    game.drawSparkles()
end

obsi.init()
