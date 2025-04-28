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
            -- card.drop_at = game.handCollUp
            return card
        end
    end
end

-- drop a dragged card or click
function game.handCollUp(self, px, py)
    local my = obsi.mouse.getY()
    if (self.pickedUp.moved) then
        if py < 50 or my > 102 then
            return
        end
        self.posx = px
        self.posy = py
        game.sortByX(vars.currentHand)
        game.distributeHand()
    else -- click, not drop
        -- select_hand(self)
        -- update_selected_cards()
    end
end

-- Checks if mouse is colliding with a button
function game.mouseCollCheck(sx, sy, sw, sh)
    local mx = obsi.mouse.getX()
    local my = obsi.mouse.getY()
    return mx >= sx and mx < sx + sw and
        my >= sy and my < sy + sh
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
    self.frames = frames
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
    local mx = obsi.mouse.getX()
    local my = obsi.mouse.getY()
    if (game.pickedUpItem ~= self) then return end
    if (not self.pickedUp) then return end
    self:dropAt(
        mx - self.pickedUp.offx,
        my - self.pickedUp.offy
    )
    self.pickedUp = nil
    game.pickedUpItem = nil
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

-- function cardObj:reset()
-- 	self.selected=false
-- 	self.pos_x=0
-- 	self.pos_y=0
-- end

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
