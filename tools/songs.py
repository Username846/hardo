"""Song definitions. Melodies are written in scale degrees so the 'dark' versions can
re-use them in a minor/creepy mode automatically.

Melody tokens:  [b|#]deg[' or ,]*[:beats]   e.g.  5:0.5  1':2  b7,  r:1 (rest)
Chords: roman numerals per bar, '|' separated; several chords in a bar are split evenly or
        given explicit beats:  "IV:1 V:1 I:2".  Quality comes from the scale.
Lyrics: '/' separates lines, '-' splits a word into sung syllables.
"""

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

# ---------------------------------------------------------------- TITLE: kazoo march
SONGS.append(dict(
    id="title", title="Who's That?", bpm=120, key=65 - 12, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="5:1 5:1 6:1.5 r:0.5 | 5:1 4:1 3:2 | 1:0.5 2:0.5 3:1 4:1 5:1 | 6:0.5 6:0.5 1':3 | "
                   "5:1 5:0.5 5:0.5 6:1 5:1 | 4:0.5 3:0.5 3:1 2:2 | 5,:1 5,:1 6,:1 7,:1 | 3:0.5 2:0.5 1:1 1:2",
            chords="I | I | I | IV | I | V | V | I",
            lyrics="What's your name? / Type it in! / There's on-ly one name that will win! / "
                   "Not Bob, not Sue, not Steve, no thank you! / Who could it be? / It's on-ly you!",
            lyrics2="Tap the keys, / one by one, / type the name of the birth-day kid! / "
                    "Type it wrong, a box-ing glove says hi! / Try it a-gain, / no need to cry!",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 6:1 5:2 | 4:0.5 4:0.5 6:1 5:2 | 3:0.5 4:0.5 5:1 5:1 6:1 | 5:4 | "
                   "1':0.75 1':0.25 7:1 6:2 | 4:1 5:3 | 2:1 2:1 3:1 4:1 | 2:1 1:3",
            chords="IV | IV I | I | V | I | IV | V | I",
            lyrics="Is it Chum-bo? / Yes, it's Chum-bo! / No-bo-dy else could be! / "
                   "Hap-py birth-day, Chum-bo! / Now type it in for me!",
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
            lyrics="Bal-loons and cake and pre-sents too, / ev-ery-bo-dy came for you! / "
                   "Ten big box-es tied with bows, / what's in-side them? No-bo-dy knows!",
            lyrics2="Tap a pre-sent, o-pen the lid, / games are hid-ing, yes they did! / "
                    "One by one and two by two, / ten big sur-pris-es just for you!",
            dark="The can-dles nev-er burn a-way, / ev-ery day is the same day. / "
                 "Stale bal-loons that nev-er fall. / No-bo-dy leaves this par-ty hall.",
            dark2="One more pre-sent, and one more bow, / ten be-come e-lev-en now. / "
                  "Ev-ery clock is stuck at three. / Hap-py birth-day, e-ter-nal-ly.",
        ),
        chorus=dict(
            melody="5:1 5:0.5 6:0.5 5:1 3:1 | 1':1 7:1 r:2 | 1':0.5 1':0.5 7:1 1':0.5 1':0.5 7:1 | 6:1 5:1 r:2 | "
                   "3:0.5 3:0.5 4:0.5 3:0.5 2:1 5:1 | 5:2 r:2 | 1':1 6:1 1':1 6:1 | 5:0.5 2:0.5 1:3",
            chords="I | IV V | IV V | I | vi | V | IV | V I",
            lyrics="It's your birth-day, it's your day! / Hip hip hoo-ray, hip hip hoo-ray! / "
                   "Ev-ery-bo-dy's glad you came, / Chum-bo, Chum-bo, that's your name!",
            dark="It's your birth-day. It's to-day. / Yes-ter-day was al-so to-day. / "
                 "Ev-ery year will be the same. / Chum-bo, Chum-bo, just a name.",
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
            lyrics="Ne{nee}-on un-der-glow is green, / fast-est car you've ev-er seen! / "
                   "Ni{nye}-tro bot-tles, hit the boost, / leave the ri-vals in the dust!",
            lyrics2="Drag race, watch the nee-dle{dull} climb, / shift in the green, right on time! / "
                    "Per-fect shift and per-fect start, / birth-day speed is in my heart!",
            dark="Lap four of three? It can't be. / Fin-ish line just runs from me. / "
                 "Ev-ery sign says Par-ty Lane, / ev-ery lap the same a-gain.",
            dark2="B{bee}-Day Boss with can-dle eyes / al-ways wins, I don't know why. / "
                  "Gas runs out, the wheels still turn, / can-dles on the dash-board burn.",
        ),
        chorus=dict(
            melody="5:1 4:0.5 5:1.5 r:1 | 5:1 4:0.5 5:1.5 r:1 | 4:0.5 4:0.5 4:0.5 3:0.5 4:1 5:1 | 3:2 r:2 | "
                   "5:0.5 5:0.5 6:0.5 5:0.5 1':1 5:1 | 6:1 5:1 r:2 | 4:0.5 4:0.5 3:0.5 4:0.5 5:1 3:1 | 1:2 r:2",
            chords="I | VII | IV | IV | I | VII | IV:2 V:2 | I",
            lyrics="Knead for speed, knead for speed, / un-der-ground on Birth-day Street! / "
                   "Ze{zee}-ro to six-ty, near miss, flash! / Chum-bo wins the mid-night dash!",
            dark="No es{ess}-cape, no es{ess}-cape, / ev-ery road's the same old shape. / "
                 "Ze{zee}-ro to six-ty, nev-er there, / go-ing no-where, ev-ery-where.",
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
            lyrics="One whole min-ute on the clock, / kick-flip, heel-flip, ol-lie{lee}, rock! / "
                   "Grind the can-dle, jump the cake, / Ton-y Honk says: sick! Great skate!",
            lyrics2="Spell the let-ters, S{ess}, K{kay}, A{ay}, / T{tee} and E{ee} are on the way! / "
                    "Find the se{see}-cret tape up high, / spin nine hun-dred through the sky!",
            dark="One whole min-ute, nev-er done. / Ses-sion's{shunz} o-ver, just be-gun. / "
                 "Same old ramp and same old rail, / ev-ery land-ing bound to fail.",
            dark2="Guests in hats line up to see. / No one claps and no one's free. / "
                  "Let-ters say: S{ess}, T{tee}, A{ay}, Y{why}. / Ton-y Honk won't say good-bye.",
        ),
        chorus=dict(
            melody="1':1 1':1 1':1 6:1 | 5:1 6:1 5:2 | 4:1 4:1 6:1 5:1 | 4:1 3:1 2:2 | "
                   "5:1 5:1 5:1 1':1 | 7:1 6:1 5:1 6:1 | 4:1 4:1 6:1 5:1 | 3:1 2:1 1:2",
            chords="IV | I | ii | V | V | IV | ii:2 V:2 | I",
            lyrics="Skate! Skate! Skate a-round the park, / kick-flip, grind, and make your mark! / "
                   "Spell it out: S{ess}, K{kay}, A{ay}, T{tee}, E{ee}! / Hon-ky, hon-ky, yes sir-ee!",
            dark="Skate, skate, skate a-round the park, / round and round in-to the dark. / "
                 "Spell it out, it's S{ess}, T{tee}, A{ay}, Y{why}. / No more ses-sions{shunz}, no good-bye.",
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
            lyrics="Beep, beep, beep, the Di{dij}-ji{ih}-vice sings, / tap the egg and see what it brings! / "
                   "Feed it, train it, clean up the poop, / Blob-mon jumps a-round in a loop!",
            lyrics2="Blob-mon, Frost-mon, Par-ty-mon too, / ev-ery lev-el is some-thing new! / "
                    "Tap the train-ing bar in the green, / best cham-pi-on you've ev-er seen!",
            dark="Beep, beep, beep, the glass is all cracked. / It ate the clock, no go-ing back. / "
                 "Feed it more, but it wants it all, / now Chum-bo-mon is ten feet tall.",
            dark2="Hatch a-gain on ev-ery birth-day, / same old egg in the same old way. / "
                  "It ate your name, it took your place, / and you're the one stuck in the case.",
        ),
        chorus=dict(
            melody="1':0.5 7:0.5 1':1 1':0.5 7:0.5 1':1 | 2':3 r:1 | 6:0.5 6:0.5 5:0.5 6:0.5 1':1 6:1 | 5:0.5 5:2.5 r:1 | "
                   "4:0.5 4:0.5 4:1 5:0.5 6:0.5 5:1 | 3:3 r:1 | 4:0.5 4:0.5 5:0.5 6:0.5 5:1 4:1 | 2:0.5 1:2.5 r:1",
            chords="IV | V | vi | IV | ii | V | IV:2 V:2 | I",
            lyrics="Di{dij}-ji{ih}-volve! Di{dij}-ji{ih}-volve! Go! / My lit-tle part-ner, watch it grow! / "
                   "Di{dij}-ji{ih}-mon, di{dij}-gi{ih}-tal friend, / hap-py birth-day, friends to the end!",
            dark="Di{dij}-ji{ih}-volve! Di{dij}-ji{ih}-volve! No! / It's still hun-gry, it won't let go. / "
                 "Di{dij}-ji{ih}-mon, so who are you? / And now it says it's Chum-bo too.",
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
            lyrics="Birth-day cards are fly-ing in, / stamp them, check them, let's be-gin! / "
                   "Check the name and check the date, / signed and sealed, or it must wait!",
            lyrics2="Grand-ma's card is pink and true, / Pip sent one with stick-ers too! / "
                    "YAY for good and NOPE for not, / stamp, stamp, stamp, the whole big lot!",
            dark="Let-ters come from far a-way. / Names are fad{fay}-ing{ding} ev-ery day. / "
                 "Pip's card came a year too late. / Rules are rules. It has to wait.",
            dark2="Ev-ery year a lit-tle less, / for-got-ten name and ad-dress. / "
                  "Stamp it, stamp it, let it go. / Who were they? You'll nev-er know.",
        ),
        chorus=dict(
            melody="5:0.5 6:1 5:0.5 6:1 5:0.5 6:0.5 | 1':1 7:3 | r:0.5 6:1 6:0.5 5:1 4:1 | 3:1.5 4:0.5 5:2 | "
                   "r:0.5 3:1 3:0.5 4:1 5:1 | 6:1.5 5:0.5 3:2 | r:0.5 2:1 2:0.5 3:1 4:1 | 2:1.5 7,:0.5 1:2",
            chords="vi7 | I7 | ii7 | I7 | IV7 | vi7 | ii7 | V7 I7",
            lyrics="Ap-proved, ap-proved, ap-proved for you! / Pip's card says I love you too! / "
                   "Love and hugs and lots of mail, / hap-py birth-day, with-out fail!",
            dark="Ap-proved, ap-proved, ap-proved, but who? / Fad{fay}-ed{ded} names I nev-er knew. / "
                 "Emp-ty en-ve{veh}-lopes of mail. / Hap-py birth-day, with-out fail.",
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
            lyrics="Load your darts and grab your hat, / mis-sion{shun}: par-ty, that is that! / "
                   "Pop the card-board crash-ers down, / don't hit Grand-ma, she's in town!",
            lyrics2="Three in a row, spy bal-loon, / five, a care pack-age{ij} lands soon! / "
                    "Sev-en streak, the cake strike falls, / Ser{sar}-geant{jent} Sprin-kles{kulls} gives the calls!",
            dark="Round one, round two, round a-gain. / Guests come back, they nev-er end. / "
                 "Hats are crook-ed, fac{fay}-es{sez} gray, / sing-ing stay, just one more day.",
            dark2="Out of darts and out of time, / ev-ery round's the same old rhyme. / "
                  "Count the rounds, they nev-er stop. / No ex-trac-tion{shun}, no air-drop.",
        ),
        chorus=dict(
            melody="5:1 5:0.5 5:0.5 1':2 | 7:1 6:1 5:2 | 4:1 4:0.5 4:0.5 6:2 | 5:1 4:1 3:2 | "
                   "5:1 5:0.5 5:0.5 2':2 | 1':1 7:1 6:2 | 6:1 5:1 4:1 2:1 | 3:1 2:1 1:2",
            chords="I | V:2 I:2 | IV | I | V | IV | ii:2 V:2 | I",
            lyrics="Call of Birth-day! Hear the call! / Foam darts fly-ing, one and all! / "
                   "Cap-ture cake and hold the line, / mis-sion{shun}: par-ty, right on time!",
            dark="Call of Birth-day, hear them call, / rounds that nev-er end at all. / "
                 "Round for-ev-er, here they come. / There's no-where for you to run.",
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
            lyrics="Jump off the bus, it's par-ty time! / Build it up and watch me climb! / "
                   "Throw the cake and build the wall, / last one stand-ing takes it all!",
            lyrics2="Land at Cake Cas-tle, find the loot! / Smash the lla-ma, dance and scoot! / "
                    "Storm is com-ing, run in-side, / par-ty bus, the best-est ride!",
            dark="The storm keeps clos-ing, nev-er through. / Ev-ery cir-cle{kull} shrinks on you. / "
                 "Nine-ty-nine have gone a-way. / You're the one who has to stay.",
            dark2="One play-er left, and that is you, / but the lob-by fills a-new. / "
                  "Bus comes back to take you down, / same old match, same emp-ty town.",
        ),
        chorus=dict(
            melody="5:1 5:0.5 6:0.5 1':1 6:1 | 5:1 3:1 r:2 | 4:1 4:0.5 5:0.5 6:1 5:1 | 3:1 2:1 r:2 | "
                   "5:1 5:0.5 6:0.5 1':1 2':1 | 1':1 6:1 r:2 | 4:1 4:0.5 5:0.5 6:1 5:1 | 2:1 1:1 r:2",
            chords="IV | I | ii | V | IV | vi | ii | V I",
            lyrics="Birth-day Roy-ale, num-ber one! / Build a wall and have some fun! / "
                   "Nine-ty-nine have left the game, / vic-to-ry has Chum-bo's name!",
            dark="Birth-day Roy-ale, nev-er won. / Ev-ery round has just be-gun. / "
                 "No one's left to call your name. / Ev-ery match is just the same.",
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
            lyrics="Jump jump jump a-cross the bricks, / show-ing off my coo-lest tricks! / "
                   "Oof oof oof, I fell a-gain, / re-spawn with my best-est friends!",
            lyrics2="La-va blocks are hot hot hot, / check-point flag, I like this spot! / "
                    "Springs go bounce, up, up, a-round, / jump the gap and touch the ground!",
            dark="Jump jump jump, the floor is gone. / Check-points move and lead you on. / "
                 "Oof oof oof, re-spawn, re-start. / Same old lev-el, same old part.",
            dark2="Ev-ery-one has gone to bed. / Serv-er emp-ty, chat un-read. / "
                  "Some-one's typ-ing: stay, stay, stay. / No one press-es Leave to-day.",
        ),
        chorus=dict(
            melody="1':1 6:1 1':1 r:0.5 6:0.5 | 5:0.5 5:0.5 5:1 r:2 | 4:1 4:1 6:1 r:0.5 6:0.5 | 5:0.5 3:0.5 1:1 r:2 | "
                   "1':1 6:1 1':1 r:0.5 2':0.5 | 1':0.5 6:0.5 5:1 r:2 | 4:1 4:1 3:1 r:0.5 2:0.5 | 5,:0.5 7,:0.5 1:1 r:2",
            chords="IV | I | IV | I | IV | vi V | ii | V I",
            lyrics="O-bby, o-bby, hop hop hop, / climb up to the ve-ry top! / "
                   "Birth-day badge is wait-ing there, / bloc-ky bud-dies ev-ery-where!",
            dark="O-bby, o-bby, stop stop stop. / There is no one at the top. / "
                 "Birth-day badge you'll nev-er get. / Climb for-ev-er. Not done yet.",
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
            lyrics="Throw the ball and catch a friend, / birth-day bat-tles nev-er end! / "
                   "Par-ty-chu and Cake-man-der, / ev-ery mon-ster loves you too!",
            lyrics2="Walk-ing through the tall green grass, / wild Pres-ent-oad, catch it fast! / "
                    "Six balls sit-ting on the shelf, / Par-ty-chu can't catch it-self!",
            dark="Grass grows tall-er ev-ery night. / Route One nev-er ends in sight. / "
                 "Walk-ing, walk-ing, round and round, / same old par-ty, same old town.",
            dark2="In the ball it's dark and small. / You can't hear the train-ers call. / "
                  "Ev-ery birth-day, caught a-gain, / stored for-ev-er in box ten.",
        ),
        chorus=dict(
            melody="1':1.5 1':0.5 7:1 6:1 | 5:1 6:1 5:2 | 4:1.5 4:0.5 5:1 6:1 | 5:1 4:1 3:2 | "
                   "1':1.5 1':0.5 7:1 6:1 | 5:1 6:1 1':2 | 2':1.5 2':0.5 1':1 7:1 | 6:1 7:1 1':2",
            chords="IV | I | ii | V:2 I:2 | IV | I | V | IV:1 V:1 I:2",
            lyrics="Gon-na catch them, ev-ery one! / Pock-et mon-sters, so much fun! / "
                   "Tall grass rus-tling, here they come! / Chum-bo is the cham-pi-on!",
            dark="Gon-na catch them, ev-ery one. / Ev-ery bat-tle, nev-er won. / "
                 "Tall grass whis-pers, here they come. / Chum-bo's in the ball. All done.",
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
            lyrics="Lit-tle ro-bots, hats on tight, / flash-lights on, it's dark to-night! / "
                   "Grab the cake with the blue beam, / care-ful, care-ful, steer it clean!",
            lyrics2="Gold-en pres-ent, crys-tal hat, / Grand-ma's vase, now look at that! / "
                    "Don't you ev-er poke the duck, / or he'll chase you! What bad luck!",
            dark="Lit-tle ro-bot, haul your past, / birth-day cakes that did-n't last. / "
                 "Ev-ery pre-sent has a price. / Tax-man takes it, once, then twice.",
            dark2="Quo-ta climbs and climbs a-gain, / nev-er e-nough, now or then. / "
                  "Last of all, the beam grabs you, / hauls the birth-day boy back through.",
        ),
        chorus=dict(
            melody="5:1 5:1 5:1 3:1 | 4:1 3:1 1:2 | 1:1 1:1 3:1 5:1 | 4:1 3:1 2:2 | "
                   "5:1 5:1 6:1 1':1 | 7:1 6:1 5:2 | 4:1 3:1 2:1 3:1 | 2:1 7,:1 1:2",
            chords="I | IV | I | V | III | VII | IV | V:2 I:2",
            lyrics="Haul a-way, oh, haul a-way, / Tax-man wants his cash to-day! / "
                   "Fill the quo-ta, ring the bell, / R{ar}, E{ee}, P{pee}, O{oh}, all is well!",
            dark="Haul a-way, oh, haul a-way, / Tax-man says you have to pay. / "
                 "Quo-ta grows and grows and grows. / Par-ty truck, and in he goes.",
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
            lyrics="Mi{mee}-ka{kah}-ke{keh} on the stage to-night, / teal twin-tails swing-ing in the light! / "
                   "Wave the glow sticks, tap to the beat, / spin the lit-tle leek, move your feet!",
            lyrics2="Cir-cle{kull}, cross, and square, tri-an-gle{gull}, / tap them all and make them jin-gle{gull}! / "
                    "Cool, cool, fine, and the com-bo grows, / sing a-long, cause the whole crowd knows!",
            dark="Mi{mee}-ka{kah}-ke{keh} on the stage a-gain, / the same old song that nev-er ends. / "
                 "Red glow sticks in a si-lent crowd, / no one claps, no one says it loud.",
            dark2="Er-ror, er-ror, song on re-peat, / ev-ery birth-day, the same old beat. / "
                  "Make a wish, but it won't come true. / Mi{mee}-ka{kah}-ke{keh} sings it just for you.",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 7:0.5 1':0.5 2':1 1':1 | 6:1 5:2 r:1 | 4:0.5 4:0.5 4:0.5 5:0.5 6:1 5:1 | 3:1 2:2 r:1 | "
                   "1':0.5 1':0.5 7:0.5 1':0.5 2':1 1':1 | 6:1 1':2 r:1 | 4:0.5 4:0.5 3:0.5 2:0.5 3:1 2:1 | 2:1 1:2 r:1",
            chords="IV | V | iii | vi | IV | V | ii:2 V:2 | I",
            lyrics="Mi{mee}-ka{kah}-ke{keh}, Mi{mee}-ka{kah}-ke{keh}, sing it! / Hap-py birth-day, Chum-bo, ring it! / "
                   "Blow the can-dles, make a big wish, / the best-est birth-day song is this!",
            dark="Mi{mee}-ka{kah}-ke{keh}, Mi{mee}-ka{kah}-ke{keh}, stay here, / and it's your birth-day ev-ery year. / "
                 "Blow the can-dles, but they come back, / the song re-starts from the first track.",
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

# ---------------------------------------------------------------- SECRET: Rocko (cozy couch -> chase)
SONGS.append(dict(
    id="rocko", title="Oh Hi Rocko", bpm=96, key=62, beats=4, scale="major",
    sections=dict(
        verse=dict(
            melody="3 3 4 5 | 5 4 3:2 | 2 2 3 4 | 4 3 2:2 | 3 3 4 5 | 1' 7 6:2 | 5 4 3 2 | 3 2 1:2",
            chords="I | I | V | V | I | IV | V | I",
            lyrics="Couch is com-fy, phone is off, / par-ty's{teez} o-ver, time to doze. / "
                   "Here comes Rock-o, soft and fluff, / pur-ring right up to my nose.",
            lyrics2="Black and fluf-fy, long long fur, / Rock-o gives a sleep-y purr. / "
                    "Scratch his chin and rub his ear, / best-est kit-ty, Rock-o's here!",
            dark="Out the door and down the street, / Rock-o's right be-hind your feet. / "
                 "Ev-ery street just turns a-round, / back to-ward the par-ty sound.",
            dark2="Run a-way, but where to go? / Rock-o al-ways seems to know. / "
                  "Bal-loons tied to ev-ery door. / One more birth-day, then one more.",
        ),
        chorus=dict(
            melody="5 3 5 3 | 6 5 4 3 | 2 3 4 2 | 3 2 1:2 | 5 3 5 3 | 1' 7 6 5 | 4 4 3 2 | 2 3 1:2",
            chords="I | IV | ii | V:2 I:2 | I | IV | ii | V:2 I:2",
            lyrics="Oh hi, Rock-o, oh hi, Rock-o, / fuz-zy lit-tle friend of mine! / "
                   "Oh hi, Rock-o, pur-ry Rock-o, / ev-ery-thing is feel-ing fine!",
            dark="Oh no, Rock-o! Oh no, Rock-o! / There is no run-ning a-way. / "
                 "Run, run, Chum-bo! Run, run, Chum-bo! / Back to par-ty. Back to stay.",
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
