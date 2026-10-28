"""The owner's MIDI pack (art/music/, from Midis.zip) into the mod, under 8-character lump names:

    python tools/art/import_music.py      # nbc/music/NBCAxx.mid (ambient), NBCOxx.mid (operations), NBCTACT.mid

Which track plays where is in nbc/zscript/nbc/music.zs (and the title / hub lines in MAPINFO.txt).
"""
import os
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "art", "music")
OUT = os.path.join(ROOT, "nbc", "music")

NAMES = {
    "amb01_versalife_68bpm.mid": "NBCA01",
    "amb01_versafarm_68bpm.mid": "NBCA01B",
    "amb02_zufang_62bpm.mid": "NBCA02",
    "amb02_hengsha_62bpm.mid": "NBCA02B",
    "amb03_synapse_58bpm.mid": "NBCA03",
    "amb04_metro_72bpm.mid": "NBCA04",
    "amb05_panchaea_54bpm.mid": "NBCA05",
    "amb05_panchaea_2_54bpm.mid": "NBCA05B",
    "amb06_unatco_2_78bpm.mid": "NBCA06",
    "amb07_golem_60bpm.mid": "NBCA07",
    "amb08_neuraldrift_50bpm.mid": "NBCA08",
    "amb09_autopsy_64bpm.mid": "NBCA09",
    "amb10_picus_70bpm.mid": "NBCA10",
    "op02_blackice_104bpm.mid": "NBCO02",
    "op03_ghostprotocol_76bpm.mid": "NBCO03",
    "op04_silentcipher_88bpm.mid": "NBCO04",
    "op05_sector7_116bpm.mid": "NBCO05",
    "op06_sleeperagent_82bpm.mid": "NBCO06",
    "op07_satellite_98bpm.mid": "NBCO07",
    "op08_thermalscan_90bpm.mid": "NBCO08",
    "op09_deaddrop_80bpm.mid": "NBCO09",
    "op10_lasergrid_110bpm.mid": "NBCO10",
    "op11_shadowrunner_96bpm.mid": "NBCO11",
    "tactical_stealth_92bpm.mid": "NBCTACT",
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for src, name in NAMES.items():
        shutil.copyfile(os.path.join(SRC, src), os.path.join(OUT, name + ".mid"))
    print("copied %d tracks to nbc/music/" % len(NAMES))


if __name__ == "__main__":
    main()
