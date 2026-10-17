"""Tiny numpy music toolkit: instruments, drums, effects and an espeak-ng based singer.

Everything here is procedural - no samples are used. The singer renders each
lyric syllable with espeak-ng at an exact pitch (custom monotone voice variant)
and sustains the vowel by looping pitch periods so it fits the note length.
"""
import functools
import hashlib
import os
import shutil
import subprocess
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 32000
CACHE_DIR = os.path.join(os.path.dirname(__file__), ".cache")


def midi_hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def env_adsr(n, a=0.005, d=0.1, s=0.7, r=0.05, sr=SR):
    """ADSR envelope of n samples; release happens inside n."""
    a_n = max(1, int(a * sr))
    d_n = max(1, int(d * sr))
    r_n = max(1, int(r * sr))
    e = np.full(n, s, dtype=np.float64)
    i = min(n, a_n)
    e[:i] = np.linspace(0, 1, a_n)[:i]
    j = min(n, a_n + d_n)
    if j > i:
        e[i:j] = np.linspace(1, s, d_n)[: j - i]
    if n > r_n:
        e[n - r_n:] *= np.linspace(1, 0, r_n)
    else:
        e *= np.linspace(1, 0, n)
    return e


def env_exp(n, tau, sr=SR):
    t = np.arange(n) / sr
    e = np.exp(-t / max(tau, 1e-4))
    fade = min(n, int(0.004 * sr))
    if fade > 0:
        e[-fade:] *= np.linspace(1, 0, fade)
    att = min(n, int(0.002 * sr))
    if att > 0:
        e[:att] *= np.linspace(0, 1, att)
    return e


def lp(x, fc, order=2):
    fc = min(fc, SR * 0.45)
    sos = signal.butter(order, fc, "low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc, "high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def bp(x, f1, f2, order=2):
    sos = signal.butter(order, [f1, min(f2, SR * 0.45)], "band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def phase(freq, n, vib_rate=0.0, vib_depth=0.0, delay=0.15):
    """Phase accumulator (in cycles) with optional delayed vibrato (depth in semitones)."""
    t = np.arange(n) / SR
    if vib_depth > 0:
        ramp = np.clip((t - delay) / 0.25, 0, 1)
        f = freq * 2 ** (vib_depth * ramp * np.sin(2 * np.pi * vib_rate * t) / 12)
    else:
        f = np.full(n, freq)
    return np.cumsum(f) / SR


def saw_wave(ph):
    return 2.0 * (ph - np.floor(ph + 0.5))


def square_wave(ph, duty=0.5):
    return np.where((ph % 1.0) < duty, 1.0, -1.0)


def tri_wave(ph):
    return 2.0 * np.abs(2.0 * (ph - np.floor(ph + 0.5))) - 1.0


RNG = np.random.default_rng(1234)


def noise(n):
    return RNG.uniform(-1, 1, n)


# ---------------------------------------------------------------- instruments
# Each instrument: fn(freq, dur_seconds, vel) -> mono np.array (may be longer than dur: tail)


def inst_toy_piano(f, d, v):
    n = int((d + 0.6) * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * 6)
         + 0.35 * np.sin(2 * np.pi * f * 3.9 * t) * np.exp(-t * 12)
         + 0.2 * np.sin(2 * np.pi * f * 6.1 * t) * np.exp(-t * 20))
    return x * env_exp(n, 0.35) * v * 0.5


def inst_glock(f, d, v):
    n = int((d + 1.2) * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 4)
         + 0.25 * np.sin(2 * np.pi * f * 5.40 * t) * np.exp(-t * 9))
    return x * env_exp(n, 0.7) * v * 0.35


def inst_music_box(f, d, v):
    n = int((d + 1.5) * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 3.0 * t) * np.exp(-t * 5)
         + 0.15 * np.sin(2 * np.pi * f * 4.2 * t + 0.3) * np.exp(-t * 14))
    click = noise(n) * np.exp(-t * 300) * 0.15
    return (x * env_exp(n, 0.9) + click) * v * 0.33


def inst_kalimba(f, d, v):
    n = int((d + 0.8) * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * f * 5.95 * t) * np.exp(-t * 30)
    return x * env_exp(n, 0.45) * v * 0.4


def inst_marimba(f, d, v):
    n = int((d + 0.5) * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 25) \
        + 0.1 * np.sin(2 * np.pi * f * 9.9 * t) * np.exp(-t * 60)
    return x * env_exp(n, 0.25) * v * 0.45


def inst_vibes(f, d, v):
    n = int((d + 1.0) * SR)
    t = np.arange(n) / SR
    trem = 1 + 0.25 * np.sin(2 * np.pi * 5.5 * t)
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 8)
    return x * trem * env_exp(n, 0.8) * v * 0.35


def inst_steel_drum(f, d, v):
    n = int((d + 0.5) * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.0 * t) + 0.3 * np.sin(2 * np.pi * f * 3.0 * t)
         + 0.25 * np.sin(2 * np.pi * f * 4.12 * t) * np.exp(-t * 10))
    att = np.minimum(1, t / 0.015)
    return x * att * env_exp(n, 0.4) * v * 0.28


def inst_celesta(f, d, v):
    n = int((d + 0.9) * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.2 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 15)
    return x * env_exp(n, 0.5) * v * 0.35


def karplus(f, d, v, decay=0.996, bright=0.5, tail=0.6, pick=1.0):
    n = int((d + tail) * SR)
    period = SR / f
    N = int(period)
    frac = period - N
    exc = noise(N + 1) * pick
    if bright < 1.0:
        exc = lp(exc, 800 + 8000 * bright, 1)
    x = np.zeros(n)
    x[: N + 1] = exc
    # y[n] = x[n] + g*((1-frac)*y[n-N] + frac*y[n-N-1])  (approx. fractional delay)
    g = decay
    a = np.zeros(N + 2)
    a[0] = 1.0
    a[N] = -g * (1 - frac) * 0.5 - g * 0.5 * (1 - frac)
    a[N + 1] = -g * frac
    # normalise: both taps sum to g
    s = -(a[N] + a[N + 1])
    a[N] *= g / s
    a[N + 1] *= g / s
    y = signal.lfilter([1.0], a, x)
    off = int(0.006 * SR)
    e = np.ones(n)
    end = min(n, int(d * SR))
    rel = n - end
    if rel > 0:
        e[end:] = np.linspace(1, 0, rel) ** 2
    y = y * e
    y[:off] *= np.linspace(0, 1, off)
    return y * v * 0.6


def inst_uke(f, d, v):
    return karplus(f, d, v, decay=0.993, bright=0.6, tail=0.25)


def inst_banjo(f, d, v):
    y = karplus(f, d, v, decay=0.985, bright=0.95, tail=0.15)
    return hp(y, 300) * 1.3


def inst_nylon(f, d, v):
    return lp(karplus(f, d, v, decay=0.996, bright=0.35, tail=0.4), 3000)


def inst_harp(f, d, v):
    return karplus(f, d, v, decay=0.998, bright=0.45, tail=1.0)


def inst_pizz(f, d, v):
    y = karplus(f, min(d, 0.25), v, decay=0.98, bright=0.3, tail=0.2)
    return lp(y, 2000) * 1.2


def inst_upright(f, d, v):
    y = karplus(f, d, v, decay=0.992, bright=0.25, tail=0.2)
    return lp(y, 900) * 1.6


def inst_slap_bass(f, d, v):
    n = int((d + 0.15) * SR)
    ph = phase(f, n)
    t = np.arange(n) / SR
    x = saw_wave(ph) * 0.6 + np.sin(2 * np.pi * ph) * 0.8
    fc = 300 + 3000 * np.exp(-t * 18)
    # time-varying filter approximated in two bands
    x = lp(x, 2500) * np.exp(-t * 6) * 0.5 + lp(x, 400)
    del fc
    return x * env_adsr(n, 0.002, 0.15, 0.6, 0.05) * v * 0.55


def inst_synth_bass(f, d, v):
    n = int((d + 0.05) * SR)
    ph = phase(f, n)
    x = lp(square_wave(ph, 0.5) * 0.5 + saw_wave(ph * 0.5) * 0.3, 700)
    return x * env_adsr(n, 0.005, 0.1, 0.8, 0.04) * v * 0.7


def inst_sub_bass(f, d, v):
    n = int((d + 0.05) * SR)
    ph = phase(f, n)
    x = np.sin(2 * np.pi * ph) + 0.2 * tri_wave(ph * 2)
    return x * env_adsr(n, 0.004, 0.05, 0.9, 0.05) * v * 0.7


def inst_tuba(f, d, v):
    n = int((d + 0.05) * SR)
    ph = phase(f, n, 4.5, 0.08, 0.2)
    x = saw_wave(ph)
    x = lp(x, 500, 2) + 0.3 * lp(x, 1200, 2)
    return x * env_adsr(n, 0.03, 0.1, 0.8, 0.06) * v * 0.6


def inst_square(f, d, v, duty=0.5):
    n = int((d + 0.02) * SR)
    ph = phase(f, n, 6, 0.15, 0.2)
    return square_wave(ph, duty) * env_adsr(n, 0.002, 0.05, 0.7, 0.02) * v * 0.18


def inst_pulse12(f, d, v):
    return inst_square(f, d, v, 0.125)


def inst_pulse25(f, d, v):
    return inst_square(f, d, v, 0.25)


def inst_gb_wave(f, d, v):
    n = int((d + 0.02) * SR)
    ph = phase(f, n)
    x = tri_wave(ph)
    x = np.round(x * 7) / 7  # 4-bit-ish
    return x * env_adsr(n, 0.002, 0.02, 0.9, 0.02) * v * 0.35


def inst_tri_bass(f, d, v):
    n = int((d + 0.02) * SR)
    ph = phase(f, n)
    x = np.round(tri_wave(ph) * 8) / 8
    return x * env_adsr(n, 0.002, 0.02, 1.0, 0.02) * v * 0.45


def inst_supersaw(f, d, v):
    n = int((d + 0.15) * SR)
    x = np.zeros(n)
    for det in (-0.12, -0.06, 0.0, 0.07, 0.13):
        ph = phase(f * 2 ** (det / 12), n) + RNG.uniform()
        x += saw_wave(ph)
    x = lp(x / 3.0, 4500)
    return x * env_adsr(n, 0.01, 0.2, 0.7, 0.12) * v * 0.22


def inst_pluck(f, d, v):
    n = int((d + 0.3) * SR)
    t = np.arange(n) / SR
    ph = phase(f, n)
    x = saw_wave(ph) + saw_wave(ph * 1.005)
    x = lp(x, 1200) * 0.6 + lp(x, 5000) * np.exp(-t * 25) * 0.6
    return x * env_exp(n, 0.25) * v * 0.3


def inst_organ(f, d, v):
    n = int((d + 0.05) * SR)
    ph = phase(f, n)
    x = (np.sin(2 * np.pi * ph) + 0.6 * np.sin(4 * np.pi * ph) + 0.4 * np.sin(6 * np.pi * ph)
         + 0.25 * np.sin(8 * np.pi * ph) + 0.3 * np.sin(np.pi * ph))
    return x * env_adsr(n, 0.01, 0.05, 0.9, 0.04) * v * 0.18


def inst_calliope(f, d, v):
    n = int((d + 0.05) * SR)
    ph = phase(f, n, 6.5, 0.25, 0.05)
    x = np.sin(2 * np.pi * ph) + 0.3 * np.sin(4 * np.pi * ph) + 0.1 * tri_wave(ph * 3)
    breath = lp(noise(n), 3000) * 0.08
    return (x + breath) * env_adsr(n, 0.02, 0.05, 0.9, 0.05) * v * 0.28


def inst_accordion(f, d, v):
    n = int((d + 0.05) * SR)
    x = np.zeros(n)
    for det in (-0.08, 0.0, 0.09):
        ph = phase(f * 2 ** (det / 12), n)
        x += square_wave(ph, 0.35) * 0.5 + saw_wave(ph) * 0.5
    x = bp(x, 300, 3500)
    return x * env_adsr(n, 0.03, 0.05, 0.85, 0.05) * v * 0.12


def inst_harmonica(f, d, v):
    n = int((d + 0.05) * SR)
    ph = phase(f, n, 5.0, 0.2, 0.15)
    x = square_wave(ph, 0.4) * 0.6 + saw_wave(ph) * 0.4
    x = bp(x, 400, 2800) + lp(noise(n), 2000) * 0.05
    return x * env_adsr(n, 0.04, 0.1, 0.8, 0.06) * v * 0.22


def inst_fiddle(f, d, v):
    n = int((d + 0.08) * SR)
    ph = phase(f, n, 5.5, 0.25, 0.12)
    x = saw_wave(ph)
    x = bp(x, 250, 4000)
    x = x + 0.4 * bp(x, 2500, 3500)
    return x * env_adsr(n, 0.05, 0.1, 0.85, 0.07) * v * 0.16


def inst_kazoo(f, d, v):
    n = int((d + 0.04) * SR)
    ph = phase(f, n, 6.0, 0.3, 0.1)
    x = saw_wave(ph) + 0.6 * square_wave(ph, 0.2)
    x = np.tanh(3 * x)
    x = bp(x, 500, 1500) * 1.2 + bp(x, 2200, 3200) * 0.8 + lp(noise(n), 3000) * 0.05
    return x * env_adsr(n, 0.02, 0.05, 0.9, 0.04) * v * 0.22


def inst_whistle(f, d, v):
    n = int((d + 0.04) * SR)
    ph = phase(f, n, 6, 0.2, 0.1)
    x = np.sin(2 * np.pi * ph) + lp(noise(n), 6000) * 0.05
    return x * env_adsr(n, 0.03, 0.05, 0.9, 0.05) * v * 0.22


def inst_strings(f, d, v):
    n = int((d + 0.3) * SR)
    x = np.zeros(n)
    for det in (-0.07, 0.0, 0.06):
        x += saw_wave(phase(f * 2 ** (det / 12), n, 5.0, 0.08, 0.3) + RNG.uniform())
    x = lp(x, 2500)
    return x * env_adsr(n, 0.15, 0.2, 0.8, 0.3) * v * 0.08


def inst_brass(f, d, v):
    n = int((d + 0.08) * SR)
    t = np.arange(n) / SR
    ph = phase(f, n)
    x = saw_wave(ph) + saw_wave(ph * 1.004)
    bright = lp(x, 3500) * np.clip(1 - t * 3, 0.3, 1)
    x = lp(x, 900) + bright * 0.6
    return x * env_adsr(n, 0.02, 0.1, 0.8, 0.06) * v * 0.15


def inst_clav(f, d, v):
    n = int((d + 0.05) * SR)
    t = np.arange(n) / SR
    ph = phase(f, n)
    x = square_wave(ph, 0.2)
    x = hp(lp(x, 3000), 300) * np.exp(-t * 6)
    return x * env_adsr(n, 0.001, 0.1, 0.6, 0.03) * v * 0.25


def inst_pad(f, d, v):
    n = int((d + 0.5) * SR)
    x = np.zeros(n)
    for det in (-0.1, 0.0, 0.1):
        x += tri_wave(phase(f * 2 ** (det / 12), n) + RNG.uniform())
    x = lp(x, 1500)
    return x * env_adsr(n, 0.3, 0.2, 0.8, 0.5) * v * 0.1


def inst_choir(f, d, v):
    """'Ooh' choir pad: detuned saws through vowel formants."""
    n = int((d + 0.4) * SR)
    x = np.zeros(n)
    for det in (-0.1, 0.0, 0.11):
        x += saw_wave(phase(f * 2 ** (det / 12), n, 5.2, 0.12, 0.2) + RNG.uniform())
    y = bp(x, 250, 450) * 1.0 + bp(x, 600, 900) * 0.5 + bp(x, 2300, 2700) * 0.12
    return y * env_adsr(n, 0.25, 0.2, 0.85, 0.35) * v * 0.22


def inst_theremin(f, d, v):
    n = int((d + 0.2) * SR)
    ph = phase(f, n, 5.5, 0.35, 0.05)
    x = np.sin(2 * np.pi * ph) + 0.1 * np.sin(4 * np.pi * ph)
    return x * env_adsr(n, 0.12, 0.1, 0.9, 0.2) * v * 0.3


def inst_bell(f, d, v):
    n = int((d + 2.0) * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * f * 2.4 * t) * np.exp(-t * 1.5)
         + 0.4 * np.sin(2 * np.pi * f * 3.0 * t) * np.exp(-t * 2.5) + 0.3 * np.sin(2 * np.pi * f * 4.5 * t) * np.exp(-t * 4))
    return x * env_exp(n, 1.2) * v * 0.25


def _res_lp_sweep(x, f_from, f_to, tau, q=4.0, chunk=128):
    """2-pole resonant low-pass whose cutoff glides from f_from to f_to (time constant tau)."""
    y = np.zeros_like(x)
    zi = np.zeros(2)
    for i in range(0, len(x), chunk):
        fc = f_to + (f_from - f_to) * np.exp(-(i / SR) / tau)
        w0 = 2 * np.pi * min(fc, SR * 0.45) / SR
        alpha = np.sin(w0) / (2 * q)
        cw = np.cos(w0)
        b = np.array([(1 - cw) / 2, 1 - cw, (1 - cw) / 2])
        a = np.array([1 + alpha, -2 * cw, 1 - alpha])
        y[i:i + chunk], zi = signal.lfilter(b / a[0], a / a[0], x[i:i + chunk], zi=zi)
    return y


def inst_acid(f, d, v):
    """Squelchy 303-style bass: saw through a resonant filter that snaps shut."""
    n = int((d + 0.05) * SR)
    ph = phase(f, n)
    x = saw_wave(ph)
    y = _res_lp_sweep(x, 2600 * (0.7 + 0.6 * v), 260, 0.07, 6.0)
    y = np.tanh(y * 1.8)
    return y * env_adsr(n, 0.003, 0.08, 0.75, 0.03) * v * 0.32


def inst_dist_guitar(f, d, v):
    y = karplus(f, d, v, decay=0.998, bright=0.85, tail=0.12)
    y = np.tanh(y * 9.0) * 0.5
    y = hp(lp(y, 3200), 90)
    return y * 0.55


def inst_skank(f, d, v):
    """Ska up-stroke: a short, choked chord chop."""
    y = karplus(f, min(d, 0.11), v, decay=0.99, bright=0.9, tail=0.04)
    y = np.tanh(y * 3.0) * 0.6
    return hp(lp(y, 4800), 280)


def inst_pick_bass(f, d, v):
    y = karplus(f, d, v, decay=0.995, bright=0.7, tail=0.1)
    return lp(np.tanh(y * 2.0), 1700) * 1.1


def inst_spiccato(f, d, v):
    """Short bowed strings for galloping orchestral ostinatos."""
    dd = min(d, 0.22)
    n = int((dd + 0.18) * SR)
    x = np.zeros(n)
    for det in (-0.08, 0.0, 0.07):
        x += saw_wave(phase(f * 2 ** (det / 12), n) + RNG.uniform())
    x = lp(x, 3200)
    return x * env_adsr(n, 0.006, 0.07, 0.35, 0.12) * v * 0.11


INSTRUMENTS = {
    "toy_piano": inst_toy_piano, "glock": inst_glock, "music_box": inst_music_box, "kalimba": inst_kalimba,
    "marimba": inst_marimba, "vibes": inst_vibes, "steel_drum": inst_steel_drum, "celesta": inst_celesta,
    "uke": inst_uke, "banjo": inst_banjo, "nylon": inst_nylon, "harp": inst_harp, "pizz": inst_pizz,
    "upright": inst_upright, "slap_bass": inst_slap_bass, "synth_bass": inst_synth_bass, "sub_bass": inst_sub_bass,
    "tuba": inst_tuba, "square": inst_square, "pulse12": inst_pulse12, "pulse25": inst_pulse25,
    "gb_wave": inst_gb_wave, "tri_bass": inst_tri_bass, "supersaw": inst_supersaw, "pluck": inst_pluck,
    "organ": inst_organ, "calliope": inst_calliope, "accordion": inst_accordion, "harmonica": inst_harmonica,
    "fiddle": inst_fiddle, "kazoo": inst_kazoo, "whistle": inst_whistle, "strings": inst_strings,
    "brass": inst_brass, "clav": inst_clav, "pad": inst_pad, "choir": inst_choir, "theremin": inst_theremin,
    "bell": inst_bell, "acid": inst_acid, "dist_guitar": inst_dist_guitar, "skank": inst_skank,
    "pick_bass": inst_pick_bass, "spiccato": inst_spiccato,
}


@functools.lru_cache(maxsize=4096)
def render_note(inst, midi, dur, vel, detune_cents=0.0):
    f = midi_hz(midi) * 2 ** (detune_cents / 1200.0)
    return INSTRUMENTS[inst](f, dur, vel).astype(np.float32)


# ---------------------------------------------------------------- drums


def dr_kick(v=1.0, tone=1.0):
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    f = 45 * tone + 110 * np.exp(-t * 30)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
    x += noise(n) * np.exp(-t * 200) * 0.2
    return x * v * 0.9


def dr_snare(v=1.0):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    x = hp(noise(n), 1200) * np.exp(-t * 18) * 0.7 + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25) * 0.5
    return x * v * 0.6


def dr_clap(v=1.0):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    e = np.exp(-t * 25)
    for k in (0.0, 0.011, 0.022):
        e += np.where(t >= k, np.exp(-(t - k) * 120), 0) * 0.6
    x = bp(noise(n), 800, 3000) * e
    return x * v * 0.5


def dr_hat(v=1.0, open_=False):
    n = int((0.3 if open_ else 0.06) * SR)
    t = np.arange(n) / SR
    x = hp(noise(n), 7000) * np.exp(-t * (8 if open_ else 60))
    return x * v * 0.35


def dr_shaker(v=1.0):
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    e = np.sin(np.pi * np.clip(t / 0.09, 0, 1)) ** 2
    return bp(noise(n), 4000, 10000) * e * v * 0.25


def dr_brush(v=1.0):
    n = int(0.2 * SR)
    t = np.arange(n) / SR
    e = np.minimum(1, t / 0.03) * np.exp(-t * 12)
    return bp(noise(n), 2000, 8000) * e * v * 0.3


def dr_rim(v=1.0):
    n = int(0.05 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 1700 * t) * np.exp(-t * 120) + hp(noise(n), 3000) * np.exp(-t * 200) * 0.3
    return x * v * 0.35


def dr_wood(v=1.0, f=900):
    n = int(0.08 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 60)
    return x * v * 0.45


def dr_cowbell(v=1.0):
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = square_wave(540 * t) + square_wave(800 * t)
    x = bp(x, 500, 2500) * np.exp(-t * 12)
    return x * v * 0.12


def dr_tamb(v=1.0):
    n = int(0.18 * SR)
    t = np.arange(n) / SR
    x = hp(noise(n), 6000) * np.exp(-t * 20) * (1 + 0.5 * np.sin(2 * np.pi * 30 * t))
    return x * v * 0.3


def dr_crash(v=1.0):
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    return hp(noise(n), 4000) * np.exp(-t * 2.5) * v * 0.3


def dr_washboard(v=1.0):
    n = int(0.07 * SR)
    t = np.arange(n) / SR
    x = hp(noise(n), 2500) * np.exp(-t * 50) * (1 + np.sign(np.sin(2 * np.pi * 180 * t)))
    return x * v * 0.25


def dr_noise_snare(v=1.0):  # chiptune noise channel
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    x = np.repeat(noise(n // 8 + 1), 8)[:n]
    return x * np.exp(-t * 30) * v * 0.3


def dr_noise_hat(v=1.0):
    n = int(0.04 * SR)
    t = np.arange(n) / SR
    x = np.repeat(noise(n // 2 + 1), 2)[:n]
    return x * np.exp(-t * 90) * v * 0.18


def dr_noise_kick(v=1.0):
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    f = 60 + 300 * np.exp(-t * 40)
    x = square_wave(np.cumsum(f) / SR) * np.exp(-t * 25)
    return x * v * 0.3


def dr_timpani(v=1.0):
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 70 * t) * np.exp(-t * 4) + lp(noise(n), 400) * np.exp(-t * 10) * 0.5
    return x * v * 0.7


def dr_heart(v=1.0):
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * (40 + 30 * np.exp(-t * 20)) * t) * np.exp(-t * 14)
    t2 = t - 0.18
    x += np.where(t2 > 0, np.sin(2 * np.pi * 38 * t2) * np.exp(-np.maximum(t2, 0) * 16) * 0.7, 0)
    return lp(x, 200) * v * 1.2


def dr_taiko(v=1.0):
    n = int(0.8 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * np.cumsum(52 + 70 * np.exp(-t * 18)) / SR) * np.exp(-t * 5)
    x += lp(noise(n), 350) * np.exp(-t * 22) * 0.7
    return x * v * 0.95


DRUMS = {
    "kick": dr_kick, "snare": dr_snare, "clap": dr_clap, "hat": dr_hat, "ohat": lambda v=1.0: dr_hat(v, True),
    "shaker": dr_shaker, "brush": dr_brush, "rim": dr_rim, "wood": dr_wood, "cowbell": dr_cowbell,
    "tamb": dr_tamb, "crash": dr_crash, "washboard": dr_washboard, "nsnare": dr_noise_snare,
    "nhat": dr_noise_hat, "nkick": dr_noise_kick, "timpani": dr_timpani, "heart": dr_heart, "taiko": dr_taiko,
}


@functools.lru_cache(maxsize=256)
def render_drum(name, vel):
    return DRUMS[name](vel).astype(np.float32)


# ---------------------------------------------------------------- effects


def _comb(x, D, g):
    y = np.zeros_like(x)
    n = len(x)
    y[:D] = x[:D]
    for k in range(D, n, D):
        e = min(k + D, n)
        y[k:e] = x[k:e] + g * y[k - D:e - D]
    return y


def _allpass(x, D, g):
    y = np.zeros_like(x)
    n = len(x)
    y[:D] = -g * x[:D]
    for k in range(D, n, D):
        e = min(k + D, n)
        y[k:e] = -g * x[k:e] + x[k - D:e - D] + g * y[k - D:e - D]
    return y


def reverb(x, wet=0.25, size=1.0, damp=3500):
    """Small Schroeder reverb (mono in -> stereo out)."""
    combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
    aps = [556, 441, 341, 225]
    scale = SR / 44100.0 * size
    xin = lp(x, damp, 1)
    outs = []
    for side in (0, 23):
        acc = np.zeros(len(x))
        for c in combs:
            acc += _comb(xin, int((c + side) * scale), 0.82)
        for ap in aps:
            acc = _allpass(acc, int((ap + side) * scale), 0.5)
        outs.append(acc * 0.05)
    return np.stack([x * (1 - wet) + outs[0] * wet * 4, x * (1 - wet) + outs[1] * wet * 4])


def echo(x, delay_s, fb=0.35, mix=0.3):
    d = int(delay_s * SR)
    shifted = np.concatenate([np.zeros(d), x])[: len(x)]
    return x + _comb(shifted, d, fb) * mix


def bitcrush(x, bits=6, down=3):
    q = 2 ** (bits - 1)
    y = np.round(x * q) / q
    if down > 1:
        y = np.repeat(y[::down], down)[: len(x)]
    return y


def wow(x, depth=0.003, rate=0.6):
    """Tape wow: slow pitch wobble via modulated delay (works on mono or stereo)."""
    n = x.shape[-1]
    t = np.arange(n) / SR
    d = depth * SR * (1 + np.sin(2 * np.pi * rate * t) + 0.5 * np.sin(2 * np.pi * rate * 2.7 * t + 1.0))
    idx = np.clip(np.arange(n) - d, 0, n - 1)
    if x.ndim == 1:
        return np.interp(idx, np.arange(n), x)
    return np.stack([np.interp(idx, np.arange(n), ch) for ch in x])


def vinyl(n, amt=0.02):
    crackle = np.zeros(n)
    k = RNG.integers(0, n, size=max(1, n // 2500))
    crackle[k] = RNG.uniform(-1, 1, size=len(k))
    crackle = hp(crackle, 1500)
    hiss = lp(noise(n), 5000) * 0.15
    return (crackle + hiss) * amt


def pan_stereo(x, pan):
    """pan in [-1, 1] -> stereo array"""
    l = np.cos((pan + 1) * np.pi / 4)
    r = np.sin((pan + 1) * np.pi / 4)
    return np.stack([x * l, x * r])


def resample(x, ratio):
    """Resample by ratio (>1 = longer/lower when played at same rate)."""
    n = int(len(x) * ratio)
    if n < 2:
        return np.zeros(1)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


# ---------------------------------------------------------------- espeak singer

_ESPEAK_ROOT = None


def espeak_root():
    """Private copy of espeak-ng-data so we can add monotone voice variants."""
    global _ESPEAK_ROOT
    if _ESPEAK_ROOT:
        return _ESPEAK_ROOT
    out = subprocess.run(["espeak-ng", "--version"], capture_output=True, text=True).stdout
    data = out.split("Data at:")[1].strip()
    root = os.path.join(CACHE_DIR, "espeak")
    dst = os.path.join(root, "espeak-ng-data")
    if not os.path.isdir(dst):
        os.makedirs(root, exist_ok=True)
        shutil.copytree(data, dst)
    _ESPEAK_ROOT = root
    return root


# voice timbres: (base variant gender, formant tweaks, extra lines)
TIMBRES = {
    "kid": ("female", "formant 0 115 90 110\nformant 1 120 90 110\nformant 2 118 80 110\nformant 3 115 80 110\n", "breath 0 2 4 4 4 4 0 4\n"),
    "lady": ("female", "formant 0 105 85 120\nformant 1 110 85 120\nformant 2 110 75 120\nformant 3 110 75 120\n", "breath 0 3 5 5 5 5 0 5\n"),
    "guy": ("male", "formant 0 100 100 100\nformant 1 98 98 100\nformant 2 98 98 100\n", ""),
    "deep": ("male", "formant 0 88 100 100\nformant 1 86 100 100\nformant 2 90 100 100\nformant 3 92 100 100\n", "roughness 2\n"),
    "whisper": ("male", "formant 0 100 0 100\nformant 1 100 80 100\n", "voicing 25\nbreath 75 75 50 40 15 10\nbreathw 150 150 200 200 400 400\n"),
    "robot": ("male", "formant 0 100 100 100\n", "flutter 0\nroughness 0\n"),
    "croak": ("male", "formant 0 92 100 100\nformant 1 90 100 100\n", "roughness 7\nflutter 30\n"),
}


def _variant_name(timbre, p):
    return f"sg_{timbre}_{p}"


def _ensure_variant(timbre, p):
    root = espeak_root()
    name = _variant_name(timbre, p)
    path = os.path.join(root, "espeak-ng-data", "voices", "!v", name)
    if not os.path.exists(path):
        gender, formants, extra = TIMBRES[timbre]
        with open(path, "w") as fh:
            fh.write(f"language variant\nname {name}\ngender {gender}\npitch {p} {p}\n{formants}{extra}")
    return name


def _read_wav(path):
    with wave.open(path) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
    return x, sr


def espeak_raw(text, voice="en-us", speed=170, pitch=None, extra_args=()):
    """Render text with espeak-ng, returns (samples at SR, float)."""
    key = hashlib.md5(f"{text}|{voice}|{speed}|{pitch}|{extra_args}".encode()).hexdigest()
    cpath = os.path.join(CACHE_DIR, "tts", key + ".npy")
    if os.path.exists(cpath):
        return np.load(cpath)
    os.makedirs(os.path.dirname(cpath), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    args = ["espeak-ng", "--path=" + espeak_root(), "-v", voice, "-s", str(int(speed)), "-w", tmp]
    if pitch is not None:
        args += ["-p", str(pitch)]
    args += list(extra_args)
    args.append(text)
    subprocess.run(args, check=True, capture_output=True)
    x, sr = _read_wav(tmp)
    os.unlink(tmp)
    x = resample(x, SR / sr)
    # trim silence
    a = np.abs(x)
    idx = np.where(a > 0.01)[0]
    if len(idx):
        x = x[max(0, idx[0] - 40): idx[-1] + 80]
    np.save(cpath, x)
    return x


def _voiced_region(x, f0):
    """Locate the most vowel-like stretch: high energy + strong periodicity."""
    period = SR / f0
    win = int(max(period * 2, 0.02 * SR))
    hop = win // 2
    best = None
    scores = []
    for i in range(0, max(1, len(x) - win), hop):
        fr = x[i:i + win]
        e = np.sqrt(np.mean(fr ** 2))
        p = int(round(period))
        if len(fr) > p + 4:
            a, b = fr[:-p], fr[p:]
            c = np.dot(a, b) / (np.sqrt(np.dot(a, a) * np.dot(b, b)) + 1e-9)
        else:
            c = 0
        scores.append((i, e * max(c, 0) ** 2))
    if not scores:
        return len(x) // 3, 2 * len(x) // 3
    sc = np.array([s for _, s in scores])
    thr = sc.max() * 0.5
    good = sc >= thr
    # longest run of good frames
    run_s = run_best = 0
    best = (0, 0)
    for k, g in enumerate(good):
        if g:
            if k == 0 or not good[k - 1]:
                run_s = k
            if k - run_s + 1 > run_best:
                run_best = k - run_s + 1
                best = (run_s, k)
    s = scores[best[0]][0]
    e = scores[best[1]][0] + win
    return s, min(e, len(x))


def sustain(x, f0, target_len):
    """Stretch a monotone syllable to target_len samples by looping pitch periods in its vowel."""
    if len(x) >= target_len:
        y = x[:target_len].copy()
        fade = min(len(y), int(0.03 * SR))
        y[-fade:] *= np.linspace(1, 0, fade)
        return y
    s, e = _voiced_region(x, f0)
    period = SR / f0
    k = max(1, int(round(0.012 * SR / period)))
    L = int(round(k * period))
    c = (s + e) // 2
    g0 = max(0, c - L)
    grain = x[g0: g0 + 2 * L]
    if len(grain) < 2 * L or L < 4:
        y = np.zeros(target_len)
        y[: len(x)] = x
        return y
    extra = ((target_len - len(x)) // L) * L  # whole loops only -> phase-continuous seams
    w = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(2 * L) / (2 * L))
    nrep = extra // L + 3
    body = np.zeros(nrep * L + L)
    gw = grain * w
    for r in range(nrep):
        body[r * L: r * L + 2 * L] += gw
    body = body[L: L + extra]
    # splice at c with short crossfades
    head = x[:c]
    tail = x[c:]
    y = np.concatenate([head, body, tail])
    if len(y) < target_len:
        y = np.concatenate([y, np.zeros(target_len - len(y))])
    y = y[:target_len]
    fin = min(len(y), int(0.003 * SR))
    y[:fin] *= np.linspace(0, 1, fin)
    fade = min(len(y), int(0.04 * SR))
    y[-fade:] *= np.linspace(1, 0, fade)
    return y


def sing_syllable(text, midi, dur, timbre="kid", speed=170):
    """Render one sung syllable at exact pitch with duration dur (seconds)."""
    f = midi_hz(midi)
    # espeak's monotone variant produces f0 = p - 9 Hz (measured)
    # keep espeak in a comfortable range and transpose the rest by resampling
    ef = f
    lo, hi = (70, 230) if TIMBRES[timbre][0] == "male" else (140, 420)
    while ef > hi:
        ef /= 2 ** (3 / 12)
    while ef < lo:
        ef *= 2 ** (3 / 12)
    p = int(round(ef + 9))
    actual = p - 9
    ratio_correct = f / actual  # remaining pitch ratio, applied by resampling
    voice = "en-us+" + _variant_name(timbre, p)
    _ensure_variant(timbre, p)
    target = int(dur * SR)
    x = espeak_raw(text, voice, speed)
    natural = len(x) / ratio_correct
    if natural > target * 0.9:
        sp = min(450, speed * natural / (target * 0.85))
        x = espeak_raw(text, voice, int(sp))
    # sustain in espeak's pitch domain, then resample to target pitch
    pre_target = int(target * ratio_correct)
    y = sustain(x, actual, pre_target)
    y = resample(y, 1.0 / ratio_correct)
    if len(y) < target:
        y = np.concatenate([y, np.zeros(target - len(y))])
    return y[:target]


def vibrato(x, rate=5.5, depth_cents=18):
    n = len(x)
    t = np.arange(n) / SR
    amp = (2 ** (depth_cents / 1200) - 1) / (2 * np.pi * rate)
    d = amp * SR * np.sin(2 * np.pi * rate * t)
    idx = np.clip(np.arange(n) + d, 0, n - 1)
    return np.interp(idx, np.arange(n), x)


def speak(text, timbre="guy", pitch_hz=None, speed=150, range_=None):
    """Plain speech (for narration and sfx). range_ = pitch variation in Hz."""
    if pitch_hz is None:
        return espeak_raw(text, "en-us", speed)
    root = espeak_root()
    rng = range_ if range_ is not None else pitch_hz * 0.5
    name = f"sp_{timbre}_{int(pitch_hz)}_{int(rng)}"
    path = os.path.join(root, "espeak-ng-data", "voices", "!v", name)
    if not os.path.exists(path):
        gender, formants, extra = TIMBRES[timbre]
        with open(path, "w") as fh:
            fh.write(f"language variant\nname {name}\ngender {gender}\npitch {int(pitch_hz)} {int(pitch_hz + rng)}\n{formants}{extra}")
    return espeak_raw(text, "en-us+" + name, speed)


# ---------------------------------------------------------------- output


def write_ogg(path, x, quality=2):
    """x: mono or (2, n) stereo float array."""
    if x.ndim == 1:
        x = np.stack([x, x])
    peak = np.max(np.abs(x)) + 1e-9
    if peak > 0.98:
        x = x * (0.98 / peak)
    pcm = (np.clip(x.T, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    os.makedirs(os.path.dirname(path), exist_ok=True)
    subprocess.run(["oggenc", "-Q", "-q", str(quality), "-o", path, tmp], check=True)
    os.unlink(tmp)


def write_ogg_mono(path, x, quality=2):
    peak = np.max(np.abs(x)) + 1e-9
    if peak > 0.98:
        x = x * (0.98 / peak)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    os.makedirs(os.path.dirname(path), exist_ok=True)
    subprocess.run(["oggenc", "-Q", "-q", str(quality), "-o", path, tmp], check=True)
    os.unlink(tmp)
