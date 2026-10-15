extends Node
## Music (with cross-fades and lyric tracking), sound effects and narration voice.

const SongData := preload("res://scripts/gen/song_data.gd")
const VoiceIndex := preload("res://scripts/gen/voice_index.gd")
const MUSIC_DB := -5.0
const DUCK_DB := -11.0

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
	apply_mute()


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


func apply_mute() -> void:
	AudioServer.set_bus_mute(0, Game.muted)


func toggle_mute() -> void:
	Game.muted = not Game.muted
	apply_mute()
	Game.save_game()


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


var _pb_last := -1.0
var _pb_at_us := 0


## Where the music really is, in seconds. Accumulating frame times drifts: Godot caps the
## frame time after a long hitch, so every stutter used to push the lyrics further behind.
## The reported position only moves in steps (and in the browser it arrives a frame late
## after a freeze), so it is carried forward by the time since it last changed.
func _audio_pos() -> float:
	var p := _cur.get_playback_position()
	var now := Time.get_ticks_usec()
	if p != _pb_last:
		_pb_last = p
		_pb_at_us = now
	p += minf((now - _pb_at_us) * 0.000001, 1.0) * _cur.pitch_scale
	return p - clampf(AudioServer.get_output_latency(), 0.0, 0.15)


func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var step := (now - _clock_us) * 0.000001 if _clock_us > 0 else delta
	_clock_us = now
	if not (_cur.playing and song != ""):
		return
	# move smoothly with the clock, then lean towards the real playback position
	song_pos += clampf(step, 0.0, 0.25) * _cur.pitch_scale
	var err := _audio_pos() - song_pos
	if absf(err) > 0.12:
		song_pos += err
	else:
		song_pos += err * minf(1.0, delta * 8.0)
	var l := song_length()
	if l > 0.0 and song_pos >= l and (_cur.stream as AudioStreamOggVorbis).loop:
		song_pos = fmod(song_pos, l)


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
			return {"parts": ln.parts, "sung": sung, "id": song + str(i), "dark": song.ends_with("_dark")}
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
