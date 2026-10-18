extends Screen
## The title screen: a party carousel going round at dusk to the theme waltz ("It's Your
## Birthday"). Each present's rider is still wrapped up until its game has been played.
## Browsers only allow sound after a tap, so on the web the first tap switches the party on
## (lights, music, carousel) and then PLAY starts the game.
##
## (Chumbo by the carousel doesn't like being poked. Poke him enough and the title screen stays
## grim, with the slow, dark theme, until a new party is started.)

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
## [what, sound when tapped, which present it comes from]
const RIDERS := [["race", "rev", 0], ["skate", "honk", 1], ["digi", "digivolve", 2], ["duty", "reload", 4],
	["repo", "beep2", 8], ["karaoke", "sparkle", 9]]
const CHUMBO := Vector2(165, 612)
const CHUMBO_H := 160.0
const HITS_TO_DIE := 10
const OUCH := ["OW!", "OOF!", "OUCH!", "HEY!"]

var awake := false
var lights := 0.0
var spin := 0.0
var rot := 0.0
var forget_armed := 0.0
var leaving := false
var _rider_pos: Array = []
# poor Chumbo
var hits := 0
var flinch := 0.0
var dying := false
var dead := false
var fall := 0.0
var body_a := 1.0
var ghost := 0.0
var tomb := 0.0
var ghost_spin := 0.0
var grim := 0.0
var _baked_grim := 0.0
var pops: Array = []     # {p, txt, t}


func enter() -> void:
	show_home = false
	remove_button("home")
	if Game.title_dead:
		dead = true
		fall = 1.0
		body_a = 0.0
		ghost = 1.0
		tomb = 1.0
		grim = 1.0
		_baked_grim = 1.0
	use_back_layer()
	lyrics_y = 676.0
	add_button("full", Rect2(16, H - 64, 168, 50), "full screen", _fullscreen, Crayon.WHITE, 24)
	if Game.player_name != "":
		add_button("forget", Rect2(W - 184, H - 64, 168, 50), "new party", _forget, Crayon.WHITE, 24)
	if not OS.has_feature("web") or Audio.unlocked:
		# no autoplay rules to wait for (or a tap already allowed sound): the party is already going
		_wake(false)


func _spin_target() -> float:
	return 0.45 if dead else 1.0


## Lights on, music on, the carousel starts to turn, and the PLAY button appears.
func _wake(fanfare: bool = true) -> void:
	if awake:
		return
	awake = true
	Audio.unlocked = true
	Audio.preload_sfx()
	Audio.play_music("theme_dark" if dead else "theme", 0.3)
	if fanfare:
		Audio.sfx("switch", -2)
		Audio.sfx("tada" if not dead else "creak", -4)
		if not dead:
			for i in 4:
				confetti_burst(Vector2(220 + i * 280, 240), 30)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "lights", 1.0, 0.5)
		tw.tween_property(self, "spin", _spin_target(), 2.5).set_trans(Tween.TRANS_SINE)
	else:
		lights = 1.0
		spin = _spin_target()
	add_button("play", PLAY_RECT, "PLAY!", _play, Crayon.YELLOW, 56)


func _play() -> void:
	if leaving:
		return
	leaving = true
	Audio.sfx("tada")
	if Game.player_name == Game.CANON_NAME:
		# the name only has to be got right once
		Game.goto("hub" if Game.intro_done else "intro")
	else:
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
		if dead:
			_revive()
		return
	forget_armed = 3.0
	b.label = "tap again!"


## A new party: Chumbo is back, and so is the colour.
func _revive() -> void:
	dead = false
	hits = 0
	fall = 0.0
	body_a = 1.0
	ghost = 0.0
	tomb = 0.0
	Audio.play_music("theme", 1.0)
	Audio.sfx("tada", -2)
	confetti_burst(CHUMBO + Vector2(0, -100), 50)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "grim", 0.0, 1.5)
	tw.tween_property(self, "spin", 1.0, 1.5)


func tick(dt: float) -> void:
	rot += dt * 0.42 * spin
	flinch = maxf(0.0, flinch - dt * 3.0)
	ghost_spin = maxf(0.0, ghost_spin - dt * 1.5)
	for pp in pops:
		pp.t -= dt
		pp.p.y -= 50.0 * dt
	pops = pops.filter(func(pp): return pp.t > 0.0)
	if absf(grim - _baked_grim) > 0.02:
		_baked_grim = grim
		refresh_back()
	if dead and not dying and awake and randf() < dt * 0.08:
		Audio.sfx("creak", -12, randf_range(0.8, 1.0))
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
	if Rect2(CHUMBO + Vector2(-55, -CHUMBO_H - 20), Vector2(110, CHUMBO_H + 30)).has_point(p) and not dying:
		if dead:
			Audio.sfx("giggle_low", -4)
			ghost_spin = 1.0
		else:
			_hurt()
		return
	# the riders make their noises (wrapped ones just rattle)
	for r in _rider_pos:
		if p.distance_to(r.p) < 60.0 * r.s + 20.0:
			Audio.sfx(r.sfx, -4, randf_range(0.95, 1.1))
			return


func _hurt() -> void:
	hits += 1
	flinch = 1.0
	Audio.sfx("ow" if hits % 2 == 1 else "oof", -2, randf_range(0.9, 1.1) - hits * 0.02)
	Audio.sfx("bonk", -8)
	pops.append({"p": CHUMBO + Vector2(randf_range(-40, 40), -CHUMBO_H - 20), "txt": OUCH[hits % OUCH.size()], "t": 0.9})
	match hits:
		2:
			say_bg("Ow! Hey!", Narrator.CHUMBO)
		4:
			say_bg("Why are you doing that?", Narrator.CHUMBO)
		6:
			say_bg("Please stop. It really hurts.", Narrator.CHUMBO)
		8:
			say_bg("I don't feel so good.", Narrator.CHUMBO)
	if hits >= HITS_TO_DIE:
		_die()


func _die() -> void:
	dying = true
	locked = true
	Audio.sfx("oof", 0, 0.75)
	Audio.music_pitch(0.55, 2.5)
	var tw := create_tween()
	tw.tween_property(self, "fall", 1.0, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await wait(0.8)
	Audio.sfx("thud")
	await wait(1.4)
	await say("Chumbo? Chumbo, get up. It's your birthday.", Narrator.DARK)
	dead = true
	Game.title_dead = true
	Game.save_game()
	Audio.play_music("theme_dark", 2.5)
	Audio.sfx("whoosh", -6, 0.6)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(self, "grim", 1.0, 3.0)
	tw2.tween_property(self, "spin", 0.45, 3.0)
	tw2.tween_property(self, "ghost", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(self, "body_a", 0.0, 2.5)
	tw2.tween_property(self, "tomb", 1.0, 1.0).set_delay(1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(3.2)
	await say("Oh well. The party goes on. It always does.", Narrator.DARK)
	dying = false
	locked = false


# ---------------------------------------------------------------- drawing

func paint_back() -> void:
	var g := grim
	# dusk sky (a sickly red one, when it's grim)
	var sky := [Color(0.22, 0.18, 0.42), Color(0.42, 0.26, 0.52), Color(0.72, 0.36, 0.55), Color(0.95, 0.56, 0.5), Color(0.99, 0.75, 0.55)]
	var sky_g := [Color(0.06, 0.04, 0.08), Color(0.13, 0.06, 0.1), Color(0.26, 0.08, 0.12), Color(0.38, 0.13, 0.14), Color(0.45, 0.22, 0.18)]
	for i in 14:
		var f := float(i) / 13.0 * (sky.size() - 1)
		var a := int(f)
		var b := mini(a + 1, sky.size() - 1)
		var col: Color = (sky[a] as Color).lerp(sky[b], f - a).lerp((sky_g[a] as Color).lerp(sky_g[b], f - a), g)
		var y0 := -2000.0 if i == 0 else 42.0 * i
		pen.draw_rect(Rect2(-2000, y0, W + 4000, 42.0 * (i + 1) - y0 + 2), col)
	for i in 18:
		var s := Vector2(fmod(i * 397.0, W), 20.0 + fmod(i * 131.0, 160.0))
		Crayon.star(pen, s, 4.0 + fmod(i * 1.7, 3.0), Color(1, 1, 0.8, 0.0), Color(1, 1, 0.85, 0.85 * (1.0 - g)), 40 + i)
	if g > 0.0:
		Crayon.circle(pen, Vector2(1100, 118), 44, Color(Crayon.INK, g), 3, Color(0.9, 0.55, 0.5, g), 45)
	# grass (dead grass, later) and a path up to the carousel
	Crayon.poly(pen, PackedVector2Array([Vector2(-2000, 560), Vector2(W + 2000, 560), Vector2(W + 2000, H + 2000), Vector2(-2000, H + 2000)]), Crayon.INK, 0.0, Color(0.36, 0.62, 0.32).lerp(Color(0.3, 0.28, 0.22), g), 60)
	Crayon.poly(pen, PackedVector2Array([Vector2(560, 600), Vector2(720, 600), Vector2(820, H + 40), Vector2(460, H + 40)]), Color(0, 0, 0, 0), 0.0, Color(0.85, 0.75, 0.55).lerp(Color(0.4, 0.36, 0.3), g), 61)
	# far-off party tents
	for k in 2:
		var x := 90.0 + k * 1090.0
		var tc: Color = ([Crayon.BLUE, Crayon.ORANGE][k] as Color).lightened(0.2).lerp(Color(0.32, 0.3, 0.32), g)
		Crayon.poly(pen, PackedVector2Array([Vector2(x - 70, 560), Vector2(x, 470), Vector2(x + 70, 560)]), Crayon.INK, 3, tc, 62 + k)
		Crayon.line(pen, Vector2(x, 470), Vector2(x, 450), Crayon.INK, 3, 64 + k)
	# the platform the riders go round on
	Crayon.ellipse(pen, Vector2(CX, PLAT_Y + 18), PLAT_R, Crayon.INK, 5, _fade(Color(0.62, 0.32, 0.4)), 70)
	Crayon.ellipse(pen, Vector2(CX, PLAT_Y), PLAT_R, Crayon.INK, 5, _fade(Color(0.98, 0.82, 0.5)), 71)
	Crayon.ellipse(pen, Vector2(CX, PLAT_Y), PLAT_R * 0.8, _fade(Color(0.85, 0.6, 0.35)), 3, Color(0, 0, 0, 0), 72)
	_canopy()
	# bunting from the top of the carousel out to the edges, in every present's colours
	for side in [-1.0, 1.0]:
		var from := Vector2(CX + side * 70.0, PEAK_Y + 40.0)
		var to := Vector2(CX + side * 700.0, 330.0 + g * 30.0)
		var n := 9
		for i in n:
			var sag := 26.0 + g * 30.0
			var a := from.lerp(to, float(i) / n) + Vector2(0, sin(float(i) / n * PI) * sag)
			var b := from.lerp(to, float(i + 1) / n) + Vector2(0, sin(float(i + 1) / n * PI) * sag)
			Crayon.line(pen, a, b, Crayon.INK, 2, 80 + i + int(side + 1) * 10)
			if i == 0 or (g > 0.5 and (i + int(side + 1)) % 3 == 0):
				continue
			var gm: Dictionary = Game.GAMES[(i + int(side + 1) * 2) % Game.GAMES.size()]
			var m := (a + b) * 0.5
			Crayon.poly(pen, PackedVector2Array([a.lerp(b, 0.12), b.lerp(a, 0.12), m + Vector2(0, 32)]), Crayon.INK, 2, _fade(gm.col), 120 + i + int(side + 1) * 10)
	# the carousel's name plate
	var plate := Rect2(CX - 250, 170, 500, 98)
	Crayon.rect(pen, plate.grow(8), Crayon.INK, 4, _fade(Color(0.98, 0.82, 0.4)), 150)
	Crayon.rect(pen, plate, Crayon.INK, 3, Crayon.WHITE.lerp(Color(0.62, 0.6, 0.6), g), 151)
	title_text(plate.get_center() + Vector2(0, 2), "CHUMBO!!!", 92, Crayon.RED.lerp(Color(0.3, 0.1, 0.12), g), 900)
	if g > 0.5:
		# a black ribbon on the corner
		Crayon.poly(pen, PackedVector2Array([plate.position + Vector2(plate.size.x - 34, -8), plate.position + Vector2(plate.size.x + 8, -8), plate.position + Vector2(plate.size.x + 8, 34)]), Crayon.INK, 2, Color(0.08, 0.06, 0.08), 152)


## Colours drain out of the party when it's grim.
func _fade(c: Color) -> Color:
	var grey := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	return c.lerp(Color(grey, grey, grey).darkened(0.35), grim * 0.8)


## The striped top of the carousel: one stripe per present.
func _canopy() -> void:
	var peak := Vector2(CX, PEAK_Y)
	var n := Game.GAMES.size()
	for i in n:
		var x0 := CX - RIM_W + i * RIM_W * 2.0 / n
		var x1 := CX - RIM_W + (i + 1) * RIM_W * 2.0 / n
		var col: Color = Game.GAMES[i].col if i % 2 == 0 else Crayon.WHITE
		Crayon.poly(pen, PackedVector2Array([peak + Vector2((x0 - CX) * 0.06, 0), peak + Vector2((x1 - CX) * 0.06, 0), Vector2(x1, RIM_Y), Vector2(x0, RIM_Y)]), Crayon.INK, 3, _fade(col.lightened(0.15)), 140 + i)
	# rim band with scallops
	Crayon.rect(pen, Rect2(CX - RIM_W - 10, RIM_Y - 4, RIM_W * 2 + 20, 30), Crayon.INK, 4, _fade(Color(0.98, 0.82, 0.4)), 160)
	for i in 14:
		var c := Vector2(CX - RIM_W + 16 + i * (RIM_W * 2 - 32) / 13.0, RIM_Y + 26)
		Crayon.circle(pen, c, 22, Crayon.INK, 3, _fade([Crayon.RED, Crayon.WHITE][i % 2]), 170 + i)
	Crayon.rect(pen, Rect2(CX - RIM_W - 10, RIM_Y - 4, RIM_W * 2 + 20, 30), Crayon.INK, 4, _fade(Color(0.98, 0.82, 0.4)), 161)
	# a pennant on top
	Crayon.line(pen, Vector2(CX, PEAK_Y + 4), Vector2(CX, PEAK_Y - 30), Crayon.INK, 4, 180)


func paint() -> void:
	var dim := 1.0 - lights
	# the bulbs on the rim (only a few still work when it's grim)
	for i in 18:
		var p := Vector2(CX - RIM_W + 4 + i * (RIM_W * 2 - 8) / 17.0, RIM_Y + 11)
		var on := lights > 0.5 and (int(t * 4.0) + i) % 3 != 0
		if grim > 0.5:
			on = lights > 0.5 and i % 5 == 2 and fmod(t * 7.0 + i, 3.0) > 0.4
		Crayon.disc(pen, p, 6.0, Color(1, 0.95, 0.55) if on else Color(0.55, 0.5, 0.4).darkened(grim * 0.4))
		if on:
			Crayon.disc(pen, p, 12.0, Color(1, 0.9, 0.4, 0.25))
	var flap := sin(t * 5.0) * 4.0 * (0.3 + 0.7 * spin)
	Crayon.poly(pen, PackedVector2Array([Vector2(CX, PEAK_Y - 30), Vector2(CX + 34, PEAK_Y - 22 + flap + grim * 14), Vector2(CX, PEAK_Y - 14)]), Crayon.INK, 2, _fade(Crayon.RED), 181)
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
	_chumbo()
	Host.draw(pen, Vector2(1137, 340), 62, grim, false, Vector2.ZERO, 11)
	# the first line of the title, bouncing to the waltz (and drooping, when it's grim)
	var title := "IT'S YOUR BIRTHDAY,"
	var x0 := W * 0.5 - 495
	for i in title.length():
		var y := 52.0 + sin(t * 3.14 + i * 0.5) * 6.0 * (0.4 + 0.6 * spin) + grim * (8.0 + fmod(i * 7.3, 14.0))
		var col: Color = (Crayon.RAINBOW[i % 7] as Color).darkened(0.1).lerp(Color(0.45, 0.4, 0.42), grim)
		Crayon.text(pen, Vector2(x0 + i * 55, y), title.substr(i, 1), 58, col, 1, 300 + i, Crayon.title_font())
	if awake and not get_button("play").is_empty():
		# a little sparkle ring round PLAY
		for k in 6:
			var a := t * 1.5 + k * TAU / 6.0
			Crayon.star(pen, PLAY_RECT.get_center() + Vector2(cos(a) * 150, sin(a) * 66), 8, Crayon.INK, _fade(Crayon.YELLOW), 700 + k)
	if grim > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.12, 0.02, 0.08, 0.3 * grim))
	if dim > 0.0:
		pen.draw_rect(Rect2(-2000, -2000, W + 4000, H + 4000), Color(0.05, 0.03, 0.12, 0.55 * dim))


## Chumbo by the carousel: waving, then (if he gets poked) hurt, then... a ghost by his grave.
func _chumbo() -> void:
	if tomb > 0.0:
		_tomb(CHUMBO + Vector2(0, 4), tomb)
	if body_a > 0.0:
		var mood := "happy"
		var pose := "wave"
		if hits >= 4:
			mood = "sad"
		if hits >= 7:
			pose = "stand"
			mood = "o"
		if flinch > 0.5:
			mood = "o"
		if fall > 0.0:
			mood = "x"
		var ink := Color(Crayon.INK, body_a)
		var lean := 0.08 if hits >= 7 else 0.0
		var feet := CHUMBO + Vector2(-flinch * 14.0 + (sin(t * 6.0) * 3.0 if hits >= 8 else 0.0), 0)
		pen.draw_set_transform(feet, -fall * PI * 0.5 + lean, Vector2.ONE)
		Crayon.person(pen, Vector2.ZERO, CHUMBO_H, ink, mood, Color(Crayon.GREEN, body_a), pose, t * 2.0, 31)
		var head := Vector2(0, -CHUMBO_H * 0.87)
		var hr := CHUMBO_H * 0.13
		if hits >= 5:
			# a black eye
			Crayon.disc(pen, head + Vector2(hr * 0.32, -hr * 0.12), hr * 0.32, Color(0.45, 0.2, 0.55, 0.5 * body_a))
		if hits >= 3:
			# sticking plasters
			for k in 2:
				var c := head + Vector2(-hr * 0.55, hr * 0.15) + Vector2(k * 4, k * -4)
				var d := Vector2(cos(0.6 + k * 1.6), sin(0.6 + k * 1.6)) * hr * 0.45
				Crayon.line(pen, c - d, c + d, Color(Crayon.INK, body_a), 9, 4600 + k, 0.2)
				Crayon.line(pen, c - d, c + d, Color(1.0, 0.85, 0.7, body_a), 6, 4602 + k, 0.2)
		if hits >= 6:
			Crayon.line(pen, Vector2(-hr * 0.9, -CHUMBO_H * 0.6), Vector2(-hr * 0.3, -CHUMBO_H * 0.55), Color(1.0, 0.85, 0.7, body_a), 6, 4604, 0.2)
		pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if flinch > 0.0 and fall == 0.0:
			for k in 3:
				var a := t * 8.0 + k * TAU / 3.0
				Crayon.star(pen, feet + head + Vector2(cos(a) * 30, sin(a) * 10 - hr * 1.3), 7, Crayon.INK, Crayon.YELLOW, 4610 + k)
	if ghost > 0.0:
		var gp := CHUMBO + Vector2(40, -60 - ghost * 120 + sin(t * 1.8) * 8)
		_ghost(gp, minf(1.0, ghost * 1.5))


func _ghost(p: Vector2, a: float) -> void:
	var white := Color(0.97, 0.97, 1.0, 0.85 * a)
	var ink := Color(Crayon.INK, 0.8 * a)
	var rot_g := sin(ghost_spin * TAU * 2.0) * 0.4
	pen.draw_set_transform(p, rot_g, Vector2.ONE)
	var pts := PackedVector2Array()
	for k in 13:
		var ang := PI + k * PI / 12.0
		pts.append(Vector2(cos(ang), sin(ang)) * 30.0)
	for k in 7:
		var x := 30.0 - k * 10.0
		pts.append(Vector2(x, 34.0 + (6.0 if k % 2 == 0 else -2.0) + sin(t * 4.0 + k) * 3.0))
	Crayon.poly(pen, pts, ink, 3, white, 4620)
	Crayon.oval(pen, Vector2(-10, -6), Vector2(5, 7), ink)
	Crayon.oval(pen, Vector2(10, -6), Vector2(5, 7), ink)
	Crayon.oval(pen, Vector2(0, 10), Vector2(4, 5), ink)
	Crayon.party_hat(pen, Vector2(4, -27), 16, Color(Crayon.GREEN, a), 4621, 0.25)
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _tomb(base: Vector2, k: float) -> void:
	pen.draw_set_transform(base, 0.0, Vector2(1, k))
	var pts := PackedVector2Array()
	for i in 11:
		var ang := PI + i * PI / 10.0
		pts.append(Vector2(cos(ang) * 44.0, -96.0 + sin(ang) * 36.0))
	pts.append(Vector2(44, 0))
	pts.append(Vector2(-44, 0))
	Crayon.poly(pen, pts, Crayon.INK, 4, Color(0.62, 0.62, 0.66), 4630)
	Crayon.text(pen, Vector2(0, -92), "R.I.P.", 24, Crayon.INK, 1, 4631, Crayon.title_font())
	Crayon.text(pen, Vector2(0, -56), "CHUMBO", 17, Crayon.INK, 1, 4632, null, 0.3, false)
	Crayon.party_hat(pen, Vector2(-8, -128), 18, Color(0.5, 0.5, 0.55), 4633, -0.4)
	for i in 4:
		Crayon.disc(pen, Vector2(-36 + i * 24, -4), 7, [Crayon.RED, Crayon.YELLOW, Crayon.PINK, Crayon.WHITE][i].darkened(0.3))
	pen.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _column() -> void:
	var r := Rect2(CX - 38, RIM_Y + 46, 76, PLAT_Y - RIM_Y - 46)
	Crayon.rect(pen, r, Crayon.INK, 4, _fade(Color(0.98, 0.7, 0.78)), 190)
	for k in 4:
		var y := r.position.y + 14 + fmod(k * 52.0 + rot * 60.0, r.size.y - 24)
		pen.draw_rect(Rect2(r.position.x + 4, y, r.size.x - 8, 8), _fade(Color(1, 0.9, 0.5, 0.8)))


func _rider(k: int, a: float) -> void:
	var d := sin(a)
	var base := Vector2(CX + cos(a) * RIDE_R.x, PLAT_Y + d * RIDE_R.y)
	var sc := 0.78 + 0.22 * (d + 1.0) * 0.5
	var bob := sin(t * 2.2 + k * 1.7) * 16.0 * spin
	var feet := base + Vector2(0, -44 - bob)
	# brass pole from the rim to the floor
	Crayon.line(pen, Vector2(base.x, RIM_Y + 30), base, _fade(Color(0.85, 0.65, 0.25)), 6 * sc + 2, 200 + k, 0.2)
	var gi: int = RIDERS[k][2]
	if not Game.done[gi]:
		# still wrapped: you haven't played that present yet
		var w := 78.0 * sc
		var r := Rect2(feet + Vector2(-w * 0.5, -w * 0.9), Vector2(w, w * 0.9))
		Crayon.present(pen, r, _fade(Game.GAMES[gi].col), _fade(Crayon.YELLOW if gi % 2 == 0 else Crayon.WHITE), 230 + k)
		var tag := r.get_center() + Vector2(0, 8)
		Crayon.circle(pen, tag, 15 * sc, Crayon.INK, 2, _fade(Crayon.WHITE), 240 + k)
		Crayon.text(pen, tag + Vector2(0, 1), "?", int(24 * sc), Crayon.INK, 1, 246 + k, Crayon.title_font())
		_rider_pos.append({"p": r.get_center(), "s": sc, "sfx": "shake"})
		return
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
	for pp in pops:
		Crayon.text(pen, pp.p, pp.txt, 34, Color(Crayon.RED, clampf(pp.t * 2.0, 0.0, 1.0)), 1, 4640, Crayon.title_font())
	if not awake and fmod(t, 1.2) < 0.85:
		Crayon.text(pen, Vector2(W * 0.5, 430), "TAP TO START THE PARTY", 54, Crayon.WHITE, 1, 600, Crayon.title_font())
		Crayon.text(pen, Vector2(W * 0.5, 486), "(turn your sound on!)", 30, Color(1, 1, 1, 0.85), 1, 601)
