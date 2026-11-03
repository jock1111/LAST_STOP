"""Fetch the CC0 creature sources needed by prepare-v4-imports.py.
The committed environment GLBs and license are the selected Kenney sources.
"""
from pathlib import Path
from urllib.request import urlopen
import zipfile

root = Path(__file__).resolve().parents[1]
cache = root / ".cache-v4"
cache.mkdir(exist_ok=True)
monster = cache / "monster"
monster.mkdir(exist_ok=True)
for filename, url in {
    "horror-poses.zip": "https://opengameart.org/sites/default/files/Poses.zip",
    "horror-colors.zip": "https://opengameart.org/sites/default/files/Colors.zip",
}.items():
    destination = cache / filename
    if not destination.exists():
        print("Downloading", url)
        with urlopen(url) as response, destination.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
with zipfile.ZipFile(cache / "horror-poses.zip") as archive:
    for name in ("Idle.fbx", "Walk.fbx", "Run.fbx", "README.txt"):
        (monster / name).write_bytes(archive.read("Poses/" + name))
with zipfile.ZipFile(cache / "horror-colors.zip") as archive:
    for name in archive.namelist():
        if name.startswith("Colors/Black/") and name.endswith(".png"):
            (monster / Path(name).name).write_bytes(archive.read(name))
print("CC0 source ready. See ART_ASSETS_V4.md for source and license provenance.")
