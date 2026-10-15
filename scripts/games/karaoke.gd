extends Screen
## Present 10: KARAOKE (sing-along rhythm game). Tap when each word reaches the circle.
## Halfway through, the song changes its mind about the words. Then: make a wish.

const IDX := 9
const SongData := preload("res://scripts/gen/song_data.gd")
const HIT_X := 260.0
const LANE_Y := 470.0
const SPEED := 330.0
const GOOD := 0.22
const PERFECT := 0.11

var chart: Array = []
var hits := {}
var song := ""
var phase := "intro"   # intro, cute, dark, candles, wish, done
var score := 0
var combo := 0
var best := 0
var judge := ""
var judge_t := 0.0
var bounce := 0.0
var end_time := 0.0
var candles: Array = []
var relights := 0
var black := 0.0
var crowd_k := 0.0
var cake_in := 0.0


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
	await say("The last present! It's karaoke time! Tap when each word reaches the circle, and sing your birthday song!")
	_start("karaoke")
	phase = "cute"
	locked = false


func _start(name: String) -> void:
	song = name
	chart = SongData.KARAOKE[name]
	hits.clear()
	var last: Array = chart[chart.size() - 1]
	end_time = float(last[0]) + float(last[1]) + 0.6
	Audio.play_music(name, 0.3, 0.0, false)


func press(p: Vector2) -> void:
	match phase:
		"cute", "dark":
			_tap()
		"candles":
			_candle_tap(p)


func _tap() -> void:
	var now: float = Audio.song_pos
	var best_i := -1
	var best_d := 99.0
	for i in chart.size():
		if hits.has(i):
			continue
		var d := absf(float(chart[i][0]) - now)
		if d < best_d:
			best_d = d
			best_i = i
	bounce = 1.0
	if best_i >= 0 and best_d <= GOOD:
		hits[best_i] = true
		combo += 1
		best = maxi(best, combo)
		if best_d <= PERFECT:
			score += 100 + combo * 5
			judge = "PERFECT!"
		else:
			score += 50 + combo * 2
			judge = "GOOD!"
		judge_t = 0.6
		Audio.sfx("key", -8, 1.5)
		if combo % 10 == 0:
			Audio.sfx("yay_small", -6)
	else:
		Audio.sfx("key", -14, 0.6)


func tick(dt: float) -> void:
	judge_t = maxf(0.0, judge_t - dt)
	bounce = maxf(0.0, bounce - dt * 4.0)
	if phase == "cute" or phase == "dark":
		var now: float = Audio.song_pos
		for i in chart.size():
			if not hits.has(i) and now - float(chart[i][0]) > GOOD:
				hits[i] = false
				combo = 0
				judge = "miss"
				judge_t = 0.4
		if now >= end_time:
			if phase == "cute":
				phase = "dark"
				_start("karaoke_dark")
				say_bg("Wait. Those aren't the words.", Narrator.DARK)
			else:
				_candles()
	if phase == "dark":
		crowd_k = minf(1.0, crowd_k + dt * 0.03)


func _candles() -> void:
	phase = "candles_wait"
	locked = true
	Audio.music_pitch(0.4, 2.5)
	await wait(2.5)
	Audio.stop_music(0.8)
	var tw := create_tween()
	tw.tween_property(self, "cake_in", 1.0, 1.0)
	await wait(1.0)
	await say("Make a wish, Chumbo. Blow out the candles.", Narrator.DARK)
	candles.clear()
	for k in 10:
		candles.append({"lit": true, "x": 440.0 + k * 44.0})
	phase = "candles"
	locked = false


func _candle_tap(p: Vector2) -> void:
	for k in candles.size():
		var c: Dictionary = candles[k]
		if c.lit and absf(p.x - c.x) < 24.0 and p.y > 300 and p.y < 520:
			c.lit = false
			Audio.sfx("puff")
			var left := candles.filter(func(cc): return cc.lit).size()
			if left == 0:
				if relights < 2:
					relights += 1
					_relight(c)
				else:
					_wish()
			return


func _relight(c: Dictionary) -> void:
	await wait(0.7)
	c.lit = true
	Audio.sfx("whoosh", -4, 1.5)
	if relights == 1:
		say_bg("Trick candle! Try again!")
	else:
		say_bg("It doesn't want to go out.", Narrator.DARK)


func _wish() -> void:
	phase = "wish"
	locked = true
	var tw := create_tween()
	tw.tween_property(self, "black", 1.0, 0.5)
	await wait(1.5)
	await say("What did you wish for?", Narrator.WHISPER)
	await wait(1.5)
	Audio.sfx("heartbeat")
	await wait(1.0)
	Game.complete(IDX)
	Game.goto("finale")


func _is_dark() -> bool:
	return phase != "intro" and phase != "cute"


func paint_back() -> void:
	var dark := _is_dark()
	_baked_dark = int(dark)
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.25, 0.1, 0.35) if not dark else Color(0.12, 0.02, 0.06))
	# curtains
	for side in [-1, 1]:
		var x0 := 0.0 if side < 0 else W - 170.0
		Crayon.rect(pen, Rect2(x0, 0, 170, H), Crayon.INK, 5, Crayon.RED.darkened(0.3 if not dark else 0.6), 10 + side)
		for k in 4:
			Crayon.line(pen, Vector2(x0 + 30 + k * 36, 0), Vector2(x0 + 30 + k * 36, H), Crayon.RED.darkened(0.5), 4, 20 + k + side * 5)
	# disco ball
	var db := Vector2(640, 90)
	Crayon.line(pen, Vector2(640, -10), db + Vector2(0, -40), Crayon.GREY, 3, 30)
	Crayon.circle(pen, db, 40, Crayon.INK, 4, Crayon.GREY.lightened(0.4), 31)
	if dark:
		Crayon.line(pen, db + Vector2(-20, -30), db + Vector2(10, 30), Crayon.INK, 3, 32)


func paint() -> void:
	var dark := _is_dark()
	if int(dark) != _baked_dark:
		refresh_back()
	var db := Vector2(640, 90)
	for k in 6:
		var a := t * 1.5 + k
		var sp := db + Vector2(cos(a) * 300, 220 + sin(a * 1.3) * 120)
		pen.draw_circle(sp, 10, Color(Crayon.RAINBOW[k], 0.35) if not dark else Color(1, 0.1, 0.1, 0.3))
	# host as the MC
	Host.draw(pen, Vector2(1000, 240), 70, 0.0 if not dark else 0.7, Narrator.is_active(), Vector2(-1, 0.4), 33)
	# you, singing
	var sing_bob := bounce * 10.0
	Crayon.person(pen, Vector2(300, 400 - sing_bob), 150, Crayon.WHITE, "o" if bounce > 0.3 else "happy", Crayon.GREEN, "wave", t * 3.0, 34, Color(1, 0.9, 0.78))
	Crayon.line(pen, Vector2(345, 300 - sing_bob), Vector2(320, 270 - sing_bob), Crayon.GREY, 6, 35)
	Crayon.circle(pen, Vector2(318, 264 - sing_bob), 9, Crayon.INK, 3, Crayon.GREY, 36)
	# lane + notes
	if phase == "cute" or phase == "dark":
		Crayon.line(pen, Vector2(180, LANE_Y), Vector2(W - 180, LANE_Y), Color(1, 1, 1, 0.4), 4, 40)
		Crayon.circle(pen, Vector2(HIT_X, LANE_Y), 38 + bounce * 6, Crayon.YELLOW, 6, Color(1, 1, 0.5, 0.15), 41)
		var now: float = Audio.song_pos
		for i in chart.size():
			var x := HIT_X + (float(chart[i][0]) - now) * SPEED
			if x < 150 or x > W - 160:
				continue
			var hit = hits.get(i, null)
			if hit == true:
				continue
			var col := Crayon.PINK if not dark else Color(0.6, 0.1, 0.15)
			if hit == false:
				col = Crayon.GREY
			Crayon.circle(pen, Vector2(x, LANE_Y), 30, Crayon.INK, 3, col, 50 + i % 40)
			Crayon.text(pen, Vector2(x, LANE_Y), String(chart[i][2]), 22, Crayon.WHITE, 1, 100 + i % 50, null, 0.3, false)
	# the crowd (they creep closer in the dark verse)
	var n := 9
	for k in n:
		var x := 200.0 + k * 110.0
		var h := 120.0 + crowd_k * 70.0 + (k % 3) * 10.0
		var mood := "happy" if not dark else ("wide" if crowd_k > 0.3 else "flat")
		var jump := absf(sin(t * 6.0 + k)) * 12.0 * (1.0 - crowd_k)
		Crayon.person(pen, Vector2(x, H + 70 + crowd_k * 30 - jump), h, Crayon.INK.lerp(Crayon.BLACK, 0.5), mood, Crayon.RAINBOW[k % 7] if not dark else Color(0, 0, 0, 0), "up" if not dark else "stand", t * 3.0, 200 + k, Color(0.85, 0.75, 0.7))
	# birthday cake for the wish
	if cake_in > 0.0:
		var base := Vector2(640, 560 + (1.0 - cake_in) * 400)
		Crayon.rect(pen, Rect2(base + Vector2(-260, -150), Vector2(520, 150)), Crayon.INK, 6, Crayon.PINK.darkened(0.2), 300)
		Crayon.poly(pen, Crayon.icing(Rect2(base + Vector2(-260, -150), Vector2(520, 150)), 7), Crayon.INK, 3, Crayon.WHITE, 301)
		for k in candles.size():
			var c: Dictionary = candles[k]
			var cp := Vector2(c.x, base.y - 150)
			Crayon.rect(pen, Rect2(cp + Vector2(-7, -60), Vector2(14, 60)), Crayon.INK, 3, Crayon.RAINBOW[k % 7], 310 + k)
			if c.lit:
				Crayon.flame(pen, cp + Vector2(0, -74), 12, 330 + k)
			else:
				Crayon.path(pen, PackedVector2Array([cp + Vector2(0, -64), cp + Vector2(6, -80), cp + Vector2(-4, -96), cp + Vector2(4, -110)]), Color(0.7, 0.7, 0.7, 0.6), 3, 350 + k)
	if black > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0, 0, 0, black))


func paint_top() -> void:
	if phase == "cute" or phase == "dark":
		pen.draw_rect(Rect2(170, 540, W - 340, 64), Color(0, 0, 0, 0.45))
		_lyrics(Audio.song_pos)
		hud("SCORE: %d" % score, Crayon.WHITE)
		Crayon.text(pen, Vector2(W - 24, 170 if Narrator.is_active() else 90), "COMBO: %d" % combo, 28, Crayon.YELLOW, 2, 4300)
		if judge_t > 0.0:
			var col := Crayon.YELLOW if judge == "PERFECT!" else (Crayon.GREEN if judge == "GOOD!" else Crayon.GREY)
			Crayon.text(pen, Vector2(HIT_X, LANE_Y - 80), judge, 40, col, 1, 4301, Crayon.title_font())
		if Audio.song_pos < 6.0 and phase == "cute":
			Crayon.text(pen, Vector2(640, 380), "TAP WHEN THE WORD HITS THE CIRCLE!", 34, Crayon.YELLOW, 1, 4302)
	if phase == "candles":
		Crayon.text(pen, Vector2(640, 140), "TAP THE CANDLES TO BLOW THEM OUT!", 40, Crayon.YELLOW, 1, 4310, Crayon.title_font())


func _lyrics(now: float) -> void:
	# find the current line (the line of the next upcoming syllable)
	var cur_line := -1
	for i in chart.size():
		if float(chart[i][0]) + float(chart[i][1]) >= now - 0.3:
			cur_line = int(chart[i][4])
			break
	if cur_line < 0:
		return
	var parts: Array = []
	for i in chart.size():
		if int(chart[i][4]) == cur_line:
			parts.append(i)
	var text_all := ""
	for i in parts:
		text_all += String(chart[i][2]) + (" " if bool(chart[i][3]) else "")
	var font := Crayon.body()
	var size := 40
	var x := 640.0 - font.get_string_size(text_all, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	var y := 575.0
	var dark := phase == "dark"
	for i in parts:
		var piece := String(chart[i][2]) + (" " if bool(chart[i][3]) else "")
		var sung := float(chart[i][0]) <= now
		var col := (Crayon.YELLOW if not dark else Color(1, 0.3, 0.3)) if sung else Crayon.WHITE
		var w := Crayon.text(pen, Vector2(x, y), piece, size, col, 0, 400 + i % 60, null, 0.6 if not dark else 1.5, false)
		if sung and float(chart[i][0]) + float(chart[i][1]) > now:
			Crayon.circle(pen, Vector2(x + w * 0.4, y - 40 - absf(sin(now * 10.0)) * 14), 9, Crayon.INK, 2, Crayon.RED, 450)
		x += w
