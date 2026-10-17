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
    voice="guy", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="5:1 5:1 6:1.5 r:0.5 | 5:1 4:1 3:2 | 1:0.5 2:0.5 3:1 4:1 5:1 | 6:0.5 6:0.5 1':3 | "
                   "5:1 5:0.5 5:0.5 6:1 5:1 | 4:0.5 3:0.5 3:1 2:2 | 5,:1 5,:1 6,:1 7,:1 | 3:0.5 2:0.5 1:1 1:2",
            chords="I | I | I | IV | I | V | V | I",
            lyrics="Who is it? / Who is here? / Tell us your name and give a cheer! / "
                   "We've got a cake and a par-ty hat! / Who could it be? / Just tell us that!",
            lyrics2="Knock knock knock! / Who is there? / Some-one's birth-day is in the air! / "
                    "We've got bal-loons and a big pink cake! / Say it with me, / for good-ness sake!",
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
    voice="kid", voice2="lady", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="1:0.5 2:0.5 3:1 3:0.5 4:0.5 5:1 | 6:1 5:1 r:2 | 3:0.5 3:0.5 4:0.5 3:0.5 2:1 1:1 | 2:2 r:2 | "
                   "1:1 2:1 3:0.5 3:0.5 4:1 | 6:2 5:2 | 5:0.5 5:0.5 6:0.5 5:0.5 4:0.5 3:0.5 2:1 | 1:2 r:2",
            chords="I | IV I | I | V | I | IV | V | I",
            lyrics="Bal-loons and cake and pre-sents too, / ev-ery-bo-dy came for you! / "
                   "Ten big box-es tied with bows, / what's in-side them? No-bo-dy knows!",
            lyrics2="Stream-ers, hats and noise-ma-kers too, / ev-ery col-or, red and blue! / "
                    "Jel-ly beans and lem-on-ade, / best-est par-ty ev-er made, yay!",
            dark="The can-dles nev-er burn a-way, / ev-ery day is the same day. / "
                 "Stale bal-loons that nev-er fall. / No-bo-dy leaves this par-ty hall.",
            dark2="You blew the can-dles, made a wish, / woke up here a-gain like this. / "
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
    dark=dict(scale="harm_minor", bpm_mul=0.8, voice="whisper", voice2="deep", detune=18,
              drop=["drums", "glock"],
              add=[P("box", "music_box", "melody", oct=1, vol=-22, pan=0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-24),
                   P("heart", None, "drums", kit=dict(heart="x.......x......."), vol=-20)],
              fx=dict(wow=0.004, lowpass=4500, crackle=0.02, reverb=0.4)),
))

# ---------------------------------------------------------------- 1 KNEAD FOR SPEED: big beat
SONGS.append(dict(
    id="race", title="Knead for Speed", bpm=126, key=55, beats=4, scale="dorian",
    voice="guy", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="1:0.5 1:0.5 3:1 4:1 3:1 | 1:1.5 7,:0.5 r:2 | 1:0.5 1:0.5 3:1 5:1 4:1 | 3:1.5 1:0.5 r:2 | "
                   "4:0.5 4:0.5 6:1 1':1 6:1 | 5:1.5 4:0.5 r:2 | 5:0.5 5:0.5 4:1 3:1 1:1 | 2:1 1:1 r:2",
            chords="I | VII | I | VII | IV | IV | V | I",
            lyrics="Ne{nee}-on lights and mid-night streets, / bass is boom-ing in the seats! / "
                   "Ni{nye}-tro, ni{nye}-tro, push the gas, / Chum-bo's car is ve-ry fast!",
            lyrics2="Pick the col-or, pick the glow, / sprin-kle{kull} stick-ers, read-y, go! / "
                    "Shift the gears and take the turn, / watch the birth-day can-dles burn!",
            dark="Mid-night lights that nev-er end, / ev-ery road is one more bend. / "
                 "Fin-ish line just slides a-way. / Same old par-ty, same old day.",
            dark2="Ev-ery sign says par-ty here, / ze{zee}-ro miles, but nev-er near. / "
                  "Gas runs out, the wheels still turn, / can-dles on the dash-board burn.",
        ),
        chorus=dict(
            melody="5:1 4:0.5 5:1.5 r:1 | 5:1 4:0.5 5:1.5 r:1 | 4:0.5 4:0.5 4:0.5 3:0.5 4:1 5:1 | 3:2 r:2 | "
                   "5:0.5 5:0.5 6:0.5 5:0.5 1':1 5:1 | 6:1 5:1 r:2 | 4:0.5 4:0.5 3:0.5 4:0.5 5:1 3:1 | 1:2 r:2",
            chords="I | VII | IV | IV | I | VII | IV:2 V:2 | I",
            lyrics="Knead for speed, knead for speed, / un-der-ground is where we lead! / "
                   "Ze{zee}-ro to six-ty in a flash, / birth-day boy is in a dash!",
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
    dark=dict(scale="phrygian", bpm_mul=0.78, voice="deep", voice2="whisper", detune=22,
              drop=["drums", "stabs", "gtr", "lead"],
              add=[P("box", "music_box", "melody", oct=1, vol=-23, pan=-0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-22),
                   P("blinker", None, "drums", kit=dict(wood="x...x...x...x...", heart="x.......x......."), vol=-21)],
              fx=dict(wow=0.006, lowpass=3600, crackle=0.02, reverb=0.5)),
))

# ---------------------------------------------------------------- 2 TONY HONK: ska punk
SONGS.append(dict(
    id="skate", title="Two Minute Session", bpm=176, key=62 - 12, beats=4, scale="major",
    voice="guy", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="5:1 5:1 6:1 5:1 | 3:1 1:1 2:2 | 2:1 2:1 3:1 4:1 | 5:1 4:1 3:2 | "
                   "5:1 5:1 6:1 1':1 | 7:1 6:1 5:2 | 4:1 4:1 3:1 2:1 | 3:1 2:1 1:2",
            chords="I | I | V | V | IV | IV | V | I",
            lyrics="Grab your board and roll a-way, / two whole min-utes, let's go play! / "
                   "Kick-flip, grind and ol-lie{lee} high, / Ton-y Honk is fly-ing by!",
            lyrics2="Ramps and rails and half-pipes too, / find the se{see}-cret tape for you! / "
                    "Bail and tum-ble, get back up, / win the birth-day skat-ing cup!",
            dark="Two whole min-utes, nev-er done. / Ses-sion's{shunz} o-ver, just be-gun. / "
                 "Same old ramp and same old rail, / ev-ery land-ing bound to fail.",
            dark2="Guests in hats line up to see. / No one claps and no one's free. / "
                  "Let-ters say: S{ess}, T{tee}, A{ay}, Y{why}. / Ton-y Honk won't say good-bye.",
        ),
        chorus=dict(
            melody="1':1 1':1 1':1 6:1 | 5:1 6:1 5:2 | 4:1 4:1 6:1 5:1 | 4:1 3:1 2:2 | "
                   "5:1 5:1 5:1 1':1 | 7:1 6:1 5:1 6:1 | 4:1 4:1 6:1 5:1 | 3:1 2:1 1:2",
            chords="IV | I | ii | V | V | IV | ii:2 V:2 | I",
            lyrics="Skate! Skate! Skate a-round the park, / fly-ing high from dawn to dark! / "
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
    dark=dict(scale="harm_minor", bpm_mul=0.55, voice="deep", voice2="whisper", detune=20,
              drop=["drums", "power", "horns2"],
              add=[P("dub", None, "drums", kit=dict(kick="x.......x.......", rim="....x.......x...",
                                                     heart="........x......."), vol=-19),
                   P("organ", "organ", "strum", pattern="..x...x...x...x.", oct=0, vol=-25, pan=0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-24)],
              fx=dict(wow=0.005, lowpass=3800, crackle=0.02, reverb=0.45, echo=0.465)),
))

# ---------------------------------------------------------------- 3 DIJIMON: music box waltz
SONGS.append(dict(
    id="digi", title="Dijimon", bpm=132, key=63, beats=3, scale="major",
    voice="lady", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="5:2 3:1 | 1:3 | 5:2 3:1 | 1:3 | 4:2 5:1 | 6:2 5:1 | 4:2 3:1 | 2:3 | "
                   "5:2 3:1 | 1':2 7:1 | 6:2 5:1 | 4:3 | 3:2 4:1 | 5:2 4:1 | 3:2 2:1 | 1:3",
            chords="I | I | I | I | IV | IV | V | V | I | I | IV | V7 | I | V7 | V | I",
            lyrics="Di{dij}-ji{ih}-mon, Di{dij}-ji{ih}-mon, / lit-tle mon-ster, beep beep beep! / "
                   "Hatched from a di{dij}-gi{ih}-tal egg, / yours to love and yours to keep!",
            lyrics2="Di{dij}-ji{ih}-volve, di{dij}-ji{ih}-volve, / grow-ing big-ger, beep beep boop! / "
                    "Feed it, train it, clean the poop, / best friends in a lit-tle loop!",
            dark="Di{dij}-ji{ih}-mon, Di{dij}-ji{ih}-mon, / hun-gry ev-ery sin-gle day. / "
                 "Ate the cake and ate the clock. / Now the hours can't get a-way.",
            dark2="Hatch a-gain, hatch a-gain, / ev-ery birth-day, start a-new. / "
                  "Feed it ev-ery-thing you are, / till there's no one left but you.",
        ),
        chorus=dict(
            melody="1':2 6:1 | 1':2 6:1 | 5:2 6:1 | 5:3 | 4:2 5:1 | 6:2 5:1 | 4:2 2:1 | 3:3 | "
                   "1':2 6:1 | 1':2 6:1 | 2':2 1':1 | 6:3 | 5:2 4:1 | 3:2 5:1 | 2:2 3:1 | 1:3",
            chords="IV | IV | I | I | IV | IV | V7 | I | IV | IV | ii | ii | V7 | I | V | I",
            lyrics="Di{dij}-ji{ih}-mon, di{dij}-gi{ih}-tal friend, / hap-py birth-day, I love you! / "
                   "Ti-ny eyes and ti-ny feet, / Di{dij}-ji{ih}-mon is ve-ry sweet!",
            dark="Di{dij}-ji{ih}-mon, so who are you? / Now you say you're Chum-bo too. / "
                 "Hatch-ing on re-peat, re-peat. / No one leaves and no one sleeps.",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("box", "music_box", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("box2", "music_box", "melody", sections=["chorus"], vol=-25, oct=2, pan=0.3),
        P("kalimba", "kalimba", "bass", pattern="R.5.5.", oct=-1, vol=-18),
        P("arp", "music_box", "arp", rate=1.0, shape="waltz", oct=0, vol=-25, pan=-0.3),
        P("beeps", "pulse25", "arp", rate=1.0, shape="up", oct=2, vol=-31, pan=0.4, sections=["chorus", "break"]),
        P("pad", "pad", "pad", oct=0, vol=-27),
        P("drums", None, "drums", kit=dict(shaker="x...x...x..."), vol=-28),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.78, voice="whisper", voice2="croak", detune=30,
              drop=["drums", "box2", "beeps"],
              add=[P("theremin", "theremin", "melody", oct=1, vol=-24, sections=["verse", "chorus"]),
                   P("drone", "pad", "drone", oct=-1, vol=-22)],
              fx=dict(wow=0.008, lowpass=3500, crackle=0.03, reverb=0.5)),
))

# ---------------------------------------------------------------- 4 CARDS: bossa nova
SONGS.append(dict(
    id="cards", title="Birthday Mail", bpm=128, key=62 - 12, beats=4, scale="major",
    voice="deep", voice2="guy", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="r:0.5 3:1 3:0.5 5:1 4:1 | 3:1.5 2:0.5 1:2 | r:0.5 2:1 2:0.5 4:1 3:1 | 2:1.5 1:0.5 7,:2 | "
                   "r:0.5 3:1 3:0.5 5:1 7:1 | 6:1.5 5:0.5 4:2 | r:0.5 4:1 4:0.5 3:1 2:1 | 3:1.5 2:0.5 1:2",
            chords="I7 | vi7 | ii7 | V7 | I7 | IV7 | ii7 V7 | I7",
            lyrics="Birth-day cards are fly-ing in, / stamp them all and let them in! / "
                   "Check the name and check the day, / ev-ery card says it's to-day!",
            lyrics2="Grand-ma's card has glit-ter glue, / Un-cle sent a pup-py too! / "
                    "Some are fun-ny, some are sweet, / stamp them all and stamp them neat!",
            dark="Let-ters come from far a-way. / Names are fad{fay}-ing{ding} ev-ery day. / "
                 "Some-one used to write to you. / Now their name is fad{fay}-ing{ding} too.",
            dark2="Ev-ery year a lit-tle less, / for-got-ten name and ad-dress. / "
                  "Stamp it, stamp it, let it go. / Who it was, you'll nev-er know.",
        ),
        chorus=dict(
            melody="5:0.5 6:1 5:0.5 6:1 5:0.5 6:0.5 | 1':1 7:3 | r:0.5 6:1 6:0.5 5:1 4:1 | 3:1.5 4:0.5 5:2 | "
                   "r:0.5 3:1 3:0.5 4:1 5:1 | 6:1.5 5:0.5 3:2 | r:0.5 2:1 2:0.5 3:1 4:1 | 2:1.5 7,:0.5 1:2",
            chords="vi7 | I7 | ii7 | I7 | IV7 | vi7 | ii7 | V7 I7",
            lyrics="Ap-proved, ap-proved, ap-proved for you! / Grand-ma's card is ve-ry true! / "
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
    dark=dict(scale="harm_minor", bpm_mul=0.8, voice="croak", voice2="whisper", detune=20,
              drop=["vibes2"],
              add=[P("drone", "strings", "drone", oct=-1, vol=-24),
                   P("bells", "bell", "arp", rate=4.0, shape="up", oct=1, vol=-28)],
              fx=dict(wow=0.006, lowpass=3200, crackle=0.04, reverb=0.4, radio=True)),
))

# ---------------------------------------------------------------- 5 CALL OF BIRTHDAY: epic orchestral
SONGS.append(dict(
    id="duty", title="Call of Birthday", bpm=104, key=62 - 12, beats=4, scale="major",
    voice="guy", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="1:0.75 1:0.25 3:1 5:2 | 6:1 5:1 3:2 | 4:0.75 4:0.25 6:1 5:2 | 3:1 2:1 5,:2 | "
                   "1:0.75 1:0.25 3:1 5:2 | 1':1 7:1 6:2 | 5:0.75 4:0.25 3:1 2:2 | 3:1 2:1 1:2",
            chords="I | vi:2 I:2 | IV | V | I | IV | ii:2 V:2 | I",
            lyrics="Load your darts and grab your hat, / mis-sion{shun}: par-ty, that is that! / "
                   "Pop the tar-gets, card-board crew, / Ser{sar}-geant{jent} Cake is proud of you!",
            lyrics2="Out-post Bounce-House, hold the line, / cake de-liv-ered right on time! / "
                    "Care pack-age{ij} is drop-ping in, / pres-ents mean we're gon-na win!",
            dark="Round one, round two, round a-gain. / Guests come back, they nev-er end. / "
                 "Hats are crook-ed, fac{fay}-es{sez} gray, / sing-ing stay, just one more day.",
            dark2="Out of darts and out of time, / ev-ery round's the same old rhyme. / "
                  "Count the rounds, they nev-er stop. / No ex-trac-tion{shun}, no air-drop.",
        ),
        chorus=dict(
            melody="5:1 5:0.5 5:0.5 1':2 | 7:1 6:1 5:2 | 4:1 4:0.5 4:0.5 6:2 | 5:1 4:1 3:2 | "
                   "5:1 5:0.5 5:0.5 2':2 | 1':1 7:1 6:2 | 6:1 5:1 4:1 2:1 | 3:1 2:1 1:2",
            chords="I | V:2 I:2 | IV | I | V | IV | ii:2 V:2 | I",
            lyrics="Call of Birth-day! Hear the call! / Fall in line and give it all! / "
                   "Foam darts fly-ing, can-dles bright, / we will par-ty day and night!",
            dark="Call of Birth-day, hear them call, / rounds that nev-er end at all. / "
                 "Hap-py birth-day, here they come. / There's no-where for you to run.",
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
    dark=dict(scale="harm_minor", bpm_mul=0.72, voice="croak", voice2="whisper", detune=25,
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
    voice="lady", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="1:0.5 1:0.5 3:0.5 1:0.5 5:1 4:0.5 3:0.5 | 3:2 r:2 | 2:0.5 2:0.5 2:0.5 3:0.5 4:1 3:1 | 2:2 r:2 | "
                   "1:0.5 1:0.5 3:0.5 5:0.5 6:1 5:1 | 5:2 r:2 | 6:0.5 5:0.5 4:0.5 3:0.5 2:1 1:1 | 2:2 r:2",
            chords="I | I | V | V | vi | I | IV | V",
            lyrics="Jump off the bus, it's par-ty time! / Build it up and watch me climb! / "
                   "Vic-to-ry is on the line, / danc-ing ev-ery sin-gle time!",
            lyrics2="Land at Cake Cas-tle, find the loot! / Dance a lit-tle, rock that suit! / "
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
                   "Ev-ery-bod-y in the game / yel-ling out your birth-day name!",
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
    dark=dict(scale="nat_minor", bpm_mul=0.75, voice="deep", voice2="whisper", detune=20,
              drop=["arp", "drums"],
              add=[P("drone", "strings", "drone", oct=-1, vol=-22),
                   P("slow", None, "drums", kit=dict(kick="x.......x.......", hat="....x.......x..."), vol=-20)],
              fx=dict(wow=0.006, lowpass=3000, crackle=0.02, reverb=0.5)),
))

# ---------------------------------------------------------------- 7 ROBLOCKS: tropical
SONGS.append(dict(
    id="obby", title="Obby Hop", bpm=112, key=57, beats=4, scale="major",
    voice="kid", voice2="lady", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="5:1 5:1 5:1 r:0.5 3:0.5 | 4:0.5 3:0.5 1:1 r:2 | 2:1 3:1 4:1 r:0.5 4:0.5 | 3:0.5 2:0.5 5,:1 r:2 | "
                   "5:1 5:1 5:1 r:0.5 6:0.5 | 5:0.5 4:0.5 3:1 r:2 | 2:1 2:1 3:1 r:0.5 2:0.5 | 7,:0.5 6,:0.5 1:1 r:2",
            chords="I | I | V | V | I | IV | V | I",
            lyrics="Jump jump jump a-cross the bricks, / show-ing off my coo-lest tricks! / "
                   "Oof oof oof, I fell a-gain, / re-spawn with my best-est friends!",
            lyrics2="La-va blocks are hot hot hot, / check-point flag, I like this spot! / "
                    "Spin-ning bars go round and round, / bounce bounce bounce right off the ground!",
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
    dark=dict(scale="harm_minor", bpm_mul=0.8, voice="robot", voice2="whisper", detune=25,
              drop=["drums", "steel2", "marimba"],
              add=[P("marimba_slow", "marimba", "arp", rate=1.0, shape="up", oct=0, vol=-22),
                   P("drone", "pad", "drone", oct=-1, vol=-22),
                   P("tick", None, "drums", kit=dict(kick="x.......x.......", rim="........x......."), vol=-22)],
              fx=dict(wow=0.007, lowpass=3500, crackle=0.02, reverb=0.5, crush=True)),
))

# ---------------------------------------------------------------- 8 POKEMANS: Game Boy
SONGS.append(dict(
    id="poke", title="Catch a Friend", bpm=150, key=60, beats=4, scale="major",
    voice="kid", voice2="kid", vocal_oct=0, crush_vocals=True,
    sections=dict(
        verse=dict(
            melody="1:1.5 1:0.5 5:1 5:1 | 6:1 5:1 3:2 | 4:1.5 4:0.5 3:1 3:1 | 2:1 1:1 2:2 | "
                   "1:1.5 1:0.5 5:1 5:1 | 6:1 7:1 1':2 | 6:1.5 6:0.5 5:1 4:1 | 3:1 2:1 5,:2",
            chords="I | IV:1 I:3 | IV | V | I | vi:1 V:1 I:2 | IV | V",
            lyrics="Throw the ball and catch a friend, / birth-day bat-tles nev-er end! / "
                   "Par-ty-chu and Cake-man-der, / ev-ery mon-ster loves you too!",
            lyrics2="Walk-ing through the tall green grass, / wild ones jump out, catch them fast! / "
                    "Gym badge num-ber eight is mine, / Chum-bo's team is do-ing fine!",
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
    dark=dict(scale="locrian_ish", bpm_mul=0.62, voice="croak", voice2="whisper", detune=10,
              drop=["drums", "arp", "lead2"],
              add=[P("arp_slow", "pulse25", "arp", rate=0.5, shape="down", oct=0, vol=-24),
                   P("drone", "gb_wave", "drone", oct=-1, vol=-24)],
              fx=dict(wow=0.004, lowpass=4000, crackle=0.01, reverb=0.55, crush=True)),
))

# ---------------------------------------------------------------- 9 LIGHTS OUT: pizzicato 6/8
SONGS.append(dict(
    id="lights", title="Hide and Seek", bpm=210, key=62, beats=6, scale="major",
    voice="lady", voice2="whisper", vocal_oct=0, double_whisper=True,
    sections=dict(
        verse=dict(
            melody="5:2 3:1 5:2 3:1 | 4:1 3:1 2:1 1:3 | 1:1 2:1 3:1 4:2 3:1 | 2:1 3:1 4:1 5:3 | "
                   "5:1 6:1 5:1 4:2 3:1 | 2:1 3:1 4:1 2:1 5:2 | 1':1 7:1 6:1 5:2 4:1 | 3:1 2:1 7,:1 1:3",
            chords="I | V:3 I:3 | I | V | IV | V | IV | V:3 I:3",
            lyrics="Lights out, lights out, where did they go? / Hid-ing and gig-gling, tip-py-toe slow. / "
                   "Un-der the ta-ble and up on the stair, / shine your lit-tle light, they're ev-ery-where!",
            lyrics2="Hush, hush, hush, hush, who's in the hall? / Some-bo-dy's gig-gle be-hind the wall! / "
                    "Cur-tains are wig-gling and toes peek-ing out, / fol-low the gig-gles{gulls}, with-out a doubt!",
            dark="Lights out, lights out, no one's a-wake, / count-ing the can-dles on some-one's cake. / "
                 "Hide un-der cov-ers and wait for the day. / Dawn will come, and it's still your birth-day.",
            dark2="Lights out, lights out, count up to ten. / O-pen your eyes, it's start-ing a-gain. / "
                  "Ev-ery-one hid-ing has hid-den for years. / No-bo-dy's com-ing to dry your tears.",
        ),
        chorus=dict(
            melody="5:2 5:1 6:2 5:1 | 3:2 2:1 1:3 | 6:2 6:1 1':2 6:1 | 5:2 3:1 5:3 | "
                   "5:1 6:1 5:1 3:1 4:1 3:1 | 2:2 3:1 5:3 | 1':1 7:2 6:1 5:2 | 4:2 2:1 1:3",
            chords="I | V:3 I:3 | IV | I | I | V | IV | V:3 I:3",
            lyrics="Read-y or not, here I come! / Find all your friends, ev-ery one! / "
                   "Peek-a-boo, peek-a-boo, I see you! / Sur-prise, sur-prise, we love you!",
            dark="Read-y or not, here they come. / Hide if you like, but they've won. / "
                 "Peek-a-boo, peek-a-boo, they see you. / Your turn. You are al-ways it.",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("celesta", "celesta", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("celesta2", "celesta", "melody", sections=["chorus"], vol=-26, oct=2, pan=0.3),
        P("pizz", "pizz", "bass", pattern="R.5R.5", oct=-1, vol=-17),
        P("harp", "harp", "arp", rate=1.0, shape="up", oct=0, vol=-24, pan=-0.3),
        P("drums", None, "drums", kit=dict(timpani="x...........", shaker="..x..x..x..x"), vol=-24),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.8, voice="whisper", voice2="croak", detune=20,
              drop=["drums", "celesta2"],
              add=[P("drone", "strings", "drone", oct=-1, vol=-21),
                   P("heart", None, "drums", kit=dict(heart="x...........x..........."), vol=-18)],
              fx=dict(wow=0.006, lowpass=3200, crackle=0.02, reverb=0.55)),
))

# ---------------------------------------------------------------- 10 KARAOKE: disco finale
SONGS.append(dict(
    id="karaoke", title="Chumbo's Birthday Song", bpm=118, key=64, beats=4, scale="major",
    voice="lady", voice2="kid", vocal_oct=0, choir=True,
    sections=dict(
        verse=dict(
            melody="5,:0.5 1:0.5 2:0.5 3:0.5 3:0.5 2:0.5 3:1 | 5:1 3:3 | 4:0.5 4:0.5 4:0.5 3:0.5 4:0.5 5:0.5 4:1 | 3:1 2:3 | "
                   "5,:0.5 1:0.5 2:0.5 3:0.5 3:0.5 2:0.5 3:1 | 6:1 5:3 | 6:0.5 6:0.5 5:0.5 4:0.5 3:0.5 2:0.5 3:1 | 2:1 5,:3",
            chords="I | I | IV | V | I | IV:1 I:3 | IV | V",
            lyrics="Can-dles on the cake are burn-ing bright, / ev-ery-bo-dy's danc-ing here to-night! / "
                   "Pre-sents o-pened, all the games are won, / sing it loud, the par-ty's just be-gun!",
            lyrics2="Dis-co ball is spin-ning round and round, / ev-ery-bo-dy jump-ing up and down! / "
                    "Grab the mi{my}-cro-phone and sing a-long, / this is Chum-bo's ve-ry spe-cial{shull} song!",
            dark="Can-dles on the cake will al-ways burn. / Ev-ery year you wait, and it's your turn. / "
                 "Sing the song a-gain, the same old tune. / No one ev-er leaves this par-ty room.",
            dark2="Ev-ery-bo-dy smil-ing, eyes so wide. / No one's left out-side, they're all in-side. / "
                  "Blow the can-dles out and close your eyes. / O-pen them, sur-prise, the same sun-rise.",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 6:0.5 6:0.5 5:1 5:1 | 3:1 5:3 | 4:0.5 4:0.5 4:0.5 4:0.5 6:1 5:1 | 3:4 | "
                   "1':0.5 1':0.5 6:0.5 6:0.5 5:1 5:1 | 6:4 | 4:0.5 4:0.5 3:0.5 2:0.5 3:1 2:1 | 1:4",
            chords="IV:2 I:2 | I | IV | I | IV:2 I:2 | vi | ii:2 V:2 | I",
            lyrics="Hap-py, hap-py birth-day, Chum-bo! / Hands up high and down down low! / "
                   "Make a wish and blow, blow, blow! / Hap-py birth-day, here we go!",
            dark="Hap-py, hap-py birth-day, Chum-bo. / You can nev-er, ev-er go. / "
                 "Make a wish. It won't come true. / See you next year. Here we go.",
        ),
    ),
    form=LONG_FORM,
    parts=[
        P("brass", "brass", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("clav", "clav", "strum", pattern="x.xx.x.xx.xx.x.x", oct=0, vol=-23, pan=-0.3),
        P("strings", "strings", "pad", oct=1, vol=-24, pan=0.3),
        P("stabs", "brass", "strum", pattern="......x.......x.", oct=0, vol=-22, sections=["chorus", "break"]),
        P("bass", "slap_bass", "bass", pattern="R.O.R.O.R.O.R.O.", oct=-2, vol=-15),
        P("drums", None, "drums", kit=dict(kick="x...x...x...x...", clap="....x.......x...",
                                            ohat="..x...x...x...x.", hat="x.x.x.x.x.x.x.x.",
                                            tamb="....x.......x...", crash="x..............."), crash_every=8, vol=-17),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.75, voice="deep", voice2="whisper", detune=18,
              drop=["drums", "clav", "stabs"],
              add=[P("drone", "choir", "drone", oct=0, vol=-22),
                   P("box", "music_box", "melody", oct=2, vol=-24),
                   P("heart", None, "drums", kit=dict(heart="x.......x......."), vol=-17)],
              fx=dict(wow=0.007, lowpass=3500, crackle=0.03, reverb=0.55)),
))

# ---------------------------------------------------------------- SECRET: Rocko (cozy couch -> chase)
SONGS.append(dict(
    id="rocko", title="Oh Hi Rocko", bpm=96, key=62, beats=4, scale="major",
    voice="lady", voice2="guy", vocal_oct=0,
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
    dark=dict(scale="phrygian", bpm_mul=1.4, voice="croak", voice2="deep", detune=20,
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
