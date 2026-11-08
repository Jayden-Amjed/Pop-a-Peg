"""Verify the user's frozen native art reference, independent of Git history depth."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    record = json.loads((ROOT / 'art/catalog/native-reference.json').read_text(encoding='utf-8-sig'))
    failures = []
    for relative, expected in record['files'].items():
        path = (ROOT / relative).resolve()
        if not path.is_relative_to(ROOT) or not path.is_file():
            failures.append(relative + ': missing/outside project')
            continue
        data = path.read_bytes().replace(b'\r\n', b'\n')
        if hashlib.sha256(data).hexdigest() != expected:
            failures.append(relative + ': frozen reference changed')
    if failures:
        raise SystemExit('\n'.join(failures) + '\nNative art is frozen by user direction; use Blender/gallery modules.')
    print(f"PASS frozen native reference: {len(record['files'])} source files at {record['source_sha']}")


if __name__ == '__main__':
    main()
