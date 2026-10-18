extends Node
## Music (with cross-fades and lyric tracking), sound effects and narration voice.

const SongData := preload("res://scripts/gen/song_data.gd")
const VoiceIndex := preload("res://scripts/gen/voice_index.gd")
const MUSIC_DB := -5.0
const DUCK_DB := -11.0
## Not "_dark" versions, but just as sad: their words are shown in the dark style too.
const GREY_SONGS := ["karaoke_grey", "rocko_leave"]

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _cur: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_i := 0
var voice: AudioStreamPlayer
var song := ""
var song_pos := 0.0
var _ducked := false
var _cache := {}
var _clock_us := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _player()
	_b = _player()
	_cur = _a
	for i in 10:
		_sfx.append(_player())
	voice = _player()
	voice.volume_db = 2.0
	apply_volume()
	_web_clock_setup()


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var s: AudioStream = load(path)
	_cache[path] = s
	return s


## Set from the volume slider. The slider is squared so the middle of it sounds like the middle.
func apply_volume() -> void:
	var v := clampf(Game.volume, 0.0, 1.0)
	AudioServer.set_bus_mute(0, v <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v * v, 0.0001)))


func set_volume(v: float, save: bool = true) -> void:
	Game.volume = clampf(v, 0.0, 1.0)
	apply_volume()
	if save:
		Game.save_game()


## True once a tap has let the browser play sound (the title screen's first tap).
var unlocked := false


## On the web, sounds are decoded the first time they play, which can freeze the game for a
## moment. Decoding ahead of time (while a screen transition covers the screen) avoids that.
func prepare(st: AudioStream) -> void:
	if st and OS.has_feature("web") and not AudioServer.is_stream_registered_as_sample(st):
		AudioServer.register_stream_as_sample(st)


func preload_music(name: String, loop: bool = true) -> void:
	var st := _load("res://assets/music/%s.ogg" % name) as AudioStreamOggVorbis
	if st:
		if not AudioServer.is_stream_registered_as_sample(st):
			st.loop = loop
		prepare(st)


var _sfx_ready := false


## Decodes every sound effect once (called on the first tap of the game).
func preload_sfx() -> void:
	if _sfx_ready:
		return
	_sfx_ready = true
	for f in ResourceLoader.list_directory("res://assets/sfx/"):
		if f.ends_with(".ogg"):
			prepare(_load("res://assets/sfx/" + f))


## Called by main once a new screen has been created. Decodes the narration a game will use
## now, while the page-turn covers the screen; on the web a line is otherwise decoded when it
## first plays, which is a small freeze in the middle of the game on slower phones.
func end_screen_setup(script_path: String) -> void:
	if script_path.begins_with("res://scripts/games/") and VoiceIndex.BY_SCRIPT.has(script_path):
		for k: String in VoiceIndex.BY_SCRIPT[script_path]:
			prepare(_load("res://assets/voice/%s.ogg" % k))


func play_music(name: String, fade: float = 1.2, from: float = 0.0, loop: bool = true) -> void:
	if name == song and _cur.playing:
		return
	var st := _load("res://assets/music/%s.ogg" % name) as AudioStreamOggVorbis
	if st == null:
		return
	if not AudioServer.is_stream_registered_as_sample(st):
		st.loop = loop
	prepare(st)
	# the spooky version of this song will be needed later: decode it now, not at the twist
	if not name.ends_with("_dark") and name != "karaoke":
		preload_music(name + "_dark")
	var old := _cur
	var nxt := _b if _cur == _a else _a
	nxt.stream = st
	nxt.pitch_scale = 1.0
	nxt.volume_db = -40.0 if fade > 0.0 else _target_db()
	if OS.has_feature("web"):
		var n = JavaScriptBridge.eval("window.__chumboMusic ? window.__chumboMusic.n : 0", true)
		_web_starts = int(n) if n != null else 0
	nxt.play(from)
	if fade > 0.0 or old.playing:
		var tw := create_tween().set_parallel(true)
		if fade > 0.0:
			tw.tween_property(nxt, "volume_db", _target_db(), fade)
		if old.playing:
			tw.tween_property(old, "volume_db", -60.0, maxf(fade, 0.05))
			tw.chain().tween_callback(old.stop)
	_cur = nxt
	song = name
	song_pos = from
	_stream_pos = from


func stop_music(fade: float = 1.0) -> void:
	song = ""
	if _cur.playing:
		var p := _cur
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -60.0, maxf(fade, 0.05))
		tw.tween_callback(p.stop)


func music_pitch(p: float, time: float = 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_cur, "pitch_scale", maxf(0.05, p), time)


func music_playing() -> bool:
	return _cur.playing and song != ""


func song_length() -> float:
	if SongData.SONGS.has(song):
		return SongData.SONGS[song]["length"]
	return 0.0


func _target_db() -> float:
	return MUSIC_DB + (DUCK_DB if _ducked else 0.0)


func duck(on: bool) -> void:
	if on == _ducked:
		return
	_ducked = on
	if _cur.playing:
		var tw := create_tween()
		tw.tween_property(_cur, "volume_db", _target_db(), 0.25)


var _stream_pos := 0.0
var _web_starts := 0

## Browser only: notes when each song really starts playing in the Web Audio engine (Godot
## starts it a little after play() is called, and its own reported position runs a second
## behind), so the game can read exactly where the music is from the audio clock.
const WEB_CLOCK_JS := """
(function () {
	if (window.__chumboMusic) return;
	var M = window.__chumboMusic = { n: 0, s: null };
	var start = AudioBufferSourceNode.prototype.start;
	AudioBufferSourceNode.prototype.start = function (when, offset) {
		try {
			if (this.buffer && this.buffer.duration > 20) {
				var c = this.context;
				M.n++;
				M.s = { node: this, c: c, t: Math.max(when || 0, c.currentTime), pos: offset || 0, last: -1, dur: this.buffer.duration };
			}
		} catch (e) {}
		return start.apply(this, arguments);
	};
	M.now = function () {
		var s = M.s;
		if (!s) return M.n + ' -1';
		var c = s.c, now = c.currentTime;
		if (now >= s.t) {
			if (s.last < 0) s.last = s.t;
			s.pos += (now - s.last) * s.node.playbackRate.value;
			s.last = now;
		}
		var p = s.pos;
		if (s.node.loop && s.dur > 0) p = p % s.dur;
		return M.n + ' ' + (p - (c.baseLatency || 0) - (c.outputLatency || 0));
	};
})();
"""


func _web_clock_setup() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_CLOCK_JS, true)


## How far into the song we are, as heard from the speakers. Summing frame times drifted
## (Godot caps the frame time after a long hitch, so every stutter pushed the lyrics further
## behind), so the clock comes from the audio itself: the Web Audio clock in the browser,
## Godot's playback position elsewhere.
func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var step := (now - _clock_us) * 0.000001 if _clock_us > 0 else delta
	_clock_us = now
	if not (_cur.playing and song != ""):
		return
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("window.__chumboMusic ? window.__chumboMusic.now() : ''", true)
		var parts := str(r).split(" ")
		if parts.size() == 2:
			# until the new song has really started, stay at its first note
			if int(parts[0]) > _web_starts:
				song_pos = float(parts[1])
			return
		# no audio clock (shouldn't happen): fall back to the real-time clock
		_stream_pos += step * _cur.pitch_scale
	else:
		_stream_pos = _cur.get_playback_position() + AudioServer.get_time_since_last_mix() * _cur.pitch_scale
	var l := song_length()
	if l > 0.0 and _stream_pos >= l and (_cur.stream as AudioStreamOggVorbis).loop:
		_stream_pos = fmod(_stream_pos, l)
	song_pos = _stream_pos - clampf(AudioServer.get_output_latency(), 0.0, 0.3)


var _lyric_lines := {}


## Per song: Array of lines {start, end, parts (syllables incl. trailing spaces), times}.
func _song_lines(name: String) -> Array:
	if _lyric_lines.has(name):
		return _lyric_lines[name]
	var out: Array = []
	if SongData.SONGS.has(name):
		for sy in SongData.SONGS[name].get("syl", []):
			var li := int(sy[4])
			while out.size() <= li:
				out.append({"start": INF, "end": 0.0, "parts": PackedStringArray(), "times": PackedFloat32Array()})
			var ln: Dictionary = out[li]
			var tt := float(sy[0])
			ln.start = minf(ln.start, tt)
			ln.end = maxf(ln.end, tt + float(sy[1]))
			ln.parts.append(String(sy[2]) + (" " if bool(sy[3]) else ""))
			ln.times.append(tt)
	_lyric_lines[name] = out
	return out


## What to show in the lyric bar right now: {} when nothing is being sung, otherwise
## {"parts": syllables, "sung": how many have been sung, "id": unique line id, "dark": bool}.
func lyric_state() -> Dictionary:
	if song == "" or not _cur.playing:
		return {}
	var lines := _song_lines(song)
	var pos := song_pos
	for i in range(lines.size() - 1, -1, -1):
		var ln: Dictionary = lines[i]
		if pos >= ln.start - 0.7 and pos <= ln.end + 1.2:
			var sung := 0
			var times: PackedFloat32Array = ln.times
			for k in times.size():
				if pos >= times[k] - 0.05:
					sung = k + 1
			return {"parts": ln.parts, "sung": sung, "id": song + str(i), "dark": song.ends_with("_dark") or song in GREY_SONGS}
	return {}


func sfx(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	var st := _load("res://assets/sfx/%s.ogg" % name)
	if st == null:
		return null
	var p := _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()
	return p


## Plays a narration clip; returns its length in seconds (0 if there is none).
func play_voice(path: String) -> float:
	var st := _load(path)
	if st == null:
		return 0.0
	voice.stream = st
	voice.play()
	return st.get_length()


func stop_voice() -> void:
	voice.stop()
