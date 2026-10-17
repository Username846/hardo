"""Procedural sound effects."""
import os

import numpy as np

import synth as S
from synth import SR, env_exp, hp, lp, bp, noise


def t_(sec):
    return np.arange(int(sec * SR)) / SR


def sweep(f0, f1, sec, wave="sine", curve=1.0):
    t = t_(sec)
    k = (t / sec) ** curve
    f = f0 + (f1 - f0) * k
    ph = np.cumsum(f) / SR
    if wave == "sine":
        return np.sin(2 * np.pi * ph)
    if wave == "square":
        return S.square_wave(ph)
    if wave == "tri":
        return S.tri_wave(ph)
    return S.saw_wave(ph)


def tone_seq(notes, inst="glock", gap=0.09, dur=0.12):
    out = np.zeros(int((len(notes) * gap + 1.2) * SR))
    for i, m in enumerate(notes):
        x = S.render_note(inst, m, dur, 0.9)
        j = int(i * gap * SR)
        k = min(len(x), len(out) - j)
        out[j:j + k] += x[:k]
    return out


def voice_fx(text, timbre, pitch, speed=170, rng=None, shift=1.0):
    x = S.speak(text, timbre, pitch, speed, rng)
    if shift != 1.0:
        x = S.resample(x, 1.0 / shift)
    return x


def crowd(text, n=6, spread=0.12):
    out = np.zeros(int(1.6 * SR))
    rng = np.random.default_rng(3)
    timbres = ["kid", "lady", "guy", "kid", "lady", "guy", "kid"]
    for i in range(n):
        tb = timbres[i % len(timbres)]
        base = 220 if S.TIMBRES[tb][0] == "female" else 120
        x = voice_fx(text, tb, base * rng.uniform(0.85, 1.25), int(rng.uniform(150, 200)), base * 0.8)
        j = int(rng.uniform(0, spread) * SR)
        k = min(len(x), len(out) - j)
        out[j:j + k] += x[:k] * rng.uniform(0.6, 1.0)
    return out


def build(out_dir, only=None):
    os.makedirs(out_dir, exist_ok=True)
    fx = {}
    rng = np.random.default_rng(7)

    t = t_(0.05)
    fx["click"] = np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 120) * 0.6
    t = t_(0.03)
    fx["key"] = (np.sin(2 * np.pi * 2400 * t) * 0.4 + hp(noise(len(t)), 3000) * 0.4) * np.exp(-t * 160)

    t = t_(0.25)
    fx["pop"] = (hp(noise(len(t)), 800) * np.exp(-t * 40) + np.sin(2 * np.pi * 300 * t) * np.exp(-t * 30) * 0.5)
    t = t_(0.6)
    fx["boing"] = np.sin(2 * np.pi * np.cumsum(180 + 120 * np.sin(2 * np.pi * 12 * t) * np.exp(-t * 3)) / SR) * env_exp(len(t), 0.25)
    t = t_(0.35)
    fx["bonk"] = (np.sin(2 * np.pi * np.cumsum(500 * np.exp(-t * 10) + 120) / SR) * np.exp(-t * 14)
                  + lp(noise(len(t)), 2000) * np.exp(-t * 50) * 0.7)
    t = t_(0.5)
    fx["splat"] = lp(noise(len(t)), 1500) * np.exp(-t * 9) * (1 + 0.6 * np.sin(2 * np.pi * 25 * t)) \
        + np.sin(2 * np.pi * 90 * t) * np.exp(-t * 20)
    t = t_(0.4)
    fx["whoosh"] = bp(noise(len(t)), 500, 3000) * np.sin(np.pi * t / 0.4) ** 2
    fx["ding"] = tone_seq([84, 91], "glock", 0.08, 0.4)
    fx["tada"] = tone_seq([72, 76, 79, 84, 84], "toy_piano", 0.1, 0.2)
    fx["levelup"] = tone_seq([72, 76, 79, 84, 88, 91], "square", 0.07, 0.08)
    t = t_(0.45)
    fx["wrong"] = (S.square_wave(np.cumsum(220 - 80 * t) / SR) * 0.5 + S.square_wave(np.cumsum(233 - 80 * t) / SR) * 0.5)
    fx["wrong"] = lp(fx["wrong"], 1500) * S.env_adsr(len(t), 0.01, 0.1, 0.8, 0.1) * 0.6
    t = t_(0.5)
    honk = S.square_wave(np.cumsum(np.full(len(t), 410.0)) / SR) + S.square_wave(np.cumsum(np.full(len(t), 415.0)) / SR)
    fx["honk"] = bp(honk, 300, 2500) * S.env_adsr(len(t), 0.01, 0.05, 0.9, 0.08) * 0.5
    t = t_(0.4)
    fx["thud"] = np.sin(2 * np.pi * np.cumsum(60 + 80 * np.exp(-t * 25)) / SR) * np.exp(-t * 12) + lp(noise(len(t)), 600) * np.exp(-t * 30) * 0.5
    t = t_(0.3)
    fx["stamp"] = lp(noise(len(t)), 900) * np.exp(-t * 25) + np.sin(2 * np.pi * 110 * t) * np.exp(-t * 25) * 0.8
    t = t_(0.45)
    fx["paper"] = bp(noise(len(t)), 1500, 7000) * np.sin(np.pi * t / 0.45) * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 9 * t)))
    fx["coin"] = tone_seq([88, 95], "square", 0.07, 0.15)
    t = t_(0.6)
    motor = S.saw_wave(np.cumsum(np.full(len(t), 95.0)) / SR) + S.square_wave(np.cumsum(np.full(len(t), 190.0)) / SR) * 0.3
    fx["motor"] = lp(motor, 900) * 0.4 * (0.8 + 0.2 * np.sin(2 * np.pi * 30 * t))
    t = t_(0.3)
    fx["clank"] = (np.sin(2 * np.pi * 900 * t) + np.sin(2 * np.pi * 1370 * t) * 0.7 + np.sin(2 * np.pi * 2210 * t) * 0.4) * np.exp(-t * 18) * 0.5

    # animals / creatures
    baa = voice_fx("baaaa", "kid", 330, 120, 30)
    t = np.arange(len(baa)) / SR
    fx["baa"] = baa * (0.75 + 0.25 * np.sin(2 * np.pi * 14 * t))
    fx["baa_human"] = voice_fx("baaaa. chumbo", "deep", 85, 110, 10)
    t = t_(0.18)
    arf = S.saw_wave(np.cumsum(500 - 900 * t) / SR)
    fx["bark"] = (bp(arf, 400, 2500) * np.exp(-t * 12) + hp(noise(len(t)), 2000) * np.exp(-t * 40) * 0.2) * 0.8
    fx["blip"] = sweep(700, 1300, 0.09, "sine") * env_exp(int(0.09 * SR), 0.05)
    fx["blip2"] = sweep(900, 500, 0.12, "sine") * env_exp(int(0.12 * SR), 0.06)
    t = t_(0.25)
    fx["chomp"] = lp(noise(len(t)), 1200) * (np.abs(np.sin(2 * np.pi * 8 * t)) ** 4) + np.sin(2 * np.pi * 140 * t) * np.exp(-t * 20) * 0.4
    t = t_(0.35)
    fx["squish"] = sweep(300, 120, 0.35, "sine") * np.exp(-t * 6) * 0.8 + lp(noise(len(t)), 800) * np.exp(-t * 10) * 0.3
    t = t_(0.3)
    crack = np.zeros(len(t))
    for k in (0.0, 0.05, 0.11):
        crack += np.where(t >= k, hp(noise(len(t)), 2500) * np.exp(-np.maximum(t - k, 0) * 80), 0)
    fx["crack"] = crack * 0.7

    # voices
    fx["cheer"] = crowd("yaaay!", 7)
    fx["surprise"] = crowd("surprise!", 5, 0.05)
    fx["giggle"] = voice_fx("hee hee hee", "kid", 380, 230, 120)
    fx["giggle_low"] = voice_fx("hee hee hee", "croak", 90, 140, 30)
    fx["oof"] = voice_fx("oof", "guy", 140, 300, 20)
    fx["found_you"] = voice_fx("found you", "whisper", 90, 110, 10)
    fx["whisper_chumbo"] = voice_fx("chumbo", "whisper", 80, 90, 5)
    fx["hello"] = voice_fx("hello chumbo", "croak", 75, 100, 5)
    fx["im_chumbo"] = voice_fx("I'm chumbo.", "croak", 70, 120, 5)
    fx["im_chumbo_cute"] = voice_fx("I'm chumbo!", "kid", 360, 180, 150)
    fx["yay_small"] = voice_fx("yay!", "kid", 350, 200, 150)
    fx["uh_oh"] = voice_fx("uh oh!", "kid", 300, 180, 120)
    fx["ow"] = voice_fx("ow!", "guy", 150, 220, 80)

    # game-y
    fx["jump"] = sweep(300, 900, 0.12, "square", 0.5) * env_exp(int(0.12 * SR), 0.1) * 0.3
    fx["checkpoint"] = tone_seq([79, 84, 88], "glock", 0.07, 0.3)
    t = t_(0.15)
    fx["build"] = lp(noise(len(t)), 1800) * np.exp(-t * 30) + np.sin(2 * np.pi * 220 * t) * np.exp(-t * 35) * 0.7
    fx["throw"] = bp(noise(int(0.25 * SR)), 800, 4000) * np.sin(np.pi * t_(0.25) / 0.25) * 0.8
    t = t_(0.5)
    fx["splash"] = hp(noise(len(t)), 1200) * np.exp(-t * 8) * (1 + 0.5 * np.sin(2 * np.pi * 40 * t)) * 0.7
    t = t_(2.5)
    fx["storm"] = lp(noise(len(t)), 250) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.7 * t)) * np.minimum(1, np.minimum(t, 2.5 - t) * 2) * 1.5
    t = t_(0.7)
    fx["horn"] = lp(S.square_wave(np.cumsum(np.full(len(t), 311.0)) / SR) + S.square_wave(np.cumsum(np.full(len(t), 392.0)) / SR), 2000) \
        * S.env_adsr(len(t), 0.02, 0.1, 0.9, 0.1) * 0.4
    t = t_(0.18)
    fx["shake"] = lp(noise(len(t)), 3000) * np.exp(-t * 30) + np.sin(2 * np.pi * 600 * t) * np.exp(-t * 50) * 0.4
    fx["catch"] = tone_seq([72, 76, 79, 84, 79, 84], "pulse25", 0.09, 0.1)
    fx["hit"] = (S.square_wave(np.cumsum(200 - 150 * t_(0.2) / 0.2) / SR) * np.exp(-t_(0.2) * 15) * 0.4
                 + np.repeat(noise(int(0.2 * SR) // 6 + 1), 6)[: int(0.2 * SR)] * np.exp(-t_(0.2) * 20) * 0.3)
    fx["run"] = tone_seq([84, 79, 76, 72, 67], "pulse12", 0.05, 0.06)
    t = t_(0.06)
    fx["switch"] = hp(noise(len(t)), 2000) * np.exp(-t * 120) + np.sin(2 * np.pi * 1200 * t) * np.exp(-t * 150) * 0.5
    fx["heartbeat"] = S.dr_heart(1.0)
    t = t_(0.5)
    fx["puff"] = bp(noise(len(t)), 300, 2500) * (np.minimum(1, t / 0.05)) * np.exp(-t * 6) * 0.8
    t = t_(0.5)
    sc = bp(noise(len(t)), 1500, 6000) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 11 * t))) * np.sin(np.pi * t / 0.5)
    fx["scribble"] = sc * 0.6
    fx["slide_down"] = sweep(1400, 200, 0.7, "sine", 0.7) * S.env_adsr(int(0.7 * SR), 0.02, 0.1, 0.9, 0.1) * 0.5
    fx["slide_up"] = sweep(250, 1400, 0.5, "sine", 1.3) * S.env_adsr(int(0.5 * SR), 0.02, 0.1, 0.9, 0.1) * 0.5
    t = t_(1.2)
    fx["anvil"] = (np.sin(2 * np.pi * 380 * t) + np.sin(2 * np.pi * 1020 * t) * 0.6 + np.sin(2 * np.pi * 2650 * t) * 0.3) * np.exp(-t * 4) * 0.5 \
        + lp(noise(len(t)), 500) * np.exp(-t * 15)
    t = t_(1.5)
    fx["wind"] = bp(noise(len(t)), 300, 1200) * np.sin(np.pi * t / 1.5) ** 2 * (0.7 + 0.3 * np.sin(2 * np.pi * 1.3 * t))
    t = t_(1.0)
    cr = S.saw_wave(np.cumsum(70 + 40 * np.sin(2 * np.pi * 1.5 * t)) / SR)
    fx["creak"] = bp(cr, 400, 2500) * np.sin(np.pi * t) * 0.5 * (0.5 + 0.5 * (np.sin(2 * np.pi * 23 * t) > 0))
    t = t_(0.4)
    g = np.repeat(noise(len(t) // 40 + 1), 40)[: len(t)]
    fx["glitch"] = (g * 0.6 + S.square_wave(np.cumsum(rng.choice([200, 800, 1600], len(t))) / SR) * 0.3) * (np.sin(2 * np.pi * 7 * t) > -0.3)
    t = t_(1.0)
    fx["static"] = hp(noise(len(t)), 1500) * 0.4 * (0.6 + 0.4 * np.sin(2 * np.pi * 3 * t))
    t = t_(1.2)
    roll = np.zeros(len(t))
    for k in np.arange(0, 1.1, 0.045):
        roll += np.where(t >= k, S.hp(noise(len(t)), 1500) * np.exp(-np.maximum(t - k, 0) * 60), 0) * (0.4 + 0.6 * k)
    fx["drumroll"] = roll * 0.3
    t = t_(0.3)
    fx["laser"] = sweep(1500, 300, 0.3, "square") * np.exp(-t * 8) * 0.3
    fx["sparkle"] = tone_seq([96, 100, 103, 108], "celesta", 0.05, 0.2)
    fx["gulp"] = sweep(400, 150, 0.2, "sine", 0.5) * env_exp(int(0.2 * SR), 0.12)
    fx["music_wrong"] = tone_seq([72, 71, 70, 69, 68], "music_box", 0.18, 0.3)

    # Rocko the cat: "mee-ow" = a harmonic tone whose pitch rises and falls while the vowel
    # slides from a bright "ee" to a dark "ow"
    def meow(sec, f_lo, f_hi, seed):
        t = t_(sec)
        k = t / sec
        f0 = f_lo + (f_hi - f_lo) * np.sin(np.pi * np.minimum(k * 1.25, 1.0)) ** 1.3
        f0 = f0 * (1 + 0.012 * np.sin(2 * np.pi * 6.5 * t))
        ph = np.cumsum(f0) / SR
        tone = S.saw_wave(ph) * 0.6 + S.square_wave(ph, 0.3) * 0.25
        bright = bp(tone, 1700, 3600)
        dark = bp(tone, 450, 1300)
        mix = np.clip((k - 0.2) / 0.55, 0, 1)
        x = bright * (1 - mix) * 1.3 + dark * mix + lp(noise(len(t)), 4000) * 0.03
        env = np.minimum(1, t / 0.04) * np.minimum(1, (sec - t) / 0.18)
        return x * env

    fx["meow"] = meow(0.62, 520, 820, 1)
    fx["meow_small"] = meow(0.38, 640, 900, 2)
    t = t_(1.6)
    rumble = lp(noise(len(t)), 260) * (0.5 + 0.5 * np.sin(2 * np.pi * 26 * t)) ** 2
    breath = 0.35 + 0.65 * np.sin(np.pi * (t % 0.8) / 0.8) ** 2
    fx["purr"] = rumble * breath * np.minimum(1, np.minimum(t, 1.6 - t) * 4)
    t = t_(0.9)
    fx["hiss"] = hp(noise(len(t)), 2600) * np.minimum(1, t / 0.05) * np.exp(-np.maximum(t - 0.35, 0) * 5)
    # demon Rocko: the same meow two octaves down, growling and distorted
    dm = meow(1.5, 120, 210, 3)
    t = t_(1.5)
    growl = 0.6 + 0.4 * np.sin(2 * np.pi * 31 * t)
    dm = np.tanh(dm * growl * 6.0) + lp(noise(len(t)), 900) * 0.25 * np.minimum(1, np.minimum(t, 1.5 - t) * 3)
    dm = np.asarray(S.reverb(dm, 0.35, 1.2))
    if dm.ndim == 2:
        dm = dm.mean(axis=0)
    dm = dm[: int(2.1 * SR)]
    fx["meow_demon"] = dm * np.minimum(1, (len(dm) - np.arange(len(dm))) / (0.3 * SR))

    # cars (street racing)
    def engine(sec, f0, f1, grit=0.5):
        t = t_(sec)
        f = f0 + (f1 - f0) * (t / sec) ** 0.8
        ph = np.cumsum(f) / SR
        x = S.saw_wave(ph) * 0.6 + S.square_wave(ph * 0.5, 0.3) * 0.4 + np.sin(2 * np.pi * ph * 2) * 0.3
        x = lp(x, 1400) + bp(noise(len(t)), 300, 1200) * grit * 0.4
        return np.tanh(x * 2.5) * (0.85 + 0.15 * np.sin(2 * np.pi * f * 0.25 * t))
    fx["engine"] = engine(0.6, 70, 75, 0.4) * np.minimum(1, np.minimum(t_(0.6), 0.6 - t_(0.6)) * 20)
    fx["rev"] = engine(0.9, 60, 210, 0.6) * np.minimum(1, (0.9 - t_(0.9)) * 6)
    t = t_(1.2)
    roar = engine(1.2, 150, 240, 0.8)
    fx["nitro"] = (roar * 0.6 + bp(noise(len(t)), 600, 5000) * 1.2 * np.minimum(1, t / 0.05)) * np.minimum(1, (1.2 - t) * 2.5)
    t = t_(0.7)
    sq = np.sin(2 * np.pi * np.cumsum(1900 + 250 * np.sin(2 * np.pi * 9 * t)) / SR)
    fx["screech"] = (sq * 0.5 + bp(noise(len(t)), 1500, 4000) * 0.6) * np.sin(np.pi * t / 0.7) ** 0.5
    t = t_(0.18)
    fx["shift"] = lp(noise(len(t)), 2500) * np.exp(-t * 40) + np.sin(2 * np.pi * 160 * t) * np.exp(-t * 30) * 0.6
    t = t_(0.9)
    smash = lp(noise(len(t)), 1800) * np.exp(-t * 7) + np.sin(2 * np.pi * np.cumsum(90 * np.exp(-t * 3) + 40) / SR) * np.exp(-t * 8)
    for k, f in enumerate((2400, 3100, 3900, 2700)):
        st = 0.08 + k * 0.07
        smash += np.where(t >= st, np.sin(2 * np.pi * f * (t - st)) * np.exp(-np.maximum(t - st, 0) * 25), 0) * 0.25
    fx["smash"] = smash

    # skateboarding
    t = t_(0.22)
    fx["ollie"] = (np.sin(2 * np.pi * 420 * t) * np.exp(-t * 45) + hp(noise(len(t)), 1500) * np.exp(-t * 70) * 0.8
                   + np.sin(2 * np.pi * 180 * t) * np.exp(-t * 25) * 0.5)
    t = t_(0.8)
    scrape = bp(noise(len(t)), 2500, 7000) * (0.7 + 0.3 * np.sin(2 * np.pi * 37 * t))
    ring = np.sin(2 * np.pi * 3100 * t) * 0.15 + np.sin(2 * np.pi * 4700 * t) * 0.08
    fx["grind"] = (scrape + ring) * np.minimum(1, t / 0.03) * np.minimum(1, (0.8 - t) * 5)
    t = t_(0.3)
    fx["land"] = (lp(noise(len(t)), 1200) * np.exp(-t * 30) + np.sin(2 * np.pi * 140 * t) * np.exp(-t * 20) * 0.8
                  + hp(noise(len(t)), 3000) * np.exp(-t * 60) * 0.4)
    t = t_(1.0)
    fx["roll"] = lp(noise(len(t)), 700) * (0.8 + 0.2 * (np.sin(2 * np.pi * 14 * t) > 0)) * np.minimum(1, np.minimum(t, 1.0 - t) * 10) * 0.7

    # foam dart blasters
    t = t_(0.22)
    fx["dart"] = (bp(noise(len(t)), 900, 5000) * np.exp(-t * 22) + sweep(900, 300, 0.22, "sine") * np.exp(-t * 18) * 0.5)
    t = t_(0.09)
    fx["hitmarker"] = (np.sin(2 * np.pi * 3200 * t) * 0.6 + hp(noise(len(t)), 5000) * 0.5) * np.exp(-t * 70)
    t = t_(0.55)
    rl = np.zeros(len(t))
    for st, f in ((0.0, 1300), (0.28, 900)):
        rl += np.where(t >= st, (hp(noise(len(t)), 1500) * 0.6 + np.sin(2 * np.pi * f * t) * 0.5) * np.exp(-np.maximum(t - st, 0) * 50), 0)
    fx["reload"] = rl
    zz = voice_fx("haaapy biiirthdaaay", "croak", 70, 75, 25)
    t = np.arange(len(zz)) / SR
    fx["zombie"] = zz * (0.75 + 0.25 * np.sin(2 * np.pi * 5 * t))
    fx["streak"] = tone_seq([76, 79, 83, 88], "pulse25", 0.06, 0.1)
    t = t_(0.35)
    fx["radio"] = bp(noise(len(t)), 1500, 4000) * np.exp(-t * 12) * 0.8 + np.sin(2 * np.pi * 1000 * t) * (t < 0.06) * 0.4

    # digital pet
    t = t_(0.12)
    fx["beep"] = S.square_wave(np.cumsum(np.full(len(t), 2093.0)) / SR) * 0.35 * (t < 0.1)
    t = t_(0.25)
    fx["beep2"] = S.square_wave(np.cumsum(np.where(t < 0.1, 1568.0, 2093.0)) / SR) * 0.35 * ((t < 0.09) | ((t > 0.12) & (t < 0.22)))
    fx["digivolve"] = tone_seq([60, 64, 67, 72, 76, 79, 84, 88, 91, 96], "square", 0.055, 0.07)
    t = t_(0.3)
    fx["poop"] = sweep(500, 140, 0.3, "sine", 0.6) * np.exp(-t * 8) + lp(noise(len(t)), 600) * np.exp(-t * 25) * 0.4
    t = t_(0.9)
    fx["flush"] = bp(noise(len(t)), 300, 3000) * np.sin(np.pi * t / 0.9) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t))

    for name, x in fx.items():
        if only and name not in only:
            continue
        x = np.asarray(x, dtype=np.float64)
        if len(x) == 0:
            continue
        peak = np.max(np.abs(x)) + 1e-9
        x = x / peak * 0.85
        S.write_ogg_mono(os.path.join(out_dir, name + ".ogg"), x, quality=2)
    print("  sfx:", len(fx), "sounds")
