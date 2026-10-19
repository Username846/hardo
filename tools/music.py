"""Song renderer: turns the definitions in songs.py into looping OGG files + timing data."""
import re

import numpy as np

import synth as S
from songs import PHONETIC, WORDS

SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "harm_minor": [0, 2, 3, 5, 7, 8, 11],
    "nat_minor": [0, 2, 3, 5, 7, 8, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "locrian_ish": [0, 1, 3, 5, 6, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
}

# Who sings: lead + chorus harmony, the same in every song.
SINGERS = ("kid", "lady")
DARK_SINGERS = ("croak", "whisper")

ROMAN = {"i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5, "vi": 6, "vii": 7}

TOKEN_RE = re.compile(r"^(b|#)?([1-7]|r)([',]*)(?::([0-9.]+))?$")


class Note:
    __slots__ = ("beat", "dur", "deg", "acc", "octv", "syl", "line", "word_end", "section")

    def __init__(self, beat, dur, deg, acc, octv):
        self.beat, self.dur, self.deg, self.acc, self.octv = beat, dur, deg, acc, octv
        self.syl = None
        self.line = -1
        self.word_end = True
        self.section = ""


def parse_melody(text, beats_per_bar, where):
    bars = [b.strip() for b in text.split("|")]
    out = []
    for bi, bar in enumerate(bars):
        notes = []
        pos = 0.0
        for tok in bar.split():
            m = TOKEN_RE.match(tok)
            if not m:
                raise ValueError(f"{where}: bad token {tok!r}")
            acc, deg, octs, dur = m.groups()
            dur = float(dur) if dur else 1.0
            if deg == "r":
                notes.append((pos, dur, None, 0, 0))
            else:
                o = octs.count("'") - octs.count(",")
                a = -1 if acc == "b" else (1 if acc == "#" else 0)
                notes.append((pos, dur, int(deg), a, o))
            pos += dur
        if abs(pos - beats_per_bar) > 1e-6:
            raise ValueError(f"{where}: bar {bi + 1} has {pos} beats: {bar}")
        out.append(notes)
    return out


def parse_chords(text, beats_per_bar):
    bars = []
    for bar in text.split("|"):
        toks = bar.split()
        explicit = [t for t in toks if ":" in t]
        chords = []
        if explicit:
            pos = 0.0
            for t in toks:
                name, b = t.split(":")
                chords.append((pos, float(b), name))
                pos += float(b)
        else:
            step = beats_per_bar / len(toks)
            for i, t in enumerate(toks):
                chords.append((i * step, step, t))
        bars.append(chords)
    return bars


def parse_lyrics(text):
    """-> list of (sung_text, display_text, word_end, line_idx), and display lines."""
    syls = []
    lines = []
    for li, line in enumerate([l.strip() for l in text.split("/") if l.strip()]):
        lines.append(re.sub(r"\{[^}]*\}", "", line).replace("-", ""))
        for word in line.split():
            parts = word.split("-")
            for k, p in enumerate(parts):
                override = re.search(r"\{([^}]*)\}", p)
                p = re.sub(r"\{[^}]*\}", "", p)
                clean = re.sub(r"[^A-Za-z']", "", p).lower()
                if override:
                    sung = override.group(1)
                elif len(parts) > 1:
                    if clean in PHONETIC:
                        sung = PHONETIC[clean]
                    elif re.search(r"[^aeiou]y$", clean):
                        sung = clean[:-1] + "ee"
                    else:
                        sung = clean
                else:
                    sung = WORDS.get(clean, clean)
                syls.append((sung, p, k == len(parts) - 1, li))
    return syls, lines


def chord_degrees(name):
    """'IV7' -> (4, seventh?)"""
    seventh = name.endswith("7")
    base = name.rstrip("7")
    return ROMAN[base.lower()], seventh


class Ctx:
    def __init__(self, song, dark):
        self.song = song
        self.dark = dark
        d = song.get("dark") or {}
        self.scale = SCALES[d.get("scale", "major")] if dark else SCALES[song["scale"]]
        self.bpm = song["bpm"] * (d.get("bpm_mul", 1.0) if dark else 1.0)
        self.key = song["key"]
        self.beats = song["beats"]
        self.spb = 60.0 / self.bpm
        self.swing = song.get("swing", 0.0) if not dark else 0.0
        self.detune = d.get("detune", 0) if dark else 0
        self.rng = np.random.default_rng(abs(hash(song["id"] + str(dark))) % (2 ** 32))

    def deg_midi(self, deg, acc=0, octv=0, base=None):
        base = self.key if base is None else base
        d = deg - 1
        return base + 12 * (octv + d // 7) + self.scale[d % 7] + acc

    def t(self, beat):
        frac = beat % 1.0
        if self.swing and abs(frac - 0.5) < 1e-6:
            beat += self.swing * 0.5
        return beat * self.spb

    def chord_tones(self, name, octv=0, seventh_ok=True):
        deg, sev = chord_degrees(name)
        steps = [0, 2, 4] + ([6] if (sev and seventh_ok) else [])
        lo = self.key + 12 * octv - 3
        out = []
        for s in steps:
            m = self.deg_midi(deg + s)
            while m < lo:
                m += 12
            while m >= lo + 12:
                m -= 12
            out.append(m)
        return sorted(out)

    def chord_root(self, name, octv=0):
        deg, _ = chord_degrees(name)
        m = self.deg_midi(deg)
        base = self.key + 12 * octv
        while m < base - 5:
            m += 12
        while m >= base + 7:
            m -= 12
        return m

    def chord_step(self, name, step):
        deg, _ = chord_degrees(name)
        return self.deg_midi(deg + step) - self.deg_midi(deg)


def build_timeline(song, ctx):
    """Expand form -> list of melody notes and chord spans with absolute beats."""
    lyr_key = "dark" if ctx.dark else "lyrics"
    notes = []
    chords = []
    entries = []
    bar_cursor = 0
    lines_out = []
    line_base = 0
    for entry_name, opt in song["form"]:
        sec = song["sections"][opt["src"]]
        mel = parse_melody(sec["melody"], ctx.beats, f"{song['id']}.{opt['src']}")
        chs = parse_chords(sec["chords"], ctx.beats)
        if len(chs) != len(mel):
            raise ValueError(f"{song['id']}.{opt['src']}: {len(chs)} chord bars vs {len(mel)} melody bars")
        b0, b1 = opt.get("bars", (0, len(mel)))
        vocal = opt.get("vocal", True)
        syls = None
        if vocal:
            # second time round a section sings its "lyrics2"/"dark2" words (else repeats)
            v = "" if opt.get("lyr", 1) == 1 else str(opt["lyr"])
            text = sec.get(lyr_key + v) or sec.get(lyr_key) or sec.get("lyrics" + v) or sec["lyrics"]
            syls, disp_lines = parse_lyrics(text)
            n_notes = sum(1 for bar in mel for n in bar if n[2] is not None)
            if n_notes != len(syls):
                raise ValueError(f"{song['id']}.{opt['src']} ({'dark' if ctx.dark else 'cute'}): "
                                 f"{n_notes} notes vs {len(syls)} syllables")
            for li, l in enumerate(disp_lines):
                lines_out.append([None, l, line_base + li])
        si = 0
        start_bar = bar_cursor
        for bi in range(b0, b1):
            for (pos, dur, deg, acc, octv) in mel[bi]:
                if deg is None:
                    continue
                n = Note((bar_cursor + bi - b0) * ctx.beats + pos, dur, deg, acc, octv)
                n.section = entry_name
                if syls is not None:
                    sung, disp, wend, li = syls[si]
                    n.syl = (sung, disp)
                    n.word_end = wend
                    n.line = line_base + li
                    si += 1
                notes.append(n)
            for (pos, dur, name) in chs[bi]:
                chords.append(((bar_cursor + bi - b0) * ctx.beats + pos, dur, name, entry_name))
        nbars = b1 - b0
        entries.append((entry_name, start_bar, nbars))
        bar_cursor += nbars
        if syls is not None:
            line_base += len(set(s[3] for s in syls))
    total_beats = bar_cursor * ctx.beats
    # line start times
    for ln in lines_out:
        first = [n for n in notes if n.line == ln[2]]
        ln[0] = ctx.t(first[0].beat) if first else 0.0
    return notes, chords, entries, total_beats, lines_out


def part_active(part, section):
    secs = part.get("sections")
    return secs is None or section in secs


def place(buf, x, start_s, gain=1.0, pan=0.0):
    i = int(start_s * S.SR)
    if i < 0:
        x = x[-i:]
        i = 0
    n = min(len(x), buf.shape[1] - i)
    if n <= 0:
        return
    l = np.cos((pan + 1) * np.pi / 4) * 1.414
    r = np.sin((pan + 1) * np.pi / 4) * 1.414
    buf[0, i:i + n] += x[:n] * gain * l
    buf[1, i:i + n] += x[:n] * gain * r


def render_part(part, ctx, notes, chords, total_beats, nsamp):
    buf = np.zeros((2, nsamp))
    kind = part["kind"]
    inst = part.get("inst")
    octv = part.get("oct", 0)
    pan = part.get("pan", 0.0)
    rng = ctx.rng

    def jitter():
        return rng.uniform(-0.006, 0.006) if not ctx.dark else rng.uniform(-0.012, 0.012)

    def det():
        return rng.uniform(-ctx.detune, ctx.detune) if ctx.detune else 0.0

    def vel():
        return rng.uniform(0.85, 1.0)

    def note(midi, start_beat, dur_beats, v=None, p=None):
        dur_s = max(0.05, dur_beats * ctx.spb)
        x = S.render_note(inst, int(midi), round(dur_s, 3), round(v if v is not None else vel(), 2), round(det(), 1))
        place(buf, x, ctx.t(start_beat) + jitter(), 1.0, pan if p is None else p)

    if kind == "melody":
        for n in notes:
            if not part_active(part, n.section):
                continue
            midi = ctx.deg_midi(n.deg, n.acc, n.octv + octv)
            note(midi, n.beat, n.dur * 0.95)
    elif kind == "drone":
        root = ctx.key + 12 * octv
        fifth = root + 7
        span = total_beats
        seg = ctx.beats * 4
        b = 0.0
        while b < span:
            d = min(seg, span - b)
            note(root, b, d, 0.8, -0.2)
            note(fifth, b, d, 0.6, 0.2)
            b += seg
    elif kind == "pad":
        for (beat, dur, name, sec) in chords:
            if not part_active(part, sec):
                continue
            for m in ctx.chord_tones(name, octv, part.get("chord7", False)):
                note(m, beat, dur * 0.98, 0.8)
    elif kind == "strum":
        pat = part["pattern"]
        steps = len(pat)
        step_b = ctx.beats / steps
        nbars = int(total_beats // ctx.beats)
        hits = [i for i, c in enumerate(pat) if c in "xX"]
        for bar in range(nbars):
            for k, i in enumerate(hits):
                beat = bar * ctx.beats + i * step_b
                nxt = hits[k + 1] if k + 1 < len(hits) else steps + hits[0]
                dur = min((nxt - i) * step_b * 0.9, 2.0)
                ch = active_chord(chords, beat)
                if ch is None or not part_active(part, ch[3]):
                    continue
                tones = ctx.chord_tones(ch[2], octv, part.get("chord7", False))
                v = vel() * (1.1 if pat[i] == "X" else 1.0)
                for j, m in enumerate(tones):
                    note(m, beat + j * 0.02 / ctx.spb * (1 if k % 2 == 0 else -1) + (0 if k % 2 == 0 else 0.06 / ctx.spb), dur, v * 0.8)
    elif kind == "bass":
        pat = part["pattern"]
        steps = len(pat)
        step_b = ctx.beats / steps
        nbars = int(total_beats // ctx.beats)
        hits = [i for i, c in enumerate(pat) if c in "R35O7"]
        for bar in range(nbars):
            for k, i in enumerate(hits):
                beat = bar * ctx.beats + i * step_b
                nxt = hits[k + 1] if k + 1 < len(hits) else steps + hits[0]
                dur = min((nxt - i) * step_b * 0.92, 2.0)
                ch = active_chord(chords, beat)
                if ch is None or not part_active(part, ch[3]):
                    continue
                root = ctx.chord_root(ch[2], octv)
                c = pat[i]
                m = root + {"R": 0, "O": 12, "3": ctx.chord_step(ch[2], 2), "5": ctx.chord_step(ch[2], 4),
                            "7": ctx.chord_step(ch[2], 6)}[c]
                note(m, beat, dur)
    elif kind == "arp":
        rate = part.get("rate", 0.5)
        shape = part.get("shape", "up")
        nsteps = int(round(total_beats / rate))
        for k in range(nsteps):
            beat = k * rate
            ch = active_chord(chords, beat)
            if ch is None or not part_active(part, ch[3]):
                continue
            tones = ctx.chord_tones(ch[2], octv)
            tones = tones + [tones[0] + 12]
            if shape == "up":
                seq = tones
            elif shape == "down":
                seq = tones[::-1]
            elif shape == "updown":
                seq = tones + tones[-2:0:-1]
            elif shape == "roll":
                seq = [tones[0], tones[1], tones[3], tones[0], tones[2], tones[3], tones[1], tones[3]]
            elif shape == "waltz":
                beat_in_bar = int(round(beat)) % ctx.beats
                if beat_in_bar == 0:
                    continue
                seq = [None, tones[1], tones[2]]
                m = seq[beat_in_bar % 3]
                note(m, beat, rate * 0.9, 0.8)
                note(tones[3], beat, rate * 0.9, 0.5)
                continue
            else:
                seq = tones
            m = seq[k % len(seq)]
            note(m, beat, rate * 1.6, 0.8)
    elif kind == "drums":
        kit = part["kit"]
        nbars = int(total_beats // ctx.beats)
        every = part.get("crash_every", 1)
        for name, pat in kit.items():
            steps = len(pat)
            # patterns may span 1 or 2 bars
            bars_span = 2 if steps > 16 and ctx.beats == 4 else (2 if steps == 24 and ctx.beats == 6 else 1)
            step_b = ctx.beats * bars_span / steps
            for bar in range(0, nbars, bars_span):
                for i, c in enumerate(pat):
                    if c not in "xXg":
                        continue
                    beat = bar * ctx.beats + i * step_b
                    if name == "crash" and (bar % every != 0):
                        continue
                    ch = active_chord(chords, beat)
                    if ch is None or not part_active(part, ch[3]):
                        continue
                    v = {"x": 1.0, "X": 1.25, "g": 0.45}[c] * rng.uniform(0.85, 1.0)
                    x = S.render_drum(name, round(v, 2))
                    p = {"hat": 0.3, "ohat": 0.3, "shaker": -0.3, "tamb": 0.4, "rim": 0.2, "wood": -0.25}.get(name, 0.0)
                    place(buf, x, ctx.t(beat) + jitter() * 0.5, 1.0, p)
    if part.get("pump"):
        n = buf.shape[1]
        t = np.arange(n) / S.SR
        ph = (t / ctx.spb) % 1.0
        g = 0.25 + 0.75 * np.clip(ph / 0.45, 0, 1) ** 1.5
        buf *= g
    return buf


def active_chord(chords, beat):
    for c in chords:
        if c[0] - 1e-6 <= beat < c[0] + c[1] - 1e-6:
            return c
    return None


def rms_norm(buf, db):
    mono = buf.mean(axis=0)
    win = int(0.05 * S.SR)
    nwin = len(mono) // win
    if nwin == 0:
        return buf
    frames = mono[: nwin * win].reshape(nwin, win)
    r = np.sqrt((frames ** 2).mean(axis=1))
    active = r[r > r.max() * 0.05] if r.max() > 0 else r
    if len(active) == 0 or active.mean() == 0:
        return buf
    level = np.sqrt((active ** 2).mean())
    return buf * (10 ** (db / 20) / level)


def pick_octave(midis, male):
    med = float(np.median(midis))
    lo, hi = (47, 60) if male else (59, 74)
    o = 0
    while med + 12 * o > hi:
        o -= 1
    while med + 12 * o < lo:
        o += 1
    return o


def render_vocals(song, ctx, notes, nsamp, timbre, harmony=False):
    sung = [n for n in notes if n.syl is not None]
    if not sung:
        return None
    male = S.TIMBRES[timbre][0] == "male"
    midis = [ctx.deg_midi(n.deg, n.acc, n.octv) for n in sung]
    o = pick_octave(midis, male)
    track = np.zeros(nsamp)
    for n in sung:
        if harmony and n.section != "chorus":
            continue
        deg = n.deg + (2 if harmony else 0)
        midi = ctx.deg_midi(deg, n.acc, n.octv) + 12 * o
        # vocals stay in tune (the instruments carry the dark versions' wobble)
        dur = n.dur * ctx.spb * 0.96
        x = S.sing_syllable(n.syl[0], midi, dur, timbre)
        i = int(ctx.t(n.beat) * S.SR)
        k = min(len(x), nsamp - i)
        if k > 0:
            track[i:i + k] += x[:k]
    track = S.vibrato(track, 5.3, 22 if not ctx.dark else 40)
    track = S.hp(track, 140)
    track = S.lp(track, 7500)
    return np.tanh(track * 1.5) / 1.5


def render_song(song, dark=False):
    ctx = Ctx(song, dark)
    notes, chords, entries, total_beats, lines = build_timeline(song, ctx)
    length_s = total_beats * ctx.spb
    tail = 3.0
    nsamp = int((length_s + tail) * S.SR)
    d = song.get("dark") or {}
    parts = list(song["parts"])
    if dark:
        parts = [p for p in parts if p["name"] not in d.get("drop", [])] + d.get("add", [])
    mix = np.zeros((2, nsamp))
    for p in parts:
        b = render_part(p, ctx, notes, chords, total_beats, nsamp)
        b = rms_norm(b, p.get("vol", -20))
        mix += b
    # the same two singers in every song: one pair for the cute versions, one for the dark ones
    # (a song can name its own, e.g. the grey whisper that sings on after Mikake breaks)
    timbre, timbre2 = song.get("singers") or (DARK_SINGERS if dark else SINGERS)
    lead = render_vocals(song, ctx, notes, nsamp, timbre)
    if lead is not None:
        mix += rms_norm(S.pan_stereo(lead, 0.0), -13.5)
        harm = render_vocals(song, ctx, notes, nsamp, timbre2, harmony=True) if timbre2 else None
        if harm is not None and np.any(harm):
            mix += rms_norm(S.pan_stereo(harm, -0.3), -21)
    fx = d.get("fx", {}) if dark else song.get("fx", {})
    # master chain
    if fx.get("radio"):
        mix = np.stack([S.bp(ch, 250, 3500) for ch in mix]) * 1.6
    if fx.get("echo"):
        mix = np.stack([S.echo(ch, fx["echo"], 0.45, 0.35) for ch in mix])
    if fx.get("crush"):
        mix = np.stack([S.bitcrush(ch, 8, 2) * 0.5 + ch * 0.5 for ch in mix])
    rev = fx.get("reverb", 0.2)
    mono = mix.mean(axis=0)
    wet = S.reverb(mono, wet=1.0, size=1.2 if dark else 0.9)
    mix = mix + (wet - np.stack([mono, mono]) * 0.0) * rev * 0.35
    if fx.get("lowpass"):
        mix = np.stack([S.lp(ch, fx["lowpass"]) for ch in mix])
    if fx.get("wow"):
        mix = S.wow(mix, fx["wow"], 0.5)
    if fx.get("crackle"):
        c = S.vinyl(nsamp, fx["crackle"])
        mix += np.stack([c, np.roll(c, 37)])
    # loop fold: reverb/note tails wrap into the start
    L = int(length_s * S.SR)
    head = mix[:, :L].copy()
    tailbuf = mix[:, L:]
    head[:, : tailbuf.shape[1]] += tailbuf
    # master glue
    peak = np.max(np.abs(head)) + 1e-9
    head = head / peak * 1.3
    head = np.tanh(head) / np.tanh(1.3) * 0.92
    meta = dict(length=round(length_s, 4), bpm=ctx.bpm, beats=ctx.beats,
                lines=[[round(t, 3), txt] for (t, txt, _) in lines],
                # [time, duration, text, ends a word, line, pitch (scale steps)]
                syllables=[[round(ctx.t(n.beat), 3), round(n.dur * ctx.spb, 3), n.syl[1].strip(), n.word_end, n.line,
                            n.deg + 7 * n.octv] for n in notes if n.syl is not None])
    return head, meta
