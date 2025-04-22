--[[
    CC Balatro by Deepacat
    Credits to
    <https://angelvalentin80.itch.io/balatro-in-pico-8> for the Pico8 demake which was mostly ported
    <https://github.com/Haynster/Balatro-DS-Port> for some referencing to non Pico8 code
    <https://github.com/simadude/obsi2> for CC game engine
]] --
local obsi = require("obsi2")

-- vars
local screenWidth, screenHeight = term.getSize()

-- local seed = math.randomseed(42)

local ante = 1
local money = 0

local handSize = 8
local handsLeft = 4
local discardsLeft = 3
local maxHands = 4
local maxDiscards = 3

local curChips = 0
local curMult = 0
local totalScore = 0
local blindReq = 300

local currentMaxJokers = 5
local currentMaxConsumables = 2
local heldJokers = {}
local heldConsumables = {}

local currentHand = {}
local selectedHand = {}

local suits = { { 'H', '\3', colors.red }, { 'D', '\4', colors.orange }, { 'C', '\5', colors.blue }, { 'S', '\6', colors.black } }


local fullDeck = {
    "1H", "2H", "3H", "4H", "5H", "6H", "7H", "8H", "9H", "JH", "KH", "QH", "AH",
    "1D", "2D", "3D", "4D", "5D", "6D", "7D", "8D", "9D", "JD", "KD", "QD", "AD",
    "1S", "2S", "3S", "4S", "5S", "6S", "7S", "8S", "9S", "JS", "KS", "QS", "AS",
    "1C", "2C", "3C", "4C", "5C", "6C", "7C", "8C", "9C", "JC", "KC", "QC", "AC",
}
local currentDeck = {}
local baseDeck = {}

local ranks = {
    { rank = 'A', baseChips = 11 }, { rank = 'K', baseChips = 10 }, { rank = 'Q', baseChips = 10 },
    { rank = 'J', baseChips = 10 }, { rank = '10', baseChips = 10 }, { rank = '9', baseChips = 9 },
    { rank = '8', baseChips = 8 }, { rank = '7', baseChips = 7 }, { rank = '6', baseChips = 6 },
    { rank = '5', baseChips = 5 }, { rank = '4', baseChips = 4 }, { rank = '3', baseChips = 3 },
    { rank = '2', baseChips = 2 },
}

local handTypes = {
    ["Flush Five"] = { baseChips = 160, baseMult = 16, level = 1 },
    ["Flush House"] = { baseChips = 140, baseMult = 14, level = 1 },
    ["Five of a Kind"] = { baseChips = 120, baseMult = 12, level = 1 },
    ["Royal Flush"] = { baseChips = 100, baseMult = 8, level = 1 },
    ["Straight Flush"] = { baseChips = 100, baseMult = 8, level = 1 },
    ["Four of a Kind"] = { baseChips = 60, baseMult = 7, level = 1 },
    ["Full House"] = { baseChips = 40, baseMult = 4, level = 1 },
    ["Flush"] = { baseChips = 35, baseMult = 4, level = 1 },
    ["Straight"] = { baseChips = 30, baseMult = 4, level = 1 },
    ["Three of a Kind"] = { baseChips = 30, baseMult = 3, level = 1 },
    ["Two Pair"] = { baseChips = 20, baseMult = 2, level = 1 },
    ["Pair"] = { baseChips = 10, baseMult = 2, level = 1 },
    ["High Card"] = { baseChips = 5, baseMult = 1, level = 1 }
}

-- -- -- -- general functions -- -- -- --

-- removes the first occurence of value in table
local function del(t, v)
    for i = 1, #t do
        if t[i] == v then
            table.remove(t, i)
            return
        end
    end
end

-- shorthand for table.remove
local deli = table.remove

-- shorthand for table.insert
local function add(t, v)
    return table.insert(t, v)
end

-- returns the number of occurences of value appears in table
local function count(t, v)
    local c = 0
    for i = 1, #t do
        if t[i] == v then
            c = c + 1
        end
    end
    return c
end

-- iterator in for loops to iterate over items in order they were added, similar to ipairs without key
local function all(t)
    local i = 0
    local n = #t
    return function()
        i = i + 1
        if i <= n then return t[i] end
    end
end

-- random number from 0 to x, or random entry in table
local function rnd(x)
    if type(x) == "number" then return math.random(x) end
    if type(x) == "table" then return x[math.random(#x)] end
end

-- shorthand for math.floor
local function flr(x)
    return math.floor(x)
end

-- shorthand for math.abs
local function abs(x)
    return math.abs(x)
end

-- -- -- -- general functions end -- -- -- --

-- -- -- -- game functions -- -- -- --
local function resetDeck()
    currentDeck = fullDeck
end

local itemObj = {
    type = "card",
    -- default size stuff
    -- width = Card_width,
    -- height = Card_height,
    -- resettable params
    selected = false,
    posx = 0,
    posy = 0,
    fromx = nil,
    fromy = nil,
    frames = 0,
    pickedUp = false
}

function itemObj:new(obj)
    return setmetatable(obj, {
        __index = self
    })
end

local cardObj = itemObj:new({
    type = "card",
    bgtile = 15,
    height = 15, -- scant 2 tiles
    effectChips = 0,
    mult = 0,
    posx = 0,
    posy = 0,
    -- when_held_in_hand = do_nothing,
    -- when_held_at_end = do_nothing,
    -- effect = do_nothing,
    -- card_effect = do_nothing
})

local function createBaseDeck()
    local tempBaseDeck = {}
    -- Set the sorting order, also
    -- used as proxy for rank in
    -- array returned by
    -- card_frequencies()
    for i, card in pairs(ranks) do
        card.order = i
    end

    -- Create deck
    for x = 1, #ranks do
        for y = 1, #suits do
            local cardInfo = cardObj:new({
                rank = ranks[x].rank,
                suit = suits[y],
                -- sprite_index = ranks[x].sprite_index,
                chips = ranks[x].baseChips,
                order = ranks[x].order,
            })
            add(tempBaseDeck, cardInfo)
        end
    end
    return tempBaseDeck
end

local function shuffleDeck(deck)
    local copyDeck = {}
    for x = 1, #deck do
        add(copyDeck, deck[x])
    end
    local shuffledDeck = {}

    for x = 1, #copyDeck do
        local rndCard = rnd(copyDeck)
        add(shuffledDeck, rndCard)
        del(copyDeck, rndCard)
    end
    return shuffledDeck
end

local function sortBy(property, cards)
    -- insertion sort
    for i = 2, #cards do
        local currentOrder = cards[i][property]
        local current = cards[i]
        local j = i - 1
        while (j >= 1 and currentOrder < cards[j][property]) do
            cards[j + 1] = cards[j]
            j = j - 1
        end
        cards[j + 1] = current
    end
end

local function sortByX(cards)
    sortBy("posx", cards)
end

local function sortByRankDescending(cards)
    sortBy("order", cards)
end

local function dealHand(shuffledDeck, cardsToDeal)
    if #shuffledDeck < cardsToDeal then
        for card in all(shuffledDeck) do
            add(currentHand, card)
            del(shuffledDeck, card)
        end
    else
        for x = 1, cardsToDeal do
            add(currentHand, shuffledDeck[1])
            del(shuffledDeck, shuffledDeck[1])
        end
    end
    sortByRankDescending(currentHand)
end

-- -- -- -- end game functions -- -- -- --

-- -- -- -- rendering functions -- -- -- --
local function renderbg()
    obsi.graphics.setBackgroundColor(colors.green)
end

local function renderScore()
    obsi.graphics.write(tostring(curChips), 2, 10, colors.white, colors.blue)
    obsi.graphics.write("x", 2 + #tostring(curChips), 10, colors.white, colors.green)
    obsi.graphics.write(tostring(curMult), 3 + #tostring(curChips), 10, colors.white, colors.red)
    obsi.graphics.write(totalScore .. "/", 2, 11, colors.white, colors.green)
    obsi.graphics.write(tostring(blindReq), 2, 12, colors.white, colors.green)
end

local function renderMoney()
    obsi.graphics.write("$:" .. tostring(money), 2, 17, colors.white, colors.lime)
end

local function renderAnte()
    obsi.graphics.write("A:" .. ante .. "/8", 2, 18, colors.white, colors.orange)
end

local function renderPlayBtn()
    obsi.graphics.setForegroundColor(colors.cyan)
    obsi.graphics.rectangle("fill", 16, 17, 7, 2)
    obsi.graphics.write("PLAY", 17, 17, colors.white, colors.cyan)
    obsi.graphics.write(handsLeft .. "/" .. maxHands, 18, 18, colors.white, colors.cyan)
end

local function renderDiscardBtn()
    obsi.graphics.setForegroundColor(colors.red)
    obsi.graphics.rectangle("fill", 28, 17, 7, 2)
    obsi.graphics.write("DISCARD", 28, 17, colors.white, colors.red)
    obsi.graphics.write(discardsLeft .. "/" .. maxDiscards, 30, 18, colors.white, colors.red)
end

local function renderSortBtn()
    obsi.graphics.setForegroundColor(colors.orange)
    obsi.graphics.rectangle("fill", 24, 17, 3, 2)
    obsi.graphics.write("S O", 24, 17, colors.white, colors.orange)
    obsi.graphics.write("R T", 24, 18, colors.white, colors.orange)
end

local function renderJokers()
    obsi.graphics.setForegroundColor(colors.white)
    obsi.graphics.rectangle("fill", 2, 2, 3, 3)
    obsi.graphics.write(tostring(#heldJokers) .. "/" .. tostring(currentMaxJokers), 2, 6, colors.white, colors.green)
end

local function renderConsumables()
    obsi.graphics.setForegroundColor(colors.white)
    obsi.graphics.rectangle("fill", 48, 2, 3, 3)
    obsi.graphics.write(tostring(#heldConsumables) .. "/" .. tostring(currentMaxConsumables), 48, 6, colors.white,
        colors.green)
end

local function renderDeck()
    -- maybe use nfp asset later
    obsi.graphics.rectangle("fill", 48, 14, 3, 3)
    obsi.graphics.write(#currentDeck .. "/" .. #fullDeck, 46, 18, colors.white, colors.green)
end

local function renderHand()
    for i = 1, #currentHand do
        local baseX = (screenWidth / 2 + 1) - (#currentHand * 3 / 2)
        local baseY = 14
        local cur = currentHand[i]
        obsi.graphics.rectangle("fill", baseX + 3 * (i - 1), baseY, 2, 2)
        obsi.graphics.write(tostring(cur.rank), baseX + 3 * (i - 1), baseY, cur.suit[3], colors.white)
        obsi.graphics.write(" " .. cur.suit[2], baseX + 3 * (i - 1), baseY + 1, cur.suit[3], colors.white)
    end
end

-- debug function to see all cards, may repurpose later for viewing deck
local function renderAllCards(cards)
    sortByRankDescending(cards)
    local baseXOff = 1
    local baseX = 1
    local baseY = 1
    for i = 1, #cards do
        local cur = cards[i]
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
-- -- -- -- end rendering functions -- -- -- --

-- Obsi run functions --
function obsi.load()
    resetDeck()
    createBaseDeck()
    baseDeck = createBaseDeck()
    currentDeck = shuffleDeck(baseDeck)
    dealHand(currentDeck, handSize)
end

function obsi.update()
    if obsi.keyboard.isDown("q") then
        obsi.quit()
    end
end

function obsi.draw()
    renderbg()
    renderPlayBtn()
    renderSortBtn()
    renderDiscardBtn()
    renderMoney()
    renderAnte()
    renderScore()
    renderJokers()
    renderConsumables()
    renderDeck()
    renderHand()

    -- renderAllCards(baseDeck)
end

obsi.init()
