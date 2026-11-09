--!nonstrict
-- Original shop skin. Rules and model lifetimes remain owned by Catalog/Presentation.
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(script.Parent.UiTheme)
local Layout = require(script.Parent.ShopLayout)
local Shop = {}
local C = {
    ink = Color3.fromRGB(16, 55, 78),
    paper = Color3.fromRGB(243, 252, 255),
    aqua = Color3.fromRGB(13, 199, 211),
    ice = Color3.fromRGB(204, 237, 245),
    green = Color3.fromRGB(102, 210, 13),
    gold = Color3.fromRGB(255, 208, 65),
    gray = Color3.fromRGB(191, 210, 217),
}
local function place(object, r)
    Theme.rect(object, r.x, r.y, r.w, r.h)
end
local function surface(parent, name, color, z, radius)
    local panel = Theme.frame(parent, name, color, z)
    Theme.corner(panel, radius or 16)
    Theme.stroke(panel, C.ink, 2)
    local shadow = Theme.frame(panel, "Depth", C.ink, z - 1)
    shadow.Position, shadow.Size = UDim2.fromOffset(0, 4), UDim2.fromScale(1, 1)
    shadow.BackgroundTransparency = 0.48
    Theme.corner(shadow, radius or 16)
    Theme.make("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.45, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(204, 227, 239)),
        }),
    }, panel)
    return panel
end
local function text(parent, name, value, size, z)
    local result = Theme.label(parent, name, value, size, C.ink, z)
    result.Font = Enum.Font.FredokaOne
    result.TextStrokeTransparency = 1
    result.TextXAlignment = Enum.TextXAlignment.Center
    result.TextWrapped, result.TextScaled = true, true
    Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = size }, result)
    return result
end
local function button(parent, name, value, color, callback, z)
    local result = Theme.make("TextButton", {
        Name = name,
        Text = "",
        AutoButtonColor = true,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = z,
        Active = true,
    }, parent)
    local skin = surface(result, "Skin", color, z, 14)
    skin.Size = UDim2.fromScale(1, 1)
    local caption = text(result, "Caption", value, 25, z + 2)
    caption.Position, caption.Size = UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0)
    result.Activated:Connect(function()
        if result.Active then
            callback()
        end
    end)
    return result
end
local function enabled(control, active, caption, color)
    control.Active, control.Selectable = active, active
    control.Skin.BackgroundColor3 = active and color or C.gray
    control.Caption.Text = caption
    control.Caption.TextTransparency = active and 0 or 0.25
    control.Caption.TextColor3 = active and color == C.green and C.paper or C.ink
    control.Caption.TextStrokeColor3 = C.ink
    control.Caption.TextStrokeTransparency = active and color == C.green and 0.4 or 1
end
local function viewport(parent, name, z)
    local result = Theme.make("ViewportFrame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = z,
    }, parent)
    result:SetAttribute("ShopPreview", true)
    return result
end

function Shop.build(host, state, width, height, top)
    local supplies = math.min(2, math.max(0, #state.shopOffers - 4))
    local layout = Layout.compute(width, height, supplies)
    local modal = surface(host.overlay, "Shop", C.paper, 22, 24)
    modal:SetAttribute("BlocksAim", true)
    local size = host.viewport or Vector2.new(1440, 900)
    Theme.rect(modal, (size.X - width) / 2, top, width, height)
    host.modal = modal
    local self = {
        cards = {},
        width = width,
        height = height,
        top = top,
        count = 4 + supplies,
        layout = layout,
        host = host,
    }
    host.shop = self
    local header = layout.title
    local titleW = math.min(420, header.w * 0.37)
    local badge = surface(modal, "ShopBanner", C.aqua, 24, 20)
    Theme.rect(badge, (width - titleW) / 2, header.y, titleW, header.h)
    self.title = text(badge, "Title", "SHOP", layout.compact and 30 or 52, 26)
    self.title.TextColor3, self.title.TextStrokeColor3 = C.paper, C.ink
    self.title.TextStrokeTransparency = 0.25
    self.title.Size = UDim2.fromScale(1, 1)
    local walletW = math.min(245, header.w * 0.27)
    local wallet = surface(modal, "Wallet", C.ice, 24, 18)
    Theme.rect(wallet, header.x, header.y + 2, walletW, header.h - 4)
    local coin = viewport(wallet, "Coin", 26)
    Theme.rect(coin, 2, 0, header.h - 4, header.h - 4)
    host:_mount(coin, "coin", 1)
    self.wallet = text(wallet, "Coins", "", layout.compact and 24 or 36, 27)
    Theme.rect(self.wallet, header.h - 2, 0, walletW - header.h, header.h - 4)
    local hint = text(modal, "InspectHint", "Tap an item\nfor details", 19, 25)
    Theme.rect(
        hint,
        (width + titleW) / 2 + 10,
        header.y,
        (width - titleW) / 2 - header.x - 10,
        header.h
    )
    if layout.groups.supplies then
        local strip = surface(modal, "Supplies", C.ice, 23, 16)
        place(strip, layout.groups.supplies)
        local title = text(modal, "SuppliesTitle", "SUPPLIES", 22, 26)
        place(title, layout.sections.supplies)
        title.Visible = layout.sections.supplies.w > 0
    end
    for index, r in layout.cards do
        local supply = index > 4
        local pos = Layout.card(r.w, r.h, supply)
        local card = surface(modal, "Offer" .. index, C.paper, 25, supply and 12 or 18)
        place(card, r)
        local inspect = Theme.make("TextButton", {
            Name = "Inspect",
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 28,
        }, card)
        place(inspect, pos.inspect)
        local model = viewport(inspect, "Item", 29)
        place(model, pos.model)
        local name = text(inspect, "Name", "", pos.short and 18 or 25, 31)
        if not supply then
            local nameBand = Theme.frame(inspect, "NameBand", C.aqua, 30)
            place(nameBand, pos.name)
            Theme.corner(nameBand, 10)
        end
        place(name, pos.name)
        local level = text(inspect, "Level", "", pos.short and 12 or 16, 31)
        place(level, pos.level)
        level.TextXAlignment = supply and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
        local price
        if not supply then
            price = text(card, "Price", "", pos.short and 18 or 26, 31)
            place(price, pos.price)
            price.Visible = pos.price.h > 0
        end
        local buy = button(card, "Buy", "Buy", C.green, function()
            local offer = host.snapshot and host.snapshot.shopOffers[index]
            if offer then
                host:_send("buy", { offer = index, itemId = offer.id })
            end
        end, 32)
        place(buy, pos.purchase)
        local hold
        if not supply then
            hold = button(card, "Hold", "Hold", C.ice, function()
                local offer = host.snapshot and host.snapshot.shopOffers[index]
                if offer then
                    local data = Catalog.Items[offer.id]
                    host:_send(
                        data.evolved and "cycleEvolution" or "freeze",
                        { offer = index, itemId = offer.id }
                    )
                end
            end, 32)
            place(hold, pos.hold)
        end
        local function resolve()
            local offer = host.snapshot and host.snapshot.shopOffers[index]
            return offer and offer.id, offer and host:_offerLevel(offer) or 1
        end
        inspect.Activated:Connect(function()
            host.selectedOffer, host.selectedSlot, host.selectedPerk = index, nil, nil
            host:_updateInventory()
            Shop.refresh(host, host.snapshot)
            local id, levelNow = resolve()
            if id and not layout.sidebar then
                host.inspector:show(id, levelNow, inspect, true)
            end
        end)
        if not layout.sidebar then
            host.inspector:bind(inspect, resolve)
        end
        self.cards[index] = {
            card = card,
            inspect = inspect,
            viewport = model,
            name = name,
            level = level,
            price = price,
            buy = buy,
            hold = hold,
            positions = pos,
            short = pos.short,
            rect = r,
        }
    end
    if layout.sidebar then
        local r = layout.sidebar
        local panel = surface(modal, "ItemDetails", C.ice, 24, 18)
        place(panel, r)
        local title = text(panel, "Title", "INSPECT ITEM", 24, 26)
        Theme.rect(title, 8, 8, r.w - 16, 36)
        self.preview = viewport(panel, "Preview", 26)
        Theme.rect(self.preview, 8, 48, r.w - 16, math.min(240, r.h * 0.38))
        local y = 54 + math.min(240, r.h * 0.38)
        self.detailName = text(panel, "Name", "", 25, 27)
        Theme.rect(self.detailName, 10, y, r.w - 20, 54)
        self.detailTrigger = text(panel, "Trigger", "", 19, 27)
        Theme.rect(self.detailTrigger, 12, y + 58, r.w - 24, 56)
        self.detailBody = text(panel, "Effect", "", 19, 27)
        Theme.rect(self.detailBody, 14, y + 116, r.w - 28, math.max(30, r.h - y - 184))
        self.detailBody.TextYAlignment = Enum.TextYAlignment.Top
        self.detailButton = button(panel, "Inspect", "All details + recipes", C.aqua, function()
            local index = host.selectedOffer or 1
            local offer = host.snapshot.shopOffers[index]
            if offer then
                host.inspector:show(offer.id, host:_offerLevel(offer), self.detailButton, true)
            end
        end, 32)
        Theme.rect(self.detailButton, 12, r.h - 60, r.w - 24, 48)
        host.inspector:bind(self.detailButton, function()
            local offer = host.snapshot and host.snapshot.shopOffers[host.selectedOffer or 1]
            return offer and offer.id, offer and host:_offerLevel(offer) or 1
        end)
    end
    local footer = layout.footer
    local fw = (footer.w - 20) / 3
    local function action(name, caption, index, color, callback)
        local control = button(modal, name, caption, color, callback, 32)
        Theme.rect(control, footer.x + (index - 1) * (fw + 10), footer.y, fw, footer.h)
        return control
    end
    self.reroll = action("Reroll", "Reroll • 1 coin", 1, C.ice, function()
        host:_send("reroll")
    end)
    self.rack = action("Rack", "Your rack", 2, C.ice, function()
        host.shopRackOpen = not host.shopRackOpen
        host.inspector:hide()
        host:_layout()
        host:_updateModal()
    end)
    self.continue = action("Continue", "NEXT SHOT  >", 3, C.green, function()
        host.shopRackOpen = false
        host.inspector:hide()
        host.statsCleared = true
        host.selectedSlot, host.selectedOffer, host.selectedPerk = nil, nil, nil
        host:_send("continue")
    end)
    enabled(self.continue, true, "NEXT SHOT  >", C.green)
    -- Rack controls are a drawer above the shop; the existing seven slots retain
    -- their selection/merge/reorder callbacks and cached model handles.
    self.scrim = Theme.frame(modal, "RackScrim", C.ink, 58)
    self.scrim.Size = UDim2.fromScale(1, 1)
    self.scrim.BackgroundTransparency = 0.35
    self.scrim.Active = true
    self.scrim:SetAttribute("BlocksAim", true)
    local drawer = surface(modal, "RackDrawer", C.paper, 60, 18)
    drawer.Active = true
    local dw = width - 24
    local dh = math.min(220, height - 24)
    Theme.rect(drawer, 12, math.max(8, (height - dh) / 2), dw, dh)
    self.drawer = drawer
    self.rackHint = text(
        drawer,
        "Hint",
        "Select an item to sell. Select another slot to move or merge.",
        18,
        62
    )
    Theme.rect(self.rackHint, 12, 6, dw - 24, 30)
    self.sell = button(drawer, "Sell", "Select to sell", C.gold, function()
        local slot = host.selectedSlot
        local item = slot and host.snapshot.inventory[slot]
        if item and item.id ~= "" then
            host.selectedSlot = nil
            host:_send("sell", { slot = slot })
        end
    end, 64)
    self.slot = button(drawer, "BuySlot", "+ Slot • 5 coins", C.aqua, function()
        host:_send("buySlot")
    end, 64)
    self.closeRack = button(drawer, "Close", "Done", C.green, function()
        host.shopRackOpen = false
        host.inspector:hide()
        host:_layout()
        host:_updateModal()
    end, 64)
    local bw = (dw - 40) / 3
    for index, control in { self.sell, self.slot, self.closeRack } do
        Theme.rect(control, 12 + (index - 1) * (bw + 8), dh - 56, bw, 44)
    end
    Shop.refresh(host, state)
end

function Shop.refresh(host, state)
    local self = host.shop
    if not self or not state then
        return
    end
    self.wallet.Text = tostring(state.coins)
    local displayed = {}
    for _, offer in state.shopOffers do
        displayed[offer.id] = true
    end
    local hiddenEvolution = false
    for _, id in state.evolutionChoices or {} do
        if not displayed[id] then
            hiddenEvolution = true
            break
        end
    end
    for index, cell in self.cards do
        local offer = state.shopOffers[index]
        local data = offer and Catalog.Items[offer.id]
        if data then
            local selected = (host.selectedOffer or (self.preview and 1)) == index
            cell.card.BackgroundColor3 = selected and C.ice or C.paper
            cell.card:FindFirstChildOfClass("UIStroke").Color = selected and C.aqua or C.ink
            cell.card:FindFirstChildOfClass("UIStroke").Thickness = selected and 4 or 2
            local level = host:_offerLevel(offer)
            host:_mount(cell.viewport, offer.id, level)
            cell.name.Text = data.name
            cell.level.Text = data.consumable and (tostring(offer.price) .. " coins • Supply")
                or (data.evolved and "EVOLVED · L5" or "L" .. level .. " / 5")
            local intent = Catalog.purchaseState(state.inventory, state.slots, offer, state.coins)
            local captions = {
                purchase = "Buy",
                upgrade = "Upgrade",
                use = "Use",
                evolve = "Evolve",
                sold = "Sold",
                maxLevel = "Max level",
                full = "Rack full",
                ingredients = "Need two L5",
                unavailable = "Unavailable",
            }
            local caption = captions[intent.action] or "Unavailable"
            if data.consumable then
                caption = caption .. (intent.action == "use" and " • " .. intent.price or "")
            elseif cell.short and (intent.action == "purchase" or intent.action == "upgrade") then
                caption = caption .. " • " .. intent.price
            end
            enabled(cell.buy, intent.allowed, caption, C.green)
            if cell.price then
                cell.price.Text = data.evolved and "FREE EVOLUTION"
                    or tostring(offer.price or 0) .. " coins"
            end
            if cell.hold then
                enabled(
                    cell.hold,
                    not offer.sold and (not data.evolved or hiddenEvolution),
                    data.evolved and (hiddenEvolution and "Cycle" or "Ready")
                        or (offer.frozen and "Held" or "Hold"),
                    offer.frozen and C.gold or C.ice
                )
            end
        end
    end
    if self.preview then
        local offer = state.shopOffers[host.selectedOffer or 1] or state.shopOffers[1]
        local detail = Catalog.detail(offer.id, host:_offerLevel(offer))
        host:_mount(self.preview, offer.id, host:_offerLevel(offer))
        self.detailName.Text, self.detailTrigger.Text = detail.name, detail.trigger
        local effects = {}
        for _, effect in detail.effects do
            table.insert(effects, effect.text)
        end
        self.detailBody.Text = table.concat(effects, "\n\n")
    end
    enabled(
        self.reroll,
        (state.rerollsLeft or 0) > 0 and state.coins >= 1,
        (state.rerollsLeft or 0) > 0 and "Reroll • 1 coin" or "No rerolls left",
        C.ice
    )
    self.drawer.Visible = host.shopRackOpen == true
    self.scrim.Visible = self.drawer.Visible
    self.rack.Caption.Text = host.shopRackOpen and "Close rack" or "Your rack"
    local selected = host.selectedSlot and state.inventory[host.selectedSlot]
    enabled(self.sell, selected ~= nil and selected.id ~= "", "Sell selected", C.gold)
    enabled(
        self.slot,
        state.slots < 7 and state.coins >= 5,
        state.slots < 7 and "+ Slot • 5 coins" or "All slots open",
        C.aqua
    )
end
return Shop
