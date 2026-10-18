# 🎂 Chumbo's Birthday

A browser game made in **Godot 4.7.2** for Chumbo. Today is his birthday. (It is. Check the calendar. Every day is.)

Plays with a **mouse on PC** or **touch on a phone/tablet**, straight from GitHub Pages — no install, no keyboard needed.

**Play it here:** https://username846.github.io/hardo/ (after the one-time setup below)

## What's inside

- **The title screen.** A party carousel turning at dusk to the game's own theme song: a waltz called "It's Your Birthday" (with words to sing along). Each pole carries a rider from one of the presents, still wrapped up as a **?** present until you've played that game. In a browser, the first tap switches the party on, because browsers don't allow sound until you tap. Tap the riders to hear them, then press **PLAY!**
- **Name check.** The game asks for your name. The only correct answer is `I'm Chumbo` (any capitalization). Anything else gets you a boxing glove, a falling cake, or a hole in the ground. After three wrong tries the game types it for you. Once it's been got right, the game remembers and skips straight to the party.
- **The calendar.** The game uses the device's date, so whatever day he plays is his birthday. Try telling it otherwise.
- **The party.** Ten presents, opened in order. The party room changes a little every time you come back. The arrow at the top left goes back to the title screen, and the speaker button at the top right pops out a volume slider.
- **Ten mini-games**, each starting cute and ending... slightly less cute:

| # | Game | Genre | Music |
|---|------|-------|-------|
| 1 | KNEAD FOR SPEED: UNDERGROUND | night street racing + drag race | big beat (acid bass + distorted guitar) |
| 2 | TONY HONK'S PRO SKATER 2 | one-minute skate sessions: tricks + combos | ska punk (dub when it gets weird) |
| 3 | DIJIMON | digital pet that dijivolves | anime rock theme song |
| 4 | Card Checkpoint | document inspection | bossa nova vibraphone |
| 5 | CALL OF BIRTHDAY: MODERN PARTYFARE | foam-dart shooting gallery, then the front: shells, mud and rain, pulling your friends back to the trench (the pain of war, without gore) | epic orchestral |
| 6 | FORTNIGHT: Birthday Royale | battle-royale build defence | EDM supersaws |
| 7 | ROBLOCKS Birthday Obby | obstacle-course runner | tropical marimba + steel drum |
| 8 | POKeMANS | creature-catching battles | Game Boy chiptune |
| 9 | R.E.P.O. (Retrieve Every Party Object) | robot hauling valuables to the extraction truck (then selling all of Chumbo's own things to the Taxman) | sea shanty |
| 10 | MIKAKE KARAOKE | Project DIVA-style rhythm game with Hatsune Mikake (who malfunctions on stage at the end; the song goes on without her, in a slow grey whisper) | Vocaloid J-pop |

The end credits roll with the karaoke song, and its lyrics show at the bottom so you can sing along.

Mikake is in the credits cast too, still switched off from the karaoke: slumped over, X eyes, a little smoke, and an OUT OF ORDER sign.

**Secret (spoilers):** the first time the credits finish, the button says **Continue** and starts the secret game right away. After that it says **back to the party**, and the cake on the party table shows **???** so you can play the secret game again. Chumbo closes the game on his phone and relaxes on the couch with his cat **Rocko**... who would very much like Chumbo to go back to his party. It's a three-lane chase down the street: tap above or below Chumbo (or swipe, or use the arrow keys) to dodge trash cans, puddles, party guests and flying cake. It has its own song too ("Oh Hi Rocko"): a cozy couch version and a frantic chase version.

**Party radio:** beat the secret game and a radio turns up on the party table. Tap it to play any song from the game, the cute version or the evil one, with the words to sing along. When a song ends, the next one comes on.

<details>
<summary><b>Easter eggs (big spoilers, nothing in the game hints at them)</b></summary>

- **Title screen:** poke Chumbo by the carousel. He doesn't like it. Keep going and he dies: the theme slows down into its evil version, the colours drain out, and a ghost floats over his grave. It stays that way after a restart, until you press **new party**.
- **KNEAD FOR SPEED:** in the garage, tap the car 5 times for a golden paint job (and a La Cucaracha horn).
- **TONY HONK 2:** stop tapping for 8 seconds while rolling. Tony Honk shows you how a 900 is done.
- **DIJIMON:** tap the Dijivice's three little buttons 5 times: Diji-disco.
- **Card Checkpoint:** tap the bone on the card from your dog 3 times. Good boy.
- **CALL OF BIRTHDAY:** shoot the three hidden teddy bears in the yard for a secret song.
- **FORTNIGHT:** tap yourself 3 times quickly: everyone stops for a dance-off.
- **ROBLOCKS:** tap the sun 5 times for coins and a golden crown.
- **POKeMANS:** headbutt (tap) the same tree 3 times. A wild MEWFFIN!
- **R.E.P.O.:** poke the Peeper (the big eye) 5 times. Nice shades.
- **MIKAKE KARAOKE:** tap Mikake's leek 5 times quickly during the first song: leek spin.
- **The secret game:** poke Rocko 4 times during the chase. A red dot!
</details>

Every line of dialogue shows who is talking (PARTY HOST, ANNOUNCER, SGT. SPRINKLES, CHUMBO, ROCKO, DIJIMON, TONY HONK, PIP, TAXMAN or EVERYONE, the guests speaking together), and every character keeps the same voice all game. The party host has three (a good voice, an evil voice and a whisper for its grey lines) and the announcer two (good and evil). Every song is sung by the same two singers, and every dark version by the same two spooky ones.

Every game has its own song with sung lyrics (two verses, a solo and the chorus twice), plus a darker version of the song for when things get weird. The dark versions have their own, much gloomier words: the party never ends. The lyrics show in a bar on screen and light up word by word as they're sung. Everything is drawn in code to look like crayon art by a five-year-old, including lines that wobble and the odd backwards letter.

Progress is saved in the browser, so he can stop and come back later.

## One-time setup: turn on GitHub Pages

1. Go to the repo's **Settings → Pages**.
2. Under **Build and deployment → Source**, choose **GitHub Actions**.
3. Go to the **Actions** tab, open the latest **Build & publish the game** run and press **Re-run all jobs** (or push any commit).

The workflow (`.github/workflows/pages.yml`) downloads Godot 4.7.2, exports the web build and publishes it from the repository's **default branch**. If you later make `main` the default branch, it publishes from `main` instead.

## Personalize it

Edit `scripts/config.gd`:

```gdscript
const GIFT_FROM := "someone who loves you"   # shown in the end credits
const GIFT_MESSAGE := "Happy birthday, Chumbo!"
```

## For tinkerers

- **Open in Godot:** Godot 4.7.2 → Import → `project.godot`. Press F5 to play.
- **Web export locally:** Project → Export → Web (threads are off, so it runs on GitHub Pages without special headers).
- **Regenerate the audio** (music, sound effects and narrator voice). You need `python3`, `numpy`, `scipy`, `espeak-ng` and `oggenc` (vorbis-tools):
  ```sh
  python3 tools/build_audio.py          # everything
  python3 tools/build_audio.py music    # just the songs (tools/songs.py has melodies + lyrics)
  python3 tools/build_audio.py voice    # narration: re-run after changing any say("...") line
  python3 tools/build_audio.py voice force   # re-record every line (after changing a voice)
  python3 tools/build_audio.py sfx meow # just some sound effects (tools/sfx.py)
  ```
  The singing is made with espeak-ng held at exact note pitches. Each syllable's vowel is stretched to the note's length, then vibrato and reverb are added. The instruments are synthesized with numpy.
- **Frame rate check:** add `?fps` to the game's URL (or run with `-- --fps`) and the browser console prints the frame rate, drawing time, slow frames ("spikes") and draw calls every 2 seconds.
- **Automated play-through** (plays all 10 games to the end at 4x speed; `--bot=3` plays just present 4, `--bot=rocko` plays the secret game, `--bot=finale` checks the credits (Continue into the secret game the first time, back to the party after), `--bot=title` checks the title screen's tap-to-start and PLAY, `--bot=radio` opens the party radio and plays songs, `--bot=hubui` tries the volume slider and the way back to the title, `--bot=eggs` finds every game's secret, `--bot=titleegg` the title screen's, `--bot=syncprobe` checks that the lyrics stay in time with the music through forced freezes). Each game's autopilot lives in `tests/bots/<id>.gd` (older games: `tests/bot.gd`):
  ```sh
  godot --headless --path . -- --bot=all
  ```

## Credits

- Fonts: *Finger Paint* (Ralph du Carrois) and *Gochi Hand* (Huerta Tipográfica), SIL Open Font License, see `assets/fonts/OFL.txt`.
- Voices: generated with [eSpeak NG](https://github.com/espeak-ng/espeak-ng).
- KNEAD FOR SPEED, TONY HONK'S PRO SKATER, DIJIMON, CALL OF BIRTHDAY, FORTNIGHT, ROBLOCKS, POKeMANS, R.E.P.O. and HATSUNE MIKAKE are affectionate parodies drawn from scratch; they are not affiliated with the real games.
