"""Bind the observed pilot MeshIds to the exact files used for this upload.

This is a replay of one recorded import, not a generic ID assignment command.
Never update these pins merely to accept a changed model: new geometry requires
a separate approved upload and a newly observed asset/mesh identity record.
"""

import hashlib
import json
import struct
from pathlib import Path


UPLOADED_BUNDLE_SHA256 = "aaac1d192ca6bdf394fbd02e5dd6958f82416525bf6acad77eb6faa73d084be1"
UPLOADED_MANIFEST_SHA256 = {
    "spring_coil": "56ee9765bf8fc755123f74f4cc5270da6ff79233c8acea464670b0a0192c49f3",
    "seed_bank": "70a82b8879b08fb851829ab3f35be844a67ad3444747b4428e8fcda3f2eec63f",
    "chest_common": "1ab9634341bd7ce97899c8d94f1cc06b2d1e949429133d57556c1d43add97950",
}
OBSERVED_IMPORT_SHA256 = "84b7a21c397ffe3b168cdd87425d6654501de5add620ab19b6b66fa76386a0b0"


def verified_bytes(path, expected, label):
    payload = path.read_bytes()
    if path.suffix == ".json":
        # Git text normalization must not break the evidence on another OS.
        payload = payload.replace(b"\r\n", b"\n")
    actual = hashlib.sha256(payload).hexdigest()
    if actual != expected:
        raise ValueError(
            f"{label} differs from the recorded upload: expected {expected}, got {actual}. "
            "Refusing to associate existing MeshIds with different geometry or evidence."
        )
    return payload


def main(root=None):
    root = Path(root) if root is not None else Path(__file__).resolve().parents[2]
    glb = verified_bytes(
        root / "art/models/uploaded/pop-a-peg-blender-pilots.glb",
        UPLOADED_BUNDLE_SHA256,
        "Uploaded GLB bundle",
    )
    observed_bytes = verified_bytes(
        root / "art/models/uploaded/studio-import-raw.json",
        OBSERVED_IMPORT_SHA256,
        "Observed Studio import",
    )
    # Validate every manifest before writing any output, including Blender/source
    # hashes and geometry signatures. Matching bounds alone cannot identify a mesh.
    manifests = {
        model_id: json.loads(
            verified_bytes(
                root / "art/models" / model_id / "manifest.json",
                expected,
                f"Uploaded {model_id} manifest",
            )
        )
        for model_id, expected in UPLOADED_MANIFEST_SHA256.items()
    }
    magic, version, total_length = struct.unpack_from("<4sII", glb, 0)
    assert magic == b"glTF" and version == 2 and total_length == len(glb)
    length, kind = struct.unpack_from("<II", glb, 12)
    assert kind == 0x4E4F534A
    gltf = json.loads(glb[20:20 + length])
    observed = json.loads(observed_bytes)
    by_name = {part["name"]: part for part in observed}
    assert len(observed) == len(by_name) == 26, "Unexpected imported count or duplicate name"

    records = []
    for model_id, manifest in manifests.items():
        for part in manifest["objects"]:
            nodes = [node for node in gltf["nodes"] if node["name"] == part["name"] + "_export"]
            assert len(nodes) == 1, (part["name"], "Missing or duplicate GLB node")
            mesh_name = gltf["meshes"][nodes[0]["mesh"]]["name"]
            got = by_name[mesh_name]
            x, y, z = part["size_blender_studs"]
            expected = (x * .28, z * .28, y * .28)
            assert len(got["size"]) == 3
            assert max(abs(a - b) for a, b in zip(got["size"], expected)) < .00001, (
                mesh_name, got["size"], expected
            )
            assert got["mesh"].startswith("rbxassetid://"), (mesh_name, "Missing MeshId")
            records.append(dict(
                part,
                id=model_id,
                imported_name=mesh_name,
                mesh_id=got["mesh"],
                imported_size=got["size"],
                imported_position=got["pos"],
            ))
    assert len(records) == len({record["mesh_id"] for record in records}) == 25

    result = {
        "schema": 1,
        "asset_id": "112890615474684",
        "owner_user_id": 583716264,
        "upload_operation": "e154117c-fac7-40a0-a440-9158ba5adf1b",
        "moderation": "Approved",
        "raw_mesh_count": 26,
        "pilot_mesh_count": 25,
        "upload_proof": {
            "bundle_sha256": UPLOADED_BUNDLE_SHA256,
            "manifest_sha256": UPLOADED_MANIFEST_SHA256,
            "observed_import_sha256": OBSERVED_IMPORT_SHA256,
            "scope": "Pins the recorded upload and observed IDs; does not download or rehash Roblox mesh bytes.",
        },
        "calibration_imported_studs": [.28, .28, .28],
        "repair_scale": 1 / .28,
        "repair_yaw_degrees": 180,
        "materials_restored_from": "source sRGB palette",
        "package_policy": "Keep raw package separate. Normalized local pilot copies do not update the uploaded package.",
        "objects": records,
    }
    target = root / "art/models/studio-import.json"
    target.write_text(json.dumps(result, indent=2) + "\n", encoding="utf8")
    print("Matched 25 pilot MeshParts to the exact pinned upload; dimensions and source evidence verified.")
    return result


if __name__ == "__main__":
    main()
