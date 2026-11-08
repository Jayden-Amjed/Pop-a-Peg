-- Call in Edit mode with the exact captured import manifest. Does not publish.
return function(raw, manifest, destination)
    local function xyz(values)
        return Vector3.new(values[1], values[3], -values[2])
    end
    local ids = { "spring_coil", "seed_bank", "chest_common" }
    local result = {}
    for _, id in ids do
        assert(not destination:FindFirstChild(id), "Pilot already exists; review before replacing")
        local records = {}
        local lower = Vector3.new(math.huge, math.huge, math.huge)
        local upper = -lower
        for _, record in manifest.objects do
            if record.id == id then
                table.insert(records, record)
                local p = xyz(record.center_blender_studs)
                local size = xyz(record.size_blender_studs)
                size = Vector3.new(size.X, size.Y, -size.Z)
                lower = lower:Min(p - size / 2)
                upper = upper:Max(p + size / 2)
            end
        end
        local center = (lower + upper) / 2
        local model = Instance.new("Model")
        model.Name = id
        model.WorldPivot = CFrame.new()
        model:SetAttribute("ItemId", id)
        model:SetAttribute("ItemLevel", 1)
        model:SetAttribute("ArtCenter", Vector3.zero)
        model:SetAttribute("SourceAssetId", manifest.asset_id)
        for _, record in records do
            local original = raw:FindFirstChild(record.imported_name, true)
            assert(original and original:IsA("MeshPart"), record.imported_name)
            assert(original.MeshId == record.mesh_id, "Imported mesh identity differs")
            local part = original:Clone()
            part.Name = record.name
            local s = record.size_blender_studs
            part.Size = Vector3.new(s[1], s[3], s[2])
            part.CFrame = CFrame.new(xyz(record.center_blender_studs) - center)
                * CFrame.Angles(0, math.pi, 0)
            local c = record.color_srgb
            part.Color = Color3.fromRGB(c[1], c[2], c[3])
            part.Transparency = if record.material == "glass" then 0.70 else 0
            part.Material = Enum.Material.SmoothPlastic
            part.Reflectance = if record.material == "gold" then 0.08 else 0
            part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
            part.CastShadow = false
            part:SetAttribute("MotionGroup", record.motion_group)
            part:SetAttribute("MotionPivot", xyz(record.motion_pivot) - center)
            part:SetAttribute("AuthoredPosition", part.Position)
            part:SetAttribute("CompressionSpan", record.compression_span)
            part:SetAttribute("TriangleCount", record.triangles)
            part:SetAttribute("GeometrySHA256", record.geometry_sha256)
            part.Parent = model
        end
        model:SetAttribute("PartCount", #records)
        model.Parent = destination
        table.insert(result, { id = id, parts = #records })
    end
    game:GetService("ChangeHistoryService"):SetWaypoint("Normalize Blender pilot copies")
    return result
end
