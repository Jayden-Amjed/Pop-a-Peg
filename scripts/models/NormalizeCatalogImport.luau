-- Normalize clones only; retain the observed raw upload untouched for provenance.
-- Calibration points establish importer scale and baked orientation, never guesses.
return function(raw, package, destination)
    local function xyz(v)
        return Vector3.new(v[1], v[3], -v[2])
    end
    local function size(v)
        return Vector3.new(v[1], v[3], v[2])
    end
    local function worldExtents(frame, extent)
        local function absolute(v)
            return Vector3.new(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
        end
        return absolute(frame.RightVector) * extent.X
            + absolute(frame.UpVector) * extent.Y
            + absolute(frame.ZVector) * extent.Z
    end
    local observed = {}
    for _, part in raw:GetDescendants() do
        if part:IsA("MeshPart") then
            assert(not observed[part.Name], "Duplicate imported name: " .. part.Name)
            observed[part.Name] = part
        end
    end
    local c = package.calibration
    local origin, xpoint, zpoint = observed[c[1].name], observed[c[2].name], observed[c[3].name]
    assert(origin and xpoint and zpoint, "Calibration meshes missing")
    for _, record in c do
        local part = observed[record.name]
        assert(part.MeshId == record.mesh_id, "Calibration identity changed")
        assert(
            (part.Size - Vector3.one * 0.28).Magnitude < 0.0001,
            "Calibration cube dimensions changed"
        )
    end
    local sourceOrigin, sourceX, sourceZ =
        xyz(c[1].center_blender_studs),
        xyz(c[2].center_blender_studs),
        xyz(c[3].center_blender_studs)
    local right, back = xpoint.Position - origin.Position, zpoint.Position - origin.Position
    local sx, sz =
        right.Magnitude / (sourceX - sourceOrigin).Magnitude,
        back.Magnitude / (sourceZ - sourceOrigin).Magnitude
    assert(math.abs(sx - sz) < 0.0001 and math.abs(sx - 0.28) < 0.0001, "Unexpected import scale")
    right, back = right.Unit, back.Unit
    assert(math.abs(right:Dot(back)) < 0.0001, "Skewed importer axes")
    local rotation = CFrame.fromMatrix(Vector3.zero, right, back:Cross(right), back)
    for _, axis in { rotation.RightVector, rotation.UpVector, rotation.ZVector } do
        assert(
            math.max(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)) > 0.9999,
            "Non-axis-aligned import needs review"
        )
    end
    local repaired = {}
    for _, manifest in package.models do
        local id = manifest.id
        assert(not destination:FindFirstChild(id), "Model exists: " .. id)
        local model = Instance.new("Model")
        model.Name = id
        local lo, hi = manifest.bounds_min, manifest.bounds_max
        local center = xyz({ (lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2, (lo[3] + hi[3]) / 2 })
        for _, record in manifest.objects do
            local original = assert(observed[record.imported_name or record.name], record.name)
            assert(original.MeshId == record.mesh_id, "Mesh identity changed: " .. record.name)
            local expected = size(record.size_blender_studs)
            local rotated = worldExtents(rotation, expected)
            assert(
                (worldExtents(original.CFrame, original.Size / sx) - rotated).Magnitude < 0.002,
                "Imported bounds differ: " .. record.name
            )
            local part = original:Clone()
            part.Name = record.name
            part.Size = original.Size / sx
            part.CFrame = CFrame.new(xyz(record.center_blender_studs) - center)
                * rotation:Inverse()
                * original.CFrame.Rotation
            local rgb = record.color_srgb
            part.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
            part.Transparency = record.transparency or (1 - (record.alpha or 1))
            part.TextureID = ""
            for _, child in part:GetChildren() do
                if child:IsA("SurfaceAppearance") or child:IsA("PackageLink") then
                    child:Destroy()
                end
            end
            part.Material, part.Reflectance =
                Enum.Material.SmoothPlastic, if record.material == "gold" then 0.06 else 0
            part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
            part.CastShadow = true
            part:SetAttribute("MotionGroup", record.motion_group)
            part:SetAttribute("MotionPivot", xyz(record.motion_pivot) - center)
            part:SetAttribute("AuthoredPosition", xyz(record.center_blender_studs))
            part:SetAttribute("CompressionSpan", record.compression_span)
            part:SetAttribute("TriangleCount", record.triangles)
            part:SetAttribute("GeometrySHA256", record.geometry_sha256)
            part.Parent = model
        end
        model.WorldPivot = CFrame.new()
        model:SetAttribute("ItemId", id)
        model:SetAttribute("ItemLevel", 1)
        model:SetAttribute("DisplayName", manifest.display_name or manifest.name)
        model:SetAttribute("Category", manifest.category)
        model:SetAttribute("TriangleCount", manifest.triangles)
        model:SetAttribute("PartCount", #manifest.objects)
        model:SetAttribute("SourceAssetId", package.asset_id)
        model:SetAttribute("SourceGLBSHA256", package.glb_sha256)
        model.Parent = destination
        table.insert(repaired, { id = id, parts = #manifest.objects })
        task.wait()
    end
    game:GetService("ChangeHistoryService"):SetWaypoint("Normalize catalog import copies")
    return { models = repaired, scale = sx, correction = { rotation:Inverse():GetComponents() } }
end
