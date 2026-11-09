"""Verify the built game actually ships the reviewed Blender model library."""
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
tree = ET.parse(ROOT / 'build/dev.rbxlx').getroot()

def child(parent, name):
    for node in parent.findall('Item'):
        if node.findtext("Properties/string[@name='Name']") == name:
            return node
    raise AssertionError(f'Missing game instance: {name}')

storage = child(tree, 'ReplicatedStorage')
assets = child(storage, 'CatalogAssets')
expected = json.loads((ROOT / 'art/catalog/index.json').read_text(encoding='utf8'))
models = {node.findtext("Properties/string[@name='Name']"): node for node in assets.findall('Item')}
assert set(models) == {model['id'] for model in expected['models']}, 'Game catalog IDs differ'
meshes = [node for node in assets.iter('Item') if node.get('class') == 'MeshPart']
runtime = json.loads((ROOT / 'art/catalog/runtime-artifacts.json').read_text(encoding='utf8'))
assert len(meshes) == runtime['mesh_parts'], 'Game is missing imported render parts'
for mesh in meshes:
    props = mesh.find('Properties')
    for flag, value in [('Anchored', 'true'), ('CanCollide', 'false'), ('CanTouch', 'false'), ('CanQuery', 'false')]:
        assert props.findtext(f"bool[@name='{flag}']") == value, f'Unsafe preview flag: {flag}'

library = child(storage, 'CatalogLibrary')
project = json.loads((ROOT / 'default.project.json').read_text(encoding='utf8'))
count = 0
for name, mapping in project['tree']['ReplicatedStorage']['CatalogLibrary'].items():
    if name.startswith('$') or '$path' not in mapping: continue
    path = ROOT / mapping['$path']
    if path.is_dir(): continue
    node = child(library, name)
    assert node.get('class') == 'ModuleScript', name
    actual = node.findtext("Properties/string[@name='Source']", '').replace('\r\n', '\n')
    assert actual == path.read_text(encoding='utf8').replace('\r\n', '\n'), f'Stale library module: {name}'
    count += 1
client = child(child(child(tree, 'StarterPlayer'), 'StarterPlayerScripts'), 'Client')
for name in ['Presentation', 'HubPresentation', 'Feedback']:
    source = child(client, name).findtext("Properties/string[@name='Source']", '')
    assert 'require(script.Parent.GameItemModels)' in source, f'Native call site remains: {name}'
for name in ['GameItemModels', 'GameModelPlayback', 'GameModelLoader', 'GamePreviewFit', 'GameSoundEffects']:
    node = child(client, name)
    assert node.get('class') == 'ModuleScript', name
    source = node.findtext("Properties/string[@name='Source']", '').replace('\r\n', '\n')
    assert source == (ROOT / f'src/client/{name}.luau').read_text(encoding='utf8').replace('\r\n', '\n'), name
print(f'PASS game Blender mapping: {len(models)} models, {len(meshes)} MeshParts, {count} library modules, 3 consumers and 5 adapters')
