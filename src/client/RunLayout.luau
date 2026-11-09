-- Pure small-screen geometry. Coordinates are relative to the core-safe root.
local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

function Layout.desktop(w, h)
    local leftW = math.clamp(w * 0.185, 225, 290)
    local rightW = math.clamp(w * 0.205, 250, 315)
    local rackW, rackH = math.min(1480, w - 300), math.clamp(h * 0.20, 124, 216)
    local sideY = h < 800 and rackH + 22 or math.max(rackH + 42, h * 0.29)
    local available = h - 114 - sideY
    local roundH = math.min(96, available * 0.16)
    local scoreH, restockH = available * 0.34, available * 0.17
    local rightX, scoreY = w - rightW - 22, sideY + roundH + 8
    local restockY = scoreY + scoreH + 8
    local perksY = restockY + restockH + 8
    local walletH, ballsH =
        math.clamp(available * 0.20, 84, 112), math.clamp(available * 0.22, 84, 120)
    local controlsW = math.min(600, w * 0.44)
    return {
        rack = rect((w - rackW) / 2, 2, rackW, rackH),
        round = rect(rightX, sideY, rightW, roundH),
        score = rect(rightX, scoreY, rightW, scoreH),
        restocks = rect(rightX, restockY, rightW, restockH),
        perks = rect(rightX, perksY, rightW, h - 114 - perksY),
        wallet = rect(22, sideY, leftW, walletH),
        balls = rect(22, sideY + walletH + 8, leftW, ballsH),
        stats = rect(22, sideY + walletH + ballsH + 16, leftW, h < 800 and 146 or 166),
        board = rect(leftW + 44, rackH + 38, w - leftW - rightW - 88, h - rackH - 146),
        controls = rect((w - controlsW) / 2, h - 96, controlsW, 72),
        speeds = rect(rightX, h - 96, math.min(300, rightW), 72),
        sound = rect(22, h - 88, 64, 64),
    }
end

function Layout.safeRect(w, h, left, top, right, bottom)
    return rect(left, top, math.max(1, w - left - right), math.max(1, h - top - bottom))
end

-- Passive rack inspection occupies less of the board. Explicitly opened details
-- retain their full reading area and touch targets.
function Layout.inspector(w, h, passiveRack)
    local small = h < 500
    local width = math.min(small and 640 or 450, w - 20)
    local height = math.min(h - 20, small and 360 or 780)
    local scale = passiveRack and 0.6 or 1
    return { w = math.floor(width * scale), h = math.floor(height * scale) }
end

function Layout.perks(w, h, count, compact, folded)
    -- Desktop uses only occupied rows. Small screens keep their established
    -- eight-slot geometry so expanding details does not reshuffle the HUD.
    local columns = folded and 4 or (compact and 8 or math.clamp(count, 1, 4))
    local rows = folded and 2 or (compact and 1 or math.ceil(math.max(1, count) / columns))
    local headerH, nameH = h < 70 and 18 or 23, h < 70 and 0 or 16
    local cw = (w - 12 - (columns - 1) * 4) / columns
    local ch = (h - headerH - 8 - (rows - 1) * 4) / rows
    local result = { headerH = headerH, cells = {} }
    for index = 1, count do
        local modelH = math.min(cw - 2, ch - nameH)
        table.insert(result.cells, {
            card = rect(
                6 + ((index - 1) % columns) * (cw + 4),
                headerH + 3 + math.floor((index - 1) / columns) * (ch + 4),
                cw,
                ch
            ),
            model = if compact or folded
                then rect((cw - modelH) / 2, 0, modelH, modelH)
                else rect(1, 0, cw - 2, ch - nameH),
            name = rect(2, ch - nameH, cw - 4, nameH),
            count = rect(cw - 24, 0, 22, 16),
        })
    end
    return result
end

-- Fullscreen rendering can extend beyond Camera.ViewportSize on cutout devices.
-- full/safe are in core-UI coordinates; board is local to the safe root.
function Layout.cameraFrame(full, safe, board)
    local worldHeight = math.max(34.5 * full.h / board.h, 26.8 * full.h / board.w)
    return {
        x = (full.w / 2 - (safe.x - full.x) - board.x - board.w / 2) * worldHeight / full.h,
        y = 11.7 + ((safe.y - full.y) + board.y + board.h / 2 - full.h / 2) * worldHeight / full.h,
        z = worldHeight / (2 * math.tan(math.rad(17.5))),
    }
end

function Layout.portrait(w, h)
    local pad, gap = 8, 6
    local width = w - pad * 2
    local unit = (width - gap * 4) / 5
    local extras = {}
    for index = 1, 5 do
        extras[index] = rect(pad + (index - 1) * (unit + gap), h - 50, unit, 44)
    end
    return {
        round = rect(pad, 0, width - 98, 44),
        navigation = rect(w - pad - 92, 0, 92, 44),
        rack = rect(pad, 48, width, 54),
        resources = rect(pad, 106, width, 30),
        score = rect(pad, 140, width, 58),
        board = rect(pad, 200, width, math.max(1, h - 312)),
        controls = rect(pad, h - 108, width, 52),
        extras = extras,
        details = rect(pad, 52, width, math.min(330, h - 160)),
        shop = rect(pad, 50, width, h - 56),
        rackOverlay = rect(pad, 50, width, 122),
    }
end

function Layout.landscape(w, h)
    local x = math.floor(w * 0.43)
    local right = Layout.portrait(w - x, h)
    for _, key in { "navigation", "rack", "resources", "score", "controls" } do
        right[key].x += x
    end
    for _, area in right.extras do
        area.x += x
    end
    right.round = rect(8, 0, x - 16, 34)
    right.board = rect(8, 42, x - 16, h - 50)
    if h < 300 then
        right.resources.h = 26
        right.score.y, right.score.h = 136, 42
        right.controls.y, right.controls.h = h - 104, 48
    end
    right.details = rect(8, 48, w - 16, h - 104)
    right.shop = rect(8, 50, w - 16, h - 56)
    right.rackOverlay = rect(8, 50, w - 16, 122)
    return right
end

return Layout
