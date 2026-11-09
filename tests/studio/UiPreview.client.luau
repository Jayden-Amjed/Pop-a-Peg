--!nonstrict
-- Opt-in unpublished UI preview. Real Run/ArcadeSessions rules, temporary memory only.
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
assert(RunService:IsStudio() and game.GameId == 0, "Open the local UI preview file")
local player = Players.LocalPlayer
local client = script.Parent:WaitForChild("Client")
assert(client.Main.Disabled, "Ordinary Main must be disabled in the preview")
local Library = Storage:WaitForChild("UiPreviewLibrary")
local Sessions = require(Library.ArcadeSessions)
local HubWorld = require(Library.HubWorld)
local Run = require(Storage.Shared.Run)
local Profile = require(Storage.Shared.Profile)
local Catalog = require(Storage.Shared.Catalog)
local Boards = require(Storage.Shared.Leaderboards)
local Presentation = require(client.Presentation)
local Hub = require(client.HubPresentation)
local Theme = require(client.UiTheme)
local PreviewId = 31031 -- Synthetic account prevents owner-access overrides in research tests.
local sessions = Sessions.new()
local session = assert(
    sessions:add(
        PreviewId,
        player.DisplayName .. " (Preview)",
        Profile.clean({
            version = 2,
            bestRound = 42,
            bestScore = 125000,
            bestEndlessRound = 115,
            playSeconds = 5600,
            restockCredits = 1500,
            research = 80,
            chests = { common = 3, uncommon = 2, rare = 1, legendary = 1 },
            unlocks = { "aurora_aquarium", "level_1", "level_2" },
        })
    ),
    "Preview session unavailable"
)
session.profileStatus = "session"
sessions:add(
    31032,
    "Coral (Preview)",
    { bestRound = 18, playSeconds = 3700, bestEndlessRound = 104 }
)
sessions:add(31033, "Reef (Preview)", { bestRound = 7, playSeconds = 2200 })

local screens = {
    "Aim",
    "Shop",
    "Perks",
    "Event",
    "Defeat",
    "Victory",
    "Arcade",
    "Collection",
    "Recipe",
    "Records",
    "Help",
    "Chests",
    "Workshop",
    "Rankings",
    "Crew",
}
local controller = { fixture = true, screens = screens, actions = 0, lastFailure = nil }
-- selene: allow(global_usage)
shared.RBX031UiPreview = controller
local view, hub, world, current, selectScreen
local queued, connections = {}, {}
local elapsed, destroyed = 0, false
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local cameraBefore = { camera.CFrame, camera.CameraType, camera.FieldOfView }
pcall(function()
    local starter = game:GetService("StarterGui")
    starter:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    starter:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    starter:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local gui = Theme.make("ScreenGui", {
    Name = "UiPreviewControls",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ScreenInsets = Enum.ScreenInsets.None,
    DisplayOrder = 200,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, playerGui)
local toggle = Theme.button(gui, "Toggle", "UI PREVIEW", Theme.colors.paper, function()
    controller.menu.Visible = not controller.menu.Visible
end, 242)
toggle.TextColor3, toggle.TextStrokeTransparency = Theme.colors.ink, 1
toggle.TextScaled = true
Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 17 }, toggle)
toggle:SetAttribute("BlocksAim", true)
local menu = Theme.plate(gui, "Screens", Theme.colors.paper, 240)
menu.Active = true
menu:SetAttribute("BlocksAim", true)
menu.Visible = false
controller.toolbar, controller.menu, controller.toggle = gui, menu, toggle
local heading =
    Theme.label(menu, "Heading", "UI PREVIEW · TEMPORARY TEST DATA", 18, Theme.colors.ink, 242)
heading.TextScaled, heading.TextXAlignment = true, Enum.TextXAlignment.Center
local screenButtons = {}
for index, name in screens do
    local control = Theme.button(menu, "Screen" .. index, name, Theme.colors.muted, function()
        menu.Visible = false
        selectScreen(name)
    end, 242)
    control.TextColor3, control.TextStrokeTransparency, control.TextScaled =
        Theme.colors.ink, 1, true
    Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 20 }, control)
    screenButtons[index] = control
end

local function layoutControls()
    local safe = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
    local width, height = math.min(540, safe.Width - 16), math.min(290, safe.Height - 12)
    Theme.rect(toggle, safe.Max.X - 148, safe.Min.Y + 2, 140, 34)
    Theme.rect(
        menu,
        safe.Min.X + (safe.Width - width) / 2,
        safe.Min.Y + (safe.Height - height) / 2,
        width,
        height
    )
    Theme.rect(heading, 8, 4, width - 16, 30)
    local cw, ch = (width - 24) / 3, (height - 42) / 5
    for index, control in screenButtons do
        Theme.rect(
            control,
            6 + ((index - 1) % 3) * (cw + 6),
            36 + math.floor((index - 1) / 3) * ch,
            cw,
            ch - 5
        )
    end
    toggle.Text = "UI: " .. (current or "Aim") .. "  ▾"
end

local function send(kind, payload)
    table.insert(queued, { kind = kind, payload = payload or {} })
end
controller.send = send

local function snapshot()
    local result = sessions:snapshot(PreviewId)
    result.profileStatus = "session"
    if result.hub then
        result.hub.leaderboards = Boards.session(sessions.players)
    end
    return result
end

local function refresh()
    controller.run, controller.session = session.run, session
    local state = snapshot()
    if session.view == "hub" then
        if view then
            view:destroy()
            view = nil
        end
        if not hub then
            hub = Hub.new(send)
            hub.gui.Name = "RBX031UiHub"
        end
        if not world then
            world = HubWorld.new(function()
                send("startRun")
            end)
            world:setStation(
                1,
                { name = player.DisplayName .. " (Preview)", view = "hub", round = 11 }
            )
        end
        camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, 55
        camera.CFrame = CFrame.lookAt(
            HubWorld.Origin + Vector3.new(0, 36, 75),
            HubWorld.Origin + Vector3.new(0, 8, 0)
        )
        hub:update(state)
    else
        if hub then
            hub:destroy()
            hub = nil
        end
        if not view then
            view = Presentation.new(send)
            view.gui.Name = "RBX031UiRun"
        end
        view:update(state)
    end
    controller.view, controller.hub = view, hub
    controller.snapshot = state
end

local function seedRun()
    session.run = Run.new(31031, { itemUnlocks = Catalog.ItemIds })
    session.runId += 1
    session.temporaryRunAccess = false
    session.lastEvent, session.rewardedRestockReceipt = 0, 0
    session.rewardedMilestones, session.rewardedEndless = {}, {}
    session.terminalRewarded = false
    local run = session.run
    run.round, run.coins, run.slots = 11, 30, 5
    run.highestClearedRound, run.shopsVisited, run.reserves = 10, 2, 4
    run.inventory = {
        { id = "seed_bank", level = 2 },
        { id = "balance_scale", level = 1 },
        { id = "goldfish", level = 3 },
        { id = "", level = 1 },
        { id = "", level = 1 },
    }
    run.perks = { Catalog.PerkIds[1], Catalog.PerkIds[2] }
    run:_resetShot()
    return run
end

selectScreen = function(name)
    assert(table.find(screens, name), "Unknown UI preview screen")
    if view then
        view:destroy()
        view = nil
    end
    if hub then
        hub:destroy()
        hub = nil
    end
    table.clear(queued)
    controller.lastFailure, current = nil, name
    local index = table.find(screens, name)
    if index <= 6 then
        session.view = "run"
        local run = seedRun()
        if name == "Shop" then
            run:_openShop(false)
        elseif name == "Perks" then
            run.routes = { { kind = "perk" } }
            run:_nextRoute()
        elseif name == "Event" then
            run.routes = { { kind = "event", index = 1 } }
            run:_nextRoute()
        elseif name == "Defeat" then
            run.reserves = 0
            run:_phase("gameover")
        elseif name == "Victory" then
            run.round, run.highestClearedRound = 101, 100
            run.routes = { { kind = "victory" } }
            run:_nextRoute()
        end
    else
        session.view = "hub"
        if not session.run then
            seedRun()
        end
    end
    refresh()
    if hub then
        local kinds = {
            Collection = "collection",
            Recipe = "collection",
            Records = "records",
            Help = "help",
            Chests = "chests",
            Workshop = "chests",
            Rankings = "leaderboards",
            Crew = "crew",
        }
        if kinds[name] then
            if name == "Workshop" then
                hub.progression.mode = "workshop"
            end
            hub:open(kinds[name])
            if name == "Recipe" then
                hub.selected = "aurora_aquarium"
                hub:_renderPanel()
            end
        end
    end
    controller.screen = name
    menu.Visible = false
    layoutControls()
end
controller.select = selectScreen
controller.reset = function()
    selectScreen("Aim")
end

selectScreen("Aim")
table.insert(
    connections,
    RunService.RenderStepped:Connect(function(dt)
        if destroyed then
            return
        end
        local changed = false
        local actions = queued
        queued = {}
        for _, request in actions do
            local ok, failure = sessions:action(
                PreviewId,
                request.kind,
                request.payload,
                31032 + controller.actions
            )
            controller.actions += 1
            controller.lastAction, controller.lastFailure = request.kind, not ok and failure or nil
            if not ok then
                (view or hub):setNotice(failure)
            end
            changed = true
        end
        local previous = session.run and session.run.phase
        sessions:step(dt, dt)
        elapsed += dt
        if
            changed
            or (
                session.run
                and (
                    session.run.phase ~= previous
                    or (session.run.phase == "flight" and elapsed >= 1 / 20)
                )
            )
        then
            refresh()
            elapsed = 0
        end
        if view then
            view:step(math.min(dt, 0.1))
        end
        if hub then
            hub:step(math.min(dt, 0.1))
        end
        layoutControls()
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
        if hub then
            hub:destroy()
        end
        if world then
            world:destroy()
        end
        gui:Destroy()
        camera.CFrame, camera.CameraType, camera.FieldOfView = table.unpack(cameraBefore)
        -- selene: allow(global_usage)
        if shared.RBX031UiPreview == controller then
            shared.RBX031UiPreview = nil
        end
    end)
)
print(
    "[RBX-031] UI PREVIEW ready: real run/hub UI, temporary in-memory account, no saves or remotes"
)
