extends Screen
## The party room. Ten presents, one per game. The room gets... a little different
## every time you come back.

const Rocko := preload("res://scripts/games/rocko.gd")

var LINES := [
	["Everyone brought you a present! Ten presents, all for you! Start with number one!", Narrator.CUTE],
	["Wow, you're so good at birthdays! Open the next one!", Narrator.CUTE],
	["The guests are having so much fun. They don't want to leave.", Narrator.CUTE],
	["Did somebody turn down the lights? No? Okay.", Narrator.CUTE],
	["Don't mind the guests. They're only looking at you because they love you.", Narrator.CUTE],
	["Halfway there! Nobody has left the party yet. Nobody ever leaves.", Narrator.DARK],
	["Is the cake supposed to be warm? It's breathing a little. That's normal.", Narrator.DARK],
	["Three more presents. We are all so proud of you, Chumbo.", Narrator.DARK],
	["The candles have been burning for a very long time.", Narrator.DARK],
	["One more present. The last one. It's for you, and it's for us.", Narrator.DARK],
]
## Spelled out (not "%d") so each one gets a voice clip.
var OPEN_NEXT := [
	["Open present number one!", Narrator.CUTE], ["Open present number two!", Narrator.CUTE],
	["Open present number three!", Narrator.CUTE], ["Open present number four!", Narrator.CUTE],
	["Open present number five!", Narrator.CUTE], ["Open present number six!", Narrator.CUTE],
	["Open present number seven!", Narrator.CUTE], ["Open present number eight!", Narrator.CUTE],
	["Open present number nine!", Narrator.CUTE], ["Open present number ten!", Narrator.CUTE],
]

var opening := -1
var open_t := 0.0
var shake_i := -1
var shake_t := 0.0
var p := 0
var guests: Array = []


func enter() -> void:
	show_home = false
	remove_button("home")
	Narrator.top = true
	use_back_layer()
	p = Game.progress()
	Audio.play_music("hub" if p < 5 else "hub_dark")
	add_button("mute", Rect2(W - 92, 10, 76, 60), "", _mute, Crayon.WHITE)
	add_button("full", Rect2(W - 180, 10, 76, 60), "", _full, Crayon.WHITE)
	var n := 4 + p * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var spots := [300.0, 990.0, 1045.0, 250.0]
	for i in n:
		var behind := i >= 2
		var x := 0.0
		if behind:
			x = rng.randf_range(350, 500) if i % 2 == 0 else rng.randf_range(780, 935)
		else:
			x = spots[i]
		guests.append({
			"x": x,
			"y": 452.0 - (rng.randf_range(0, 40) if i >= 6 else 0.0) if behind else 525.0,
			"h": rng.randf_range(130, 165) * (rng.randf_range(1.0, 1.3) if i >= 6 else 1.0),
			"col": Crayon.RAINBOW[i % 7],
			"back": i >= 6,
			"seed": 1000 + i * 37,
		})
	guests.sort_custom(func(a, b): return a.y < b.y)
	_talk()


func _mute() -> void:
	Audio.toggle_mute()


func _full() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _talk() -> void:
	await wait(0.6)
	if Game.finale_seen:
		if Game.hub_lines_heard < 11:
			Game.hub_lines_heard = 11
			Game.save_game()
			await say("Happy birthday, Chumbo. See you tomorrow. It's your birthday tomorrow, too.", Narrator.DARK)
		if not Game.secret_done:
			say_bg("Psst. Chumbo. Tap the cake.", Narrator.WHISPER)
		else:
			say_bg("Pick any present you like. They're all yours. Forever.")
		return
	if p < LINES.size() and Game.hub_lines_heard < p:
		Game.hub_lines_heard = p
		Game.save_game()
		await say(LINES[p][0], LINES[p][1])
	elif p < LINES.size():
		say_bg(OPEN_NEXT[p][0], OPEN_NEXT[p][1])


func _present_rect(i: int) -> Rect2:
	var bw := 100.0
	var x := 34.0 + i * 122.0
	var y := 528.0
	if i == opening:
		y -= sin(clampf(open_t * 3.0, 0, 1) * PI * 0.5) * 20
	if i == next_index():
		y -= absf(sin(t * 4.0)) * 14.0
	return Rect2(x, y, bw, 100)


func next_index() -> int:
	for i in Game.GAMES.size():
		if not Game.done[i]:
			return i
	return -1


func press(pos: Vector2) -> void:
	if opening >= 0:
		return
	for i in Game.GAMES.size():
		if _present_rect(i).grow(12).has_point(pos):
			_open_present(i)
			return
	# after the credits the cake hides a secret
	if Game.finale_seen and Rect2(515, 100, 250, 310).has_point(pos):
		_open_secret()
		return
	# poking guests is allowed
	for g in guests:
		if absf(pos.x - g.x) < 30 and pos.y > g.y - g.h and pos.y < g.y:
			Audio.sfx("giggle" if p < 5 else "giggle_low", -4, randf_range(0.9, 1.1))
			return


func _open_present(i: int) -> void:
	if not Game.is_unlocked(i):
		shake_i = i
		shake_t = 0.5
		refresh_back()
		Audio.sfx("wrong", -4)
		say_bg("Not that one yet! Open them in order!")
		return
	opening = i
	open_t = 0.0
	locked = true
	refresh_back()
	Audio.sfx("pop")
	Audio.sfx("tada", -4)
	confetti_burst(_present_rect(i).get_center(), 50)
	await wait(0.9)
	Game.play_game(i)


func _open_secret() -> void:
	opening = 99
	locked = true
	Audio.sfx("giggle_low", -2)
	Audio.sfx("pop")
	confetti_burst(Vector2(640, 300), 40)
	await wait(0.8)
	Game.goto("rocko")


func tick(dt: float) -> void:
	open_t += dt
	if shake_t > 0.0:
		shake_t = maxf(0.0, shake_t - dt)
		if shake_t == 0.0:
			refresh_back()


func _wall() -> Color:
	return Color(0.99, 0.93, 0.8).lerp(Color(0.42, 0.36, 0.48), clampf(p / 10.0, 0.0, 1.0) * 0.85)


## Presents that move right now are drawn every frame; the rest are part of the scenery.
func _animated_present(i: int) -> bool:
	return i == next_index() or i == opening or (i == shake_i and shake_t > 0.0)


func paint_back() -> void:
	var dark := clampf(p / 10.0, 0.0, 1.0)
	var wall := _wall()
	pen.draw_rect(Rect2(-2000, -2000, W + 4000, 2520), wall)
	var floor_col := Color(0.86, 0.68, 0.48).lerp(Color(0.32, 0.25, 0.28), dark * 0.85)
	pen.draw_rect(Rect2(-2000, 520, W + 4000, 2000), floor_col)
	Crayon.line(pen, Vector2(-40, 520), Vector2(W + 40, 520), Crayon.INK, 5, 1)
	# wallpaper dots
	for i in 24:
		var dp := Vector2(fmod(i * 197.0, W), 150 + fmod(i * 71.0, 330))
		Crayon.disc(pen, dp, 4, wall.darkened(0.12))
	_window()
	_banner()
	_calendar()
	# guests stand still once the party gets... quieter
	if p >= 3:
		_guests()
		_table()
		if p < 6:
			Crayon.cake(pen, Vector2(640, 400), 230, 110 + p * 4, Crayon.PINK.lerp(Color(0.55, 0.25, 0.3), dark * 0.6), 5 + p, false, 23)
	for i in Game.GAMES.size():
		if not _animated_present(i):
			_present(i)


func _guests() -> void:
	var wall := _wall()
	for g in guests:
		var mood := "happy"
		if p >= 6:
			mood = "wide"
		if p >= 9 and int(g.seed) % 3 == 0:
			mood = "blank"
		var col := Crayon.INK if not g.back else Crayon.INK.lerp(wall, 0.35)
		Crayon.person(pen, Vector2(g.x, g.y), g.h, col, mood, g.col, "wave" if p < 3 else "stand", t * 2.0 + g.x, g.seed)


func _table() -> void:
	var dark := clampf(p / 10.0, 0.0, 1.0)
	Crayon.rect(pen, Rect2(330, 400, 620, 40), Crayon.INK, 5, Crayon.BROWN.lerp(Crayon.PURPLE, dark * 0.3), 20)
	Crayon.line(pen, Vector2(370, 440), Vector2(370, 520), Crayon.INK, 7, 21)
	Crayon.line(pen, Vector2(910, 440), Vector2(910, 520), Crayon.INK, 7, 22)


func paint() -> void:
	var dark := clampf(p / 10.0, 0.0, 1.0)
	if p < 3:
		# early on the guests wave at you (and stand in front of the table edge)
		_guests()
		_table()
	elif p >= 4:
		# eyes that follow you
		for g in guests:
			if p >= 9 and int(g.seed) % 3 == 0:
				continue
			var feet := Vector2(g.x, g.y)
			var look := (mouse - feet).normalized()
			var head: Vector2 = feet + Vector2(0, -g.h * 0.87)
			var hr: float = g.h * 0.13
			for sx in [-1, 1]:
				var e: Vector2 = head + Vector2(sx * hr * 0.32, -hr * 0.12)
				Crayon.disc(pen, e, hr * 0.17, Crayon.WHITE)
				Crayon.disc(pen, e + look * hr * 0.07, hr * 0.09, Crayon.INK)
	if p < 6:
		if p < 3:
			Crayon.cake(pen, Vector2(640, 400), 230, 110 + p * 4, Crayon.PINK, 5 + p, false, 23)
		Crayon.cake_flames(pen, Vector2(640, 400), 230, 110 + p * 4, 5 + p, 23)
	else:
		var breathe := 1.0 + sin(t * 1.3) * 0.03
		pen.draw_set_transform(Vector2(640, 400), 0, Vector2(1, breathe))
		Crayon.cake(pen, Vector2(0, 0), 230, 110 + p * 4, Crayon.PINK.lerp(Color(0.55, 0.25, 0.3), dark * 0.6), 5 + p, true, 23)
		pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		Crayon.face(pen, Vector2(640, 340), 34, "wide" if p >= 8 else "blank", (mouse - Vector2(640, 340)).normalized(), 24)
	if Game.finale_seen:
		var bob := absf(sin(t * 3.0)) * 10.0
		Crayon.text(pen, Vector2(640, 138 - bob), "???", 60, Crayon.YELLOW if not Game.secret_done else Crayon.GREEN, 1, 4447, Crayon.title_font())
		if Game.secret_done:
			# Rocko came to the party too
			Rocko.draw_cat(pen, Vector2(830, 400), 0.8, -1.0, "sit", 0.0, t)
			Crayon.party_hat(pen, Vector2(823, 320), 12, Crayon.GREEN, 4448, -0.2)
	# balloons tied to the table
	var cols := [Crayon.RED, Crayon.BLUE, Crayon.YELLOW, Crayon.GREEN]
	for i in 4:
		var bx := 300.0 + i * 30.0 if i < 2 else 940.0 + (i - 2) * 30.0
		var sag := clampf((p - 2) / 7.0, 0.0, 0.9)
		Crayon.balloon(pen, Vector2(bx, 250 + sag * 80 + sin(t + i) * 8), 30, cols[i], 120 - sag * 60, 30 + i, sag)
	Host.draw(pen, Vector2(150, 405), 58, dark * 0.9, Narrator.is_active(), (mouse - Vector2(150, 405)).normalized(), 40)
	# eyes in the window at night
	if p >= 7:
		var r := Rect2(40, 110, 230, 200)
		for i in mini(p - 6, 4):
			var e := r.position + Vector2(40 + i * 45, 150 - i * 20)
			if fmod(t + i * 1.7, 3.0) >= 0.15:
				Crayon.disc(pen, e, 5, Color(1, 0.95, 0.4))
				Crayon.disc(pen, e + Vector2(14, 0), 5, Color(1, 0.95, 0.4))
	for i in Game.GAMES.size():
		if _animated_present(i):
			_present(i)


func paint_top() -> void:
	var mb := get_button("mute")
	var c: Vector2 = mb.rect.get_center()
	Crayon.poly(pen, PackedVector2Array([c + Vector2(-20, -8), c + Vector2(-8, -8), c + Vector2(4, -20), c + Vector2(4, 20), c + Vector2(-8, 8), c + Vector2(-20, 8)]), Crayon.INK, 3, Crayon.GREY, 50)
	if Game.muted:
		Crayon.line(pen, c + Vector2(10, -12), c + Vector2(26, 12), Crayon.RED, 5, 51)
		Crayon.line(pen, c + Vector2(26, -12), c + Vector2(10, 12), Crayon.RED, 5, 52)
	else:
		Crayon._arc(pen, c + Vector2(6, 0), 14, -0.9, 0.9, Crayon.INK, 3, 53)
		Crayon._arc(pen, c + Vector2(6, 0), 22, -0.9, 0.9, Crayon.INK, 3, 54)
	var fb := get_button("full")
	var fc: Vector2 = fb.rect.get_center()
	for k in 4:
		var sx := -1.0 if k % 2 == 0 else 1.0
		var sy := -1.0 if k < 2 else 1.0
		var corner := fc + Vector2(sx * 20, sy * 16)
		Crayon.line(pen, corner, corner - Vector2(sx * 12, 0), Crayon.INK, 4, 60 + k)
		Crayon.line(pen, corner, corner - Vector2(0, sy * 10), Crayon.INK, 4, 64 + k)


func _present(i: int) -> void:
	var r := _present_rect(i)
	var g: Dictionary = Game.GAMES[i]
	if shake_i == i and shake_t > 0.0:
		r.position.x += sin(shake_t * 60.0) * 8.0
	var unlocked := Game.is_unlocked(i)
	var col: Color = g.col
	if not unlocked:
		col = col.lerp(Crayon.GREY, 0.55)
	if Game.done[i]:
		# opened box with a star
		Crayon.rect(pen, Rect2(r.position + Vector2(0, 30), Vector2(r.size.x, r.size.y - 30)), Crayon.INK, 4, col, 200 + i)
		Crayon.star(pen, r.position + Vector2(r.size.x * 0.5, 22), 26, Crayon.INK, Crayon.YELLOW, 210 + i)
		Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, 74), str(i + 1), 34, Crayon.WHITE, 1, 220 + i, Crayon.title_font())
	else:
		var lift := 0.0
		if i == opening:
			lift = clampf(open_t * 3.0, 0, 1) * 160.0
		Crayon.present(pen, r, col, Crayon.YELLOW if i % 2 == 0 else Crayon.WHITE, 230 + i, lift)
		Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, 70), str(i + 1), 36, Crayon.INK, 1, 240 + i, Crayon.title_font())
	if i == next_index() and opening < 0:
		Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, -46 - absf(sin(t * 4.0)) * 6), "OPEN ME!", 26, Crayon.RED, 1, 250)
	if Game.done[i] or i == next_index():
		var name: String = g.title
		Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, r.size.y + 22), name, 18, Crayon.INK, 1, 260 + i, null, 0.5, false)


func _window() -> void:
	var r := Rect2(40, 110, 230, 200)
	var sky := Crayon.SKY
	if p >= 4:
		sky = Crayon.SKY.lerp(Color(0.98, 0.55, 0.35), clampf((p - 3) / 3.0, 0, 1))
	if p >= 7:
		sky = Color(0.98, 0.55, 0.35).lerp(Color(0.08, 0.06, 0.2), clampf((p - 6) / 2.0, 0, 1))
	Crayon.rect(pen, r, Crayon.INK, 6, sky, 70)
	if p < 7:
		Crayon.sun(pen, r.position + Vector2(160, 70 + p * 12), 26, "happy" if p < 4 else "flat", 71)
	else:
		Crayon.circle(pen, r.position + Vector2(160, 60), 24, Crayon.INK, 3, Color(1, 1, 0.85), 72)
	Crayon.line(pen, r.position + Vector2(r.size.x * 0.5, 0), r.position + Vector2(r.size.x * 0.5, r.size.y), Crayon.INK, 5, 73)
	Crayon.line(pen, r.position + Vector2(0, r.size.y * 0.5), r.position + Vector2(r.size.x, r.size.y * 0.5), Crayon.INK, 5, 74)


func _banner() -> void:
	var msg := "HAPPY BIRTHDAY CHUMBO"
	if p >= 8:
		msg = "HAPPY BIRTHDAY FOREVER"
	var x0 := 330.0
	var x1 := 1060.0
	var pts := PackedVector2Array()
	for i in 21:
		var f := i / 20.0
		pts.append(Vector2(lerpf(x0, x1, f), 40 + sin(f * PI) * 40))
	Crayon.path(pen, pts, Crayon.INK, 3, 80)
	var letters := msg.replace(" ", "")
	var n := letters.length()
	for i in n:
		var f := (i + 0.5) / n
		var top := Vector2(lerpf(x0, x1, f), 40 + sin(f * PI) * 40)
		var col: Color = Crayon.RAINBOW[i % 7].lerp(Crayon.GREY, clampf((p - 5) / 6.0, 0, 0.6))
		Crayon.poly(pen, PackedVector2Array([top + Vector2(-16, 0), top + Vector2(16, 0), top + Vector2(0, 44)]), Crayon.INK, 2, col, 81 + i)
		Crayon.text(pen, top + Vector2(0, 14), letters.substr(i, 1), 22, Crayon.INK, 1, 120 + i, null, 0.6, true)


func _calendar() -> void:
	var r := Rect2(1090, 110, 160, 160)
	Crayon.rect(pen, r, Crayon.INK, 4, Crayon.WHITE, 90)
	Crayon.rect(pen, Rect2(r.position, Vector2(r.size.x, 34)), Crayon.INK, 4, Crayon.RED, 91)
	var d := Game.today()
	Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, 18), Game.MONTHS[d.month - 1].substr(0, 3).to_upper(), 24, Crayon.WHITE, 1, 92)
	Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, 82), str(d.day), 54, Crayon.INK, 1, 93, Crayon.title_font())
	Crayon.circle(pen, r.position + Vector2(r.size.x * 0.5, 82), 38, Crayon.RED, 4, Color(0, 0, 0, 0), 94)
	var label := "CHUMBO'S BDAY!" if p < 5 else "EVERY DAY"
	Crayon.text(pen, r.position + Vector2(r.size.x * 0.5, 138), label, 20, Crayon.RED, 1, 95, null, 0.6, false)
