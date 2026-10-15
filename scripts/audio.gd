extends Node
## Music (with cross-fades and lyric tracking), sound effects and narration voice.

const SongData := preload("res://scripts/gen/song_data.gd")
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


func play_music(name: String, fade: float = 1.2, from: float = 0.0, loop: bool = true) -> void:
	if name == song and _cur.playing:
		return
	var st := _load("res://assets/music/%s.ogg" % name) as AudioStreamOggVorbis
	if st == null:
		return
	st.loop = loop
	var old := _cur
	var nxt := _b if _cur == _a else _a
	nxt.stream = st
	nxt.pitch_scale = 1.0
	nxt.volume_db = -40.0 if fade > 0.0 else _target_db()
	nxt.play(from)
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


func _process(delta: float) -> void:
	if _cur.playing and song != "":
		song_pos += delta * _cur.pitch_scale
		var l := song_length()
		if l > 0.0 and song_pos >= l:
			if (_cur.stream as AudioStreamOggVorbis).loop:
				song_pos = fmod(song_pos, l)


## The lyric line being sung right now ("" during instrumental bits).
func lyric() -> String:
	if not SongData.SONGS.has(song):
		return ""
	var lines: Array = SongData.SONGS[song]["lines"]
	var cur := ""
	for ln in lines:
		if song_pos >= ln[0] - 0.15:
			cur = ln[1]
	if lines.size() > 0:
		var last: Array = lines[lines.size() - 1]
		if song_pos > last[0] + 5.5:
			cur = ""
	return cur


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
