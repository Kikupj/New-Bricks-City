"""Pack nbc/ into dist/NewBricksCity.pk3 (a zip with nbc/'s contents at its root).

    python tools/build_pk3.py
    uzdoom.exe -iwad freedoom-0.13.0\\freedoom2.wad -file dist\\NewBricksCity.pk3
"""
import os
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NBC = os.path.join(ROOT, "nbc")
OUT = os.path.join(ROOT, "dist", "NewBricksCity.pk3")
JUNK = {"thumbs.db", "desktop.ini", ".ds_store"}


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    count = 0
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for d, dirs, files in os.walk(NBC):
            dirs.sort()
            for f in sorted(files):
                if f.lower() in JUNK:
                    continue
                full = os.path.join(d, f)
                z.write(full, os.path.relpath(full, NBC).replace(os.sep, "/"))
                count += 1
    print(f"{os.path.relpath(OUT, ROOT)}: {count} files, {os.path.getsize(OUT) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
