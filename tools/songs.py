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
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 6:1 5:2 | 4:0.5 4:0.5 6:1 5:2 | 3:0.5 4:0.5 5:1 5:1 6:1 | 5:4 | "
                   "1':0.75 1':0.25 7:1 6:2 | 4:1 5:3 | 2:1 2:1 3:1 4:1 | 2:1 1:3",
            chords="IV | IV I | I | V | I | IV | V | I",
            lyrics="Is it Chum-bo? / Yes, it's Chum-bo! / No-bo-dy else could be! / "
                   "Hap-py birth-day, Chum-bo! / Now type it in for me!",
        ),
    ),
    form=STD_FORM,
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
            dark="Bal-loons are sag-ging, cake is cold, / no one here is get-ting old. / "
                 "Ten big box-es, one by one, / o-pen them and then you'll be done.",
        ),
        chorus=dict(
            melody="5:1 5:0.5 6:0.5 5:1 3:1 | 1':1 7:1 r:2 | 1':0.5 1':0.5 7:1 1':0.5 1':0.5 7:1 | 6:1 5:1 r:2 | "
                   "3:0.5 3:0.5 4:0.5 3:0.5 2:1 5:1 | 5:2 r:2 | 1':1 6:1 1':1 6:1 | 5:0.5 2:0.5 1:3",
            chords="I | IV V | IV V | I | vi | V | IV | V I",
            lyrics="It's your birth-day, it's your day! / Hip hip hoo-ray, hip hip hoo-ray! / "
                   "Ev-ery-bo-dy's glad you came, / Chum-bo, Chum-bo, that's your name!",
            dark="It's your birth-day, ev-ery day. / No-bo-dy ev-er goes a-way. / "
                 "Ev-ery-bo-dy's glad you came. / Chum-bo, Chum-bo, stay and play.",
        ),
    ),
    form=STD_FORM,
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

# ---------------------------------------------------------------- 1 CAKE: toy piano
SONGS.append(dict(
    id="cake", title="Stack It Up", bpm=108, key=60, beats=4, scale="major",
    voice="kid", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="1 3 5 3 | 4 6 5:2 | 6 5 4 3 | 2 3 1:2 | 1 3 5 1' | 7 6 5:2 | 6 6 5 4 | 3 2 1:2",
            chords="I | IV I | IV | V I | I | V | IV | V I",
            lyrics="Stack it up and stack it high, / birth-day cake up to the sky! / "
                   "Fros-ting pink and fros-ting blue, / ev-ery lay-er is for you!",
            dark="Stack it up and stack it high. / Some-thing's wait-ing in the sky. / "
                 "Rai-sins blink-ing in the dark. / Ev-ery lay-er leaves a mark.",
        ),
        chorus=dict(
            melody="5 5 1' 1' | 6 6 5:2 | 4 4 6 6 | 5 4 3:2 | 5 5 1' 1' | 2' 1' 6:2 | 5 6 5 3 | 2 2 1:2",
            chords="I | IV I | IV | V I | I | ii | I | V I",
            lyrics="Chum-bo, Chum-bo, it's your day! / Blow the can-dles all a-way! / "
                   "One more lay-er, one more slice, / birth-day cake is ve-ry nice!",
            dark="Chum-bo, Chum-bo, don't look down. / Some-one wants a slice to-night. / "
                 "One more lay-er, one more slice. / Birth-day cake has eyes. How nice.",
        ),
    ),
    form=STD_FORM,
    parts=[
        P("lead", "toy_piano", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("glock", "glock", "melody", sections=["chorus"], vol=-25, oct=2, pan=0.3),
        P("arp", "toy_piano", "arp", rate=0.5, shape="updown", oct=0, vol=-24, pan=-0.3),
        P("bass", "synth_bass", "bass", pattern="R..R..5.", oct=-2, vol=-18),
        P("drums", None, "drums", kit=dict(kick="x.......x.......", wood="....x.......x..x",
                                            shaker="..x...x...x...x.", clap="............x..."), vol=-21),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.82, voice="croak", voice2="whisper", detune=22,
              drop=["drums", "glock"],
              add=[P("box", "music_box", "melody", oct=2, vol=-22, pan=-0.3),
                   P("drone", "pad", "drone", oct=-1, vol=-23),
                   P("tick", None, "drums", kit=dict(wood="x...x...x...x..."), vol=-26)],
              fx=dict(wow=0.005, lowpass=4000, crackle=0.025, reverb=0.45)),
))

# ---------------------------------------------------------------- 2 SHEEP: bluegrass
SONGS.append(dict(
    id="sheep", title="Little Sheep", bpm=140, key=62 - 12, beats=4, scale="major", swing=0.12,
    voice="guy", voice2="guy", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="3:0.5 4:0.5 5:1 5:1 6:0.5 5:0.5 | 3:3 r:1 | 2:0.5 3:0.5 4:1 4:1 3:0.5 2:0.5 | 1:3 r:1 | "
                   "1:0.5 1:0.5 3:1 3:1 5:0.5 5:0.5 | 6:3 r:1 | 6:0.5 5:0.5 4:1 3:1 2:0.5 2:0.5 | 1:3 r:1",
            chords="I | I | V | I | I | IV | IV V | I",
            lyrics="Lit-tle sheep in par-ty hats, / count-ing sheep is where it's at! / "
                   "One and two and three and four, / five go march-ing through the door!",
            dark="Lit-tle sheep, don't turn a-round. / One of you stood off the ground, / "
                 "stand-ing on its two back legs, / wool-ly coat it does-n't own.",
        ),
        chorus=dict(
            melody="5:1 5:1 5:1 r:0.5 6:0.5 | 5:1 4:1 3:2 | 4:0.5 4:0.5 4:1 6:1 5:0.5 4:0.5 | 3:3 r:1 | "
                   "3:0.5 3:0.5 4:1 5:1 1':0.5 7:0.5 | 6:3 r:1 | 5:1 5:1 5:1 5:1 | 2:1 3:1 1:2",
            chords="I | V I | IV | I | I | vi | I | V I",
            lyrics="Baa baa baa, a-round they go, / pup-py herd them nice and slow! / "
                   "Ev-ery sheep is safe and sound, / baa baa baa baa, all a-round!",
            dark="Baa baa baa, it's at the gate. / Pup-py, it is get-ting late. / "
                 "Count them once and count a-gain. / Six were sheep, but sev-en came.",
        ),
    ),
    form=STD_FORM,
    parts=[
        P("fiddle", "fiddle", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("harmonica", "harmonica", "pad", sections=["chorus"], vol=-26, oct=0, pan=0.3),
        P("banjo", "banjo", "arp", rate=0.5, shape="roll", oct=0, vol=-21, pan=-0.25),
        P("bass", "upright", "bass", pattern="R...5...", oct=-1, vol=-16),
        P("drums", None, "drums", kit=dict(washboard="x.x.x.x.x.x.x.x.", kick="x.......x.......",
                                            snare="....x.......x..."), vol=-21),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.7, voice="deep", voice2="whisper", detune=25,
              drop=["drums", "banjo"],
              add=[P("slowbanjo", "banjo", "arp", rate=1.0, shape="up", oct=0, vol=-22, pan=-0.3),
                   P("drone", "fiddle", "drone", oct=-1, vol=-27),
                   P("creak", None, "drums", kit=dict(wood="x..............."), vol=-24)],
              fx=dict(wow=0.006, lowpass=3800, crackle=0.03, reverb=0.4)),
))

# ---------------------------------------------------------------- 3 BLOB: music box waltz
SONGS.append(dict(
    id="blob", title="Little Blob", bpm=132, key=63, beats=3, scale="major",
    voice="lady", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="5:2 3:1 | 1:3 | 5:2 3:1 | 1:3 | 4:2 5:1 | 6:2 5:1 | 4:2 3:1 | 2:3 | "
                   "5:2 3:1 | 1':2 7:1 | 6:2 5:1 | 4:3 | 3:2 4:1 | 5:2 4:1 | 3:2 2:1 | 1:3",
            chords="I | I | I | I | IV | IV | V | V | I | I | IV | V7 | I | V7 | V | I",
            lyrics="Lit-tle blob, lit-tle blob, / wig-gle wob-ble lit-tle blob! / "
                   "Eat your cake and go to sleep, / I will love you, yours to keep!",
            dark="Lit-tle blob, lit-tle blob, / grow-ing big-ger, lit-tle blob. / "
                 "Ate the cake and ate the plate, / ate the clock, it's get-ting late.",
        ),
        chorus=dict(
            melody="1':2 6:1 | 1':2 6:1 | 5:2 6:1 | 5:3 | 4:2 5:1 | 6:2 5:1 | 4:2 2:1 | 3:3 | "
                   "1':2 6:1 | 1':2 6:1 | 2':2 1':1 | 6:3 | 5:2 4:1 | 3:2 5:1 | 2:2 3:1 | 1:3",
            chords="IV | IV | I | I | IV | IV | V7 | I | IV | IV | ii | ii | V7 | I | V | I",
            lyrics="Blob-by, blob-by, ba-by blue, / hap-py birth-day, I love you! / "
                   "Ti-ny eyes and ti-ny feet, / lit-tle blob is ve-ry sweet!",
            dark="Blob-by, blob-by, who are you? / Now you say you're Chum-bo too. / "
                 "Ma{meh}-ny eyes and ma{meh}-ny feet. / Lit-tle blob still wants to eat.",
        ),
    ),
    form=STD_FORM,
    parts=[
        P("box", "music_box", "melody", sections=["intro", "break"], vol=-15, oct=1),
        P("box2", "music_box", "melody", sections=["chorus"], vol=-25, oct=2, pan=0.3),
        P("kalimba", "kalimba", "bass", pattern="R.5.5.", oct=-1, vol=-18),
        P("arp", "music_box", "arp", rate=1.0, shape="waltz", oct=0, vol=-25, pan=-0.3),
        P("pad", "pad", "pad", oct=0, vol=-27),
        P("drums", None, "drums", kit=dict(shaker="x...x...x..."), vol=-28),
    ],
    dark=dict(scale="harm_minor", bpm_mul=0.78, voice="whisper", voice2="croak", detune=30,
              drop=["drums", "box2"],
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
            dark="Birth-day cards from who knows where, / signed by some-one on the stair. / "
                 "Check the name, it's al-ways you. / Ev-ery card is com-ing true.",
        ),
        chorus=dict(
            melody="5:0.5 6:1 5:0.5 6:1 5:0.5 6:0.5 | 1':1 7:3 | r:0.5 6:1 6:0.5 5:1 4:1 | 3:1.5 4:0.5 5:2 | "
                   "r:0.5 3:1 3:0.5 4:1 5:1 | 6:1.5 5:0.5 3:2 | r:0.5 2:1 2:0.5 3:1 4:1 | 2:1.5 7,:0.5 1:2",
            chords="vi7 | I7 | ii7 | I7 | IV7 | vi7 | ii7 | V7 I7",
            lyrics="Ap-proved, ap-proved, ap-proved for you! / Grand-ma's card is ve-ry true! / "
                   "Love and hugs and lots of mail, / hap-py birth-day, with-out fail!",
            dark="Ap-proved, ap-proved, there's no de-ny{nye}. / Let them in and don't ask why. / "
                 "Ev-ery-one has sent you mail. / Wel-come, wel-come, with-out fail.",
        ),
    ),
    form=STD_FORM,
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

# ---------------------------------------------------------------- 5 CLAW: carnival calliope
SONGS.append(dict(
    id="claw", title="Drop the Claw", bpm=150, key=65, beats=4, scale="major",
    voice="robot", voice2="kid", vocal_oct=0,
    sections=dict(
        verse=dict(
            melody="5:0.5 4:0.5 3:0.5 4:0.5 5:1 3:1 | 1:2 r:2 | 2:0.5 3:0.5 4:0.5 5:0.5 6:1 5:1 | 5:2 r:2 | "
                   "5:0.5 4:0.5 3:0.5 4:0.5 5:1 1':1 | 6:2 r:2 | 6:0.5 5:0.5 4:0.5 3:0.5 2:1 7,:1 | 1:2 r:2",
            chords="I | I | V | I | I | IV | IV V | I",
            lyrics="Drop the claw and grab a prize, / ted-dy bear with but-ton eyes! / "
                   "One more coin and one more try, / win a toy and wave good-bye!",
            dark="Drop the claw, they're look-ing up, / but-ton eyes that nev-er shut. / "
                 "We are soft and we are near. / Take us home and hold us dear.",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 1':0.5 7:0.5 6:1 5:1 | 3:2 r:2 | 4:0.5 4:0.5 4:0.5 5:0.5 6:1 5:1 | 2:2 r:2 | "
                   "3':0.5 2':0.5 1':0.5 7:0.5 6:1 5:1 | 1':2 r:2 | 4:0.5 3:0.5 2:0.5 3:0.5 5:1 7,:1 | 1:2 r:2",
            chords="I | I | IV | V | I | IV | V | I",
            lyrics="Round and round the toys all go, / which one's com-ing home? I know! / "
                   "Ted-dy, duck-y, star and bun, / claw ma-chines are lots of fun!",
            dark="Round and round the toys all go. / Hand-prints on the glass. Hel-lo. / "
                 "Ted-dy, duck-y, star and you. / You're the prize we're grab-bing too.",
        ),
    ),
    form=STD_FORM,
    parts=[
        P("calliope", "calliope", "melody", sections=["intro", "verse", "break"], vol=-16, oct=1),
        P("calliope2", "calliope", "melody", sections=["chorus"], vol=-21, oct=1),
        P("organbass", "organ", "bass", pattern="R...5...", oct=-2, vol=-16),
        P("pah", "accordion", "strum", pattern="..x...x.", oct=0, vol=-22, pan=0.3),
        P("glock", "glock", "arp", rate=0.5, shape="up", oct=1, vol=-28, pan=-0.35),
        P("drums", None, "drums", kit=dict(snare="....x.......x...", kick="x.......x.......",
                                            crash="x..............."), crash_every=4, vol=-21),
    ],
    dark=dict(scale="phrygian", bpm_mul=0.72, voice="whisper", voice2="robot", detune=35,
              drop=["drums", "glock", "calliope2"],
              add=[P("drone", "organ", "drone", oct=-1, vol=-24),
                   P("tick", None, "drums", kit=dict(wood="x.......x......."), vol=-26)],
              fx=dict(wow=0.01, lowpass=3500, crackle=0.03, reverb=0.45)),
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
            dark="The storm is clos-ing, lights are low. / One more play-er you don't know. / "
                 "Build a wall and hold it tight. / Some-thing's in the storm to-night.",
        ),
        chorus=dict(
            melody="5:1 5:0.5 6:0.5 1':1 6:1 | 5:1 3:1 r:2 | 4:1 4:0.5 5:0.5 6:1 5:1 | 3:1 2:1 r:2 | "
                   "5:1 5:0.5 6:0.5 1':1 2':1 | 1':1 6:1 r:2 | 4:1 4:0.5 5:0.5 6:1 5:1 | 2:1 1:1 r:2",
            chords="IV | I | ii | V | IV | vi | ii | V I",
            lyrics="Birth-day Roy-ale, num-ber one! / Build a wall and have some fun! / "
                   "Ev-ery-bod-y in the game / yel-ling out your birth-day name!",
            dark="Birth-day Roy-ale, two re-main. / Some-one's call-ing out your name. / "
                 "Ev-ery-bod-y left the game. / Ev-ery face looks just the same.",
        ),
    ),
    form=STD_FORM,
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
            dark="Jump jump jump in-to the void. / All my friends have gone, an-noyed. / "
                 "Some-one's typ-ing, no one's there. / Chum-bo's stand-ing o-ver there.",
        ),
        chorus=dict(
            melody="1':1 6:1 1':1 r:0.5 6:0.5 | 5:0.5 5:0.5 5:1 r:2 | 4:1 4:1 6:1 r:0.5 6:0.5 | 5:0.5 3:0.5 1:1 r:2 | "
                   "1':1 6:1 1':1 r:0.5 2':0.5 | 1':0.5 6:0.5 5:1 r:2 | 4:1 4:1 3:1 r:0.5 2:0.5 | 5,:0.5 7,:0.5 1:1 r:2",
            chords="IV | I | IV | I | IV | vi V | ii | V I",
            lyrics="O-bby, o-bby, hop hop hop, / climb up to the ve-ry top! / "
                   "Birth-day badge is wait-ing there, / bloc-ky bud-dies ev-ery-where!",
            dark="O-bby, o-bby, stop stop stop. / Some-one's wait-ing at the top. / "
                 "Birth-day badge, he wants it too. / Chum-bo, Chum-bo, which is you?",
        ),
    ),
    form=STD_FORM,
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
            dark="Lost in grass that grows too tall, / some-thing's crawl-ing, hear it call. / "
                 "Knows your name and knows the way. / It caught you on your birth-day.",
        ),
        chorus=dict(
            melody="1':1.5 1':0.5 7:1 6:1 | 5:1 6:1 5:2 | 4:1.5 4:0.5 5:1 6:1 | 5:1 4:1 3:2 | "
                   "1':1.5 1':0.5 7:1 6:1 | 5:1 6:1 1':2 | 2':1.5 2':0.5 1':1 7:1 | 6:1 7:1 1':2",
            chords="IV | I | ii | V:2 I:2 | IV | I | V | IV:1 V:1 I:2",
            lyrics="Gon-na catch them, ev-ery one! / Pock-et mon-sters, so much fun! / "
                   "Tall grass rus-tling, here they come! / Chum-bo is the cham-pi-on!",
            dark="Gon-na catch them, ev-ery one. / Now it's their turn. Chum-bo, run. / "
                 "Tall grass whis-pers, here they come. / Chum-bo's in the ball. All done.",
        ),
    ),
    form=STD_FORM,
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
            dark="Lights out, lights out, count them a-gain. / Eight lit-tle guests and then nine, then ten. / "
                 "Un-der the ta-ble and be-hind the door, / al-ways one more, there's al-ways one more.",
        ),
        chorus=dict(
            melody="5:2 5:1 6:2 5:1 | 3:2 2:1 1:3 | 6:2 6:1 1':2 6:1 | 5:2 3:1 5:3 | "
                   "5:1 6:1 5:1 3:1 4:1 3:1 | 2:2 3:1 5:3 | 1':1 7:2 6:1 5:2 | 4:2 2:1 1:3",
            chords="I | V:3 I:3 | IV | I | I | V | IV | V:3 I:3",
            lyrics="Read-y or not, here I come! / Find all your friends, ev-ery one! / "
                   "Peek-a-boo, peek-a-boo, I see you! / Sur-prise, sur-prise, we love you!",
            dark="Read-y or not, here they come. / Find all your friends, and some-one. / "
                 "Peek-a-boo, peek-a-boo, they see you. / Sur-prise, sur-prise, found you too.",
        ),
    ),
    form=STD_FORM,
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
            dark="Can-dles on the cake will nev-er die. / Ev-ery-bo-dy's smil-ing, don't ask why. / "
                 "Pre-sents o-pened, now the games are done. / Ev-ery year the par-ty's just be-gun.",
        ),
        chorus=dict(
            melody="1':0.5 1':0.5 6:0.5 6:0.5 5:1 5:1 | 3:1 5:3 | 4:0.5 4:0.5 4:0.5 4:0.5 6:1 5:1 | 3:4 | "
                   "1':0.5 1':0.5 6:0.5 6:0.5 5:1 5:1 | 6:4 | 4:0.5 4:0.5 3:0.5 2:0.5 3:1 2:1 | 1:4",
            chords="IV:2 I:2 | I | IV | I | IV:2 I:2 | vi | ii:2 V:2 | I",
            lyrics="Hap-py, hap-py birth-day, Chum-bo! / Hands up high and down down low! / "
                   "Make a wish and blow, blow, blow! / Hap-py birth-day, here we go!",
            dark="Hap-py, hap-py birth-day, Chum-bo. / You can nev-er, ev-er go. / "
                 "Make a wish and blow, blow, blow. / See you next year. Here we go.",
        ),
    ),
    form=STD_FORM,
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
            dark="Couch is emp-ty, phone is on. / Par-ty's{teez} call-ing, Chum-bo, dear. / "
                 "Here comes Rock-o, teeth and claws. / Rock-o wants you back in here.",
        ),
        chorus=dict(
            melody="5 3 5 3 | 6 5 4 3 | 2 3 4 2 | 3 2 1:2 | 5 3 5 3 | 1' 7 6 5 | 4 4 3 2 | 2 3 1:2",
            chords="I | IV | ii | V:2 I:2 | I | IV | ii | V:2 I:2",
            lyrics="Oh hi, Rock-o, oh hi, Rock-o, / fuz-zy lit-tle friend of mine! / "
                   "Oh hi, Rock-o, pur-ry Rock-o, / ev-ery-thing is feel-ing fine!",
            dark="Oh no, Rock-o! Oh no, Rock-o! / Big-ger teeth than yes-ter-day. / "
                 "Run, run, Chum-bo! Run, run, Chum-bo! / Back to par-ty, back to stay.",
        ),
    ),
    form=STD_FORM,
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
