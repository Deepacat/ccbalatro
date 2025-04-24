--[[
    CC Balatro by Deepacat
    Credits to
    <https://angelvalentin80.itch.io/balatro-in-pico-8> for the Pico8 demake which was mostly ported
    <https://github.com/Haynster/Balatro-DS-Port> for some referencing to non Pico8 code
    <https://github.com/simadude/obsi2> for CC game engine
]] --

local vars = require("vars")
local game = require("game")
local render = require("rendering")
local util = require("util")
local obsi = require("obsi2")

-- Obsi run functions --
function obsi.load()
    game.resetDeck()
    game.createBaseDeck()
    game.baseDeck = game.createBaseDeck()
    game.currentDeck = game.shuffleDeck(vars.baseDeck)
    -- game.dealHand(vars.currentDeck, vars.handSize)
end

function obsi.onKeyPress(key)
    vars.sortTest = key
    if key == 57 then
        if vars.sortMode == "suit" then
            vars.sortMode = "rank"
        else
            vars.sortMode = "suit"
        end
        vars.currentHand = game.sort(vars.currentHand)
    end
    if key == 18 then
        game.dealHand(vars.currentDeck, 1)
    end
end

function obsi.update()
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
    obsi.graphics.write(tostring(vars.sortTest), 10, 6, colors.white, colors.green)
    -- render.renderAllCards(vars.currentDeck)
end

obsi.init()
