local obsi = require("obsi2")

local vars = {}

vars.screenWidth, vars.screenHeight = term.getSize()

local monitor = peripheral.find("monitor")

if monitor then
    vars.screenWidth, vars.screenHeight = monitor.getSize()
end

-- vars.seed = math.randomseed(42)


vars.debugPrint = {}
vars.tooltip = {}
vars.tooltip[3] = ""

-- game
vars.gameState = "blind"
vars.initDraw = true
vars.blind = 1
vars.ante = 1
vars.money = 4
vars.blindGoal = 300
vars.curChips = 0
vars.curMult = 0
vars.currentScore = 0
vars.sparkles = {}

-- cards
vars.handSize = 8
vars.handsLeft = 4
vars.discardsLeft = 30
vars.maxHands = 4
vars.maxSelected = 5
vars.selectedCount = 0
vars.maxDiscards = 3

-- Jokers
vars.currentMaxJokers = 5
vars.currentMaxConsumables = 2
vars.heldJokers = {}
vars.heldConsumables = {}
vars.selectedJoker = nil

-- Game hand
vars.handTypeText = ""
vars.currentHand = {}
vars.selectedCards = {}
vars.sortMode = "rank"
vars.scoredCards = {}

-- Card props
vars.ranks = {
    { rank = 'A', baseChips = 11 }, { rank = 'K', baseChips = 10 }, { rank = 'Q', baseChips = 10 },
    { rank = 'J', baseChips = 10 }, { rank = '10', baseChips = 10 }, { rank = '9', baseChips = 9 },
    { rank = '8', baseChips = 8 }, { rank = '7', baseChips = 7 }, { rank = '6', baseChips = 6 },
    { rank = '5', baseChips = 5 }, { rank = '4', baseChips = 4 }, { rank = '3', baseChips = 3 },
    { rank = '2', baseChips = 2 },
}
vars.suits = { { 'H', '\3', colors.red }, { 'D', '\4', colors.orange }, { 'C', '\5', colors.blue }, { 'S', '\6', colors.black } }

-- Deck
vars.fullDeck = {
    "1H", "2H", "3H", "4H", "5H", "6H", "7H", "8H", "9H", "JH", "KH", "QH", "AH",
    "1D", "2D", "3D", "4D", "5D", "6D", "7D", "8D", "9D", "JD", "KD", "QD", "AD",
    "1S", "2S", "3S", "4S", "5S", "6S", "7S", "8S", "9S", "JS", "KS", "QS", "AS",
    "1C", "2C", "3C", "4C", "5C", "6C", "7C", "8C", "9C", "JC", "KC", "QC", "AC",
}
vars.currentDeck = {}
vars.baseDeck = {}
vars.handTypes = {
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
vars.handTypesCopy = {}

return vars
