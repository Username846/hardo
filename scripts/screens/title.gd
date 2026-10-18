extends Screen
## The title screen: a party carousel going round at dusk to the theme waltz ("It's Your
## Birthday"), with a rider from the presents on every pole. Browsers only allow sound after a
## tap, so on the web the first tap switches the party on (lights, music, carousel) and then
## PLAY starts the game.

const Race := preload("res://scripts/games/race.gd")
const Skate := preload("res://scripts/games/skate.gd")
const Digi := preload("res://scripts/games/digi.gd")
const Duty := preload("res://scripts/games/duty.gd")
const Repo := preload("res://scripts/games/repo.gd")
const Karaoke := preload("res://scripts/games/karaoke.gd")

const CX := 640.0
const PEAK_Y := 122.0
const RIM_Y := 288.0
const RIM_W := 370.0
const PLAT_Y := 578.0
const PLAT_R := Vector2(380, 50)
const RIDE_R := Vector2(300, 38)
const PLAY_RECT := Rect2(1012, 466, 250, 100)
## [what, sound when tapped]
const RIDERS := [["race", "rev"], ["skate", "honk"], ["digi", "digivolve"], ["duty", "reload"],
	["repo", "beep2"], ["karaoke", "sparkle"]]

var awake := false
var lights := 0.0
var spin := 0.0
var rot := 0.0
var forget_armed := 0.0
var leaving := false
var _rider_pos: Array = []


func enter() -> void:
	show_home = false
	remove_button("home")
	use_back_layer()
	lyrics_y = 676.0
	add_button("full", Rect2(16, H - 64, 168, 50), "full screen", _fullscreen, Crayon.WHITE, 24)
	if Game.player_name != "":
		add_button("forget", Rect2(W - 184, H - 64, 168, 50), "new party", _forget, Crayon.WHITE, 24)
	if not OS.has_feature("web"):
		# no autoplay rules to wait for: the party is already going
		_wake(false)


## Lights on, music on, the carousel starts to turn, and the PLAY button appears.
func _wake(fanfare: bool = true) -> void:
	if awake:
		return
	awake = true
	Audio.preload_sfx()
	Audio.play_music("theme", 0.3)
	if fanfare:
		Audio.sfx("switch", -2)
		Audio.sfx("tada", -4)
		for i in 4:
			confetti_burst(Vector2(220 + i * 280, 240), 30)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "lights", 1.0, 0.5)
		tw.tween_property(self, "spin", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	else:
		lights = 1.0
		spin = 1.0
	add_button("play", PLAY_RECT, "PLAY!", _play, Crayon.YELLOW, 56)


func _play() -> void:
	if leaving:
		return
	leaving = true
	Audio.sfx("tada")
	# every launch starts by asking for the name (there is only one right answer)
	Game.goto("name")


func _fullscreen() -> void:
	_wake()
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _forget() -> void:
	_wake()
	var b := get_button("forget")
	if forget_armed > 0.0:
		Game.reset()
		Audio.sfx("music_wrong")
		b.label = "forgotten!"
		b.visible = false
		return
	forget_armed = 3.0
	b.label = "tap again!"


func tick(dt: float) -> void:
	rot += dt * 0.42 * spin
	if forget_armed > 0.0:
		forget_armed -= dt
		if forget_armed <= 0.0:
			var b := get_button("forget")
			if not b.is_empty() and b.visible:
				b.label = "new party"


func press(p: Vector2) -> void:
	if not awake:
		_wake()
		return
	# the riders make their noises
	for r in _rider_pos:
		if p.distance_to(r.p) < 60.0 * r.s + 20.0:
			Audio.sfx(r.sfx, -4, randf_range(0.95, 1.1))
			return


# ---------------------------------------------------------------- drawing

func paint_back() -> void:
	# dusk sky
	var sky := [Color(0.22, 0.18, 0.42), Color(0.42, 0.26, 0.52), Color(0.72, 0.36, 0.55), Color(0.95, 0.56, 0.5), Color(0.99, 0.75, 0.55)]
	for i in 14:
		var f := float(i) / 13.0 * (sky.size() - 1)
		var col: Color = (sky[int(f)] as Color).lerp(sky[mini(int(f) + 1, sky.size() - 1)], f - int(f))
		var y0 := -2000.0 if i == 0 else 42.0 * i
		pen.draw_rect(Rect2(-2000, y0, W + 4000, 42.0 * (i + 1) - y0 + 2), col)
	for i in 18:
		var s := Vector2(fmod(i * 397.0, W), 20.0 + fmod(i * 131.0, 160.0))
		Crayon.star(pen, s, 4.0 + fmod(i * 1.7, 3.0), Color(1, 1, 0.8, 0.0), Color(1, 1, 0.85, 0.85), 40 + i)
	# grass and a path up to the carousel
	Crayon.poly(pen, PackedVector2Array([Vector2(-2000, 560), Vector2(W + 2000, 560), Vector2(W + 2000, H + 2000), Vector2(-2000, H + 2000)]), Crayon.INK, 0.0, Color(0.36, 0.62, 0.32), 60)
	Crayon.poly(pen, PackedVector2Array([Vector2(560, 600), Vector2(720, 600), Vector2(820, H + 40), Vector2(460, H + 40)]), Color(0, 0, 0, 0), 0.0, Color(0.85, 0.75, 0.55), 61)
	# far-off party tents
	for k in 2:
		var x := 90.0 + k * 1090.0
		Crayon.poly(pen, PackedVector2Array([Vector2(x - 70, 560), Vector2(x, 470), Vector2(x + 70, 560)]), Crayon.INK, 3, [Crayon.BLUE, Crayon.ORANGE][k].lightened(0.2), 62 + k)
		Crayon.line(pen, Vector2(x, 470), Vector2(x, 450), Crayon.INK, 3, 64 + k)
	# the platform the riders go round on
	Crayon.ellipse(pen, Vector2(CX, PLAT_Y + 18), PLAT_R, Crayon.INK, 5, Color(0.62, 0.32, 0.4), 70)
	Crayon.ellipse(pen, Vector2(CX, PLAT_Y), PLAT_R, Crayon.INK, 5, Color(0.98, 0.82, 0.5), 71)
	Crayon.ellipse(pen, Vector2(CX, PLAT_Y), PLAT_R * 0.8, Color(0.85, 0.6, 0.35), 3, Color(0, 0, 0, 0), 72)
	_canopy()
	# bunting from the top of the carousel out to the edges, in every present's colours
	for side in [-1.0, 1.0]:
		var from := Vector2(CX + side * 70.0, PEAK_Y + 40.0)
		var to := Vector2(CX + side * 700.0, 330.0)
		var n := 9
		for i in n:
			var a := from.lerp(to, float(i) / n) + Vector2(0, sin(float(i) / n * PI) * 26.0)
			var b := from.lerp(to, float(i + 1) / n) + Vector2(0, sin(float(i + 1) / n * PI) * 26.0)
			Crayon.line(pen, a, b, Crayon.INK, 2, 80 + i + int(side + 1) * 10)
			if i == 0:
				continue
			var g: Dictionary = Game.GAMES[(i + int(side + 1) * 2) % Game.GAMES.size()]
			var m := (a + b) * 0.5
			Crayon.poly(pen, PackedVector2Array([a.lerp(b, 0.12), b.lerp(a, 0.12), m + Vector2(0, 32)]), Crayon.INK, 2, g.col, 120 + i + int(side + 1) * 10)
	# the carousel's name plate
	var plate := Rect2(CX - 250, 170, 500, 98)
	Crayon.rect(pen, plate.grow(8), Crayon.INK, 4, Color(0.98, 0.82, 0.4), 150)
	Crayon.rect(pen, plate, Crayon.INK, 3, Crayon.WHITE, 151)
	title_text(plate.get_center() + Vector2(0, 2), "CHUMBO!!!", 92, Crayon.RED, 900)


## The striped top of the carousel: one stripe per present, a candle on top.
func _canopy() -> void:
	var peak := Vector2(CX, PEAK_Y)
	var n := Game.GAMES.size()
	for i in n:
		var x0 := CX - RIM_W + i * RIM_W * 2.0 / n
		var x1 := CX - RIM_W + (i + 1) * RIM_W * 2.0 / n
		var col: Color = Game.GAMES[i].col if i % 2 == 0 else Crayon.WHITE
		Crayon.poly(pen, PackedVector2Array([peak + Vector2((x0 - CX) * 0.06, 0), peak + Vector2((x1 - CX) * 0.06, 0), Vector2(x1, RIM_Y), Vector2(x0, RIM_Y)]), Crayon.INK, 3, col.lightened(0.15), 140 + i)
	# rim band with scallops
	Crayon.rect(pen, Rect2(CX - RIM_W - 10, RIM_Y - 4, RIM_W * 2 + 20, 30), Crayon.INK, 4, Color(0.98, 0.82, 0.4), 160)
	for i in 14:
		var c := Vector2(CX - RIM_W + 16 + i * (RIM_W * 2 - 32) / 13.0, RIM_Y + 26)
		Crayon.circle(pen, c, 22, Crayon.INK, 3, [Crayon.RED, Crayon.WHITE][i % 2], 170 + i)
	Crayon.rect(pen, Rect2(CX - RIM_W - 10, RIM_Y - 4, RIM_W * 2 + 20, 30), Crayon.INK, 4, Color(0.98, 0.82, 0.4), 161)
	# a pennant on top
	Crayon.line(pen, Vector2(CX, PEAK_Y + 4), Vector2(CX, PEAK_Y - 30), Crayon.INK, 4, 180)


func paint() -> void:
	var dim := 1.0 - lights
	# the bulbs on the rim and the string lights
	for i in 18:
		var p := Vector2(CX - RIM_W + 4 + i * (RIM_W * 2 - 8) / 17.0, RIM_Y + 11)
		var on := lights > 0.5 and (int(t * 4.0) + i) % 3 != 0
		Crayon.disc(pen, p, 6.0, Color(1, 0.95, 0.55) if on else Color(0.55, 0.5, 0.4))
		if on:
			Crayon.disc(pen, p, 12.0, Color(1, 0.9, 0.4, 0.25))
	var flap := sin(t * 5.0) * 4.0 * (0.3 + 0.7 * spin)
	Crayon.poly(pen, PackedVector2Array([Vector2(CX, PEAK_Y - 30), Vector2(CX + 34, PEAK_Y - 22 + flap), Vector2(CX, PEAK_Y - 14)]), Crayon.INK, 2, Crayon.RED, 181)
	# riders, back half first, then the middle pole, then the front half
	_rider_pos.clear()
	var order: Array = []
	for k in RIDERS.size():
		var a := rot + k * TAU / RIDERS.size()
		order.append([sin(a), k, a])
	order.sort_custom(func(x, y): return x[0] < y[0])
	var column_done := false
	for o in order:
		if o[0] >= 0.0 and not column_done:
			_column()
			column_done = true
		_rider(int(o[1]), float(o[2]))
	if not column_done:
		_column()
	# Chumbo and the party host, by the carousel
	Crayon.person(pen, Vector2(165, 612), 160, Crayon.INK, "happy", Crayon.GREEN, "wave", t * 2.0, 31)
	Host.draw(pen, Vector2(1137, 340), 62, 0.0, false, Vector2.ZERO, 11)
	# the first line of the title, bouncing to the waltz
	var title := "IT'S YOUR BIRTHDAY,"
	var x0 := W * 0.5 - 495
	for i in title.length():
		var y := 52.0 + sin(t * 3.14 + i * 0.5) * 6.0 * (0.4 + 0.6 * spin)
		Crayon.text(pen, Vector2(x0 + i * 55, y), title.substr(i, 1), 58, Crayon.RAINBOW[i % 7].darkened(0.1), 1, 300 + i, Crayon.title_font())
	if awake and not get_button("play").is_empty():
		# a little sparkle ring round PLAY
		for k in 6:
			var a := t * 1.5 + k * TAU / 6.0
			Crayon.star(pen, PLAY_RECT.get_center() + Vector2(cos(a) * 150, sin(a) * 66), 8, Crayon.INK, Crayon.YELLOW, 700 + k)
	if dim > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.05, 0.03, 0.12, 0.55 * dim))


func _column() -> void:
	var r := Rect2(CX - 38, RIM_Y + 46, 76, PLAT_Y - RIM_Y - 46)
	Crayon.rect(pen, r, Crayon.INK, 4, Color(0.98, 0.7, 0.78), 190)
	for k in 4:
		var y := r.position.y + 14 + fmod(k * 52.0 + rot * 60.0, r.size.y - 24)
		pen.draw_rect(Rect2(r.position.x + 4, y, r.size.x - 8, 8), Color(1, 0.9, 0.5, 0.8))


func _rider(k: int, a: float) -> void:
	var d := sin(a)
	var base := Vector2(CX + cos(a) * RIDE_R.x, PLAT_Y + d * RIDE_R.y)
	var sc := 0.78 + 0.22 * (d + 1.0) * 0.5
	var bob := sin(t * 2.2 + k * 1.7) * 16.0 * spin
	var feet := base + Vector2(0, -44 - bob)
	# brass pole from the rim to the floor
	Crayon.line(pen, Vector2(base.x, RIM_Y + 30), base, Color(0.85, 0.65, 0.25), 6 * sc + 2, 200 + k, 0.2)
	var what: String = RIDERS[k][0]
	match what:
		"race":
			Race.draw_mascot(pen, feet, 0.8 * sc, t)
		"skate":
			Skate.draw_mascot(pen, feet, 1.0 * sc, t, true)
		"digi":
			Digi.draw_mascot(pen, feet, 0.62 * sc, t)
		"duty":
			Duty.draw_mascot(pen, feet, 0.92 * sc, t)
		"repo":
			Repo.draw_mascot(pen, feet, 0.95 * sc, t)
		"karaoke":
			Karaoke.draw_mascot(pen, feet, 0.82 * sc, t, 0.0)
	_rider_pos.append({"p": feet + Vector2(0, -60 * sc), "s": sc, "sfx": RIDERS[k][1]})


func paint_top() -> void:
	if not awake and fmod(t, 1.2) < 0.85:
		Crayon.text(pen, Vector2(W * 0.5, 430), "TAP TO START THE PARTY", 54, Crayon.WHITE, 1, 600, Crayon.title_font())
		Crayon.text(pen, Vector2(W * 0.5, 486), "(turn your sound on!)", 30, Color(1, 1, 1, 0.85), 1, 601)
