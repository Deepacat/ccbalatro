local util = require("util")
local vars = require("vars")
local obsi = require("obsi2")

local game = {}

function game.distributeHand()
    local x = util.flr(vars.screenWidth / 2 + 1) - util.flr(#vars.currentHand * 3 / 2)
    local y = 14
    for card in util.all(vars.currentHand) do
        if card.selected then
            card:place(x, y - 1, 5)
        else
            card:place(x, y, 5)
        end
        x = x + card.width + 1
    end
end

function game.drawHand()
    if vars.initDraw then
        game.distributeHand()
        -- making initdraw false and not running distribute makes all cards render at 0,0 for some reason
        -- vars.initDraw = false
    end
    for i = 1, #vars.currentHand do
        vars.currentHand[i]:draw()
    end
end

-- called when mouse-down to
-- check if card picked up
function game.handCollDown()
    for card in util.all(vars.currentHand) do
        if card:moused() then
            -- card:pickup()
            card.drop_at = game.handCollUp
            return card
        end
    end
end

-- drop a dragged card or click
function game.handCollUp(self, px, py)
    local my = obsi.mouse.getY()
    if (self.pickedUp.moved) then
        --     if py < 50 or my > 102 then
        --         return
        --     end
        --     self.posx = px
        --     self.posy = py
        --     game.sortByX(vars.currentHand)
        --     game.distributeHand()
        -- else -- click, not drop
        --     game.selectHand(self)
        --     game.updateSelectedCards()
        return
    end
end

-- Checks if mouse is colliding with a button
function game.mouseCollCheck(sx, sy, sw, sh)
    local mx = obsi.mouse.getX()
    local my = obsi.mouse.getY()
    return mx >= sx and mx < sx + sw and
        my >= sy and my < sy + sh
end

function game.playBtnClicked()
    if game.mouseCollCheck(16, 17, 7, 2) and #vars.selectedCards > 0 and vars.handsLeft > 0 then
        -- sfx(sfx_play_btn_clicked)
        vars.handsLeft = vars.handsLeft - 1
        -- animation = cocreate(score_hand)
        game.scoreHand()
    end
end

function game.discardBtnClicked()
    if not game.mouseCollCheck(28, 17, 7, 2) then return end
    if #vars.selectedCards > 0 and vars.discardsLeft > 0 then
        -- sfx(sfx_discard_btn_clicked)
        for card in util.all(vars.selectedCards) do
            util.del(vars.currentHand, card)
        end
        game.dealHand(vars.currentDeck, vars.selectedCount)
        vars.selectedCards = {}
        -- vars.initDraw = false
        vars.selectedCount = 0
        vars.discardsLeft = vars.discardsLeft - 1
        -- error_message = ""
    end
end

function game.addMoney(i, card)
    if (i == 0) then return end
    vars.money = vars.money + i
    -- sfx(sfx_add_money)
    -- add_sparkle(35,card)
    -- pause(7)
end

function game.multiplyMult(i, card)
    if (i == 0) then return end
    vars.curMult = vars.curMult * i
    -- sfx(sfx_multiply_mult)
    -- add_sparkle(34,card)
    -- pause(7)
end

function game.addMult(i, card)
    if (i == 0) then return end
    vars.curMult = vars.curMult + i
    -- sfx(sfx_add_mult)
    -- add_sparkle(33,card)
    -- pause(5)
end

function game.addChips(i, card)
    if (i == 0) then return end
    vars.curChips = vars.curChips + i
    -- sfx(sfx_add_chips)
    -- add_sparkle(32,card)
    -- pause(5)
end

function game.finishScoringHand()
    if vars.currentScore >= (vars.blindGoal) then
        -- win_state()
        -- in_shop = true
    else
        for card in util.all(vars.selectedCards) do
            util.del(vars.currentHand, card)
        end
        vars.selectedCards = {}
        game.dealHand(vars.currentDeck, vars.selectedCount)
        vars.initDraw = true
        vars.selectedCount = 0
        vars.scoredCards = {}
        -- error_message = ""
        if vars.handsLeft == 0 then
            -- lose_state()
        end
    end
end

function game.scoreHand()
    -- pause(5) -- wait for sfx
    -- card are processed left-to-right
    game.sortByX(vars.scoredCards)
    -- Score cards
    for card in util.all(vars.scoredCards) do
        game.addChips(card.chips + card.effectChips, card)
        game.addMult(card.mult, card)
        -- for joker in all(joker_cards) do
        --     joker:card_effect(card)
        -- end
    end
    -- score_held_cards()
    -- score_jokers()
    vars.currentScore = vars.currentScore + (vars.curChips * vars.curMult)
    game.finishScoringHand()
    -- Reset
    vars.curChips = 0
    vars.curMult = 0
    vars.handTypeText = ""
end

function game.containsFlush(cards)
    local run_goal = 5
    -- if(has_joker("four fingers")) then run_goal=4 end
    if (#cards < run_goal) then return end
    local first = cards[1]
    local ct = 0
    for card in util.all(cards) do
        if (card:matches_suit(first)) then ct = ct + 1 end
        if (ct >= run_goal) then return true end
    end
    return false
end

function game.containsRoyal(cards)
    -- only called if straight is
    -- already detected, so just
    -- return false if any
    -- commoners present
    local royals = { 'A', 'K', 'Q', 'J', '10' }
    for c in util.all(cards) do
        if (not util.contains(royals, c.rank)) then return false end
    end
    return true
end

function game.containsStraight(cf)
    -- todo: implement shortcut joker
    local runGold = 5
    -- if(has_joker("four fingers"))run_goal=4
    if #vars.selectedCards < runGold then
        return false
    end
    local runLength = 0
    -- detect run
    for f in util.all(cf) do
        if f > 0 then
            runLength = runLength + 1
            if runLength >= runGold then
                return true
            end
        else
            runLength = 0
        end
    end
    -- special case for a,2,3,4,5
    if runLength == runGold - 1
        and cf[1] > 0 then
        return true
    end
    -- insufficient run
    return false
end

-- hand detection

-- collect card frequencies to
-- detect matches and runs.
-- indexed by card.order as a
-- numeric proxy for rank.
function game.cardFrequencies()
    local histogram = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    for card in util.all(vars.selectedCards) do
        histogram[card.order] = histogram[card.order] + 1
    end
    return histogram
end

function game.addAllCardsToScore(cards)
    for card in util.all(cards) do
        util.add(vars.scoredCards, card)
    end
end

function game.scoreCardsOfOrder(o)
    for card in util.all(vars.selectedCards) do
        if (card.order == o) then util.add(vars.scoredCards, card) end
    end
end

function game.scoreCardsOfCount(cf, qty)
    for i, q in pairs(cf) do
        if (q == qty) then game.scoreCardsOfOrder(i) end
    end
end

function game.getHighestSelected()
    local min_order = 99
    local result = nil
    for card in util.all(vars.selectedCards) do
        if card.order < min_order then
            result = card
            min_order = card.order
        end
    end
    return result
end

function game.checkHandType()
    vars.scoredCards = {}
    if #vars.selectedCards == 0 then
        vars.handTypeText = ""
        return "none"
    end
    local flush = false
    if #vars.selectedCards >= 4 then
        flush = game.containsFlush(vars.selectedCards)
    end
    local cf = game.cardFrequencies()
    if flush then
        game.addAllCardsToScore(vars.selectedCards)
        if util.count(cf, 5) > 0 then
            return "Flush Five"
        elseif util.count(cf, 3) > 0 and util.count(cf, 2) > 0 then
            return "Flush House"
        elseif game.containsStraight(cf) then
            if game.containsRoyal(vars.currentHand) then
                return "Royal Flush"
            else
                return "Straight Flush"
            end
        end
        return "Flush"
    end
    --non-flush decision tree
    if util.count(cf, 5) > 0 then
        game.addAllCardsToScore(vars.selectedCards)
        return "Five of a Kind"
    elseif util.count(cf, 4) > 0 then
        game.scoreCardsOfCount(cf, 4)
        return "Four of a Kind"
    elseif util.count(cf, 3) > 0 then
        game.scoreCardsOfCount(cf, 3)
        if util.count(cf, 2) > 0 then
            game.scoreCardsOfCount(cf, 2)
            return "Full House"
        end
        return "Three of a Kind"
    elseif game.containsStraight(cf) then
        game.addAllCardsToScore(vars.selectedCards)
        return "Straight"
    elseif util.count(cf, 2) > 0 then
        game.scoreCardsOfCount(cf, 2)
        if util.count(cf, 2) > 1 then
            return "Two Pair"
        end
        return "Pair"
    end
    -- high card is all that's left
    util.add(vars.scoredCards, game.getHighestSelected())
    return "High Card"
end

function game.updateSelectedCards()
    for card in util.all(vars.currentHand) do
        if card.selected and not util.contains(vars.selectedCards, card) then
            util.add(vars.selectedCards, card)
        elseif not card.selected and util.contains(vars.selectedCards, card) then
            util.del(vars.selectedCards, card)
        end
    end
    local handType = game.checkHandType()
    if handType ~= "none" then
        vars.handTypeText = handType
        vars.curChips = 0
        vars.curMult = 0
        vars.curChips = vars.curChips + vars.handTypes[handType].baseChips
        vars.curMult = vars.curMult + vars.handTypes[handType].baseMult
    end
end

function game.selectHand(card)
    if card.selected == false and vars.selectedCount < vars.maxSelected then
        card.selected = true
        vars.selectedCount = vars.selectedCount + 1
        card:place(card.posx, card.posy - 1, 5)
    elseif card.selected == true then
        card.selected = false
        vars.selectedCount = vars.selectedCount - 1
        card:place(card.posx, card.posy + 1, 5)
        --     if vars.selectedCount == 4 then error_message = "" end
        -- else
        --     sfx(sfx_error_message)
        --     error_message = "You can only select 5 \ncards at a time"
    end
end

function game.resetDeck()
    vars.currentDeck = vars.fullDeck
end

local itemObj = {
    type = "card",
    -- default size stuff
    width = 0,
    height = 0,
    -- resettable params
    selected = false,
    posx = 0,
    posy = 0,
    fromx = nil,
    fromy = nil,
    frames = 0,
    pickedUp = false
}

game.pickedUpItem = nil
function itemObj:new(obj)
    return setmetatable(obj, {
        __index = self
    })
end

function itemObj:place(x, y, frames)
    -- if util.max(0, frames) > 0 then
    self.fromx = self.posx
    self.fromy = self.posy
    -- self.frames = frames
    -- end
    self.posx = x
    self.posy = y
end

function itemObj:reset()
    self.selected = false
    -- self.pos_x = deck_sprite_pos_x
    -- self.pos_y = deck_sprite_pos_y
end

function itemObj:draw()
    if (game.pickedUpItem == self) then return end
    -- -- animation
    -- if self.frames > 0 then
    --     self.frames = self.frames - 1
    --     if self.frames == 0 then
    --         self.fromx = nil
    --         self.fromy = nil
    --     else
    --         self.fromx = self.fromx + (self.posx - self.fromx) / self.frames
    --         self.fromy = self.fromy + (self.posy - self.fromy) / self.frames
    --         self:drawAt(self.fromx, self.fromy)
    --         return
    --     end
    -- end

    -- no animation
    self:drawAt(self.posx, self.posy)
end

-- draw at absolute position
-- regardless of obj position
function itemObj:drawAt(x, y)
    -- spr(self.sprite_index, x, y)
end

function itemObj:moused(morex, morey)
    morex = util.min(morex) -- default 0
    morey = util.min(morey)
    return game.mouseCollCheck(
        self.posx,
        self.posy,
        self.width + morex,
        self.height + morey
    )
end

-- called when mouse is clicked
-- and held
function itemObj:pickup()
    local mx = obsi.mouse.getX()
    local my = obsi.mouse.getY()
    -- record start state of
    -- object and mouse
    self.pickedUp = {
        srcx = self.posx,
        srcy = self.posy,
        mx = mx,
        my = my,
        offx = mx - self.posx,
        offy = my - self.posy,
        moved = false
    }
    game.pickedUpItem = self
end

-- detect if the mouse moves
-- more than 1 pixel between
-- mouse_down and mouse_up
function itemObj:detect_moved()
    local mx = obsi.mouse.getX()
    local my = obsi.mouse.getY()
    if (not self.pickedUp) then return end
    if (self.pickedUp.moved) then return end
    if util.abs(mx - self.pickedUp.mx) > 1
        or util.abs(my - self.pickedUp.my) > 1
    then
        self.pickedUp.moved = true
    end
end

function itemObj:drop()
    -- local mx = obsi.mouse.getX()
    -- local my = obsi.mouse.getY()
    -- if (game.pickedUpItem ~= self) then return end
    -- if (not self.pickedUp) then return end
    -- self:dropAt(
    --     mx - self.pickedUp.offx,
    --     my - self.pickedUp.offy
    -- )
    -- self.pickedUp = nil
    -- game.pickedUpItem = nil
end

-- fallback: leave it where it lies
function itemObj:dropAt(px, py)
    self.posx = px
    self.posy = py
end

-- utility functions
local function doNothing() end

-- playing cards
local cardObj = itemObj:new({
    type = "card",
    bgtile = 15,
    height = 2,
    width = 2,
    effectChips = 0,
    mult = 0,
    posx = 0,
    posy = 0,
    whenHeldInHand = doNothing,
    whenHeldAtEnd = doNothing,
    effect = doNothing,
    cardEffect = doNothing
})

-- DEAR GOD OH MY PICO API
---@diagnostic disable-next-line: duplicate-set-field
function cardObj:drawAt(x, y)
    obsi.graphics.setForegroundColor(colors.white)
    obsi.graphics.rectangle("fill", x, y, self.width, self.height)
    obsi.graphics.write(tostring(self.rank), x, y, self.suit[3], colors.white)
    obsi.graphics.write(" " .. self.suit[2], x, y + 1, self.suit[3], colors.white)

    -- 	pal()
    -- 	rectfill(x-1,y-1,x-2+self.width,y-2+self.height,0)
    -- 	palt(11,true)
    -- 	pal(8,suit_colors[self.suit])
    -- 	spr(self.bgtile,x,y,1,2)
    -- 	-- overlay rank
    -- 	spr(self.sprite_index, x, y)
    -- 	-- if not wild, overlay suit
    --  if self.bgtile != 44 then
    -- 		spr(suit_sprites[self.suit],x,y+8)
    -- 	end
    -- 	pal()
end

function cardObj:drawAtMouse()
    local mx = obsi.mouse.getX()
    local my = obsi.mouse.getY()
    if (not self.pickedUp) then return end
    self:drawAt(
        mx - self.pickedUp.offx,
        my - self.pickedUp.offy
    )
end

-- rank moving
function cardObj:setRankByOrder(o)
    for r in util.all(vars.ranks) do
        if r.order == o then
            return self:setRank(r)
        end
    end
    assert(false) -- rank not found
end

function cardObj:setRank(r)
    self.rank = r.rank
    -- self.sprite_index = r.sprite_index
    self.order = r.order
    self.chips = r.baseChips
end

function cardObj:plusOrder(d)
    return ((self.order - d - 1) % 13) + 1
end

function cardObj:addRank(d)
    local newOrder = self:plusOrder(d)
    self:setRankByOrder(newOrder)
end

function game.hasJoker(name)
    for j in util.all(vars.heldJokers) do
        if (j.name == name) then return j end
    end
    return false
end

function cardObj:isFace()
    if (game.hasJoker('pareidolia')) then return true end
    return util.contains({ 'K', 'J', 'Q' }, self.rank)
end

function cardObj:matches_suit(other)
    -- 44=wild card
    if (other.bgtile == 44) then return true end
    -- compare normally
    return self:is_suit(other.suit)
end

function cardObj:is_suit(target)
    -- 44=wild card
    if (self.bgtile == 44) then return true end
    if game.hasJoker('smeared joker') then
        if target == 's' or target == 'C' then
            return self.suit == 'S' or self.suit == 'C'
        else
            return self.suit == 'D' or self.suit == 'H'
        end
    end
    return self.suit == target
end

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
            local cardInfo = cardObj:new({
                rank = vars.ranks[x].rank,
                suit = vars.suits[y],
                -- sprite_index = ranks[x].sprite_index,
                chips = vars.ranks[x].baseChips,
                order = vars.ranks[x].order,
            })
            util.add(tempBaseDeck, cardInfo)
        end
    end
    return tempBaseDeck
end

function game.shuffleDeck(deck)
    local copyDeck = {}
    for x = 1, #deck do
        util.add(copyDeck, deck[x])
    end
    local shuffledDeck = {}

    for x = 1, #copyDeck do
        local rndCard = util.rnd(copyDeck)
        util.add(shuffledDeck, rndCard)
        util.del(copyDeck, rndCard)
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
        for card in util.all(shuffledDeck) do
            util.add(vars.currentHand, card)
            util.del(shuffledDeck, card)
        end
    else
        for x = 1, cardsToDeal do
            util.add(vars.currentHand, shuffledDeck[1])
            util.del(shuffledDeck, shuffledDeck[1])
        end
    end
    vars.currentHand = game.sort(vars.currentHand)
end

function game.changeSortMode()
    if (vars.sortMode == "suit") then
        vars.sortMode = "rank"
    else
        vars.sortMode = "suit"
    end
    vars.currentHand = game.sort(vars.currentHand)
end

return game
