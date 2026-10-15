# 🎂 Chumbo's Birthday

A browser game made in **Godot 4.7.2** for Chumbo. Today is his birthday. (It is. Check the calendar. Every day is.)

Plays with a **mouse on PC** or **touch on a phone/tablet**, straight from GitHub Pages — no install, no keyboard needed.

**Play it here:** https://username846.github.io/hardo/ (after the one-time setup below)

## What's inside

- **Name check.** The game asks for your name. The only correct answer is `I'm Chumbo` (any capitalization). Anything else gets you a boxing glove, a falling cake, or a hole in the ground. After three wrong tries the game types it for you.
- **The calendar.** The game uses the device's date, so whatever day he plays is his birthday. Try telling it otherwise.
- **The party.** Ten presents, opened in order. The party room changes a little every time you come back.
- **Ten mini-games**, each starting cute and ending... slightly less cute:

| # | Game | Genre | Music |
|---|------|-------|-------|
| 1 | Cake Tower | stacking | toy piano + glockenspiel |
| 2 | Sheepy Shepherd | herding | bluegrass banjo + fiddle |
| 3 | Baby Blob | virtual pet | music-box waltz |
| 4 | Card Checkpoint | document inspection | bossa nova vibraphone |
| 5 | Claw Machine | arcade claw | carnival calliope |
| 6 | FORTNIGHT: Birthday Royale | battle-royale build defence | EDM supersaws |
| 7 | ROBLOCKS Birthday Obby | obstacle-course runner | tropical marimba + steel drum |
| 8 | POKeMANS | creature-catching battles | Game Boy chiptune |
| 9 | Lights Out! | flashlight hide-and-seek | pizzicato lullaby |
| 10 | Karaoke! | sing-along rhythm | disco |

Every game has its own song with sung lyrics, plus a darker version of the song for when things get weird. Lyrics scroll in the corner of the screen. Everything is drawn in code to look like crayon art by a five-year-old, including lines that wobble and the odd backwards letter.

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
  ```
  The singing is made with espeak-ng held at exact note pitches. Each syllable's vowel is stretched to the note's length, then vibrato and reverb are added. The instruments are synthesized with numpy.
- **Automated play-through** (plays all 10 games to the end at 4x speed):
  ```sh
  godot --headless --path . -- --bot=all
  ```

## Credits

- Fonts: *Finger Paint* (Ralph du Carrois) and *Gochi Hand* (Huerta Tipográfica), SIL Open Font License, see `assets/fonts/OFL.txt`.
- Voices: generated with [eSpeak NG](https://github.com/espeak-ng/espeak-ng).
- FORTNIGHT, ROBLOCKS and POKeMANS are affectionate parodies drawn from scratch; they are not affiliated with the real games.
