"""Reads dialogue.txt (every line anyone says, and the words to every song; see the notes at
the top of it). The game reads the same file (scripts/game_text.gd) and must split lines into
boxes the same way, because each box's voice clip is named after its exact text."""
import os
import re

PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dialogue.txt")

# who -> narrator mood number (same order as Narrator's enum)
WHO = {"host": 0, "evil host": 1, "grey host": 2, "dijimon": 3, "everyone": 4, "announcer": 5, "chumbo": 6,
       "rocko": 7, "evil dijimon": 8, "tony honk": 9, "pip": 10, "taxman": 11, "sarge": 12, "evil announcer": 13}

HEAD_RE = re.compile(r"^\[(\w+)\]")
ENTRY_RE = re.compile(r"^(\w+)\s*\(([^)]*)\)\s*:\s*(.*)$")
SONG_RE = re.compile(r"^song\s+(\w+)\s*-\s*(\w+)\s*(?:\(([^)]*)\))?\s*:\s*$")


def boxes(words):
    """\\\\n = a new box, \\n = a new line in the same box."""
    out = []
    for box in words.split("\\\\n"):
        b = "\n".join(row.strip() for row in box.split("\\n")).strip()
        if b:
            out.append(b)
    return out


def read(path=PATH):
    """-> (lines, songs). lines: [(section, name, mood, [boxes])] in file order.
    songs: {song_id: {section_name: {field: "row / row / ..."}}}, field = lyrics, lyrics2, dark or
    dark2. In the rows, \\\\n becomes a new window (" / ") and \\n a line break in the window (" ¶ ")."""
    lines, songs = [], {}
    sec = ""
    song = None
    with open(path, encoding="utf-8") as fh:
        raw_lines = fh.read().split("\n")
    for n, raw in enumerate(raw_lines, 1):
        ln = raw.rstrip()
        bare = ln.strip()
        if bare.startswith("#"):
            continue
        if bare == "":
            song = None
            continue
        m = HEAD_RE.match(ln)
        if m:
            sec, song = m.group(1), None
            continue
        m = SONG_RE.match(ln)
        if m:
            sid, part, flags = m.group(1), m.group(2), (m.group(3) or "").lower()
            field = ("dark" if "evil" in flags else "lyrics") + ("2" if "2nd" in flags else "")
            song = songs.setdefault(sid, {}).setdefault(part, {})
            song[field] = []
            song = song[field]
            continue
        if song is not None and raw[:1] in (" ", "\t"):
            song.append(bare)
            continue
        m = ENTRY_RE.match(ln)
        if m:
            who = m.group(2).strip().lower()
            if who not in WHO:
                raise ValueError(f"dialogue.txt line {n}: nobody called \"{who}\"")
            lines.append((sec, m.group(1), WHO[who], boxes(m.group(3))))
            song = None
            continue
        raise ValueError(f"dialogue.txt line {n}: can't read this line: {ln}")
    # song rows -> the "a / b / c" text tools/songs.py has always used
    for parts in songs.values():
        for part, fields in parts.items():
            for field, rows in fields.items():
                windows = []
                for row in rows:
                    for w in row.split("\\\\n"):
                        w = re.sub(r"\s*\\n\s*", " ¶ ", w.strip())
                        if w:
                            windows.append(w)
                fields[field] = " / ".join(windows)
    return lines, songs
