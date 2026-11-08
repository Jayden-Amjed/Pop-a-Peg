local Catalog = require("../../src/shared/Catalog")
local out = {}
for id, definition in pairs(Catalog.Items) do
    table.insert(
        out,
        string.format(
            '{"id":%q,"name":%q,"trigger":%q,"description":%q}',
            id,
            definition.name,
            definition.triggerText or "",
            definition.description or ""
        )
    )
end
for id, definition in pairs(Catalog.Perks) do
    table.insert(
        out,
        string.format(
            '{"id":%q,"name":%q,"trigger":%q,"description":%q}',
            id,
            definition.name,
            definition.triggerText or "Run bonus",
            definition.description or ""
        )
    )
end
table.sort(out)
print("[" .. table.concat(out, ",") .. "]")
