--!nonstrict
-- Opt-in local Studio prototype. Only build-shop-prototype.ps1 maps this script.
-- Run owns every gameplay decision; this fixture grants scenarios in memory only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
assert(RunService:IsStudio() and game.GameId == 0, "Open the unpublished local shop prototype")

local client = script.Parent:WaitForChild("Client")
assert(client.Main.Disabled, "The ordinary game client must be disabled in this fixture")
local Run = require(ReplicatedStorage.Shared.Run)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local Presentation = require(client.Presentation)
local Theme = require(client.UiTheme)
local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local run, view, reset, toolbar
local queued, connections = {}, {}
local sequence, elapsed, destroyed = 0, 0, false
local controller = { fixture = true, actions = 0, lastFailure = nil }
-- selene: allow(global_usage)
shared.RBX031ShopPrototype = controller

local function offer(id)
    local definition = assert(Catalog.Items[id], "Unknown fixture item: " .. id)
    return {
        id = id,
        price = definition.evolved and 0 or definition.price,
        sold = false,
        frozen = false,
        consumable = definition.consumable == true,
        evolution = definition.evolved == true,
    }
end

local function refresh()
    if view and run then
        view:update(run:snapshot())
    end
end

local function addToolbar()
    toolbar = Theme.frame(view.root, "ShopPrototypeControls", Theme.colors.ink, 240)
    toolbar:SetAttribute("BlocksAim", true)
    toolbar.BackgroundTransparency = 0.08
    Theme.corner(toolbar, 8)
    local title = Theme.label(toolbar, "FixtureLabel", "TEST SHOP", 15, Theme.colors.gold, 242)
    title.TextStrokeTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    Theme.rect(title, 2, 0, 88, 36)
    for index, entry in
        {
            { "Reset shop", "standard" },
            { "Full rack", "full" },
            { "Evolution", "evolution" },
            { "Back to shop", "back" },
        }
    do
        local control = Theme.button(
            toolbar,
            "Scenario" .. index,
            entry[1],
            Theme.colors.paper,
            function()
                reset(entry[2])
            end,
            242
        )
        control.TextColor3 = Theme.colors.ink
        control.TextStrokeTransparency = 1
        control.TextSize = 15
        control.TextScaled = true
        Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 15 }, control)
        control:SetAttribute("FixtureColumn", index)
    end
end

local function layoutToolbar()
    if not toolbar or not view.viewport then
        return
    end
    local width = math.min(600, view.viewport.X - 16)
    Theme.rect(toolbar, 8, 2, width, 36)
    local buttonWidth = (width - 98 - 18) / 4
    for _, control in toolbar:GetChildren() do
        local column = control:GetAttribute("FixtureColumn")
        if column then
            Theme.rect(control, 94 + (column - 1) * (buttonWidth + 6), 3, buttonWidth, 30)
        end
    end
end

reset = function(scenario)
    scenario = scenario or "standard"
    assert(
        scenario == "standard"
            or scenario == "full"
            or scenario == "evolution"
            or scenario == "back",
        "Unknown shop fixture scenario"
    )
    if view then
        view:destroy()
    end
    table.clear(queued)
    elapsed = 0
    if scenario == "back" and run then
        -- An explicit test shortcut cancels the current shot, then uses the normal
        -- shop roll. Purchased equipment and coins stay in this in-memory run.
        run.round = math.max(Run.Config.suppliesRound, run.round)
        run.routes, run.lastResult, run.lastShotStats = {}, nil, nil
        run:_resetShot()
        run:_openShop(false)
    else
        sequence += 1
        run = Run.new(31000 + sequence, { itemUnlocks = Catalog.ItemIds })
        run.round, run.coins, run.slots = Run.Config.suppliesRound, 30, 5
        run.highestClearedRound, run.shopsVisited = run.round - 1, 2
        run.reserves = 3
        run.inventory = {
            { id = "seed_bank", level = 2 },
            { id = "balance_scale", level = 1 },
            { id = "goldfish", level = 3 },
            { id = "", level = 1 },
            { id = "", level = 1 },
        }
        if scenario == "full" then
            run.slots = 7
            local ids = {
                "seed_bank",
                "balance_scale",
                "goldfish",
                "tap_driver",
                "spring_coil",
                "compass",
                "relay",
            }
            for index, id in ids do
                run.inventory[index] = { id = id, level = index == 2 and Catalog.MaxLevel or 2 }
            end
        elseif scenario == "evolution" then
            run.inventory[1] = { id = "goldfish", level = Catalog.MaxLevel }
            run.inventory[2] = { id = "fishbowl", level = Catalog.MaxLevel }
            run.inventory[3] = { id = "seed_bank", level = 2 }
        end
        run:_resetShot()
        run:_openShop(false)
        run.shopOffers = {}
        local ids = {
            scenario == "evolution" and "aurora_aquarium" or "seed_bank",
            "aurora_kite",
            "balance_scale",
            "biolume_jar",
            "reserve_pack",
            "tuning_oil",
        }
        for index, id in ids do
            run.shopOffers[index] = offer(id)
        end
    end
    controller.scenario, controller.run = scenario, run
    controller.lastFailure = nil
    view = Presentation.new(function(kind, payload)
        table.insert(queued, { kind = kind, payload = payload })
    end)
    controller.view = view
    view.gui.Name = "RBX031ShopPrototype"
    refresh()
    addToolbar()
    layoutToolbar()
end
controller.reset = reset

reset("standard")
table.insert(
    connections,
    RunService.RenderStepped:Connect(function(dt)
        if destroyed then
            return
        end
        -- Snapshot after simulation and each input; feedback can queue automatic
        -- continuation, handled on the next frame without re-entering Presentation.
        local changed = false
        local actions = queued
        queued = {}
        for _, request in actions do
            local ok, failure = run:action(request.kind, request.payload)
            controller.actions += 1
            controller.lastAction = request.kind
            controller.lastFailure = not ok and failure or nil
            if not ok then
                view:setNotice(failure)
            end
            changed = true
        end
        local previousPhase = run.phase
        run:step(dt)
        elapsed += dt
        if
            changed
            or previousPhase ~= run.phase
            or (run.phase == "flight" and elapsed >= 1 / 20)
        then
            refresh()
            elapsed = 0
        end
        view:step(math.min(dt, 0.1))
        layoutToolbar()
    end)
)

table.insert(
    connections,
    script.Destroying:Connect(function()
        destroyed = true
        for _, connection in connections do
            connection:Disconnect()
        end
        if view then
            view:destroy()
        end
        -- selene: allow(global_usage)
        if shared.RBX031ShopPrototype == controller then
            -- selene: allow(global_usage)
            shared.RBX031ShopPrototype = nil
        end
    end)
)
print("[RBX-031] Local TEST SHOP ready; no profiles, remotes, saves, or publication")
