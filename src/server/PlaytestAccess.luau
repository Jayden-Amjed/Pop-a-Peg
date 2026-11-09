-- Temporary, server-owned content access requested by this account's owner.
-- Set Enabled=false and restart the playtest/server to restore normal access.
-- Nothing here grants currency, chest contents, records, or saved ownership.
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("../shared/Catalog")
local Profile = if Shared then require(Shared.Profile) else require("../shared/Profile")

local Access = { Enabled = true, UserId = 583716264 }

function Access.active(userId)
    return Access.Enabled and userId == Access.UserId
end

function Access.runProfile(userId, profile)
    local result = Profile.clean(profile)
    if Access.active(userId) then
        result.itemUnlocks = table.clone(Catalog.ItemIds)
    end
    return result
end

function Access.viewProfile(userId, profile)
    local result = Access.runProfile(userId, profile)
    if Access.active(userId) then
        for _, id in Catalog.EvolvedIds do
            if not table.find(result.unlocks, id) then
                table.insert(result.unlocks, id)
            end
        end
    end
    -- Level badges describe completed rounds, not content access. Every stage
    -- is already visible, so do not fabricate level_*, endless, or best records.
    return result
end

function Access.captureProfile(runProfile, temporaryRunAccess)
    local result = table.clone(runProfile)
    if temporaryRunAccess then
        -- Runs cannot earn base blueprints; those are awarded directly to the
        -- real session profile by chest/research transactions in the hub.
        result.itemUnlocks = {}
    end
    return result
end

return Access
