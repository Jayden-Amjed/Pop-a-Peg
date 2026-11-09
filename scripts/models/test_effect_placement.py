"""Validate actual source geometry against every effect's placement contract.

No Roblox or Blender dependency: use committed manifests and the pinned Luau CLI.
The generated scratch fixture is not art authority or runtime visual evidence.
"""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def luau(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + json.dumps(k) + ']=' + luau(v) for k, v in value.items()) + '}'
    if isinstance(value, list):
        return '{' + ','.join(luau(v) for v in value) + '}'
    return json.dumps(value)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--luau', default='.tools/luau.exe')
    args = parser.parse_args()
    catalog = json.loads((ROOT / 'art/catalog/index.json').read_text(encoding='utf8'))['models']
    models = []
    for entry in catalog:
        manifest = json.loads((ROOT / entry['manifest']).read_text(encoding='utf8'))
        records = []
        for obj in manifest['objects']:
            low, high = obj['bounds_min'], obj['bounds_max']
            records.append({'group': obj['motion_group'],
                            'low': [low[0], low[2], -high[1]],
                            'high': [high[0], high[2], -low[1]]})
        models.append({'id': entry['id'], 'records': records})
    harness = '''local A=require("../scripts/models/CatalogEffectAnchors")
local E=require("../scripts/models/CatalogEffectProfiles")
local models=MODELS
local count,attached,special,ambient,samples=0,0,0,0,0
local seen={}
for _,model in models do
    local id,records=model.id,model.records
    local d,origin,index=A.resolve(id,records)
    assert(not seen[id]);seen[id]=true;count+=1
    if d.mode=="ambient" then ambient+=1
    elseif d.mode=="special" then
        special+=1
        for _,group in d.groups do
            local found=false
            for _,r in records do found=found or r.group==group end
            assert(found,id.." requires actual group "..group)
        end
    else
        attached+=1
        assert(records[index].group==d.group,id.." bound wrong assembly")
        local low,high={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
        for _,r in records do for a=1,3 do low[a]=math.min(low[a],r.low[a]);high[a]=math.max(high[a],r.high[a]) end end
        for a=1,3 do
            assert(origin[a]>=low[a]-.10 and origin[a]<=high[a]+.10,id.." emitter outside physical silhouette axis"..a)
        end
        if d.face and not d.point then
            local axis=({X=1,Y=2,Z=3})[d.face:sub(2)]
            local edge=d.face:sub(1,1)=="+" and -math.huge or math.huge
            for _,r in records do if r.group==d.group then
                edge=d.face:sub(1,1)=="+" and math.max(edge,r.high[axis]) or math.min(edge,r.low[axis])
            end end
            assert(math.abs(origin[axis]-edge)<1e-7,id.." emitter is not on its declared face")
        end
        assert(not pcall(A.resolve,id,{}),id.." silently tolerated missing assembly")
    end
    for _,t in {.10,.25,.27,.40,.60,.85} do
        local raw=E.sample(id,t,1)
        -- Exercise the real profile's full affine handoff, not just an offset:
        -- rotate90 degrees, then translate. Every endpoint must follow it.
        local function transform(q)return {q[3]+.1,q[2]-.2,-q[1]+.3} end
        local mapped=E.sample(id,t,1,{transform=transform})
        assert(#raw==#mapped,id.." mapping changed particle count")
        for i,a in raw do
            for _,key in {"a","b"} do if a[key] then
                local expect=transform(a[key])
                for axis=1,3 do assert(math.abs(mapped[i][key][axis]-expect[axis])<1e-8,id.." endpoint lost emitter rotation") end
            end end
        end
        samples+=1
    end
end
assert(count==78 and attached+special+ambient==78)
for id in A.entries do assert(seen[id],"Unregistered emitter "..id) end
assert(A.entries.quota_bonus.point[1]==.35 and A.entries.quota_bonus.point[2]==.46 and A.entries.quota_bonus.point[3]==0,"Quota must strike the paper plate")
assert(#E.sample("quota_bonus",.24,1)==0,"Quota impact precedes contact")
local impact=E.sample("quota_bonus",.27,1)
assert(#impact>12,"Quota contact is missing")
for i=1,12 do assert(impact[i].a[2]==0 and impact[i].b[2]==0,"Quota ring must spread in the horizontal plate plane") end
assert(A.entries.bubble_wand.group=="WandLoop","Wand must use its real moving loop")
assert(A.entries.tap_driver.face=="+X" and A.entries.tap_driver.axis=="+X","Piston effect must leave the tip")
assert(A.entries.tuning_oil.group=="Spout" and A.entries.tuning_oil.axis=="-Y","Oil must drip from the spout")
print(string.format("PASS effect placement: %d actual manifests, %d attached/body, %d special, %d intentional ambient, %d affine sample contracts",count,attached,special,ambient,samples))
'''.replace('MODELS', luau(models))
    scratch = ROOT / 'scratch'
    scratch.mkdir(exist_ok=True)
    with tempfile.NamedTemporaryFile('w', suffix='.luau', prefix='effect-placement-', dir=scratch,
                                     encoding='utf8', delete=False) as file:
        file.write(harness)
        path = Path(file.name)
    try:
        subprocess.run([str((ROOT / args.luau).resolve()), str(path)], cwd=ROOT, check=True)
    finally:
        path.unlink()


if __name__ == '__main__':
    main()
