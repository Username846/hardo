extends Screen
## The party radio (it turns up in the party room once the secret game is beaten): every song
## from the party, the cute version or the evil one, with the words to sing along. When a song
## finishes, the next one comes on.

const SongData := preload("res://scripts/gen/song_data.gd")

## [song id, where it plays in the game]
const TRACKS := [
	["theme", "title screen"], ["title", "what's your name?"], ["hub", "party room"],
	["race", "KNEAD FOR SPEED"], ["skate", "TONY HONK 2"], ["digi", "DIJIMON"],
	["cards", "Card Checkpoint"], ["duty", "CALL OF BIRTHDAY"], ["royale", "FORTNIGHT"],
	["obby", "ROBLOCKS"], ["poke", "POKeMANS"], ["repo", "R.E.P.O."],
	["karaoke", "MIKAKE KARAOKE"], ["rocko", "the secret"],
]
const BOX := Rect2(300, 70, 680, 196)
const EVIL_COL := Color(0.72, 0.6, 0.85)

var cur := -1
var evil := false
var playing := false
var _last_pos := 0.0
var _since := 0.0
var notes: Array = []   # {p, v, t, col}


func enter() -> void:
	bg = Color(0.16, 0.13, 0.27)
	use_back_layer()
	lyrics_y = 684.0
	Game.radio_seen = true
	Game.save_game()
	for i in TRACKS.size():
		var id: String = TRACKS[i][0]
		var x := 40.0 + (i % 2) * 610.0
		var y := 284.0 + (i / 2) * 54.0
		add_button("t%d" % i, Rect2(x, y, 456, 46), "%s  (%s)" % [_title(id), TRACKS[i][1]], func(): _play(i, false), Crayon.WHITE, 22)
		if SongData.SONGS.has(id + "_dark"):
			add_button("e%d" % i, Rect2(x + 464, y, 126, 46), "evil", func(): _play(i, true), EVIL_COL, 22)
	var cy := BOX.end.y - 50.0
	add_button("prev", Rect2(BOX.get_center().x - 160, cy, 96, 42), "<<", _prev, Crayon.WHITE, 26)
	add_button("stop", Rect2(BOX.get_center().x - 52, cy, 104, 42), "STOP", _stop, Crayon.WHITE, 24)
	add_button("next", Rect2(BOX.get_center().x + 64, cy, 96, 42), ">>", _next, Crayon.WHITE, 26)
	Audio.sfx("radio", -6)
	_play(0, false)


func _title(id: String) -> String:
	return String(SongData.SONGS[id]["title"]) if SongData.SONGS.has(id) else id


func _song_id() -> String:
	return String(TRACKS[cur][0]) + ("_dark" if evil else "")


func _play(i: int, dark: bool) -> void:
	cur = i
	evil = dark and SongData.SONGS.has(String(TRACKS[i][0]) + "_dark")
	playing = true
	_since = 0.0
	_last_pos = 0.0
	Audio.play_music(_song_id(), 0.4)
	get_button("stop").label = "STOP"
	for b in buttons:
		var id: String = b.id
		if id.begins_with("t"):
			b.col = Crayon.YELLOW if (int(id.substr(1)) == cur and not evil) else Crayon.WHITE
		elif id.begins_with("e"):
			b.col = Crayon.PURPLE.lightened(0.15) if (int(id.substr(1)) == cur and evil) else EVIL_COL


func _stop() -> void:
	if playing:
		playing = false
		Audio.stop_music(0.4)
		get_button("stop").label = "PLAY"
	else:
		_play(maxi(cur, 0), evil)


func _next() -> void:
	_play((cur + 1) % TRACKS.size(), evil)


func _prev() -> void:
	_play((cur - 1 + TRACKS.size()) % TRACKS.size(), evil)


func tick(dt: float) -> void:
	_since += dt
	if playing and Audio.song == _song_id():
		# a song that wraps round to the start has finished: on to the next one
		if Audio.song_pos < _last_pos - 2.0 and _since > 3.0:
			_next()
			return
		_last_pos = Audio.song_pos
	if playing and randf() < dt * 3.0:
		var side := -1.0 if randf() < 0.5 else 1.0
		notes.append({"p": BOX.get_center() + Vector2(side * 250, -20), "v": Vector2(side * randf_range(20, 70), -randf_range(50, 90)), "t": 0.0, "col": Crayon.RAINBOW[randi() % 7]})
	for n in notes:
		n.t += dt
		n.p += n.v * dt
	notes = notes.filter(func(n): return n.t < 2.5)


func _pulse() -> float:
	if not playing or not SongData.SONGS.has(Audio.song):
		return 0.0
	var beat := Audio.song_pos * float(SongData.SONGS[Audio.song]["bpm"]) / 60.0
	return pow(1.0 - fmod(maxf(beat, 0.0), 1.0), 3.0)


func paint_back() -> void:
	# a cosy room at night with a shelf for the radio
	for i in 30:
		var p := Vector2(fmod(i * 233.0, W), fmod(i * 157.0, 260.0) + 10)
		Crayon.disc(pen, p, 3, Color(1, 1, 1, 0.08))
	Crayon.rect(pen, Rect2(-40, BOX.end.y + 2, W + 80, 10), Crayon.INK, 3, Crayon.BROWN, 20)
	Crayon.text(pen, Vector2(150, 150), "PARTY", 44, Crayon.YELLOW, 1, 21, Crayon.title_font())
	Crayon.text(pen, Vector2(150, 200), "RADIO", 44, Crayon.YELLOW, 1, 22, Crayon.title_font())
	Crayon.text(pen, Vector2(1130, 160), "every song", 26, Color(1, 1, 1, 0.7), 1, 23)
	Crayon.text(pen, Vector2(1130, 194), "from the party", 26, Color(1, 1, 1, 0.7), 1, 24)


func paint() -> void:
	var dark := evil and playing
	draw_boombox(pen, BOX, _pulse(), 300, dark)
	_lcd(Rect2(BOX.position + Vector2(BOX.size.x * 0.3, 18), Vector2(BOX.size.x * 0.4, 108)))
	for n in notes:
		var a := clampf(2.5 - n.t, 0.0, 1.0)
		Crayon.text(pen, n.p, "♪", 34, Color(n.col, a), 1, 900, null, 0.3, false)


func _lcd(r: Rect2) -> void:
	var glow := Color(0.6, 1.0, 0.7) if not evil else Color(1.0, 0.5, 0.6)
	if cur < 0 or not playing:
		Crayon.text(pen, r.get_center(), "PICK A SONG!" if cur < 0 else "STOPPED", 30, glow, 1, 310, Crayon.title_font())
		return
	Crayon.text(pen, r.position + Vector2(8, 16), "CHUMBO FM   %02d/%02d" % [cur + 1, TRACKS.size()], 17, Color(glow, 0.8), 0, 311, null, 0.2, false)
	var name := _title(String(TRACKS[cur][0]))
	Crayon.text(pen, r.get_center() + Vector2(0, -4), name, 28 if name.length() < 18 else 24, glow, 1, 312, Crayon.title_font())
	var sub: String = "(evil version)" if evil else String(TRACKS[cur][1])
	Crayon.text(pen, r.position + Vector2(8, r.size.y - 16), sub, 17, Color(glow, 0.8), 0, 313, null, 0.2, false)
	var tm := maxf(Audio.song_pos, 0.0)
	var ln := Audio.song_length()
	Crayon.text(pen, r.end - Vector2(8, 16), "%d:%02d / %d:%02d" % [int(tm) / 60, int(tm) % 60, int(ln) / 60, int(ln) % 60], 17, Color(glow, 0.8), 2, 314, null, 0.2, false)


## A crayon boombox: handle, two thumping speakers, and a little screen in the middle.
## pulse 0..1 makes the speakers kick (to the beat); also drawn on the table in the party room.
static func draw_boombox(ci: CanvasItem, r: Rect2, pulse: float, sd: int, dark: bool = false) -> void:
	var ink := Crayon.INK
	var body := Crayon.RED.lerp(Crayon.PURPLE, 0.6) if dark else Crayon.RED.lightened(0.1)
	# handle and antenna
	var hy := r.position.y - r.size.y * 0.16
	Crayon.line(ci, r.position + Vector2(r.size.x * 0.22, 0), Vector2(r.position.x + r.size.x * 0.22, hy), ink, maxf(3.0, r.size.y * 0.03), sd)
	Crayon.line(ci, Vector2(r.position.x + r.size.x * 0.22, hy), Vector2(r.position.x + r.size.x * 0.78, hy), ink, maxf(3.0, r.size.y * 0.03), sd + 1)
	Crayon.line(ci, Vector2(r.position.x + r.size.x * 0.78, hy), r.position + Vector2(r.size.x * 0.78, 0), ink, maxf(3.0, r.size.y * 0.03), sd + 2)
	Crayon.line(ci, r.position + Vector2(r.size.x * 0.9, 0), r.position + Vector2(r.size.x * 1.0, -r.size.y * 0.42), ink, maxf(2.0, r.size.y * 0.02), sd + 3)
	Crayon.disc(ci, r.position + Vector2(r.size.x * 1.0, -r.size.y * 0.42), maxf(3.0, r.size.y * 0.035), ink)
	Crayon.rect(ci, r, ink, maxf(3.0, r.size.y * 0.035), body, sd + 4)
	# speakers
	var sr := r.size.y * 0.34
	for side in [0.15, 0.85]:
		var c := r.position + Vector2(r.size.x * side, r.size.y * 0.52)
		Crayon.circle(ci, c, sr, ink, maxf(2.0, sr * 0.06), Color(0.2, 0.18, 0.22), sd + 5 + int(side * 10))
		Crayon.circle(ci, c, sr * (0.55 + 0.12 * pulse), ink, maxf(2.0, sr * 0.05), Color(0.4, 0.38, 0.42), sd + 7 + int(side * 10))
		Crayon.disc(ci, c, sr * 0.16, Color(0.75, 0.72, 0.7))
	# the screen in the middle
	var lcd := Rect2(r.position + Vector2(r.size.x * 0.3, r.size.y * 0.09), Vector2(r.size.x * 0.4, r.size.y * 0.55))
	Crayon.rect(ci, lcd, ink, maxf(2.0, r.size.y * 0.025), Color(0.08, 0.14, 0.1) if not dark else Color(0.14, 0.06, 0.08), sd + 20)
