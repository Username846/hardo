extends Screen
## Present 10: MIKAKE KARAOKE (a Project DIVA-style rhythm game). Hatsune Mikake sings your
## birthday song on stage. Notes fly in from both sides of the screen to the two targets beside
## her: tap that side of the screen (or press A or D) as a note reaches its target. Miss too many
## and the voltage runs out: the song fails and starts again. In the solos the buttons make her
## dance. Halfway through, the song changes its mind about the words (and the buttons make her
## glitch instead). Then: make a wish.

const IDX := 9
const SongData := preload("res://scripts/gen/song_data.gd")
## A note comes in from the edge of the screen this long before it's due, and reaches its
## target on time.
const APPEAR := 1.4
## Timing windows (seconds either side of the note).
const COOL := 0.08
const FINE := 0.14
const SAFE := 0.2
const SAD := 0.28
const TEAL := Color(0.22, 0.78, 0.76)
const TEAL_DK := Color(0.08, 0.42, 0.45)
const SKIN := Color(1.0, 0.9, 0.8)
## The two targets, either side of her: left (tap the left half of the screen, or press A) and
## right (the right half, or D). Notes start at the edge of the screen on their side.
const TARGETS := [Vector2(450, 330), Vector2(830, 330)]
const TARGET_R := 44.0
const NOTE_FROM := [-30.0, 1310.0]
const PAD_KEY := ["A", "D"]
const LANE_COL := [Color(0.98, 0.45, 0.72), Color(0.22, 0.78, 0.76)]
## The voltage is the life bar: good hits fill it, misses drain it, and empty fails the song.
const START_VOLT := 0.5
const MISS_VOLT := 0.06
## Dance moves for the solos: each button has its own, one per tap, in turn.
## [move, seconds, what the screen calls it]
const MOVES := [
	[["pirouette", 1.0, "PIROUETTE!"], ["slide", 1.2, "SLIDE!"], ["axel", 1.3, "TRIPLE AXEL!"]],
	[["leap", 0.9, "BIG LEAP!"], ["slide", 1.2, "SLIDE!"], ["break", 1.2, "DANCE BREAK!"]],
]
## In the red song there's no dancing: the buttons make her break down a little more, in turn.
const DARK_MOVES := [["twitch", 1.0, "ERROR"], ["slump", 1.6, "PLEASE STOP"], ["tilt", 1.5, "HELP ME"],
	["flicker", 1.3, "I CAN'T STOP SINGING"]]
## How dark the room is when the cake comes out (it's lit by the candles from then on).
const ROOM_DIM := 0.3
const LYRIC_Y := 588.0
const LEEK_R := 60.0

var chart: Array = []
var hits := {}
var song := ""
var phase := "intro"   # intro, cute, dark, fail, malfunction, grey, candles_wait, candles, wish
var score := 0
var combo := 0
var best := 0
var voltage := START_VOLT
var end_time := 0.0
var bpm := 120.0
var candles: Array = []
var relights := 0
var black := 0.0
var crowd_k := 0.0
var cake_in := 0.0
var pops: Array = []       # {p, t, txt, col}
var bursts: Array = []     # {p, t, col}
var bounce := 0.0
var pad_flash := [0.0, 0.0]
## The targets fade away when she breaks down.
var pads_k := 1.0
## Failing: how many times each song has failed, the score to go back to, and the sign.
var fails := {}
var score_at_start := 0
var fail_k := 0.0
## A dance move in a solo: which one, how far into it (s), how long it is, which way a slide
## goes, and a tap that came in during it (its move is next).
var dance := ""
var dance_t := 0.0
var dance_len := 1.0
var dance_dir := 1.0
var dance_next := -1
var moves_done := [0, 0]
var dark_moves_done := 0
## Mikake breaking down after the last song: glitching (0..1), switched off (0..1), the beat
## she froze on, what the stage screens say, and the sparks and smoke coming off her.
var mal_glitch := 0.0
var broken := 0.0
var frozen_beat := 0.0
var err_text := ""
## The grey spotlight on her while the song goes on without her (0..1), and the dark that
## swallows everything else meanwhile.
var grey_light := 0.0
var gloom := 0.0
## The room going dark as the candles go out (the cake is drawn over it, in their light).
var candle_dark := 0.0
var _room_tw: Tween = null
var sparks: Array = []      # {p, v, t}
var smoke: Array = []       # {p, t}
## (Tap her leek five times quickly during the first song and she does the leek spin.)
var leek_taps: Array = []
var leek_spin := 0.0
var spin_ang := 0.0
var _whoosh_t := 0.0

# per note: which button (0 = left, 1 = right)
var _lane := PackedInt32Array()
var _lo := 0
var _baked_dark := -1


func enter() -> void:
	Narrator.top = true
	use_back_layer()
	lyrics_y = -1.0
	Audio.stop_music(0.5)
	Audio.preload_music("karaoke", false)
	Audio.preload_music("karaoke_dark", false)
	_run()


func _run() -> void:
	locked = true
	await wait(0.6)
	await line("welcome")
	_start("karaoke")
	phase = "cute"
	locked = false


func _start(name: String) -> void:
	song = name
	chart = SongData.KARAOKE[name]
	bpm = float(SongData.SONGS[name].bpm) if SongData.SONGS.has(name) else 120.0
	hits.clear()
	_lo = 0
	voltage = START_VOLT
	score_at_start = score
	_layout()
	var last: Array = chart[chart.size() - 1]
	end_time = float(last[0]) + float(last[1]) + 0.6
	Audio.play_music(name, 0.3, 0.0, false)


## Which button each note goes on follows the tune: a line's first note goes right if it's one of
## the line's high notes, then up a note = right, down = left, the same note = the same side.
func _layout() -> void:
	var n := chart.size()
	_lane.resize(n)
	var lines := {}
	for i in n:
		var ln := int(chart[i][4])
		if not lines.has(ln):
			lines[ln] = []
		lines[ln].append(i)
	for ln in lines:
		var idx: Array = lines[ln]
		var pitches: Array = []
		for i in idx:
			pitches.append(_pitch(i))
		var sorted := pitches.duplicate()
		sorted.sort()
		var c := sorted.size()
		var mid := (float(sorted[(c - 1) / 2]) + float(sorted[c / 2])) * 0.5
		var lane := 0
		for j in c:
			var p: float = pitches[j]
			if j == 0:
				lane = 1 if p >= mid else 0
			elif p > float(pitches[j - 1]):
				lane = 1
			elif p < float(pitches[j - 1]):
				lane = 0
			_lane[idx[j]] = lane


func _pitch(i: int) -> float:
	var e: Array = chart[i]
	return float(e[5]) if e.size() > 5 else float(i % 2)


func press(p: Vector2) -> void:
	match phase:
		"cute", "dark":
			# her leek isn't a button (but tap it a few times in a row in the first song...)
			if phase == "cute" and dance == "" and p.distance_to(_leek_center()) < LEEK_R:
				_leek_tap()
				return
			_button(0 if p.x < W * 0.5 else 1)
		"candles":
			_candle_tap(p)


func _unhandled_key_input(e: InputEvent) -> void:
	if locked or not (e is InputEventKey and e.pressed and not e.echo):
		return
	if phase != "cute" and phase != "dark":
		return
	if e.keycode in [KEY_A, KEY_LEFT]:
		_button(0)
	elif e.keycode in [KEY_D, KEY_RIGHT]:
		_button(1)


func _leek_tap() -> void:
	if leek_spin > 0.0:
		return
	leek_taps.append(t)
	leek_taps = leek_taps.filter(func(x: float) -> bool: return t - x < 2.5)
	if leek_taps.size() >= 5:
		leek_taps.clear()
		_leek_spin()


## Where the middle of her leek is right now (it moves with the dance).
func _leek_center() -> Vector2:
	var h := 330.0
	var beat := _beat()
	var up := sin(beat * PI)
	var sway := sin(beat * PI * 0.5) * 0.06
	var hand_r := Vector2(h * 0.08, -h * 0.69) + Vector2(h * 0.13, -h * 0.1 - up * h * 0.08)
	var la := -1.25 + up * 0.5
	return MIKAKE_FEET + (hand_r + Vector2(cos(la), sin(la)) * h * 0.12).rotated(sway)


func _leek_spin() -> void:
	leek_spin = 8.0
	_whoosh_t = 0.0
	Audio.sfx("sparkle", -2)
	Audio.sfx("yay_small", -4)
	if Game.found_egg("karaoke"):
		line_bg("leek_spin")


## Nothing to sing for a while (a solo, or before the words start): the buttons are for dancing.
func _free_time() -> bool:
	if phase != "cute" and phase != "dark":
		return false
	if _lo >= chart.size():
		return true
	return float(chart[_lo][0]) - Audio.song_pos > APPEAR + 0.3


## A button: hits the note that's due on that side, or in a solo, makes her dance.
func _button(lane: int) -> void:
	pad_flash[lane] = 1.0
	bounce = 1.0
	if _free_time():
		_dance(lane)
		return
	var now: float = Audio.song_pos
	var best_i := -1
	var best_d := 99.0
	var other_i := -1
	var other_d := 99.0
	for i in range(_lo, chart.size()):
		var nt := float(chart[i][0])
		if nt - now > SAD:
			break
		if hits.has(i):
			continue
		var d := absf(nt - now)
		if _lane[i] == lane:
			if d < best_d:
				best_d = d
				best_i = i
		elif d < other_d:
			other_d = d
			other_i = i
	if best_i < 0:
		if other_i >= 0 and other_d <= SAFE:
			# that note was on the other side
			Audio.sfx("wrong", -12)
			_miss(other_i, "WRONG")
		else:
			Audio.sfx("key", -14, 0.6)
		return
	hits[best_i] = true
	var txt := "SAD"
	var col := Color(0.6, 0.6, 0.75)
	if best_d <= COOL:
		txt = "COOL"
		col = Crayon.YELLOW
		score += 500 + combo * 10
		voltage += 0.03
	elif best_d <= FINE:
		txt = "FINE"
		col = TEAL.lightened(0.3)
		score += 300 + combo * 5
		voltage += 0.02
	elif best_d <= SAFE:
		txt = "SAFE"
		col = Crayon.GREEN.lightened(0.3)
		score += 100
		voltage += 0.01
	else:
		score += 30
		voltage -= 0.01
	if txt == "SAD":
		combo = 0
	else:
		combo += 1
		best = maxi(best, combo)
	voltage = clampf(voltage, 0.0, 1.0)
	pops.append({"p": _pop_at(lane), "t": 0.0, "txt": txt, "col": col})
	bursts.append({"p": TARGETS[lane], "t": 0.0, "col": LANE_COL[lane]})
	Audio.sfx("key", -8, 1.5 if txt == "COOL" else 1.2)
	if combo > 0 and combo % 10 == 0:
		Audio.sfx("yay_small", -6)
	if voltage <= 0.0:
		_fail()


func _miss(i: int, txt: String) -> void:
	hits[i] = false
	combo = 0
	voltage = maxf(0.0, voltage - MISS_VOLT)
	pops.append({"p": _pop_at(_lane[i]), "t": 0.0, "txt": txt, "col": Color(0.55, 0.45, 0.6)})
	if voltage <= 0.0:
		_fail()


## Where COOL / FINE / ... pops up for a button: above its target.
func _pop_at(lane: int) -> Vector2:
	return TARGETS[lane] + Vector2(0, -TARGET_R - 40.0)


func _dance(lane: int) -> void:
	if dance != "":
		dance_next = lane
		return
	var dark := phase == "dark"
	var mv: Array
	if dark:
		mv = DARK_MOVES[dark_moves_done % DARK_MOVES.size()]
		dark_moves_done += 1
	else:
		mv = MOVES[lane][moves_done[lane] % MOVES[lane].size()]
		moves_done[lane] += 1
	dance = mv[0]
	dance_len = mv[1]
	dance_t = 0.0
	dance_dir = -1.0 if lane == 0 else 1.0
	voltage = minf(1.0, voltage + 0.02)
	if dark:
		pops.append({"p": Vector2(640, 220), "t": 0.0, "txt": mv[2], "col": Color(1, 0.3, 0.3), "life": 1.4})
		match dance:
			"twitch":
				Audio.sfx("glitch", -4, randf_range(0.8, 1.2))
			"slump":
				Audio.sfx("slide_down", -4, 0.7)
			"tilt":
				Audio.sfx("creak", -4, 0.8)
			_:
				Audio.sfx("static", -6)
		return
	score += 150
	pops.append({"p": Vector2(640, 220), "t": 0.0, "txt": mv[2], "col": Crayon.YELLOW, "life": 1.2})
	Audio.sfx("whoosh", -6, 0.9 if dance == "leap" or dance == "axel" else 1.25)
	Audio.sfx("yay_small", -9)
	_spark_burst(12)


## The voltage ran out: the music grinds to a halt, and the song starts again from the top.
func _fail() -> void:
	var was := phase
	frozen_beat = _beat()
	phase = "fail"
	locked = true
	dance = ""
	dance_next = -1
	leek_spin = 0.0
	fails[song] = int(fails.get(song, 0)) + 1
	var n: int = fails[song]
	Audio.sfx("music_wrong", -2)
	Audio.music_pitch(0.3, 0.7)
	var tw := create_tween()
	tw.tween_property(self, "fail_k", 1.0, 0.35)
	await wait(0.8)
	Audio.stop_music(0.2)
	if was == "cute":
		Audio.sfx("uh_oh", -4)
		if n == 1:
			await line("failed")
		else:
			await line("failed_again")
	elif n == 1:
		await line("red_failed")
	else:
		await line("red_failed_again")
	var tw2 := create_tween()
	tw2.tween_property(self, "fail_k", 0.0, 0.3)
	score = score_at_start
	combo = 0
	phase = was
	_start(song)
	locked = false


func tick(dt: float) -> void:
	bounce = maxf(0.0, bounce - dt * 4.0)
	for k in 2:
		pad_flash[k] = maxf(0.0, pad_flash[k] - dt * 5.0)
	if dance != "":
		var was_t := dance_t
		dance_t += dt
		if dance == "slump" and was_t < dance_len * 0.75 and dance_t >= dance_len * 0.75:
			# jerked back up, to keep singing
			Audio.sfx("glitch", -2, 0.7)
			_spark_burst(16)
		if dance_t >= dance_len:
			dance = ""
			if dance_next >= 0:
				var nx := dance_next
				dance_next = -1
				if _free_time():
					_dance(nx)
	if leek_spin > 0.0:
		leek_spin = maxf(0.0, leek_spin - dt) if phase == "cute" else 0.0
		spin_ang += dt * 15.0
		_whoosh_t -= dt
		if _whoosh_t <= 0.0 and leek_spin > 0.0:
			_whoosh_t = 0.42
			Audio.sfx("whoosh", -14, randf_range(1.3, 1.6))
	for pp in pops:
		pp.t += dt
	pops = pops.filter(func(pp): return pp.t < pp.get("life", 0.7))
	for b in bursts:
		b.t += dt
	bursts = bursts.filter(func(b): return b.t < 0.35)
	for sp in sparks:
		sp.t += dt
		sp.v.y += 900.0 * dt
		sp.p += sp.v * dt
	sparks = sparks.filter(func(sp): return sp.t < 0.8)
	for sm in smoke:
		sm.t += dt
		sm.p += Vector2(sin(sm.t * 3.0 + sm.p.x) * 12.0, -40.0) * dt
	smoke = smoke.filter(func(sm): return sm.t < 3.0)
	if broken > 0.6 and randf() < dt * 3.0:
		smoke.append({"p": mikake_head(MIKAKE_FEET, 330.0, broken) + Vector2(randf_range(-20, 20), -20), "t": 0.0})
	if phase == "cute" or phase == "dark":
		var now: float = Audio.song_pos
		for i in range(_lo, chart.size()):
			var nt := float(chart[i][0])
			if now - nt <= SAD:
				break
			if not hits.has(i):
				_miss(i, "WORST")
				if phase == "fail":
					return
		while _lo < chart.size() and hits.has(_lo):
			_lo += 1
		if now >= end_time:
			if phase == "cute":
				# (no dancing into the red song)
				phase = "dark"
				dance = ""
				dance_next = -1
				_start("karaoke_dark")
				line_bg("wrong_words")
			else:
				_malfunction()
	if phase == "dark":
		crowd_k = minf(1.0, crowd_k + dt * 0.03)


## The song never ends... until the singer can't take it any more. Mikake glitches, throws
## sparks, winds down with the music and switches off, right there on the stage.
func _malfunction() -> void:
	frozen_beat = _beat()
	phase = "malfunction"
	locked = true
	dance = ""
	dance_next = -1
	var tp := create_tween()
	tp.tween_property(self, "pads_k", 0.0, 0.6)
	mal_glitch = 0.75
	err_text = "ERROR"
	Audio.music_pitch(0.6, 2.5)
	for k in 7:
		Audio.sfx("glitch", -3, randf_range(0.7, 1.3))
		if k % 2 == 0:
			Audio.sfx("static", -10)
		_spark_burst(14)
		await wait(0.32)
	err_text = "FATAL\nERROR"
	await line("are_you_okay")
	err_text = "SINGER.EXE\nHAS\nSTOPPED"
	Audio.music_pitch(0.2, 1.6)
	Audio.sfx("slide_down", -1, 0.55)
	mal_glitch = 0.0
	var tw := create_tween()
	tw.tween_property(self, "broken", 1.0, 1.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_spark_burst(30)
	await wait(1.2)
	Audio.stop_music(0.4)
	Audio.sfx("thud", -2, 0.7)
	Audio.sfx("switch", -4, 0.6)
	await wait(1.0)
	err_text = "NO\nSIGNAL"
	await line("singer_stopped")
	await _grey_verse()
	_candles()


## And it does go on: one slow verse in a grey whisper, while she just stands there, switched
## off, in one spotlight, and the dark takes everything else but the glow sticks.
func _grey_verse() -> void:
	phase = "grey"
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "grey_light", 1.0, 2.0)
	tw.tween_property(self, "gloom", 0.96, 2.5)
	Audio.play_music("karaoke_grey", 1.0, 0.0, false)
	var dur := Audio.song_length()
	var t0 := Time.get_ticks_msec()
	# it doesn't loop: wait for the last note to ring out
	while Audio.song == "karaoke_grey" and Audio.song_pos < dur - 0.4 and Time.get_ticks_msec() - t0 < (dur + 8.0) * 1000.0:
		await get_tree().process_frame
	Audio.stop_music(1.0)
	await wait(1.0)


func _spark_burst(n: int) -> void:
	var head := mikake_head(MIKAKE_FEET, 330.0, broken)
	for k in n:
		var a := randf_range(-PI, 0.0)
		sparks.append({"p": head + Vector2(randf_range(-40, 40), randf_range(-30, 20)), "v": Vector2(cos(a), sin(a)) * randf_range(150, 420), "t": randf() * 0.2})


## The cake comes up with its candles already lit, and the room comes back in their light.
func _candles() -> void:
	phase = "candles_wait"
	locked = true
	candles.clear()
	for k in 10:
		candles.append({"lit": true, "x": 442.0 + k * 44.0})
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "cake_in", 1.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "gloom", 0.0, 1.8)
	tw.tween_property(self, "candle_dark", ROOM_DIM, 1.8)
	tw.tween_property(self, "grey_light", 0.3, 1.8)
	await wait(1.8)
	await line("make_a_wish")
	phase = "candles"
	locked = false


func _candle_tap(p: Vector2) -> void:
	for k in candles.size():
		var c: Dictionary = candles[k]
		if c.lit and absf(p.x - c.x) < 24.0 and p.y > 300 and p.y < 520:
			c.lit = false
			Audio.sfx("puff")
			_room_light()
			var left := candles.filter(func(cc): return cc.lit).size()
			if left == 0:
				if relights < 2:
					relights += 1
					_relight(c)
				else:
					_wish()
			return


## Each candle that goes out takes some of the light with it.
func _room_light() -> void:
	var out := candles.filter(func(cc): return not cc.lit).size()
	if _room_tw:
		_room_tw.kill()
	_room_tw = create_tween()
	_room_tw.tween_property(self, "candle_dark", lerpf(ROOM_DIM, 1.0, float(out) / candles.size()), 0.45)


func _relight(c: Dictionary) -> void:
	await wait(0.7)
	c.lit = true
	_room_light()
	Audio.sfx("whoosh", -4, 1.5)
	if relights == 1:
		line_bg("trick_candle")
	else:
		line_bg("doesnt_want_to_leave")


func _wish() -> void:
	phase = "wish"
	locked = true
	var tw := create_tween()
	tw.tween_property(self, "black", 1.0, 0.5)
	await wait(1.5)
	await line("what_did_you_wish")
	await wait(1.5)
	Audio.sfx("heartbeat")
	await wait(1.0)
	Game.complete(IDX)
	Game.goto("finale")


func _is_dark() -> bool:
	if phase == "intro" or phase == "cute":
		return false
	return not (phase == "fail" and song == "karaoke")


func _beat() -> float:
	if phase == "cute" or phase == "dark":
		return Audio.song_pos * bpm / 60.0
	if phase != "intro":
		# Mikake has stopped dancing (with a little twitch while she glitches)
		return frozen_beat + (randf_range(-0.15, 0.15) if mal_glitch > 0.0 else 0.0)
	return t * 2.0


# ------------------------------------------------------------------ drawing


func paint_back() -> void:
	var dark := _is_dark()
	_baked_dark = int(dark)
	var sky := Color(0.1, 0.08, 0.22) if not dark else Color(0.1, 0.02, 0.04)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), sky)
	# back wall glow
	pen.draw_rect(Rect2(-2000, 330, W + 4000, 170), sky.lightened(0.06))
	# big LED screens either side
	for sx in [40.0, 990.0]:
		Crayon.rect(pen, Rect2(sx, 110, 250, 300), Crayon.INK, 6, Color(0.05, 0.05, 0.08), 10 + int(sx))
		Crayon.rect(pen, Rect2(sx - 10, 410, 270, 22), Crayon.INK, 4, Crayon.GREY.darkened(0.3), 11 + int(sx))
	# lighting truss
	Crayon.rect(pen, Rect2(-40, 52, W + 80, 26), Crayon.INK, 4, Crayon.GREY.darkened(0.2), 20)
	for k in 14:
		var x := 30.0 + k * 94.0
		Crayon.line(pen, Vector2(x, 54), Vector2(x + 47, 76), Crayon.INK.lightened(0.2), 3, 21 + k, 0.3)
	# the stage floor with an LED edge
	var stage := PackedVector2Array([Vector2(120, 488), Vector2(1160, 488), Vector2(1320, 620), Vector2(-40, 620)])
	Crayon.poly(pen, stage, Crayon.INK, 5, Color(0.16, 0.14, 0.24) if not dark else Color(0.14, 0.05, 0.07), 30)
	Crayon.line(pen, Vector2(120, 492), Vector2(1160, 492), TEAL if not dark else Crayon.RED.darkened(0.3), 6, 31)
	# speaker stacks
	for sx in [60.0, 1140.0]:
		Crayon.rect(pen, Rect2(sx, 440, 80, 110), Crayon.INK, 4, Color(0.12, 0.12, 0.15), 40 + int(sx))
		Crayon.circle(pen, Vector2(sx + 40, 475), 22, Crayon.INK, 3, Color(0.2, 0.2, 0.25), 41 + int(sx))
		Crayon.circle(pen, Vector2(sx + 40, 525), 14, Crayon.INK, 3, Color(0.2, 0.2, 0.25), 42 + int(sx))


func paint() -> void:
	var dark := _is_dark()
	if int(dark) != _baked_dark:
		refresh_back()
	var beat := _beat()
	if gloom <= 0.0:
		_lights(beat, dark)
	_screens(beat, dark)
	if gloom > 0.0:
		# the grey verse: nothing left but her in the red spotlight, the red stage lights and the
		# glow sticks
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, gloom))
		_lights(beat, dark)
	# Hatsune Mikake herself
	var sing := false
	if phase == "cute" or phase == "dark":
		var now: float = Audio.song_pos
		for i in range(maxi(0, _lo - 2), mini(chart.size(), _lo + 4)):
			var nt := float(chart[i][0])
			if now >= nt and now <= nt + float(chart[i][1]):
				sing = true
				break
	var dk := 1.0 if dark else 0.0
	var feet := MIKAKE_FEET
	if mal_glitch > 0.0:
		feet += Vector2(randf_range(-8, 8), randf_range(-3, 3)) * mal_glitch
	var glitch := 0.18 if phase == "dark" else mal_glitch
	if grey_light > 0.0:
		# one red spotlight on the empty performance
		var top := Vector2(640, -20)
		Crayon.poly(pen, PackedVector2Array([top + Vector2(-40, 0), top + Vector2(40, 0), MIKAKE_FEET + Vector2(170, 20), MIKAKE_FEET + Vector2(-170, 20)]), Color(0, 0, 0, 0), 0.0, Color(0.95, 0.22, 0.25, 0.16 * grey_light), 4460)
		Crayon.ellipse(pen, MIKAKE_FEET + Vector2(0, 14), Vector2(170, 26), Color(0, 0, 0, 0), 0.0, Color(0.95, 0.25, 0.28, 0.22 * grey_light), 4461)
	# a dance move in a solo (or in the red song, something worse)
	var spin := 1.0
	var lean := 0.0
	var mbeat := beat
	var slump := broken
	var shown := true
	if dance != "":
		var f := clampf(dance_t / dance_len, 0.0, 1.0)
		var hop := sin(f * PI)
		match dance:
			"pirouette":
				spin = cos(f * TAU * 2.0)
				feet.y -= hop * 16.0
				mbeat = 0.5
			"axel":
				spin = cos(f * TAU * 3.0)
				feet.y -= hop * 140.0
				mbeat = 0.5
			"leap":
				feet.y -= hop * 120.0
				mbeat = 0.5
			"slide":
				feet.x += hop * 190.0 * dance_dir
				lean = hop * 0.16 * dance_dir
			"break":
				mbeat = beat + dance_t * 7.0
			"twitch":
				# violent jerks, a few times a second
				glitch = 1.0
				if fmod(dance_t * 9.0, 1.0) < 0.45:
					feet += Vector2(randf_range(-14, 14), randf_range(-5, 3))
					lean = randf_range(-0.14, 0.14)
			"slump":
				# she folds over, switches off... and is jerked back up to keep singing
				if f < 0.75:
					slump = maxf(broken, sin(f / 0.75 * PI * 0.5) * 0.85)
				else:
					feet.x += randf_range(-6, 6)
			"tilt":
				# her whole body tips over, much too far, shaking, then snaps back
				lean = dance_dir * (smoothstep(0.0, 0.5, f) * 0.55 if f < 0.85 else 0.0) + sin(t * 47.0) * 0.025
			"flicker":
				# the signal keeps dropping out
				glitch = 1.0
				shown = fmod(dance_t * 13.0, 1.0) > 0.45
				if fmod(dance_t * 5.0, 1.0) < 0.3:
					feet.x += randf_range(-22, 22)
		if feet.y < MIKAKE_FEET.y - 2.0:
			var up := clampf((MIKAKE_FEET.y - feet.y) / 160.0, 0.0, 1.0)
			Crayon.ellipse(pen, Vector2(feet.x, MIKAKE_FEET.y + 4), Vector2(60.0 * (1.0 - up * 0.5), 10), Color(0, 0, 0, 0), 0.0, Color(0, 0, 0, 0.35 * (1.0 - up * 0.5)), 4462)
	if shown:
		draw_mikake(pen, feet, 330.0, mbeat, dk, sing and slump < 0.5, 600, glitch, slump, spin_ang if leek_spin > 0.0 else NAN, spin, lean)
	if leek_spin > 0.0:
		# a ring of little leeks spinning round her
		var fade := clampf(leek_spin, 0.0, 1.0)
		for k in 8:
			var a := t * 2.2 + k * TAU / 8.0
			_mini_leek(MIKAKE_FEET + Vector2(0, -190) + Vector2(cos(a) * 250.0, sin(a) * 120.0), spin_ang * 0.6 + k, 46.0 * fade)
	for sm in smoke:
		Crayon.disc(pen, sm.p, 14.0 + sm.t * 10.0, Color(0.55, 0.55, 0.6, 0.35 * (1.0 - sm.t / 3.0)))
	for sp in sparks:
		var c := Color(1, 0.95, 0.5) if int(sp.t * 20.0) % 2 == 0 else Color(0.6, 0.95, 1.0)
		pen.draw_rect(Rect2(sp.p - Vector2(2.5, 2.5), Vector2(5, 5)), c)
	_crowd(beat, dark)
	if candle_dark > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, candle_dark))
	# the birthday cake for the wish
	if cake_in > 0.0:
		_cake()
	if pads_k > 0.0 and phase in ["intro", "cute", "dark", "fail", "malfunction"]:
		_targets(song == "karaoke_dark")
		if phase == "cute" or phase == "dark":
			_notes(Audio.song_pos, song == "karaoke_dark")
	if black > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, black))


func paint_top() -> void:
	if phase == "grey":
		_grey_lyrics()
	if phase == "cute" or phase == "dark" or phase == "fail":
		var dark := song == "karaoke_dark"
		if phase != "fail":
			_lyrics(Audio.song_pos)
		hud("SCORE: %d" % score, Crayon.WHITE)
		Crayon.text(pen, Vector2(W - 24, 170 if Narrator.is_active() else 90), "COMBO %d" % combo, 30, Crayon.YELLOW if not dark else Color(1, 0.35, 0.35), 2, 4300, Crayon.title_font())
		_voltage(dark)
		for pp in pops:
			var a := clampf(1.0 - pp.t / float(pp.get("life", 0.7)), 0.0, 1.0)
			Crayon.text(pen, pp.p + Vector2(0, -pp.t * 40.0), pp.txt, 42, Color(pp.col, a), 1, 4310, Crayon.title_font(), 0.5, false)
		var now: float = Audio.song_pos
		if phase == "fail":
			pass
		elif phase == "cute" and _lo == 0 and now < 6.0:
			_banner("TAP WHEN A RING LANDS!", 140.0, Crayon.YELLOW)
		elif _lo > 0 and _free_time():
			if not dark:
				_banner("SOLO! TAP TO MAKE HER DANCE!", 140.0, TEAL.lightened(0.3))
			elif fmod(t * 3.0, 1.0) < 0.8:
				_banner("ERROR: SONG WILL REPEAT FOREVER", 140.0, Color(1, 0.3, 0.3))
	if fail_k > 0.0:
		var a := fail_k
		pen.draw_rect(Rect2(-2000, 246, W + 4000, 150), Color(0, 0, 0, 0.6 * a))
		Crayon.text(pen, Vector2(640, 306), "SONG FAILED", 84, Color(1, 0.35, 0.42, a), 1, 4480, Crayon.title_font(), 0.5, false)
		Crayon.text(pen, Vector2(640, 368), "the voltage ran out", 30, Color(1, 1, 1, 0.85 * a), 1, 4481, null, 0.3, false)
	if phase == "candles":
		_banner("TAP THE CANDLES TO BLOW THEM OUT!", 150.0, Crayon.YELLOW)


func _banner(s: String, y: float, col: Color) -> void:
	var size := 40
	var w := Crayon.title_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if w > W - 120.0:
		size = int(size * (W - 120.0) / w)
		w = Crayon.title_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	pen.draw_rect(Rect2(640 - w * 0.5 - 24, y - 30, w + 48, 60), Color(0, 0, 0, 0.5))
	Crayon.text(pen, Vector2(640, y), s, size, col, 1, 4320, Crayon.title_font())


func _voltage(dark: bool) -> void:
	var r := Rect2(100, 24, 280, 26)
	# running low: it flashes (if it runs out, the song fails)
	var low := voltage < 0.25 and phase != "fail"
	var lab := Crayon.WHITE if not (low and fmod(t * 4.0, 1.0) < 0.5) else Color(1, 0.4, 0.4)
	Crayon.text(pen, Vector2(r.position.x, r.end.y + 20), "VOLTAGE  LOW!" if low else "VOLTAGE", 22, lab, 0, 4330, null, 0.3, false)
	pen.draw_rect(r, Color(0, 0, 0, 0.55))
	var col := TEAL if not dark else Color(0.9, 0.2, 0.25)
	if voltage > 0.75 and not dark:
		col = TEAL.lerp(Crayon.YELLOW, 0.5 + 0.5 * sin(t * 8.0))
	if low:
		col = col.lerp(Color(1, 0.15, 0.2), 0.5 + 0.5 * sin(t * 12.0))
	pen.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2((r.size.x - 6) * voltage, r.size.y - 6)), col)
	Crayon.rect(pen, r, Crayon.WHITE, 3, Color(0, 0, 0, 0), 4331)


## Spotlight beams swinging to the beat (cheap: one quad each).
func _lights(beat: float, dark: bool) -> void:
	for k in 4:
		var top := Vector2(220.0 + k * 280.0, 70)
		var sw := sin(beat * PI * 0.5 + k * 1.3) * 160.0
		if dark:
			sw = sin(t * 0.3 + k) * 30.0
		var c := [TEAL, Crayon.PINK, Crayon.YELLOW, TEAL][k] as Color
		if dark:
			c = Color(0.8, 0.1, 0.12)
		c.a = 0.1 if not dark else 0.07
		var q := PackedVector2Array([top + Vector2(-10, 0), top + Vector2(10, 0), Vector2(top.x + sw + 90, 500), Vector2(top.x + sw - 90, 500)])
		pen.draw_primitive(q, PackedColorArray([c, c, c, c]), PackedVector2Array())
		Crayon.disc(pen, top + Vector2(0, 6), 12, c.lightened(0.5) if not dark else Color(0.9, 0.2, 0.2))


func _mini_leek(c: Vector2, ang: float, len_: float) -> void:
	if len_ < 4.0:
		return
	var d := Vector2(cos(ang), sin(ang)) * len_ * 0.5
	Crayon.line(pen, c - d, c, Color(0.97, 0.97, 0.92), len_ * 0.2, 640)
	Crayon.line(pen, c, c + d, Crayon.GREEN, len_ * 0.17, 641)
	Crayon.line(pen, c + d * 0.4, c + d * 1.05 + d.orthogonal() * 0.3, Crayon.GREEN.darkened(0.1), len_ * 0.12, 642)


## The LED screens: equaliser bars and a heart, or glitchy errors in the dark verse.
func _screens(beat: float, dark: bool) -> void:
	for sx in [40.0, 990.0]:
		var r := Rect2(sx + 12, 122, 226, 276)
		if err_text != "":
			for k in 9:
				var y := r.position.y + fmod(k * 37.0 + t * 140.0, r.size.y - 10.0)
				pen.draw_rect(Rect2(r.position.x, y, r.size.x, 4), Color(0.5, 0.5, 0.55, 0.35))
			var blink := not err_text.begins_with("NO") and fmod(t * 4.0, 1.0) < 0.25
			if not blink:
				# same bold screen font as AGAIN, and no backwards crayon letters on an error screen
				var rows := err_text.split("\n")
				var big := 0
				for row in rows:
					big = maxi(big, row.length())
				var fs := 46 if big <= 6 else 34
				for i in rows.size():
					var ry := r.get_center().y + (i - (rows.size() - 1) * 0.5) * fs * 1.1
					Crayon.text(pen, Vector2(r.get_center().x, ry), rows[i], fs, Color(1, 0.3, 0.3), 1, 4420 + int(sx) + i, Crayon.title_font(), 0.5, false)
			continue
		if leek_spin > 0.0 and not dark:
			# the screens join in
			_mini_leek(r.get_center() + Vector2(0, -16), spin_ang * (1.0 if sx < 500.0 else -1.0), 170.0)
			Crayon.text(pen, Vector2(r.get_center().x, r.end.y - 34), "LEEK SPIN!", 34, Crayon.YELLOW, 1, 4405 + int(sx), Crayon.title_font(), 0.5, false)
			continue
		if not dark:
			for k in 9:
				var hgt := (0.3 + 0.7 * absf(sin(beat * PI * 0.5 + k * 0.9 + sx))) * 150.0
				var c: Color = [TEAL, Crayon.PINK, TEAL.lightened(0.3)][k % 3]
				pen.draw_rect(Rect2(r.position.x + 8 + k * 24, r.end.y - 10 - hgt, 18, hgt), Color(c, 0.85))
			Crayon.text(pen, Vector2(r.get_center().x, r.position.y + 40), "MIKAKE", 30, Crayon.WHITE, 1, 4400 + int(sx), Crayon.title_font())
		else:
			var glitch := fmod(t * 5.0 + sx, 1.0) < 0.3
			for k in 7:
				var y := r.position.y + fmod(k * 41.0 + t * 90.0, r.size.y - 20.0)
				pen.draw_rect(Rect2(r.position.x, y, r.size.x * (0.3 + 0.7 * fmod(k * 0.37 + t, 1.0)), 6), Color(0.6, 0.1, 0.12, 0.6))
			Crayon.text(pen, r.get_center() + Vector2(8 if glitch else 0, 0), "ERROR" if glitch else "AGAIN", 46, Color(1, 0.25, 0.25), 1, 4410 + int(sx), Crayon.title_font())


## The two targets beside her, A on the left and D on the right, each at the end of its lane.
## They light up when pressed.
func _targets(dark: bool) -> void:
	var now: float = Audio.song_pos
	var hint := phase == "intro" or (phase == "cute" and _lo == 0 and now < 8.0)
	var pulse := pow(1.0 - fmod(maxf(_beat(), 0.0), 1.0), 3.0) if phase == "cute" or phase == "dark" else 0.0
	for lane in 2:
		var c: Vector2 = TARGETS[lane]
		var col: Color = LANE_COL[lane]
		if dark:
			col = col.lerp(Color(0.85, 0.1, 0.14), 0.6)
		# the lane the notes come along
		var x0: float = NOTE_FROM[lane]
		var lane_r := Rect2(minf(x0, c.x), c.y - 34, absf(c.x - x0), 68)
		pen.draw_rect(lane_r, Color(col, 0.13 * pads_k))
		pen.draw_line(Vector2(lane_r.position.x, c.y - 34), Vector2(lane_r.end.x, c.y - 34), Color(col, 0.35 * pads_k), 2.0)
		pen.draw_line(Vector2(lane_r.position.x, c.y + 34), Vector2(lane_r.end.x, c.y + 34), Color(col, 0.35 * pads_k), 2.0)
		var fl: float = pad_flash[lane]
		var r := TARGET_R * (1.0 + 0.06 * pulse - 0.1 * fl)
		Crayon.disc(pen, c, TARGET_R + 16.0, Color(col, (0.2 + 0.4 * fl) * pads_k))
		Crayon.circle(pen, c, r, Color(1, 1, 1, pads_k), 7, Color(col.darkened(0.35).lerp(col.lightened(0.45), fl), 0.9 * pads_k), 470 + lane)
		Crayon.text(pen, c + Vector2(0, 2), PAD_KEY[lane], 46, Color(1, 1, 1, pads_k), 1, 474 + lane, Crayon.title_font())
		if hint:
			var hx := c.x + (-150.0 if lane == 0 else 150.0)
			Crayon.text(pen, Vector2(hx, c.y + 70), "tap this side", 26, Crayon.WHITE, 1, 476 + lane, null, 0.3, false)
			Crayon.text(pen, Vector2(hx, c.y + 100), "or press " + PAD_KEY[lane], 24, Color(1, 1, 1, 0.75), 1, 478 + lane, null, 0.3, false)
	for b in bursts:
		var f: float = b.t / 0.35
		Crayon.circle(pen, b.p, TARGET_R + f * 50.0, Color(b.col, 1.0 - f), 7, Color(0, 0, 0, 0), 620)


## The notes: big music notes coming in along each lane, reaching the target just as they're due.
func _notes(now: float, dark: bool) -> void:
	for i in range(_lo, chart.size()):
		var nt := float(chart[i][0])
		if nt - now > APPEAR:
			break
		if hits.has(i):
			continue
		var lane: int = _lane[i]
		var k := 1.0 - (nt - now) / APPEAR
		var c: Vector2 = TARGETS[lane]
		var p := Vector2(lerpf(float(NOTE_FROM[lane]), c.x, k), c.y)
		var col: Color = LANE_COL[lane]
		if dark:
			col = col.lerp(Color(0.85, 0.1, 0.14), 0.5)
		var a := clampf(k * 6.0, 0.0, 1.0)
		if k > 1.0:
			# late: it carries on past the target, fading
			a = clampf(1.0 - (k - 1.0) * 5.0, 0.0, 1.0)
		_note_icon(p, col, a, 500 + i % 50)


## A big crayon eighth note; p = the middle of its head.
func _note_icon(p: Vector2, col: Color, a: float, sd: int) -> void:
	var ink := Color(Crayon.INK, a)
	var fill := Color(col.lightened(0.15), a)
	Crayon.ellipse(pen, p, Vector2(24, 18), ink, 4, fill, sd)
	var stem := p + Vector2(20, 0)
	pen.draw_line(stem, stem + Vector2(0, -66), ink, 9.0)
	pen.draw_line(stem, stem + Vector2(0, -66), fill, 5.0)
	var flag := PackedVector2Array([stem + Vector2(0, -66), stem + Vector2(26, -44), stem + Vector2(20, -24), stem + Vector2(4, -42)])
	Crayon.poly(pen, flag, ink, 3, fill, sd + 50)
	Crayon.disc(pen, p + Vector2(-8, -6), 5, Color(1, 1, 1, 0.7 * a))


## The crowd at the front of the stage, glow sticks up. In the dark verse they stop and stare.
func _crowd(beat: float, dark: bool) -> void:
	var stick := TEAL.lightened(0.2) if not dark else Color(0.95, 0.15, 0.2)
	if leek_spin > 0.0 and not dark:
		stick = Crayon.GREEN.lightened(0.25)
	# in the grey verse, in the dark, they hold their red glow sticks up, swaying slowly
	var grey := gloom > 0.3
	for k in 16:
		var x := 40.0 + k * 80.0 + (20.0 if k % 2 == 1 else 0.0)
		var y := H + 6.0 - (k % 3) * 8.0 - crowd_k * 26.0
		var jump := absf(sin(beat * PI + k * 0.7)) * 10.0 if not dark else 0.0
		var head := Vector2(x, y - 28.0 - jump)
		var ang := sin(beat * PI + k * 0.6) * 0.55 if not dark else (k % 3 - 1) * 0.08
		if grey:
			ang = sin(t * 0.9 + k * 0.7) * 0.35
		var hand := head + Vector2(22, 10)
		var tip := hand + Vector2(sin(ang), -cos(ang)) * 70.0
		if grey:
			pen.draw_line(hand, tip, Color(stick, 0.12), 34.0)
		pen.draw_line(hand, tip, Color(stick, 0.35), 14.0)
		pen.draw_line(hand, tip, stick, 6.0)
		pen.draw_line(hand + Vector2(0, -6), tip.lerp(hand, 0.35), Color(1, 1, 1, 0.7), 2.0)
		Crayon.disc(pen, head, 30.0, Color(0.06, 0.05, 0.1))
		if dark and crowd_k > 0.2 and not grey:
			# they just watch
			Crayon.disc(pen, head + Vector2(-9, -4), 4.0, Color(1, 1, 1, 0.85))
			Crayon.disc(pen, head + Vector2(9, -4), 4.0, Color(1, 1, 1, 0.85))


## A proper birthday cake: pink sponge, white icing with sprinkles, a candle in every colour.
## It's lit by its own candles, so it gets darker as they go out.
func _cake() -> void:
	var base := Vector2(640, 560 + (1.0 - cake_in) * 420)
	var shade := clampf((candle_dark - ROOM_DIM) / (1.0 - ROOM_DIM), 0.0, 1.0) * 0.9
	var ink := Crayon.INK
	var white := Crayon.WHITE.darkened(shade)
	var body := Rect2(base + Vector2(-250, -140), Vector2(500, 140))
	Crayon.ellipse(pen, base + Vector2(0, 2), Vector2(300, 24), ink, 4, Color(0.9, 0.9, 0.95).darkened(shade), 296)
	Crayon.rect(pen, body, ink, 6, Color(1.0, 0.7, 0.8).darkened(shade), 300)
	Crayon.poly(pen, Crayon.icing(body, 7), ink, 3, white, 301)
	# sprinkles on the icing
	for k in 26:
		var sp := Vector2(body.position.x + 16 + fmod(k * 97.3, body.size.x - 32), body.position.y + 6 + fmod(k * 5.3, 9.0))
		var d := Vector2(cos(k * 1.7), sin(k * 1.7)) * 5.0
		pen.draw_line(sp - d, sp + d, (Crayon.RAINBOW[k % 7] as Color).darkened(shade), 3.5)
	# icing blobs round the bottom
	for k in 13:
		Crayon.disc(pen, Vector2(body.position.x + 20 + k * 38.3, base.y - 7), 13, white)
	Crayon.text(pen, body.get_center() + Vector2(0, 2), "HAPPY BIRTHDAY", 36, Crayon.RED.darkened(shade), 1, 302, Crayon.title_font())
	Crayon.text(pen, body.get_center() + Vector2(0, 38), "CHUMBO", 28, Crayon.BLUE.darkened(shade), 1, 303, Crayon.title_font())
	for k in candles.size():
		var c: Dictionary = candles[k]
		var cp := Vector2(c.x, body.position.y + 2)
		Crayon.rect(pen, Rect2(cp + Vector2(-7, -58), Vector2(14, 58)), ink, 3, (Crayon.RAINBOW[k % 7] as Color).darkened(shade), 310 + k)
		for j in 3:
			pen.draw_line(cp + Vector2(-5, -12 - j * 16), cp + Vector2(5, -19 - j * 16), Color(1, 1, 1, 0.8).darkened(shade), 3.0)
		if c.lit:
			Crayon.disc(pen, cp + Vector2(0, -72), 28, Color(1, 0.85, 0.4, 0.16))
			Crayon.flame(pen, cp + Vector2(0, -72), 12, 330 + k)
		else:
			Crayon.path(pen, PackedVector2Array([cp + Vector2(0, -62), cp + Vector2(6, -78), cp + Vector2(-4, -94), cp + Vector2(4, -108)]), Color(0.7, 0.7, 0.7, 0.6), 3, 350 + k)


func _lyrics(now: float) -> void:
	# the current line = the line of the next syllable still to finish
	var cur_line := -1
	for i in range(maxi(0, _lo - 3), chart.size()):
		if float(chart[i][0]) + float(chart[i][1]) >= now - 0.3:
			cur_line = int(chart[i][4])
			break
	if cur_line < 0:
		pen.draw_rect(Rect2(150, LYRIC_Y - 34, W - 300, 66), Color(0, 0, 0, 0.55))
		return
	var idx: Array = []
	var parts := PackedStringArray()
	for i in range(maxi(0, _lo - 20), mini(chart.size(), _lo + 30)):
		if int(chart[i][4]) == cur_line:
			idx.append(i)
			var txt := String(chart[i][2])
			parts.append(txt if txt.ends_with("\n") else txt + (" " if bool(chart[i][3]) else ""))
	var font := Crayon.body()
	var size := 40
	var lh := 50.0
	var rows := Narrator.lyric_rows(parts)
	var top_y := LYRIC_Y - (rows.size() - 1) * lh
	pen.draw_rect(Rect2(150, top_y - 34, W - 300, 66 + (rows.size() - 1) * lh), Color(0, 0, 0, 0.55))
	var dark := phase == "dark"
	for ri in rows.size():
		var row_text := ""
		for j in range(rows[ri][0], rows[ri][1]):
			row_text += parts[j].trim_suffix("\n")
		var x := 640.0 - font.get_string_size(row_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
		var y := top_y + ri * lh
		for j in range(rows[ri][0], rows[ri][1]):
			var i: int = idx[j]
			var sung := float(chart[i][0]) <= now
			var col := (TEAL.lightened(0.25) if not dark else Color(1, 0.3, 0.3)) if sung else Crayon.WHITE
			var w := Crayon.text(pen, Vector2(x, y), parts[j].trim_suffix("\n"), size, col, 0, 400 + i % 60, null, 0.6 if not dark else 1.5, false)
			if sung and float(chart[i][0]) + float(chart[i][1]) > now:
				Crayon.disc(pen, Vector2(x + w * 0.4, y - 40 - absf(sin(now * 10.0)) * 12), 9, TEAL if not dark else Crayon.RED)
			x += w


## The words of the grey verse, in grey.
func _grey_lyrics() -> void:
	var ls := Audio.lyric_state()
	if ls.is_empty():
		return
	var parts: PackedStringArray = ls.parts
	var sung: int = ls.sung
	var font := Crayon.body()
	var size := 38
	var lh := 48.0
	var rows := Narrator.lyric_rows(parts)
	var top_y := LYRIC_Y - (rows.size() - 1) * lh
	pen.draw_rect(Rect2(150, top_y - 34, W - 300, 66 + (rows.size() - 1) * lh), Color(0, 0, 0, 0.55))
	for ri in rows.size():
		var row_text := ""
		for i in range(rows[ri][0], rows[ri][1]):
			row_text += parts[i].trim_suffix("\n")
		var x := 640.0 - font.get_string_size(row_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
		for i in range(rows[ri][0], rows[ri][1]):
			var col := Color(0.85, 0.85, 0.88) if i < sung else Color(0.5, 0.5, 0.54)
			x += Crayon.text(pen, Vector2(x, top_y + ri * lh), parts[i].trim_suffix("\n"), size, col, 0, 4470 + i, null, 0.4, false)


const MIKAKE_FEET := Vector2(640, 540)


## For the finale cast: since the karaoke she's switched off, still smoking a little, with
## the odd spark.
static func draw_mascot(ci: CanvasItem, feet: Vector2, sc: float, tm: float, broken: float = 1.0) -> void:
	var h := 210.0 * sc
	draw_mikake(ci, feet, h, tm * 2.0, 0.0, false, 9100, 0.0, broken)
	if broken <= 0.0:
		return
	var head := mikake_head(feet, h, broken)
	# a hand-written sign taped to her
	var lean := 0.32 * broken
	var chest := feet + Vector2(sin(lean), -cos(lean)) * h * 0.52 + Vector2(0, h * 0.05 * broken)
	var sign := Rect2(chest - Vector2(h * 0.3, h * 0.11), Vector2(h * 0.6, h * 0.22))
	Crayon.rect(ci, sign, Crayon.INK, 2, Color(1, 1, 0.94), 9180)
	Crayon.line(ci, sign.position + Vector2(sign.size.x * 0.4, -3), sign.position + Vector2(sign.size.x * 0.6, -3), Color(0.8, 0.75, 0.6), 5, 9181)
	Crayon.text(ci, sign.get_center() + Vector2(0, -sign.size.y * 0.2), "OUT OF", int(h * 0.088), Crayon.RED, 1, 9182, Crayon.title_font(), 0.3, false)
	Crayon.text(ci, sign.get_center() + Vector2(0, sign.size.y * 0.24), "ORDER", int(h * 0.088), Crayon.RED, 1, 9183, Crayon.title_font(), 0.3, false)
	for k in 3:
		var ph := fmod(tm * 0.45 + k / 3.0, 1.0)
		var p := head + Vector2(sin(ph * 6.0 + k) * 8.0, -h * 0.1 - ph * h * 0.35)
		Crayon.disc(ci, p, h * (0.04 + ph * 0.07), Color(0.4, 0.4, 0.45, 0.5 * (1.0 - ph)))
	var sp := fmod(tm, 2.6)
	if sp < 0.4:
		for k in 6:
			var a := -PI + (k + 0.5) * PI / 6.0
			var p := head + Vector2(cos(a), sin(a)) * (h * 0.08 + sp * h * 0.5) + Vector2(0, sp * sp * h * 0.8)
			ci.draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 0.95, 0.5) if k % 2 == 0 else Color(0.6, 0.95, 1.0))


## Where her head is, when she's slumped over by `broken` (0..1).
static func mikake_head(feet: Vector2, h: float, broken: float) -> Vector2:
	var a := 0.32 * broken
	return feet + Vector2(sin(a), -cos(a)) * h * 0.86 + Vector2(0, h * 0.05 * broken)


## Hatsune Mikake: teal twin-tails down to the floor, headset, grey top, teal tie, a leek.
## h = height from feet to the top of her head, beat = dance phase (in beats), dark 0..1,
## glitch = how often her hair and leek jump around (dark verse), broken = switched off
## (0..1: she slumps over, arms hanging, X eyes), twirl = leek-spin angle (NAN = not spinning),
## spin = how far round she's turned (1 = facing us, -1 = her back... drawn as a mirror image),
## lean = tilting over (radians).
static func draw_mikake(ci: CanvasItem, feet: Vector2, h: float, beat: float, dark: float, sing: bool, sd: int, glitch: float = 0.0, broken: float = 0.0, twirl: float = NAN, spin: float = 1.0, lean: float = 0.0) -> void:
	var lively := (1.0 - dark * 0.85) * (1.0 - broken)
	var bob := absf(sin(beat * PI)) * h * 0.025 * lively
	var sway := sin(beat * PI * 0.5) * 0.06 * lively
	var glitching := glitch > 0.0 and fmod(beat * 1.37, 1.0) < glitch
	ci.draw_set_transform(feet + Vector2(0, h * 0.05 * broken), sway + 0.32 * broken + lean, Vector2(spin if absf(spin) > 0.04 else 0.04, 1.0))
	var ink := Crayon.INK
	var hair := TEAL.lerp(Color(0.3, 0.4, 0.42), dark * 0.5)
	var hr := h * 0.115
	var head := Vector2(0, -h * 0.86 - bob)
	var swing := sin(beat * PI) * h * 0.05 * lively
	# twin-tails, behind everything
	for side in [-1.0, 1.0]:
		var gx: float = side * h * 0.06 if glitching else 0.0
		var top := head + Vector2(side * hr * 0.95 + gx, -hr * 0.3)
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for k in 7:
			var f := k / 6.0
			var cx: float = top.x + side * h * 0.13 * sin(f * PI * 0.7) + swing * f * f
			var cy := lerpf(top.y, -h * 0.03, f)
			var hw := hr * (0.28 + 0.62 * sin(minf(f * 1.4, 1.0) * PI * 0.5) * (1.0 - f * 0.65))
			left.append(Vector2(cx - hw, cy))
			right.append(Vector2(cx + hw, cy))
		right.reverse()
		Crayon.poly(ci, left + right, ink, 3, hair, sd + int(side + 1))
		Crayon.rect(ci, Rect2(top - Vector2(hr * 0.28, hr * 0.22), Vector2(hr * 0.56, hr * 0.44)), ink, 2, Color(0.85, 0.2, 0.4), sd + 4 + int(side + 1))
	# legs and boots
	for side in [-1.0, 1.0]:
		var hip := Vector2(side * h * 0.045, -h * 0.4)
		var foot := Vector2(side * h * 0.06, -h * 0.015)
		Crayon.line(ci, hip, foot, ink, h * 0.04, sd + 10 + int(side + 1))
		Crayon.line(ci, hip, foot, SKIN, h * 0.028, sd + 12 + int(side + 1), 0.3)
		Crayon.line(ci, hip.lerp(foot, 0.5), foot, Color(0.1, 0.1, 0.13), h * 0.05, sd + 14 + int(side + 1))
		Crayon.line(ci, foot + Vector2(-h * 0.03, 0), foot + Vector2(h * 0.035, 0), TEAL, h * 0.018, sd + 16 + int(side + 1), 0.3)
	# skirt
	var skirt := PackedVector2Array([Vector2(-h * 0.07, -h * 0.49), Vector2(h * 0.07, -h * 0.49), Vector2(h * 0.115, -h * 0.37), Vector2(-h * 0.115, -h * 0.37)])
	Crayon.poly(ci, skirt, ink, 3, Color(0.15, 0.15, 0.2), sd + 20)
	Crayon.line(ci, Vector2(-h * 0.11, -h * 0.38), Vector2(h * 0.11, -h * 0.38), TEAL, 3, sd + 21, 0.3)
	# grey top + teal tie
	var top_pts := PackedVector2Array([Vector2(-h * 0.075, -h * 0.71), Vector2(h * 0.075, -h * 0.71), Vector2(h * 0.065, -h * 0.485), Vector2(-h * 0.065, -h * 0.485)])
	Crayon.poly(ci, top_pts, ink, 3, Color(0.78, 0.8, 0.83), sd + 22)
	Crayon.poly(ci, PackedVector2Array([Vector2(-h * 0.016, -h * 0.7), Vector2(h * 0.016, -h * 0.7), Vector2(h * 0.012, -h * 0.58), Vector2(0, -h * 0.555), Vector2(-h * 0.012, -h * 0.58)]), ink, 2, TEAL_DK.lightened(0.2), sd + 23)
	# arms: one on the hip, one waving the leek
	var sh_l := Vector2(-h * 0.08, -h * 0.69)
	var sh_r := Vector2(h * 0.08, -h * 0.69)
	var up := sin(beat * PI) * lively
	var hand_l := sh_l + Vector2(-h * 0.1, h * 0.12 - absf(up) * h * 0.06)
	var hand_r := sh_r + Vector2(h * 0.13, -h * 0.1 - up * h * 0.08)
	# switched off: both arms just hang
	hand_l = hand_l.lerp(sh_l + Vector2(-h * 0.03, h * 0.24), broken)
	hand_r = hand_r.lerp(sh_r + Vector2(h * 0.04, h * 0.24), broken)
	var spinning := not is_nan(twirl)
	if spinning:
		hand_r = sh_r + Vector2(h * 0.15, -h * 0.17)
	for arm in [[sh_l, hand_l], [sh_r, hand_r]]:
		var s0: Vector2 = arm[0]
		var s1: Vector2 = arm[1]
		var elbow := s0.lerp(s1, 0.45)
		Crayon.line(ci, s0, elbow, SKIN, h * 0.028, sd + 30)
		Crayon.line(ci, elbow, s1, Color(0.1, 0.1, 0.13), h * 0.045, sd + 31)
		Crayon.disc(ci, elbow, h * 0.024, TEAL)
		Crayon.disc(ci, s1, h * 0.022, SKIN)
	# the leek
	var la := -1.25 + up * 0.5
	if glitching:
		la += 1.6
	la = lerpf(la, 1.35, broken)
	if spinning:
		la = twirl
	var ldir := Vector2(cos(la), sin(la))
	# spinning, she holds it by the middle
	var grip := hand_r - ldir * h * 0.1 if spinning else hand_r
	var leek_top := grip + ldir * h * 0.24
	var white := Color(0.97, 0.97, 0.92).lerp(Color(0.6, 0.6, 0.55), dark * 0.5)
	var green := Crayon.GREEN.lerp(Color(0.35, 0.4, 0.3), dark * 0.6)
	Crayon.line(ci, grip - ldir * h * 0.04, grip + ldir * h * 0.12, white, h * 0.032, sd + 40)
	Crayon.line(ci, grip + ldir * h * 0.1, leek_top, green, h * 0.028, sd + 41)
	Crayon.line(ci, grip + ldir * h * 0.16, leek_top + ldir.rotated(0.5) * h * 0.06, green.darkened(0.1), h * 0.02, sd + 42)
	Crayon.line(ci, grip + ldir * h * 0.16, leek_top + ldir.rotated(-0.45) * h * 0.05, green.lightened(0.1), h * 0.02, sd + 43)
	# neck + head
	Crayon.line(ci, Vector2(0, -h * 0.71), Vector2(0, -h * 0.76 - bob), SKIN, h * 0.035, sd + 50, 0.3)
	Crayon.circle(ci, head, hr, ink, 3, SKIN, sd + 51)
	# hair on top with bangs
	var cap := PackedVector2Array()
	for k in 9:
		var a := PI + PI * k / 8.0
		cap.append(head + Vector2(cos(a), sin(a)) * hr * 1.08)
	cap.append(head + Vector2(hr * 1.02, hr * 0.05))
	cap.append(head + Vector2(hr * 0.62, -hr * 0.28))
	cap.append(head + Vector2(hr * 0.3, -hr * 0.05))
	cap.append(head + Vector2(0, -hr * 0.32))
	cap.append(head + Vector2(-hr * 0.3, -hr * 0.05))
	cap.append(head + Vector2(-hr * 0.62, -hr * 0.28))
	cap.append(head + Vector2(-hr * 1.02, hr * 0.05))
	Crayon.poly(ci, cap, ink, 3, hair, sd + 52)
	# face: big anime eyes (blank in the dark verse)
	for side in [-1.0, 1.0]:
		var e := head + Vector2(side * hr * 0.4, hr * 0.18)
		if broken > 0.5:
			# X X
			var d := hr * 0.2
			var xw := maxf(3.0, hr * 0.1)
			Crayon.line(ci, e + Vector2(-d, -d), e + Vector2(d, d), ink, xw, sd + 56 + int(side + 1), 0.3)
			Crayon.line(ci, e + Vector2(d, -d), e + Vector2(-d, d), ink, xw, sd + 58 + int(side + 1), 0.3)
		elif dark > 0.5:
			Crayon.ellipse(ci, e, Vector2(hr * 0.17, hr * 0.22), ink, 2, Crayon.WHITE, sd + 54 + int(side + 1))
		else:
			Crayon.oval(ci, e, Vector2(hr * 0.17, hr * 0.23), TEAL_DK)
			Crayon.disc(ci, e + Vector2(-hr * 0.05, -hr * 0.08), hr * 0.07, Crayon.WHITE)
			Crayon.disc(ci, head + Vector2(side * hr * 0.55, hr * 0.48), hr * 0.12, Color(1, 0.5, 0.6, 0.35))
	var m := head + Vector2(0, hr * 0.58)
	if dark > 0.5 or broken > 0.5:
		Crayon.line(ci, m + Vector2(-hr * 0.15, 0), m + Vector2(hr * 0.15, 0), ink, 3, sd + 60, 0.3)
	elif sing:
		Crayon.oval(ci, m, Vector2(hr * 0.12, hr * 0.15), Color(0.6, 0.15, 0.2))
	else:
		Crayon.path(ci, PackedVector2Array([m + Vector2(-hr * 0.18, -hr * 0.04), m + Vector2(0, hr * 0.08), m + Vector2(hr * 0.18, -hr * 0.04)]), ink, 3, sd + 61, 0.3)
	# headset with a little mic
	for side in [-1.0, 1.0]:
		Crayon.rect(ci, Rect2(head + Vector2(side * hr * 1.0 - hr * 0.13, -hr * 0.05), Vector2(hr * 0.26, hr * 0.42)), ink, 2, Color(0.15, 0.15, 0.18), sd + 62 + int(side + 1))
	Crayon.path(ci, PackedVector2Array([head + Vector2(-hr * 1.0, hr * 0.3), head + Vector2(-hr * 0.8, hr * 0.62), head + Vector2(-hr * 0.35, hr * 0.68)]), Color(0.15, 0.15, 0.18), 3, sd + 65, 0.3)
	Crayon.disc(ci, head + Vector2(-hr * 0.32, hr * 0.68), hr * 0.08, TEAL)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
