"""Regression tests for immutable upload history and explicit active revisions.

The temporary partial upload below is a synthetic fixture, never upload evidence.
It reuses one GLB's geometry to test archive selection/corruption handling without
requiring Blender, Studio, credentials, or writes to accepted repository assets.
"""
import copy
import json
from pathlib import Path
import shutil
import struct
import tempfile
import unittest

import bind_catalog_import as binder
import validate_catalog as audit


ROOT = Path(__file__).resolve().parents[2]


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf8')


class RevisionArchiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        scratch = ROOT / 'scratch'
        scratch.mkdir(exist_ok=True)
        cls.temporary = tempfile.TemporaryDirectory(prefix='revision-test-', dir=scratch)
        cls.root = Path(cls.temporary.name).resolve()
        shutil.copytree(ROOT / 'art/catalog', cls.root / 'art/catalog',
                        ignore=lambda directory, names: ['revisions'] if Path(directory) == ROOT / 'art/catalog' and 'revisions' in names else [])
        cls.manifests = {}
        for entry in audit.read_json(ROOT / 'art/catalog/index.json')['models']:
            cls.manifests[entry['id']] = audit.read_json(ROOT / entry['manifest'])
        original = cls.root / 'art/catalog/uploaded'
        cls.revision = cls.root / 'art/catalog/revisions/TEST'
        cls.revision.mkdir(parents=True)
        active = {ident: 'art/models/studio-import.json' for ident in audit.PILOTS}
        for proof in sorted(original.glob('*.receipt.json')):
            for model in audit.read_json(proof)['models']:
                active[model['id']] = proof.relative_to(cls.root).as_posix()
        # Restore the original baseline when these tests run after real revisions
        # have landed. Original history stays authoritative for this fixture.
        existing_index = ROOT / 'art/catalog/revisions/index.json'
        if existing_index.exists():
            for record in audit.read_json(existing_index)['historical_sources']:
                ident = record['id']
                if active[ident] == record['receipt']:
                    target = cls.root / 'art/catalog' / ident
                    shutil.copyfile(ROOT / record['source'], target / (ident + '.blend'))
                    shutil.copyfile(ROOT / record['manifest'], target / 'manifest.json')
                    cls.manifests[ident] = audit.read_json(target / 'manifest.json')
        historical = cls.revision / 'previous/burst_capsule'
        shutil.copytree(cls.root / 'art/catalog/burst_capsule', historical)
        cls.old_receipt = active['burst_capsule']
        cls.batch_name = 'catalog-partial-001'
        cls.proof_relative = 'art/catalog/revisions/TEST/' + cls.batch_name + '.receipt.json'
        active['burst_capsule'] = cls.proof_relative
        cls.index_path = cls.root / 'art/catalog/revisions/index.json'
        cls.index = {'schema': 1, 'active': active, 'historical_sources': [{
            'id': 'burst_capsule', 'receipt': cls.old_receipt,
            'source': 'art/catalog/revisions/TEST/previous/burst_capsule/burst_capsule.blend',
            'manifest': 'art/catalog/revisions/TEST/previous/burst_capsule/manifest.json',
        }]}
        write_json(cls.index_path, cls.index)

        # A new source hash and authored group distinguish active and history.
        current = cls.root / 'art/catalog/burst_capsule'
        source_path = current / 'burst_capsule.blend'
        source_path.write_bytes(b'SYNTHETIC TEST SOURCE; not a usable Blender asset')
        source = copy.deepcopy(cls.manifests['burst_capsule'])
        source['blend_sha256'] = audit.sha(source_path)
        source['objects'][0]['motion_group'] = 'TestRevisionCap'
        write_json(current / 'manifest.json', source)
        cls.manifests['burst_capsule'] = source

        batch = audit.read_json(original / 'catalog-001.manifest.json')
        batch['name'] = cls.batch_name
        batch['file'] = cls.batch_name + '.glb'
        batch['models'] = [m for m in batch['models'] if m['id'] == 'burst_capsule']
        batch['models'][0]['blend_sha256'] = source['blend_sha256']
        batch['objects'] = [p for p in batch['objects'] if p['id'] == 'burst_capsule']
        batch['objects'][0]['motion_group'] = 'TestRevisionCap'
        chosen = {p['name'] for p in batch['objects'] + batch['calibration']}
        data = (original / 'catalog-001.glb').read_bytes()
        length = struct.unpack_from('<I', data, 12)[0]
        doc = json.loads(data[20:20+length])
        doc['nodes'] = [n for n in doc['nodes'] if n.get('name') in chosen]
        doc['scenes'] = [{'nodes': list(range(len(doc['nodes'])))}]
        doc['scene'] = 0
        encoded = json.dumps(doc, separators=(',', ':')).encode()
        encoded += b' ' * (-len(encoded) % 4)
        tail = data[20+length:]
        glb_path = cls.revision / batch['file']
        glb_path.write_bytes(struct.pack('<4sIIII', b'glTF', 2, 20+len(encoded)+len(tail), len(encoded), 0x4E4F534A) + encoded + tail)
        batch['glb_sha256'] = audit.sha(glb_path)
        cls.batch_path = cls.revision / (cls.batch_name + '.manifest.json')
        write_json(cls.batch_path, batch)
        names = {doc['meshes'][n['mesh']]['name'] for n in doc['nodes']}
        raw = [p for p in audit.read_json(original / 'catalog-001.raw.json') if p['name'] in names]
        for p in raw:
            p['mesh'] += '99'  # Synthetic, distinct IDs for a new upload receipt.
        cls.raw_path = cls.revision / (cls.batch_name + '.raw.json')
        write_json(cls.raw_path, raw)
        operation = {'batchName': cls.batch_name, 'operationId': 'synthetic-revision',
                     'path': 'operations/synthetic-revision', 'done': False}
        receipt = dict(operation, done=True, response={'assetId': '999999',
                       'creationContext': {'creator': {'userId': '583716264'}},
                       'moderationResult': {'moderationState': 'Approved'}})
        write_json(cls.revision / 'operations.json', [operation])
        write_json(cls.revision / 'receipts.json', [receipt])
        previous_root = binder.ROOT
        try:
            binder.ROOT = cls.root
            binder.bind(cls.batch_path, cls.raw_path, '999999', 'synthetic-revision', cls.root / cls.proof_relative)
        finally:
            binder.ROOT = previous_root

    @classmethod
    def tearDownClass(cls):
        assert cls.root.is_relative_to((ROOT / 'scratch').resolve())
        cls.temporary.cleanup()

    def validate(self):
        return audit.validate_batches(self.root, self.manifests, '583716264')

    def corrupt(self, path, content, expected):
        original = path.read_bytes()
        try:
            path.write_bytes(content)
            with self.assertRaisesRegex(ValueError, expected):
                self.validate()
        finally:
            path.write_bytes(original)

    def test_partial_revision_counts_only_current_models(self):
        report = self.validate()
        self.assertEqual(report['batches'], 11)
        self.assertEqual(report['revision_batches'], 1)
        self.assertEqual(report['superseded_models'], 1)
        self.assertEqual(report['new_models'], 75)
        self.assertEqual(report['new_mesh_parts'], sum(len(m['objects']) for ident, m in self.manifests.items() if ident not in audit.PILOTS))
        self.assertGreater(report['archived_mesh_parts'], report['new_mesh_parts'])

    def test_index_cannot_silently_ignore_revision(self):
        original = self.index_path.read_bytes()
        self.index_path.unlink()
        try:
            with self.assertRaisesRegex(ValueError, 'require an explicit active index'):
                self.validate()
        finally:
            self.index_path.write_bytes(original)

    def test_wrong_active_receipt_rejects_current_source(self):
        index = copy.deepcopy(self.index)
        index['active']['burst_capsule'] = self.old_receipt
        self.corrupt(self.index_path, json.dumps(index).encode(), 'bytes differ')

    def test_missing_preserved_history_fails(self):
        index = copy.deepcopy(self.index)
        index['historical_sources'] = []
        self.corrupt(self.index_path, json.dumps(index).encode(), 'missing preserved source')

    def test_history_bytes_are_still_verified(self):
        record = self.index['historical_sources'][0]
        self.corrupt(self.root / record['source'], b'changed previous source', 'bytes differ')
        self.corrupt(self.root / record['manifest'], b'{}', 'bytes differ')

    def test_new_and_old_export_bytes_are_verified(self):
        for path in [self.revision / (self.batch_name + '.glb'), self.root / 'art/catalog/uploaded/catalog-001.glb']:
            self.corrupt(path, b'changed GLB', 'bytes differ')

    def test_raw_mesh_identity_is_pinned(self):
        raw = audit.read_json(self.raw_path)
        raw[0]['mesh'] = 'rbxassetid://1234'
        self.corrupt(self.raw_path, json.dumps(raw).encode(), 'bytes differ')

    def test_upload_name_cannot_rebind_another_batch(self):
        path = self.revision / 'receipts.json'
        rows = audit.read_json(path)
        rows[0]['batchName'] = 'catalog-partial-other'
        self.corrupt(path, json.dumps(rows).encode(), 'incomplete batch archive')


if __name__ == '__main__':
    unittest.main()
