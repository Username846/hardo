"""Song definitions. Melodies are written in scale degrees so the 'dark' versions can
re-use them in a minor/creepy mode automatically.

Melody tokens:  [b|#]deg[' or ,]*[:beats]   e.g.  5:0.5  1':2  b7,  r:1 (rest)
Chords: roman numerals per bar, '|' separated; several chords in a bar are split evenly or
        given explicit beats:  "IV:1 V:1 I:2".  Quality comes from the scale.
Lyrics: they live in dialogue.txt (with everything anyone says, so they're easy to change) and
        are put into each song's sections at the bottom of this file. In the text here, '/'
        separates the windows of the lyric bar, a lone '¶' breaks a window into two lines, and
        '-' splits a word into sung syllables.
"""
import game_text

# Part helper ---------------------------------------------------------------


def P(name, inst, kind, **kw):
    d = dict(name=name, inst=inst, kind=kind)
    d.update(kw)
    return d


STD_FORM = [
    ("intro", dict(src="chorus", bars=(0, 4), vocal=False)),
    ("verse", dict(src="verse")),
    ("chorus", dict(src="chorus")),
    ("break", dict(src="chorus", bars=(4, 8), vocal=False)),
]

# Twice as long: a solo, then a second verse ("lyrics2"/"dark2") and the chorus again
# (sung with its "lyrics2"/"dark2" words if it has them).
LONG_FORM = [
    ("intro", dict(src="chorus", bars=(0, 4), vocal=False)),
    ("verse", dict(src="verse")),
    ("chorus", dict(src="chorus")),
    ("break", dict(src="chorus", bars=(0, 8), vocal=False)),
    ("verse", dict(src="verse", lyr=2)),
    ("chorus", dict(src="chorus", lyr=2)),
    ("break", dict(src="chorus", bars=(4, 8), vocal=False)),
]

SONGS = []

# ---------------------------------------------------------------- THEME: the title screen's party waltz
SONGS.append(dict(
    id="theme", title="It's Your Birthday", bpm=168, key=65, beats=3, scale="major",
    sections=dict(
        verse=dict(
            melody="1:2 3:1 | 5:1 5:1 6:0.5 5:0.5 | 4:1.5 3:0.5 2:1 | 3:3 | "
                   "2:2 4:1 | 6:1 6:1 7:0.5 6:0.5 | 5:1.5 4:0.5 3:1 | 2:3 | "
                   "1:2 3:1 | 5:1 5:1 6:0.5 5:0.5 | 1':1.5 7:0.5 6:1 | 5:3 | "
                   "6:2 6:1 | 5:1 5:1 3:0.5 1:0.5 | 2:1.5 3:0.5 2:1 | 1:3",
            chords="I | I | V | I | ii | ii | I | V | I | I | IV | I | IV | I | V | I",
        ),
        chorus=dict(
            melody="1:1 3:1 5:1 | 1':2 6:1 | 5:1 3:1 1:1 | 2:1 5:2 | "
                   "1:1 3:1 5:1 | 1':2 6:1 | 5:1 6:1 5:1 | 3:1 2:2 | "
                   "6:1 6:1 6:1 | 1':2 6:1 | 5:1 5:1 3:1 | 1:1 3:2 | "
                   "4:1 4:1 6:1 | 1':2 7:1 | 5:1 5:1 2:1 | 2:1 1:2",
            chords="I | IV | I | V | I | IV | I | V | IV | IV | I | vi | ii | I | V | V:1 I:2",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("lead", "calliope", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("bells", "glock", "melody", sections=["chorus"], vol=-26, oct=2, pan=0.3),
        P("strings", "strings", "pad", vol=-25),
        P("oom", "tuba", "bass", pattern="R...........", oct=-1, vol=-16),
        P("pah", "pizz", "strum", pattern="....x...x...", oct=0, vol=-21, pan=-0.2),
        P("brass", "brass", "strum", pattern="....x...x...", sections=["chorus", "break"], oct=0, vol=-27, pan=0.2),
        P("harp", "harp", "arp", rate=0.5, shape="updown", sections=["verse"], oct=1, vol=-28, pan=-0.35),
        P("drums", None, "drums", kit=dict(kick="x...........", tamb="....x...x...", timpani="x...........",
                                            crash="x..........."), crash_every=8, vol=-21),
    ],
    # the evil version: a broken-down carousel, still going round
    dark=dict(scale="harm_minor", bpm_mul=0.72, detune=25,
              drop=["drums", "pah", "brass", "harp"],
              add=[P("box", "music_box", "melody", oct=2, vol=-23),
                   P("drone", "choir", "drone", oct=0, vol=-24),
                   P("heart", None, "drums", kit=dict(heart="x..........."), vol=-17)],
              fx=dict(wow=0.012, lowpass=3200, crackle=0.04, reverb=0.55)),
))

# ---------------------------------------------------------------- TITLE: kazoo march
SONGS.append(dict(
    id="title", title="Who's That?", bpm=120, key=65 - 12, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="5:1 5:1 6:1.5 r:0.5 | 5:1 4:1 3:2 | 1:0.5 2:0.5 3:1 4:1 5:1 | 6:0.5 6:0.5 1':3 | "
                   "5:1 5:0.5 5:0.5 6:1 5:1 | 4:0.5 3:0.5 3:1 2:2 | 5,:1 5,:1 6,:1 7,:1 | 3:0.5 2:0.5 1:1 1:2",
            chords="I | I | I | IV | I | V | V | I",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 6:1 5:2 | 4:0.5 4:0.5 6:1 5:2 | 3:0.5 4:0.5 5:1 5:1 6:1 | 5:4 | "
                   "1':0.75 1':0.25 7:1 6:2 | 4:1 5:3 | 2:1 2:1 3:1 4:1 | 2:1 1:3",
            chords="IV | IV I | I | V | I | IV | V | I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("kazoo", "kazoo", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("kazoo2", "kazoo", "melody", sections=["chorus"], vol=-27, oct=1, pan=0.3),
        P("glock", "glock", "melody", sections=["chorus", "break"], vol=-25, oct=2, pan=-0.3),
        P("tuba", "tuba", "bass", pattern="R...5...", oct=-1, vol=-17),
        P("pah", "accordion", "strum", pattern="..x...x.", oct=0, vol=-25, pan=0.25),
        P("drums", None, "drums", kit=dict(snare="x.xxx.x.x.xxx.xx", kick="x.......x.......",
                                            crash="x..............."), crash_every=8, vol=-19),
    ],
    dark=None,
))

# ---------------------------------------------------------------- HUB: party ukulele
SONGS.append(dict(
    id="hub", title="Party Time", bpm=126, key=67, beats=4, scale="major", swing=0.18,
    sections=dict(
        verse=dict(
            melody="1:0.5 2:0.5 3:1 3:0.5 4:0.5 5:1 | 6:1 5:1 r:2 | 3:0.5 3:0.5 4:0.5 3:0.5 2:1 1:1 | 2:2 r:2 | "
                   "1:1 2:1 3:0.5 3:0.5 4:1 | 6:2 5:2 | 5:0.5 5:0.5 6:0.5 5:0.5 4:0.5 3:0.5 2:1 | 1:2 r:2",
            chords="I | IV I | I | V | I | IV | V | I",
        ),
        chorus=dict(
            melody="5:1 5:0.5 6:0.5 5:1 3:1 | 1':1 7:1 r:2 | 1':0.5 1':0.5 7:1 1':0.5 1':0.5 7:1 | 6:1 5:1 r:2 | "
                   "3:0.5 3:0.5 4:0.5 3:0.5 2:1 5:1 | 5:2 r:2 | 1':1 6:1 1':1 6:1 | 5:0.5 2:0.5 1:3",
            chords="I | IV V | IV V | I | vi | V | IV | V I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("whistle", "whistle", "melody", sections=["intro", "break"], vol=-16, oct=1),
        P("uke", "uke", "strum", pattern="x.x.xxx.", oct=0, vol=-20, pan=-0.2),
        P("glock", "glock", "arp", rate=1.0, shape="up", oct=1, vol=-27, pan=0.35),
        P("bass", "upright", "bass", pattern="R...5...", oct=-2, vol=-17),
        P("drums", None, "drums", kit=dict(kick="x.......x.......", clap="....x.......x...",
                                            shaker="x.x.x.x.x.x.x.x.", tamb="......x.......x."), vol=-20),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.8, detune=18,
              drop=["drums", "glock"],
              add=[P("box", "music_box", "melody", oct=1, vol=-22, pan=0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-24),
                   P("heart", None, "drums", kit=dict(heart="x.......x......."), vol=-20)],
              fx=dict(wow=0.004, lowpass=4500, crackle=0.02, reverb=0.4)),
))

# ---------------------------------------------------------------- 1 KNEAD FOR SPEED: big beat
SONGS.append(dict(
    id="race", title="Knead for Speed", bpm=126, key=55, beats=4, scale="dorian",
    sections=dict(
        verse=dict(
            melody="1:0.5 1:0.5 3:1 4:1 3:1 | 1:1.5 7,:0.5 r:2 | 1:0.5 1:0.5 3:1 5:1 4:1 | 3:1.5 1:0.5 r:2 | "
                   "4:0.5 4:0.5 6:1 1':1 6:1 | 5:1.5 4:0.5 r:2 | 5:0.5 5:0.5 4:1 3:1 1:1 | 2:1 1:1 r:2",
            chords="I | VII | I | VII | IV | IV | V | I",
        ),
        chorus=dict(
            melody="5:1 4:0.5 5:1.5 r:1 | 5:1 4:0.5 5:1.5 r:1 | 4:0.5 4:0.5 4:0.5 3:0.5 4:1 5:1 | 3:2 r:2 | "
                   "5:0.5 5:0.5 6:0.5 5:0.5 1':1 5:1 | 6:1 5:1 r:2 | 4:0.5 4:0.5 3:0.5 4:0.5 5:1 3:1 | 1:2 r:2",
            chords="I | VII | IV | IV | I | VII | IV:2 V:2 | I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("riff", "dist_guitar", "melody", sections=["intro", "break"], vol=-15, oct=0),
        P("lead", "pluck", "melody", sections=["chorus"], vol=-26, oct=1, pan=0.3),
        P("acid", "acid", "bass", pattern="R.RO.R.5R.RO.R7.", oct=-2, vol=-17),
        P("stabs", "supersaw", "strum", pattern="x.....x...x.....", oct=0, vol=-23, pan=-0.2,
          sections=["chorus", "break"], pump=True),
        P("gtr", "dist_guitar", "strum", pattern="x..x..x.........", oct=-1, vol=-24, pan=-0.3, sections=["verse"]),
        P("drums", None, "drums", kit=dict(kick="x.........x.x...", snare="....x..x.x..x...",
                                            hat="x.x.x.x.x.x.x.x.", ohat="......x.......x.",
                                            crash="x..............."), crash_every=8, vol=-17),
    ],
    dark=dict(scale="phrygian", bpm_mul=0.78, detune=22,
              drop=["drums", "stabs", "gtr", "lead"],
              add=[P("box", "music_box", "melody", oct=1, vol=-23, pan=-0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-22),
                   P("blinker", None, "drums", kit=dict(wood="x...x...x...x...", heart="x.......x......."), vol=-21)],
              fx=dict(wow=0.006, lowpass=3600, crackle=0.02, reverb=0.5)),
))

# ---------------------------------------------------------------- 2 TONY HONK: ska punk
SONGS.append(dict(
    id="skate", title="One Minute Session", bpm=176, key=62 - 12, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="5:1 5:1 6:1 5:1 | 3:1 1:1 2:2 | 2:1 2:1 3:1 4:1 | 5:1 4:1 3:2 | "
                   "5:1 5:1 6:1 1':1 | 7:1 6:1 5:2 | 4:1 4:1 3:1 2:1 | 3:1 2:1 1:2",
            chords="I | I | V | V | IV | IV | V | I",
        ),
        chorus=dict(
            melody="1':1 1':1 1':1 6:1 | 5:1 6:1 5:2 | 4:1 4:1 6:1 5:1 | 4:1 3:1 2:2 | "
                   "5:1 5:1 5:1 1':1 | 7:1 6:1 5:1 6:1 | 4:1 4:1 6:1 5:1 | 3:1 2:1 1:2",
            chords="IV | I | ii | V | V | IV | ii:2 V:2 | I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("horns", "brass", "melody", sections=["intro", "break"], vol=-14, oct=1),
        P("horns2", "brass", "melody", sections=["chorus"], vol=-25, oct=1, pan=0.3),
        P("skank", "skank", "strum", pattern="..x...x...x...x.", oct=0, vol=-20, pan=-0.3),
        P("power", "dist_guitar", "strum", pattern="x.x.x.x.x.x.x.x.", oct=-1, vol=-24, pan=0.25,
          sections=["chorus", "break"]),
        P("bass", "pick_bass", "bass", pattern="R.R.5.R.R.R.5.O.", oct=-1, vol=-16),
        P("drums", None, "drums", kit=dict(kick="x.......x.x.....", snare="....x.......x...",
                                            hat="x.x.x.x.x.x.x.x.", rim="..x...x...x...x.",
                                            crash="x..............."), crash_every=8, vol=-18),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.55, detune=20,
              drop=["drums", "power", "horns2"],
              add=[P("dub", None, "drums", kit=dict(kick="x.......x.......", rim="....x.......x...",
                                                     heart="........x......."), vol=-19),
                   P("organ", "organ", "strum", pattern="..x...x...x...x.", oct=0, vol=-25, pan=0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-24)],
              fx=dict(wow=0.005, lowpass=3800, crackle=0.02, reverb=0.45, echo=0.465)),
))

# ---------------------------------------------------------------- 3 DIJIMON: anime rock theme song
SONGS.append(dict(
    id="digi", title="Dijivolve!", bpm=150, key=62, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="5:1 5:1 5:1 3:0.5 4:0.5 | 5:0.5 6:0.5 5:2 r:1 | 3:0.5 3:0.5 4:1 3:0.5 2:0.5 1:1 | 2:0.5 3:2.5 r:1 | "
                   "5:0.5 5:0.5 6:0.5 5:0.5 4:1 3:1 | 4:0.5 5:2.5 r:1 | 1':0.5 7:0.5 6:1 5:0.5 4:0.5 3:1 | 2:0.5 1:2.5 r:1",
            chords="I | V | vi | IV | I | V | IV | V",
        ),
        chorus=dict(
            melody="1':0.5 7:0.5 1':1 1':0.5 7:0.5 1':1 | 2':3 r:1 | 6:0.5 6:0.5 5:0.5 6:0.5 1':1 6:1 | 5:0.5 5:2.5 r:1 | "
                   "4:0.5 4:0.5 4:1 5:0.5 6:0.5 5:1 | 3:3 r:1 | 4:0.5 4:0.5 5:0.5 6:0.5 5:1 4:1 | 2:0.5 1:2.5 r:1",
            chords="IV | V | vi | IV | ii | V | IV:2 V:2 | I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("lead", "dist_guitar", "melody", sections=["intro", "break"], vol=-14, oct=0),
        P("power", "dist_guitar", "strum", pattern="x.x.x.x.x.x.x.x.", oct=-1, vol=-23, pan=-0.3),
        P("strings", "strings", "pad", oct=1, vol=-26, pan=0.3, sections=["chorus", "break"]),
        P("beeps", "pulse25", "arp", rate=0.25, shape="up", oct=1, vol=-30, pan=0.4),
        P("bass", "pick_bass", "bass", pattern="R.R.R.R.R.R.O.R.", oct=-2, vol=-16),
        P("drums", None, "drums", kit=dict(kick="x...x...x..x.x..", snare="....x.......x...",
                                            hat="x.x.x.x.x.x.x.x.", crash="x..............."), crash_every=8, vol=-17),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.62, detune=28,
              drop=["drums", "power", "beeps", "lead"],
              add=[P("box", "music_box", "melody", oct=1, vol=-20, pan=-0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-22),
                   P("heart", None, "drums", kit=dict(heart="x.......x......."), vol=-19)],
              fx=dict(wow=0.008, lowpass=3500, crackle=0.03, reverb=0.5)),
))

# ---------------------------------------------------------------- 4 CARDS: bossa nova
SONGS.append(dict(
    id="cards", title="Birthday Mail", bpm=128, key=62 - 12, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="r:0.5 3:1 3:0.5 5:1 4:1 | 3:1.5 2:0.5 1:2 | r:0.5 2:1 2:0.5 4:1 3:1 | 2:1.5 1:0.5 7,:2 | "
                   "r:0.5 3:1 3:0.5 5:1 7:1 | 6:1.5 5:0.5 4:2 | r:0.5 4:1 4:0.5 3:1 2:1 | 3:1.5 2:0.5 1:2",
            chords="I7 | vi7 | ii7 | V7 | I7 | IV7 | ii7 V7 | I7",
        ),
        chorus=dict(
            melody="5:0.5 6:1 5:0.5 6:1 5:0.5 6:0.5 | 1':1 7:3 | r:0.5 6:1 6:0.5 5:1 4:1 | 3:1.5 4:0.5 5:2 | "
                   "r:0.5 3:1 3:0.5 4:1 5:1 | 6:1.5 5:0.5 3:2 | r:0.5 2:1 2:0.5 3:1 4:1 | 2:1.5 7,:0.5 1:2",
            chords="vi7 | I7 | ii7 | I7 | IV7 | vi7 | ii7 | V7 I7",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("vibes", "vibes", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("vibes2", "vibes", "melody", sections=["chorus"], vol=-26, oct=1, pan=0.35),
        P("guitar", "nylon", "strum", pattern="x..x..x...x..x..", oct=0, vol=-21, pan=-0.25, chord7=True),
        P("bass", "upright", "bass", pattern="R..5R..5", oct=-1, vol=-16),
        P("drums", None, "drums", kit=dict(rim="x..x..x...x..x..", brush="x.x.x.x.x.x.x.x.",
                                            kick="x.....x.x.....x."), vol=-22),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.8, detune=20,
              drop=["vibes2"],
              add=[P("drone", "strings", "drone", oct=-1, vol=-24),
                   P("bells", "bell", "arp", rate=4.0, shape="up", oct=1, vol=-28)],
              fx=dict(wow=0.006, lowpass=3200, crackle=0.04, reverb=0.4, radio=True)),
))

# ---------------------------------------------------------------- 5 CALL OF BIRTHDAY: epic orchestral
SONGS.append(dict(
    id="duty", title="Call of Birthday", bpm=104, key=62 - 12, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="1:0.75 1:0.25 3:1 5:2 | 6:1 5:1 3:2 | 4:0.75 4:0.25 6:1 5:2 | 3:1 2:1 5,:2 | "
                   "1:0.75 1:0.25 3:1 5:2 | 1':1 7:1 6:2 | 5:0.75 4:0.25 3:1 2:2 | 3:1 2:1 1:2",
            chords="I | vi:2 I:2 | IV | V | I | IV | ii:2 V:2 | I",
        ),
        chorus=dict(
            melody="5:1 5:0.5 5:0.5 1':2 | 7:1 6:1 5:2 | 4:1 4:0.5 4:0.5 6:2 | 5:1 4:1 3:2 | "
                   "5:1 5:0.5 5:0.5 2':2 | 1':1 7:1 6:2 | 6:1 5:1 4:1 2:1 | 3:1 2:1 1:2",
            chords="I | V:2 I:2 | IV | I | V | IV | ii:2 V:2 | I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("horns", "brass", "melody", sections=["intro", "break"], vol=-14, oct=1),
        P("horns2", "brass", "melody", sections=["chorus"], vol=-25, oct=0, pan=-0.3),
        P("ostinato", "spiccato", "arp", rate=0.25, shape="updown", oct=0, vol=-21, pan=0.3),
        P("low", "spiccato", "bass", pattern="R.RRR.RRR.RRR.RR", oct=-2, vol=-17),
        P("choir", "choir", "pad", oct=0, vol=-25, sections=["chorus", "break"]),
        P("drums", None, "drums", kit=dict(taiko="x.....x.x.......", timpani="x...............",
                                            snare="....x.......x.xx", crash="x..............."), crash_every=8, vol=-17),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.72, detune=25,
              drop=["drums", "ostinato", "horns", "horns2"],
              add=[P("box", "music_box", "melody", oct=1, vol=-20, sections=["intro", "break"]),
                   P("box2", "music_box", "melody", oct=2, vol=-27, sections=["verse", "chorus"]),
                   P("drone", "choir", "drone", oct=0, vol=-23),
                   P("march", None, "drums", kit=dict(heart="x.......x.......", wood="....x.......x..."), vol=-19)],
              fx=dict(wow=0.007, lowpass=3400, crackle=0.03, reverb=0.55)),
))

# ---------------------------------------------------------------- 6 FORTNIGHT: EDM
SONGS.append(dict(
    id="royale", title="Birthday Royale", bpm=128, key=64, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="1:0.5 1:0.5 3:0.5 1:0.5 5:1 4:0.5 3:0.5 | 3:2 r:2 | 2:0.5 2:0.5 2:0.5 3:0.5 4:1 3:1 | 2:2 r:2 | "
                   "1:0.5 1:0.5 3:0.5 5:0.5 6:1 5:1 | 5:2 r:2 | 6:0.5 5:0.5 4:0.5 3:0.5 2:1 1:1 | 2:2 r:2",
            chords="I | I | V | V | vi | I | IV | V",
        ),
        chorus=dict(
            melody="5:1 5:0.5 6:0.5 1':1 6:1 | 5:1 3:1 r:2 | 4:1 4:0.5 5:0.5 6:1 5:1 | 3:1 2:1 r:2 | "
                   "5:1 5:0.5 6:0.5 1':1 2':1 | 1':1 6:1 r:2 | 4:1 4:0.5 5:0.5 6:1 5:1 | 2:1 1:1 r:2",
            chords="IV | I | ii | V | IV | vi | ii | V I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("lead", "pluck", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("saw", "supersaw", "strum", pattern="..x...x...x...x.", oct=0, vol=-20, pump=True),
        P("arp", "pluck", "arp", rate=0.25, shape="up", oct=1, vol=-25, pan=0.3),
        P("bass", "sub_bass", "bass", pattern=".R.R.R.R", oct=-2, vol=-15),
        P("drums", None, "drums", kit=dict(kick="x...x...x...x...", clap="....x.......x...",
                                            hat="..x...x...x...x.", crash="x..............."), crash_every=8, vol=-17),
    ],
    dark=dict(scale="nat_minor", bpm_mul=0.75, detune=20,
              drop=["arp", "drums"],
              add=[P("drone", "strings", "drone", oct=-1, vol=-22),
                   P("slow", None, "drums", kit=dict(kick="x.......x.......", hat="....x.......x..."), vol=-20)],
              fx=dict(wow=0.006, lowpass=3000, crackle=0.02, reverb=0.5)),
))

# ---------------------------------------------------------------- 7 ROBLOCKS: tropical
SONGS.append(dict(
    id="obby", title="Obby Hop", bpm=112, key=57, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="5:1 5:1 5:1 r:0.5 3:0.5 | 4:0.5 3:0.5 1:1 r:2 | 2:1 3:1 4:1 r:0.5 4:0.5 | 3:0.5 2:0.5 5,:1 r:2 | "
                   "5:1 5:1 5:1 r:0.5 6:0.5 | 5:0.5 4:0.5 3:1 r:2 | 2:1 2:1 3:1 r:0.5 2:0.5 | 7,:0.5 6,:0.5 1:1 r:2",
            chords="I | I | V | V | I | IV | V | I",
        ),
        chorus=dict(
            melody="1':1 6:1 1':1 r:0.5 6:0.5 | 5:0.5 5:0.5 5:1 r:2 | 4:1 4:1 6:1 r:0.5 6:0.5 | 5:0.5 3:0.5 1:1 r:2 | "
                   "1':1 6:1 1':1 r:0.5 2':0.5 | 1':0.5 6:0.5 5:1 r:2 | 4:1 4:1 3:1 r:0.5 2:0.5 | 5,:0.5 7,:0.5 1:1 r:2",
            chords="IV | I | IV | I | IV | vi V | ii | V I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("steel", "steel_drum", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("steel2", "steel_drum", "melody", sections=["chorus"], vol=-25, oct=1, pan=-0.3),
        P("marimba", "marimba", "arp", rate=0.5, shape="updown", oct=0, vol=-21, pan=0.3),
        P("bass", "synth_bass", "bass", pattern="R..R.5.R", oct=-1, vol=-17),
        P("drums", None, "drums", kit=dict(kick="x.....x...x.....", clap="....x.......x...",
                                            shaker="x.xxx.xxx.xxx.xx", wood="..x.......x....."), vol=-20),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.8, detune=25,
              drop=["drums", "steel2", "marimba"],
              add=[P("marimba_slow", "marimba", "arp", rate=1.0, shape="up", oct=0, vol=-22),
                   P("drone", "pad", "drone", oct=-1, vol=-22),
                   P("tick", None, "drums", kit=dict(kick="x.......x.......", rim="........x......."), vol=-22)],
              fx=dict(wow=0.007, lowpass=3500, crackle=0.02, reverb=0.5, crush=True)),
))

# ---------------------------------------------------------------- 8 POKEMANS: Game Boy
SONGS.append(dict(
    id="poke", title="Catch a Friend", bpm=150, key=60, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="1:1.5 1:0.5 5:1 5:1 | 6:1 5:1 3:2 | 4:1.5 4:0.5 3:1 3:1 | 2:1 1:1 2:2 | "
                   "1:1.5 1:0.5 5:1 5:1 | 6:1 7:1 1':2 | 6:1.5 6:0.5 5:1 4:1 | 3:1 2:1 5,:2",
            chords="I | IV:1 I:3 | IV | V | I | vi:1 V:1 I:2 | IV | V",
        ),
        chorus=dict(
            melody="1':1.5 1':0.5 7:1 6:1 | 5:1 6:1 5:2 | 4:1.5 4:0.5 5:1 6:1 | 5:1 4:1 3:2 | "
                   "1':1.5 1':0.5 7:1 6:1 | 5:1 6:1 1':2 | 2':1.5 2':0.5 1':1 7:1 | 6:1 7:1 1':2",
            chords="IV | I | ii | V:2 I:2 | IV | I | V | IV:1 V:1 I:2",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("lead", "pulse12", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("lead2", "pulse12", "melody", sections=["verse", "chorus"], vol=-26, oct=1),
        P("arp", "pulse25", "arp", rate=0.25, shape="up", oct=0, vol=-25, pan=0.25),
        P("bass", "gb_wave", "bass", pattern="R.R.5.R.", oct=-1, vol=-16),
        P("drums", None, "drums", kit=dict(nkick="x.......x.x.....", nsnare="....x.......x...",
                                            nhat="x.x.x.x.x.x.x.x."), vol=-20),
    ],
    dark=dict(scale="locrian_ish", bpm_mul=0.62, detune=10,
              drop=["drums", "arp", "lead2"],
              add=[P("arp_slow", "pulse25", "arp", rate=0.5, shape="down", oct=0, vol=-24),
                   P("drone", "gb_wave", "drone", oct=-1, vol=-24)],
              fx=dict(wow=0.004, lowpass=4000, crackle=0.01, reverb=0.55, crush=True)),
))

# ---------------------------------------------------------------- 9 R.E.P.O.: sea shanty
SONGS.append(dict(
    id="repo", title="Haul It Home", bpm=108, key=62, beats=4, scale="dorian",
    sections=dict(
        verse=dict(
            melody="5,:1 1:1 1:1 3:1 | 2:1 1:1 5,:2 | 1:1 3:1 5:1 5:1 | 4:1 3:1 2:2 | "
                   "5:1 5:1 6:1 5:1 | 4:1 3:1 2:2 | 1:1 3:1 2:1 7,:1 | 1:1 5,:1 1:2",
            chords="I | VII | I | V | III | VII | IV | I",
        ),
        chorus=dict(
            melody="5:1 5:1 5:1 3:1 | 4:1 3:1 1:2 | 1:1 1:1 3:1 5:1 | 4:1 3:1 2:2 | "
                   "5:1 5:1 6:1 1':1 | 7:1 6:1 5:2 | 4:1 3:1 2:1 3:1 | 2:1 7,:1 1:2",
            chords="I | IV | I | V | III | VII | IV | V:2 I:2",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("fiddle", "fiddle", "melody", sections=["intro", "break"], vol=-14, oct=1),
        P("whistle", "whistle", "melody", sections=["chorus"], vol=-27, oct=1, pan=0.3),
        P("squeeze", "accordion", "strum", pattern="x...x.x.x...x.x.", oct=0, vol=-21, pan=-0.25),
        P("bass", "upright", "bass", pattern="R...5...", oct=-2, vol=-16),
        P("drums", None, "drums", kit=dict(kick="x...x...x...x...", clap="....x.......x...",
                                            tamb="..x...x...x...x."), vol=-19),
    ],
    dark=dict(scale="phrygian", bpm_mul=0.68, detune=22,
              drop=["drums", "whistle"],
              add=[P("drone", "organ", "drone", oct=-1, vol=-23),
                   P("creak", None, "drums", kit=dict(wood="x.......x.......", heart="....x.......x..."), vol=-21)],
              fx=dict(wow=0.007, lowpass=3400, crackle=0.03, reverb=0.5)),
))

# ---------------------------------------------------------------- 10 MIKAKE KARAOKE: Vocaloid J-pop
SONGS.append(dict(
    id="karaoke", title="Birthday Diva", bpm=140, key=64, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="3:0.5 3:0.5 5:0.5 3:0.5 2:1 1:1 | 2:1 3:2 r:1 | 3:0.5 3:0.5 5:0.5 6:0.5 5:1 3:1 | 5:1 6:2 r:1 | "
                   "6:0.5 6:0.5 5:0.5 6:0.5 1':1 6:1 | 5:1 3:2 r:1 | 4:0.5 4:0.5 3:0.5 4:0.5 5:1 2:1 | 3:1 1:2 r:1",
            chords="I | V | vi | IV | IV | V | ii | V",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 7:0.5 1':0.5 2':1 1':1 | 6:1 5:2 r:1 | 4:0.5 4:0.5 4:0.5 5:0.5 6:1 5:1 | 3:1 2:2 r:1 | "
                   "1':0.5 1':0.5 7:0.5 1':0.5 2':1 1':1 | 6:1 1':2 r:1 | 4:0.5 4:0.5 3:0.5 2:0.5 3:1 2:1 | 2:1 1:2 r:1",
            chords="IV | V | iii | vi | IV | V | ii:2 V:2 | I",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("lead", "square", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("bells", "bell", "melody", sections=["chorus"], vol=-27, oct=2, pan=0.3),
        P("saw", "supersaw", "strum", pattern="x..x..x.x..x..x.", oct=0, vol=-21, pump=True),
        P("arp", "pluck", "arp", rate=0.25, shape="updown", oct=1, vol=-25, pan=-0.3),
        P("bass", "sub_bass", "bass", pattern="R.R.O.R.R.R.O.R.", oct=-2, vol=-15),
        P("drums", None, "drums", kit=dict(kick="x...x...x...x...", clap="....x.......x...",
                                            hat="xxxxxxxxxxxxxxxx", crash="x..............."), crash_every=8, vol=-17),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.7, detune=20,
              drop=["drums", "saw", "arp"],
              add=[P("box", "music_box", "melody", oct=2, vol=-23),
                   P("drone", "choir", "drone", oct=0, vol=-23),
                   P("heart", None, "drums", kit=dict(heart="x.......x......."), vol=-17)],
              fx=dict(wow=0.007, lowpass=3500, crackle=0.03, reverb=0.55)),
))

# ---------------------------------------------------------------- KARAOKE: after Mikake breaks down
# The birthday song goes on without her: one slow verse in the grey whisper, then nothing.
SONGS.append(dict(
    id="karaoke_grey", title="Without Her", bpm=64, key=64, beats=4, scale="nat_minor",
    singers=("lady_whisper", None),
    sections=dict(
        verse=dict(
            melody="3:0.5 3:0.5 5:0.5 3:0.5 2:1 1:1 | 2:1 3:2 r:1 | 3:0.5 3:0.5 5:0.5 6:0.5 5:1 3:1 | 5:1 6:2 r:1 | "
                   "6:0.5 6:0.5 5:0.5 6:0.5 1':1 6:1 | 5:1 3:2 r:1 | 4:0.5 4:0.5 3:0.5 4:0.5 5:1 2:1 | 3:1 1:2 r:1",
            chords="I | V | vi | IV | IV | V | ii | V",
        ),
    ),
    form=[
        ("intro", dict(src="verse", bars=(6, 8), vocal=False)),
        ("verse", dict(src="verse")),
        ("outro", dict(src="verse", bars=(6, 8), vocal=False)),
    ],
    parts=[
        P("box", "music_box", "melody", sections=["intro", "outro"], vol=-20, oct=2),
        P("drone", "choir", "drone", oct=0, vol=-25),
        P("pad", "strings", "pad", vol=-27),
        P("heart", None, "drums", kit=dict(heart="x.......x......."), vol=-19),
    ],
    fx=dict(wow=0.009, lowpass=2600, crackle=0.05, reverb=0.65),
    dark=None,
))

# ---------------------------------------------------------------- SECRET: the road away from the party
# Only if Chumbo chooses to leave. Slow, alone, in the dark whisper, and every road bends back.
SONGS.append(dict(
    id="rocko_leave", title="Every Road Leads Back", bpm=66, key=57, beats=4, scale="nat_minor",
    singers=("whisper", None),
    sections=dict(
        verse=dict(
            melody="5:1 5:1 4:1 3:1 | 2:1 3:1 1:2 | 1:1 2:1 3:1 4:1 | 3:1 2:1 2:2 | "
                   "5:1 5:1 6:1 5:1 | 4:1 3:1 2:2 | 3:1 2:1 1:1 7,:1 | 2:1 7,:1 1:2",
            chords="I | V | IV | V | I | IV | V | I",
        ),
        chorus=dict(
            melody="1':1 1':1 7:1 6:1 | 5:1 6:1 5:2 | 4:1 4:1 5:1 6:1 | 5:1 4:1 3:2 | "
                   "1':1 1':1 7:1 6:1 | 5:1 6:1 5:2 | 4:1 3:1 2:1 1:1 | 2:1 7,:1 1:2",
            chords="IV | I | IV | V | IV | I | V | I",
        ),
    ),
    form=[
        ("intro", dict(src="verse", bars=(6, 8), vocal=False)),
        ("verse", dict(src="verse")),
        ("chorus", dict(src="chorus")),
        ("outro", dict(src="chorus", bars=(6, 8), vocal=False)),
    ],
    parts=[
        P("box", "music_box", "melody", sections=["intro", "outro"], vol=-21, oct=1),
        P("harp", "harp", "arp", rate=1.0, shape="up", oct=0, vol=-24, pan=-0.2),
        P("pad", "strings", "pad", vol=-26),
        P("drone", "choir", "drone", oct=0, vol=-26),
        P("heart", None, "drums", kit=dict(heart="x...............x..............."), vol=-20),
    ],
    fx=dict(wow=0.008, lowpass=2400, crackle=0.04, reverb=0.7),
    dark=None,
))

# ---------------------------------------------------------------- SECRET: Rocko (cozy couch -> chase)
SONGS.append(dict(
    id="rocko", title="Oh Hi Rocko", bpm=96, key=62, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="3 3 4 5 | 5 4 3:2 | 2 2 3 4 | 4 3 2:2 | 3 3 4 5 | 1' 7 6:2 | 5 4 3 2 | 3 2 1:2",
            chords="I | I | V | V | I | IV | V | I",
        ),
        chorus=dict(
            melody="5 3 5 3 | 6 5 4 3 | 2 3 4 2 | 3 2 1:2 | 5 3 5 3 | 1' 7 6 5 | 4 4 3 2 | 2 3 1:2",
            chords="I | IV | ii | V:2 I:2 | I | IV | ii | V:2 I:2",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("lead", "kalimba", "melody", sections=["intro", "break"], vol=-14, oct=1),
        P("bells", "celesta", "melody", sections=["chorus"], vol=-25, oct=2, pan=0.3),
        P("guitar", "nylon", "strum", pattern="x..x..x.x..x..x.", oct=0, vol=-20, pan=-0.25),
        P("bass", "upright", "bass", pattern="R...5...", oct=-2, vol=-17),
        P("drums", None, "drums", kit=dict(kick="x.......x.......", brush="x.x.x.x.x.x.x.x.",
                                            rim="....x.......x..."), vol=-21),
    ],
    dark=dict(scale="phrygian", bpm_mul=1.4, detune=20,
              drop=["lead", "bells", "guitar", "drums"],
              add=[P("ther", "theremin", "melody", sections=["intro", "break"], vol=-15, oct=1),
                   P("clav", "clav", "strum", pattern="x.x.x.x.x.x.x.x.", oct=0, vol=-22, pan=-0.3),
                   P("organ", "organ", "pad", oct=0, vol=-26, pan=0.3),
                   P("drums", None, "drums", kit=dict(kick="x...x...x...x...", timpani="x.......x.......",
                                                       hat="xxxxxxxxxxxxxxxx", heart="..x.......x....."), vol=-18)],
              fx=dict(wow=0.003, lowpass=5200, reverb=0.35)),
))

# Phonetic spellings for syllable fragments espeak would otherwise misread.


def _load_words():
    _, words = game_text.read()
    for s in SONGS:
        for part, fields in words.get(s["id"], {}).items():
            if part not in s["sections"]:
                raise ValueError(f"dialogue.txt: the song {s['id']} has no part called '{part}'")
            s["sections"][part].update(fields)
    for s in SONGS:
        for part, sec in s["sections"].items():
            if "lyrics" not in sec:
                raise ValueError(f"dialogue.txt: no words for 'song {s['id']} - {part}'")


_load_words()

PHONETIC = {
    "chum": "chum", "bo": "boh", "bo!": "boh", "py": "pee", "dy": "dee", "ry": "ree", "ty": "tee",
    "ny": "nee", "by": "bee", "ky": "kee", "ly": "lee", "ery": "ree", "ev": "ev", "tle": "tull",
    "ble": "bull", "dles": "dulls", "gle": "gull", "bble": "bull", "gling": "gling", "na": "nuh",
    "gon": "gun", "ale": "al", "roy": "roy", "loons": "loons", "bal": "buh", "pre": "prez",
    "sents": "ents", "ting": "ting", "es": "ezz", "ing": "ing", "er": "ur", "der": "dur",
    "ter": "tur", "ver": "vur", "ger": "gur", "et": "it", "ster": "stur", "sters": "sturz",
    "man": "man", "cham": "cham", "pi": "pee", "on": "on", "a": "uh", "o": "oh", "ap": "uh",
    "proved": "prooved", "de": "dee", "nied": "nide", "ted": "ted", "duck": "duck", "ma": "muh",
    "chines": "sheens", "rai": "ray", "sins": "zins", "fros": "fros", "lay": "lay", "dies": "deez",
    "bloc": "block", "bud": "bud", "est": "est", "re": "ree", "spawn": "spawn", "coo": "coo",
    "lest": "lest", "show": "show", "vic": "vick", "to": "tuh", "danc": "dance", "sin": "sing",
    "yel": "yell", "ling": "ling", "mon": "mon", "pock": "pock", "rus": "russ", "tling": "ling",
    "par": "par", "chu": "choo", "cake": "cake", "wig": "wig", "wob": "wob", "blob": "blob",
    "ti": "tie", "ba": "bay", "hid": "hid", "gig": "gig", "tip": "tip", "toe": "toe", "un": "un",
    "ta": "tay", "read": "red", "peek": "peek", "boo": "boo", "sur": "sir", "prise": "prize",
    "can": "can", "burn": "burn", "pened": "pend", "gun": "gun", "be": "bee", "hap": "hap",
    "birth": "birth", "day": "day", "pup": "pup", "lit": "lit", "count": "count", "march": "march",
    "wool": "wool", "does": "duz", "n't": "nt", "stand": "stand", "grow": "grow", "big": "big",
    "nev": "nev", "sag": "sag", "ging": "ging", "get": "get", "clos": "close", "play": "play",
    "some": "sum", "thing's": "things", "one's": "wuns", "typ": "tipe", "void": "void", "noyed": "noyd",
    "an": "an", "in": "in", "wait": "wait", "smil": "smile", "blink": "blink", "whis": "wiss",
    "pers": "purz", "be-": "bee", "hind": "hind", "al": "all", "ways": "ways", "wel": "well",
    "come": "cum", "with": "with", "out": "out", "grab": "grab", "bing": "bing", "fly": "fly",
    "crawl": "crawl", "hel": "hel", "lo": "low", "hand": "hand", "prints": "prints", "grand": "grand",
    "card": "card", "ma's": "muz", "stair": "stair", "wants": "wants", "ate": "ate", "plate": "plate",
    "clock": "clock", "late": "late", "eyes": "eyes", "feet": "feet", "sweet": "sweet", "go": "go",
    "home": "home", "bun": "bun", "pre-": "pree", "ad": "ad", "box": "box", "side": "side",
    "no": "no", "bod": "bod", "ray": "ray", "hoo": "hoo",
    "est": "ist", "n't": "ent", "y": "ee", "ging": "ghing", "tles": "tulls", "dy's": "deez",
    "ty's": "teez", "fros": "fross", "ve": "vair", "bby": "bee",
}
PHONETIC["der"] = "durr"
PHONETIC["ma's"] = "mahz"

# whole words espeak reads oddly when sung
WORDS = {"a": "uh"}
