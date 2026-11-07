-- Original run equipment. Trigger thresholds and prices are tuning data.
local Catalog = { Items = {}, Perks = {}, ItemIds = {}, PerkIds = {} }

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
    "Score 45 points. Upgrade: 90 points.",
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
    "Score 150 points on natural drain. Upgrade: 300 points.",
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
    "Score 40 points per quota crossed. Upgrade: 80 points.",
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
    "Score 25 points. Upgrade: 50 points.",
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
    "doubleMany",
    "Double four pegs. Upgrade: eight pegs.",
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

Catalog.Items.gain_dial.unlock = "workshop_access"
Catalog.Items.growth_array.unlock = "growth_kit"
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
        description = "Growth Array can appear in future shops.",
        round = 10,
    },
    relay_kit = {
        name = "Relay kit",
        description = "Echo Plate and Encore can appear in future shops.",
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

return Catalog
