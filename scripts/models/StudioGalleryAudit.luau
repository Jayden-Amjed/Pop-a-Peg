-- Real inspector mounting and full-pose camera fit, at default Fit (100%).
return function(first, last)
    local gui = game.Players.LocalPlayer.PlayerGui.CatalogInspector
    local catalog = require(game.ReplicatedStorage.CatalogLibrary.CatalogInfo)
    local report = { checked = 0, corners = 0, failures = {}, loaded = {}, minimumMargin = 1 }
    gui:SetAttribute("NativeComparison", false)
    gui:SetAttribute("Zoom", 1)
    gui:SetAttribute("CameraView", "Three-quarter")
    gui:SetAttribute("Strength", 2)
    for index = first, last do
        local id = catalog[index].id
        gui:SetAttribute("SelectedId", id)
        local deadline = os.clock() + 4
        repeat
            task.wait(0.03)
        until gui:GetAttribute("Ready") or os.clock() > deadline
        if not gui:GetAttribute("Ready") or gui:GetAttribute("Failures") ~= "" then
            table.insert(report.failures, id .. ": " .. tostring(gui:GetAttribute("Failures")))
            continue
        end
        local viewport
        for _, item in gui:GetDescendants() do
            if item:IsA("ViewportFrame") and item:FindFirstChild(id) then
                viewport = item
                break
            end
        end
        if not viewport then
            table.insert(report.failures, id .. ": missing mounted model")
            continue
        end
        for _, pose in { 0, 0.10, 0.19, 0.27, 0.36, 0.45, 0.54, 0.63, 0.72, 0.81, 0.90, 1 } do
            gui:SetAttribute("Pose", pose)
            task.wait(0.035)
            local camera = viewport.CurrentCamera
            local aspect = viewport.AbsoluteSize.X / viewport.AbsoluteSize.Y
            local tangent = math.tan(math.rad(camera.FieldOfView / 2))
            for _, part in viewport[id]:GetDescendants() do
                if not part:IsA("BasePart") then
                    continue
                end
                for _, x in { -1, 1 } do
                    for _, y in { -1, 1 } do
                        for _, z in { -1, 1 } do
                            local p = camera.CFrame:PointToObjectSpace(
                                part.CFrame * (part.Size * Vector3.new(x, y, z) / 2)
                            )
                            local u, v =
                                (p.X / (-p.Z * tangent * aspect) + 1) / 2,
                                (1 - p.Y / (-p.Z * tangent)) / 2
                            local margin = math.min(u, 1 - u, v, 1 - v)
                            report.minimumMargin = math.min(report.minimumMargin, margin)
                            report.corners += 1
                            if p.Z >= 0 or margin < 0 then
                                table.insert(
                                    report.failures,
                                    id .. ": camera clips at pose " .. pose
                                )
                            end
                        end
                    end
                end
            end
        end
        table.insert(report.loaded, id)
        report.checked += 1
    end
    report.ok = #report.failures == 0
    return report
end
