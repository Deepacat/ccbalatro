local vars = require("vars")
local gen = require("general")
-- -- -- -- game functions -- -- -- --
local game = {}

function game.resetDeck()
    vars.currentDeck = vars.fullDeck
end

game.itemObj = {
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

function game.itemObj:new(obj)
    return setmetatable(obj, {
        __index = self
    })
end

game.cardObj = game.itemObj:new({
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

function game.createBaseDeck()
    local tempBaseDeck = {}
    -- Set the sorting order, also
    -- used as proxy for rank in
    -- array returned by
    -- card_frequencies()
    for i, card in pairs(vars.ranks) do
        card.order = i
    end

    -- Create deck
    for x = 1, #vars.ranks do
        for y = 1, #vars.suits do
            local cardInfo = game.cardObj:new({
                rank = vars.ranks[x].rank,
                suit = vars.suits[y],
                -- sprite_index = ranks[x].sprite_index,
                chips = vars.ranks[x].baseChips,
                order = vars.ranks[x].order,
            })
            gen.add(tempBaseDeck, cardInfo)
        end
    end
    return game.tempBaseDeck
end

function game.shuffleDeck(deck)
    local copyDeck = {}
    for x = 1, #deck do
        gen.add(copyDeck, deck[x])
    end
    local shuffledDeck = {}

    for x = 1, #copyDeck do
        local rndCard = gen.rnd(copyDeck)
        gen.add(shuffledDeck, rndCard)
        gen.del(copyDeck, rndCard)
    end
    return shuffledDeck
end

function game.sortBy(property, cards)
    -- insertion sort
    local tempDeck = cards
    for i = 2, #tempDeck do
        local currentOrder = tempDeck[i][property]
        local current = tempDeck[i]
        local j = i - 1
        while (j >= 1 and currentOrder < tempDeck[j][property]) do
            tempDeck[j + 1] = tempDeck[j]
            j = j - 1
        end
        tempDeck[j + 1] = current
    end
    return tempDeck
end

function game.sortByX(cards)
    return game.sortBy("posx", cards)
end

function game.sortRank(cards)
    return game.sortBy("order", cards)
end

function game.sortSuit(cards)
    cards = game.sortRank(cards)
    local sdeck = { ["S"] = {}, ["D"] = {}, ["C"] = {}, ["H"] = {} }
    local sorted = {}
    for i, v in pairs(cards) do
        table.insert(sdeck[v.suit[1]], v)
    end
    for i, v in pairs({ "S", "D", "C", "H" }) do
        for k, h in pairs(sdeck[v]) do
            table.insert(sorted, h)
        end
    end
    -- cards = sorted
    return sorted
end

function game.sort(cards)
    if (vars.sortMode == "rank") then
        return game.sortRank(cards)
    end
    if (vars.sortMode == "suit") then
        return game.sortSuit(cards)
    end
end

function game.dealHand(shuffledDeck, cardsToDeal)
    if #shuffledDeck < cardsToDeal then
        for card in gen.all(shuffledDeck) do
            gen.add(vars.currentHand, card)
            gen.del(shuffledDeck, card)
        end
    else
        for x = 1, cardsToDeal do
            gen.add(vars.currentHand, shuffledDeck[1])
            gen.del(shuffledDeck, shuffledDeck[1])
        end
    end
    vars.currentHand = game.sort(vars.currentHand)
end

return game