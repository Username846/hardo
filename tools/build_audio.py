#!/usr/bin/env python3
"""Generates every sound in the game.

    python3 tools/build_audio.py            # music + sfx + narration
    python3 tools/build_audio.py music      # just one group (music | sfx | voice)
    python3 tools/build_audio.py music race # just one song
    python3 tools/build_audio.py voice force # re-record every narration line
    python3 tools/build_audio.py text       # after editing dialogue.txt: voices for new or changed
                                            # lines, and the songs whose words changed

Needs: python3, numpy, scipy, espeak-ng, oggenc (vorbis-tools).
"""
import hashlib
import json
import os
import sys
from concurrent.futures import ProcessPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synth as S  # noqa: E402
import music  # noqa: E402
import songs  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC_DIR = os.path.join(ROOT, "assets", "music")
GEN_DIR = os.path.join(ROOT, "scripts", "gen")


def words_hash(song):
    """Fingerprint of a song's words (from dialogue.txt), kept in songs.json, so the songs whose
    words were changed can be found and made again."""
    parts = []
    for name, sec in sorted(song["sections"].items()):
        for f in ("lyrics", "lyrics2", "dark", "dark2"):
            if f in sec:
                parts.append(f"{name}.{f}={sec[f]}")
    return hashlib.md5("\n".join(parts).encode("utf-8")).hexdigest()[:12]


def _render_one(args):
    sid, dark = args
    song = [s for s in songs.SONGS if s["id"] == sid][0]
    x, meta = music.render_song(song, dark)
    meta["words"] = words_hash(song)
    name = sid + ("_dark" if dark else "")
    S.write_ogg(os.path.join(MUSIC_DIR, name + ".ogg"), x, quality=0)
    return name, meta


def _try_render(args):
    try:
        return args, _render_one(args), None
    except Exception as e:  # noqa: BLE001 - reported, and the old recording is kept
        return args, None, str(e)


def build_changed_words():
    """Makes again just the songs whose words in dialogue.txt changed since they were made. A
    song whose new words can't be sung (say a line has more syllables than the tune has notes)
    keeps its old recording, and a warning says why."""
    meta_path = os.path.join(GEN_DIR, "songs.json")
    with open(meta_path) as fh:
        all_meta = json.load(fh)
    jobs = []
    for s in songs.SONGS:
        h = words_hash(s)
        for dark in ([False, True] if s.get("dark") else [False]):
            name = s["id"] + ("_dark" if dark else "")
            m = all_meta.get(name)
            if m is not None and "words" not in m:
                # made before songs.json kept track of the words: they're the ones in dialogue.txt
                m["words"] = h
            elif m is None or m["words"] != h or not os.path.exists(os.path.join(MUSIC_DIR, name + ".ogg")):
                jobs.append((s["id"], dark))
    if jobs:
        with ProcessPoolExecutor(max_workers=os.cpu_count()) as ex:
            for (sid, dark), res, err in ex.map(_try_render, jobs):
                if err:
                    print(f"::warning title=dialogue.txt::the song {sid}{' (evil)' if dark else ''} kept its old words: {err}")
                    continue
                name, meta = res
                print("  music", name, meta["length"], "s (new words)")
                all_meta[name] = meta
    else:
        print("  music: no song's words have changed")
    with open(meta_path, "w") as fh:
        json.dump(all_meta, fh, indent=0)
    write_song_gd(all_meta)


def build_music(only=None):
    jobs = []
    for s in songs.SONGS:
        if only and s["id"] != only:
            continue
        jobs.append((s["id"], False))
        if s.get("dark"):
            jobs.append((s["id"], True))
    meta_path = os.path.join(GEN_DIR, "songs.json")
    all_meta = {}
    if os.path.exists(meta_path):
        with open(meta_path) as fh:
            all_meta = json.load(fh)
    # forget songs that no longer exist
    valid = {s["id"] + sfx for s in songs.SONGS for sfx in ("", "_dark")}
    all_meta = {k: v for k, v in all_meta.items() if k in valid}
    with ProcessPoolExecutor(max_workers=os.cpu_count()) as ex:
        for name, meta in ex.map(_render_one, jobs):
            print("  music", name, meta["length"], "s")
            all_meta[name] = meta
    os.makedirs(GEN_DIR, exist_ok=True)
    with open(meta_path, "w") as fh:
        json.dump(all_meta, fh, indent=0)
    write_song_gd(all_meta)


def gd_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(float(v)) if isinstance(v, float) else str(v)
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, list):
        return "[" + ", ".join(gd_value(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ", ".join(f"{json.dumps(k)}: {gd_value(x)}" for k, x in v.items()) + "}"
    raise TypeError(v)


def write_song_gd(all_meta):
    titles = {s["id"]: s["title"] for s in songs.SONGS}
    lines = ["# AUTO-GENERATED by tools/build_audio.py - do not edit.", "extends RefCounted", "", "const SONGS := {"]
    for name in sorted(all_meta):
        m = all_meta[name]
        base = name.replace("_dark", "")
        # syllables: [time, duration, text, ends_a_word, line] - used for the karaoke-style lyric bar
        syl = [[x[0], x[1], x[2], x[3], x[4]] for x in m["syllables"]]
        entry = dict(length=m["length"], bpm=m["bpm"], title=titles.get(base, base), lines=m["lines"], syl=syl)
        lines.append(f"\t{json.dumps(name)}: {gd_value(entry)},")
    lines.append("}")
    lines.append("")
    lines.append("const KARAOKE := {")
    for name in ("karaoke", "karaoke_dark"):
        if name in all_meta:
            lines.append(f"\t{json.dumps(name)}: {gd_value(all_meta[name]['syllables'])},")
    lines.append("}")
    with open(os.path.join(GEN_DIR, "song_data.gd"), "w") as fh:
        fh.write("\n".join(lines) + "\n")


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    only = sys.argv[2] if len(sys.argv) > 2 else None
    if what in ("all", "music"):
        build_music(only)
    if what in ("all", "sfx"):
        import sfx
        sfx.build(os.path.join(ROOT, "assets", "sfx"), set(sys.argv[2:]) or None)
    if what in ("all", "voice", "text"):
        import voices
        voices.build(ROOT, force="force" in sys.argv[2:])
    if what == "text":
        build_changed_words()


if __name__ == "__main__":
    main()
