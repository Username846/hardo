import sys, time
sys.path.insert(0, '.')
import numpy as np
import synth as S, music, songs
sid = sys.argv[1]
dark = len(sys.argv) > 2
song = [s for s in songs.SONGS if s["id"] == sid][0]
t0 = time.time()
x, meta = music.render_song(song, dark)
print("render", round(time.time() - t0, 1), "s; length", meta["length"])
out = "/tmp/claude-0/-home-user-hardo/6abfe1b8-8a0c-5f01-9840-3a0439460ad2/scratchpad/" + sid + ("_dark" if dark else "") + ".ogg"
S.write_ogg(out, x)
print(meta["lines"][:3])
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
f, ax = plt.subplots(2, 1, figsize=(14, 6))
m = x.mean(axis=0)
ax[0].specgram(m[:int(20*S.SR)], NFFT=2048, Fs=S.SR, noverlap=1536); ax[0].set_ylim(0, 3000)
ax[1].plot(np.arange(len(m)) / S.SR, m, lw=0.3)
plt.savefig(out.replace(".ogg", ".png"), dpi=60)
