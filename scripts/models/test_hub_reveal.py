"""Exercise the actual HubProgressionPanel source against mocked service boundaries.

Usage: python scripts/models/test_hub_reveal.py --luau .tools/luau.exe
No game source is copied into this test. Every run wraps the current module text,
reports its exact SHA256, and tests the received-reward/animation-clock contract.
"""
import argparse
import hashlib
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
PREFIX = r"""-- Generated test fixture wraps the actual source, with only service boundaries mocked.
local now = 0
local os = { clock = function() return now end }
local modules = {
    Catalog = {}, Format = {}, UiTheme = { colors = {} }, HubProgressionLayout = {},
    ItemMotion = { Profiles = { chest_legendary = { duration = 4.2 } } },
}
local Shared = { Catalog = "Catalog", Format = "Format" }
local script = { Parent = { UiTheme = "UiTheme", HubProgressionLayout = "HubProgressionLayout", ItemMotion = "ItemMotion" } }
local function require(key) return modules[key] end
local game = {}
function game:GetService(name)
    if name == "HttpService" then return { GenerateGUID = function() return "test-request" end } end
    return { Shared = Shared, CatalogLibrary = { BlenderChoreography = "ItemMotion" } }
end
local Panel = (function()
"""
SUFFIX = r"""
end)()
local function fixture()
    now = 0
    local host = { openPanel = "chests", gui = { Enabled = true }, notices = 0, renders = 0 }
    function host:setNotice(_) self.notices += 1 end
    host.onAction = function() end
    local panel = Panel.new(host)
    panel.render = function() host.renders += 1 end
    local handle = { active = false }
    function handle:pulse(strength) assert(strength == 1.5); self.active = true end
    function handle:isAnimating() return self.active end
    panel:request("openChest", { tier = "legendary" }, handle)
    return panel, host, handle
end
local function response(panel)
    panel.pendingResult = { tier = "legendary", kind = "open", itemId = "fixture-reward" }
end
local panel, host, handle = fixture()
response(panel)
now = 9
panel:step()
assert(panel.pending and panel.pendingResult and not panel.reveal, "Received reward cut off a slow chest")
assert(host.notices == 0 and host.renders == 0, "Received reward entered network timeout")
handle.active = false
panel:step()
assert(panel.reveal and not panel.pending and not panel.pendingResult and host.renders == 1, "Completed chest did not reveal exactly once")
panel:step()
assert(host.renders == 1, "Reward rendered twice")
for _, scenario in { "closed", "hidden", "destroyed" } do
    panel, host, handle = fixture()
    response(panel)
    now = 5
    if scenario == "closed" then host.openPanel = nil
    elseif scenario == "hidden" then host.gui.Enabled = false
    else handle.active = false end
    panel:step()
    assert(panel.reveal and not panel.pending, scenario .. " preview trapped received reward")
end
panel, host, handle = fixture()
now = 9
panel:step()
assert(not panel.pending and panel.retry and host.notices == 1, "Missing response did not time out with retry identity")
panel, host, handle = fixture()
response(panel)
handle.active = false
now = 1
panel:step()
assert(panel.pending and not panel.reveal, "Minimum reveal timing lost")
now = 4.2
panel:step()
assert(panel.reveal, "Minimum reveal timing never completed")
panel, host, handle = fixture()
panel.pending = nil
panel:request("buyChest", { tier = "legendary" }, handle)
panel.pendingResult = { kind = "purchase", tier = "legendary" }
panel:step()
assert(not panel.pending and not panel.pendingResult and host.notices == 1, "Chest purchase waited for open animation")
print("PASS actual HubProgressionPanel: slow received reward, completion, close/hidden/dispose, timeout/retry, minimum timing and immediate purchase")

"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", type=Path, default=ROOT / ".tools/luau.exe",
                        help="Path to the repository-pinned Luau executable")
    args = parser.parse_args()
    source_path = ROOT / "src/client/HubProgressionPanel.luau"
    source_bytes = source_path.read_bytes()
    source = source_bytes.decode("utf-8-sig")
    print("Hub reveal source:", source_path, flush=True)
    print("SHA256:", hashlib.sha256(source_bytes).hexdigest(), flush=True)
    scratch = ROOT / "scratch"
    scratch.mkdir(exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", suffix=".luau", prefix="hub-reveal-",
                                     dir=scratch, encoding="utf-8", delete=False) as output:
        fixture = Path(output.name)
        output.write(PREFIX + source + SUFFIX)
    try:
        result = subprocess.run([str(args.luau.resolve()), str(fixture)],
                                cwd=ROOT, text=True, capture_output=True, timeout=30)
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="")
        return result.returncode
    finally:
        fixture.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())

