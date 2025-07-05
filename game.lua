local util = require("util")
local vars = require("vars")
local obsi = require("obsi2")

local game = {}

function game.distributeHand()
    local x = util.flr(vars.screenWidth / 2 + 1) - util.flr(#vars.currentHand * 3 / 2)
    local y = 14
    for card in util.all(vars.currentHand) do
        if card.selected then
            card:place(x, y - 1, 30)
        else
            card:place(x, y, 30)
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
            card.dropAt = game.handCollUp
            return card
        end
    end
end

-- called when mouse down to
-- check if joker clicked
function game.jokerCollDown()
    for joker in util.all(vars.heldJokers) do
        if game.mouseCollCheck(joker.posx, joker.posy, 3, 3) then
            return joker
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
        game.selectHand(self)
        game.updateSelectedCards()
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
        vars.animation = util.cocreate(game.scoreHand)
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

-- animations
function game.pause(frames)
    while frames > 0 do
        frames = frames - 1
        util.yield()
    end
end

function game.addMoney(i, card)
    if (i == 0) then return end
    vars.money = vars.money + i
    -- sfx(sfx_add_money)
    game.addSparkle("$" .. i, colors.white, colors.green, card)
    game.pause(20)
end

function game.multiplyMult(i, card)
    if (i == 0) then return end
    vars.curMult = vars.curMult * i
    -- sfx(sfx_multiply_mult)
    game.addSparkle("*" .. i, colors.white, colors.magenta, card)
    game.pause(15)
end

function game.addMult(i, card)
    if (i == 0) then return end
    vars.curMult = vars.curMult + i
    -- sfx(sfx_add_mult)
    game.addSparkle("x" .. i, colors.white, colors.red, card)
    game.pause(10)
end

function game.addChips(i, card)
    if (i == 0) then return end
    vars.curChips = vars.curChips + i
    -- sfx(sfx_add_chips)
    game.addSparkle("+" .. i, colors.white, colors.blue, card)
    game.pause(10)
end

-- sparkles
function game.addSparkle(text, fgcol, bgcol, source)
    if (source == nil or util.max(0, source.posy) < 1) then return end
    local function upperAdd(x)
        if x < vars.screenHeight / 2 then
            return x + 2
        end
        return x
    end
    util.add(vars.sparkles, {
        ix = source.posx,
        iy = upperAdd(source.posy),
        x = source.posx,
        y = upperAdd(source.posy),
        text = text,
        fgcol = fgcol,
        bgcol = bgcol,
        -- spriteIndex = spriteIndex,
        frames = 15
    })
end

function game.drawSparkles()
    for i = #vars.sparkles, 1, -1 do
        local sp = vars.sparkles[i]
        local function dir(val, offset)
            if sp.iy > vars.screenHeight / 2 then
                return val - offset
            else
                return val + offset
            end
        end
        obsi.graphics.write(sp.text, dir(sp.x, 1), dir(sp.y, 1), sp.fgcol, sp.bgcol)
        if sp.frames > 0 then
            sp.frames = sp.frames - 1
            sp.y = dir(sp.y, 0.3)
        else
            util.deli(vars.sparkles, i)
        end
    end
end

function game.makeHandTypesCopy()
    for k, v in pairs(vars.handTypes) do
        local newTable = {}
        for subK, subV in pairs(v) do
            newTable[subK] = subV
        end
        vars.handTypesCopy[k] = newTable
    end
end

function game.makeShopStock()
    vars.shopOptions = {}
    local shopTypes = { util.rnd(game.special_cards["Planets"]), game.findRandomUniqueShopOption("Jokers",
        vars.heldJokers), game.findRandomUniqueShopOption("Tarots", vars.heldConsumables) }
    for i = 1, 4, 1 do
        util.add(vars.shopOptions, util.rnd(shopTypes))
    end
end

function game.winState()
    vars.gameState = "shop"
    for card in util.all(vars.currentHand) do
        card:whenHeldAtEnd()
        game.pause(1)
    end
    -- error_message = ""
    -- update_round_and_score()	
    -- cash_out_interest()
    -- cash_out_money_earned_per_round()
    -- cash_out_money_earned_per_hand_remaining()
    -- add_cards_to_shop()
    if vars.blind == 3 then
        vars.ante = vars.ante + 1
        vars.blind = 1
    else
        vars.blind = vars.blind + 1
    end
    vars.selectedCount = 0
    vars.scoredCards = {}
    vars.handsLeft = vars.maxHands
    vars.discardsLeft = vars.maxDiscards
    vars.currentDeck = game.shuffleDeck(vars.baseDeck)
    -- reset_card_params()
    vars.selectedCards = {}
    vars.currentHand = {}
    vars.initDraw = true
    game.dealHand(vars.currentDeck, vars.handSize)
end

function game.loseState()
    vars.baseDeck = game.createBaseDeck()
    util.clear(vars.heldConsumables)
    util.clear(vars.heldJokers)
    vars.ante = 1
    vars.blindGoal = 300
    vars.selectedCount = 0
    vars.scoredCards = {}
    vars.handsLeft = vars.maxHands
    vars.discardsLeft = vars.maxDiscards
    vars.currentScore = 0
    -- reroll_price = 5
    vars.currentDeck = game.shuffleDeck(vars.baseDeck)
    -- reset_card_params()
    vars.selectedCards = {}
    vars.scoredCards = {}
    vars.currentHand = {}
    vars.handTypes = vars.handTypesCopy
    vars.initDraw = true
    game.dealHand(vars.currentDeck, vars.handSize)
    vars.money = 4
end

function game.levelUpHandType(handTypeName, multAmount, chipAmount)
    local ht = vars.handTypes[handTypeName]
    ht.baseMult = ht.baseMult + multAmount
    ht.baseChips = ht.baseChips + chipAmount
    ht.level = ht.level + 1
end

function game.cashOutInterest()
    if vars.money >= 25 then
        game.addMoney(5, nil)
    elseif vars.money >= 5 then
        local interest = util.flr(vars.money / 5)
        game.addMoney(interest, nil)
    end
end

function game.finishScoringHand()
    game.pause(30)
    if vars.currentScore >= (vars.blindGoal) then
        game.pause(30)
        game.winState()
        -- TEMPORARY LOSE RESTART UNTIL SHOP MADE
        -- game.loseState()
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
            game.pause(30)
            game.loseState()
        end
    end
end

function game.scoreHand()
    game.pause(5)
    -- card are processed left-to-right
    game.sortByX(vars.scoredCards)
    -- Score cards
    for card in util.all(vars.scoredCards) do
        game.addChips(card.chips + card.effectChips, card)
        game.addMult(card.mult, card)
        for joker in util.all(vars.heldJokers) do
            joker:cardEffect(card)
        end
    end
    -- score_held_cards()
    game.scoreJokers()
    vars.currentScore = vars.currentScore + (vars.curChips * vars.curMult)
    game.finishScoringHand()
    -- Reset
    vars.curChips = 0
    vars.curMult = 0
    vars.handTypeText = ""
    game.pause(60)
end

function game.scoreJokers()
    for joker in util.all(vars.heldJokers) do
        joker:effect()
        game.pause(10)
    end
end

function game.containsFlush(cards)
    local runGoal = 5
    if (game.hasJoker("four fingers")) then runGoal = 4 end
    if (#cards < runGoal) then return false end
    local first = cards[1]
    local ct = 0
    for card in util.all(cards) do
        if (card:matchesSuit(first)) then ct = ct + 1 end
        if (ct >= runGoal) then return true end
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
    local runGoal = 5
    if (game.hasJoker("four fingers")) then runGoal = 4 end
    if #vars.selectedCards < runGoal then
        return false
    end
    local runLength = 0
    -- detect run
    for f in util.all(cf) do
        if f > 0 then
            runLength = runLength + 1
            if runLength >= runGoal then
                return true
            end
        else
            runLength = 0
        end
    end
    -- special case for a,2,3,4,5
    if runLength == runGoal - 1
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
        return "None"
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
    vars.handType = game.checkHandType()
    if vars.handType ~= "None" then
        vars.handTypeText = vars.handType
        vars.curChips = 0
        vars.curMult = 0
        vars.curChips = vars.curChips + vars.handTypes[vars.handType].baseChips
        vars.curMult = vars.curMult + vars.handTypes[vars.handType].baseMult
    end
end

function game.deselectAllCards()
    for card in util.all(vars.selectedCards) do
        game.selectHand(card)
    end
    vars.selectedCards = {}
    vars.curChips = 0
    vars.curMult = 0
    vars.handTypeText = ""
end

function game.drawTooltips(x, y)
    -- if game.pickedUpItem then
    --     return -- none of these other
    --     -- cards are targets.
    -- end
    for joker in util.all(vars.heldJokers) do
        if game.mouseCollCheck(joker.posx, joker.posy, 3, 3) then
            joker:describe()
            return true
        end
    end
    for tarot in util.all(vars.heldConsumables) do
        if game.mouseCollCheck(tarot.posx, tarot.posy, 3, 3) then
            tarot:describe()
            return true
        end
    end
    -- if in_shop then
    --     for special_card in all(shop_options) do
    --         if mouse_sprite_collision(special_card.posx, special_card.posy, card_width, card_height * 2) then
    --             special_card:describe()
    --             return
    --         end
    --     end
    -- end
    return false
end

function game.selectHand(card)
    if card.selected == false and vars.selectedCount < vars.maxSelected then
        card.selected = true
        vars.selectedCount = vars.selectedCount + 1
        card:place(card.posx, card.posy - 1, 0)
    elseif card.selected == true then
        card.selected = false
        vars.selectedCount = vars.selectedCount - 1
        card:place(card.posx, card.posy + 1, 0)
        -- if vars.selectedCount == 4 then error_message = "" end
        -- else
        -- sfx(sfx_error_message)
        --     error_message = "You can only select 5 \ncards at a time"
    end
end

function game.selectJoker(joker)
    if vars.selectedJoker == joker then
        vars.selectedJoker = nil
    else
        vars.selectedJoker = joker
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
    if util.max(0, frames) > 0 then
        self.fromx = self.posx
        self.fromy = self.posy
        self.frames = frames
    end
    self.posx = x
    self.posy = y
end

function itemObj:reset()
    self.selected = false
    self.posx = 49
    self.posy = 14
end

function itemObj:draw()
    if (game.pickedUpItem == self) then return end
    -- animation
    if self.frames > 0 then
        self.frames = self.frames - 1
        if self.frames == 0 then
            self.fromx = nil
            self.fromy = nil
        else
            self.fromx = self.fromx + (self.posx - self.fromx) / self.frames
            self.fromy = self.fromy + (self.posy - self.fromy) / self.frames
            self:drawAt(self.fromx, self.fromy)
            return
        end
    end

    -- no animation
    self:drawAt(self.posx, self.posy)
end

-- draw at absolute position
-- regardless of obj position
function itemObj:drawAt(x, y)
    -- spr(self.spriteIndex, x, y)
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
function itemObj:detectMoved()
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
    posx = 49,
    posy = 14,
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
    -- 	spr(self.spriteIndex, x, y)
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
    -- self.spriteIndex = r.spriteIndex
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

function cardObj:matchesSuit(other)
    -- 44=wild card
    if (other.bgtile == 44) then return true end
    -- compare normally
    return self:isSuit(other.suit[1])
end

function cardObj:isSuit(target)
    -- 44=wild card
    if (self.bgtile == 44) then return true end
    if game.hasJoker('smeared joker') then
        if target == 'S' or target == 'C' then
            return self.suit[1] == 'S' or self.suit[1] == 'C'
        end
        if target == 'D' or target == 'H' then
            return self.suit[1] == 'D' or self.suit[1] == 'H'
        end
    end
    return self.suit[1] == target
end

-- special cards
local specialObj = itemObj:new({})

-- description shown when mouse
-- is over the object
function specialObj:describe()
    if type(self.description) == "string" then
        vars.tooltip[1] = self.name
        vars.tooltip[2] = self.type
        vars.tooltip[3] = self.description
    else
        vars.tooltip[1] = self.name
        vars.tooltip[2] = self.type
        vars.tooltip[3] = self:description()
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function specialObj:drawAt(x, y)
    -- -- draw icon obviously
    -- spr(self.spriteIndex, x, y)
    -- -- draw sell icon if owned
    -- if in_shop and contains(shop_options,self) then
    -- 	spr(btn_buy_spriteIndex, x , y+self.height)
    -- 	print("$"..self.price, x + self.width, y + self.height + 1, 7)
    -- elseif contains(self.ref,self) then
    -- 	spr(btn_sell_spriteIndex, x - self.width, y)
    -- 	print("$"..calculate_sell_price(self.price), x - card_width, y + card_height + 1, 7)
    -- 	if self.usable then
    -- 		spr(btn_use_spriteIndex, x, y + self.height)
    -- 	end
    -- end
end

local jokerObj = specialObj:new({
    type = "Joker",
    bg = 0,
    fg = 7,
    ref = vars.heldJokers,
    effect = function(self) end,
    cardEffect = function(self, card) end
})
local tarotObj = specialObj:new({
    type = "Tarot",
    bg = 15,
    fg = 1,
    ref = vars.heldConsumables,
    usable = true
})
local planetObj = specialObj:new({
    type = "Planet",
    bg = 12,
    fg = 7,
    effect = function(self)
        game(self.hand, self.mult, self.chips)
    end,
    description = function(self)
        return "levels up " .. self.hand ..
            "\nadds +" .. tostring(self.mult) ..
            " mult and +" .. tostring(self.chips) ..
            " chips"
    end
})

-- common function to add an effect
-- to cards.  pass in the maximum
-- number of cards and a function
-- that modifies one individual card.
function game.cardEnhancement(qty, body)
    return function(self)
        -- consider checking for 0 if
        -- it's no longer handled elsewhere
        if #vars.selectedCards > qty then
            -- sfx(sfx_error_message)
            -- error_message = "too many cards selected"
            return
        end
        for card in util.all(vars.selectedCards) do
            card.selected = false
            card.posy = card.posy + 10
            body(card, self)
        end
        vars.selectedCount = 0
        util.del(vars.heldConsumables, self)
        vars.initDraw = true
    end
end

-- all change-suit tarots are the same
function game.suitChange(newSuit)
    return game.cardEnhancement(3, function(card)
        card.suit[1] = newSuit
    end)
end

-- shop inventory
game.specialCards = {
    Jokers = {
        jokerObj:new({
            name = "joker",
            price = 2,
            effect = function(self)
                game.addMult(4, self)
            end,
            spriteIndex = 128,
            description = "+4 mult"
        }),
        jokerObj:new({
            name = "Add 8 Mult",
            price = 3,
            effect = function(self)
                game.addMult(8, self)
            end,
            spriteIndex = 129,
            description = "+8 mult"
        }),
        jokerObj:new({
            name = "raised fist",
            price = 3,
            effect = function(self)
                local minRank = 99
                for card in util.all(vars.currentHand) do
                    if (not card.selected) then minRank = util.min(minRank, card.chips) end
                end
                game.addMult(2 * minRank, self)
            end,
            spriteIndex = 130,
            description = "adds double the rank of lowest\nranked card held in hand\nto mult"
        }),
        jokerObj:new({
            name = "Add Random Mult",
            price = 4,
            effect = function(self)
                game.addMult(util.flr(util.rnd(25)), self)
            end,
            -- spriteIndex = 131,
            description = "adds a random amount of mult.\nlowest being 0, highest being 25",
        }),
        jokerObj:new({
            name = "Times 1.5 Mult",
            price = 6,
            effect = function(self)
                game.multiplyMult(1.5, self)
            end,
            spriteIndex = 132,
            description = "Multiplies your mult by 1.5",
        }),
        jokerObj:new({
            name = "photograph",
            price = 5,
            cardAffected = nil,
            cardEffect = function(self, card)
                if self.cardAffected == nil and card:isFace() then
                    self.cardAffected = card
                end
                if self.cardAffected == card then
                    game.multiplyMult(2, card)
                    game.addSparkle("*2", colors.white, colors.pink, self)
                end
            end,
            effect = function(self)
                self.cardAffected = nil
            end,
            spriteIndex = 133,
            description = "first played face card gives\nx2 mult when scored",
        }),
        jokerObj:new({
            name = "Times 3 Mult",
            price = 8,
            effect = function(self)
                game.multiplyMult(3, self)
            end,
            spriteIndex = 134,
            description = "Multiplies your mult by 3",
        }),
        jokerObj:new({
            name = "odd todd",
            price = 4,
            cardEffect = function(self, card)
                if (util.contains({ 'A', '3', '5', '7', '9' }, card.rank)) then
                    game.addChips(31, card)
                end
            end,
            spriteIndex = 140,
            description = "adds 31 chips for each card with odd rank",
        }),
        jokerObj:new({
            name = "scary face",
            price = 4,
            cardEffect = function(self, card)
                if card:isFace() then
                    game.addChips(30, card)
                end
            end,
            spriteIndex = 142,
            description = "played face cards give +30 \nchips when scored"
        }),
        jokerObj:new({
            name = "scholar",
            price = 4,
            cardEffect = function(self, card)
                if card.rank == 'A' then
                    game.addChips(20, card)
                    game.addChips(4, card)
                end
            end,
            spriteIndex = 141,
            description = "played aces give +20 chips\nand +4 mult when scored"
        }),
        jokerObj:new({
            name = "even steven",
            price = 4,
            cardEffect = function(self, card)
                if util.contains({ '2', '4', '6', '8', '10' }, card.rank) then
                    game.addMult(4, card)
                end
            end,
            spriteIndex = 128,
            description = "+4 mult for cards with even-numbered rank"
        }),
        jokerObj:new({
            name = "gluttonous joker",
            price = 5,
            cardEffect = function(self, card)
                if card:isSuit('C') then
                    game.addMult(3, card)
                end
            end,
            spriteIndex = 179,
            description = "played cards with club suit\ngive +3 mult when scored"
        }),
        jokerObj:new({
            name = "lusty joker",
            price = 5,
            cardEffect = function(self, card)
                if card:isSuit('H') then
                    game.addMult(3, card)
                end
            end,
            spriteIndex = 177,
            description = "played cards with heart suit\ngive +3 mult when scored"
        }),
        jokerObj:new({
            name = "wrathful joker",
            price = 5,
            cardEffect = function(self, card)
                if card:isSuit('S') then
                    game.addMult(3, card)
                end
            end,
            spriteIndex = 180,
            description = "played cards with spade suit\ngive +3 mult when scored"
        }),
        jokerObj:new({
            name = "greedy joker",
            price = 5,
            cardEffect = function(self, card)
                if card:isSuit('D') then
                    game.addMult(3, card)
                end
            end,
            spriteIndex = 178,
            description = "played cards with diamond suit\ngive +3 mult when scored"
        }),
        jokerObj:new({
            name = "Add 60 Chips",
            price = 3,
            effect = function(self)
                game.addChips(60, self)
            end,
            spriteIndex = 136,
            description = "Adds 60 to your chips",
        }),
        jokerObj:new({
            name = "Add 90 Chips",
            price = 4,
            effect = function(self)
                game.addChips(90, self)
            end,
            spriteIndex = 137,
            description = "Adds 90 to your chips",
        }),
        jokerObj:new({
            name = "Add Random Chips",
            price = 5,
            effect = function(self)
                local chip_options = {}
                local step = 10
                local amount = 0
                while (amount <= 150) do
                    util.add(chip_options, amount)
                    amount = amount + step
                end
                game.addChips(util.rnd(chip_options), self)
            end,
            spriteIndex = 138,
            description = "adds a random amount of chips.\nlowest being 0, highest being 150",
        }),
        jokerObj:new({
            name = "pareidolia",
            price = 5,
            -- effect in card_obj:isFace
            spriteIndex = 182,
            description = "all cards count as face cards"
        }),
        jokerObj:new({
            name = "smeared joker",
            price = 7,
            -- effect in card_obj:isSuit
            spriteIndex = 181,
            description = "clubs and spades are the same suit.\nhearts and diamonds are the same suit."
        }),
        jokerObj:new({
            name = "four fingers",
            price = 7,
            -- effect in contains_flush
            spriteIndex = 183,
            description = "all flushes and straights can\nbe made with 4 cards."
        }),
    },
    Planets = {
        planetObj:new({
            name = "king neptune",
            price = 5,
            hand = "royal flush",
            chips = 50,
            mult = 5,
            spriteIndex = 153,
        }),
        planetObj:new({
            name = "neptune",
            price = 5,
            hand = "straight flush",
            chips = 40,
            mult = 4,
            spriteIndex = 152,
        }),
        planetObj:new({
            name = "mars",
            price = 4,
            hand = "four of a kind",
            chips = 30,
            mult = 3,
            spriteIndex = 151,
        }),
        planetObj:new({
            name = "earth",
            price = 3,
            hand = "full house",
            chips = 25,
            mult = 2,
            spriteIndex = 150,
        }),
        planetObj:new({
            name = "jupiter",
            price = 3,
            hand = "flush",
            chips = 15,
            mult = 2,
            spriteIndex = 149,
        }),
        planetObj:new({
            name = "saturn",
            price = 3,
            hand = "straight",
            chips = 30,
            mult = 3,
            spriteIndex = 148,
        }),
        planetObj:new({
            name = "venus",
            price = 2,
            hand = "three of a kind",
            chips = 20,
            mult = 2,
            spriteIndex = 147,
        }),
        planetObj:new({
            name = "uranus",
            price = 2,
            hand = "two pair",
            chips = 20,
            mult = 1,
            spriteIndex = 146,
        }),
        planetObj:new({
            name = "mercury",
            price = 1,
            hand = "pair",
            chips = 15,
            mult = 1,
            spriteIndex = 145,
        }),
        planetObj:new({
            name = "pluto",
            price = 1,
            hand = "high card",
            chips = 10,
            mult = 1,
            spriteIndex = 144,
        })
    },
    Tarots = {
        tarotObj:new({
            name = "the devil",
            price = 2,
            effect = game.cardEnhancement(1, function(card, self)
                card.bgtile = 45
                card.whenHeldAtEnd = doNothing
                card.whenHeldAtEnd = function(c)
                    game.addMoney(3, c)
                end
            end),
            spriteIndex = 169,
            description = "converts 1 card into a\ngold card, which grants $3 if\ncard is in hand at end of round",
        }),
        tarotObj:new({
            name = "the chariot",
            price = 2,
            effect = game.cardEnhancement(1, function(card, self)
                card.bgtile = 46
                card.whenHeldInHand = function(c)
                    game.multiplyMult(1.5, c)
                end
                card.whenHeldAtEnd = doNothing
            end),
            spriteIndex = 170,
            description = "converts 1 card into a\nsteel card, which grants x1.5 mult \nif card is left in hand",
        }),
        tarotObj:new({
            name = "the lovers",
            price = 2,
            effect = game.cardEnhancement(1, function(card, self)
                card.bgtile = 44
                card.whenHeldInHand = doNothing
                card.whenHeldAtEnd = doNothing
            end),
            spriteIndex = 169,
            description = "converts 1 card into a\nwild card, which matches\nevery suit",
        }),
        tarotObj:new({
            name = "strength",
            price = 2,
            effect = game.cardEnhancement(2, function(card, self)
                card:addRank(1)
                game.sortRank(vars.currentHand)
            end),
            spriteIndex = 160,
            description = "increases the rank of two\nselected cards by 1",
        }),
        tarotObj:new({
            name = "the sun",
            price = 2,
            effect = game.suitChange("H"),
            spriteIndex = 161,
            description = "changes the suit of 3 selected \ncards to hearts",
        }),
        tarotObj:new({
            name = "the star",
            price = 2,
            effect = game.suitChange("D"),
            spriteIndex = 162,
            description = "changes the suit of 3 selected \ncards to diamonds",
        }),
        tarotObj:new({
            name = "the moon",
            price = 2,
            effect = game.suitChange("C"),
            spriteIndex = 163,
            description = "changes the suit of 3 selected \ncards to clubs",
        }),
        tarotObj:new({
            name = "the world",
            price = 2,
            effect = game.suitChange("S"),
            spriteIndex = 164,
            description = "changes the suit of 3 selected \ncards to spades",
        }),
        tarotObj:new({
            name = "the empress",
            price = 2,
            effect = game.cardEnhancement(2, function(card, self)
                card.bgtile = 14
                card.effect_chips = 0
                card.mult = 4
                card.whenHeldInHand = doNothing
            end),
            spriteIndex = 165,
            description = "causes up to two cards to add\n4 mult when scored",
        }),
        tarotObj:new({
            name = "the hierophant",
            price = 2,
            effect = game.cardEnhancement(2, function(card, self)
                card.bgtile = 13
                card.effect_chips = 30
                card.mult = 0
                card.whenHeldInHand = doNothing
                card.whenHeldAtEnd = doNothing
            end),
            spriteIndex = 166,
            description = "causes up to two cards to add\n30 chips when scored",
        }),
        tarotObj:new({
            name = "the hermit",
            price = 4,
            effect = function(tarot)
                if vars.money >= 20 then
                    game.addMoney(20, tarot)
                else
                    game.addMoney(vars.money, tarot)
                end
            end,
            spriteIndex = 167,
            description = "Multiplies your money by\n2 with the max being 20",
        }),
        tarotObj:new({
            name = "the hanged man",
            price = 2,
            effect = function(tarot)
                if #vars.selectedCards <= 2 then
                    for card in util.all(vars.selectedCards) do
                        util.del(vars.baseDeck, card)
                    end
                    vars.currentHand = {}
                    game.dealHand(vars.currentDeck, #vars.selectedCards)
                    vars.selectedCount = 0
                    util.del(vars.heldConsumables, tarot)
                    vars.initDraw = true
                    game.sortRank(vars.currentHand)
                    vars.selectedCards = {}
                    vars.handTypeText = ""
                else
                    -- sfx(sfx_error_message)
                    -- error_message = "Can only use this\n tarot card with 2 cards"
                end
            end,
            spriteIndex = 168,
            description = "Deletes two selected\ncards from the deck",
        })
    }
}

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
                -- spriteIndex = ranks[x].spriteIndex,
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

function game.getSpecialCardByName(name, type)
    for specialCardType, v in pairs(game.specialCards) do
        if specialCardType == type then
            for card in util.all(v) do
                if card.name == name then
                    return card
                end
            end
        end
    end
end

function game.changeToSuit(suit, tarot)
    if #vars.selectedCards <= 3 then
        for card in util.all(vars.selectedCards) do
            card.suit[1] = suit
            card.selected = false
            card.posy = card.posy + 10
        end
        vars.selectedCount = 0
        util.del(vars.heldConsumables, tarot)
    else
        -- sfx(sfx_error_message)
        -- error_message = "Can only use this\n tarot card with 3 cards"
    end
end

function game.findRandomUniqueShopOption(specialCardType, tableToCheck)
    local unique_table = {}
    for card in util.all(game.specialCards[specialCardType]) do
        if not util.contains(tableToCheck, card) then
            util.add(unique_table, card)
        end
    end
    return util.rnd(unique_table)
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
