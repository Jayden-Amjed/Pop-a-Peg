-- Original run equipment. Trigger thresholds and prices are tuning data.
local Catalog = {
    Items = {},
    Perks = {},
    ItemIds = {},
    PerkIds = {},
    MaxLevel = 5,
    Evolutions = {},
    EvolvedIds = {},
    StarterIds = {
        "tap_driver",
        "split_prism",
        "wall_meter",
        "landing_fund",
        "survey_lens",
        "resonator",
        "compass",
        "seed_bank",
    },
    TierOrder = { "common", "uncommon", "rare", "legendary" },
    Tiers = {
        common = { name = "Common", rank = 1, weight = 60, color = { 147, 221, 190 } },
        uncommon = { name = "Uncommon", rank = 2, weight = 28, color = { 89, 205, 244 } },
        rare = { name = "Rare", rank = 3, weight = 10, color = { 111, 147, 255 } },
        legendary = { name = "Legendary", rank = 4, weight = 2, color = { 255, 201, 95 } },
    },
}

local function item(id, name, price, event, every, effect, description, triggerText, rarity)
    Catalog.Items[id] = {
        id = id,
        name = name,
        price = price,
        trigger = { event = event, every = every },
        effect = effect,
        description = description,
        triggerText = triggerText,
        rarity = rarity or "common",
        color = rarity == "rare" and { 182, 135, 255 } or { 78, 210, 202 },
    }
    table.insert(Catalog.ItemIds, id)
end

item(
    "tap_driver",
    "Tap Driver",
    4,
    "pop",
    6,
    "pop",
    "Pop a random peg. Upgrade: pop two.",
    "Every 6 pops"
)
item(
    "split_prism",
    "Split Prism",
    6,
    "pop",
    9,
    "double",
    "Double a random peg. Upgrade: double two.",
    "Every 9 pops"
)
item(
    "wall_meter",
    "Wall Meter",
    4,
    "wall",
    2,
    "wallScore",
    "Score 8% of the round quota per level.",
    "Every 2 wall hits"
)
item(
    "clockwork",
    "Clockwork",
    7,
    "time",
    1.5,
    "pop",
    "Pop a random peg. Upgrade: pop two.",
    "Every 1.5 seconds alive"
)
item(
    "burst_capsule",
    "Burst Capsule",
    6,
    "pop",
    11,
    "burst",
    "Pop one peg and its two nearest neighbors. Upgrade: five pegs.",
    "Every 11 pops"
)
item(
    "relay",
    "Relay",
    6,
    "pop",
    13,
    "right",
    "Activate the next occupied slot to the right. Upgrade: twice.",
    "Every 13 pops"
)
item(
    "landing_fund",
    "Landing Fund",
    4,
    "drain",
    1,
    "drainScore",
    "Score 15% of the round quota per level on natural drain.",
    "On ball drain"
)
item(
    "survey_lens",
    "Survey Lens",
    5,
    "first",
    1,
    "firstScore",
    "Score the highest peg value twice. Upgrade: four times.",
    "On first peg hit"
)
item(
    "gain_dial",
    "Gain Dial",
    8,
    "pop",
    15,
    "multiply",
    "Increase current score by 15%. Upgrade: 30%.",
    "Every 15 pops",
    "rare"
)
item(
    "soft_saw",
    "Soft Saw",
    5,
    "time",
    2,
    "halve",
    "Halve two pegs without scoring. Upgrade: four pegs.",
    "Every 2 seconds alive"
)
item(
    "balance_scale",
    "Balance Scale",
    5,
    "halve",
    2,
    "halfScore",
    "Score four times the lowest peg value. Upgrade: eight times.",
    "Every 2 unscored halves"
)
item(
    "resonator",
    "Resonator",
    7,
    "double",
    3,
    "pop",
    "Pop a random peg. Upgrade: pop two.",
    "Every 3 doubles"
)
item(
    "echo_plate",
    "Echo Plate",
    7,
    "pop",
    12,
    "left",
    "Activate the previous occupied slot. Upgrade: twice.",
    "Every 12 pops",
    "rare"
)
item(
    "growth_array",
    "Growth Array",
    10,
    "pop",
    25,
    "doubleMany",
    "Double four pegs. Upgrade: eight pegs.",
    "Every 25 pops",
    "rare"
)
item(
    "quota_bonus",
    "Quota Bonus",
    5,
    "goal",
    1,
    "goalScore",
    "Score 5% of the round quota per level on each restock earned.",
    "On each quota crossed"
)
item(
    "spring_coil",
    "Spring Coil",
    5,
    "wall",
    3,
    "double",
    "Double a random peg. Upgrade: double two.",
    "Every 3 wall hits"
)
item(
    "pulse_cell",
    "Pulse Cell",
    4,
    "time",
    1,
    "pulseScore",
    "Score 3% of the round quota per level.",
    "Every second alive"
)
item(
    "compass",
    "Compass",
    6,
    "first",
    1,
    "highestPop",
    "Pop the highest peg once. Upgrade: twice.",
    "On first peg hit"
)
item(
    "seed_bank",
    "Seed Bank",
    6,
    "drain",
    1,
    "bankDoubleMany",
    "Double four pegs. On natural drain, also seed four distinct pegs for the next shot.",
    "On ball drain"
)
item(
    "encore",
    "Encore",
    10,
    "drain",
    1,
    "all",
    "Activate every other item once. Upgrade: twice.",
    "On ball drain",
    "rare"
)

item(
    "goldfish",
    "Goldfish",
    6,
    "pop",
    6,
    "lowestDouble",
    "Double the lowest live peg. Upgrade: double two lowest pegs in sequence.",
    "Every 6 pops"
)
item(
    "fishbowl",
    "Fishbowl",
    8,
    "double",
    3,
    "highestPop",
    "Pop the highest peg. Upgrade: pop it twice. Pair with Goldfish to turn growth into points.",
    "Every 3 doubles"
)

local displayNames = {
    split_prism = "Sun Prism",
    resonator = "Reef Chime",
    soft_saw = "Soft Current",
    balance_scale = "Pearl Scale",
    relay = "Current Relay",
    echo_plate = "Echo Shell",
    spring_coil = "Wave Spring",
    wall_meter = "Shore Meter",
    growth_array = "Coral Garden",
    clockwork = "Tide Clock",
    pulse_cell = "Dew Cell",
    encore = "Ocean Chorus",
    landing_fund = "Landing Shell",
}
for id, name in pairs(displayNames) do
    Catalog.Items[id].name = name
end

local families = {
    { name = "Living Water", ids = { "goldfish", "fishbowl" } },
    { name = "Sunlit Reef", ids = { "split_prism", "resonator", "growth_array" } },
    { name = "Tidepool", ids = { "soft_saw", "balance_scale" } },
    { name = "Ocean Currents", ids = { "relay", "echo_plate", "encore" } },
    { name = "Shoreline", ids = { "spring_coil", "wall_meter" } },
    { name = "Morning Dew", ids = { "clockwork", "pulse_cell" } },
    { name = "First Light", ids = { "survey_lens", "compass" } },
    { name = "Homecoming", ids = { "landing_fund", "seed_bank" } },
    { name = "Bubble Chain", ids = { "tap_driver", "burst_capsule", "gain_dial", "quota_bonus" } },
}
for _, family in ipairs(families) do
    for _, id in ipairs(family.ids) do
        local definition = Catalog.Items[id]
        definition.family = family.name
    end
end

local hybrids = {
    gain_dial = {
        operations = { { effect = "multiply" }, { effect = "halveHighest", fixed = true } },
        effectLines = { "Gain 15% score (30% upgraded).", "Halve the highest peg once." },
        tradeoff = "Immediate points cost future value on your strongest peg.",
    },
    soft_saw = {
        operations = { { effect = "halve" }, { effect = "lowestPop", fixed = true } },
        effectLines = { "Halve 2 pegs (4 upgraded).", "Pop the lowest peg once." },
        tradeoff = "Trimming reduces future hit values, but starts halve and pop combos.",
    },
    burst_capsule = {
        operations = {
            { effect = "primeBurst", fixed = true },
            { effect = "popNeighbors" },
            { effect = "halveCenter", fixed = true },
        },
        effectLines = {
            "Double one random center peg.",
            "Pop 2 nearest other pegs (4 upgraded).",
            "Halve the center peg.",
        },
        tradeoff = "The center scores no points and its growth is temporary; neighbors pay out.",
    },
}
for id, hybrid in pairs(hybrids) do
    local definition = Catalog.Items[id]
    for key, value in pairs(hybrid) do
        definition[key] = value
    end
    definition.description = table.concat(hybrid.effectLines, " ") .. " " .. hybrid.tradeoff
end
for _, id in ipairs(Catalog.ItemIds) do
    local definition = Catalog.Items[id]
    definition.effectLines = definition.effectLines or { definition.description }
end

-- Chest discoveries add new build directions, not permanent stat boosts.
-- Ordered effects share Run's normal causal chain and level scaling.
local additions = {
    {
        "rain_catcher",
        "Rain Catcher",
        "common",
        5,
        "drain",
        1,
        "On ball drain",
        "Morning Dew",
        {
            { effect = "bankLowestDouble" },
            { effect = "pulseScore" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "bubble_wand",
        "Bubble Wand",
        "common",
        5,
        "pop",
        8,
        "Every 8 pops",
        "Bubble Chain",
        { { effect = "double" }, { effect = "lowestPop", fixed = true } },
    },
    {
        "lily_pad",
        "Lily Pad",
        "common",
        4,
        "wall",
        3,
        "Every 3 wall hits",
        "Living Water",
        { { effect = "lowestDouble" }, { effect = "halveHighest", fixed = true } },
    },
    {
        "solar_leaf",
        "Solar Leaf",
        "uncommon",
        6,
        "first",
        1,
        "On first peg hit",
        "First Light",
        { { effect = "pulseScore" }, { effect = "double" } },
    },
    {
        "mist_fan",
        "Breeze Fan",
        "uncommon",
        7,
        "time",
        3,
        "Every 3 seconds alive",
        "Morning Dew",
        { { effect = "halve" }, { effect = "pop" } },
    },
    {
        "coral_fork",
        "Coral Spark",
        "uncommon",
        7,
        "double",
        4,
        "Every 4 doubles",
        "Sunlit Reef",
        { { effect = "highestPop" }, { effect = "halveHighest", fixed = true } },
    },
    {
        "tide_valve",
        "Tide Valve",
        "uncommon",
        7,
        "halve",
        4,
        "Every 4 unscored halves",
        "Ocean Currents",
        { { effect = "right", fixed = true }, { effect = "lowestDouble" } },
    },
    {
        "dew_lantern",
        "Dew Lantern",
        "uncommon",
        7,
        "time",
        4,
        "Every 4 seconds alive",
        "Morning Dew",
        {
            { effect = "pulseScore" },
            { effect = "lowestDouble" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "moss_capacitor",
        "Moss Capacitor",
        "uncommon",
        8,
        "pop",
        12,
        "Every 12 pops",
        "Living Water",
        {
            { effect = "double" },
            { effect = "goalScore" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "pearl_diver",
        "Pearl Diver",
        "rare",
        9,
        "drain",
        1,
        "On ball drain",
        "Homecoming",
        {
            { effect = "highestPop" },
            { effect = "firstScore" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "stream_wheel",
        "Stream Wheel",
        "rare",
        8,
        "wall",
        5,
        "Every 5 wall hits",
        "Ocean Currents",
        { { effect = "left", fixed = true }, { effect = "wallScore" } },
    },
    {
        "cloud_mirror",
        "Cloud Mirror",
        "rare",
        9,
        "first",
        1,
        "On first peg hit",
        "First Light",
        {
            { effect = "firstScore" },
            { effect = "halveHighest", fixed = true },
            { effect = "lowestDouble" },
        },
    },
    {
        "nectar_pump",
        "Nectar Pump",
        "rare",
        9,
        "double",
        6,
        "Every 6 doubles",
        "Living Water",
        {
            { effect = "lowestDouble" },
            { effect = "halfScore" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "lagoon_synth",
        "Lagoon Synth",
        "rare",
        10,
        "goal",
        1,
        "On each quota crossed",
        "Ocean Currents",
        {
            { effect = "right", fixed = true },
            { effect = "pulseScore" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "aurora_kite",
        "Aurora Kite",
        "legendary",
        11,
        "wall",
        8,
        "Every 8 wall hits",
        "First Light",
        {
            { effect = "multiply" },
            { effect = "double" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "biolume_jar",
        "Biolume Jar",
        "legendary",
        12,
        "time",
        5,
        "Every 5 seconds alive",
        "Sunlit Reef",
        {
            { effect = "lowestDouble" },
            { effect = "left", fixed = true },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "ozone_orb",
        "Ozone Orb",
        "legendary",
        12,
        "pop",
        20,
        "Every 20 pops",
        "Bubble Chain",
        {
            { effect = "highestPop" },
            { effect = "goalScore" },
            { effect = "halveHighest", fixed = true },
        },
    },
    {
        "monsoon_loom",
        "Monsoon Loom",
        "legendary",
        12,
        "drain",
        1,
        "On ball drain",
        "Homecoming",
        {
            { effect = "bankDoubleMany" },
            { effect = "right", fixed = true },
            { effect = "halveHighest", fixed = true },
        },
    },
}
Catalog.NewItemIds = {}
for _, entry in ipairs(additions) do
    local id, name, tier, price, event, every, triggerText, family, operations = table.unpack(entry)
    item(id, name, price, event, every, operations[1].effect, "", triggerText, tier)
    local definition = Catalog.Items[id]
    definition.operations, definition.family = operations, family
    table.insert(Catalog.NewItemIds, id)
end

local tiers = {
    common = {
        "tap_driver",
        "split_prism",
        "wall_meter",
        "landing_fund",
        "survey_lens",
        "resonator",
        "compass",
        "seed_bank",
        "soft_saw",
        "spring_coil",
        "goldfish",
    },
    uncommon = {
        "clockwork",
        "gain_dial",
        "balance_scale",
        "growth_array",
        "quota_bonus",
        "pulse_cell",
    },
    rare = { "burst_capsule", "relay", "fishbowl" },
    legendary = { "echo_plate", "encore" },
}
for tier, ids in pairs(tiers) do
    for _, id in ipairs(ids) do
        Catalog.Items[id].rarity = tier
    end
end
for _, id in ipairs(Catalog.ItemIds) do
    local definition = Catalog.Items[id]
    definition.tier = definition.rarity
    definition.color = Catalog.Tiers[definition.tier].color
end

-- Only base equipment can enter the persistent item-unlock pool. Starter items
-- are always available; old discoveries are migrated by Profile, not shop rolls.
function Catalog.isBaseItem(id)
    local definition = Catalog.Items[id]
    return definition ~= nil and not definition.evolved and not definition.consumable
end

function Catalog.itemUnlockSet(ids)
    local unlocked = {}
    for _, id in ipairs(Catalog.StarterIds) do
        unlocked[id] = true
    end
    if type(ids) == "table" then
        for key, value in pairs(ids) do
            local id = if type(key) == "number" then value else key
            if
                type(id) == "string"
                and (type(key) == "number" or value == true)
                and Catalog.isBaseItem(id)
            then
                unlocked[id] = true
            end
        end
    end
    return unlocked
end

Catalog.Items.gain_dial.unlock = "workshop_access"
Catalog.Items.growth_array.unlock = "growth_kit"
Catalog.Items.fishbowl.unlock = "growth_kit"
Catalog.Items.echo_plate.unlock = "relay_kit"
Catalog.Items.encore.unlock = "relay_kit"
Catalog.Unlocks = {
    workshop_access = {
        name = "Workshop access",
        description = "Gain Dial can appear in future shops.",
        round = 5,
    },
    growth_kit = {
        name = "Growth kit",
        description = "Coral Garden and Fishbowl can appear in future shops.",
        round = 10,
    },
    relay_kit = {
        name = "Relay kit",
        description = "Echo Shell and Ocean Chorus can appear in future shops.",
        round = 20,
    },
}
Catalog.ConsumableIds = { "reserve_pack", "coin_press", "tuning_oil" }
local consumables = {
    {
        id = "reserve_pack",
        name = "Reserve Pack",
        price = 8,
        description = "Use now: recover two reserve balls.",
        effect = "repair",
    },
    {
        id = "coin_press",
        name = "Coin Press",
        price = 3,
        description = "Use now: gain one coin for each reserve ball.",
        effect = "reserveCoins",
    },
    {
        id = "tuning_oil",
        name = "Tuning Oil",
        price = 8,
        description = "Use now: upgrade a random basic item. If none qualify, gain four coins.",
        effect = "upgrade",
    },
}
for _, definition in ipairs(consumables) do
    definition.consumable = true
    definition.rarity = "common"
    definition.triggerText = "Use immediately"
    definition.color = { 255, 172, 100 }
    definition.family = "Supplies"
    definition.effectLines = { definition.description }
    Catalog.Items[definition.id] = definition
end

local function perk(id, name, event, every, effect, description, triggerText)
    Catalog.Perks[id] = {
        id = id,
        name = name,
        trigger = { event = event, every = every },
        effect = effect,
        description = description,
        triggerText = triggerText,
        color = { 255, 201, 95 },
    }
    table.insert(Catalog.PerkIds, id)
end

perk("first_spark", "First Spark", "first", 1, "first", "Activate slot 1.", "On first peg hit")
perk(
    "tailwind",
    "Tailwind",
    "pop",
    8,
    "last",
    "Activate your rightmost occupied slot.",
    "Every 8 pops"
)
perk(
    "ricochet",
    "Ricochet",
    "wall",
    4,
    "random",
    "Activate a random occupied slot.",
    "Every 4 wall hits"
)
perk("growth_ring", "Growth Ring", "double", 5, "first", "Activate slot 1.", "Every 5 doubles")
perk(
    "recovery",
    "Recovery",
    "halve",
    3,
    "last",
    "Activate your rightmost occupied slot.",
    "Every 3 unscored halves"
)
perk(
    "last_word",
    "Last Word",
    "drain",
    1,
    "third",
    "Activate slot 3 twice.",
    "On natural ball drain"
)
perk(
    "metronome",
    "Metronome",
    "time",
    3,
    "random",
    "Activate a random occupied slot.",
    "Every 3 seconds alive"
)
perk(
    "milestone",
    "Milestone",
    "goal",
    1,
    "third",
    "Activate slot 3 twice.",
    "On each quota crossed"
)

Catalog.Events = {
    {
        title = "Spare Parts",
        choices = {
            { id = "coins", name = "Sell the crate", description = "Gain 4 coins." },
            {
                id = "grow",
                name = "Fit new pegs",
                description = "Double four pegs for the next round.",
            },
        },
    },
    {
        title = "Maintenance Break",
        choices = {
            { id = "repair", name = "Refill reserves", description = "Recover two reserve balls." },
            {
                id = "upgrade",
                name = "Tune equipment",
                description = "Upgrade a random basic item; gain 4 coins if none qualify.",
            },
        },
    },
    {
        title = "Extra Shift",
        choices = {
            {
                id = "overtime",
                name = "Work overtime",
                description = "Spend one reserve ball to earn 8 coins.",
            },
            {
                id = "grow",
                name = "Improve the board",
                description = "Double four pegs for the next round.",
            },
        },
    },
}

Catalog.Bosses = {
    { name = "Pressure Shift", description = "The quota is 25% higher.", multiplier = 1.25 },
    {
        name = "Quiet Circuit",
        description = "The last inventory slot is disabled this round.",
        disabledLast = true,
    },
    {
        name = "Stopped Clock",
        description = "Timed item and perk triggers are disabled this round.",
        noTime = true,
    },
    { name = "Final Audit", description = "The quota is 40% higher.", multiplier = 1.4 },
}

-- Inspection rows follow the same ordered effect IDs used by Run. These are
-- presentation values, not a second execution path or extra gameplay effects.
local function amount(base, _oldUpgrade, level)
    local percent = type(base) == "string"
    local unit = if percent then tonumber(string.match(base, "%d+")) else base
    local suffix = if percent then "%" else ""
    local current = tostring(unit * level) .. suffix
    if level >= Catalog.MaxLevel then
        return current
    end
    return current .. " (↑ " .. tostring(unit * (level + 1)) .. suffix .. ")"
end

local detailEffects = {
    pop = function(level)
        return "Pop " .. amount(1, 2, level) .. " random pegs", "positive"
    end,
    double = function(level)
        return "Double " .. amount(1, 2, level) .. " random pegs", "positive"
    end,
    doubleMany = function(level)
        return "Double " .. amount(4, 8, level) .. " random pegs", "positive"
    end,
    bankDoubleMany = function(level)
        return "Double "
            .. amount(4, 8, level)
            .. " random pegs; on natural drain, seed that many next-shot pegs (max once per peg)",
            "positive"
    end,
    bankLowestDouble = function(level)
        return "Double the lowest peg "
            .. amount(1, 2, level)
            .. " times; on natural drain, seed that many lowest next-shot pegs (max once per peg)",
            "positive"
    end,
    lowestDouble = function(level)
        return "Double the lowest peg " .. amount(1, 2, level) .. " times", "positive"
    end,
    halve = function(level)
        return "Halve " .. amount(2, 4, level) .. " random pegs without scoring", "negative"
    end,
    halveHighest = function()
        return "Halve the highest peg once", "negative"
    end,
    lowestPop = function()
        return "Pop the lowest peg once", "positive"
    end,
    primeBurst = function()
        return "Double a random center peg", "positive"
    end,
    popNeighbors = function(level)
        return "Pop " .. amount(2, 4, level) .. " nearest other pegs", "positive"
    end,
    halveCenter = function()
        return "Halve the center peg", "negative"
    end,
    highestPop = function(level)
        return "Pop the highest peg " .. amount(1, 2, level) .. " times", "positive"
    end,
    firstScore = function(level)
        return "Score " .. amount(2, 4, level) .. " × the highest peg value", "positive"
    end,
    halfScore = function(level)
        return "Score " .. amount(4, 8, level) .. " × the lowest peg value", "positive"
    end,
    multiply = function(level)
        return "Gain " .. amount("15%", "30%", level) .. " score", "positive"
    end,
    wallScore = function(level)
        return "Gain " .. amount("8%", "16%", level) .. " of round quota", "positive"
    end,
    drainScore = function(level)
        return "Gain " .. amount("15%", "30%", level) .. " of round quota", "positive"
    end,
    pulseScore = function(level)
        return "Gain " .. amount("3%", "6%", level) .. " of round quota", "positive"
    end,
    goalScore = function(level)
        return "Gain " .. amount("5%", "10%", level) .. " of round quota", "positive"
    end,
    right = function(level)
        return "Activate the next occupied slot to the right " .. amount(1, 2, level) .. " times",
            "positive"
    end,
    left = function(level)
        return "Activate the previous occupied slot " .. amount(1, 2, level) .. " times", "positive"
    end,
    all = function(level)
        return "Activate every other item " .. amount(1, 2, level) .. " times", "positive"
    end,
    repair = function()
        return "Recover 2 balls, up to 5", "positive"
    end,
    reserveCoins = function()
        return "Gain 1 coin per ball remaining", "positive"
    end,
    upgrade = function()
        return "Add 1 level to a random item below level 5", "positive"
    end,
    first = function()
        return "Activate slot 1", "positive"
    end,
    third = function()
        return "Activate slot 3 twice", "positive"
    end,
    last = function()
        return "Activate the rightmost occupied slot", "positive"
    end,
    random = function()
        return "Activate a random occupied slot", "positive"
    end,
}

-- Evolved items retain both ingredient triggers and ordered effects at level 5.
-- They enter the shop only through eligible recipes, never the random item pool.
local function evolve(id, name, left, right)
    local channels = {}
    for _, ingredient in ipairs({ left, right }) do
        local source = Catalog.Items[ingredient]
        table.insert(channels, {
            sourceId = ingredient,
            trigger = source.trigger,
            triggerText = source.triggerText,
            operations = source.operations or { { effect = source.effect } },
        })
    end
    Catalog.Items[id] = {
        id = id,
        name = name,
        evolved = true,
        price = 0,
        rarity = "evolved",
        family = "Evolutions",
        channels = channels,
        triggerText = "Two level-5 abilities",
        color = { 255, 215, 100 },
        effect = "evolution",
    }
    table.insert(Catalog.EvolvedIds, id)
    table.insert(Catalog.Evolutions, { id = id, ingredients = { left, right } })
end

evolve("aurora_aquarium", "Aurora Aquarium", "goldfish", "fishbowl")
evolve("spectrum_reef", "Spectrum Reef", "split_prism", "resonator")
evolve("tidal_engine", "Tidal Engine", "wall_meter", "spring_coil")
evolve("storm_clock", "Storm Clock", "clockwork", "pulse_cell")
evolve("horizon_observatory", "Horizon Observatory", "survey_lens", "compass")
evolve("eden_greenhouse", "Eden Greenhouse", "seed_bank", "growth_array")
evolve("pearl_turbine", "Pearl Turbine", "soft_saw", "balance_scale")
evolve("current_nexus", "Current Nexus", "relay", "echo_plate")
evolve("ocean_orchestra", "Ocean Orchestra", "landing_fund", "encore")
evolve("bubble_reactor", "Bubble Reactor", "tap_driver", "burst_capsule")
evolve("solar_treasury", "Solar Treasury", "gain_dial", "quota_bonus")
evolve("sun_koi", "Sun Koi", "split_prism", "goldfish")
evolve("tide_gyroscope", "Tide Gyroscope", "clockwork", "spring_coil")

function Catalog.evolutionsFor(id)
    local recipes = {}
    for _, recipe in ipairs(Catalog.Evolutions) do
        if recipe.ingredients[1] == id or recipe.ingredients[2] == id then
            table.insert(
                recipes,
                { id = recipe.id, ingredients = { recipe.ingredients[1], recipe.ingredients[2] } }
            )
        end
    end
    return recipes
end

function Catalog.evolutionState(inventory, slots, recipeId)
    local result = { ready = false, slots = {}, levels = { 0, 0 }, owned = { false, false } }
    for _, recipe in ipairs(Catalog.Evolutions) do
        if recipe.id == recipeId then
            for ingredientIndex, ingredient in ipairs(recipe.ingredients) do
                for slot = 1, slots do
                    local entry = inventory[slot]
                    if entry and entry.id == ingredient then
                        result.owned[ingredientIndex] = true
                        result.levels[ingredientIndex] =
                            math.max(result.levels[ingredientIndex], entry.level)
                        if
                            entry.level == Catalog.MaxLevel and not result.slots[ingredientIndex]
                        then
                            result.slots[ingredientIndex] = slot
                        end
                    end
                end
            end
            result.ready = result.slots[1] ~= nil and result.slots[2] ~= nil
            return result
        end
    end
    return result
end

for _, id in ipairs(Catalog.ConsumableIds) do
    Catalog.Items[id].triggerText = "On purchase"
end

function Catalog.owns(inventory, id)
    for _, entry in pairs(inventory or {}) do
        if type(entry) == "table" and entry.id == id then
            return true
        end
    end
    return false
end

function Catalog.detail(id, level)
    local definition = Catalog.Items[id] or Catalog.Perks[id]
    if not definition then
        return nil
    end
    level = if type(level) == "number" and level == level
        then math.clamp(math.floor(level), 1, Catalog.MaxLevel)
        else 1
    if definition.evolved then
        level = Catalog.MaxLevel
    end
    local effects = {}
    local function addOperations(operations, power, event)
        for _, operation in ipairs(operations) do
            local render = detailEffects[operation.effect]
            assert(render, "Missing inspection effect: " .. operation.effect)
            local text, tone = render(operation.fixed and 1 or power)
            if event == "drain" and operation.effect == "halveHighest" then
                text = "Halve the highest live peg once"
            end
            if operation.fixed then
                text = string.gsub(text, " %(↑ [^)]+%)", "")
            end
            table.insert(effects, { text = text, tone = tone })
        end
    end
    if definition.channels then
        for _, channel in ipairs(definition.channels) do
            table.insert(effects, { text = channel.triggerText, tone = "trigger" })
            addOperations(channel.operations, Catalog.MaxLevel, channel.trigger.event)
        end
    else
        addOperations(
            definition.operations or { { effect = definition.effect } },
            level,
            definition.trigger and definition.trigger.event
        )
    end
    if definition.effect == "upgrade" then
        table.insert(effects, { text = "If none qualify: gain 4 coins", tone = "positive" })
    end
    return {
        id = id,
        name = definition.name,
        trigger = definition.triggerText,
        kind = if definition.evolved
            then "evolved"
            elseif Catalog.Perks[id] then "perk"
            elseif definition.consumable then "supply"
            else "item",
        level = level,
        tier = definition.tier,
        effects = effects,
        evolutions = Catalog.evolutionsFor(id),
    }
end

function Catalog.purchaseState(inventory, slots, offer, coins)
    local function blocked(action, message)
        return { action = action, allowed = false, reason = action, price = 0, message = message }
    end
    local definition = type(offer) == "table" and Catalog.Items[offer.id]
    if
        not definition
        or type(offer.price) ~= "number"
        or offer.price < 0
        or offer.price >= math.huge
        or offer.price ~= offer.price
    then
        return blocked("unavailable", "That offer is unavailable.")
    end
    if offer.sold then
        return blocked("sold", "That offer was already purchased.")
    end
    local intent = { action = "use", allowed = true, price = offer.price }
    if definition.evolved then
        local state = Catalog.evolutionState(inventory, slots, definition.id)
        if not state.ready then
            return blocked("ingredients", "Both evolution ingredients must be level 5.")
        end
        intent.action, intent.slot, intent.level = "evolve", state.slots[1], Catalog.MaxLevel
        intent.removeSlots = state.slots
    elseif not definition.consumable then
        local upgradeSlot, emptySlot, capped
        for slot = 1, slots do
            local entry = inventory[slot]
            if entry and entry.id == definition.id then
                if entry.level < Catalog.MaxLevel then
                    upgradeSlot = upgradeSlot or slot
                else
                    capped = true
                end
            elseif entry and entry.id == "" then
                emptySlot = emptySlot or slot
            end
        end
        if upgradeSlot then
            intent.action, intent.slot, intent.level =
                "upgrade", upgradeSlot, inventory[upgradeSlot].level + 1
        elseif capped then
            return blocked("maxLevel", "That item is already at max level.")
        elseif emptySlot then
            intent.action, intent.slot, intent.level = "purchase", emptySlot, 1
        else
            return blocked("full", "Inventory full. Sell an item or buy a slot.")
        end
    end
    if coins < offer.price then
        intent.allowed, intent.reason, intent.message = false, "coins", "Not enough coins."
    end
    return intent
end

-- Legacy summary consumers use the same current inspection text.
for id, definition in pairs(Catalog.Items) do
    local detail = Catalog.detail(id, 1)
    local lines = {}
    for _, row in ipairs(detail.effects) do
        table.insert(lines, row.text)
    end
    definition.effectLines = lines
    definition.description = table.concat(lines, ". ")
end

return Catalog
